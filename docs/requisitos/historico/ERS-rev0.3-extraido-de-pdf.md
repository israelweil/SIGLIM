# ERS — SIGLIM · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia

> **Especificación de Requisitos de Software** (IEEE Std 830-1998) · Rev. 1.3 · Octubre de 2026
> Equipo: López Meza Leonardo · Olvera Bucio Jose Israel · Olvera Lobato David Geovani
> Seguimiento: Claudio Ernesto Florian Arenas

> [!WARNING]
> **Versión de texto extraída del PDF del ERS.** Se corrigieron la codificación, los encabezados de página
> y las flechas (`→`), pero **las tablas de varias columnas perdieron su estructura**: en las secciones
> 2.2, 2.3, 3.1.1, 3.2 (RF), 3.3 (RNF), 3.4.1 (RN), 4.1 (CU) y en los apéndices, el texto de las columnas
> aparece intercalado. Ante cualquier duda sobre un requisito, consulta el ERS original (PDF/DOCX).
>
> **Pendiente:** regenerar este archivo desde el `.docx` con
> `pandoc ERS.docx -t gfm --wrap=none -o docs/requisitos/ERS.md` para recuperar las tablas.
>
> El documento usa "Rev. 1.3" en el encabezado de página y "Revisión 0.3" en el control del documento;
> confirmar cuál es la numeración correcta.

**Marcas que usa este documento** (respétalas al implementar):

| Marca | Significado para el desarrollo |
| --- | --- |
| *(sin marca)* | Respaldado por las fuentes; implementable, aunque sujeto a validación con la Liga. |
| `[PROPUESTA]` | Propuesta del equipo; implementable como versión de demostración, sin presentarla como requisito aprobado. |
| `[PENDIENTE]` | Decisión abierta. **No se implementa** hasta resolverla (ver Apéndices A y C). |
| `I · S · P` | Estado de entrega: Incluido, Simplificado, Pendiente de decisión. |
| `E · C · O` | Prioridad de entrega: Esencial, Conveniente, Opcional. |

---

Instituto Tecnológico Nacional
de México
Tecnológico Nacional de
México
campus
Instituto Tecnológico de
Morelia
SIGLIM
Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia
Ingeniería en Sistemas Computacionales
Presenta:
López Meza Leonardo
Olvera Bucio Jose Israel
Olvera Lobato David Geovani
Profesor:
Claudio Ernesto Florian Arenas
Wednesday, 7 de October de 2026

Control del documento
Información del documento
Proyecto
Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia. Nombre
definitivo del proyecto.
Documento Especificación de requisitos de software (ERS), estructurada según IEEE Std 830-
1998.
Revisión 0.3 (alcance de entrega acotado). Versiones previas: 0.1 y 0.2.
Fecha Octubre de 2026
Elaborado por López Meza Leonardo, por encargo del equipo de trabajo (véase 1.2).
Seguimiento
Profesor de Ingeniería de Software. Nombre: Claudio Ernesto Florian Arenas
Estado Borrador para seguimiento. Los requisitos aún no han sido aprobados por la Liga ni
validados formalmente; el documento se actualizará durante el semestre. La
revisión 1.3 acota el documento a la entrega propuesta para un equipo de
tres personas; ese alcance no está aprobado por la Liga, el profesor ni el
equipo.

Historial de revisiones
Revisión Fecha Autor Descripción
0.1 Octubre de 2026 López Meza Leonardo
Primera versión. Se organiza la
documentación técnica base de la Liga en la
estructura IEEE 830, con prioridades
propuestas y pendientes señalados.
0.2 Octubre de 2026 López Meza Leonardo Etiquetado de estado y prioridad de entrega
sobre el contenido integral (versión
intermedia).
0.3 Octubre de 2026 López Meza Leonardo
Reducción del documento al alcance de
entrega propuesto: se retiran del cuerpo,
casos de uso, procesos, modelos y criterios
las funciones aplazadas; se agrega la
sección 2.6 «Fuera del alcance de esta
entrega» y las preguntas y supuestos
pendientes (Apéndices C y D). Propuesta
pendiente de validación.

Registro de aprobaciones
Parte Nombre Fecha Estado
Representante de la Liga Municipal Claudio Ernesto Florian [PENDIENTE] Sin aprobar
(cliente)
Arenas
Profesor de Ingeniería de Software Claudio Ernesto Florian 07/10/26 Aprobado
Parcialmente
Arenas
Equipo de desarrollo Olvera Bucio Jose Israel; Olvera 07/10/26 Aprobado
Lobato David Geovani; López Parcialmente
Meza Leonardo

Convenciones de este documento
Marca Significado
[PENDIENTE] Dato o decisión aún no definido o por confirmar. No debe tomarse como requisito
aprobado. El detalle de cada pendiente está en el Apéndice A.

Marca Significado
[PROPUESTA] Propuesta del equipo que requiere validación. En este documento se aplica, sobre todo, a
las prioridades de los requisitos y a las entidades, pantallas y asignaciones de carril que no
vienen de la fuente.
Sin marca Contenido respaldado por las fuentes del proyecto (R1 y R3, véase 1.4). Aun así sigue
sujeto a validación con la Liga, como indica la propia fuente.
Identificadores Se conservan los de la fuente: RF (requisito funcional), RNF (no funcional), RN (regla de
negocio), CU (caso de uso), P (proceso), M (módulo), UI (pantalla), VAL (validación),
REP (reporte), CA (criterio de aceptación), DD y DP (decisiones y propuestas de diseño),
PEN, AMB y RSK (pendientes, ambigüedades y riesgos).
Estado de entrega (I, S, P) [PROPUESTA] Disposición de cada elemento retenido en la entrega: I Incluido, S Simplificado, P
Pendiente de decisión. Lo aplazado (A) solo aparece en 2.6.
Prioridad de entrega (E, C, [PROPUESTA] Esencial, Conveniente u Opcional para esta entrega; independiente de la prioridad
O) de producto (Alta/Media/Baja).

## 1 Introducción
Este documento es la Especificación de Requisitos de Software (ERS) del Sistema de Gestión de la Liga
Municipal de Futbol Amateur Morelia. Describe qué debe hacer el sistema y bajo qué restricciones, sin
definir todavía cómo se implementará. Está estructurado según IEEE Std 830-1998 y sigue la plantilla de
ERS del curso.
Está dirigido al equipo de desarrollo, que lo usará como base para el diseño, el backlog y las pruebas; al
profesor de Ingeniería de Software, que da seguimiento al proyecto durante el semestre; y a los
representantes de la Liga, que deberán validar los requisitos, los procesos y las reglas en caso de ser lanzada
al público.
El proyecto es real y el documento es de seguimiento. Se actualizará conforme se definan nuevos detalles.
Por eso se conserva la información respaldada por las fuentes, se señalan con [PENDIENTE] los aspectos
por definir y se marcan con [PROPUESTA] las sugerencias del equipo, de modo que ninguna suposición
se presente como requisito aprobado. Esta revisión especifica únicamente la entrega acotada para un equipo
de tres personas (véase 1.1); lo que queda fuera se lista en 2.6.
### 1.1 Alcance
Contexto operativo. La operación se organiza en la estructura Temporada → Categoría → Grupo →
Equipos → Partidos. Las programaciones observadas incluyen categorías como Primera Especial, Primera
Fuerza, Reserva, Intermedia, Segunda, Tercera, Juvenil, Cuarta y Veteranos. Una categoría puede tener uno
o varios grupos, y el modelo debe admitir nuevas categorías sin rediseño.
### 1.2 Personal involucrado
Equipo de trabajo del proyecto.
Nombre Olvera Bucio Jose Israel
Rol Desarrollador responsable de arquitectura y datos
Categoría profesional Estudiante de Ingeniería en Sistemas Computacionales
Responsabilidades Coordinar la arquitectura y el diseño lógico de datos; preparar el repositorio y el entorno
de desarrollo; documentar decisiones técnicas; colaborar en desarrollo, integración y
revisión.
Información de contacto l24120356@morelia.tecnm.mx
Aprobación Ing. López Meza Leonardo, Scrum Master.
Nombre Olvera Lobato David Geovani
Rol Product Owner y analista de requisitos
Categoría profesional Estudiante de Ingeniería en Sistemas Computacionales
Responsabilidades Mantener y priorizar el Product Backlog; elaborar historias de usuario y criterios de
aceptación; coordinar el ERS y el análisis de procesos; consultar y validar requisitos con
la Liga o el asesor.
Información de contacto l24120339@morelia.tecnm.mx
Aprobación Ing. Claudio Ernesto Florian Arenas, Representante del Cliente.

Nombre López Meza Leonardo

Rol Scrum Master y responsable de calidad

Categoría profesional Estudiante de Ingeniería en Sistemas Computacionales
Responsabilidades Facilitar Sprint Planning, Daily Scrum, Sprint Review y Sprint Retrospective; mantener
actualizado el tablero; dar seguimiento a impedimentos; coordinar pruebas y verificar los
entregables.
Información de contacto l24120362@morelia.tecnm.mx
Aprobación Ing. Olvera Lobato David Geovani, Product Owner.

Otras partes interesadas
Parte Nombre Participación
Liga Municipal de Futbol Amateur [PENDIENTE] Cliente y fuente de los procesos y reglas.
Morelia Valida requisitos, procesos y reglas.
Profesor de Fundamentos de Seguimiento académico del proyecto durante
Ingeniería de Software el semestre.
Claudio Ernesto Florian
Arenas
### 1.3 Definiciones, acrónimos y abreviaturas
Término Definición
ERS / SRS Especificación de requisitos de software.
RF / RNF Requisito funcional / requisito no funcional.
RN Regla de negocio.
CU Caso de uso.
RBAC Control de acceso basado en roles.
BPMN Notación para el modelado de procesos de negocio (OMG).
API Interfaz de programación de aplicaciones.
Liga Liga Municipal de Futbol Amateur Morelia.
Temporada Periodo deportivo en que se desarrolla una competencia. Tiene una convocatoria
asociada.
Convocatoria Documento normativo de una temporada, del cual se derivan sus reglas de
operación.
Categoría / Grupo Nivel deportivo / agrupación de equipos dentro de una categoría.
Competencia / Fase Estructura de competencia de una temporada y su fase. El formato exacto está
definido por el usuario programador de partidos.
Programación / Jornada Organización de partidos con fecha, hora y cancha o sede asignadas.
Hecho disciplinario registrado manualmente solo si se valida la disciplina reducida.
Incidente
Sanción Consecuencia disciplinaria con vigencia. Solo se registra, de forma manual, si se valida la
disciplina reducida.
Elegibilidad Condición que determina si una persona o un equipo puede participar.

Término Definición
Restricción dura Condición que no puede violarse en la programación (equipo duplicado, cancha ocupada,
cancha no disponible).
Portal público Parte del sistema, sin privilegios de edición, que muestra solo la información
publicada.
Publicación Flujo Borrador → Revisión → Publicado aplicado a la información pública.
PEN / AMB / RSK Pendiente / ambigüedad / riesgo identificados en la fuente (Apéndices A y B).
### 1.4 Referencias
Código Referencia
R1 Presentación «Sistema_Gestion_Liga_Municipal_Morelia_Base_Ingenieria_Software(2).pptx»: visión,
alcance y requerimientos preliminares. Es el documento base del proyecto.
R2 Audio de levantamiento «PREGUNTAS - PROY LIGAS DEPORTIVAS (2).m4a». No transcrito de
forma confiable; pendiente de verificación.
R3 Documentación técnica base para ERS/SRS del Sistema de Gestión de la Liga
(«Sistema_Gestion_Liga_Municipal_Morelia_Documentacion_Tecnica_Base_ERS.md»), derivada de
R1. Las citas «R3 §n» remiten a sus secciones.
R4 Fuentes de fondo citadas por R1, no consultadas directamente en esta revisión: Reglamento de la Liga,
Convocatoria 2025–2026 y programaciones oficiales de las Fechas 32 y 33 (11–12 y 18–19 de julio de
2026).
R5 IEEE Std 830-1998, Recommended Practice for Software Requirements Specifications.
R6 Plantilla «ERS_simplificado» (formato de ERS basado en IEEE 830) proporcionada para el curso.
R7 OMG, Business Process Model and Notation (BPMN) 2.0 (ISO/IEC 19510:2013); notación usada en los
diagramas de proceso de 4.2.
### 1.5 Visión general del documento
El capítulo 2 describe el producto, sus funciones, usuarios, restricciones y dependencias. El capítulo 3
contiene los requisitos específicos: interfaces, requisitos funcionales (RF), no funcionales (RNF) y otros
requisitos, entre ellos las reglas de negocio. El capítulo 4 reúne el modelado: casos de uso, procesos en
BPMN, estados del partido, datos, arquitectura conceptual y trazabilidad. La sección 2.6 lista lo que queda
fuera de esta entrega. El Apéndice A concentra los pendientes de la fuente, el Apéndice B las ambigüedades,
riesgos y verificación de fuentes, el Apéndice C las preguntas para el equipo, el profesor y la Liga, y el
Apéndice D los supuestos propuestos.

