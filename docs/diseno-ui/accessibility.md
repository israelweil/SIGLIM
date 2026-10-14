# Accesibilidad y Criterios WCAG - SIGLIM

## 1. Criterios Verificables
- **Contraste de Color**: Las combinaciones de texto sobre fondos oscuros (`#131b2e` con texto blanco) y fondos claros (`#f8fafc` con texto `#1e293b`) cumplen con la ratio mínima WCAG AA (4.5:1 para texto normal).
- **Navegación por Teclado**: Todos los elementos interactivos (botones, enlaces, pestañas de login, inputs) deben exponer un indicador de foco visible (`focus:ring-2 focus:ring-emerald-600`).
- **Etiquetas de Formularios**: Los campos de entrada de inicio de sesión y gestión deben contar con etiquetas asociadas explícitamente (`<label>`).
- **Iconografía**: Los iconos puramente decorativos deben marcarse como `aria-hidden="true"`, mientras que los iconos interactivos requieren etiquetas descriptivas o `aria-label`.