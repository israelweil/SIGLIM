# Prompts para Google Stitch

**SIGLIM · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia**  
Versión 1.0 · 20 de octubre de 2026 · Alineado con el [ERS Rev. 0.4.1](../requisitos/ERS.md) (§3.1.1,
UI-001 a UI-034) y las [convenciones de API v2.0](../arquitectura/convenciones-api.md)

> [!NOTE]
> Este documento sirve para generar con Google Stitch el prototipo de pantallas que pide el ERS
> (PEN-014). Las pantallas resultantes son una **[PROPUESTA]**: el ERS y la API mandan sobre lo que
> dibuje Stitch (AGENTS.md §2). Los nombres de clubes, canchas y categorías de los prompts son
> **datos de ejemplo**, no requisitos.

## 1. Cómo usar estos prompts

1. Crea un proyecto en Stitch en modo **Web** y pega el **prompt base** (§2). Genera con él el
   primer frame, F-01. El prompt base fija la marca, los colores, la tipografía, los componentes y
   las reglas que comparten todas las pantallas.
2. Para cada frame siguiente, abre un prompt nuevo **en el mismo proyecto** y pega el **bloque de
   estilo** (§3) seguido del prompt del frame. El bloque es corto y evita que Stitch cambie de estilo
   entre pantallas.
3. Genera los frames en el orden de la tabla (§4): primero portal y acceso, luego el núcleo (N) por
   flujo y al final, si da tiempo, los de backlog (B).
4. Refina **un cambio a la vez** («cambia la tabla a filas compactas», «mueve el botón Aprobar a la
   derecha») en lugar de reescribir el prompt entero. Si Stitch omite componentes, divide el prompt;
   los textos muy largos (más de unos 5,000 caracteres) suelen perder elementos.
5. Los frames marcados **Móvil** se generan en modo **Mobile**. Para el resto, cuando el frame de
   escritorio quede bien, pide «genera la versión móvil de esta pantalla a 390 px» (RNF-007 exige que
   todo funcione desde 360 px).
6. Exporta a Figma (prototipo del ERS §3.1.1) y guarda las capturas aprobadas en
   `docs/diseno-ui/pantallas/` con el ID del frame (`F-14-programacion-jornada.png`).

Los prompts están en español a propósito: así Stitch escribe toda la interfaz en español sin mezclar
textos en inglés.

## 2. Prompt base

Cópialo completo en el primer prompt del proyecto.

```text
Diseña la interfaz web de SIGLIM, la plataforma oficial de la Liga Municipal de Futbol Amateur Morelia (México). Todo el texto de la interfaz en español de México.

PRODUCTO
Dos caras en la misma aplicación:
1) Portal público de solo consulta: programación semanal, resultados oficiales y tablas de posiciones. Sin cuenta.
2) Aplicación interna con inicio de sesión para 11 tipos de usuario: Administrador general, Presidente del Comité Ejecutivo, Secretario, Tesorero, Comisión Disciplinaria, Comisión de Arbitraje, Programador de partidos, Directiva de club, Árbitro, Capturista y Jugador o tutor. Cada usuario ve solo los módulos y datos de su ámbito (liga, su club o lo propio).

CARÁCTER VISUAL
Institucional, sobrio, confiable y orientado a datos, como un sistema administrativo moderno de una federación deportiva municipal. Limpio, con mucho espacio en blanco y alta legibilidad. Sin fotografías de jugadores, sin patrocinadores, sin ilustraciones decorativas. Íconos de línea estilo Lucide.

MARCA
Logotipo tipográfico «SIGLIM» en verde con el subtítulo «Liga Municipal de Futbol Amateur Morelia». No uses otros nombres de liga.

COLORES
Primario verde #006837 (hover #004D28). Fondo #F8FAFC. Superficies #FFFFFF. Panel oscuro #131B2E solo para destacar en el portal. Texto principal #1E293B, secundario #64748B. Bordes #E2E8F0. Éxito #10B981, error #EF4444, advertencia #F59E0B, información #2563EB.

TIPOGRAFÍA
Inter. Títulos de pantalla de 28 px en negrita, subtítulos de 20 px seminegrita, cuerpo de 14 px, etiquetas de 12 px. Marcadores, folios y montos en JetBrains Mono.

COMPONENTES
- Botones: primario verde relleno, secundario con contorno, destructivo rojo (solo para rechazar, cancelar o dar de baja). Esquinas de 8 px y altura mínima de 44 px.
- Insignias de estado con texto e ícono, nunca solo color. Verde: Activo, Aprobada, Pagado, Publicado, Finalizado. Azul: Programado, En curso, Pendiente de validación, En revisión. Ámbar: Suspendido, Reprogramado, Devuelta, Vencido. Gris: Borrador, Baja, Cancelado. Rojo: Rechazado.
- Insignia ámbar «No oficial» junto a cualquier valor de demostración (puntos, desempates, plazos).
- Tablas densas con encabezados en mayúsculas pequeñas grises, filas de 48 px y acciones por fila en un menú de tres puntos.
- Formularios con etiqueta visible arriba, texto de ayuda debajo y error en rojo con ícono.
- Toda acción que cambia un estado abre un modal de confirmación con un campo obligatorio «Motivo».
- Alertas en línea que explican por qué algo está bloqueado, en este formato: causa, dato que choca y qué hacer.
- Estados vacíos con un ícono y una acción sugerida. Esqueletos de carga.

DISPOSICIÓN DE LA APLICACIÓN INTERNA
- Barra lateral izquierda de 256 px, colapsable, con los módulos permitidos agrupados: Inicio, Organización, Registros, Programación, Partidos, Disciplina, Tesorería, Administración.
- Barra superior con el texto «Temporada 2025–2026 · Activa», la campana de notificaciones con contador y el menú del usuario con su nombre, rol y ámbito.
- Contenido de ancho máximo 1280 px con migas de pan. Título de la pantalla a la izquierda y acciones principales a la derecha.

DISPOSICIÓN DEL PORTAL
- Encabezado blanco con logotipo, navegación (Programación, Resultados, Tablas) y botón con contorno «Iniciar sesión».
- Barra de filtros: semana, categoría, grupo y equipo.
- Pie con el nombre de la liga, el enlace «Aviso de privacidad» y la leyenda «Solo se publican resultados validados por el árbitro».

REGLAS
- No incluyas buscador global, marcadores en vivo ni elementos en tiempo real, estadísticas de jugadores con nombre, ni campos de tarjeta bancaria.
- Fechas como «sáb 25 oct 2026 · 10:00». Montos como «$350.00».
- Accesibilidad WCAG 2.1 AA: contraste suficiente, foco visible y áreas táctiles de 44 px.
- Diseño responsivo, sin desplazamiento horizontal desde 360 px de ancho.

Primera pantalla: F-01 Portal público, Programación semanal (te la describo enseguida).
```

## 3. Bloque de estilo

Pégalo **al inicio** de cada prompt de frame.