## 2 Descripción general
### 2.1 Perspectiva del producto
El sistema es una plataforma web independiente con dos caras: una aplicación interna para los usuarios de
la Liga, con acceso según perfil, y una vista pública de solo consulta. Ambas comparten un backend
modular y una base de datos relacional dentro de una sola aplicación [PROPUESTA]. La información
interna solo llega al portal después de un flujo de validación y autorización, y no existe flujo inverso desde
el portal para editar datos.
Esta entrega no incluye integraciones con servicios externos. Los sistemas o archivos que la Liga usa hoy
y los datos históricos por importar siguen por definir [PENDIENTE] (PEN-003) y no forman parte de la
entrega.
Figura 1. Contexto del sistema de la entrega. Los perfiles internos se detallan en 2.3.
A continuación se adjunta la liga de acceso al documento pdf que se encuentra cargado en OneDrive donde
contiene a detalle:
• Arquitectura
• Diseño Jerárquico
https://itecm-
my.sharepoint.com/:b:/g/personal/l24120356_morelia_tecnm_mx/IQDJlksHByLHR6OTzFSXRQSVAUigyqzW2snfk5
ciVYfrWVU?e=Xcwb0G
### 2.2 Funcionalidad del producto
En esta entrega el sistema se organiza en 8 módulos funcionales (M-01 a M-04, M-06 a M-08 y M-11), más
M-09 como módulo condicionado y pendiente de decisión. El detalle está en los requisitos de la sección
3.2 y en los casos de uso de la sección 4.1. Los módulos y requisitos que no forman parte de la entrega se
listan en 2.6; no se exige una interfaz o servicio independiente por módulo.
Módulo Nombre Propósito Entrega [PROPUESTA]
M-01 Administración y Autenticación, perfiles mínimos, permisos por acción S · E
seguridad y auditoría de acciones críticas. Autenticación, pocos perfiles,
denegación por defecto y auditoría
mínima. (Q-07)
M-02 Temporadas y Administrar una temporada de trabajo, su convocatoria S · E
normativa de referencia y la versión de las reglas usadas. Una temporada, categoría/grupo y
referencia de reglas.
M-03 Organización Administrar clubes, equipos, personas, categorías y S · E
deportiva grupos. Club/equipo para una temporada y
grupo.
M-04 Registros y Registrar altas y bajas de jugadores y su estado de S · C
elegibilidad participación. Alta/baja y estado vigente; sin
renovación ni transferencia. (Q-01)

Módulo Nombre Propósito Entrega [PROPUESTA]
M-06 Canchas y recursos Administrar canchas, su disponibilidad temporal y S · E
bloqueos. Catálogo, disponibilidad y bloqueo
mínimos.
S · E
M-07 Programación Registrar y ajustar manualmente partidos y jornadas y
detectar conflictos duros.
Programación manual con conflictos
duros básicos. (Q-04)
M-08 Partidos y resultados Controlar estados del partido, resultados, tabla y I · E
estadísticas de equipo. Núcleo del flujo; sin histórico de tabla ni
estadísticas de jugador.
M-09 Disciplina Registro manual reducido de incidentes y P · C
resoluciones, solo si se valida [PENDIENTE] (Q-05). Registro mínimo manual si se valida;
resto aplazado. (Q-05)
S · E
M-11 Portal público y Publicar solo información autorizada y permitir la
consulta de programación, resultados y tabla.
publicación Consulta pública mínima de contenido
publicado.

Figura 2. Flujo vertical de la entrega [PROPUESTA]. La disciplina reducida solo se incluye si se valida (Q-05).

Cadena de trazabilidad de la entrega. Temporada → Categoría → Grupo → Equipo → Jornada/Partido
(programación manual) → Resultado → Tabla → Publicación, con auditoría de las acciones críticas. Cada
cambio crítico debe poder rastrearse hasta el usuario, la fecha y el motivo.
### 2.3 Características de los usuarios
En esta entrega se consideran perfiles mínimos: administración, operación (programación y captura),
disciplina solo si se valida, y usuario público. El acceso se controla con permisos por acción y el portal
público no tiene privilegios de edición.
Tipo de usuario Formación y Descripción y responsabilidades Acciones y permisos
habilidades
Administrador Presente ante Usuario con control administrativo del debe definirse catálogo exacto de acciones.
general problemáticas sistema. Administración global del sistema.
que surjan en
campo.
Comisión Dominio de Autoridad que registra la resolución y la Registrar resolución y vigencia.
Disciplinaria
las reglas a sanción. Solo se incluye si se valida la
disciplina reducida (Q-05).
seguir y de la
plataforma
Registro y ajuste manual de programación
Programador de Disponer de Responsable de programación. Registrar,
partidos horarios y revisar y ajustar la programación de forma
dominar la manual.
plataforma.
Capturista Noción del Usuario operativo de captura. Registrar Capturar información operativa
entorno de la información operativa. autorizada, por ejemplo resultados.
plataforma.

Tipo de usuario Formación y Descripción y responsabilidades Acciones y permisos
habilidades
Usuario público Conocimiento Visitante sin privilegios de edición. Consultar programación, resultados y tabla
y manejo Consultar información publicada. publicados
básico de
ordenador y/o
teléfono
móvil.
Los demás tipos de usuario de la fuente (presidente del Comité Ejecutivo, secretario, tesorero, Comisión
de Arbitraje, presidente o delegado de club, árbitro y jugador) no se modelan en esta entrega y se listan
en 2.6. La matriz de permisos perfil → módulo → acción debe formalizarse con el profesor y la Liga
(PEN-010, PEN-029, Q-07). Si se valida la disciplina, la captura se mantiene separada de la resolución
(DD-010).
### 2.4 Restricciones
Decisiones de diseño respaldadas por la fuente (R3 §18.1), que el equipo debe respetar:
ID Restricción Entrega [PROPUESTA]
DD- El sistema será una aplicación web responsive I · E
001
DD- Debe existir backend/API modular S · E
002 Backend modular dentro de una sola
aplicación; sin API pública.
DD- Se utilizará una base de datos relacional I · E
003
DD- Debe existir trazabilidad de cambios y decisiones críticas I · E
006
DD- Las temporadas históricas no deben sobrescribirse I · E
007
DD- La publicación requiere control y aprobación I · E
008
DD- Los permisos se basan en roles y acciones S · E
009 RBAC con pocos perfiles hasta validar la
matriz. (Q-07)
DD- La lógica disciplinaria debe separar captura y resolución P · C
010 Aplica solo si se incluye disciplina. (Q-
05)
Restricciones DD-004 y DD-005. Las decisiones de la fuente sobre un motor de reglas desacoplado y un
servicio específico de programación no se incluyen como componentes de esta entrega (la programación
es manual y las reglas se limitan a una referencia por temporada). Su interpretación queda pendiente de
confirmar con el profesor (sección 2.6, Q-04).
Otras restricciones:
• Proyecto académico con desarrollo planificado en 10 semanas. La fuente propone un
plan de referencia que no sustituye el Scrum que debe construir el equipo. Que esas 10
semanas sean el calendario aplicable a esta entrega y cuáles entregables se evaluarán
sigue [PENDIENTE] (Q-24).
• El equipo debe justificar el stack tecnológico y la arquitectura elegidos (PEN-024 a PEN-
027).
• Esta entrega no incluye integraciones externas.
• No debe existir flujo inverso desde el portal público para editar información.
• Lo que no esté expresamente respaldado por las fuentes debe validarse con la Liga
antes de convertirse en requisito definitivo.

• El sistema debe reflejar los procesos reales de la Liga, no imponer primero una
estructura de pantallas.
### 2.5 Suposiciones y dependencias
Este documento no asume reglas de negocio sin respaldo. Cuando una regla requiere interpretación, se
marca como pendiente y debe pasar por validación humana (RN-006, RN-035).
Dependencias:
• La validación de requisitos, procesos, interfaces, modelo de datos y reglas de la
demostración con la Liga y el profesor.
• El Reglamento y la Convocatoria vigentes de la Liga como base de las reglas
configurables por temporada.
• La resolución de los pendientes del Apéndice A que aplican a la entrega, en particular las
prioridades (PEN-001) y la matriz de permisos (PEN-010).
• La verificación del audio del levantamiento (R2) contra las definiciones de este
documento.
• La rúbrica y las indicaciones escritas del profesor sobre las funciones obligatorias (Q-02)
y el calendario y los entregables a evaluar (Q-24). Este ERS no asume que el alcance
propuesto prevalezca sobre ellos.
### 2.6 Fuera del alcance de esta entrega [PROPUESTA]
Los siguientes elementos de la fuente se conservan solo por su identificador, para trazabilidad. No son
trabajo obligatorio de diseño, implementación ni aceptación de esta entrega. «A» significa aplazado y
«P» pendiente de decisión. Esta delimitación proviene de la propuesta de alcance para un equipo de tres
personas; no está aprobada por el profesor, la rúbrica, la Liga ni el equipo, y debe validarse (Apéndice C).
Si alguno resulta obligatorio, deberá reincorporarse al cuerpo del ERS.
Capacidad Identificadores de la fuente Estado Pregunta
Árbitros, designaciones y cédula RF-021 a RF-026; M-05; UI-007, UI-014; entidades Árbitro, A Q-06
integral Designación arbitral y Cédula; RN-026
Programación automática RF-034, RF-035, RF-037, RF-038, RF-041, RF-042; RN-016, A Q-04
RN-017; VAL-007
Renovación, transferencia e RF-015, RF-016, RF-018 A Q-01
historial detallado de registro
Sede independiente, RF-028, RF-031, RF-032 A —
mantenimiento y partidos
consecutivos
Histórico de tabla y estadísticas de RF-051, RF-054; UI-013 A —
jugador
Disciplina avanzada RF-059, RF-060, RF-061, RF-066, RF-067, RF-068; RN-027, A Q-05
RN-028, RN-031, RN-032; CU-012, CU-013; UI-016, UI-017;
entidades Artículo/Infracción, Expediente y Recurso
Bloqueo derivado de sanción RF-064; RN-015 P (AMB- Q-17
001)
Ascensos, descensos, liguilla y RF-069 a RF-081; RN-004, RN-033, RN-034, RN-036; M-10; A Q-18
fases finales CU-014, CU-015; P-07, P-08; UI-018, UI-019
Portal ampliado RF-085 a RF-088; entidad Documento/Comunicado (noticias, A —
comunicados y buscador general)
Reportes y exportación RF-091, RF-092; REP-004 a REP-009, REP-011; M-12; UI-021 A Q-09
Integraciones y plataforma Correo, WhatsApp/SMS, almacenamiento documental, mapas, A Q-09
CSV/Excel, API pública y autenticación externa; CI/CD y
contenedores (PEN-033 a PEN-035, PEN-038)

Capacidad Identificadores de la fuente Estado Pregunta
Perfiles de usuario no modelados Presidente del Comité Ejecutivo, Secretario, Tesorero, Comisión A Q-07
de Arbitraje, Presidente/delegado de club, Árbitro y Jugador
(PEN-011 a PEN-013)
Restricciones DD-004 y DD-005 Motor de reglas desacoplado y servicio específico de P Q-04
programación como componentes separados
La reducción proviene de limitar funciones, dependencias y decisiones sin validar; este ERS no presume
que el uso de herramientas de IA reduzca el esfuerzo de análisis, integración, pruebas o mantenimiento.

