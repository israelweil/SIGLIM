# ADR-0009: Ejecutar los procesos por tiempo como tareas programadas idempotentes en el backend

- **Estado:** Aceptada
- **Fecha:** 2026-10-19
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** DP-003, DP-007, RNF-004, RF-045, RF-124, RF-127, RF-141, RF-143, RN-021, DEC-20, DEC-23

## Contexto
Varios cambios ocurren por tiempo y no por la acción de un usuario:

| Proceso | Requisito | Efecto |
| --- | --- | --- |
| Inicio del partido | RF-127 | Programado o Reprogramado → En curso al llegar su fecha y hora |
| Plazo de la cédula | RF-124 | Al vencer (48 h [DEMO]) se habilita la aprobación a la Comisión de Arbitraje y se le avisa |
| Vencimiento de cobros | RF-141 | Pendiente → Vencido al terminar el periodo de pago y aviso al club |
| Envío de correos | RF-143 | Despachar la bandeja de salida (ADR-0010) |

Cada transición debe quedar en el historial con usuario y motivo (RF-045, RN-021) y publicar sus
eventos (avisos, expedientes por falta de pago). Si el backend se detiene un rato, al volver debe
ponerse al corriente sin duplicar efectos.

## Decisión
1. Las tareas son métodos de servicio del módulo dueño anotados con `@Scheduled`
   (`@EnableScheduling` en `compartido`), con la zona horaria `America/Mexico_City` para las reglas
   de calendario. La base guarda instantes en `timestamptz`.
2. **Idempotencia por estado:** cada tarea selecciona lo que ya cumplió su condición con una
   actualización condicional, por ejemplo:

   ```sql
   UPDATE partido SET estado = 'EN_CURSO', actualizado_en = now()
   WHERE estado IN ('PROGRAMADO', 'REPROGRAMADO') AND inicio <= now()
   RETURNING id;
   ```

   Solo los registros devueltos generan historial, auditoría y eventos, en la misma transacción.
   Repetir la tarea, o ejecutarla en dos instancias a la vez, no cambia nada más: la segunda
   actualización no encuentra filas.
3. **Recuperación automática:** las condiciones son «ya pasó el momento» (`<= now()`), no «pasó
   en el último minuto», así que una ejecución tardía procesa todo lo pendiente.
4. Las tareas se ejecutan con el **usuario Sistema** (ADR-0005) y el motivo fijo de cada
   transición («inicio automático por fecha y hora», «plazo de validación vencido»…).
5. **Frecuencia [PROPUESTA]**, configurable en `application.yml` bajo `siglim.tareas.*`:

   | Tarea | Frecuencia |
   | --- | --- |
   | Inicio de partidos | cada minuto |
   | Plazo de cédula | cada 5 minutos |
   | Vencimiento de cobros | diaria a las 00:05 |
   | Bandeja de correo | cada minuto |

6. Cada ejecución registra en la bitácora cuántos registros procesó y su duración, sin datos
   personales (RNF-011).

## Alternativas consideradas
- **`pg_cron` en Supabase:** no depende de que el backend esté encendido, pero la lógica quedaría en
  SQL, sin eventos ni avisos, y duplicaría reglas que viven en los servicios.
- **Calcular el estado al consultar (sin guardar la transición):** evita la tarea, pero no deja
  historial ni dispara avisos.
- **Planificador externo que llame a un endpoint:** agrega otro servicio y un endpoint que hay
  que proteger.
- **ShedLock o Quartz:** útiles con varias instancias; la idempotencia por estado ya evita efectos
  duplicados y el proyecto opera con una sola instancia.

## Consecuencias
- El backend debe estar encendido de forma continua; un alojamiento que lo suspenda por inactividad
  retrasa las transiciones hasta que vuelva (se ponen al corriente solas). Esto se considera al
  elegir el alojamiento (PEN-036, PEN-037).
- Las pruebas fijan el reloj con un `java.time.Clock` inyectable para verificar los plazos sin
  esperar.