```text
Usa el mismo sistema visual de SIGLIM de este proyecto: verde #006837, fondo #F8FAFC, Inter, insignias de estado con texto e ícono, insignia «No oficial» para valores de demostración, modales con «Motivo» obligatorio para cambios de estado y textos en español de México. Aplicación interna con barra lateral y barra superior («Temporada 2025–2026 · Activa», campana y usuario). Sin buscador global ni datos en tiempo real.
```

## 4. Mapa de frames

| Frame | Pantalla | UI | Actor del ejemplo | RF principales | E | Dispositivo |
| --- | --- | --- | --- | --- | --- | --- |
| F-01 | Portal · Programación semanal | UI-020 | Usuario público | RF-082, RF-089 | N | Web |
| F-02 | Portal · Programación (móvil) | UI-020 | Usuario público | RF-082, RF-089 | N | Móvil |
| F-03 | Portal · Resultados | UI-020 | Usuario público | RF-083, RF-056 | N | Web |
| F-04 | Portal · Tabla de posiciones | UI-012, UI-020 | Usuario público | RF-084, RF-055 | N | Web |
| F-05 | Inicio de sesión | UI-001 | Todos los internos | RF-094 | N | Web |
| F-06 | Aviso de privacidad y consentimiento | UI-033 | Tutor, Directiva | RF-097 | N | Web |
| F-07 | Panel de inicio | UI-002 | Presidente | RF-142, RF-121 | N | Web |
| F-08 | Panel de inicio de club | UI-002 | Directiva de club | RF-140, RF-142 | N | Web |
| F-09 | Notificaciones | UI-030 | Cualquiera | RF-142 | N | Web |
| F-10 | Temporadas | UI-003 | Administrador general | RF-001, RF-003 | N | Web |
| F-11 | Categorías, grupos y parámetros | UI-004 | Administrador general | RF-004, RF-005, RF-099, RF-100 | N | Web |
| F-12 | Usuarios y asignaciones | UI-029 | Administrador general | RF-094 | N | Web |
| F-13 | Roles y permisos | UI-029 | Administrador, Presidente | RF-095, RF-096 | N | Web |
| F-14 | Auditoría | UI-022 | Administrador, Presidente | RF-134 | N | Web |
| F-15 | Clubes y equipos | UI-005 | Secretario | RF-008, RF-009, RF-102 | N | Web |
| F-16 | Afiliación (tarjetón) | UI-023 | Directiva, Presidente | RF-101 | N | Web |
| F-17 | Plantilla del equipo | UI-006 | Directiva de club | RF-013, RF-017 | N | Web |
| F-18 | Alta de jugador | UI-006, UI-024, UI-033 | Directiva de club | RF-013, RF-106, RF-107, RF-108 | N | Web |
| F-19 | Validación de registros y documentos | UI-024 | Secretario | RF-109 | N | Web |
| F-20 | Árbitros | UI-007 | Comisión de Arbitraje | RF-021, RF-112, RF-113 | N | Web |
| F-21 | Canchas y disponibilidad | UI-008 | Administrador general | RF-027, RF-029, RF-030 | N | Web |
| F-22 | Programación de jornada | UI-009 | Programador | RF-033, RF-036, RF-039, RF-040 | N | Web |
| F-23 | Aprobación de jornada | UI-009 | Presidente | RF-121, RF-090 | N | Web |
| F-24 | Designación de árbitros | UI-025 | Comisión de Arbitraje | RF-023, RF-115 | N | Web |
| F-25 | Detalle de partido | UI-010 | Programador | RF-043 a RF-046 | N | Web |
| F-26 | Captura de cédula | UI-011 | Capturista | RF-025, RF-026, RF-047, RF-122, RF-126 | N | Web (tableta) |
| F-27 | Validación de cédula (árbitro) | UI-014 | Árbitro | RF-123 | N | Móvil |
| F-28 | Cédulas pendientes (Comisión) | UI-014 | Comisión de Arbitraje | RF-124 | N | Web |
| F-29 | Tabla de posiciones interna | UI-012 | Programador, Presidente | RF-049, RF-050, RF-053 | N | Web |
| F-30 | Expedientes | UI-015 | Comisión Disciplinaria | RF-057, RF-058 | N | Web |
| F-31 | Resolución de expediente | UI-015 | Comisión Disciplinaria | RF-060, RF-062 a RF-065 | N | Web |
| F-32 | Catálogos disciplinarios | UI-026 | Comisión Disciplinaria | RF-128, RF-129 | N | Web |
| F-33 | Tesorería: cobros y adeudos | UI-027 | Tesorero | RF-137, RF-139, RF-140 | N | Web |
| F-34 | Adeudos y pago simulado del club | UI-027 | Directiva de club | RF-138, RF-140 | N | Móvil |
| F-35 | Mi información | UI-032 | Jugador o tutor | RF-144 | N | Móvil |
| F-36 | Estados de sistema | Transversal | — | VAL-015, VAL-024 | N | Web |
| B-01 | Estadísticas | UI-013 | Interno y público | RF-053, RF-054, RF-145 | B | Web |
| B-02 | Sanciones y castigados | UI-016 | Comisión Disciplinaria | RF-066, RF-068 | B | Web |
| B-03 | Recursos de inconformidad | UI-017 | Directiva, Presidente | RF-067 | B | Web |
| B-04 | Ascensos y descensos | UI-018 | Presidente | RF-069 a RF-075 | B | Web |
| B-05 | Liguilla | UI-019 | Programador | RF-076 a RF-081 | B | Web |
| B-06 | Reportes | UI-021 | Usuarios internos | RF-091, RF-092 | B | Web |
| B-07 | Solicitudes y ofertas de cancha | UI-028 | Directiva, Presidente | RF-116 a RF-118 | B | Web |
| B-08 | Comunicados | UI-031 | Secretario, Presidente | RF-090, RF-086 | B | Web |
| B-09 | Venta de equipo y plaza | UI-034 | Directiva, Presidente | RF-103, RF-104 | B | Web |
| B-10 | Portal ampliado | UI-020 | Usuario público | RF-085 a RF-088 | B | Web |

## 5. Prompts de los frames del núcleo (N)

### Portal público

#### F-01 · Portal · Programación semanal (UI-020)

```text
Pantalla: Portal público, Programación de la semana. Escritorio, 1440 px.

Encabezado del portal con «Programación» activo en la navegación y el botón «Iniciar sesión».

Debajo, un panel oscuro #131B2E de poca altura con el título «Programación de la semana», el rango «20 – 26 oct 2026» y flechas de semana anterior y siguiente.

Barra de filtros: semana, categoría (Libre Primera, Libre Segunda, Veteranos +40, Infantil Sub-12), grupo y equipo, con el botón «Limpiar filtros».

Contenido agrupado por día («Sábado 25 de octubre», «Domingo 26 de octubre») y, dentro de cada día, por cancha. Cada partido es una fila-tarjeta con: hora en monoespaciada, categoría y grupo en una insignia gris, equipo local «vs» equipo visitante, cancha y sede, número de jornada e insignia de estado (Programado, Reprogramado con su nueva hora, Suspendido o Cancelado).

Ejemplos: 10:00 Halcones FC vs Toros de Santa María, Unidad Deportiva Norte, cancha 2, Jornada 7. 12:00 Real Atapaneo vs Club Juventud Morelia.

Estado vacío: «No hay partidos publicados para esta semana».

Nota fija arriba de la lista: «Solo se muestra la programación aprobada por el Comité Ejecutivo».
```