## 3 Requisitos específicos
Este capítulo contiene los requisitos con el detalle necesario para diseñar y probar el sistema. Cada requisito
tiene identificador, nombre, tipo, fuente y prioridad. La fuente indica el origen del requisito (R1, R3, véase
1.4), y las prioridades son propuestas del equipo, como se explica en 3.2.
### 3.1 Requisitos comunes de los interfaces
#### 3.1.1 Interfaces de usuario
El sistema es una aplicación web responsive (RNF-007) con una aplicación interna de acceso autenticado
y un portal público. La fuente no define colores, tipografías ni estilos visuales. Las pantallas siguientes se
identificaron a partir de funcionalidades explícitas, por lo que son una [PROPUESTA] cuya composición
y nomenclatura deben validarse en un prototipo (PEN-014).
ID Pantalla Actor Objetivo Acciones Entrega [PROPUESTA]
Inicio/Login interno Usuarios internos Autenticarse Iniciar sesión I · E
UI-
001
Inicio y navegación Usuarios internos Navegar S · C
UI- Acceder a funciones
002 autorizadas Puede integrarse en el inicio.
Administración S · E
UI- Gestión de Administrar Crear, consultar,
003 temporadas temporadas editar Una temporada.
Administración Estructurar temporada S · E
UI- Configuración de Crear, editar,
004 categorías/grupos consultar
Una vista puede cubrir varias
pantallas.
UI- Gestión de Administración Administrar Registrar, S · E
005 clubes/equipos organizaciones consultar, Una vista puede cubrir varias
deportivas actualizar pantallas.
UI- Registro de Usuarios Gestionar registros Alta, baja S · E
006 jugadores autorizados Alta/baja básica.
UI- Gestión de canchas Usuarios Administrar recursos Registrar, bloquear S · E
008 autorizados
Una vista puede cubrir varias
pantallas.
UI- Programación Programador Registrar y revisar Crear, ajustar, S · E
009 jornada validar conflictos, Programación manual. (Q-04)
enviar a revisión
UI- Detalle de partido Usuarios internos Consultar ciclo del Cambiar estado S · E
010 partido según permiso Una vista puede cubrir varias
pantallas.
UI- Captura de resultado Usuario Registrar marcador Capturar, validar, S · E
011 autorizado corregir Una vista puede cubrir varias
pantallas.
Tabla de posiciones Interno / público Consultar I · E
UI- Consultar
012 clasificación
Resolver expediente Revisar, resolver P · C
UI- Expediente Comisión /
015 disciplinario autoridad Solo si se valida disciplina. (Q-05)
Portal público Usuario público S · E
UI- Consultar Filtrar y consultar
020 información programación, Consulta de solo lectura.
publicada resultados y tabla
UI- Auditoría Administrador / Revisar trazabilidad Consultar, filtrar P · C
022 autoridad Consulta de auditoría: ¿requerida?
(Q-15)
Pantallas de la entrega [PROPUESTA]. No se requiere una interfaz independiente por cada
identificador UI; una misma vista puede cubrir varias funciones si es clara. UI-015 y UI-022 están
pendientes de decisión (Q-05, Q-15).

Comportamientos que la interfaz debe reflejar:
• Mostrar la causa de bloqueo cuando una persona o un equipo no puede participar.
• Mostrar los conflictos de programación y su motivo.
• Mostrar el estado del partido y las acciones permitidas en ese estado.
• Diferenciar los datos oficiales de los indicadores calculados.
• Diferenciar borrador, revisión y publicado en el contenido público.
• Evitar que usuarios sin autorización vean o ejecuten acciones administrativas.
Navegación. Aplicación interna: inicio de sesión → panel con acceso a Temporadas y normativa,
Organización deportiva, Registros y elegibilidad, Canchas, Programación, Partidos y resultados, Tablas y
Administración (seguridad, historial y auditoría). Portal público: Programación, Resultados y Tabla, con
filtros por fecha, categoría/grupo y equipo. La navegación final queda por validar [PENDIENTE] (PEN-
014).
A continuación se adjunta la liga de acceso la cuál contiene el acceso a Figma dónde se puede visualizar la
propuesta para las interfaces.
https://www.figma.com/design/kxtW96Gd0FNxdwmvSk6S4t/Untitled?node-id=0-
1&t=VymLfyImOGjy1T3f-1
#### 3.1.2 Interfaces de hardware
No aplica. La fuente no identifica ningún dispositivo de hardware con el que el sistema deba comunicarse;
el acceso es mediante navegador web desde equipos de escritorio y móviles (RNF-007). Esta sección se
revisará si se define lo contrario.
#### 3.1.3 Interfaces de software
Esta entrega no incluye interfaces con software externo (correo, mensajería, almacenamiento documental,
mapas, importación o exportación de archivos, API pública ni autenticación externa); véase 2.6.
Las integraciones con sistemas externos son potenciales y ninguna está aprobada. Cada una debe justificarse
por costo, seguridad y necesidad (PEN-033 a PEN-035). Hasta definirlas, sus datos y proveedores quedan
pendientes.
A continuación se adjunta la liga de acceso para el Diccionario de la BD´s propuesta para el sistema.
https://itecm-
my.sharepoint.com/:b:/g/personal/l24120356_morelia_tecnm_mx/IQCzMefLsnvMS6fRWMhs3da1Af0B
kpxt7vIjWf2IgmIU-hw?e=jDG3Ne
Si se deasea ver la consulta SQL para dicha base de datos a continuación se adjunta la liga de acceso.
https://itecm-
my.sharepoint.com/:u:/g/personal/l24120356_morelia_tecnm_mx/IQDvro8mXY5pSZJ3D3LUadWjAZiV
S9JHpOUPktLOPQxK8zA?e=qO5cHm

#### 3.1.4 Interfaces de comunicación
La arquitectura de la entrega prevé que el usuario público acceda a la vista de consulta por HTTPS. Los
protocolos y formatos de comunicación de las demás interfaces siguen sin definirse [PENDIENTE].

### 3.2 Requisitos funcionales
Los requisitos funcionales (RF) convierten el alcance de la entrega en comportamientos verificables del sistema. No definen implementación interna. Se agrupan por módulo funcional
y conservan el identificador de la fuente; por eso la numeración tiene huecos: los RF que no forman parte de la entrega se listan en 2.6. Todos tienen tipo «Requisito» y como fuente
R1 formalizada en la sección indicada de R3.
Prioridad. La fuente no define prioridades (PEN-001). Las que aparecen son una [PROPUESTA] del equipo, calculada con los criterios de la tabla, y deberán validarse con la Liga y
el profesor antes de ordenar el backlog.
Prioridad propuesta Criterio
Alta / Esencial Indispensable para el flujo operativo central (configuración → programación → resultado → tabla), para la disciplina o para la integridad, trazabilidad y seguridad.
Sin él el sistema no cumple su propósito.
Media / Deseado Necesario para la operación completa, pero puede entregarse en una iteración posterior sin invalidar el flujo central.
Baja / Opcional Complementario. Puede posponerse sin afectar la operación esencial.
Prioridad de entrega y estado de entrega [PROPUESTA]. La columna «Prioridad» es la prioridad del producto integral (revisión 0.1) y no cambia. La columna «Entrega» indica
el estado (I incluido, S simplificado, P pendiente de decisión) y la prioridad de entrega (E esencial, C conveniente, O opcional) para esta entrega, con un motivo breve cuando el texto
se ajustó o el requisito depende de una decisión (Q-nn, Apéndice C). Un requisito pendiente no es compromiso hasta que se resuelva.
#### 3.2.1 Gestión de temporadas, convocatorias y configuración deportiva
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-001 Gestionar temporadas El sistema debe permitir registrar y administrar una Administrador general / Requisito R1 Alta / Esencial S · E
temporada de trabajo como periodo deportivo. autoridad autorizada R3 §3.2 [PROPUESTA] Se gestiona una temporada de trabajo (no
múltiples simultáneas). (Q-11)
RF-002 Asociar convocatoria a El sistema debe asociar el documento normativo Usuario autorizado Requisito R1 Media / S · C
temporada correspondiente a una temporada. R3 §3.2 Deseado Solo referencia a la convocatoria; fuente
[PROPUESTA] aún no validada. (Q-03)
RF-003 Conservar histórico de El sistema debe conservar información histórica sin Usuario autorizado Requisito R1 Alta / Esencial I · E
temporadas sobrescribir temporadas anteriores. R3 §3.2 [PROPUESTA]
RF-004 Gestionar categorías por El sistema debe permitir registrar la categoría de la temporada Usuario autorizado Requisito R1 Alta / Esencial S · E
temporada de trabajo; el modelo no debe impedir que las categorías R3 §3.2 [PROPUESTA] Una categoría de demostración; el modelo
varíen entre temporadas. no debe impedir otras. (Q-11)
RF-005 Gestionar grupos por El sistema debe permitir registrar el grupo (o los grupos) de Usuario autorizado Requisito R1 Alta / Esencial S · E
categoría y temporada la categoría de la temporada de trabajo. R3 §3.2 [PROPUESTA] Un grupo de demostración; el modelo no
debe impedir otros. (Q-11)

ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-006 Configurar reglas El sistema debe registrar la referencia o versión de las reglas Usuario autorizado Requisito R1 Alta / Esencial S · C
versionables usadas en la temporada/convocatoria (puntuación y R3 §3.2 [PROPUESTA] Se registra la versión/referencia de la regla
desempates de la tabla). No incluye un motor genérico de usada; sin motor genérico. (Q-03)
reglas.
RF-007 Registrar reglas El sistema no debe convertir automáticamente una Autoridad autorizadora Requisito R1 Media / S · C
interpretadas como interpretación administrativa en una regla permanente; debe R3 §3.2 Deseado Se registra como pendiente de validación;
pendientes de validación permitir su validación/autorización. [PROPUESTA] no se automatiza. (Q-03)
#### 3.2.2 Clubes, equipos y personas
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-008 Gestionar clubes El sistema debe registrar y administrar clubes afiliados. Administrador / usuario Requisito R1 Alta / Esencial S · E
autorizado R3 §3.3 [PROPUESTA] Registro básico de clubes necesarios para
la demostración.
RF-009 Gestionar equipos El sistema debe registrar equipos como representación Administrador / usuario Requisito R1 Alta / Esencial S · E
deportiva de un club dentro de categoría/grupo/temporada. autorizado R3 §3.3 [PROPUESTA] Registro básico de equipos de la
temporada/grupo.
RF-010 Reutilizar identidad de El sistema debe mantener una identidad de persona Usuario autorizado Requisito R1 Alta / Esencial S · C
persona reutilizable en diferentes roles. R3 §3.3 [PROPUESTA] Se mantiene solo lo necesario para evitar
duplicidad y conservar el vínculo por
temporada.
RF-011 Mantener roles de persona El sistema debe mantener la identidad de una persona Usuario autorizado Requisito R1 Media / S · C
separados de su identidad separada de sus roles, sin duplicarla. R3 §3.3 Deseado Se mantiene solo lo necesario para evitar
[PROPUESTA] d
y conservar el vínculo por
RF-012 Mantener historial de El sistema debe conservar el historial de un jugador por Usuario autorizado Requisito R1 Media / S · C
pertenencia temporadas/equipos. R3 §3.3 Deseado Se mantiene solo lo necesario para evitar
[PROPUESTA] d
y conservar el vínculo por
#### 3.2.3 Registro y elegibilidad de jugadores
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-013 Dar de alta jugador El sistema debe registrar el alta de un jugador conforme a las Usuario autorizado Requisito R1 Alta / Esencial S · E
reglas de la Liga. R3 §3.4 [PROPUESTA] Alta básica; reglas de alta no validadas. (Q-
03, Q-16)
RF-014 Dar de baja jugador El sistema debe registrar la baja de un jugador conservando Usuario autorizado Requisito R1 Alta / Esencial S · E
su historial. R3 §3.4 [PROPUESTA] Baja básica conservando historial.

ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-017 Registrar estado de El sistema debe manejar estados como activo, suspendido, Usuario autorizado Requisito R1 Alta / Esencial P · C
elegibilidad baja e inelegible. R3 §3.4 [PROPUESTA] Solo estados cuyas reglas la Liga confirme.
(Q-16)
RF-019 Validar elegibilidad antes de El sistema debe comprobar la elegibilidad antes de permitir Sistema / usuario Requisito R1 Alta / Esencial P · C
participación una participación cuando la regla así lo exija. autorizado R3 §3.4 [PROPUESTA] Se incluye solo con reglas de elegibilidad
confirmadas. (Q-16)
RF-020 Bloquear participación por Cuando una sanción vigente impida participar, el sistema Sistema Requisito R1 Alta / Esencial P · C
sanción vigente debe impedir la acción correspondiente y explicar el motivo. R3 §3.4 [PROPUESTA] Depende de disciplina (Q-05) y de AMB-
001. (Q-05, Q-17)
#### 3.2.4 Canchas y sedes
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-027 Gestionar catálogo de El sistema debe registrar canchas y sus características Usuario autorizado Requisito R1 Alta / Esencial S · E
canchas conocidas. R3 §3.6 [PROPUESTA] Catálogo mínimo de canchas.
RF-029 Registrar disponibilidad El sistema debe administrar disponibilidad por fecha/hora. Usuario autorizado Requisito R1 Alta / Esencial S · E
temporal R3 §3.6 [PROPUESTA] Disponibilidad mínima para validar
asignaciones. (Q-24)
RF-030 Bloquear cancha El sistema debe permitir bloquear una cancha cuando Usuario autorizado Requisito R1 Alta / Esencial S · E
corresponda. R3 §3.6 [PROPUESTA] Bloqueo por intervalo; formalidad (PEN-
007) pendiente.
#### 3.2.5 Programación
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-033 Registrar programación El sistema debe permitir registrar manualmente la Programador / usuario Requisito R1 Alta / Esencial S · E
programación por categoría, grupo, equipos, cancha, fecha y autorizado R3 §3.7 [PROPUESTA] Captura manual de jornadas/partidos. (Q-
hora. 04)
RF-036 Asignar canchas El sistema debe permitir asignar manualmente una cancha Programador / usuario Requisito R1 Alta / Esencial S · E
disponible a un partido y rechazar la asignación si genera un autorizado R3 §3.7 [PROPUESTA] Asignación manual de cancha con
conflicto duro. validación de conflictos.
RF-039 Detectar conflictos de El sistema debe detectar, al crear o ajustar una asignación Sistema Requisito R1 Alta / Esencial I · E
programación manual, conflictos como equipo duplicado, cancha ocupada o R3 §3.7 [PROPUESTA] Conflictos duros básicos: equipo
cancha no disponible. El conflicto por sanción depende de duplicado, cancha ocupada, cancha no
AMB-001 [PENDIENTE]. disponible.

ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-040 Permitir ajuste manual El sistema debe permitir crear y modificar manualmente la Programador / usuario Requisito R1 Alta / Esencial S · E
autorizado programación a usuarios autorizados, con traza del cambio autorizado R3 §3.7 [PROPUESTA] Limitado a ajuste manual autorizado con
(RN-018). traza (RN-018). (Q-07)

