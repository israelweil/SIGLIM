# ADR-0012: Simular el pago en línea detrás de una interfaz de pasarela

- **Estado:** Aceptada
- **Fecha:** 2026-10-19
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** RF-137 a RF-141, RNF-004, VAL-028, DEC-36, DEC-37, ERS §2.6 y §4.3.5

## Contexto
El club debe poder pagar sus cobros en línea, pero el pago es **simulado**: existen los campos y
los estados (Pendiente → Pagado / Rechazado / Vencido) con una referencia ficticia y no hay
pasarela real (DEC-37; la pasarela real está fuera del alcance, ERS §2.6). El Tesorero también
registra pagos recibidos por otros medios con su comprobante (RF-139). Pagar un cobro vencido o ya
pagado se rechaza (VAL-028).

## Decisión
1. `tesoreria` define la interfaz **`PasarelaDePago`** con dos operaciones: `iniciar(cobro)` →
   intento con referencia, y `confirmar(referencia, resultado)`. La única implementación de esta
   entrega es **`PasarelaSimulada`**.
2. **Flujo simulado:**
   1. La directiva elige «Pagar en línea»; el backend valida el estado del cobro (VAL-028) y crea un
      **intento de pago** con referencia `SIM-AAAAMMDD-XXXXXX` (aleatoria y única).
   2. El frontend muestra una pantalla rotulada **«Pago simulado: no se realiza ningún cargo»** con
      los botones «Aprobar pago» y «Rechazar pago». **No se piden ni se guardan datos de tarjeta.**
   3. El backend confirma con una actualización condicional (`WHERE estado = 'PENDIENTE'`): Pagado
      registra el pago con medio `EN_LINEA_SIMULADO`; Rechazado deja el cobro en Rechazado, desde
      donde puede volver a intentarse (§4.3.5).
3. Los pagos **fuera del sistema** (efectivo, transferencia) los registra el Tesorero con medio,
   fecha, referencia y comprobante en el almacenamiento privado (ADR-0008); pueden aplicarse a un
   cobro Pendiente o Vencido (§4.3.5).
4. Cada confirmación es una transacción atómica que actualiza el cobro, crea el pago, audita y
   publica `CobroPagado` (RNF-004).

## Alternativas consideradas
- **Integrar una pasarela en modo de pruebas (Stripe, Mercado Pago):** realista, pero exige cuentas,
  *webhooks* públicos y manejo de secretos que el ERS deja fuera.
- **Marcar el cobro como pagado con un solo botón, sin intento ni referencia:** no ejercita los
  estados ni la referencia que pide DEC-37.

## Consecuencias
- Integrar una pasarela real en el futuro consiste en otra implementación de `PasarelaDePago` más un
  endpoint de *webhook*; el resto de la tesorería no cambia.
- La interfaz debe dejar claro en todo momento que el pago es simulado, para evitar confusión en
  demostraciones con la Liga.