#### F-02 · Portal · Programación (móvil) (UI-020)

```text
Pantalla: Portal público, Programación de la semana, versión móvil a 390 px. Mismo contenido que la versión de escritorio.

Encabezado compacto con el logotipo SIGLIM, un menú hamburguesa (Programación, Resultados, Tablas, Iniciar sesión) y debajo el selector de semana con flechas.

Los filtros se abren en una hoja inferior desde el botón «Filtros (2)». Los filtros activos se ven como chips que se pueden quitar.

Cada partido es una tarjeta apilada: hora grande en monoespaciada, insignia de estado, local y visitante en dos líneas, y debajo cancha, categoría y jornada. Días como encabezados fijos al desplazar.

Sin desplazamiento horizontal. Áreas táctiles de 44 px.
```

#### F-03 · Portal · Resultados (UI-020)

```text
Pantalla: Portal público, Resultados oficiales. Escritorio.

Navegación con «Resultados» activo. Filtros: semana o jornada, categoría, grupo y equipo.

Lista por jornada. Cada resultado muestra la fecha, la categoría y el grupo, el equipo local y el visitante, y el marcador grande en monoespaciada (por ejemplo, Halcones FC 2 – 1 Toros de Santa María).
- Si hubo penales, debajo: «Penales 4 – 3».
- Si fue por no presentación: insignia «Por default».
- Si el resultado fue corregido por una resolución disciplinaria: insignia informativa «Resultado modificado por resolución», con un tooltip que explica que el resultado anterior se conserva en el historial.

Nota visible: «Los resultados son oficiales cuando el árbitro aprueba la cédula del partido».

No muestres goleadores ni nombres de jugadores.
```

#### F-04 · Portal · Tabla de posiciones (UI-012, UI-020)

```text
Pantalla: Portal público, Tabla de posiciones. Escritorio.

Navegación con «Tablas» activo. Selectores de categoría y grupo (Libre Primera, Grupo A).

Tabla con columnas: Pos, Equipo, PJ, PG, PE, PP, GF, GC, DG y PTS (PTS en negrita). Diez equipos de ejemplo. Una franja verde en el borde izquierdo de las primeras 8 posiciones, con la leyenda «Zona de liguilla» y la insignia «No oficial».

Arriba de la tabla, una nota con ícono de información: «Puntos: ganado 3, empatado 1, perdido 0 · Desempate: diferencia de goles, goles a favor, enfrentamiento directo», con la insignia ámbar «No oficial» y el texto «Valores de demostración hasta que la Liga confirme su reglamento».

Si dos equipos empatan en posición, comparten el número.

Pie de la tabla: «Actualizada con resultados oficiales al 26 oct 2026, 19:40».

En móvil, la tabla mantiene Pos, Equipo, PJ, DG y PTS, y el resto se ve al tocar la fila.
```

### Acceso y privacidad

#### F-05 · Inicio de sesión (UI-001)

```text
Pantalla: Inicio de sesión de la aplicación interna. Escritorio, centrada.

Tarjeta blanca de 420 px sobre fondo #F8FAFC. Arriba, el logotipo SIGLIM y la leyenda «Liga Municipal de Futbol Amateur Morelia».

Título «Iniciar sesión». Campos «Correo electrónico» y «Contraseña» con botón para mostrar u ocultar. Botón primario de ancho completo «Entrar» y enlace «¿Olvidaste tu contraseña?».

Texto pequeño: «El acceso es por invitación de la Liga. Si eres jugador menor de edad, entra tu tutor con su cuenta».

Estado de error encima del formulario: «Correo o contraseña incorrectos». Estado de carga en el botón.

Debajo de la tarjeta: «Volver al portal público» y «Aviso de privacidad».

Sin registro libre y sin botones de Google, Facebook u otros proveedores.
```

#### F-06 · Aviso de privacidad y consentimiento (UI-033)

```text
Pantalla: Aviso de privacidad y consentimiento, dentro del alta de un jugador menor. La captura la Directiva de club; el tutor es quien otorga el consentimiento. Aplicación interna, escritorio.

Encabezado «Consentimiento para el tratamiento de datos personales» con la insignia «Aviso integral v1.0 · vigente desde 1 oct 2026».

Caja de texto desplazable con el aviso: responsable, finalidades, datos que se recaban (incluye INE del tutor y fotografía) y derechos ARCO.

Tarjeta del titular: «Mateo Hernández Ruiz · menor de edad». Tarjeta del tutor: «Laura Ruiz Pérez · madre».

Casillas de finalidades, cada una con su explicación:
- «Registro y participación en la liga» (obligatoria, ya marcada y deshabilitada).
- «Difusión de nombre y estadísticas en el portal público» (opcional).

Casilla final: «El tutor leyó el aviso y otorga su consentimiento expreso».

Botones «Registrar consentimiento» (primario) y «Cancelar».

Alerta de bloqueo cuando falta el consentimiento: «Sin el consentimiento del tutor no se puede completar el registro del menor (VAL-025)».
```

### Inicio y avisos

#### F-07 · Panel de inicio del Presidente (UI-002)

```text
Pantalla: Panel de inicio del Presidente del Comité Ejecutivo. Escritorio.

La barra lateral muestra solo sus módulos: Inicio, Organización, Programación, Partidos, Disciplina y Administración. El menú de usuario dice «Ing. Ramón Medina · Presidente · Liga».

Saludo «Buenos días, Ramón» y la fecha.

Fila de 4 tarjetas de pendientes, cada una con un número grande y un enlace «Revisar»:
- «Jornadas por aprobar: 2»
- «Afiliaciones por aprobar: 5»
- «Cambios de permisos por aprobar: 1»
- «Recursos por resolver: 0» (deshabilitada)

Abajo, dos columnas:
- Izquierda: «Próximos partidos del fin de semana», una tabla compacta.
- Derecha: «Notificaciones recientes», 5 avisos con ícono, texto y hora relativa, y el enlace «Ver todas».

Cada tarjeta de pendientes lleva directo a la pantalla de su trámite, para resolverlo en tres pasos o menos.
```

#### F-08 · Panel de inicio de la Directiva de club (UI-002)