#### 3.2.6 Partidos y ciclo de vida
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-043 Gestionar estado del partido El sistema debe manejar los estados del ciclo de vida del Usuario autorizado / Requisito R1 Alta / Esencial S · E
partido. sistema R3 §3.8 [PROPUESTA] Estados mínimos de partido por confirmar.
(Q-13)
RF-044 Mantener historial del El sistema no debe eliminar partidos con historial. Sistema Requisito R1 Alta / Esencial I · E
partido R3 §3.8 [PROPUESTA]
RF-045 Auditar transiciones de Cada transición debe conservar usuario, fecha y motivo. Sistema Requisito R1 Alta / Esencial I · E
estado R3 §3.8 [PROPUESTA]
RF-046 El estado del partido debe determinar las acciones permitidas. Sistema Requisito R1 Alta / Esencial I · E
Restringir acciones por
estado R3 §3.8 [PROPUESTA]

#### 3.2.7 Resultados, tablas y estadísticas
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-047 Capturar marcador El sistema debe permitir registrar el marcador y estado del Usuario autorizado Requisito R1 Alta / Esencial I · E
resultado. R3 §3.9 [PROPUESTA]
RF-048 Validar resultado El sistema debe permitir identificar cuándo un resultado Usuario/autoridad Requisito R1 Alta / Esencial I · E
queda validado/oficial. autorizada R3 §3.9 [PROPUESTA]
RF-049 Calcular tabla El sistema debe calcular PJ, resultados, goles y puntos según Sistema Requisito R1 Alta / Esencial I · E
automáticamente reglas configuradas. R3 §3.9 [PROPUESTA] Con reglas de puntos de demostración si no
hay regla oficial validada. (Q-10)
RF-050 Parametrizar desempates Usuario autorizado Requisito R1 Alta / Esencial P · E
El sistema debe soportar criterios de desempate
configurables. R3 §3.9 [PROPUESTA]
Criterios de desempate de demostración
hasta validación oficial. (Q-10)
RF-052 Recalcular tras corrección El sistema debe recalcular las tablas cuando se corrija un Sistema Requisito R1 Alta / Esencial I · E
autorizada resultado de forma autorizada. R3 §3.9 [PROPUESTA]
RF-053 Calcular estadísticas de El sistema debe producir PJ, PG, PE, PP, GF, GC, DG, puntos Sistema Requisito R1 Alta / Esencial S · E
equipo y posición. R3 §3.9 [PROPUESTA] Solo estadísticas de equipo necesarias para
la tabla.

ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-055 Separar dato oficial de El sistema debe distinguir información oficial de métricas Sistema Requisito R1 Media / I · E
indicador calculado derivadas. R3 §3.9 Deseado Depende de definir resultado oficial. (Q-
[PROPUESTA] 12)
RF-056 Publicar sólo información El portal sólo debe mostrar resultados y datos que hayan sido Usuario autorizado / Requisito R1 Alta / Esencial I · E
validada validados y publicados. sistema R3 §3.9 [PROPUESTA]
#### 3.2.8 Disciplina reducida (pendiente de decisión)
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-057 Generar expediente El sistema debe permitir registrar manualmente un caso Sistema Requisito R1 Alta / Esencial P · C
disciplinario disciplinario a partir de un incidente. Solo si se valida la R3 §3.10 [PROPUESTA] Solo registro manual mínimo de
disciplina. incidente/resolución si se valida. (Q-05)
RF-058 Relacionar incidentes con Cada incidente debe quedar relacionado con las personas y/o Sistema / usuario Requisito R1 Alta / Esencial P · C
personas/equipos equipos involucrados. autorizado R3 §3.10 [PROPUESTA] Relación mínima incidente–
persona/equipo si se valida. (Q-05)
RF-062 Validar y resolver sanción El sistema debe permitir que una autoridad registre la Autoridad competente Requisito R1 Alta / Esencial P · C
resolución y la sanción correspondiente. R3 §3.10 [PROPUESTA] Resolución manual por autoridad, solo si
se valida disciplina. (Q-05, Q-07)
RF-063 Calcular vigencia de sanción El sistema debe permitir registrar y conservar la vigencia Autoridad competente Requisito R1 Alta / Esencial P · C
indicada en la resolución; el cálculo automático queda fuera R3 §3.10 [PROPUESTA] Vigencia capturada manualmente, no
de la entrega. calculada automáticamente. (Q-05)
RF-065 Mantener resolución El historial de resolución debe conservarse sin alteración Sistema Requisito R1 Alta / Esencial P · C
inmutable destructiva. R3 §3.10 [PROPUESTA] Condicionado a RF-062; inmutabilidad de
la resolución. (Q-05)
#### 3.2.9 Portal público y auditoría
ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-082 Consultar programación El portal debe mostrar la programación semanal publicada. Usuario público Requisito R1 Alta / Esencial I · E
semanal R3 §3.12 [PROPUESTA]
RF-083 Consultar resultados El portal debe mostrar resultados validados/publicados. Usuario público Requisito R1 Alta / Esencial I · E
R3 §3.12 [PROPUESTA]
RF-084 Consultar tablas El portal debe mostrar tablas publicadas. Usuario público Requisito R1 Alta / Esencial I · E
R3 §3.12 [PROPUESTA]

ID Requisito Descripción Actor Tipo Fuente Prioridad Entrega [PROPUESTA]
RF-089 Buscar por El portal debe permitir filtrar las consultas públicas por fecha, Usuario público Requisito R1 Media / S · C
fecha/categoría/equipo categoría/grupo y equipo; no incluye buscador general. R3 §3.12 Deseado Solo filtros básicos por
[PROPUESTA] t
da/grupo/equipo; sin buscador
RF-090 Gestionar flujo de La información pública debe seguir un flujo de borrador → Usuario autorizado Requisito R1 Alta / Esencial I · E
publicación revisión → publicado. R3 §3.12 [PROPUESTA] Flujo Borrador → Revisión → Publicado;
detalle PEN-009. (Q-07)
RF-093 Auditar acciones críticas El sistema debe registrar acciones críticas con trazabilidad Sistema Requisito R1 Alta / Esencial S · E
suficiente para revisión posterior. R3 §3.12 [PROPUESTA] Auditoría mínima de acciones críticas. (Q-
15)
#### 3.2.10 Validaciones y manejo de errores
Validaciones que el sistema debe aplicar y comportamiento ante su fallo. Los mensajes exactos de interfaz y los códigos técnicos de error están por definir [PENDIENTE] (PEN-016).
ID Elemento Validación Comportamiento si falla Entrega [PROPUESTA]
VAL- Registro de jugador Cumplimiento de reglas de alta y baja No completar operación; informar causa S · E
001 Solo alta/baja; renovación/transferencia
aplazadas. (Q-01)
VAL- Elegibilidad Jugador no suspendido/inelegible cuando la regla impida Bloquear participación y explicar motivo P · C
002 participación Reglas de elegibilidad no validadas. (Q-16)
VAL- Programación Equipo duplicado Rechazar asignación y explicar conflicto I · E
003
VAL- Programación Cancha ocupada Rechazar asignación y explicar conflicto I · E
004
VAL- Programación Cancha no disponible Rechazar asignación y explicar conflicto I · E
005
VAL- Programación Restricción disciplinaria aplicable Impedir programación cuando corresponda P · C
006 Depende de disciplina/AMB-001. (Q-17)
VAL- Estado de partido Acción no permitida por el estado Rechazar la acción I · E
008
VAL- Resultado Resultado no validado No convertir en información oficial/publicada I · E
009
VAL- Corrección de resultado Corrección no autorizada Rechazar y conservar dato oficial previo I · E
010
VAL- Desempate Igualdad Aplicar criterios configurados P · E
011 Criterios de demostración hasta validación
oficial. (Q-10)

ID Elemento Validación Comportamiento si falla Entrega [PROPUESTA]
VAL- Disciplina Artículo/infracción no identificado Dejar caso en revisión P · C
012 Solo si se valida disciplina. (Q-05)
VAL- Sanción Excepción no formalmente definida No automatizarla como regla general; requerir validación P · C
013 Solo si se valida disciplina. (Q-05)
VAL- Publicación Información en borrador/revisión No mostrarla como pública I · E
014
VAL- Acceso Rol sin permiso Denegar acción I · E
015
VAL- Auditoría Operación crítica Debe registrarse usuario, fecha y motivo/contexto I · E
016
#### 3.2.11 Consultas y listados requeridos
Consultas y listados de programación, resultados, tabla y auditoría que forman parte del flujo de la entrega; no incluyen exportación a PDF/Excel ni reportes generalizados (véase 2.6).
Los filtros marcados como pendientes deben confirmarse [PENDIENTE].
ID Consulta o listado Filtros o alcance conocido Prioridad Entrega [PROPUESTA]
REP-001 Programación Fecha / categoría / cancha Media / Deseado S · E
[PROPUESTA] Como consulta/listado del flujo, no como
reporte generalizado.
REP-002 Resultados Temporada / competencia según corresponda Media / Deseado S · E
[PROPUESTA] Como consulta/listado del flujo.
REP-003 Tabla de posiciones Categoría / grupo Media / Deseado S · E
[PROPUESTA] Como consulta de tabla (M-08/M-11).
REP-010 Auditoría Usuario / operación / fecha Media / Deseado P · C
[PROPUESTA] Consulta de auditoría: ¿requerida? (Q-15)
### 3.3 Requisitos no funcionales
Los requisitos no funcionales (RNF) conservan el identificador de la fuente. Los valores cuantitativos (porcentaje de disponibilidad, tiempos de respuesta, nivel de accesibilidad,
políticas de respaldo) no están definidos y quedan como [PENDIENTE]; mientras no se fijen, estos requisitos no son verificables. Las prioridades son una [PROPUESTA] del equipo.

#### 3.3.1 Requisitos de rendimiento
ID Requisito Descripción y criterio Tipo Fuente Prioridad Entrega [PROPUESTA]
RNF- Rendimiento de consultas Las consultas del portal deben responder adecuadamente; tiempo objetivo [PENDIENTE]. Requisito R1 Media / P · C
002 públicas R3 §4 Deseado Sin métrica acordada; no es criterio de
[PROPUESTA] aceptación. (Q-19)
#### 3.3.2 Seguridad
ID Requisito Descripción y criterio Tipo Fuente Prioridad Entrega [PROPUESTA]
RNF- Seguridad y mínimo privilegio El acceso debe limitarse a las capacidades necesarias por rol/contexto. Requisito R1 Alta / I · E
003 R3 §4 Esencial Mínimo privilegio sobre los pocos perfiles de
[PROPUESTA] la demostración. (Q-07)
RNF- Protección de datos personales La información personal debe protegerse y separarse adecuadamente de la información Requisito R1 Alta / I · E
012 pública. R3 §4 Esencial Separar datos personales de públicos. (Q-08)
[PROPUESTA]
RNF- Hash seguro de contraseñas Las contraseñas no deben almacenarse en texto plano. Requisito R1 Alta / S · E
013 R3 §4 Esencial Aplica si se manejan contraseñas propias.
[PROPUESTA]
RNF- Gestión segura de sesiones Deben existir sesiones y controles antiabuso. Requisito R1 Alta / S · E
014 R3 §4 Esencial Acorde a la solución adoptada (PEN-030).
[PROPUESTA]
RNF- Auditoría Las acciones relevantes deben ser trazables. Requisito R1 Alta / S · E
015 R3 §4 Esencial Trazabilidad mínima de acciones críticas. (Q-
[PROPUESTA] 15)
Requisitos de seguridad respaldados por la fuente (R3 §15.1): autenticación segura; autorización por rol y contexto (RBAC); permisos por módulo y acción; separación de funciones;
separación de los datos internos y públicos; respaldo y recuperación.
Controles por definir [PENDIENTE]: política de contraseñas; duración y renovación de sesión; recuperación de acceso; bloqueo o límite de intentos; matriz de permisos por rol;
datos personales visibles para cada rol; retención de auditoría; política de respaldo y recuperación; tratamiento de evidencias disciplinarias; protección de la información en tránsito y
en almacenamiento (PEN-029 a PEN-032).
#### 3.3.3 Fiabilidad
ID Requisito Descripción y criterio Tipo Fuente Prioridad Entrega [PROPUESTA]
RNF- Integridad transaccional Las operaciones críticas deben preservar consistencia e integridad de datos. Requisito R1 Alta / I · E
004 R3 §4 Esencial
[PROPUESTA]

