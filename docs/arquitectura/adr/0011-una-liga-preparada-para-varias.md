# ADR-0011: Operar una sola liga con el modelo preparado para varias

- **Estado:** Aceptada
- **Fecha:** 2026-10-19
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** DD-011, RNF-005, DEC-07, ERS §2.6 y §3.3.6, ADR-0007

## Contexto
SIGLIM administra solo la Liga Municipal de Futbol Amateur Morelia, pero el diseño no debe impedir
operar varias ligas en el futuro (DD-011, DEC-07). Operar varias ligas a la vez está fuera de esta
entrega (ERS §2.6). Agregar la liga después obligaría a migrar todas las tablas y a reescribir
consultas y restricciones de unicidad.

## Decisión
1. Existe la entidad **`liga`** desde la migración inicial, con una sola fila de semilla.
2. Las **entidades raíz** llevan `liga_id NOT NULL` con llave foránea: temporada, club, cancha y
   sede, catálogo de categorías, tipos de incidencia, artículos, tarifas, comunicados, roles y
   asignaciones de rol. Las entidades hijas heredan la liga por su padre (un partido pertenece a
   una jornada, que pertenece a un grupo de una temporada) y no repiten la columna.
3. Las **reglas de unicidad** se definen por liga: `UNIQUE (liga_id, nombre)` en clubes, canchas y
   categorías; una sola temporada activa **por liga** (RN-058).
4. **Persona y perfil son globales:** la CURP es única en todo el sistema (DEC-10), porque una
   misma persona podría participar en dos ligas; su participación se acota por la temporada, que
   sí pertenece a una liga.
5. La **liga activa** se toma de la configuración `siglim.liga-id`. Los servicios filtran siempre
   por ella y el portal muestra solo sus datos. No hay selector de liga ni la liga aparece en las
   URL de la API.
6. La asignación de rol con ámbito `LIGA` se refiere a esa liga; las funciones de RLS (ADR-0007)
   comparan también `liga_id`.

## Alternativas consideradas
- **Sin entidad liga:** más simple ahora, pero agregarla después afecta todas las tablas raíz,
  índices y restricciones.
- **Una base de datos o un esquema por liga:** aislamiento fuerte, pero multiplica migraciones y
  respaldos; excesivo para una sola liga.
- **Liga en la URL (`/api/v1/ligas/{id}/…`):** prepara la API, pero agrega un parámetro sin uso
  en toda la entrega.

## Consecuencias
- Cada consulta de una entidad raíz incluye el filtro por liga; las pruebas lo verifican con una
  segunda liga de prueba que nunca debe aparecer.
- Habilitar varias ligas en el futuro requiere: selector de liga, la liga en el contexto de cada
  petición y en las URL públicas, y revisar los catálogos compartidos. El esquema no cambia.