```text
Pantalla: Panel de inicio de la Directiva de club. Escritorio.

El menú de usuario dice «Julio César Ortiz · Delegado · Halcones FC». Barra lateral solo con: Inicio, Mi club, Jugadores, Árbitros del club, Tesorería y Notificaciones.

Encabezado del club: nombre «Halcones FC», insignia «Afiliación 2025–2026 · Aprobada» y folio «AF-2025-0137» en monoespaciada.

Tarjetas:
- «Jugadores: 64 activos · 3 pendientes de validación · 1 rechazado», con el enlace «Ver jugadores».
- «Equipos: 4», con chips de categoría.
- «Adeudos: $1,450.00 · 2 cobros pendientes», con el botón primario «Pagar».
- «Árbitros presentados: 1 de 1 requerido», con insignia verde.

Lista «Próximos partidos de mis equipos».

Lista «Avisos», con un ejemplo en ámbar: «Registro de Diego Salas rechazado: la fotografía no es legible. Corrige y vuelve a enviar».

Botón principal arriba a la derecha: «Registrar jugador».
```

#### F-09 · Notificaciones (UI-030)

```text
Pantalla: Notificaciones. Escritorio, más un panel desplegable desde la campana de la barra superior.

Pestañas «No leídas (6)» y «Todas». Botón secundario «Marcar todas como leídas».

Lista con ícono por tipo de evento, título, descripción corta, fecha relativa y punto azul de no leída. Ejemplos:
- «Cédula pendiente de validar: Halcones FC vs Toros, Jornada 7».
- «Cédula devuelta con observaciones».
- «Plazo de validación vencido: la Comisión puede aprobar».
- «Expediente abierto EXP-2025-0042».
- «Jornada 8 de Libre Primera por aprobar».
- «Cobro generado: arbitraje Jornada 7, $350.00».
- «Programación de la semana publicada».

Cada aviso lleva a la pantalla correspondiente.

El panel desplegable de la campana muestra las 5 más recientes y el enlace «Ver todas».

Estado vacío: «Estás al día».
```

### Administración

#### F-10 · Temporadas (UI-003)

```text
Pantalla: Gestión de temporadas. Administrador general. Escritorio.

Título «Temporadas» y botón primario «Nueva temporada».

Tabla: nombre, periodo, estado (Configuración, Activa o Cerrada), categorías participantes, versión de parámetros vigente y acciones. Ejemplos:
- «2025–2026 · Activa».
- «2026–2027 · Configuración».
- «2024–2025 · Cerrada», con el ícono de candado y el texto «Solo lectura: las temporadas cerradas no se modifican».

Para la temporada en configuración, una lista de verificación antes de activar: categorías asignadas ✓, grupos creados ✓, parámetros deportivos registrados ✗, canchas disponibles ✓. El botón «Activar temporada» está deshabilitado y explica qué falta.

Alerta: «Solo puede haber una temporada activa. Cierra 2025–2026 antes de activar otra».

Modal de cierre con «Motivo» obligatorio y la advertencia de que el cierre no se puede deshacer.
```

#### F-11 · Categorías, grupos y parámetros (UI-004)

```text
Pantalla: Estructura y parámetros de la temporada 2025–2026. Administrador general. Escritorio, con tres pestañas.

Pestaña «Categorías»: lista ordenable por arrastre con nombre, tipo (Infantil, Libre o Veteranos), orden y «Categoría superior inmediata». Ejemplo: Libre Segunda → Libre Primera. Interruptor «Participa en la temporada».

Pestaña «Grupos»: por cada categoría de la temporada, tarjetas de grupos (Grupo A, Grupo B) con número de equipos y el botón «Agregar grupo».

Pestaña «Parámetros deportivos», con el encabezado «Versión 3 · vigente desde 1 sep 2025» y el historial de versiones a la derecha. Campos, cada uno con la insignia «No oficial»:
- Puntos por partido ganado, empatado y perdido.
- Criterios de desempate en orden, como lista arrastrable: Diferencia de goles, Goles a favor, Enfrentamiento directo, Menos expulsiones, Sorteo.
- Duración del juego y bloque de cancha por categoría (tabla).
- Marcador por default «3 – 0».
- Plazo de validación de la cédula «48 h».
- Clasificados a liguilla «8».
- Ascensos y descensos «2 y 2».

Botón «Guardar como nueva versión», con la nota «Los cálculos anteriores conservan la versión con la que se hicieron».
```

#### F-12 · Usuarios y asignaciones de rol (UI-029)

```text
Pantalla: Usuarios. Administrador general. Escritorio.

Botón primario «Invitar usuario». Filtros: rol, ámbito, club y estado (Activo o Inactivo).

Tabla: nombre, correo, roles con ámbito como chips («Directiva de club · Halcones FC», «Árbitro · Propio», «Secretario · Liga»), estado y último acceso.

Panel lateral al abrir un usuario: datos, lista de asignaciones con vigencia y botón «Revocar» (pide motivo), el botón «Agregar asignación» (rol, ámbito y club si el ámbito es Club) y el interruptor «Cuenta activa».

Modal «Invitar usuario» con correo, nombre, rol, ámbito y club. Nota: «Recibirá un correo para crear su contraseña».

Mensaje de bloqueo al intentar editar su propio rol: «No puedes cambiar los permisos de tu propio rol (VAL-022)».
```

#### F-13 · Roles y permisos (UI-029)

```text
Pantalla: Roles y permisos. Administrador general, con una vista de aprobación para el Presidente. Escritorio.

A la izquierda, la lista de 12 roles. A la derecha, la matriz de permisos del rol seleccionado (Programador de partidos), agrupada por módulo (Seguridad, Temporadas, Organización, Registros, Arbitraje, Canchas, Programación, Partidos, Disciplina, Publicación, Reportes, Tesorería y Notificaciones). Cada permiso con su casilla, nombre legible y código pequeño en monoespaciada («programacion.jornada:APROBAR»).

Al marcar un permiso incompatible aparece una alerta ámbar: «Este cambio combina "Registrar y ajustar jornadas" con "Aprobar la jornada". Quedará pendiente hasta que lo apruebe el Presidente». El botón cambia a «Solicitar aprobación» y pide motivo.

Pestaña «Solicitudes pendientes» (vista del Presidente): tarjeta con rol, permisos agregados y quitados, quién solicitó, motivo y fecha, y los botones «Aprobar» y «Rechazar» (los dos piden motivo). Nota: «Quien solicita no puede aprobar».
```

#### F-14 · Auditoría (UI-022)

```text
Pantalla: Auditoría. Administrador general y Presidente. Escritorio. Solo lectura.

Filtros: rango de fechas, usuario, módulo (M-01 a M-14), acción y entidad. Botón «Limpiar».

Tabla densa: fecha y hora, usuario con rol, módulo, acción (por ejemplo, APROBAR_CEDULA, CAMBIAR_ESTADO_PARTIDO o RESOLVER_EXPEDIENTE), entidad afectada con enlace y motivo truncado.

Al expandir una fila se ven el detalle en pares clave-valor y el motivo completo.

Ícono de candado y la leyenda «La auditoría no se puede modificar ni borrar». Paginación de 50 filas.
```

### Organización y registros

#### F-15 · Clubes y equipos (UI-005)