#### 3.3.4 Disponibilidad
ID Requisito Descripción y criterio Tipo Fuente Prioridad Entrega [PROPUESTA]
RNF- Disponibilidad durante El sistema debe estar disponible durante las jornadas; porcentaje y tolerancia de Requisito R1 Alta / P · C
001 jornadas indisponibilidad [PENDIENTE].
R3 §4 Esencial Sin métrica acordada; no es criterio de
aceptación. (Q-19)
[PROPUESTA]
RNF- Respaldo y recuperación Deben existir mecanismos de respaldo y recuperación; política exacta [PENDIENTE]. Requisito R1 Alta / P · O
010 R3 §4 Esencial Respaldo/recuperación: política y entorno no
definidos (PEN-031). (Q-19)
[PROPUESTA]

#### 3.3.5 Mantenibilidad
ID Requisito Descripción y criterio Tipo Fuente Prioridad Entrega [PROPUESTA]
RNF- Escalabilidad El diseño debe soportar nuevas temporadas y nuevas categorías sin rediseño del dominio. Requisito R1 Media / S · C
005 R3 §4 Deseado Permite nuevas temporadas/categorías; sin
exigir plataforma de producción.
[PROPUESTA]
RNF- Mantenibilidad Debe facilitar evolución de reglas, temporadas y módulos. Requisito R1 Media / P · C
009 R3 §4 Deseado Sin criterio medible definido. (Q-21)
[PROPUESTA]
Observabilidad Requisito R1 P · O
RNF- Deben existir mecanismos para observar el comportamiento del sistema; detalle técnico Media /
011 [PENDIENTE]. R3 §4 Deseado
Observabilidad: sin acuerdo; no obligatorio.
[PROPUESTA] (Q-19)

#### 3.3.6 Portabilidad
La fuente no define requisitos de portabilidad específicos. El único requisito relacionado es que la aplicación web sea responsive (RNF-007, en Usabilidad). Los requisitos de
portabilidad entre plataformas, motores de base de datos o entornos de despliegue dependen del stack y la infraestructura, por definir [PENDIENTE] (PEN-024 a PEN-026).
#### 3.3.7 Usabilidad y accesibilidad
Subsección añadida a la plantilla porque la fuente incluye requisitos de este tipo.

ID Requisito Descripción y criterio Tipo Fuente Prioridad Entrega [PROPUESTA]
RNF- Usabilidad El sistema debe ser utilizable por actores con funciones distintas. Requisito R1 Media / P · C
006 R3 §4 Deseado Sin criterio medible definido. (Q-21)
[PROPUESTA]

RNF- Responsive La aplicación web debe ser responsive. Requisito R1 Alta / I · E
007 R3 §4 Esencial
[PROPUESTA]
RNF- Accesibilidad Debe contemplarse accesibilidad; estándar/nivel [PENDIENTE]. Requisito R1 Media / P · C
008 R3 §4 Deseado Nivel de accesibilidad no acordado. (Q-19)
[PROPUESTA]

### 3.4 Otros requisitos
#### 3.4.1 Reglas de negocio
Las reglas de negocio (RN) establecen condiciones del dominio que el sistema debe respetar. Las reglas deportivas y disciplinarias provienen de la convocatoria de cada temporada y
deben versionarse. Si una regla no es explícita, su interpretación requiere validación y autorización (RN-006); no se convierte en regla permanente.
Reglas de temporada y configuración
ID Regla Condición Comportamiento esperado Actores afectados Entrega [PROPUESTA]
RN-001 Cuando se gestione una competencia La información debe quedar asociada a su temporada I · E
La temporada representa un periodo Todos los usuarios
deportivo administrativos
RN-002 La convocatoria es normativa S · C
Una temporada tiene una convocatoria Las reglas de operación deben poder vincularse a su Autoridades / usuarios
asociada documento normativo administrativos
Convocatoria como referencia; contenido aún no validado. (Q-03)
RN-003 Las categorías/grupos pueden variar por Al abrir una nueva temporada No debe asumirse una estructura fija heredada sin Administración I · E
temporada configuración
RN-005 El histórico no se sobrescribe Al modificar una temporada nueva o Los datos históricos deben conservarse Todos I · E
actual
RN-006 Las interpretaciones requieren validación Cuando una regla no sea explícita Debe pasar por validación/autorización Autoridades I · E

Reglas deportivas y de registro
ID Regla Condición Comportamiento esperado Actores afectados Entrega [PROPUESTA]
RN-007 Un equipo pertenece a una categoría/grupo Durante su participación La relación deportiva debe poder identificarse por Administración I · E
durante una temporada temporada
RN-008 Una persona es una identidad reutilizable Cuando tenga uno o más roles No debe duplicarse la identidad para cada rol Administración S · C
Identidad reutilizable solo si se necesita.
RN-009 El registro del jugador está sujeto a reglas Alta, baja, renovación o transferencia La operación debe validarse conforme a la temporada Jugadores / clubes P · C
Reglas de registro no validadas. (Q-16)
RN-010 La elegibilidad debe comprobarse antes de Antes de una acción que habilite El sistema debe bloquear cuando exista impedimento Sistema / usuarios operativos P · C
participar participación Reglas de elegibilidad no validadas. (Q-16)
RN-011 La sanción vigente puede impedir Cuando la norma lo establezca El sistema debe impedir la participación Jugador / equipo / P · C
participación correspondiente administración Depende de disciplina y AMB-001. (Q-05,
Q-17)
Reglas de programación
ID Regla Condición Comportamiento esperado Actores afectados Entrega [PROPUESTA]
RN-012 Un equipo no puede aparecer duplicado en Generación/edición de jornada Debe detectarse como conflicto duro Programador I · E
conflicto
RN-013 Una cancha ocupada no puede reutilizarse Generación de jornada Debe bloquearse la asignación conflictiva Programador I · E
en el mismo intervalo
RN-014 Una cancha no disponible no puede Existe bloqueo/mantenimiento/no El sistema debe impedir la asignación Programador I · E
asignarse disponibilidad
RN-018 Los cambios manuales autorizados deben Al modificar una programación Registrar usuario, fecha y motivo Programador / administración I · E
quedar trazados
Reglas de partidos y resultados
ID Regla Condición Comportamiento esperado Actores afectados Entrega [PROPUESTA]
RN-019 El estado del partido controla acciones En cualquier momento del ciclo Sólo deben permitirse acciones válidas para el estado Todos los usuarios internos I · E
RN-020 Los partidos históricos no se eliminan Un partido posee historial Debe conservarse Administración I · E
RN-021 Cada transición de estado es auditable Cambio de estado Registrar usuario, fecha y motivo Usuarios internos I · E
RN-022 La tabla se deriva de resultados validados Se oficializa un resultado Debe actualizarse el cálculo de la tabla Sistema / administración I · E
RN-023 Los desempates dependen de reglas Existe igualdad de posiciones Se deben aplicar los criterios configurados para la Sistema S · E
configuradas temporada Desempates de demostración hasta validar
los oficiales. (Q-10)
RN-024 Una corrección autorizada puede requerir Se corrige un resultado oficial La tabla debe recalcularse y quedar trazada Administración I · E
recálculo
RN-025 Sólo información validada se publica Un dato aún no es oficial No debe mostrarse como oficial en el portal Sistema / publicación I · E

Reglas disciplinarias
ID Regla Condición Comportamiento esperado Actores afectados Entrega [PROPUESTA]
RN-029 La resolución genera vigencia verificable Se aprueba una sanción Debe conservarse el periodo de vigencia Sistema / disciplina P · C
Vigencia registrada manualmente si se
valida disciplina. (Q-05)
RN-030 El historial de resolución es inmutable Resolución generada No debe alterarse destructivamente Autoridades P · C
Condicionado a registro de resolución. (Q-
05)
Reglas de promoción y fases finales
ID Regla Condición Comportamiento esperado Actores afectados Entrega [PROPUESTA]
RN-035 Los casos no automáticos requieren Regla ambigua/no automatizada Generar propuesta y solicitar autorización Autoridades I · C
validación Principio transversal: lo ambiguo pasa a
validación humana.
#### 3.4.2 Requisitos de datos
Principios de diseño de datos respaldados por la fuente:
• Usar catálogos e identificadores para resolver abreviaturas, nombres variables y formatos no uniformes.
• Validar duplicados y ambigüedades.
• No sobrescribir históricos.
• Separar la identidad de la persona de sus roles.
• Separar los datos oficiales de los indicadores calculados.
• Proteger los datos personales.
• Mantener la trazabilidad de configuraciones y reglas utilizadas.
Atributos que requieren definición [PENDIENTE]: identificador exacto y claves naturales de cada entidad; datos personales obligatorios del jugador; datos específicos del club y el
equipo; datos de convocatoria y versionado; campos del resultado; variables de disponibilidad de cancha; auditoría detallada (PEN-018, PEN-019, PEN-022).
Datos [PROPUESTA]. La entrega se limita a las entidades de la sección 4.3. Los atributos, cardinalidades y retención siguen [PENDIENTE] hasta validar reglas y datos (PEN-
018, PEN-019, AMB-005).
#### 3.4.3 Criterios de aceptación preliminares
Criterios iniciales de aceptación que deberán completarse por requisito (historias de usuario y pruebas) en el diseño detallado.

ID Criterio Entrega [PROPUESTA]
CA- Las temporadas históricas no se alteran. I · E
001
CA- La programación manual no acepta asignaciones con conflicto duro detectable (equipo duplicado, cancha ocupada o cancha no S · E
002 disponible). Se aplica a la captura manual: no se acepta una asignación con conflicto duro detectable (RF-
039). (Q-04)
CA- Un resultado validado actualiza la tabla. I · E
003
CA- Una sanción vigente bloquea cuando corresponda. P · C
004 Solo si se valida disciplina y AMB-001. (Q-17)
CA- Una resolución genera vigencia verificable. P · C
005 Vigencia registrada manualmente, si se valida. (Q-05)
CA- El sistema explica por qué un equipo/persona no puede participar. P · C
006 Depende de reglas de elegibilidad validadas. (Q-16)
CA- El portal muestra sólo información publicada. I · E
007
CA- Los cambios críticos quedan auditados. I · E
008
Criterios de la entrega [PROPUESTA]. CA-001, CA-002, CA-003, CA-007 y CA-008 aplican a la entrega. CA-004, CA-005 y CA-006 están pendientes porque dependen de la
disciplina reducida, de AMB-001 y de reglas de elegibilidad confirmadas. Los valores cuantitativos de los requisitos no funcionales siguen [PENDIENTE] y no son criterios de
aceptación (Q-19).
#### 3.4.4 Requisitos legales y normativos
La fuente exige proteger los datos personales (RNF-012) pero no identifica el marco legal aplicable ni las obligaciones concretas, como avisos de privacidad o plazos de conservación.
Este marco queda por definir [PENDIENTE] (PEN-019, PEN-032). La normativa deportiva proviene del Reglamento y la Convocatoria de la Liga (R4), que deben consultarse para
validar las reglas.

## 4 Modelado del Sistema
Este capítulo reúne los modelos que complementan los requisitos: casos de uso, procesos, estados, datos, estructura modular y trazabilidad. Los modelos se derivan de la fuente; cuando
el equipo agregó un elemento propio (por ejemplo, la asignación de tareas a carriles en los procesos), se marca como [PROPUESTA].
### 4.1 Modelo de casos de uso
La entrega comprende 10 casos de uso incluidos o simplificados (CU-001 a CU-009 y CU-016) y 2 condicionados y pendientes de decisión (CU-010 y CU-011). Los demás casos de
uso de la fuente se listan en 2.6. «Usuario autorizado» representa a cualquier usuario interno con el permiso correspondiente; los roles concretos dependen de la matriz de permisos
[PENDIENTE] (PEN-010). La línea punteada de CU-001 indica al actor secundario.

Figura 3. Diagrama de casos de uso de la entrega. Discontinuo: pendiente de decisión.

