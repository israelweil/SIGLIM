# Documentación de Diseño UI/UX - SIGLIM

## Propósito de la Documentación
Esta documentación establece la especificación visual, de componentes, tipográfica y de diseño de sistemas para el desarrollo del frontend en **React** del sistema **SIGLIM** (Liga Municipal de Futbol Amateur Morelia).

> [!NOTE]
> **Estado (20 de octubre de 2026).** Los archivos de tokens, tipografía y componentes describen la
> primera ronda de capturas (alcance de la Rev. 0.3). Las pantallas del ERS Rev. 0.4.1 se generan con
> los [prompts de Stitch](prompts-stitch.md); al aprobarse el prototipo (PEN-014) se actualizan estos
> archivos con lo que se haya validado. Mientras tanto, si algo choca, mandan el ERS, las
> [convenciones de API](../arquitectura/convenciones-api.md) y [`open-design-decisions.md`](open-design-decisions.md).


Está diseñada para servir como fuente de verdad absoluta para ingenieros frontend y agentes de programación, garantizando una implementación pixel-perfect y coherente con los diseños aprobados (Google Stitch / capturas de referencia) y los requisitos funcionales de la ERS.

## Estructura de la Documentación
- [`design-system.md`](design-system.md): Principios fundamentales del sistema visual y directrices de arquitectura frontend.
- [`typography.md`](typography.md): Jerarquía tipográfica, pesos, tamaños, interlineado y uso de fuentes.
- [`colors-and-tokens.md`](colors-and-tokens.md): Paleta cromática completa, tokens CSS, estados de negocio y colores deportivos.
- [`components.md`](components.md): Especificación detallada de componentes visuales reutilizables (botones, tarjetas, inputs, tablas, etc.).
- [`layouts-and-navigation.md`](layouts-and-navigation.md): Estructura de navegación global, cabeceras, barras laterales y pies de página.
- [`responsive.md`](responsive.md): Breakpoints, comportamiento en dispositivos móviles y tabletas.
- [`accessibility.md`](accessibility.md): Criterios WCAG 2.1 AA, contraste, navegación por teclado y soporte para tecnologías de asistencia.
- [`open-design-decisions.md`](open-design-decisions.md): Registro de decisiones pendientes, inferencias y puntos que requieren validación del equipo.
- [`prompts-stitch.md`](prompts-stitch.md): Prompt base y un prompt por pantalla (F-01 a F-36 del núcleo, B-01 a B-10 del backlog) para generar el prototipo en Google Stitch.

## Guía de Consulta para Agentes de Programación
1. **No inventar estilos**: Utilizar estrictamente los tokens de color y clases definidos en `colors-and-tokens.md` y `components.md`.
2. **Respetar jerarquías**: Mantener los tamaños tipográficos y espaciados especificados.
3. **Validación de estados**: Los estados de negocio (ej. "En juego", "Publicado", "Victoria") deben conectarse con los endpoints REST del backend (Spring Boot / Supabase Auth).
4. **El ERS manda sobre el diseño**: si una pantalla de referencia muestra algo que el ERS deja fuera
   del alcance (sección 2.6) o marca como pendiente, **no se implementa**. Revisa la sección 4 de
   [`open-design-decisions.md`](open-design-decisions.md) antes de construir el header, el portal o
   las tarjetas de estadísticas.
5. **Sin datos inventados**: los textos de las capturas ("Temporada 2024/25", "Primera División",
   nombres de clubes) son de ejemplo; en la aplicación vienen del backend.

## Referencias externas
- Prototipo en Figma (ERS 3.1.1): https://www.figma.com/design/kxtW96Gd0FNxdwmvSk6S4t/Untitled?node-id=0-1