```text
Pantalla: Clubes. Secretario de la liga. Escritorio, con lista y detalle.

Lista de clubes con filtro por estado de afiliación y búsqueda por nombre dentro de la lista. Columnas: club, estado de afiliación en la temporada, equipos, jugadores activos y adeudo.

Detalle del club «Halcones FC» en pestañas:
- «Datos»: colores del uniforme como muestras de color.
- «Directiva»: cargos Presidente, Secretario, Tesorero y Delegado, con nombre, vigencia desde y estado de autorización. Botón «Registrar cambio de directiva».
- «Equipos»: tabla con equipo, categoría, grupo y estado (Activo o Baja), y el botón «Nuevo equipo».
- «Afiliaciones»: historial por temporada.

Acciones del club: «Editar» y, en un menú secundario, «Registrar cambio de nombre».
```

#### F-16 · Afiliación (tarjetón) (UI-023)

```text
Pantalla: Afiliación de la temporada 2025–2026, el tarjetón del club. Escritorio, en dos vistas.

Vista 1, Directiva de club, en captura. Formulario por secciones:
- Club.
- Directiva (presidente, secretario y tesorero del club).
- Colores del uniforme.
- Categorías en las que participará (casillas).
- Documentos y firmas: carga de archivo con vista previa.
Folio asignado automáticamente «AF-2025-0137» en monoespaciada. Botón «Enviar a aprobación».

Vista 2, Presidente, en revisión. El mismo tarjetón en solo lectura con una línea de tiempo de estados (Solicitada → Aprobada o Rechazada), quién la capturó y cuándo, y los botones «Aprobar afiliación» y «Rechazar» (con observaciones obligatorias).

Insignias de estado: Solicitada (azul), Aprobada (verde), Rechazada (rojo).
```

#### F-17 · Plantilla del equipo (UI-006)

```text
Pantalla: Jugadores del equipo «Halcones FC · Libre Primera · Grupo A». Directiva de club. Escritorio.

Botón primario «Registrar jugador». Filtros por estado: Pendiente de validación, Activo, Suspendido, Baja y Rechazado, con contadores.

Tabla: fotografía en miniatura (círculo), nombre, CURP enmascarada («HERM******HMN***08»), edad, insignia «Menor» si aplica, estado del registro, documentos (3 de 3 ✓ o 2 de 3 ⚠) y elegibilidad.

Para la elegibilidad, un ícono verde «Elegible» o rojo «No elegible». El rojo tiene un tooltip con la causa, por ejemplo «Sanción vigente: 2 partidos de suspensión (EXP-2025-0042)».

Fila rechazada con la observación del Secretario y la acción «Corregir y reenviar».

Menú por fila: «Ver detalle», «Documentos» y «Dar de baja», que pide fecha y motivo y advierte que el historial se conserva.
```

#### F-18 · Alta de jugador (UI-006, UI-024, UI-033)

```text
Pantalla: Registrar jugador, asistente en 4 pasos. Directiva de club. Escritorio, con un indicador de pasos arriba.

Paso 1, «Identidad». Campo CURP con validación de formato y el botón «Buscar».
- Si la persona ya existe: tarjeta «Ya registrada en SIGLIM. Se reutilizarán sus datos».
- Si ya tiene registro activo en la temporada: alerta roja «Esta CURP ya está registrada en Toros de Santa María · Libre Segunda. Un jugador solo puede tener un registro activo por temporada (VAL-017)», y no se puede avanzar.

Paso 2, «Datos y equipo»: nombre, apellidos, fecha de nacimiento y equipo del club. Si es menor aparece la sección «Tutor» (CURP del tutor, nombre, parentesco y correo).

Paso 3, «Documentos»: lista de requisitos según el tipo de categoría (acta de nacimiento, CURP, fotografía y, si es menor, INE del tutor). Cada requisito tiene una zona para soltar el archivo o tomar foto, una vista previa y su estado. Texto: «JPG, PNG, WebP o PDF, máximo 5 MB».

Paso 4, «Consentimiento y envío»: resumen y consentimiento (ver F-06). Botón «Enviar a validación».

Mensaje final: «Registro enviado. Queda pendiente de validación por la Secretaría».
```

#### F-19 · Validación de registros y documentos (UI-024)

```text
Pantalla: Validación de registros. Secretario de la liga. Escritorio, en dos paneles.

Panel izquierdo: bandeja «Pendientes de validación (12)» ordenada por antigüedad. Cada elemento muestra jugador, club, equipo y fecha de envío. Filtro por club y categoría.

Panel derecho: el registro seleccionado.
- Datos de la persona con la CURP completa.
- Datos del tutor si es menor.
- Visor de documentos con miniaturas. Al hacer clic, el documento se abre en grande dentro de un visor seguro, con la nota «Enlace temporal de 60 segundos».
- Cada documento con los botones «Aprobar documento» y «Rechazar» (pide observación).
- Indicador del consentimiento registrado (versión del aviso y fecha).

Barra de acciones fija abajo: «Validar registro» (primario, habilitado solo con todos los documentos aprobados) y «Rechazar registro» (pide observaciones).
```

### Árbitros, canchas y programación

#### F-20 · Árbitros (UI-007)

```text
Pantalla: Árbitros. Comisión de Arbitraje. Escritorio.

Pestañas «Por validar (4)», «Validados (38)» y «Rechazados».

Tabla: nombre, club que lo presenta, fecha de propuesta y estado (Propuesto, Validado, Rechazado o Baja). Botones por fila «Validar» y «Rechazar» (con observaciones).

A la derecha, una tarjeta «Cuota de árbitros por club» con la regla «1 árbitro por cada 4 equipos» y la lista de clubes que no la cumplen. Esta tarjeta lleva la insignia «Próximamente» porque es de backlog.

En la vista de la Directiva de club, la misma pantalla muestra solo sus árbitros y el botón «Presentar árbitro».
```

#### F-21 · Canchas y disponibilidad (UI-008)

```text
Pantalla: Canchas. Administrador general. Escritorio.

Lista de canchas: nombre, sede, ubicación (Unidad deportiva o Externa), propietario (Liga, Club o Externo) e interruptor «Activa». Botón «Nueva cancha».

Detalle de «Unidad Deportiva Norte · Cancha 2» con un calendario semanal por horas (7:00 a 21:00):
- Bloques verdes «Disponible».
- Bloques grises con patrón diagonal «Bloqueo: evento municipal» y «Mantenimiento: resiembra de pasto».
- Bloques azules con los partidos programados («Halcones vs Toros · 10:00–11:45»).

Botones «Agregar disponibilidad» y «Bloquear intervalo». El modal de bloqueo pide tipo, inicio, fin y motivo obligatorio.

Alerta si se intenta bloquear un horario con partido: «En ese horario hay 2 partidos programados. Reprográmalos primero».
```

#### F-22 · Programación de jornada (UI-009)