Caso de uso Actores Objetivo y precondiciones Flujo principal Requisitos
Alternativas, excepciones y Entrega [PROPUESTA]
postcondición
CU-001 S · E
Principal: Objetivo: Crear y configurar un periodo registrar temporada → asociar Alternativas: convocatoria RF-001, RF-002,
Registrar temporada Administrador deportivo. convocatoria → guardar. no disponible → dejar RF-003. Una temporada de trabajo. (Q-11)
general / usuario Precondiciones: Usuario autenticado y configuración pendiente.
autorizado.
autorizado. Excepciones: datos
incompletos.
Secundario:
Autoridad
Postcondición: temporada
responsable de registrada con histórico
validación.
preservado.
CU-002 Principal: Usuario Objetivo: Definir estructura deportiva de la seleccionar temporada → crear Postcondición: estructura RF-004, RF-005. I · E
autorizado. temporada.
Configurar categoría/grupo categoría → crear uno o más grupos → disponible para registrar
Precondiciones: temporada existente. guardar. equipos.
CU-003 — RF-008, RF-009. I · E
Principal: Usuario Objetivo: Incorporar un club y su representación registrar club → registrar equipo →
Registrar club/equipo autorizado. deportiva. asociar categoría/grupo/temporada.
CU-004 S · E
Principal: Usuario Objetivo: Incorporar o actualizar el registro identificar persona → asociar Alternativas: datos RF-010 a RF-
Registrar jugador autorizado. competitivo de una persona. incompletos; regla no Solo alta/baja básica.
equipo → solicitar alta o baja → 014; RF-017 y
validar reglas confirmadas → satisfecha. RF-019
guardar conservando el historial. [PENDIENTE].
CU-005 CU-005 / Registrar Objetivo: Incorporar una cancha y su registrar cancha → características — RF-027, RF- S · E
Registrar cancha cancha disponibilidad. → disponibilidad → bloqueos. 029, RF-030. Catálogo mínimo.
CU-006 / Registrar y Principal: Objetivo: Registrar o ajustar manualmente los crear o ajustar el partido (equipos, Alternativas: ajuste RF-033, RF- S · E
ajustar programación Programador de partidos de la jornada sin conflictos duros. / fecha, hora, cancha) → validar posterior autorizado. / 036, RF-039, Captura manual con validación de
manual partidos [perfil Precondiciones: temporada, categoría, grupo, conflictos duros → guardar en Excepciones: conflicto RF-040. conflictos; se aplaza la generación
automática. (Q-04)
PENDIENTE]. equipos y canchas con disponibilidad borrador con traza → enviar a (equipo duplicado, cancha
registrados. revisión.
ocupada o cancha no
disponible) → rechazar la
asignación y explicar el
conflicto. / Postcondición:
programación en borrador
con traza.
CU-007 Principal: Usuario Objetivo: Pasar una programación de revisión a seleccionar propuesta → revisar → — RF-040, RF-056, I · E
autorizado. publicación. aprobar → publicar. RF-090.
Publicar programación Aprobación/publicación; quién aprueba:
pendiente. (Q-07)
CU-008 Principal: Usuario Objetivo: Registrar un resultado y convertirlo en capturar marcador → validar → Alternativas: corrección RF-047 a RF- I · E
Registrar/confirmar autorizado. dato oficial cuando corresponda. actualizar tabla/estadísticas → autorizada → recalcular. 050, RF-052,
conservar histórico.
resultado RF-053, RF-
055, RF-056.
CU-009 Principal: Sistema. Objetivo: Calcular posiciones con las reglas recuperar resultados validados → — RF-049, RF- I · E
configuradas.
Calcular tabla calcular estadísticas de equipo → 050, RF-052,
Precondiciones: resultados válidos.
aplicar puntos → aplicar desempates RF-053, RF-
→ guardar el resultado de la tabla. 055.

Caso de uso Actores Objetivo y precondiciones Flujo principal Alternativas, excepciones y Requisitos Entrega [PROPUESTA]
postcondición
CU-010 / Registrar Principal: Objetivo: Registrar manualmente un incidente. identificar partido → registrar — RF-057, RF- P · C
incidente (manual) Capturista o Solo si se valida la disciplina reducida (Q-05). incidente y personas o equipos 058. Solo si el curso la exige y se valida el
[PENDIENTE] usuario autorizado involucrados → guardar. alcance manual. (Q-05, Q-06)
[PENDIENTE].
CU-011 / Registrar Principal: Objetivo: Registrar la resolución de un caso y abrir caso → revisar → registrar Alternativas: devolver a RF-062, RF- P · C
resolución y vigencia Autoridad su vigencia. Solo si se valida la disciplina resolución → registrar vigencia. revisión. / Excepciones: 063, RF-065. Solo si se valida disciplina manual
[PENDIENTE] competente reducida (Q-05). alcance de la sanción sin acotada. (Q-05)
[PENDIENTE]. definir → caso en revisión
(AMB-001).
CU-016 Principal: Usuario Objetivo: Consultar información publicada. elegir fecha/categoría/equipo → — RF-082 a RF- S · E
Consultar portal público público. consultar programación, resultados 084, RF-089, Tres consultas principales con filtros
o tabla publicados → filtrar → RF-090. básicos.
visualizar.
### 4.2 Modelo de procesos (BPMN)
Los procesos se modelan con BPMN 2.0 (R7): círculo verde de borde fino para el inicio, círculo de borde grueso rojo para el fin, círculo doble para un evento de enlace entre partes de
un diagrama, rectángulo redondeado para una tarea, rombo con × para una decisión exclusiva y carriles para los actores bajo el pool «Liga». Los procesos largos se dividen en partes
enlazadas para que el texto sea legible.
La fuente describe los pasos, las decisiones y los actores principales de cada proceso. La asignación de cada tarea a un carril se tomó del actor indicado en los RF y los CU y es una
[PROPUESTA] que debe validarse con la Liga (PEN-005, PEN-010). Se modelan los procesos de la entrega; P-07 y P-08 se listan en 2.6. P-04 (ciclo de vida del partido) se modela
como máquina de estados.
#### 4.2.1 P-01 Configuración de temporada
Objetivo Preparar el marco deportivo y normativo de una temporada.
Inicio y actor iniciador Decisión de crear o configurar una nueva temporada. Inicia un usuario autorizado; participan administración y autoridades según sus facultades.
Entradas Temporada, convocatoria, categorías, grupos y reglas.
Decisiones ¿La regla es explícita? ¿Está sujeta a validación?
Salida Temporada configurada y versionada.
Excepciones Información incompleta; regla no validada (queda pendiente).
Requisitos y casos de uso RF-001 a RF-007; CU-001, CU-002.

Figura 4. P-01 Configuración de temporada, parte A de 2.
Figura 5. P-01 Configuración de temporada, parte B de 2.
#### 4.2.2 P-02 Registro de clubes, equipos y jugadores
Objetivo Mantener la estructura de participantes y el registro de jugadores.
Inicio Alta o modificación de club, equipo o jugador.
Entradas Identificación de la persona, datos administrativos, club, equipo, categoría, temporada y operación solicitada.
Decisiones ¿Datos completos? ¿Registro permitido por las reglas confirmadas? ¿Persona elegible (solo con reglas confirmadas)?

Salida Registro válido o solicitud rechazada con causa; el historial se conserva.
Requisitos y casos de uso RF-008 a RF-014, RF-017, RF-019, RF-020; CU-003, CU-004.
Figura 6. P-02 Registro de clubes, equipos y jugadores (alta y baja básicas) [PROPUESTA].
#### 4.2.3 P-03 Programación manual y publicación
Objetivo Registrar manualmente una programación sin conflictos duros y publicarla tras su aprobación.
Actor iniciador Programador de partidos o usuario autorizado [perfil PENDIENTE].
Entradas Temporada, categoría, grupo, equipos, canchas y disponibilidad.
Decisiones ¿Hay conflicto duro? ¿Requiere ajuste manual autorizado? ¿Está aprobada?
Salidas Programación en borrador o ajustada, o rechazo con el conflicto explicado; programación publicada.
Restricciones duras Equipo duplicado; cancha ocupada; cancha no disponible. La restricción por sanción depende de AMB-001 [PENDIENTE].
Requisitos y casos de uso RF-033, RF-036, RF-039, RF-040, RF-056, RF-090; CU-006, CU-007.

Figura 7. P-03 Programación manual y publicación [PROPUESTA].
#### 4.2.4 P-04 Ciclo de vida del partido
El estado del partido controla las acciones permitidas. Los estados base son BORRADOR → PROGRAMADO → CONFIRMADO → EN JUEGO → FINALIZADO; los estados
alternativos son SUSPENDIDO, CANCELADO, REPROGRAMADO, NO PROGRAMADO y RESUELTO ADMINISTRATIVAMENTE. Los eventos y las transiciones exactas
deben validarse con la Liga [PENDIENTE] (PEN-008), por lo que el diagrama es preliminar. Los estados mínimos de la entrega están pendientes de decisión (Q-13); la columna
«Entrega» de la tabla lo indica.

Figura 8. Estados y transiciones preliminares del partido.
Estado Tipo Implicación Entrega [PROPUESTA]
BORRADOR Principal Se puede preparar información antes de programación definitiva P · E
Probable necesario para preparar la programación.
(Q-13)
PROGRAMADO Principal Existe una asignación de jornada P · E
Probable necesario para publicar la programación.
(Q-13)
CONFIRMADO Principal Programación/partido confirmado P · C
Estados alternativos por definir. (Q-13)
EN JUEGO Principal Partido en ejecución P · C
Estados alternativos por definir. (Q-13)

Estado Tipo Implicación Entrega [PROPUESTA]
FINALIZADO Principal Partido concluyó P · E
Necesario para registrar el resultado. (Q-13)
SUSPENDIDO Alternativo Interrupción que puede requerir reprogramación P · C
Estados alternativos por definir. (Q-13)
P · C
CANCELADO Alternativo Partido no se realizará en la programación vigente
Estados alternativos por definir. (Q-13)
REPROGRAMADO Alternativo Partido cambia de fecha/hora/sede según reglas P · C
Estados alternativos por definir. (Q-13)
NO PROGRAMADO Alternativo Sin programación válida P · C
Estados alternativos por definir. (Q-13)
RESUELTO Alternativo Resultado/estado resuelto fuera del flujo deportivo normal P · C
ADMINISTRATIVAMENTE Estados alternativos por definir. (Q-13)
Reglas del proceso: no se eliminan partidos con historial (RN-020); toda transición registra usuario, fecha y motivo (RN-021); el estado controla las acciones permitidas (RN-019,
VAL-008). Requisitos: RF-043 a RF-046.
#### 4.2.5 P-05 Registro de resultado y actualización de tabla
Inicio y actor Partido finalizado con resultado disponible. Actúa un usuario autorizado.
Entradas Marcador, estado y datos oficiales disponibles.
Decisiones ¿Resultado validado? ¿Es una corrección? ¿Hay empate en la clasificación?
Salida Resultado oficial y tabla actualizada; se conserva el histórico.
Requisitos y casos de uso RF-047 a RF-050, RF-052, RF-053, RF-055, RF-056; CU-008, CU-009.

Figura 9. P-05 Registro de resultado y actualización de tabla, parte A de 2.

Figura 10. P-05 Registro de resultado y actualización de tabla, parte B de 2.
#### 4.2.6 P-06 Disciplina reducida (pendiente de decisión)
Flujo reducido [PENDIENTE] Solo si se valida: un usuario autorizado registra manualmente un incidente y lo relaciona con la persona o el equipo; una autoridad competente registra la resolución y su vigencia; el
sistema conserva la resolución sin alteración destructiva.
Separación de funciones La captura (capturista) está separada de la resolución (autoridad competente), DD-010; aplica solo si se valida la disciplina reducida (Q-05).
Decisiones ¿La autoridad registra la resolución? ¿Está definido el alcance de la sanción?
Alcance de la sanción Sobre si afecta la participación, la programación o ambas hay una ambigüedad abierta (AMB-001).
Requisitos y casos de uso RF-057, RF-058, RF-062, RF-063, RF-065; CU-010, CU-011.

Figura 11. P-06 Disciplina reducida y condicionada [PROPUESTA]; solo si se valida (Q-05).
#### 4.2.7 P-09 Flujo de publicación del portal
La información pública sigue el flujo Borrador → Revisión → Publicado. En la entrega aplica a la programación, los resultados y la tabla. Solo se publica información validada (RN-
025). El flujo exacto de revisión (quién crea y quién aprueba) está por definir [PENDIENTE] (PEN-009, Q-07). Requisitos: RF-056, RF-082 a RF-084, RF-089, RF-090; CU-007,
CU-016.
Figura 12. Estados de publicación de la información del portal.
### 4.3 Modelo de datos conceptual
Modelo conceptual preliminar. Las entidades de la tabla provienen de la fuente, salvo las marcadas como [PROPUESTA], que son entidades auxiliares o nombres deducidos del flujo
para normalizar el modelo. Las cardinalidades se presentaron como hipótesis y deben validarse antes del diseño lógico (AMB-005). Los atributos exactos están por definir (véase 3.4).

