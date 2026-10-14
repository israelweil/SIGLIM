# Decisiones de Diseño Pendientes y Observaciones - SIGLIM

## 1. Decisiones Observadas (Confirmadas por Referencias Visuales)
- Uso de la paleta verde esmeralda (`#006837`) como color primario institucional.
- Estructura de cabecera fija con selector de temporada y acceso a gestión.
- Uso de tarjetas oscuras (`#131b2e`) para destacar el Partido de la Semana y los paneles de control de competición.

## 2. Inferencias Razonables
- Los estados de los partidos (Final, En juego, Programado) se alimentan directamente de los estados devueltos por el backend en Spring Boot / Supabase.
- La responsividad en dispositivos móviles transforma los grids de múltiples columnas en listas apiladas de una sola columna.

## 3. Puntos Pendientes de Validación por el Equipo
- **P-01**: Confirmar si el sistema de notificaciones en tiempo real para cambios de marcador en el portal público utilizará WebSockets de Supabase o sondeo HTTP.
- **P-02**: Verificar la biblioteca exacta de iconos a utilizar en el desarrollo frontend (se recomienda Lucide React por su coherencia de trazo).

## 4. Conflictos detectados entre el diseño de referencia y el ERS

Las capturas de referencia (Google Stitch) muestran elementos que el ERS deja fuera del alcance o
pendientes. Mientras no se resuelvan, **la implementación sigue al ERS**.

| ID | Elemento del diseño | Qué dice el ERS | Qué se implementa |
| --- | --- | --- | --- |
| C-01 | Marca "LIGA APEX" | El sistema es **SIGLIM**; nombre de la Liga: Liga Municipal de Futbol Amateur Morelia | Logo/nombre SIGLIM hasta que el equipo decida la marca |
| C-02 | Buscador global en el header | RF-089: "solo filtros básicos… **sin buscador general**"; buscador listado en 2.6 (portal ampliado) | Filtros por fecha, categoría/grupo y equipo |
| C-03 | Botón "Portal Delegados" | Presidente/delegado de club es un perfil **no modelado** (2.6, Q-07) | Botón "Acceso interno" → login (UI-001) |
| C-04 | Tarjetas "Máximo goleador" / "Mejor portero" | Estadísticas de jugador **aplazadas** (RF-051, RF-054; 2.6) | Solo estadísticas de equipo de la tabla (RF-053) |
| C-05 | Enlaces a Reglamento, Comité de Competición, Prensa y Medios | Noticias, comunicados y documentos **aplazados** (RF-085 a RF-088) | Footer con créditos y sin esas secciones |
| C-06 | Marcador "En vivo" en tiempo real (P-01) | Sin requisito de tiempo real; WebSockets fuera del alcance | Estado del partido al consultar (sin tiempo real) |
| C-07 | Selector de temporada y de división | Una temporada de trabajo (RF-001, Q-11); categorías reales de la Liga, no "divisiones" | Filtro de categoría/grupo; selector de temporada solo si se valida |
| C-08 | Resultados de partidos "Finalizados" en el portal | Solo resultados **validados y publicados** (RF-056, VAL-009, VAL-014) | Mostrar únicamente lo que devuelve `consultar_resultados_publicos` |