```text
Pantalla: Programación de la Jornada 8, Libre Primera, Grupo A. Programador de partidos. Escritorio ancho.

Encabezado con insignia «Borrador», selector de jornada y botones «Verificar conflictos» (secundario) y «Enviar a aprobación» (primario).

Columna izquierda: «Equipos sin partido en esta jornada» como tarjetas arrastrables.

Centro: tabla de partidos editable con local, visitante, fecha, hora de inicio, cancha y fin del bloque (calculado y gris), estado de validación y menú de acciones. Botón «Agregar partido».

Validación en línea:
- Una fila con borde rojo y la alerta «Cancha ocupada: Unidad Deportiva Norte · Cancha 2 ya tiene Real Atapaneo vs Club Juventud de 10:00 a 11:45 (VAL-004)».
- Otra fila: «Toros de Santa María ya juega a las 12:00 en esta jornada (VAL-003)».
- Una advertencia ámbar de localía con el botón «Aceptar con motivo».

Columna derecha: mini calendario de ocupación de canchas del fin de semana.

Al enviar con conflictos, el botón queda deshabilitado con la explicación «Resuelve 2 conflictos para enviar».
```

#### F-23 · Aprobación de jornada (UI-009)

```text
Pantalla: Revisión de la Jornada 8, Libre Primera, Grupo A. Presidente. Escritorio.

Insignia «En revisión». Enviada por «Carlos Gómez · Programador» el 21 oct 2026.

Resumen: 6 partidos, 3 canchas, 0 conflictos y 1 advertencia de localía aceptada (con su motivo visible).

Tabla de solo lectura con los partidos. Línea de tiempo de publicación: Borrador → Revisión → Publicado.

Botones: «Aprobar y publicar» (primario) y «Devolver con observaciones» (secundario, pide observaciones).

El modal de aprobación explica: «Al publicar, la programación aparecerá en el portal y se notificará a los clubes».

Nota visible: «Quien programa no puede aprobar su propia jornada».
```

#### F-24 · Designación de árbitros (UI-025)

```text
Pantalla: Designación de árbitros de la Jornada 8. Comisión de Arbitraje. Escritorio.

Tabla de partidos (fecha, hora, cancha, local vs visitante) con dos columnas de designación: «Central» y «Asistente». Cada celda tiene un selector con búsqueda de árbitros validados.

El selector deshabilita a los árbitros del club de cualquiera de los equipos y explica por qué: «No disponible: pertenece a Halcones FC (VAL-019)». También marca en ámbar a los que ya están designados en otro partido a la misma hora.

Indicador de avance «4 de 6 partidos con árbitro central».

Botón «Guardar designaciones». Historial de cambios en un panel lateral con el motivo de cada cambio.
```

### Partidos y cédula

#### F-25 · Detalle de partido (UI-010)

```text
Pantalla: Detalle del partido Halcones FC vs Toros de Santa María. Programador. Escritorio.

Encabezado: equipos con sus colores, fecha, hora, cancha, jornada e insignia de estado grande («Programado»).

Barra de acciones permitidas según el estado. Para Programado: «Reprogramar», «Cancelar» y «Suspender» (esta deshabilitada con el tooltip «Solo un partido En curso se puede suspender»). Cada acción abre un modal con motivo obligatorio. Reprogramar pide además la nueva fecha, la hora y la cancha.

Pestañas:
- «Resumen»: árbitros designados.
- «Cédula»: estado de la cédula y enlace.
- «Resultado»: versión vigente y versiones anteriores, si hubo corrección por resolución.
- «Historial»: línea de tiempo de estados con usuario, fecha y motivo (por ejemplo, «Programado → Reprogramado · lluvia en la cancha · Carlos Gómez · 24 oct 18:02»).

Nota: «El partido pasa a En curso automáticamente a su hora y a Finalizado cuando se aprueba la cédula».
```

#### F-26 · Captura de cédula (UI-011)

```text
Pantalla: Captura de cédula del partido Halcones FC vs Toros de Santa María, Jornada 7. Capturista. Optimizada para tableta horizontal (1280 px).

Encabezado con insignia «En captura», guardado automático («Guardado hace 5 s») y el botón primario «Enviar a validación».

Tres columnas:
1) Alineación local. Lista de jugadores del equipo con casilla de alineado, número de playera y titular o suplente. Al agregar un jugador de la categoría inmediata inferior del mismo club, se marca «Categoría superior». Los jugadores no elegibles aparecen deshabilitados con su causa («Sanción vigente», «Registro pendiente de validación»).
2) Marcador central grande con botones + y –, penales opcionales y la casilla «No se presentó» por equipo, que aplica el marcador por default «3 – 0» con la insignia «No oficial».
3) Alineación visitante, igual que la local.

Abajo, la línea de eventos: botones rápidos «Gol», «Autogol», «Amarilla», «Roja» y «Sustitución», cada uno con minuto y jugador. Lista cronológica con opción de quitar.

Sección «Incidencias»: tipo (Amonestación, Expulsión, Riña), minuto, descripción e involucrados (personas o equipo).

Campo «Observaciones».

Validación al enviar: lista de campos obligatorios faltantes (VAL-020) con enlaces a cada sección.
```

#### F-27 · Validación de cédula del árbitro (UI-014)

```text
Pantalla: Validar cédula. Árbitro designado. Móvil, 390 px.

Encabezado: «Halcones FC 2 – 1 Toros de Santa María», fecha y cancha, insignia «Pendiente de validación» y el texto «Plazo: vence en 31 h» con la insignia «No oficial».

Secciones plegables: Alineaciones (titulares y suplentes por equipo), Goles y tarjetas (lista cronológica), Incidencias y Observaciones del capturista.

Barra fija abajo con dos botones grandes: «Aprobar cédula» (primario) y «Devolver» (secundario).
- «Devolver» abre una hoja inferior con «Observaciones para el capturista» obligatorias.
- «Aprobar» confirma: «Al aprobar, el resultado será oficial, se publicará en el portal y actualizará la tabla. No se puede deshacer».

Acceso a la pantalla desde «Mis designaciones»: lista de partidos con su estado de cédula.
```

#### F-28 · Cédulas pendientes de la Comisión (UI-014)

```text
Pantalla: Cédulas pendientes. Comisión de Arbitraje. Escritorio.

Pestañas: «Plazo vencido (3)» y «Pendientes del árbitro (9)».

Tabla: partido, jornada, árbitro designado, enviada, plazo con barra de tiempo restante e indicador rojo «Vencido hace 6 h», y acciones.

En «Plazo vencido», el botón «Revisar y aprobar» abre la misma vista de la cédula con la alerta «El árbitro no respondió en el plazo de 48 h (No oficial). La Comisión puede aprobar esta cédula (RF-124)» y los botones «Aprobar» y «Devolver».

En «Pendientes del árbitro» no hay botón de aprobar, solo «Ver».

Nota: «Quien capturó la cédula no puede aprobarla (VAL-021)».
```

#### F-29 · Tabla de posiciones interna (UI-012)