Entidad Propósito Atributos conocidos Origen Entrega [PROPUESTA]
Persona Identidad reutilizable Datos de identidad/administrativos; detalles exactos Definida en la fuente S · E
[PENDIENTE] Atributos mínimos.
Club Entidad afiliada Identificación del club; detalle [PENDIENTE] Definida en la fuente I · E
Equipo Representación deportiva de club Club, categoría, grupo, temporada Definida en la fuente I · E
Temporada Periodo deportivo Periodo; convocatoria asociada Definida en la fuente I · E
Convocatoria Documento normativo de temporada Documento/contenido normativo Definida en la fuente S · C
Referencia/versión de reglas.
Categoría Nivel/categoría deportiva Nombre; contexto de temporada Definida en la fuente I · E
Grupo Agrupación dentro de categoría Identificación del grupo Definida en la fuente I · E
Competencia/Fase Estructura de competencia y fase Tipo/fase/formato; detalle [PENDIENTE] Definida en la fuente P · C
¿Necesaria para tabla y partidos? (Q-14)
Partido Unidad competitiva Local/visitante, fecha/hora, estado, cancha, competencia, Definida en la fuente I · E
incidencias
Cancha Recurso físico Características, disponibilidad, bloqueo/mantenimiento Definida en la fuente I · E
Incidente Hecho disciplinario Participantes, evidencia, presunta infracción Definida en la fuente P · C
Solo si se valida disciplina.
Resolución Determinación de autoridad Decisión, vigencia; detalle [PENDIENTE] [PROPUESTA] entidad auxiliar o nombre P · C
deducido Solo si se valida disciplina.
Sanción Consecuencia disciplinaria Vigencia, estado, relación con regla Definida en la fuente P · C
Solo si se valida disciplina.
Resultado Marcador/resultado oficial Marcador, estado; detalle [PENDIENTE] Definida en la fuente I · E
Programación Organización de jornada/partidos Fecha, hora, cancha/sede, estado Definida en la fuente S · E
Jornada/partidos manuales.
Usuario Cuenta de acceso Credenciales/estado; detalle [PENDIENTE] Definida en la fuente I · E
Rol Conjunto de permisos Nombre y permisos Definida en la fuente I · E
Pocos perfiles.
Registro de jugador Relación persona-equipo-temporada Persona, equipo, categoría, temporada, estado, historial [PROPUESTA] entidad auxiliar o nombre S · E
deducido Alta/baja y estado.
Disponibilidad de cancha Disponibilidad temporal Cancha, fecha/hora, estado [PROPUESTA] entidad auxiliar o nombre S · E
deducido Mínima.
Auditoría Trazabilidad de acciones Usuario, fecha, acción, motivo/contexto [PROPUESTA] entidad auxiliar o nombre S · E
deducido Mínima.
Permiso Autorización por módulo/acción Módulo, acción [PROPUESTA] entidad auxiliar o nombre S · E
deducido Matriz mínima pendiente.

Relaciones principales. Todas las cardinalidades están por validar.
Origen Relación Destino Cardinalidad Estado Entrega [PROPUESTA]
Club tiene Equipo por temporada 1:N [PENDIENTE] validar I · E
Equipo pertenece a Categoría/Grupo N:1 [PENDIENTE] validar I · E
Equipo registra Persona N:M mediante Registro [PENDIENTE] validar S · E
Registro de jugador como relación.
Partido pertenece a Competencia/Fase N:1 [PENDIENTE] validar P · C
Si se valida Competencia/Fase (Q-14).
Partido usa Cancha N:1 [PENDIENTE] validar I · E
Partido tiene Resultado 1:1 cuando finaliza [PENDIENTE] validar I · E

Figura 13. Modelo entidad-relación preliminar de la entrega. Las cardinalidades están [PENDIENTE] (AMB-005).
Varias entidades del diagrama (REGISTRO_JUGADOR, ROL_USUARIO y PERMISO) son relaciones o entidades auxiliares [PROPUESTA]; sus nombres y cardinalidades deben
validarse. Incidente, Resolución y Sanción solo se modelan si se valida la disciplina reducida (Q-05), y Competencia/Fase solo si se valida (Q-14). La relación del Incidente con el
Partido sigue [PENDIENTE].

### 4.4 Estructura modular y arquitectura conceptual
Figura 14. Descomposición modular de la entrega (M-01 a M-04, M-06 a M-08, M-11; M-09 pendiente). No se exige una interfaz o servicio independiente por módulo.
Directrices arquitectónicas de la entrega [PROPUESTA]: aplicación web responsive; backend modular y una sola aplicación; base de datos relacional; separación lógica entre interfaz,
reglas de la demostración, autorización y datos; y un componente lógico de validación de conflictos de programación. No se incluyen API pública, integraciones, almacenamiento
documental, CI/CD ni contenedores. Que el frontend sea separado o integrado es una decisión abierta. El stack y la arquitectura deben ser justificados por el equipo.

Figura 15. Arquitectura conceptual de la entrega [PROPUESTA]: una aplicación modular y una base de datos relacional. El stack y el despliegue siguen [PENDIENTE] (PEN-024 a PEN-026, PEN-
036, PEN-037).
Propuestas de diseño del análisis (R3 §18.2). No son requisitos de la fuente y deben justificarse antes de adoptarse:
ID Propuesta Motivo Estado Entrega [PROPUESTA]
DP-001 Mantener módulos de dominio desacoplados dentro del backend Reduce acoplamiento y facilita evolución [PROPUESTA] I · C
DP-002 Versionar explícitamente reglas de temporada Alineado con trazabilidad normativa [PROPUESTA] S · C
Referencia de reglas por temporada.
DP-003 Diseñar una máquina de estados de partido El estado controla acciones y auditoría [PROPUESTA] I · E
DP-004 Tratar Programación como entidad/documento de jornada Facilita histórico, publicación y trazabilidad [PROPUESTA] I · C
además de los partidos
DP-005 Mantener un módulo lógico específico para la validación de La programación es manual; el problema se reduce a validar [PROPUESTA] S · C
conflictos de programación conflictos duros Módulo lógico de validación; el generador se
aplaza.
DP-006 Separar datos publicados de datos internos a nivel de aplicación Reduce exposición accidental [PROPUESTA] I · E
y autorización

Decisiones arquitectónicas pendientes [PENDIENTE]: stack de frontend; stack de backend; motor de base de datos relacional; estrategia de autenticación y sesión; frontend separado
o integrado; y entornos y alojamiento de la demostración (PEN-024 a PEN-026, PEN-030, PEN-036, PEN-037).
### 4.5 Flujo de información
Flujo por operación. Entrada del usuario → interfaz → validación de formato y permisos → reglas de negocio → procesamiento del módulo → persistencia transaccional → auditoría
→ resultado → publicación (solo cuando corresponda).
Flujo público. Datos internos → validación y autorización → estado publicado → portal público → consulta del usuario. No existe flujo inverso desde el portal para editar información.
Trazabilidad de la entrega. Temporada → Categoría → Grupo → Equipo → Jornada/Partido → Resultado → Tabla → Publicación. Cada cambio crítico conserva usuario, fecha y
motivo. Si se valida la disciplina, se añade Incidente → Resolución → Sanción [PENDIENTE].
### 4.6 Matriz de trazabilidad
La trazabilidad se presenta a nivel funcional. En el diseño detallado, cada requisito deberá vincularse además con historias de usuario, pruebas y criterios de aceptación específicos.
Requisitos Casos de uso Proceso Módulo Pantalla Entidades
Entrega
[PROPUEST
A]
RF-001 a RF-007 P-01 M-02 S · E
CU-001, CU- UI-003, UI- Temporada,
002 004 Convocatoria, Categoría,
Grupo
RF-008 a RF-012 CU-003 P-02 M-03 UI-005 Club, Equipo, Persona S · E
CU-004 P-02 M-04 UI-006
RF-013, RF-014; RF-017, Persona, Registro de S · E (P para
RF-019, RF-020 jugador, Equipo, RF-017, 019,
[PENDIENTE] Temporada 020)
RF-027, RF-029, RF-030 CU-005 P-03 M-06 UI-008 Cancha, Disponibilidad S · E
de cancha
RF-033, RF-036, RF-039, CU-006 P-03 M-07 UI-009 Programación, Partido, S · E
RF-040 Equipo, Cancha
RF-043 a RF-046 CU-008 P-04 M-08 UI-010 Partido, estado, Auditoría S · E
RF-047 a RF-050, RF- CU-008, CU- P-05 M-08 UI-011, UI- Resultado, Partido, I · E (RF-050
052, RF-053, RF-055, 009 012 Equipo pendiente)
RF-056
RF-056, RF-082 a RF- CU-007, CU- P-09 M-11 UI-020 Datos publicados de I · E
084, RF-089, RF-090 016 programación, resultados
y tabla

Requisitos Casos de uso Proceso Módulo Pantalla Entidades Entrega
[PROPUEST
A]
RF-093 Transversal M-01 Auditoría S · E
Transvers UI-022
[PENDIEN
TE]
RF-057, RF-058, RF-062, CU-010, CU- P-06 M-09 UI-015 Incidente, Resolución, P · C
RF-063, RF-065 011 Sanción
[PENDIENTE]
Trazabilidad [PROPUESTA]. La matriz cubre solo lo que forma parte de la entrega. Los requisitos aplazados y sus casos de uso, pantallas y entidades se listan en 2.6.

## Apéndice A. Pendientes por definir
Nota de la revisión 0.3 [PROPUESTA]. Los pendientes se conservan con su identificador. La columna
«Relación con la entrega» indica si el pendiente aplica a la entrega o a lo que queda fuera (2.6). Las
preguntas nuevas están en el Apéndice C.
Información faltante que debe definirse antes de convertir los elementos relacionados en requisitos
definitivos. Se conservan los identificadores PEN de la fuente.
Requisitos
ID Pendiente Por qué debe definirse
Quién debería Relación con la entrega
aclararlo [PROPUESTA]
Prioridad formal de cada requisito Equipo/cliente/profesor Aplica a la entrega
PEN- Permite ordenar backlog y
001 entregas
Alcance exacto de cada actor Evita permisos incorrectos Liga / autoridades Aplica a la entrega
PEN-
002
Liga Fuera del alcance (2.6)
PEN- Requisitos de importación de Afecta modelo y
003 datos históricos migración
Liga Aplica a la entrega
PEN- Qué operaciones son obligatorias Define validaciones y
004 por temporada flujos
Procesos
ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
Aplica a la entrega
PEN- Quién crea y quién aprueba Define separación de Liga
005 programación funciones
Aplica a la entrega
PEN- Qué es obligatorio antes de Define precondiciones del Liga
006 programar algoritmo
Aplica a la entrega
PEN- Qué ocurre formalmente al bloquear Define reprogramación y Liga
007 una cancha conflictos
Aplica a la entrega
PEN- Qué sucede ante una Define estados y Liga
008 suspensión/cancelación transiciones reales
Aplica a la entrega
PEN- Flujo exacto de publicación/revisión Define gobernanza del portal Liga
009
Usuarios y permisos
ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
PEN- Matriz rol → módulo → acción Es necesaria para Liga Aplica a la entrega
010 implementar RBAC
PEN- Facultades exactas del Comité El modelo organizacional Liga Aplica a la entrega
011 Ejecutivo, Secretaría, Tesorería y requiere facultades
comisiones explícitas
Fuera del alcance (2.6)
PEN- Acciones permitidas a Define alcance de Liga
012 presidente/delegado de club autoservicio
Fuera del alcance (2.6)
PEN- Acciones permitidas al jugador Define participación directa Liga
013 o sólo consulta
Interfaz
ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
PEN- Prototipo y navegación final Reduce retrabajo de Equipo + cliente Aplica a la entrega
014 desarrollo
PEN- Campos obligatorios por formulario Define validaciones Liga Aplica a la entrega
015 concretas
Borrador para seguimiento · Octubre de 2026
Descripción de requisitos del software

ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
Aplica a la entrega
PEN- Mensajes de error/bloqueo Necesarios para UX y Equipo + Liga
016 soporte
Aplica a la entrega
PEN- Diseño final de estados de Evita mostrar datos no Liga
017 publicación oficiales
Base de datos
ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
PEN- Identificadores oficiales y claves Evita duplicados y Liga + equipo Aplica a la entrega
018 ambigüedad
PEN- Atributos de persona/jugador Define protección de datos y Liga Aplica a la entrega
019 formularios
PEN- Estructura detallada de cédula e Es núcleo del módulo Liga / árbitros Fuera del alcance (2.6)
020 incidentes disciplinario
PEN- Catálogo de artículos, infracciones y Necesario para motor de Liga Fuera del alcance (2.6)
021 sanciones reglas disciplinarias
PEN- Modelo definitivo de disponibilidad Crítico para programación Liga Aplica a la entrega
022 de canchas
PEN- Estructura de documentos/evidencias Afecta almacenamiento Liga Fuera del alcance (2.6)
023 documental
Arquitectura
ID Pendiente Por qué debe definirse
Quién debería Relación con la entrega
aclararlo [PROPUESTA]
PEN- Stack tecnológico Requisito para prototipos e Equipo Aplica a la entrega
024 implementación
PEN- Frontend separado o integrado Afecta despliegue y Equipo Aplica a la entrega
025 arquitectura
PEN- Base de datos concreta Afecta persistencia y Equipo Aplica a la entrega
026 despliegue
PEN- Estrategia del motor de reglas Afecta mantenibilidad y Equipo Fuera del alcance (2.6)
027 pruebas
PEN- Algoritmo de programación Es un problema técnico Equipo + Fuera del alcance (2.6)
028 central validación con
reglas reales
Seguridad
ID Pendiente Por qué debe definirse
Quién debería Relación con la entrega
aclararlo [PROPUESTA]
Matriz de permisos detallada Liga Aplica a la entrega
PEN- Sin ella no se puede
029 implementar autorización
correctamente
PEN- Políticas de sesiones/contraseñas Convierte seguridad general Equipo Aplica a la entrega
030 en controles verificables
PEN- Política de respaldo/recuperación Define continuidad Liga + equipo Aplica a la entrega
031 operativa
PEN- Datos públicos vs restringidos Evita exposición de Liga Aplica a la entrega
032 información
personal/disciplinaria
Integraciones
ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
PEN- Integraciones realmente necesarias Evita sobrecoste y Liga + equipo Fuera del alcance (2.6)
033 dependencia innecesaria
Borrador para seguimiento · Octubre de 2026
Descripción de requisitos del software

ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
Fuera del alcance (2.6)
PEN- Proveedor y presupuesto de Afecta factibilidad Liga
034 WhatsApp/SMS/correo
Fuera del alcance (2.6)
PEN- Necesidad real de mapas/API Afecta alcance Liga + equipo
035 pública/autenticación externa
Infraestructura
ID Pendiente Por qué debe definirse Quién debería Relación con la entrega
aclararlo [PROPUESTA]
PEN- Ambiente de Necesario para despliegue Equipo Aplica a la entrega
036 desarrollo/pruebas/producción controlado
PEN- Dominio/hosting/infraestructura Necesario para despliegue Liga + equipo Aplica a la entrega
037 funcional
PEN- Estrategia CI/CD y contenedores Necesaria sólo si se adopta Equipo Fuera del alcance (2.6)
038
Borrador para seguimiento · Octubre de 2026
Descripción de requisitos del software

## Apéndice B. Ambigüedades, riesgos y verificación
de fuentes
Ambigüedades abiertas
ID Ambigüedad Impacto
AMB-001 Alcance de la sanción: participación, programación o ambas Afecta reglas, UI, programación y BD
AMB-002 Qué resultado se considera oficial Afecta tablas y publicación
AMB-003 Qué elementos pueden publicarse Afecta privacidad y portal
AMB-005 Cardinalidades de datos preliminares Afecta modelo ER
AMB-006 Permisos exactos por cargo/comisión Afecta seguridad y procesos
Riesgos identificados
ID Riesgo Impacto Mitigación
RSK-001 Automatización incorrecta
Reglas pueden requerir Versionado, validación humana y
interpretación autorización
RSK-002 Diseño rígido Configuración versionable
Convocatorias cambian por
temporada
RSK-003 Datos históricos no estructurados Migración/duplicados Catálogos, identificadores, validación
RSK-005 Disciplina exige trazabilidad
Riesgo de perder evidencia o Modelo de expediente + auditoría +
contexto historial inmutable
RSK-006
Automatización incorrecta por mala Decisiones Validación humana y pruebas con casos
parametrización deportivas/disciplinares erróneas reales
RSK-007 Exposición de datos personales Riesgo de privacidad
Separar datos internos/públicos y
permisos explícitos
RSK-008 Retraso del desarrollo
Demasiadas decisiones técnicas Cerrar arquitectura durante sprint de
abiertas arquitectura
Contradicciones y verificación del audio
Nota de la revisión 0.3. AMB-004 (excepciones en reglas) y RSK-004 (programación como problema
de restricciones) se retiraron de las tablas porque corresponden a funciones fuera del alcance de la entrega
(2.6).
En el contenido textual de R1 no se identifica ninguna contradicción explícita entre las definiciones
centrales. Sí existen varios puntos deliberadamente abiertos que no deben resolverse por suposición.
El audio del levantamiento (R2) no pudo transcribirse de forma confiable. Antes de cerrar el ERS deben
comprobarse las respuestas dadas verbalmente y registrar como contradicción cualquier respuesta que
difiera de estas definiciones [PENDIENTE].
## Apéndice C. Preguntas pendientes para el equipo,
el profesor y la Liga
Estas preguntas bloquean o condicionan decisiones de alcance. Mientras no se respondan, los elementos
relacionados conservan estado P (pendiente) o se mantienen fuera de la entrega. «Quién» indica quién
debería responder [PROPUESTA].
ID Tema Pregunta Elementos afectados Quién Estado
Q-01 Renovación y ¿Son obligatorias para la evaluación o para la RF-015, RF-016, VAL- Profesor / Abierta
transferencia de operación real? Si lo son, ¿cuál es la regla 001, M-04 Liga
jugadores vigente de la Liga?
Borrador para seguimiento · Octubre de 2026
Descripción de requisitos del software

ID Tema Pregunta Elementos afectados Quién Estado
Q-02 Alcance que ¿El entregable académico exige implementar Todo el alcance de Profesor Abierta
exige la rúbrica todo el alcance del ERS o basta una versión entrega
acotada y demostrable? ¿Qué funciones exige
explícitamente la rúbrica (se necesita la rúbrica
por escrito)?
Q-03 Abierta
Reglamento y ¿El Reglamento y la Convocatoria 2025–2026 RF-002, RF-006, RF- Liga /
Convocatoria estarán disponibles y validados para el equipo? 007, RN-002, R4 Profesor
como fuente Sin ellos no se fijan reglas oficiales de puntos,
desempates, registro, sanciones ni ascensos.
Q-04 Programación ¿Es obligatoria en la evaluación? Si sí, ¿basta RF-034, RF-035, RF- Profesor Abierta
automática una primera versión que genere 037, RF-038, RF-041,
enfrentamientos o debe asignar fechas, horas y RF-042, CU-006, P-03
canchas?
Q-05 Disciplina en el ¿Debe aparecer? Si sí, ¿basta con registrar RF-057–RF-068, CU- Profesor / Abierta
producto manualmente incidencias y resoluciones o se 010, CU-011, P-06, M- Liga
demostrable 09
piden cédulas, expediente, recursos, evidencias
y castigados? ¿Qué campos son
indispensables?
Q-06 Arbitraje y ¿Basta con asignar un árbitro como dato del RF-021–RF-026, CU- Profesor / Abierta
cédula partido y registrar una incidencia textual? ¿Se 010, UI-007, UI-014 Liga
exige catálogo, disponibilidad y cédula?
Q-07 Matriz mínima ¿Quién puede registrar y quién puede aprobar o RF-040, RF-090, DD- Liga / Abierta
de permisos publicar programación, resultados y sanciones? 009, RNF-003, PEN- Profesor
¿Qué perfiles se usarán en la demostración? 005, PEN-010
Q-08 Datos de ¿Qué información de jugadores puede RNF-012, AMB-003, Liga / Abierta
jugadores y almacenar y publicar el prototipo? ¿Deben ser PEN-019, PEN-032 Profesor
privacidad datos ficticios? ¿Qué datos son públicos?
Q-09 Integraciones, ¿Se requiere carga histórica, notificaciones, Integraciones, RF-092, Profesor / Abierta
Liga
importación, exportación o alojamiento accesible en REP-011, PEN-003,
internet? Hoy son dependencias no resueltas. PEN-037
exportación y
alojamiento
Q-10 Abierta
Reglas de ¿Qué puntuación y criterios de desempate se RF-049, RF-050, RN- Liga /
demostración: usarán en la demostración? Si no son oficiales, 023, VAL-011 Profesor
puntos y deben rotularse como datos de demostración.
desempates
Q-11 Temporada, ¿Cuál temporada, categoría y grupo se usarán y RF-001, RF-004, RF- Profesor / Abierta
categoría y qué datos pueden usarse (reales autorizados o 005, CU-001 Liga
grupo de ficticios)?
demostración
Q-12 Resultado ¿Qué se considera resultado oficial y cuándo se AMB-002, RF-048, Liga Abierta
oficial vuelve oficial? RF-055, VAL-009
Q-13 Estados ¿Qué estados y transiciones se usarán RF-043, P-04, PEN- Liga Abierta
(suspensión, cancelación, pospuesto)? 008
mínimos del
partido
Q-14 Abierta
Competencia/Fa ¿Debe existir la entidad Competencia/Fase en Entidad Equipo /
se en el modelo la entrega o basta temporada–categoría–grupo? Profesor
Competencia/Fase, RF-
076
Q-15 Auditoría Abierta
¿Se requiere una pantalla de consulta de RF-093, UI-022, REP- Profesor /
auditoría o basta registrar las acciones críticas? 010, VAL-016 Equipo
Q-16 Liga Abierta
Reglas de ¿Qué reglas de registro y bloqueo están RF-017, RF-019, RN-
elegibilidad confirmadas por la Liga? 009, RN-010, VAL-
002, CA-006
Q-17 AMB-001: ¿La sanción afecta participación, programación RF-064, RF-020, RN- Liga Abierta
alcance de la o ambas? 011, RN-015, VAL-
sanción 006, CA-004
Q-18 Ascensos, ¿Se piden en la evaluación? Si no, ¿se registra RF-069–RF-081, CU- Profesor / Abierta
descensos y el cierre fuera del sistema? ¿Cuáles son las 014, CU-015, P-07, P- Liga
fases finales reglas y el formato? 08
Q-19 Valores ¿Qué metas medibles (disponibilidad, RNF-001, 002, 008, Equipo / Abierta
cuantitativos de rendimiento, accesibilidad, respaldo) acepta el 010, 011 Profesor
los RNF equipo verificar y en qué entorno?
Borrador para seguimiento · Octubre de 2026
Descripción de requisitos del software

ID Tema Pregunta Elementos afectados Quién Estado
Q-20 Roles de Scrum ¿Pueden combinarse responsabilidades de Sección 1.2 Equipo / Abierta
y revisión Scrum, análisis, arquitectura, desarrollo y Profesor
pruebas? ¿Quién revisa código e integración?
Q-21 RNF-006 y ¿Qué criterio medible tendrán la usabilidad y la RNF-006, RNF-009 Equipo Abierta
RNF-009 mantenibilidad?
Q-22 Tabla de En el registro de aprobaciones el nombre del Registro de Equipo Abierta
aprobaciones profesor aparece también como representante aprobaciones, 1.2
de la Liga. ¿Quién es el representante de la
Liga? No se corrigió por suposición.
Q-23 Audio R2 y ¿Quién verificará el audio del levantamiento y R2, R4, Apéndice B Equipo Abierta
fuentes R4 consultará el Reglamento y la Convocatoria
directamente?
Q-24 Calendario y ¿Las 10 semanas son el calendario aplicable? Sección 2.4, plan Profesor Abierta
entregables ¿Qué se evaluará (ERS, BPMN, arquitectura,
prototipo, sistema desplegado, pruebas)? ¿Hay
hitos o fechas de entrega?
## Apéndice D. Supuestos inevitables [PROPUESTA]
Los siguientes supuestos son necesarios para poder proponer el alcance de entrega. Son propuestas
pendientes de aprobación, no requisitos aprobados.
ID Supuesto Relacionado con
S-01 El calendario aplicable es de 10 semanas con un equipo de tres personas (2.4). Q-24
S-02 La entrega cubre una temporada de trabajo y una categoría/grupo de demostración. Q-11
S-03 Se usan datos ficticios o autorizados y reglas de puntos y desempates de demostración rotuladas Q-03, Q-08, Q-10
como no oficiales mientras no haya fuente validada.
S-04 Los perfiles se reducen a administración, operación, disciplina (condicional) y público, con Q-07
nombres y permisos pendientes.
S-05 La arquitectura es una aplicación modular única con base de datos relacional; el stack y el PEN-024 a 026
despliegue son decisión técnica del equipo.
S-06 La prioridad de entrega (E/C/O) es una propuesta; la prioridad de producto (Alta/Media/Baja) no Q-02
cambia.
S-07 La auditoría mínima cubre acciones críticas: cambios de programación, resultado y corrección, Q-15
transiciones de estado del partido y publicación; el contenido exacto está pendiente.
S-08 La disciplina solo se incluye como registro manual acotado si se valida; en caso contrario queda Q-05
fuera de la entrega.
S-09 No se presume que el uso de IA reduzca el esfuerzo de análisis, integración, pruebas o —
mantenimiento.
S-10 Mientras no se definan los estados mínimos del partido se mantienen los de la fuente como Q-13
preliminares.
S-11 Lo que queda fuera se conserva solo por identificador en 2.6, para trazabilidad. —