```text
Pantalla: Tabla de posiciones, Libre Primera, Grupo A. Programador y Presidente. Escritorio.

Igual que la tabla del portal, más:
- Columna «Expulsiones».
- Al pasar sobre una posición empatada, un tooltip con el criterio que la definió («Definido por enfrentamiento directo»).
- Etiqueta «Parámetros versión 3» con enlace a los parámetros.
- Separación visual entre «Dato oficial» (resultados de cédulas aprobadas) e «Indicador calculado» (porcentajes de efectividad en gris con un ícono de calculadora).

Si persiste un empate que requiere sorteo: alerta ámbar «Halcones FC y Real Atapaneo siguen empatados. Registra el sorteo» con el botón «Registrar sorteo», que abre un modal para elegir el orden, con motivo.
```

### Disciplina

#### F-30 · Expedientes (UI-015)

```text
Pantalla: Expedientes disciplinarios. Comisión Disciplinaria. Escritorio.

Pestañas por estado con contadores: Abierto (5), En revisión (3), Resuelto, En recurso y Cerrado.

Tabla: folio «EXP-2025-0042» en monoespaciada, origen (Incidencia de cédula, Automático o Manual), partido, tipo de incidencia, involucrados (chips de personas y equipos), fecha de apertura y antigüedad. Fila en rojo suave si lleva más de 7 días abierto.

Botón secundario «Expediente manual».

Al abrir un expediente: encabezado con folio y estado; la incidencia original con un extracto de la cédula (minuto, descripción, partido); involucrados; evidencias (con la insignia «Próximamente» si no aplica); y el botón «Iniciar revisión».
```

#### F-31 · Resolución de expediente (UI-015)

```text
Pantalla: Resolver el expediente EXP-2025-0042. Comisión Disciplinaria. Escritorio, en dos columnas.

Izquierda: hechos (incidencia, cédula e involucrados) y el buscador del catálogo de artículos. Cada artículo muestra número, descripción, tipo de sanción, sujeto, efecto (hacia adelante o retroactivo) y la insignia «No oficial» si es de demostración.

Derecha: formulario de resolución.
- Artículo seleccionado y fundamentos (texto largo obligatorio).
- Casilla «Sin sanción».
- Lista de sanciones para agregar: tipo (Suspensión por partidos, Multa, Pérdida de puntos, Pérdida del partido, Baja), sujeto (jugador, equipo o club), cantidad de partidos o monto, y vigencia desde y hasta (calculada).
- Vista previa de efectos: «Diego Salas no podrá alinearse en los próximos 2 partidos de Halcones FC», «Se generará un cobro de multa de $500.00».

Botón «Emitir resolución», con la confirmación «La resolución no se puede modificar. Solo se puede impugnar mediante recurso».
```

#### F-32 · Catálogos disciplinarios (UI-026)

```text
Pantalla: Catálogos disciplinarios. Comisión Disciplinaria y Administrador general. Escritorio, con dos pestañas.

Pestaña «Tipos de incidencia»: tabla con código, nombre e interruptor «Abre expediente automáticamente». Ejemplos: Amonestación (no), Expulsión (sí), Riña (sí). Insignia «No oficial» en los de demostración.

Pestaña «Artículos del reglamento»: tabla con número, descripción, tipo de sanción, sujeto, efecto, partidos o monto por defecto e interruptor «Aplicación automática». Botón «Nuevo artículo». Formulario lateral de edición.

Banner superior: «El catálogo usa valores de demostración hasta cargar el Reglamento oficial de la Liga».
```

### Tesorería

#### F-33 · Tesorería: cobros y adeudos (UI-027)

```text
Pantalla: Tesorería. Tesorero de la liga. Escritorio.

Fila de tarjetas: «Por cobrar $48,350.00», «Vencido $6,200.00», «Cobrado este mes $21,900.00» y «Clubes con adeudo 23».

Pestañas «Cobros» y «Adeudos por club».

Cobros: filtros por club, equipo, tipo (Arbitraje, Cancha, Multa o Manual), estado y periodo. Tabla con concepto, club o equipo, monto en monoespaciada, fecha límite y estado (Pendiente, Pagado, Rechazado o Vencido). Botón primario «Nuevo cobro» (modal con destino club o equipo, concepto, monto y periodo de pago).

Por fila: «Registrar pago externo», que abre un modal con medio (Efectivo, Transferencia u Otro), fecha, referencia y carga del comprobante. Si el cobro ya está pagado, el botón está deshabilitado con el tooltip «Este cobro ya está pagado (VAL-028)».

Adeudos por club: tabla agregada con desglose por equipo.
```

#### F-34 · Adeudos y pago simulado del club (UI-027)

```text
Pantalla: Adeudos del club Halcones FC. Directiva de club. Móvil, 390 px. Flujo de pago simulado en 3 pasos.

Paso 1: lista de cobros pendientes y vencidos, cada uno con concepto, monto y fecha límite, e insignia de estado. Total arriba. Botón «Pagar» en cada cobro pendiente. Los vencidos muestran «Vencido: comunícate con Tesorería».

Paso 2, pantalla «Pago simulado». Banner ámbar prominente: «Pago simulado: no se realiza ningún cargo». Resumen del cobro y referencia «SIM-20261025-4F7K2A» en monoespaciada. Dos botones: «Aprobar pago» y «Rechazar pago». No hay campos de tarjeta.

Paso 3, resultado:
- Éxito, con ícono verde: «Pago registrado» y referencia.
- Rechazo: «El pago fue rechazado. Puedes intentarlo de nuevo».
```

### Jugador y estados generales

#### F-35 · Mi información (UI-032)

```text
Pantalla: Mi información. Tutor de un jugador menor. Móvil, 390 px.

Selector arriba si el tutor tiene varios menores: «Mateo Hernández Ruiz».

Tarjeta de registro: equipo «Halcones FC · Infantil Sub-12», temporada, estado «Activo» y elegibilidad con ícono verde «Puede jugar».

Secciones:
- «Documentos»: lista con estado de validación y observaciones, sin descarga pública.
- «Próximos partidos».
- «Mis partidos»: fecha, rival y resultado.
- «Sanciones»: vacío con «Sin sanciones».
- «Consentimientos»: finalidades otorgadas, con la opción «Solicitar revocación de difusión».

Si estuviera suspendido: tarjeta roja «Suspendido 2 partidos · Expediente EXP-2025-0042 · vigente hasta 9 nov 2026».

Navegación inferior con Inicio, Partidos y Avisos.
```

#### F-36 · Estados de sistema (transversal)

```text
Pantalla: hoja de estados reutilizables de SIGLIM. Escritorio. Una sola página de referencia con estas variantes:

1) «No tienes permiso para esta acción» (403), con ícono de candado y el botón «Volver al inicio».
2) «No encontramos lo que buscas» (404), con el texto «Puede que no exista o que no tengas acceso».
3) Error de conexión con el botón «Reintentar».
4) Notificación emergente de éxito: «Cédula aprobada. El resultado ya es oficial».
5) Notificación emergente de error con código: «No se pudo programar: cancha ocupada (VAL-004)».
6) Modal genérico de cambio de estado con título, explicación del efecto, campo «Motivo» obligatorio (mínimo 10 caracteres) y los botones «Confirmar» y «Cancelar».
7) Alerta en línea de bloqueo con causa, dato que choca y qué hacer.
8) Estado vacío de una tabla.
9) Esqueleto de carga de una tabla.
10) Insignias de todos los estados del sistema, juntas, con su color.
```

## 6. Prompts de los frames de backlog (B)

Genéralos solo cuando su historia entre a un Sprint (AGENTS.md §3). Mientras tanto, las pantallas
del núcleo que los mencionan muestran la insignia «Próximamente».

#### B-01 · Estadísticas (UI-013)

```text
Pantalla: Estadísticas de Libre Primera, Grupo A. Interna y pública. Escritorio.

Pestaña «Equipos»: efectividad, goles a favor y en contra por jornada (gráfica de líneas) y mejor defensa, rotulados «Indicador calculado».

Pestaña «Jugadores»: tabla de goleadores y tarjetas. En el portal, solo aparece el nombre de quien dio consentimiento de difusión; los demás se muestran como «Jugador (dato reservado)» con su equipo.

Nota: «Las estadísticas de jugador se calculan de las cédulas aprobadas».
```

#### B-02 · Sanciones y castigados (UI-016)

```text
Pantalla: Sanciones vigentes y lista de castigados. Comisión Disciplinaria. Escritorio.

Filtros por categoría, club y sujeto. Tabla con sancionado (persona o equipo), tipo, partidos cumplidos de totales (barra de progreso), vigencia, artículo y estado (Vigente, Cumplida o Revocada).

Interruptor «Autorizar publicación» por sanción, con la columna «Publicada en el portal».

Para el portal, una versión pública de solo lectura que muestra «Jugador (dato reservado)» cuando no hay consentimiento.
```

#### B-03 · Recursos de inconformidad (UI-017)

```text
Pantalla: Recursos de inconformidad. Escritorio, en dos vistas.

Vista de la Directiva de club: desde una resolución de su club, el botón «Interponer recurso» con motivo y documentos. Muestra el estado Interpuesto o Resuelto.

Vista del Presidente: bandeja de recursos con la resolución original lado a lado y el formulario de resolución en segunda instancia (confirmar, modificar o revocar la sanción) con fundamentos.

Nota: «La resolución del recurso cierra el expediente».
```

#### B-04 · Ascensos y descensos (UI-018)

```text
Pantalla: Propuesta de ascensos y descensos, temporada 2025–2026. Presidente. Escritorio.

Por cada par de categorías adyacentes, dos columnas: «Ascienden» y «Descienden», con equipo, posición final y puntos.

Equipos excluidos con su causa: «Adeudo pendiente», «Sanción de baja» o «El club ya tiene equipo en la categoría superior».

Insignias «No oficial» en la regla «2 y 2» y la etiqueta «Reglas versión 3».

Botones «Validar propuesta» y «Observar» (con observaciones).
```

#### B-05 · Liguilla (UI-019)

```text
Pantalla: Liguilla de Libre Primera. Programador. Escritorio.

Configuración: número de clasificados (8), formato (partido único o ida y vuelta) y criterio de empate (penales), con la insignia «No oficial».

Cuadro de llaves (cuartos, semifinal y final) con los equipos sembrados según la tabla y el marcador de cada serie.

Cada partido de llave enlaza a la programación manual: «Programar partido».

Al final: «Campeón» y «Subcampeón».
```

#### B-06 · Reportes (UI-021)

```text
Pantalla: Reportes. Usuarios internos. Escritorio.

Catálogo de reportes en tarjetas: Programación, Resultados, Tabla, Castigados, Sanciones, Cédulas, Historial de equipo o jugador, Ascensos y descensos, Uso de canchas, Auditoría, Adeudos y pagos, Árbitros y designaciones, y Afiliaciones. Solo se ven los permitidos para el usuario.

Al elegir uno: filtros propios, vista previa en tabla y los botones «Exportar PDF» y «Exportar Excel».
```

#### B-07 · Solicitudes y ofertas de cancha (UI-028)

```text
Pantalla: Trámites de cancha. Escritorio.

Pestañas:
- «Préstamo y comodato (Formato 1)», con estados Pendiente, Aprobada y No aprobada.
- «Ofertas de cancha (Formato 2)», con estados Pendiente de negociación, Aceptada y Rechazada.

Formulario de solicitud con los campos del formato. Vista del Presidente con «Aprobar» y «No aprobar».

Botón «Generar carta», que muestra una vista previa de la carta con número de oficio «OF-2025-0089» y la descarga en PDF.
```

#### B-08 · Comunicados (UI-031)

```text
Pantalla: Comunicados. Secretario (redacta) y Presidente (aprueba). Escritorio.

Lista con título, estado (Borrador, Revisión o Publicado) y fechas.

Editor con título y cuerpo de texto enriquecido básico (negritas, listas y enlaces) y vista previa de cómo se verá en el portal.

Botones «Enviar a aprobación» y, para el Presidente, «Aprobar y publicar» y «Devolver con observaciones».
```

#### B-09 · Venta de equipo y conservación de plaza (UI-034)

```text
Pantalla: Venta de equipo y conservación de plaza. Escritorio.

Formulario de la Directiva: equipo, club comprador, fecha y documentos. Aviso: «La venta surte efecto al cierre de la temporada».

Operación separada «Conservación de plaza», con la categoría y la plaza deportiva.

Vista del Presidente: «Autorizar» y «Rechazar», con motivo.

Historial de propietarios del equipo.
```

#### B-10 · Portal ampliado (UI-020)

```text
Pantalla: Portal público ampliado. Escritorio. Agrega a la navegación: Calendario, Comunicados, Sanciones y Equipos.
- Calendario: vista mensual de jornadas por categoría.
- Comunicados: tarjetas con título, fecha y extracto.
- Sanciones: tabla pública de sanciones autorizadas con «Jugador (dato reservado)» cuando aplique.
- Equipos: directorio por categoría y grupo con club y estado.

Sin buscador global; solo filtros por fecha, categoría o grupo y equipo.
```

## 7. Revisión de cada frame antes de aprobarlo

| Verificación | Fuente |
| --- | --- |
| Solo aparecen acciones permitidas por el estado y el rol del ejemplo | ERS §3.1.1, RF-046 |
| Los cambios de estado piden motivo | RF-045, RN-021 |
| Los bloqueos dicen la causa y el dato que choca | ERS §3.1.1, VAL-003 a VAL-006 |
| Los valores de demostración llevan «No oficial» | RN-006, AGENTS.md §3 |
| El portal no muestra datos personales ni nada sin publicar | RF-056, RNF-012 |
| Sin buscador global, tiempo real ni datos de tarjeta | RF-089, C-06, ADR-0012 |
| Estados con texto además de color; contraste AA; foco visible | RNF-008 |
| Sin desplazamiento horizontal a 360 px | RNF-007 |
| Las tareas clave se hacen en tres pasos o menos desde el panel | RNF-006 |
