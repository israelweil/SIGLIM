> [!CAUTION]
> **DOCUMENTO REEMPLAZADO por el ERS Rev. 0.4** ([`../ERS.md`](../ERS.md)). Se conserva como evidencia.

> [!NOTE]
> **ERS Rev. 0.3 (alcance de entrega acotado)** convertido desde el documento de Word, con las tablas
> de RF, RNF, RN, CU y apéndices conservadas. Los bloques `<!-- Start of picture text -->` marcan
> imágenes (logotipo y diagramas). Los procesos BPMN (P-xx) están en [`bpmn/`](../bpmn/).
> La versión anterior de este archivo, extraída del PDF, está en [`ERS-rev0.3-extraido-de-pdf.md`](ERS-rev0.3-extraido-de-pdf.md).
>
> **Sincronización (19-oct-2026):** se incorporaron las ediciones que el equipo hizo en el PDF entregado
> (nombre SIGLIM, registro de aprobaciones, aprobación del personal, perfiles de los usuarios y ligas a
> Figma y SharePoint). El encabezado del PDF decía «Rev. 1.3»; se conserva **0.3**, que es la numeración
> del historial de revisiones. Las decisiones posteriores al levantamiento están en
> [`decisiones/registro-de-decisiones.md`](../decisiones/registro-de-decisiones.md) y se integrarán en la Rev. 0.4.

# **Especificación de requisitos de software** 

**Proyecto: SIGLIM — Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia** Revisión 0.3 (alcance de entrega acotado) 

Estado: borrador para seguimiento académico (sin aprobación formal); alcance de entrega propuesto, pendiente de validación 



<!-- Start of picture text -->
Logo<br><!-- End of picture text -->

Octubre de 2026 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 2 

## **Control del documento** 

#### **Información del documento** 

|**Proyecto**|Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia.<br>Nombre definitivo del proyecto: **SIGLIM**.|
|---|---|
|**Documento**|Especificación de requisitos de software (ERS), estructurada según IEEE<br>Std 830-1998.|
|**Revisión**|0.3 (alcance de entrega acotado). Versiones previas: 0.1 y 0.2.|
|**Fecha**|Octubre de 2026|
|**Elaborado por**|López Meza Leonardo, por encargo del equipo de trabajo (véase 1.2).|
|**Seguimiento**|Profesor de Fundamentos de Ingeniería de Software. Nombre:Claudio<br>Ernesto Florian Arenas|
|**Estado**|Borrador para seguimiento. Los requisitos aún no han sido aprobados por<br>la Liga ni validados formalmente; el documento se actualizará durante el<br>semestre.La revisión 0.3 acota el documento a la entrega propuesta<br>para un equipo de tres personas; ese alcance no está aprobado por<br>la Liga, el profesor ni el equipo.|



#### **Historial de revisiones** 

|**Revisión**|**Fecha**|**Autor**|**Descripción**|
|---|---|---|---|
|0.1|Octubre de 2026|López Meza Leonardo|Primera versión. Se organiza la<br>documentación técnica base de la Liga<br>en la estructura IEEE 830, con<br>prioridades propuestas y pendientes<br>señalados.|
|0.2|Octubre de 2026|López Meza Leonardo|Etiquetado de estado y prioridad de<br>entrega sobre el contenido integral<br>(versión intermedia).|
|0.3|Octubre de 2026|López Meza Leonardo|Reducción del documento al alcance<br>de entrega propuesto: se retiran del<br>cuerpo, casos de uso, procesos,<br>modelos y criterios las funciones<br>aplazadas; se agrega la sección 2.6<br>«Fuera del alcance de esta entrega» y<br>las preguntas y supuestos pendientes<br>(Apéndices C y D). Propuesta<br>pendiente de validación.|



#### **Registro de aprobaciones** 

|**Parte**|**Nombre**|**Fecha**|**Estado**|
|---|---|---|---|
|Representante de la Liga Municipal<br>(cliente)|Claudio Ernesto Florian<br>Arenas|**[PENDIENTE]**|Sin aprobar|
|Profesor de Fundamentos de<br>Ingeniería de Software|Claudio Ernesto Florian<br>Arenas|07/10/26|Aprobado<br>parcialmente|
|Equipo de desarrollo|Olvera Bucio Jose Israel;<br>Olvera Lobato David Geovani;<br>López Meza Leonardo|07/10/26|Aprobado<br>parcialmente|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 3 

#### **Convenciones de este documento** 

|**Marca**|**Significado**|
|---|---|
|**[PENDIENTE]**|Dato o decisión aún no definido o por confirmar. No debe tomarse como<br>requisito aprobado. El detalle de cada pendiente está en el Apéndice A.|
|**[PROPUESTA]**|Propuesta del equipo que requiere validación. En este documento se aplica,<br>sobre todo, a las prioridades de los requisitos y a las entidades, pantallas y<br>asignaciones de carril que no vienen de la fuente.|
|Sin marca|Contenido respaldado por las fuentes del proyecto (R1 y R3, véase 1.4). Aun<br>así sigue sujeto a validación con la Liga, como indica la propia fuente.|
|Identificadores|Se conservan los de la fuente: RF (requisito funcional), RNF (no funcional), RN<br>(regla de negocio), CU (caso de uso), P (proceso), M (módulo), UI (pantalla),<br>VAL (validación), REP (reporte), CA (criterio de aceptación), DD y DP<br>(decisiones y propuestas de diseño), PEN, AMB y RSK (pendientes,<br>ambigüedades y riesgos).|
|Estado de entrega (I, S,<br>P)|**[PROPUESTA]**Disposición de cada elemento retenido en la entrega: I Incluido, S<br>Simplificado, P Pendiente de decisión. Lo aplazado (A) solo aparece en 2.6.|
|Prioridad de entrega (E,<br>C, O)|**[PROPUESTA]**Esencial, Conveniente u Opcional para esta entrega; independiente de la<br>prioridad de producto (Alta/Media/Baja).|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 4 

## **Contenido** 

|1 Introducción.................................................................................................................................6|
|---|
|1.1 Alcance.................................................................................................................................6|
|1.2 Personal involucrado............................................................................................................6|
|1.3 Definiciones, acrónimos y abreviaturas................................................................................7|
|1.4 Referencias...........................................................................................................................8|
|1.5 Visión general del documento..............................................................................................8|
|2 Descripción general.....................................................................................................................9|
|2.1 Perspectiva del producto......................................................................................................9|
|2.2 Funcionalidad del producto...................................................................................................9|
|2.3 Características de los usuarios..........................................................................................10|
|2.4 Restricciones......................................................................................................................11|
|2.5 Suposiciones y dependencias............................................................................................11|
|2.6 Fuera del alcance de esta entrega [PROPUESTA]............................................................12|
|3 Requisitos específicos...............................................................................................................14|
|3.1 Requisitos comunes de los interfaces................................................................................14|
|3.1.1 Interfaces de usuario....................................................................................................14|
|3.1.2 Interfaces de hardware................................................................................................15|
|3.1.3 Interfaces de software..................................................................................................15|
|3.1.4 Interfaces de comunicación.........................................................................................15|
|3.2 Requisitos funcionales........................................................................................................16|
|3.2.1 Gestión de temporadas, convocatorias y configuración deportiva..............................16|
|3.2.2 Clubes, equipos y personas.........................................................................................17|
|3.2.3 Registro y elegibilidad de jugadores............................................................................17|
|3.2.4 Canchas y sedes..........................................................................................................18|
|3.2.5 Programación...............................................................................................................18|
|3.2.6 Partidos y ciclo de vida................................................................................................19|
|3.2.7 Resultados, tablas y estadísticas.................................................................................19|
|3.2.8 Disciplina reducida (pendiente de decisión)................................................................20|
|3.2.9 Portal público y auditoría..............................................................................................21|
|3.2.10 Validaciones y manejo de errores..............................................................................21|
|3.2.11 Consultas y listados requeridos.................................................................................22|
|3.3 Requisitos no funcionales...................................................................................................23|
|3.3.1 Requisitos de rendimiento............................................................................................23|
|3.3.2 Seguridad.....................................................................................................................23|
|3.3.3 Fiabilidad......................................................................................................................24|
|3.3.4 Disponibilidad...............................................................................................................24|
|3.3.5 Mantenibilidad..............................................................................................................25|
|3.3.6 Portabilidad..................................................................................................................25|
|3.3.7 Usabilidad y accesibilidad............................................................................................25|
|3.4 Otros requisitos...................................................................................................................26|
|3.4.1 Reglas de negocio.......................................................................................................26|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 5 

|3.4.2 Requisitos de datos......................................................................................................28|
|---|
|3.4.3 Criterios de aceptación preliminares............................................................................28|
|3.4.4 Requisitos legales y normativos..................................................................................29|
|4 Modelado del Sistema...............................................................................................................30|
|4.1 Modelo de casos de uso.....................................................................................................30|
|4.2 Modelo de procesos (BPMN)..............................................................................................33|
|4.2.1 P-01 Configuración de temporada...............................................................................33|
|4.2.2 P-02 Registro de clubes, equipos y jugadores............................................................34|
|4.2.3 P-03 Programación manual y publicación...................................................................35|
|4.2.4 P-04 Ciclo de vida del partido......................................................................................36|
|4.2.5 P-05 Registro de resultado y actualización de tabla...................................................38|
|4.2.6 P-06 Disciplina reducida (pendiente de decisión)........................................................39|
|4.2.7 P-09 Flujo de publicación del portal.............................................................................40|
|4.3 Modelo de datos conceptual...............................................................................................41|
|4.4 Estructura modular y arquitectura conceptual....................................................................44|
|4.5 Flujo de información...........................................................................................................46|
|4.6 Matriz de trazabilidad..........................................................................................................46|
|Apéndice A. Pendientes por definir..............................................................................................48|
|Apéndice B. Ambigüedades, riesgos y verificación de fuentes...................................................51|
|Apéndice C. Preguntas pendientes para el equipo, el profesor y la Liga....................................51|
|Apéndice D. Supuestos inevitables [PROPUESTA]....................................................................53|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 6 

## **1 Introducción** 

Este documento es la Especificación de Requisitos de Software (ERS) del **Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia** . Describe qué debe hacer el sistema y bajo qué restricciones, sin definir todavía cómo se implementará. Está estructurado según IEEE Std 830-1998 y sigue la plantilla de ERS del curso. 

Está dirigido al equipo de desarrollo, que lo usará como base para el diseño, el backlog y las pruebas; al profesor de Fundamentos de Ingeniería de Software, que da seguimiento al proyecto durante el semestre; y a los representantes de la Liga, que deberán validar los requisitos, los procesos y las reglas en caso de ser lanzada al público. 

El proyecto es real y el documento es de seguimiento. Se actualizará conforme se definan nuevos detalles. Por eso se conserva la información respaldada por las fuentes, se señalan con **[PENDIENTE]** los aspectos por definir y se marcan con **[PROPUESTA]** las sugerencias del equipo, de modo que ninguna suposición se presente como requisito aprobado. Esta revisión especifica únicamente la entrega acotada para un equipo de tres personas (véase 1.1); lo que queda fuera se lista en 2.6. 

### **1.1 Alcance** 

**Contexto operativo.** La operación se organiza en la estructura Temporada → Categoría → Grupo → Equipos → Partidos. Las programaciones observadas incluyen categorías como Primera Especial, Primera Fuerza, Reserva, Intermedia, Segunda, Tercera, Juvenil, Cuarta y Veteranos. Una categoría puede tener uno o varios grupos, y el modelo debe admitir nuevas categorías sin rediseño. 

### **1.2 Personal involucrado** 

Equipo de trabajo del proyecto. 

|**Nombre**|Olvera Bucio Jose Israel|
|---|---|
|**Rol**|Desarrollador responsable de arquitectura y datos|
|**Categoría profesional**|Estudiante de Ingeniería en Sistemas Computacionales|
|**Responsabilidades**|Coordinar la arquitectura y el diseño lógico de datos; preparar el repositorio y el<br>entorno de desarrollo; documentar decisiones técnicas; colaborar en desarrollo,<br>integración y revisión.|
|**Información de contacto**|l24120356@morelia.tecnm.mx|
|**Aprobación**|Ing. López Meza Leonardo, Scrum Master.|



|**Nombre**|Olvera Lobato David Geovani|
|---|---|
|**Rol**|Product Owner y analista de requisitos|
|**Categoría profesional**|Estudiante de Ingeniería en Sistemas Computacionales|
|**Responsabilidades**|Mantener y priorizar el Product Backlog; elaborar historias de usuario y criterios<br>de aceptación; coordinar el ERS y el análisis de procesos; consultar y validar<br>requisitos con la Liga o el asesor.|
|**Información de contacto**|l24120339@morelia.tecnm.mx|
|**Aprobación**|Ing. Claudio Ernesto Florian Arenas, Representante del Cliente.|
|**Nombre**|López Meza Leonardo|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 7 

|**Rol**|Scrum Master y responsable de calidad|
|---|---|
|**Categoría profesional**|Estudiante de Ingeniería en Sistemas Computacionales|
|**Responsabilidades**|Facilitar Sprint Planning, Daily Scrum, Sprint Review y Sprint Retrospective;<br>mantener actualizado el tablero; dar seguimiento a impedimentos; coordinar<br>pruebas y verificar los entregables.|
|**Información de contacto**|l24120362@morelia.tecnm.mx|
|**Aprobación**|Ing. Olvera Lobato David Geovani, Product Owner.|



#### **Otras partes interesadas** 

|**Parte**|**Nombre**|**Participación**|
|---|---|---|
|Liga Municipal de Futbol<br>Amateur Morelia|**[PENDIENTE]**|Cliente y fuente de los procesos y reglas.<br>Valida requisitos, procesos y reglas.|
|Profesor de Fundamentos de<br>Ingeniería de Software|Claudio Ernesto Florian<br>Arenas|Seguimiento académico del proyecto<br>durante el semestre.|



### **1.3 Definiciones, acrónimos y abreviaturas** 

|**Término**|**Definición**|
|---|---|
|**ERS / SRS**|Especificación de requisitos de software.|
|**RF / RNF**|Requisito funcional / requisito no funcional.|
|**RN**|Regla de negocio.|
|**CU**|Caso de uso.|
|**RBAC**|Control de acceso basado en roles.|
|**BPMN**|Notación para el modelado de procesos de negocio (OMG).|
|**API**|Interfaz de programación de aplicaciones.|
|**Liga**|Liga Municipal de Futbol Amateur Morelia.|
|**Temporada**|Periodo deportivo en que se desarrolla una competencia. Tiene una<br>convocatoria asociada.|
|**Convocatoria**|Documento normativo de una temporada, del cual se derivan sus reglas<br>de operación.|
|**Categoría / Grupo**|Nivel deportivo / agrupación de equipos dentro de una categoría.|
|**Competencia / Fase**|Estructura de competencia de una temporada y su fase. El formato exacto<br>lo define el usuario programador de partidos.|
|**Programación / Jornada**|Organización de partidos con fecha, hora y cancha o sede asignadas.|
|**Incidente**|Hecho disciplinario registrado manualmente solo si se valida la disciplina reducida.|
|Sanción|Consecuencia disciplinaria con vigencia. Solo se registra, de forma manual, si se<br>valida la disciplina reducida.|
|**Elegibilidad**|Condición que determina si una persona o un equipo puede participar.|
|Restricción dura|Condición que no puede violarse en la programación (equipo duplicado, cancha<br>ocupada, cancha no disponible).|
|**Portal público**|Parte del sistema, sin privilegios de edición, que muestra solo la<br>información publicada.|
|**Publicación**|Flujo Borrador → Revisión → Publicado aplicado a la información pública.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 8 

|**Término**|**Definición**|
|---|---|
|**PEN / AMB / RSK**|Pendiente / ambigüedad / riesgo identificados en la fuente (Apéndices A y<br>B).|



### **1.4 Referencias** 

|**Código**|**Referencia**|
|---|---|
|**R1**|Presentación<br>«Sistema_Gestion_Liga_Municipal_Morelia_Base_Ingenieria_Software(2).pptx»: visión,<br>alcance y requerimientos preliminares. Es el documento base del proyecto.|
|**R2**|Audio de levantamiento «PREGUNTAS - PROY LIGAS DEPORTIVAS (2).m4a». No transcrito<br>de forma confiable; pendiente de verificación.|
|**R3**|Documentación técnica base para ERS/SRS del Sistema de Gestión de la Liga<br>(«Sistema_Gestion_Liga_Municipal_Morelia_Documentacion_Tecnica_Base_ERS.md»),<br>derivada de R1. Las citas «R3 §n» remiten a sus secciones.|
|**R4**|Fuentes de fondo citadas por R1, no consultadas directamente en esta revisión: Reglamento<br>de la Liga, Convocatoria 2025–2026 y programaciones oficiales de las Fechas 32 y 33 (11–12<br>y 18–19 de julio de 2026).|
|**R5**|IEEE Std 830-1998, Recommended Practice for Software Requirements Specifications.|
|**R6**|Plantilla «ERS_simplificado» (formato de ERS basado en IEEE 830) proporcionada para el<br>curso.|
|**R7**|OMG, Business Process Model and Notation (BPMN) 2.0 (ISO/IEC 19510:2013); notación<br>usada en los diagramas de proceso de 4.2.|



### **1.5 Visión general del documento** 

El capítulo 2 describe el producto, sus funciones, usuarios, restricciones y dependencias. El capítulo 3 contiene los requisitos específicos: interfaces, requisitos funcionales (RF), no funcionales (RNF) y otros requisitos, entre ellos las reglas de negocio. El capítulo 4 reúne el modelado: casos de uso, procesos en BPMN, estados del partido, datos, arquitectura conceptual y trazabilidad. La sección 2.6 lista lo que queda fuera de esta entrega. El Apéndice A concentra los pendientes de la fuente, el Apéndice B las ambigüedades, riesgos y verificación de fuentes, el Apéndice C las preguntas para el equipo, el profesor y la Liga, y el Apéndice D los supuestos propuestos. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 9 

## **2 Descripción general** 

### **2.1 Perspectiva del producto** 

El sistema es una plataforma web independiente con dos caras: una aplicación interna para los usuarios de la Liga, con acceso según perfil, y una vista pública de solo consulta. Ambas comparten un backend modular y una base de datos relacional dentro de una sola aplicación **[PROPUESTA]** . La información interna solo llega al portal después de un flujo de validación y autorización, y no existe flujo inverso desde el portal para editar datos. 

Esta entrega no incluye integraciones con servicios externos. Los sistemas o archivos que la Liga usa hoy y los datos históricos por importar siguen por definir **[PENDIENTE]** (PEN-003) y no forman parte de la entrega. 



<!-- Start of picture text -->
1“ iariog interes (penies(PENDIENTE)<br>H ‘<br>=<br>i Programadorde partidos 1 vesptaracresitados ericaSistema de es eisaol Gestin Aeneas de a Liga Morea) Peresultadonysae tablaos Usuario piblico<br>H Copturista : Aplicacién web responsive:<br>' | fegistra resoluciones -- P| grea interna + vista publica de consulta<br>i ( Comisién biscipiinaria ~~~<br><!-- End of picture text -->

_Figura 1. Contexto del sistema de la entrega. Los perfiles internos se detallan en 2.3._ 

A continuación se adjunta la liga de acceso al documento PDF, cargado en OneDrive, que contiene a detalle la arquitectura y el diseño jerárquico:

- [Arquitectura y diseño jerárquico (OneDrive)](https://itecm-my.sharepoint.com/:b:/g/personal/l24120356_morelia_tecnm_mx/IQDJlksHByLHR6OTzFSXRQSVAUigyqzW2snfk5ciVYfrWVU?e=Xcwb0G)

### **2.2 Funcionalidad del producto** 

En esta entrega el sistema se organiza en 8 módulos funcionales (M-01 a M-04, M-06 a M-08 y M-11), más M-09 como módulo condicionado y pendiente de decisión. El detalle está en los requisitos de la sección 3.2 y en los casos de uso de la sección 4.1. Los módulos y requisitos que no forman parte de la entrega se listan en 2.6; no se exige una interfaz o servicio independiente por módulo. 

|**Mód**<br>**ulo**|**Nombre**|**Propósito**|**Entrega[PROPUESTA]**|
|---|---|---|---|
|M-01|Administración y<br>seguridad|Autenticación, perfiles mínimos, permisos por<br>acción y auditoría de acciones críticas.|**S · E**<br>Autenticación, pocos perfiles,<br>denegación por defecto y auditoría<br>mínima. (Q-07)|
|M-02|Temporadas y<br>normativa|Administrar una temporada de trabajo, su<br>convocatoria de referencia y la versión de las<br>reglas usadas.|**S · E**<br>Una temporada, categoría/grupo y<br>referencia de reglas.|
|M-03|Organización<br>deportiva|Administrar clubes, equipos, personas,<br>categorías y grupos.|**S · E**<br>Club/equipo para una temporada y<br>grupo.|
|M-04|Registros y<br>elegibilidad|Registrar altas y bajas de jugadores y su estado<br>de participación.|**S · C**<br>Alta/baja y estado vigente; sin<br>renovación ni transferencia. (Q-01)|
|M-06|Canchas y recursos|Administrar canchas, su disponibilidad temporal y<br>bloqueos.|**S · E**<br>Catálogo, disponibilidad y bloqueo<br>mínimos.|
|M-07|Programación|Registrar y ajustar manualmente partidos y<br>jornadas y detectar conflictos duros.|**S · E**<br>Programación manual con conflictos<br>duros básicos. (Q-04)|
|M-08|Partidos y<br>resultados|Controlar estados del partido, resultados, tabla y<br>estadísticas de equipo.|**I · E**<br>Núcleo del flujo; sin histórico de<br>tabla ni estadísticas de jugador.|
|M-09|Disciplina|Registro manual reducido de incidentes y<br>resoluciones, solo si se valida**[PENDIENTE]**<br>(Q-05).|**P · C**<br>Registro mínimo manual si se<br>valida; resto aplazado. (Q-05)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 10 



<!-- Start of picture text -->
Mód Nombre Propósito Entrega [PROPUESTA]<br>ulo<br>M-11 Portal público y  Publicar solo información autorizada y permitir la  S · E<br>publicación consulta de programación, resultados y tabla. Consulta pública mínima de<br>contenido publicado.<br>1. Configurar temporada,<br>Categoria y grupo (M-02) 5.programacionAprobary publicar(M-11) la<br>2. Registrar clubes, equipos y 6. Registrar y validar el<br>jugadores (M-03, M-04) resultado (M-08)<br>3. Registrar canchas y 7. Calcular la tabla de<br>disponibilidad (M-06) posiciones (M-08)<br>4. Programar partidos de forma ' ey<br>manual y validar conflictos 8. Publicar resultados y tabla 1<br>(M-07) é 1<br>“Transversal (M-O1, RF-093): autenticacién y permisos minimos, erasSe<<br>proteccién de datos, integridad transaccional, historial ; cae 4<br>y auditoria de acciones criticas ee ee<br><!-- End of picture text -->

_Figura 2. Flujo vertical de la entrega [PROPUESTA]. La disciplina reducida solo se incluye si se valida (Q-05)._ 

**Cadena de trazabilidad de la entrega.** Temporada → Categoría → Grupo → Equipo → Jornada/Partido (programación manual) → Resultado → Tabla → Publicación, con auditoría de las acciones críticas. Cada cambio crítico debe poder rastrearse hasta el usuario, la fecha y el motivo. 

### **2.3 Características de los usuarios** 

En esta entrega se consideran perfiles mínimos: administración, operación (programación y captura), disciplina solo si se valida, y usuario público. El acceso se controla con permisos por acción y el portal público no tiene privilegios de edición. 

|**Tipo de usuario**|**Formación y**<br>**habilidades**|**Descripción y responsabilidades**|**Acciones y permisos**|
|---|---|---|---|
|**Administrador**<br>**general**|Presente ante problemáticas que<br>surjan en campo.|Usuario con control administrativo<br>del sistema. Administración global<br>del sistema.|Debe definirse el<br>catálogo exacto de acciones.|
|**Comisión**<br>**Disciplinaria**|Dominio de las reglas a seguir<br>y de la plataforma.|Autoridad que registra la resolución y<br>la sanción. Solo se incluye si se<br>valida la disciplina reducida (Q-05).|Registrar resolución y vigencia.|
|**Programador de**<br>**partidos**|Disponer de horarios y<br>dominar la plataforma.|Responsable de programación.<br>Registrar, revisar y ajustar la<br>programación de forma manual.|Registro y ajuste manual de<br>programación.|
|**Capturista**|Noción del entorno de la<br>plataforma.|Usuario operativo de captura.<br>Registrar información operativa.|Capturar información operativa<br>autorizada, por ejemplo resultados.|
|**Usuario público**|Conocimiento y manejo básico<br>de ordenador y/o teléfono móvil.|Visitante sin privilegios de edición.<br>Consultar información publicada.|Consultar programación,<br>resultados y tabla publicados|



Los demás tipos de usuario de la fuente (presidente del Comité Ejecutivo, secretario, tesorero, Comisión de Arbitraje, presidente o delegado de club, árbitro y jugador) no se modelan en esta entrega y se listan en 2.6. La matriz de permisos perfil → módulo → acción debe formalizarse con el profesor y la Liga (PEN-010, PEN-029, Q-07). Si se valida la disciplina, la captura se mantiene separada de la resolución (DD-010). 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 11 

### **2.4 Restricciones** 

Decisiones de diseño respaldadas por la fuente (R3 §18.1), que el equipo debe respetar: 

|**ID**|**Restricción**|**Entrega[PROPUESTA]**|
|---|---|---|
|DD-0<br>01|El sistema será una aplicación web responsive|**I · E**|
|DD-0<br>02|Debe existir backend/API modular|**S · E**<br>Backend modular dentro de una<br>sola aplicación; sin API pública.|
|DD-0<br>03|Se utilizará una base de datos relacional|**I · E**|
|DD-0<br>06|Debe existir trazabilidad de cambios y decisiones críticas|**I · E**|
|DD-0<br>07|Las temporadas históricas no deben sobrescribirse|**I · E**|
|DD-0<br>08|La publicación requiere control y aprobación|**I · E**|
|DD-0<br>09|Los permisos se basan en roles y acciones|**S · E**<br>RBAC con pocos perfiles hasta<br>validar la matriz. (Q-07)|
|DD-0<br>10|La lógica disciplinaria debe separar captura y resolución|**P · C**<br>Aplica solo si se incluye disciplina.<br>(Q-05)|



**Restricciones DD-004 y DD-005.** Las decisiones de la fuente sobre un motor de reglas desacoplado y un servicio específico de programación no se incluyen como componentes de esta entrega (la programación es manual y las reglas se limitan a una referencia por temporada). Su interpretación queda pendiente de confirmar con el profesor (sección 2.6, Q-04). 

Otras restricciones: 

- Proyecto académico con desarrollo planificado en 10 semanas. La fuente propone un plan de referencia que no sustituye el Scrum que debe construir el equipo. Que esas 10 semanas sean el calendario aplicable a esta entrega y cuáles entregables se evaluarán sigue [PENDIENTE] (Q-24). 

- El equipo debe justificar el stack tecnológico y la arquitectura elegidos (PEN-024 a PEN-027). 

- Esta entrega no incluye integraciones externas. 

- No debe existir flujo inverso desde el portal público para editar información. 

- Lo que no esté expresamente respaldado por las fuentes debe validarse con la Liga antes de convertirse en requisito definitivo. 

- El sistema debe reflejar los procesos reales de la Liga, no imponer primero una estructura de pantallas. 

### **2.5 Suposiciones y dependencias** 

Este documento no asume reglas de negocio sin respaldo. Cuando una regla requiere interpretación, se marca como pendiente y debe pasar por validación humana (RN-006, RN-035). 

#### **Dependencias:** 

- La validación de requisitos, procesos, interfaces, modelo de datos y reglas de la demostración con la Liga y el profesor. 

- El Reglamento y la Convocatoria vigentes de la Liga como base de las reglas configurables por temporada. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 12 

- La resolución de los pendientes del Apéndice A que aplican a la entrega, en particular las prioridades (PEN-001) y la matriz de permisos (PEN-010). 

- La verificación del audio del levantamiento (R2) contra las definiciones de este documento. 

- La rúbrica y las indicaciones escritas del profesor sobre las funciones obligatorias (Q-02) y el calendario y los entregables a evaluar (Q-24). Este ERS no asume que el alcance propuesto prevalezca sobre ellos. 

### **2.6 Fuera del alcance de esta entrega [PROPUESTA]** 

Los siguientes elementos de la fuente se conservan solo por su identificador, para trazabilidad. **No son trabajo obligatorio de diseño, implementación ni aceptación de esta entrega.** «A» significa aplazado y «P» pendiente de decisión. Esta delimitación proviene de la propuesta de alcance para un equipo de tres personas; **no está aprobada** por el profesor, la rúbrica, la Liga ni el equipo, y debe validarse (Apéndice C). Si alguno resulta obligatorio, deberá reincorporarse al cuerpo del ERS. 

|**Capacidad**|**Identificadores de la fuente**|**Estado**|**Pregunta**|
|---|---|---|---|
|Árbitros, designaciones y<br>cédula integral|RF-021 a RF-026; M-05; UI-007, UI-014; entidades<br>Árbitro, Designación arbitral y Cédula; RN-026|A|Q-06|
|Programación automática|RF-034, RF-035, RF-037, RF-038, RF-041, RF-042;<br>RN-016, RN-017; VAL-007|A|Q-04|
|Renovación, transferencia e<br>historial detallado de registro|RF-015, RF-016, RF-018|A|Q-01|
|Sede independiente,<br>mantenimiento y partidos<br>consecutivos|RF-028, RF-031, RF-032|A|—|
|Histórico de tabla y<br>estadísticas de jugador|RF-051, RF-054; UI-013|A|—|
|Disciplina avanzada|RF-059, RF-060, RF-061, RF-066, RF-067, RF-068;<br>RN-027, RN-028, RN-031, RN-032; CU-012, CU-013;<br>UI-016, UI-017; entidades Artículo/Infracción, Expediente<br>y Recurso|A|Q-05|
|Bloqueo derivado de sanción|RF-064; RN-015|P<br>(AMB-00<br>1)|Q-17|
|Ascensos, descensos, liguilla y<br>fases finales|RF-069 a RF-081; RN-004, RN-033, RN-034, RN-036;<br>M-10; CU-014, CU-015; P-07, P-08; UI-018, UI-019|A|Q-18|
|Portal ampliado|RF-085 a RF-088; entidad Documento/Comunicado<br>(noticias, comunicados y buscador general)|A|—|
|Reportes y exportación|RF-091, RF-092; REP-004 a REP-009, REP-011; M-12;<br>UI-021|A|Q-09|
|Integraciones y plataforma|Correo, WhatsApp/SMS, almacenamiento documental,<br>mapas, CSV/Excel, API pública y autenticación externa;<br>CI/CD y contenedores (PEN-033 a PEN-035, PEN-038)|A|Q-09|
|Perfiles de usuario no<br>modelados|Presidente del Comité Ejecutivo, Secretario, Tesorero,<br>Comisión de Arbitraje, Presidente/delegado de club,<br>Árbitro y Jugador (PEN-011 a PEN-013)|A|Q-07|
|Restricciones DD-004 y<br>DD-005|Motor de reglas desacoplado y servicio específico de<br>programación como componentes separados|P|Q-04|



La reducción proviene de limitar funciones, dependencias y decisiones sin validar; este ERS no presume que el uso de herramientas de IA reduzca el esfuerzo de análisis, integración, pruebas o mantenimiento. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 13 

## **3 Requisitos específicos** 

Este capítulo contiene los requisitos con el detalle necesario para diseñar y probar el sistema. Cada requisito tiene identificador, nombre, tipo, fuente y prioridad. La fuente indica el origen del requisito (R1, R3, véase 1.4), y las prioridades son propuestas del equipo, como se explica en 3.2. 

### **3.1 Requisitos comunes de los interfaces** 

#### **3.1.1 Interfaces de usuario** 

El sistema es una aplicación web responsive (RNF-007) con una aplicación interna de acceso autenticado y un portal público. La fuente no define colores, tipografías ni estilos visuales. Las pantallas siguientes se identificaron a partir de funcionalidades explícitas, por lo que son una **[PROPUESTA]** cuya composición y nomenclatura deben validarse en un prototipo (PEN-014). 

|**ID**<br>UI-00<br>1|**Pantalla**<br>Inicio/Login interno|**Actor**<br>Usuarios<br>internos|**Objetivo**<br>Autenticarse|**Acciones**<br>Iniciar sesión|**Entrega[PROPUESTA]**<br>**I · E**|
|---|---|---|---|---|---|
|UI-00<br>2|Inicio y<br>navegación|Usuarios<br>internos|Acceder a<br>funciones<br>autorizadas|Navegar|**S · C**<br>Puede integrarse en el inicio.|
|UI-00<br>3|Gestión de<br>temporadas|Administración|Administrar<br>temporadas|Crear, consultar,<br>editar|**S · E**<br>Una temporada.|
|UI-00<br>4|Configuración de<br>categorías/grupos|Administración|Estructurar<br>temporada|Crear, editar,<br>consultar|**S · E**<br>Una vista puede cubrir varias<br>pantallas.|
|UI-00<br>5|Gestión de<br>clubes/equipos|Administración|Administrar<br>organizaciones<br>deportivas|Registrar,<br>consultar,<br>actualizar|**S · E**<br>Una vista puede cubrir varias<br>pantallas.|
|UI-00<br>6|Registro de<br>jugadores|Usuarios<br>autorizados|Gestionar registros|Alta, baja|**S · E**<br>Alta/baja básica.|
|UI-00<br>8|Gestión de<br>canchas|Usuarios<br>autorizados|Administrar<br>recursos|Registrar,<br>bloquear|**S · E**<br>Una vista puede cubrir varias<br>pantallas.|
|UI-00<br>9|Programación|Programador|Registrar y revisar<br>jornada|Crear, ajustar,<br>validar conflictos,<br>enviar a revisión|**S · E**<br>Programación manual. (Q-04)|
|UI-01<br>0|Detalle de partido|Usuarios<br>internos|Consultar ciclo del<br>partido|Cambiar estado<br>según permiso|**S · E**<br>Una vista puede cubrir varias<br>pantallas.|
|UI-01<br>1|Captura de<br>resultado|Usuario<br>autorizado|Registrar marcador|Capturar, validar,<br>corregir|**S · E**<br>Una vista puede cubrir varias<br>pantallas.|
|UI-01<br>2|Tabla de<br>posiciones|Interno /<br>público|Consultar<br>clasificación|Consultar|**I · E**|
|UI-01<br>5|Expediente<br>disciplinario|Comisión /<br>autoridad|Resolver<br>expediente|Revisar, resolver|**P · C**<br>Solo si se valida disciplina.<br>(Q-05)|
|UI-02<br>0|Portal público|Usuario público|Consultar<br>información<br>publicada|Filtrar y consultar<br>programación,<br>resultados y tabla|**S · E**<br>Consulta de solo lectura.|
|UI-02<br>2|Auditoría|Administrador /<br>autoridad|Revisar trazabilidad|Consultar, filtrar|**P · C**<br>Consulta de auditoría:<br>¿requerida? (Q-15)|



**Pantallas de la entrega [PROPUESTA].** No se requiere una interfaz independiente por cada identificador UI; una misma vista puede cubrir varias funciones si es clara. UI-015 y UI-022 están pendientes de decisión (Q-05, Q-15). 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 14 

#### **Comportamientos que la interfaz debe reflejar:** 

- Mostrar la causa de bloqueo cuando una persona o un equipo no puede participar. 

- Mostrar los conflictos de programación y su motivo. 

- Mostrar el estado del partido y las acciones permitidas en ese estado. 

- Diferenciar los datos oficiales de los indicadores calculados. 

- Diferenciar borrador, revisión y publicado en el contenido público. 

- Evitar que usuarios sin autorización vean o ejecuten acciones administrativas. 

Navegación. Aplicación interna: inicio de sesión → panel con acceso a Temporadas y normativa, Organización deportiva, Registros y elegibilidad, Canchas, Programación, Partidos y resultados, Tablas y Administración (seguridad, historial y auditoría). Portal público: Programación, Resultados y Tabla, con filtros por fecha, categoría/grupo y equipo. La navegación final queda por validar **[PENDIENTE]** (PEN-014). 

A continuación se adjunta la liga de acceso a Figma, donde se puede visualizar la propuesta de las interfaces:

- [Prototipo de interfaces (Figma)](https://www.figma.com/design/kxtW96Gd0FNxdwmvSk6S4t/Untitled?node-id=0-1&t=VymLfyImOGjy1T3f-1)

#### **3.1.2 Interfaces de hardware** 

No aplica. La fuente no identifica ningún dispositivo de hardware con el que el sistema deba comunicarse; el acceso es mediante navegador web desde equipos de escritorio y móviles (RNF-007). Esta sección se revisará si se define lo contrario. 

#### **3.1.3 Interfaces de software** 

Esta entrega no incluye interfaces con software externo (correo, mensajería, almacenamiento documental, mapas, importación o exportación de archivos, API pública ni autenticación externa); véase 2.6. 

Las integraciones con sistemas externos son potenciales y ninguna está aprobada. Cada una debe justificarse por costo, seguridad y necesidad (PEN-033 a PEN-035). Hasta definirlas, sus datos y proveedores quedan pendientes. 

A continuación se adjuntan las ligas de acceso al diccionario de la base de datos propuesta y a su script SQL:

- [Diccionario de datos (OneDrive)](https://itecm-my.sharepoint.com/:b:/g/personal/l24120356_morelia_tecnm_mx/IQCzMefLsnvMS6fRWMhs3da1Af0Bkpxt7vIjWf2IgmIU-hw?e=jDG3Ne)
- [Script SQL de la base de datos (OneDrive)](https://itecm-my.sharepoint.com/:u:/g/personal/l24120356_morelia_tecnm_mx/IQDvro8mXY5pSZJ3D3LUadWjAZiVS9JHpOUPktLOPQxK8zA?e=qO5cHm)

#### **3.1.4 Interfaces de comunicación** 

La arquitectura de la entrega prevé que el usuario público acceda a la vista de consulta por HTTPS. Los protocolos y formatos de comunicación de las demás interfaces siguen sin definirse **[PENDIENTE]** . 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 15 

### **3.2 Requisitos funcionales** 

Los requisitos funcionales (RF) convierten el alcance de la entrega en comportamientos verificables del sistema. No definen implementación interna. Se agrupan por módulo funcional y conservan el identificador de la fuente; por eso la numeración tiene huecos: los RF que no forman parte de la entrega se listan en 2.6. Todos tienen tipo «Requisito» y como fuente R1 formalizada en la sección indicada de R3. 

**Prioridad.** La fuente no define prioridades (PEN-001). Las que aparecen son una **[PROPUESTA]** del equipo, calculada con los criterios de la tabla, y deberán validarse con la Liga y el profesor antes de ordenar el backlog. 

|**Prioridad propuesta**|**Criterio**|
|---|---|
|**Alta / Esencial**|Indispensable para el flujo operativo central (configuración → programación → resultado → tabla), para la disciplina o para la integridad,<br>trazabilidad y seguridad. Sin él el sistema no cumple su propósito.|
|**Media / Deseado**|Necesario para la operación completa, pero puede entregarse en una iteración posterior sin invalidar el flujo central.|
|**Baja / Opcional**|Complementario. Puede posponerse sin afectar la operación esencial.|



**Prioridad de entrega y estado de entrega [PROPUESTA].** La columna «Prioridad» es la prioridad del producto integral (revisión 0.1) y no cambia. La columna «Entrega» indica el estado (I incluido, S simplificado, P pendiente de decisión) y la prioridad de entrega (E esencial, C conveniente, O opcional) para esta entrega, con un motivo breve cuando el texto se ajustó o el requisito depende de una decisión (Q-nn, Apéndice C). Un requisito pendiente no es compromiso hasta que se resuelva. 

#### **3.2.1 Gestión de temporadas, convocatorias y configuración deportiva** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-001|Gestionar temporadas|El sistema debe permitir registrar y administrar una<br>temporada de trabajo como periodo deportivo.|Administrador general /<br>autoridad autorizada|Requisit<br>o|R1<br>R3 §3.2|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Se gestiona una temporada de trabajo<br>(no múltiples simultáneas). (Q-11)|
|RF-002|Asociar convocatoria a<br>temporada|El sistema debe asociar el documento normativo<br>correspondiente a una temporada.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.2|**Media /**<br>**Deseado**<br>**[PROPUESTA]**|**S · C**<br>Solo referencia a la convocatoria;<br>fuente aún no validada. (Q-03)|
|RF-003|Conservar histórico de<br>temporadas|El sistema debe conservar información histórica sin<br>sobrescribir temporadas anteriores.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.2|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-004|Gestionar categorías por<br>temporada|El sistema debe permitir registrar la categoría de la<br>temporada de trabajo; el modelo no debe impedir que<br>las categorías varíen entre temporadas.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.2|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Una categoría de demostración; el<br>modelo no debe impedir otras. (Q-11)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 16 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-005|Gestionar grupos por<br>categoría y temporada|El sistema debe permitir registrar el grupo (o los<br>grupos) de la categoría de la temporada de trabajo.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.2|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Un grupo de demostración; el modelo<br>no debe impedir otros. (Q-11)|
|RF-006|Configurar reglas<br>versionables|El sistema debe registrar la referencia o versión de las<br>reglas usadas en la temporada/convocatoria<br>(puntuación y desempates de la tabla). No incluye un<br>motor genérico de reglas.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.2|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · C**<br>Se registra la versión/referencia de la<br>regla usada; sin motor genérico.<br>(Q-03)|
|RF-007|Registrar reglas<br>interpretadas como<br>pendientes de validación|El sistema no debe convertir automáticamente una<br>interpretación administrativa en una regla permanente;<br>debe permitir su validación/autorización.|Autoridad autorizadora|Requisit<br>o|R1<br>R3 §3.2|**Media /**<br>**Deseado**<br>**[PROPUESTA]**|**S · C**<br>Se registra como pendiente de<br>validación; no se automatiza. (Q-03)|



#### **3.2.2 Clubes, equipos y personas** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-008|Gestionar clubes|El sistema debe registrar y administrar clubes afiliados.|Administrador / usuario<br>autorizado|Requisit<br>o|R1<br>R3 §3.3|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Registro básico de clubes necesarios<br>para la demostración.|
|RF-009|Gestionar equipos|El sistema debe registrar equipos como<br>representación deportiva de un club dentro de<br>categoría/grupo/temporada.|Administrador / usuario<br>autorizado|Requisit<br>o|R1<br>R3 §3.3|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Registro básico de equipos de la<br>temporada/grupo.|
|RF-010|Reutilizar identidad de<br>persona|El sistema debe mantener una identidad de persona<br>reutilizable en diferentes roles.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.3|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · C**<br>Se mantiene solo lo necesario para<br>evitar duplicidad y conservar el<br>vínculo por temporada.|
|RF-011|Mantener roles de<br>persona separados de su<br>identidad|El sistema debe mantener la identidad de una persona<br>separada de sus roles, sin duplicarla.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.3|**Media /**<br>**Deseado**<br>**[PROPUESTA]**|**S · C**<br>Se mantiene solo lo necesario para<br>evitar duplicidad y conservar el<br>vínculo por temporada.|
|RF-012|Mantener historial de<br>pertenencia|El sistema debe conservar el historial de un jugador<br>por temporadas/equipos.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.3|**Media /**<br>**Deseado**<br>**[PROPUESTA]**|**S · C**<br>Se mantiene solo lo necesario para<br>evitar duplicidad y conservar el<br>vínculo por temporada.|



#### **3.2.3 Registro y elegibilidad de jugadores** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-013|Dar de alta jugador|El sistema debe registrar el alta de un jugador<br>conforme a las reglas de la Liga.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.4|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Alta básica; reglas de alta no<br>validadas. (Q-03, Q-16)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 17 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-014|Dar de baja jugador|El sistema debe registrar la baja de un jugador<br>conservando su historial.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.4|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Baja básica conservando historial.|
|RF-017|Registrar estado de<br>elegibilidad|El sistema debe manejar estados como activo,<br>suspendido, baja e inelegible.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.4|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Solo estados cuyas reglas la Liga<br>confirme. (Q-16)|
|RF-019|Validar elegibilidad antes<br>de participación|El sistema debe comprobar la elegibilidad antes de<br>permitir una participación cuando la regla así lo exija.|Sistema / usuario<br>autorizado|Requisit<br>o|R1<br>R3 §3.4|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Se incluye solo con reglas de<br>elegibilidad confirmadas. (Q-16)|
|RF-020|Bloquear participación<br>por sanción vigente|Cuando una sanción vigente impida participar, el<br>sistema debe impedir la acción correspondiente y<br>explicar el motivo.|Sistema|Requisit<br>o|R1<br>R3 §3.4|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Depende de disciplina (Q-05) y de<br>AMB-001. (Q-05, Q-17)|



#### **3.2.4 Canchas y sedes** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-027|Gestionar catálogo de<br>canchas|El sistema debe registrar canchas y sus características<br>conocidas.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.6|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Catálogo mínimo de canchas.|
|RF-029|Registrar disponibilidad<br>temporal|El sistema debe administrar disponibilidad por<br>fecha/hora.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.6|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Disponibilidad mínima para validar<br>asignaciones. (Q-24)|
|RF-030|Bloquear cancha|El sistema debe permitir bloquear una cancha cuando<br>corresponda.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.6|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Bloqueo por intervalo; formalidad<br>(PEN-007) pendiente.|



#### **3.2.5 Programación** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-033|Registrar programación|El sistema debe permitir registrar manualmente la<br>programación por categoría, grupo, equipos, cancha,<br>fecha y hora.|Programador / usuario<br>autorizado|Requisit<br>o|R1<br>R3 §3.7|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Captura manual de jornadas/partidos.<br>(Q-04)|
|RF-036|Asignar canchas|El sistema debe permitir asignar manualmente una<br>cancha disponible a un partido y rechazar la<br>asignación si genera un conflicto duro.|Programador / usuario<br>autorizado|Requisit<br>o|R1<br>R3 §3.7|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Asignación manual de cancha con<br>validación de conflictos.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 18 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-039|Detectar conflictos de<br>programación|El sistema debe detectar, al crear o ajustar una<br>asignación manual, conflictos como equipo duplicado,<br>cancha ocupada o cancha no disponible. El conflicto<br>por sanción depende de AMB-001**[PENDIENTE]**.|Sistema|Requisit<br>o|R1<br>R3 §3.7|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**<br>Conflictos duros básicos: equipo<br>duplicado, cancha ocupada, cancha<br>no disponible.|
|RF-040|Permitir ajuste manual<br>autorizado|El sistema debe permitir crear y modificar<br>manualmente la programación a usuarios autorizados,<br>con traza del cambio (RN-018).|Programador / usuario<br>autorizado|Requisit<br>o|R1<br>R3 §3.7|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Limitado a ajuste manual autorizado<br>con traza (RN-018). (Q-07)|



#### **3.2.6 Partidos y ciclo de vida** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-043|Gestionar estado del<br>partido|El sistema debe manejar los estados del ciclo de vida<br>del partido.|Usuario autorizado /<br>sistema|Requisit<br>o|R1<br>R3 §3.8|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Estados mínimos de partido por<br>confirmar. (Q-13)|
|RF-044|Mantener historial del<br>partido|El sistema no debe eliminar partidos con historial.|Sistema|Requisit<br>o|R1<br>R3 §3.8|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-045|Auditar transiciones de<br>estado|Cada transición debe conservar usuario, fecha y<br>motivo.|Sistema|Requisit<br>o|R1<br>R3 §3.8|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-046|Restringir acciones por<br>estado|El estado del partido debe determinar las acciones<br>permitidas.|Sistema|Requisit<br>o|R1<br>R3 §3.8|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|



#### **3.2.7 Resultados, tablas y estadísticas** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-047|Capturar marcador|El sistema debe permitir registrar el marcador y estado<br>del resultado.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.9|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-048|Validar resultado|El sistema debe permitir identificar cuándo un<br>resultado queda validado/oficial.|Usuario/autoridad<br>autorizada|Requisit<br>o|R1<br>R3 §3.9|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-049|Calcular tabla<br>automáticamente|El sistema debe calcular PJ, resultados, goles y<br>puntos según reglas configuradas.|Sistema|Requisit<br>o|R1<br>R3 §3.9|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**<br>Con reglas de puntos de<br>demostración si no hay regla oficial<br>validada. (Q-10)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 19 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-050|Parametrizar<br>desempates|El sistema debe soportar criterios de desempate<br>configurables.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.9|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · E**<br>Criterios de desempate de<br>demostración hasta validación oficial.<br>(Q-10)|
|RF-052|Recalcular tras<br>corrección autorizada|El sistema debe recalcular las tablas cuando se corrija<br>un resultado de forma autorizada.|Sistema|Requisit<br>o|R1<br>R3 §3.9|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-053|Calcular estadísticas de<br>equipo|El sistema debe producir PJ, PG, PE, PP, GF, GC,<br>DG, puntos y posición.|Sistema|Requisit<br>o|R1<br>R3 §3.9|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Solo estadísticas de equipo<br>necesarias para la tabla.|
|RF-055|Separar dato oficial de<br>indicador calculado|El sistema debe distinguir información oficial de<br>métricas derivadas.|Sistema|Requisit<br>o|R1<br>R3 §3.9|**Media /**<br>**Deseado**<br>**[PROPUESTA]**|**I · E**<br>Depende de definir resultado oficial.<br>(Q-12)|
|RF-056|Publicar sólo información<br>validada|El portal sólo debe mostrar resultados y datos que<br>hayan sido validados y publicados.|Usuario autorizado /<br>sistema|Requisit<br>o|R1<br>R3 §3.9|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|



#### **3.2.8 Disciplina reducida (pendiente de decisión)** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-057|Generar expediente<br>disciplinario|El sistema debe permitir registrar manualmente un<br>caso disciplinario a partir de un incidente.<br>**[PENDIENTE]**Solo si se valida la disciplina.|Sistema|Requisit<br>o|R1<br>R3 §3.10|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Solo registro manual mínimo de<br>incidente/resolución si se valida.<br>(Q-05)|
|RF-058|Relacionar incidentes<br>con personas/equipos|Cada incidente debe quedar relacionado con las<br>personas y/o equipos involucrados.|Sistema / usuario<br>autorizado|Requisit<br>o|R1<br>R3 §3.10|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Relación mínima<br>incidente–persona/equipo si se valida.<br>(Q-05)|
|RF-062|Validar y resolver<br>sanción|El sistema debe permitir que una autoridad registre la<br>resolución y la sanción correspondiente.|Autoridad competente|Requisit<br>o|R1<br>R3 §3.10|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Resolución manual por autoridad, solo<br>si se valida disciplina. (Q-05, Q-07)|
|RF-063|Calcular vigencia de<br>sanción|El sistema debe permitir registrar y conservar la<br>vigencia indicada en la resolución; el cálculo<br>automático queda fuera de la entrega.|Autoridad competente|Requisit<br>o|R1<br>R3 §3.10|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Vigencia capturada manualmente, no<br>calculada automáticamente. (Q-05)|
|RF-065|Mantener resolución<br>inmutable|El historial de resolución debe conservarse sin<br>alteración destructiva.|Sistema|Requisit<br>o|R1<br>R3 §3.10|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**P · C**<br>Condicionado a RF-062; inmutabilidad<br>de la resolución. (Q-05)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 20 

#### **3.2.9 Portal público y auditoría** 

|**ID**|**Requisito**|**Descripción**|**Actor**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|---|
|RF-082|Consultar programación<br>semanal|El portal debe mostrar la programación semanal<br>publicada.|Usuario público|Requisit<br>o|R1<br>R3 §3.12|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-083|Consultar resultados|El portal debe mostrar resultados<br>validados/publicados.|Usuario público|Requisit<br>o|R1<br>R3 §3.12|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-084|Consultar tablas|El portal debe mostrar tablas publicadas.|Usuario público|Requisit<br>o|R1<br>R3 §3.12|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**|
|RF-089|Buscar por<br>fecha/categoría/equipo|El portal debe permitir filtrar las consultas públicas por<br>fecha, categoría/grupo y equipo; no incluye buscador<br>general.|Usuario público|Requisit<br>o|R1<br>R3 §3.12|**Media /**<br>**Deseado**<br>**[PROPUESTA]**|**S · C**<br>Solo filtros básicos por<br>temporada/grupo/equipo; sin<br>buscador general.|
|RF-090|Gestionar flujo de<br>publicación|La información pública debe seguir un flujo de<br>borrador → revisión → publicado.|Usuario autorizado|Requisit<br>o|R1<br>R3 §3.12|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**I · E**<br>Flujo Borrador → Revisión →<br>Publicado; detalle PEN-009. (Q-07)|
|RF-093|Auditar acciones críticas|El sistema debe registrar acciones críticas con<br>trazabilidad suficiente para revisión posterior.|Sistema|Requisit<br>o|R1<br>R3 §3.12|**Alta /**<br>**Esencial**<br>**[PROPUESTA]**|**S · E**<br>Auditoría mínima de acciones críticas.<br>(Q-15)|



#### **3.2.10 Validaciones y manejo de errores** 

Validaciones que el sistema debe aplicar y comportamiento ante su fallo. Los mensajes exactos de interfaz y los códigos técnicos de error están por definir **[PENDIENTE]** (PEN-016). 

|**ID**|**Elemento**|**Validación**|**Comportamiento si falla**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|
|VAL-00<br>1|Registro de jugador|Cumplimiento de reglas de alta y baja|No completar operación; informar causa|**S · E**<br>Solo alta/baja;<br>renovación/transferencia aplazadas.<br>(Q-01)|
|VAL-00<br>2|Elegibilidad|Jugador no suspendido/inelegible cuando la regla impida<br>participación|Bloquear participación y explicar motivo|**P · C**<br>Reglas de elegibilidad no validadas.<br>(Q-16)|
|VAL-00<br>3|Programación|Equipo duplicado|Rechazar asignación y explicar conflicto|**I · E**|
|VAL-00<br>4|Programación|Cancha ocupada|Rechazar asignación y explicar conflicto|**I · E**|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 21 

|**ID**|**Elemento**|**Validación**|**Comportamiento si falla**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|
|VAL-00<br>5|Programación|Cancha no disponible|Rechazar asignación y explicar conflicto|**I · E**|
|VAL-00<br>6|Programación|Restricción disciplinaria aplicable|Impedir programación cuando corresponda|**P · C**<br>Depende de disciplina/AMB-001.<br>(Q-17)|
|VAL-00<br>8|Estado de partido|Acción no permitida por el estado|Rechazar la acción|**I · E**|
|VAL-00<br>9|Resultado|Resultado no validado|No convertir en información oficial/publicada|**I · E**|
|VAL-01<br>0|Corrección de resultado|Corrección no autorizada|Rechazar y conservar dato oficial previo|**I · E**|
|VAL-01<br>1|Desempate|Igualdad|Aplicar criterios configurados|**P · E**<br>Criterios de demostración hasta<br>validación oficial. (Q-10)|
|VAL-01<br>2|Disciplina|Artículo/infracción no identificado|Dejar caso en revisión|**P · C**<br>Solo si se valida disciplina. (Q-05)|
|VAL-01<br>3|Sanción|Excepción no formalmente definida|No automatizarla como regla general; requerir validación|**P · C**<br>Solo si se valida disciplina. (Q-05)|
|VAL-01<br>4|Publicación|Información en borrador/revisión|No mostrarla como pública|**I · E**|
|VAL-01<br>5|Acceso|Rol sin permiso|Denegar acción|**I · E**|
|VAL-01<br>6|Auditoría|Operación crítica|Debe registrarse usuario, fecha y motivo/contexto|**I · E**|



#### **3.2.11 Consultas y listados requeridos** 

Consultas y listados de programación, resultados, tabla y auditoría que forman parte del flujo de la entrega; no incluyen exportación a PDF/Excel ni reportes generalizados (véase 2.6). Los filtros marcados como pendientes deben confirmarse **[PENDIENTE]** . 

|**ID**|Consulta o listado|**Filtros o alcance conocido**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|
|REP-00<br>1|Programación|Fecha / categoría / cancha|**Media / Deseado**<br>**[PROPUESTA]**|**S · E**<br>Como consulta/listado del flujo, no<br>como reporte generalizado.|
|REP-00|Resultados|Temporada / competencia**[PENDIENTE]**|**Media / Deseado**|**S · E**|
|2|||**[PROPUESTA]**|Como consulta/listado del flujo.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 22 

|**ID**|Consulta o listado|**Filtros o alcance conocido**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|
|REP-00<br>3|Tabla de posiciones|Categoría / grupo|**Media / Deseado**<br>**[PROPUESTA]**|**S · E**<br>Como consulta de tabla (M-08/M-11).|
|REP-01<br>0|Auditoría|Usuario / operación / fecha**[PENDIENTE]**|**Media / Deseado**<br>**[PROPUESTA]**|**P · C**<br>Consulta de auditoría: ¿requerida?<br>(Q-15)|



### **3.3 Requisitos no funcionales** 

Los requisitos no funcionales (RNF) conservan el identificador de la fuente. Los valores cuantitativos (porcentaje de disponibilidad, tiempos de respuesta, nivel de accesibilidad, políticas de respaldo) no están definidos y quedan como **[PENDIENTE]** ; mientras no se fijen, estos requisitos no son verificables. Las prioridades son una **[PROPUESTA]** del equipo. 

#### **3.3.1 Requisitos de rendimiento** 

|**ID**|**Requisito**|**Descripción y criterio**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|RNF-00<br>2|Rendimiento de consultas<br>públicas|Las consultas del portal deben responder adecuadamente; tiempo objetivo<br>**[PENDIENTE]**.|Requisit<br>o|R1<br>R3 §4|**Media /**<br>**Deseado**<br>**[PROPUESTA**<br>**]**|**P · C**<br>Sin métrica acordada; no es criterio de<br>aceptación. (Q-19)|



#### **3.3.2 Seguridad** 

|**ID**|**Requisito**|**Descripción y criterio**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|RNF-00<br>3|Seguridad y mínimo<br>privilegio|El acceso debe limitarse a las capacidades necesarias por rol/contexto.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**I · E**<br>Mínimo privilegio sobre los pocos perfiles<br>de la demostración. (Q-07)|
|RNF-01<br>2|Protección de datos<br>personales|La información personal debe protegerse y separarse adecuadamente de la<br>información pública.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**I · E**<br>Separar datos personales de públicos.<br>(Q-08)|
|RNF-01<br>3|Hash seguro de<br>contraseñas|Las contraseñas no deben almacenarse en texto plano.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**S · E**<br>Aplica si se manejan contraseñas<br>propias.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 23 

|**ID**|**Requisito**|**Descripción y criterio**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|RNF-01<br>4|Gestión segura de<br>sesiones|Deben existir sesiones y controles antiabuso.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**S · E**<br>Acorde a la solución adoptada<br>(PEN-030).|
|RNF-01<br>5|Auditoría|Las acciones relevantes deben ser trazables.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**S · E**<br>Trazabilidad mínima de acciones críticas.<br>(Q-15)|



Requisitos de seguridad respaldados por la fuente (R3 §15.1): autenticación segura; autorización por rol y contexto (RBAC); permisos por módulo y acción; separación de funciones; separación de los datos internos y públicos; respaldo y recuperación. 

**Controles por definir [PENDIENTE]:** política de contraseñas; duración y renovación de sesión; recuperación de acceso; bloqueo o límite de intentos; matriz de permisos por rol; datos personales visibles para cada rol; retención de auditoría; política de respaldo y recuperación; tratamiento de evidencias disciplinarias; protección de la información en tránsito y en almacenamiento (PEN-029 a PEN-032). 

#### **3.3.3 Fiabilidad** 

|**ID**|**Requisito**|**Descripción y criterio**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|RNF-00<br>4|Integridad transaccional|Las operaciones críticas deben preservar consistencia e integridad de datos.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**I · E**|



#### **3.3.4 Disponibilidad** 

|**ID**|**Requisito**|**Descripción y criterio**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|RNF-00<br>1|Disponibilidad durante<br>jornadas|El sistema debe estar disponible durante las jornadas; porcentaje y tolerancia de<br>indisponibilidad**[PENDIENTE]**.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**P · C**<br>Sin métrica acordada; no es criterio de<br>aceptación. (Q-19)|
|RNF-01<br>0|Respaldo y recuperación|Deben existir mecanismos de respaldo y recuperación; política exacta<br>**[PENDIENTE]**.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**P · O**<br>Respaldo/recuperación: política y entorno<br>no definidos (PEN-031). (Q-19)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 24 

#### **3.3.5 Mantenibilidad** 

|**ID**|**Requisito**|**Descripción y criterio**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|RNF-00<br>5|Escalabilidad|El diseño debe soportar nuevas temporadas y nuevas categorías sin rediseño del<br>dominio.|Requisit<br>o|R1<br>R3 §4|**Media /**<br>**Deseado**<br>**[PROPUESTA**<br>**]**|**S · C**<br>Permite nuevas temporadas/categorías;<br>sin exigir plataforma de producción.|
|RNF-00<br>9|Mantenibilidad|Debe facilitar evolución de reglas, temporadas y módulos.|Requisit<br>o|R1<br>R3 §4|**Media /**<br>**Deseado**<br>**[PROPUESTA**<br>**]**|**P · C**<br>Sin criterio medible definido. (Q-21)|
|RNF-01<br>1|Observabilidad|Deben existir mecanismos para observar el comportamiento del sistema; detalle<br>técnico**[PENDIENTE]**.|Requisit<br>o|R1<br>R3 §4|**Media /**<br>**Deseado**<br>**[PROPUESTA**<br>**]**|**P · O**<br>Observabilidad: sin acuerdo; no<br>obligatorio. (Q-19)|



#### **3.3.6 Portabilidad** 

La fuente no define requisitos de portabilidad específicos. El único requisito relacionado es que la aplicación web sea responsive (RNF-007, en Usabilidad). Los requisitos de portabilidad entre plataformas, motores de base de datos o entornos de despliegue dependen del stack y la infraestructura, por definir **[PENDIENTE]** (PEN-024 a PEN-026). 

#### **3.3.7 Usabilidad y accesibilidad** 

Subsección añadida a la plantilla porque la fuente incluye requisitos de este tipo. 

|**ID**|**Requisito**|**Descripción y criterio**|**Tipo**|**Fuente**|**Prioridad**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|RNF-00<br>6|Usabilidad|El sistema debe ser utilizable por actores con funciones distintas.|Requisit<br>o|R1<br>R3 §4|**Media /**<br>**Deseado**<br>**[PROPUESTA**<br>**]**|**P · C**<br>Sin criterio medible definido. (Q-21)|
|RNF-00<br>7|Responsive|La aplicación web debe ser responsive.|Requisit<br>o|R1<br>R3 §4|**Alta /**<br>**Esencial**<br>**[PROPUESTA**<br>**]**|**I · E**|
|RNF-00<br>8|Accesibilidad|Debe contemplarse accesibilidad; estándar/nivel**[PENDIENTE]**.|Requisit<br>o|R1<br>R3 §4|**Media /**<br>**Deseado**<br>**[PROPUESTA**<br>**]**|**P · C**<br>Nivel de accesibilidad no acordado.<br>(Q-19)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 25 

### **3.4 Otros requisitos** 

#### **3.4.1 Reglas de negocio** 

Las reglas de negocio (RN) establecen condiciones del dominio que el sistema debe respetar. Las reglas deportivas y disciplinarias provienen de la convocatoria de cada temporada y deben versionarse. Si una regla no es explícita, su interpretación requiere validación y autorización (RN-006); no se convierte en regla permanente. 

#### **Reglas de temporada y configuración** 

|**ID**|**Regla**|**Condición**|**Comportamiento esperado**|**Actores afectados**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|
|RN-001|La temporada representa un periodo<br>deportivo|Cuando se gestione una<br>competencia|La información debe quedar asociada a su<br>temporada|Todos los usuarios<br>administrativos|**I · E**|
|RN-002|La convocatoria es normativa|Una temporada tiene una<br>convocatoria asociada|Las reglas de operación deben poder<br>vincularse a su documento normativo|Autoridades / usuarios<br>administrativos|**S · C**<br>Convocatoria como referencia;<br>contenido aún no validado. (Q-03)|
|RN-003|Las categorías/grupos pueden variar<br>por temporada|Al abrir una nueva temporada|No debe asumirse una estructura fija heredada<br>sin configuración|Administración|**I · E**|
|RN-005|El histórico no se sobrescribe|Al modificar una temporada nueva o<br>actual|Los datos históricos deben conservarse|Todos|**I · E**|
|RN-006|Las interpretaciones requieren<br>validación|Cuando una regla no sea explícita|Debe pasar por validación/autorización|Autoridades|**I · E**|



#### **Reglas deportivas y de registro** 

|**ID**|**Regla**|**Condición**|**Comportamiento esperado**|**Actores afectados**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|
|RN-007|Un equipo pertenece a una<br>categoría/grupo durante una<br>temporada|Durante su participación|La relación deportiva debe poder identificarse<br>por temporada|Administración|**I · E**|
|RN-008|Una persona es una identidad<br>reutilizable|Cuando tenga uno o más roles|No debe duplicarse la identidad para cada rol|Administración|**S · C**<br>Identidad reutilizable solo si se<br>necesita.|
|RN-009|El registro del jugador está sujeto a<br>reglas|Alta, baja, renovación o<br>transferencia|La operación debe validarse conforme a la<br>temporada|Jugadores / clubes|**P · C**<br>Reglas de registro no validadas.<br>(Q-16)|
|RN-010|La elegibilidad debe comprobarse<br>antes de participar|Antes de una acción que habilite<br>participación|El sistema debe bloquear cuando exista<br>impedimento|Sistema / usuarios<br>operativos|**P · C**<br>Reglas de elegibilidad no validadas.<br>(Q-16)|
|RN-011|La sanción vigente puede impedir<br>participación|Cuando la norma lo establezca|El sistema debe impedir la participación<br>correspondiente|Jugador / equipo /<br>administración|**P · C**<br>Depende de disciplina y AMB-001.<br>(Q-05, Q-17)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 26 

#### **Reglas de programación** 

|**ID**|**Regla**|**Condición**|**Comportamiento esperado**|**Actores afectados**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|
|RN-012|Un equipo no puede aparecer<br>duplicado en conflicto|Generación/edición de jornada|Debe detectarse como conflicto duro|Programador|**I · E**|
|RN-013|Una cancha ocupada no puede<br>reutilizarse en el mismo intervalo|Generación de jornada|Debe bloquearse la asignación conflictiva|Programador|**I · E**|
|RN-014|Una cancha no disponible no puede<br>asignarse|Existe bloqueo/mantenimiento/no<br>disponibilidad|El sistema debe impedir la asignación|Programador|**I · E**|
|RN-018|Los cambios manuales autorizados<br>deben quedar trazados|Al modificar una programación|Registrar usuario, fecha y motivo|Programador /<br>administración|**I · E**|



#### **Reglas de partidos y resultados** 

|**ID**|**Regla**|**Condición**|**Comportamiento esperado**|**Actores afectados**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|
|RN-019|El estado del partido controla<br>acciones|En cualquier momento del ciclo|Sólo deben permitirse acciones válidas para el<br>estado|Todos los usuarios<br>internos|**I · E**|
|RN-020|Los partidos históricos no se eliminan|Un partido posee historial|Debe conservarse|Administración|**I · E**|
|RN-021|Cada transición de estado es<br>auditable|Cambio de estado|Registrar usuario, fecha y motivo|Usuarios internos|**I · E**|
|RN-022|La tabla se deriva de resultados<br>validados|Se oficializa un resultado|Debe actualizarse el cálculo de la tabla|Sistema / administración|**I · E**|
|RN-023|Los desempates dependen de reglas<br>configuradas|Existe igualdad de posiciones|Se deben aplicar los criterios configurados para<br>la temporada|Sistema|**S · E**<br>Desempates de demostración hasta<br>validar los oficiales. (Q-10)|
|RN-024|Una corrección autorizada puede<br>requerir recálculo|Se corrige un resultado oficial|La tabla debe recalcularse y quedar trazada|Administración|**I · E**|
|RN-025|Sólo información validada se publica|Un dato aún no es oficial|No debe mostrarse como oficial en el portal|Sistema / publicación|**I · E**|



#### **Reglas disciplinarias** 

|**ID**|**Regla**|**Condición**|**Comportamiento esperado**|**Actores afectados**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|
|RN-029|La resolución genera vigencia<br>verificable|Se aprueba una sanción|Debe conservarse el periodo de vigencia|Sistema / disciplina|**P · C**<br>Vigencia registrada manualmente si<br>se valida disciplina. (Q-05)|
|RN-030|El historial de resolución es inmutable|Resolución generada|No debe alterarse destructivamente|Autoridades|**P · C**<br>Condicionado a registro de resolución.<br>(Q-05)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 27 

#### **Reglas de promoción y fases finales** 

|**ID**|**Regla**|**Condición**|**Comportamiento esperado**|**Actores afectados**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|
|RN-035|Los casos no automáticos requieren|Regla ambigua/no automatizada|Generar propuesta y solicitar autorización|Autoridades|**I · C**|
||validación||||Principio transversal: lo ambiguo pasa<br>a validación humana.|



#### **3.4.2 Requisitos de datos** 

Principios de diseño de datos respaldados por la fuente: 

- Usar catálogos e identificadores para resolver abreviaturas, nombres variables y formatos no uniformes. 

- Validar duplicados y ambigüedades. 

- No sobrescribir históricos. 

- Separar la identidad de la persona de sus roles. 

- Separar los datos oficiales de los indicadores calculados. 

- Proteger los datos personales. 

- Mantener la trazabilidad de configuraciones y reglas utilizadas. 

Atributos que requieren definición **[PENDIENTE]** : identificador exacto y claves naturales de cada entidad; datos personales obligatorios del jugador; datos específicos del club y el equipo; datos de convocatoria y versionado; campos del resultado; variables de disponibilidad de cancha; auditoría detallada (PEN-018, PEN-019, PEN-022). 

**Datos [PROPUESTA].** La entrega se limita a las entidades de la sección 4.3. Los atributos, cardinalidades y retención siguen **[PENDIENTE]** hasta validar reglas y datos (PEN-018, PEN-019, AMB-005). 

#### **3.4.3 Criterios de aceptación preliminares** 

Criterios iniciales de aceptación que deberán completarse por requisito (historias de usuario y pruebas) en el diseño detallado. 

|**ID**|**Criterio**|**Entrega[PROPUESTA]**|
|---|---|---|
|CA-0<br>01|Las temporadas históricas no se alteran.|**I · E**|
|CA-0<br>02|La programación manual no acepta asignaciones con conflicto duro detectable (equipo duplicado, cancha ocupada o<br>cancha no disponible).|**S · E**<br>Se aplica a la captura manual: no se acepta una asignación con conflicto duro<br>detectable (RF-039). (Q-04)|
|CA-0<br>03|Un resultado validado actualiza la tabla.|**I · E**|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 28 

|**ID**|**Criterio**|**Entrega[PROPUESTA]**|
|---|---|---|
|CA-0<br>04|Una sanción vigente bloquea cuando corresponda.|**P · C**<br>Solo si se valida disciplina y AMB-001. (Q-17)|
|CA-0<br>05|Una resolución genera vigencia verificable.|**P · C**<br>Vigencia registrada manualmente, si se valida. (Q-05)|
|CA-0<br>06|El sistema explica por qué un equipo/persona no puede participar.|**P · C**<br>Depende de reglas de elegibilidad validadas. (Q-16)|
|CA-0<br>07|El portal muestra sólo información publicada.|**I · E**|
|CA-0<br>08|Los cambios críticos quedan auditados.|**I · E**|



**Criterios de la entrega [PROPUESTA].** CA-001, CA-002, CA-003, CA-007 y CA-008 aplican a la entrega. CA-004, CA-005 y CA-006 están pendientes porque dependen de la disciplina reducida, de AMB-001 y de reglas de elegibilidad confirmadas. Los valores cuantitativos de los requisitos no funcionales siguen **[PENDIENTE]** y no son criterios de aceptación (Q-19). 

#### **3.4.4 Requisitos legales y normativos** 

La fuente exige proteger los datos personales (RNF-012) pero no identifica el marco legal aplicable ni las obligaciones concretas, como avisos de privacidad o plazos de conservación. Este marco queda por definir **[PENDIENTE]** (PEN-019, PEN-032). La normativa deportiva proviene del Reglamento y la Convocatoria de la Liga (R4), que deben consultarse para validar las reglas. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 29 

## **4 Modelado del Sistema** 

Este capítulo reúne los modelos que complementan los requisitos: casos de uso, procesos, estados, datos, estructura modular y trazabilidad. Los modelos se derivan de la fuente; cuando el equipo agregó un elemento propio (por ejemplo, la asignación de tareas a carriles en los procesos), se marca como **[PROPUESTA]** . 

### **4.1 Modelo de casos de uso** 

La entrega comprende 10 casos de uso incluidos o simplificados (CU-001 a CU-009 y CU-016) y 2 condicionados y pendientes de decisión (CU-010 y CU-011). Los demás casos de uso de la fuente se listan en 2.6. «Usuario autorizado» representa a cualquier usuario interno con el permiso correspondiente; los roles concretos dependen de la matriz de permisos **[PENDIENTE]** (PEN-010). La línea punteada de CU-001 indica al actor secundario. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 30 



<!-- Start of picture text -->
( Estado de entrega [PROPUESTA] »)<br>eteneeeen<br>Autoridad competente af cu-01L oo<br>(solosi se valida) \__ Registrarresoluciny vigencia 7<br>aan cu-010 te.<br>T_esistarincdente (manual)?<br><!-- End of picture text -->

_Figura 3. Diagrama de casos de uso de la entrega. Discontinuo: pendiente de decisión._ 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 31 

|**Caso de uso**|**Actores**|**Objetivo y precondiciones**|**Flujo principal**|**Alternativas, excepciones**<br>**y postcondición**|**Requisitos**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|**CU-001**<br>Registrar temporada|**Principal:**<br>Administrador<br>general / usuario<br>autorizado.<br>**Secundario:**<br>Autoridad<br>responsable de<br>validación.|**Objetivo:**Crear y configurar un periodo<br>deportivo.<br>**Precondiciones:**Usuario autenticado y<br>autorizado.|registrar temporada → asociar<br>convocatoria → guardar.|**Alternativas:**convocatoria<br>no disponible → dejar<br>configuración pendiente.<br>**Excepciones:**datos<br>incompletos.<br>**Postcondición:**temporada<br>registrada con histórico<br>preservado.|RF-001,<br>RF-002,<br>RF-003.|**S · E**<br>Una temporada de trabajo. (Q-11)|
|**CU-002**<br>Configurar<br>categoría/grupo|**Principal:**<br>Usuario<br>autorizado.|**Objetivo:**Definir estructura deportiva de la<br>temporada.<br>**Precondiciones:**temporada existente.|seleccionar temporada → crear<br>categoría → crear uno o más<br>grupos → guardar.|**Postcondición:**estructura<br>disponible para registrar<br>equipos.|RF-004,<br>RF-005.|**I · E**|
|**CU-003**<br>Registrar club/equipo|**Principal:**<br>Usuario<br>autorizado.|**Objetivo:**Incorporar un club y su<br>representación deportiva.|registrar club → registrar equipo →<br>asociar<br>categoría/grupo/temporada.|—|RF-008,<br>RF-009.|**I · E**|
|**CU-004**<br>Registrar jugador|**Principal:**<br>Usuario<br>autorizado.|**Objetivo:**Incorporar o actualizar el registro<br>competitivo de una persona.|identificar persona → asociar<br>equipo → solicitar alta o baja →<br>validar reglas confirmadas →<br>guardar conservando el historial.|**Alternativas:**datos<br>incompletos; regla no<br>satisfecha.|RF-010 a<br>RF-014;<br>RF-017 y<br>RF-019<br>**[PENDIENT**<br>**E]**.|**S · E**<br>Solo alta/baja básica.|
|**CU-005**<br>Registrar cancha|CU-005 /<br>Registrar cancha|Objetivo: Incorporar una cancha y su<br>disponibilidad.|registrar cancha →<br>características → disponibilidad<br>→ bloqueos.|—|RF-027,<br>RF-029,<br>RF-030.|**S · E**<br>Catálogo mínimo.|
|CU-006 / Registrar y<br>ajustar programación<br>manual|Principal:<br>Programador de<br>partidos [perfil<br>PENDIENTE].|Objetivo: Registrar o ajustar manualmente<br>los partidos de la jornada sin conflictos<br>duros. / Precondiciones: temporada,<br>categoría, grupo, equipos y canchas con<br>disponibilidad registrados.|crear o ajustar el partido<br>(equipos, fecha, hora, cancha)<br>→ validar conflictos duros →<br>guardar en borrador con traza →<br>enviar a revisión.|Alternativas: ajuste<br>posterior autorizado. /<br>Excepciones: conflicto<br>(equipo duplicado,<br>cancha ocupada o<br>cancha no disponible) →<br>rechazar la asignación y<br>explicar el conflicto. /<br>Postcondición:<br>programación en<br>borrador con traza.|RF-033,<br>RF-036,<br>RF-039,<br>RF-040.|**S · E**<br>Captura manual con validación de<br>conflictos; se aplaza la generación<br>automática. (Q-04)|
|**CU-007**<br>Publicar programación|**Principal:**<br>Usuario<br>autorizado.|**Objetivo:**Pasar una programación de<br>revisión a publicación.|seleccionar propuesta → revisar →<br>aprobar → publicar.|—|RF-040,<br>RF-056,<br>RF-090.|**I · E**<br>Aprobación/publicación; quién<br>aprueba: pendiente. (Q-07)|
|**CU-008**<br>Registrar/confirmar<br>resultado|**Principal:**<br>Usuario<br>autorizado.|**Objetivo:**Registrar un resultado y convertirlo<br>en dato oficial cuando corresponda.|capturar marcador → validar →<br>actualizar tabla/estadísticas →<br>conservar histórico.|**Alternativas:**corrección<br>autorizada → recalcular.|RF-047 a<br>RF-050,<br>RF-052,<br>RF-053,<br>RF-055,<br>RF-056.|**I · E**|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 32 

|**Caso de uso**|**Actores**|**Objetivo y precondiciones**|**Flujo principal**|**Alternativas, excepciones**<br>**y postcondición**|**Requisitos**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|---|
|**CU-009**<br>Calcular tabla|**Principal:**<br>Sistema.|**Objetivo:**Calcular posiciones con las reglas<br>configuradas.<br>**Precondiciones:**resultados válidos.|recuperar resultados validados<br>→ calcular estadísticas de<br>equipo → aplicar puntos →<br>aplicar desempates → guardar<br>el resultado de la tabla.|—|RF-049,<br>RF-050,<br>RF-052,<br>RF-053,<br>RF-055.|**I · E**|
|CU-010 / Registrar<br>incidente (manual)<br>**[PENDIENTE]**|Principal:<br>Capturista o<br>usuario<br>autorizado<br>**[PENDIENTE]**.|Objetivo: Registrar manualmente un<br>incidente. Solo si se valida la disciplina<br>reducida (Q-05).|identificar partido → registrar<br>incidente y personas o equipos<br>involucrados → guardar.|—|RF-057,<br>RF-058.|**P · C**<br>Solo si el curso la exige y se valida el<br>alcance manual. (Q-05, Q-06)|
|CU-011 / Registrar<br>resolución y vigencia<br>**[PENDIENTE]**|Principal:<br>Autoridad<br>competente<br>**[PENDIENTE]**.|Objetivo: Registrar la resolución de un<br>caso y su vigencia. Solo si se valida la<br>disciplina reducida (Q-05).|abrir caso → revisar → registrar<br>resolución → registrar vigencia.|Alternativas: devolver a<br>revisión. / Excepciones:<br>alcance de la sanción sin<br>definir → caso en revisión<br>(AMB-001).|RF-062,<br>RF-063,<br>RF-065.|**P · C**<br>Solo si se valida disciplina manual<br>acotada. (Q-05)|
|**CU-016**<br>Consultar portal público|**Principal:**<br>Usuario público.|**Objetivo:**Consultar información publicada.|elegir fecha/categoría/equipo →<br>consultar programación,<br>resultados o tabla publicados →<br>filtrar → visualizar.|—|RF-082 a<br>RF-084,<br>RF-089,<br>RF-090.|**S · E**<br>Tres consultas principales con filtros<br>básicos.|



### **4.2 Modelo de procesos (BPMN)** 

Los procesos se modelan con BPMN 2.0 (R7): círculo verde de borde fino para el inicio, círculo de borde grueso rojo para el fin, círculo doble para un evento de enlace entre partes de un diagrama, rectángulo redondeado para una tarea, rombo con × para una decisión exclusiva y carriles para los actores bajo el pool «Liga». Los procesos largos se dividen en partes enlazadas para que el texto sea legible. 

La fuente describe los pasos, las decisiones y los actores principales de cada proceso. La asignación de cada tarea a un carril se tomó del actor indicado en los RF y los CU y es una **[PROPUESTA]** que debe validarse con la Liga (PEN-005, PEN-010). Se modelan los procesos de la entrega; P-07 y P-08 se listan en 2.6. P-04 (ciclo de vida del partido) se modela como máquina de estados. 

#### **4.2.1 P-01 Configuración de temporada** 

|**Objetivo**|Preparar el marco deportivo y normativo de una temporada.|
|---|---|
|**Inicio y actor iniciador**|Decisión de crear o configurar una nueva temporada. Inicia un usuario autorizado; participan administración y autoridades según sus facultades.|
|**Entradas**|Temporada, convocatoria, categorías, grupos y reglas.|
|**Decisiones**|¿La regla es explícita? ¿Está sujeta a validación?|
|**Salida**|Temporada configurada y versionada.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 33 

|**Excepciones**|Información incompleta; regla no validada (queda pendiente).|
|---|---|
|**Requisitos y casos de uso**|RF-001 a RF-007; CU-001, CU-002.|





<!-- Start of picture text -->
©<br>6<br>3 Continua en parte B<br>S|S| 25s C) temporadaRegistrar; convocatoAsocia r ia eieetayConfigurares Configurarreglas; O<br>E Inicio<br><!-- End of picture text -->

_Figura 4. P-01 Configuración de temporada, parte A de 2._ 



<!-- Start of picture text -->
©<br>s<br>3 Viene de parte A<br>5 Enviar a Marcar regla Versionar<br>2 autorizacién como pendiente configuracién<br>rr Temporada configurada<br>3 éLa regiavalidaci6n?requiere y versionada<br>=oc<br>—<br>z Revisar y<br>2 autorizar 0<br>8 rechazar la<br>FI< reglag Autorizada?.<br><!-- End of picture text -->

_Figura 5. P-01 Configuración de temporada, parte B de 2._ 

#### **4.2.2 P-02 Registro de clubes, equipos y jugadores** 

|**Objetivo**|Mantener la estructura de participantes y el registro de jugadores.|
|---|---|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 34 

|**Inicio**|Alta o modificación de club, equipo o jugador.|
|---|---|
|**Entradas**|Identificación de la persona, datos administrativos, club, equipo, categoría, temporada y operación solicitada.|
|**Decisiones**|¿Datos completos? ¿Registro permitido por las reglas confirmadas? ¿Persona elegible (solo con reglas confirmadas)?|
|**Salida**|Registro válido o solicitud rechazada con causa; el historial se conserva.|
|**Requisitos y casos de uso**|RF-008 a RF-014, RF-017, RF-019, RF-020; CU-003, CU-004.|





<!-- Start of picture text -->
8 eT<br>aE23 Ineo seleecionar club Ja temporada y grupo |] seleccionar persona del jugador registroi yVcanedconservar fysae(Solo conrelas, I1>)| Registro vaso<br>si<br>eal<br>No, | Rechazory mosraria ia solctus causa O<br>Solicitud rechazada<br>Las reglas de alta, baja y legibilidad estén pencientes de volidacién con la Liga (Q-03, @-16).<br><!-- End of picture text -->

_Figura 6. P-02 Registro de clubes, equipos y jugadores (alta y baja básicas) [PROPUESTA]._ 

#### **4.2.3 P-03 Programación manual y publicación** 

|**Objetivo**|Registrar manualmente una programación sin conflictos duros y publicarla tras su aprobación.|
|---|---|
|**Actor iniciador**|Programador de partidos o usuario autorizado [perfil PENDIENTE].|
|**Entradas**|Temporada, categoría, grupo, equipos, canchas y disponibilidad.|
|**Decisiones**|¿Hay conflicto duro? ¿Requiere ajuste manual autorizado? ¿Está aprobada?|
|**Salidas**|Programación en borrador o ajustada, o rechazo con el conflicto explicado; programación publicada.|
|**Restricciones duras**|Equipo duplicado; cancha ocupada; cancha no disponible. La restricción por sanción depende de AMB-001**[PENDIENTE]**.|
|**Requisitos y casos de uso**|RF-033, RF-036, RF-039, RF-040, RF-056, RF-090; CU-006, CU-007.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 35 



<!-- Start of picture text -->
#é£ O partido manuavponosh tech, a imente: oe baieccoad etersra<br>EB]Z| sepaequposy cencnasope vem we<br>EL “esas<br>i le<br>a3id& portRevisor 90 ia si<br>| onecad, caere =teoesn pontlasserrst)<br>intae029 “var ico,oy rr bicas) |<br>i const<br>ai bitteprogramacion, ©<br>i ™<br><!-- End of picture text -->

_Figura 7. P-03 Programación manual y publicación [PROPUESTA]._ 

#### **4.2.4 P-04 Ciclo de vida del partido** 

El estado del partido controla las acciones permitidas. Los estados base son BORRADOR → PROGRAMADO → CONFIRMADO → EN JUEGO → FINALIZADO; los estados alternativos son SUSPENDIDO, CANCELADO, REPROGRAMADO, NO PROGRAMADO y RESUELTO ADMINISTRATIVAMENTE. Los eventos y las transiciones exactas deben validarse con la Liga **[PENDIENTE]** (PEN-008), por lo que el diagrama es preliminar. Los estados mínimos de la entrega están pendientes de decisión (Q-13); la columna «Entrega» de la tabla lo indica. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 36 



<!-- Start of picture text -->
rosie<br>ata et<br>©<br><!-- End of picture text -->

_Figura 8. Estados y transiciones preliminares del partido._ 

|**Estado**|**Tipo**|**Implicación**|**Entrega[PROPUESTA]**|
|---|---|---|---|
|**BORRADOR**|Principal|Se puede preparar información antes de programación definitiva|**P · E**<br>Probable necesario para preparar la<br>programación. (Q-13)|
|**PROGRAMADO**|Principal|Existe una asignación de jornada|**P · E**<br>Probable necesario para publicar la<br>programación. (Q-13)|
|**CONFIRMADO**|Principal|Programación/partido confirmado|**P · C**<br>Estados alternativos por definir. (Q-13)|
|**EN JUEGO**|Principal|Partido en ejecución|**P · C**<br>Estados alternativos por definir. (Q-13)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 37 

|**Estado**|**Tipo**|**Implicación**|**Entrega[PROPUESTA]**|
|---|---|---|---|
|**FINALIZADO**|Principal|Partido concluyó|**P · E**<br>Necesario para registrar el resultado. (Q-13)|
|**SUSPENDIDO**|Alternativo|Interrupción que puede requerir reprogramación|**P · C**<br>Estados alternativos por definir. (Q-13)|
|**CANCELADO**|Alternativo|Partido no se realizará en la programación vigente|**P · C**<br>Estados alternativos por definir. (Q-13)|
|**REPROGRAMADO**|Alternativo|Partido cambia de fecha/hora/sede según reglas|**P · C**<br>Estados alternativos por definir. (Q-13)|
|**NO PROGRAMADO**|Alternativo|Sin programación válida|**P · C**<br>Estados alternativos por definir. (Q-13)|
|**RESUELTO**<br>**ADMINISTRATIVAMENTE**|Alternativo|Resultado/estado resuelto fuera del flujo deportivo normal|**P · C**<br>Estados alternativos por definir. (Q-13)|



**Reglas del proceso:** no se eliminan partidos con historial (RN-020); toda transición registra usuario, fecha y motivo (RN-021); el estado controla las acciones permitidas (RN-019, VAL-008). Requisitos: RF-043 a RF-046. 

#### **4.2.5 P-05 Registro de resultado y actualización de tabla** 

|**Inicio y actor**|Partido finalizado con resultado disponible. Actúa un usuario autorizado.|
|---|---|
|**Entradas**|Marcador, estado y datos oficiales disponibles.|
|**Decisiones**|¿Resultado validado? ¿Es una corrección? ¿Hay empate en la clasificación?|
|**Salida**|Resultado oficial y tabla actualizada; se conserva el histórico.|
|**Requisitos y casos de uso**|RF-047 a RF-050, RF-052, RF-053, RF-055, RF-056; CU-008, CU-009.|





<!-- Start of picture text -->
<Resultado valido?<br>Continua en parte B<br>of C) Capturar si confirmarresultadoMarcar 0 O<br>o| <8 Inicio<br>By) ss No<br>7) 38<br>&<br>Corregir captura<br><!-- End of picture text -->

_Figura 9. P-05 Registro de resultado y actualización de tabla, parte A de 2._ 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 38 



<!-- Start of picture text -->
Aplicar<br>criterios de<br>¢Hay empate? desempate<br>Viene de parte A =<br>O Calcular No.7 Guardar<br>estadisticas Caledets ro histérico<br>Conservar<br>posicion<br>=Cc<br>=|<br>Publicar cuando<br>esté autorizado<br>Resultado oficial y<br>tabla actualizada<br><!-- End of picture text -->

_Figura 10. P-05 Registro de resultado y actualización de tabla, parte B de 2._ 

#### **4.2.6 P-06 Disciplina reducida (pendiente de decisión)** 

|Flujo reducido**[PENDIENTE]**|Solo si se valida: un usuario autorizado registra manualmente un incidente y lo relaciona con la persona o el equipo; una autoridad competente registra la resolución y<br>su vigencia; el sistema conserva la resolución sin alteración destructiva.|
|---|---|
|**Separación de funciones**|La captura (capturista) está separada de la resolución (autoridad competente), DD-010; aplica solo si se valida la disciplina reducida (Q-05).|
|**Decisiones**|¿La autoridad registra la resolución? ¿Está definido el alcance de la sanción?|
|**Alcance de la sanción**|Sobre si afecta la participación, la programación o ambas hay una ambigüedad abierta (AMB-001).|
|**Requisitos y casos de uso**|RF-057, RF-058, RF-062, RF-063, RF-065; CU-010, CU-011.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 39 



<!-- Start of picture text -->
ay (C77 Regarer<br>BZ ~~)<br>se I incidente de forma |<br>4 (rani{con partidoy reacionaro y persona ||<br>28 Incidente en un aaron eee!<br>= Partido (si se valida<br>< 2-05)<br>8 eAlcance de la sancién<br>ge33HeFe i|TGece T TT TTTTTS1 definido? (AMB-001),No,!‘TTT— DejarelcasopendientedeTES5 y||<br>85 ea | validacién (VAL-012, ——O<br>23 { H 1 _VAL-OT3) "| caso envevisién<br>i<br>|| eH 1 resoluciénegistrar sinla 1 O<br>t auditoria (RF-093) 1! 1{ alteraciénposibilidad(RN-030) def| Resolucién registrada<br>Flujo reducido y condicionado: solo si se valida la disciplina (Q-05). El bloqueo derivado de la sancién depende de aclarar AMB-001 (Q-17).<br><!-- End of picture text -->

_Figura 11. P-06 Disciplina reducida y condicionada [PROPUESTA]; solo si se valida (Q-05)._ 

#### **4.2.7 P-09 Flujo de publicación del portal** 

La información pública sigue el flujo Borrador → Revisión → Publicado. En la entrega aplica a la programación, los resultados y la tabla. Solo se publica información validada (RN-025). El flujo exacto de revisión (quién crea y quién aprueba) está por definir **[PENDIENTE]** (PEN-009, Q-07). Requisitos: RF-056, RF-082 a RF-084, RF-089, RF-090; CU-007, CU-016. 



_Figura 12. Estados de publicación de la información del portal._ 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 40 

### **4.3 Modelo de datos conceptual** 

Modelo conceptual preliminar. Las entidades de la tabla provienen de la fuente, salvo las marcadas como **[PROPUESTA]** , que son entidades auxiliares o nombres deducidos del flujo para normalizar el modelo. Las cardinalidades se presentaron como hipótesis y deben validarse antes del diseño lógico (AMB-005). Los atributos exactos están por definir (véase 3.4). 

|**Entidad**|**Propósito**|**Atributos conocidos**|**Origen**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|
|**Persona**|Identidad reutilizable|Datos de identidad/administrativos; detalles exactos<br>**[PENDIENTE]**|Definida en la fuente|**S · E**<br>Atributos mínimos.|
|**Club**|Entidad afiliada|Identificación del club; detalle**[PENDIENTE]**|Definida en la fuente|**I · E**|
|**Equipo**|Representación deportiva de club|Club, categoría, grupo, temporada|Definida en la fuente|**I · E**|
|**Temporada**|Periodo deportivo|Periodo; convocatoria asociada|Definida en la fuente|**I · E**|
|**Convocatoria**|Documento normativo de temporada|Documento/contenido normativo|Definida en la fuente|**S · C**<br>Referencia/versión de reglas.|
|**Categoría**|Nivel/categoría deportiva|Nombre; contexto de temporada|Definida en la fuente|**I · E**|
|**Grupo**|Agrupación dentro de categoría|Identificación del grupo|Definida en la fuente|**I · E**|
|**Competencia/Fase**|Estructura de competencia y fase|Tipo/fase/formato; detalle**[PENDIENTE]**|Definida en la fuente|**P · C**<br>¿Necesaria para tabla y partidos? (Q-14)|
|**Partido**|Unidad competitiva|Local/visitante, fecha/hora, estado, cancha, competencia,<br>incidencias|Definida en la fuente|**I · E**|
|**Cancha**|Recurso físico|Características, disponibilidad, bloqueo/mantenimiento|Definida en la fuente|**I · E**|
|**Incidente**|Hecho disciplinario|Participantes, evidencia, presunta infracción|Definida en la fuente|**P · C**<br>Solo si se valida disciplina.|
|**Resolución**|Determinación de autoridad|Decisión, vigencia; detalle**[PENDIENTE]**|**[PROPUESTA]**entidad auxiliar o<br>nombre deducido|**P · C**<br>Solo si se valida disciplina.|
|**Sanción**|Consecuencia disciplinaria|Vigencia, estado, relación con regla|Definida en la fuente|**P · C**<br>Solo si se valida disciplina.|
|**Resultado**|Marcador/resultado oficial|Marcador, estado; detalle**[PENDIENTE]**|Definida en la fuente|**I · E**|
|**Programación**|Organización de jornada/partidos|Fecha, hora, cancha/sede, estado|Definida en la fuente|**S · E**<br>Jornada/partidos manuales.|
|**Usuario**|Cuenta de acceso|Credenciales/estado; detalle**[PENDIENTE]**|Definida en la fuente|**I · E**|
|**Rol**|Conjunto de permisos|Nombre y permisos|Definida en la fuente|**I · E**<br>Pocos perfiles.|
|**Registro de jugador**|Relación persona-equipo-temporada|Persona, equipo, categoría, temporada, estado, historial|**[PROPUESTA]**entidad auxiliar o<br>nombre deducido|**S · E**<br>Alta/baja y estado.|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 41 

|**Entidad**|**Propósito**|**Atributos conocidos**|**Origen**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|
|**Disponibilidad de**<br>**cancha**|Disponibilidad temporal|Cancha, fecha/hora, estado|**[PROPUESTA]**entidad auxiliar o<br>nombre deducido|**S · E**<br>Mínima.|
|**Auditoría**|Trazabilidad de acciones|Usuario, fecha, acción, motivo/contexto|**[PROPUESTA]**entidad auxiliar o<br>nombre deducido|**S · E**<br>Mínima.|
|**Permiso**|Autorización por módulo/acción|Módulo, acción|**[PROPUESTA]**entidad auxiliar o<br>nombre deducido|**S · E**<br>Matriz mínima pendiente.|



#### **Relaciones principales.** Todas las cardinalidades están por validar. 

|**Origen**|**Relación**|**Destino**|**Cardinalidad**|**Estado**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|---|
|Club|tiene|Equipo por temporada|1:N|**[PENDIENTE]**validar|**I · E**|
|Equipo|pertenece a|Categoría/Grupo|N:1|**[PENDIENTE]**validar|**I · E**|
|Equipo|registra|Persona|N:M mediante Registro|**[PENDIENTE]**validar|**S · E**<br>Registro de jugador como relación.|
|Partido|pertenece a|Competencia/Fase|N:1|**[PENDIENTE]**validar|**P · C**<br>Si se valida Competencia/Fase<br>(Q-14).|
|Partido|usa|Cancha|N:1|**[PENDIENTE]**validar|**I · E**|
|Partido|tiene|Resultado|1:1 cuando finaliza|**[PENDIENTE]**validar|**I · E**|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 42 



<!-- Start of picture text -->
Cardinalidades [PENDIENTE] (AMB-005). 5<br>Ga, par. rN<br> incidente }—______—_sisevaldo_" pesoiucign |—#1¢vala_{' sancién<br>Sirencis<br>(ce } (io)<br>Disponibilidad de cancha<br>| Competencia/Fase ;<br><!-- End of picture text -->

_Figura 13. Modelo entidad-relación preliminar de la entrega. Las cardinalidades están [PENDIENTE] (AMB-005)._ 

Varias entidades del diagrama (REGISTRO_JUGADOR, ROL_USUARIO y PERMISO) son relaciones o entidades auxiliares **[PROPUESTA]** ; sus nombres y cardinalidades deben validarse. Incidente, Resolución y Sanción solo se modelan si se valida la disciplina reducida (Q-05), y Competencia/Fase solo si se valida (Q-14). La relación del Incidente con el Partido sigue **[PENDIENTE]** . 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 43 

### **4.4 Estructura modular y arquitectura conceptual** 



<!-- Start of picture text -->
(Estado de entrega [PROPUESTA] )<br>M-O1 Administracién {M09 Disciplina »)<br>y seguridad \reducida<br>re<br>7<br>M-02 Temporadasy normativa M-03deportivaOrganizaci6n M-04elegibilidadRegistros y M-06y recursosCanchas M-07 ‘manualProgramacién M-08resultadosPartidos y M-11y publicacionPortal piblico eaea<br>|"<br>Pendientede decision |<br><!-- End of picture text -->

_Figura 14. Descomposición modular de la entrega (M-01 a M-04, M-06 a M-08, M-11; M-09 pendiente). No se exige una interfaz o servicio independiente por módulo._ 

Directrices arquitectónicas de la entrega **[PROPUESTA]** : aplicación web responsive; backend modular y una sola aplicación; base de datos relacional; separación lógica entre interfaz, reglas de la demostración, autorización y datos; y un componente lógico de validación de conflictos de programación. No se incluyen API pública, integraciones, almacenamiento documental, CI/CD ni contenedores. Que el frontend sea separado o integrado es una decisión abierta. El stack y la arquitectura deben ser justificados por el equipo. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 44 



<!-- Start of picture text -->
Aplicacién web responsive Unica y modular [PROPUESTA]<br>Vista publica de solo consulta Interfaz interna autenticada<br>(programacién, resultados, tabla) (formularios y listados)<br>Logica de negocio modular:<br>temporadas, equipos, partidos, resultados,<br>tabla, validacién de conflictos<br>a<br>Autenticacion, autorizacién (RBAC minimo) Base de datos relacional<br>y auditoria de acciones criticas (datos internos y publicados separados)<br><!-- End of picture text -->

_Figura 15. Arquitectura conceptual de la entrega [PROPUESTA]: una aplicación modular y una base de datos relacional. El stack y el despliegue siguen [PENDIENTE] (PEN-024 a PEN-026, PEN-036, PEN-037)._ 

#### **Propuestas de diseño del análisis (R3 §18.2).** No son requisitos de la fuente y deben justificarse antes de adoptarse: 

|**ID**|**Propuesta**|**Motivo**|**Estado**|**Entrega[PROPUESTA]**|
|---|---|---|---|---|
|DP-001|Mantener módulos de dominio desacoplados dentro del<br>backend|Reduce acoplamiento y facilita evolución|**[PROPUESTA]**|**I · C**|
|DP-002|Versionar explícitamente reglas de temporada|Alineado con trazabilidad normativa|**[PROPUESTA]**|**S · C**<br>Referencia de reglas por temporada.|
|DP-003|Diseñar una máquina de estados de partido|El estado controla acciones y auditoría|**[PROPUESTA]**|**I · E**|
|DP-004|Tratar Programación como entidad/documento de<br>jornada además de los partidos|Facilita histórico, publicación y trazabilidad|**[PROPUESTA]**|**I · C**|
|DP-005|Mantener un módulo lógico específico para la validación de<br>conflictos de programación|La programación es manual; el problema se reduce a<br>validar conflictos duros|**[PROPUESTA]**|**S · C**<br>Módulo lógico de validación; el generador<br>se aplaza.|
|DP-006|Separar datos publicados de datos internos a nivel de<br>aplicación y autorización|Reduce exposición accidental|**[PROPUESTA]**|**I · E**|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 45 

Decisiones arquitectónicas pendientes **[PENDIENTE]** : stack de frontend; stack de backend; motor de base de datos relacional; estrategia de autenticación y sesión; frontend separado o integrado; y entornos y alojamiento de la demostración (PEN-024 a PEN-026, PEN-030, PEN-036, PEN-037). 

### **4.5 Flujo de información** 

**Flujo por operación.** Entrada del usuario → interfaz → validación de formato y permisos → reglas de negocio → procesamiento del módulo → persistencia transaccional → auditoría → resultado → publicación (solo cuando corresponda). 

**Flujo público.** Datos internos → validación y autorización → estado publicado → portal público → consulta del usuario. No existe flujo inverso desde el portal para editar información. 

**Trazabilidad de la entrega.** Temporada → Categoría → Grupo → Equipo → Jornada/Partido → Resultado → Tabla → Publicación. Cada cambio crítico conserva usuario, fecha y motivo. Si se valida la disciplina, se añade Incidente → Resolución → Sanción **[PENDIENTE]** . 

### **4.6 Matriz de trazabilidad** 

La trazabilidad se presenta a nivel funcional. En el diseño detallado, cada requisito deberá vincularse además con historias de usuario, pruebas y criterios de 

aceptación específicos. 

|**Requisitos**|**Casos de**<br>**uso**|**Proces**<br>**o**|**Módul**<br>**o**|**Pantalla**|**Entidades**|**Entrega**<br>**[PROPUES**<br>**TA]**|
|---|---|---|---|---|---|---|
|RF-001 a RF-007|CU-001,<br>CU-002|P-01|M-02|UI-003,<br>UI-004|Temporada,<br>Convocatoria,<br>Categoría, Grupo|S · E|
|RF-008 a RF-012|CU-003|P-02|M-03|UI-005|Club, Equipo, Persona|S · E|
|RF-013, RF-014;<br>RF-017, RF-019,<br>RF-020**[PENDIENTE]**|CU-004|P-02|M-04|UI-006|Persona, Registro de<br>jugador, Equipo,<br>Temporada|S · E (P para<br>RF-017,<br>019, 020)|
|RF-027, RF-029,<br>RF-030|CU-005|P-03|M-06|UI-008|Cancha, Disponibilidad<br>de cancha|S · E|
|RF-033, RF-036,<br>RF-039, RF-040|CU-006|P-03|M-07|UI-009|Programación, Partido,<br>Equipo, Cancha|S · E|
|RF-043 a RF-046|CU-008|P-04|M-08|UI-010|Partido, estado,<br>Auditoría|S · E|
|RF-047 a RF-050,<br>RF-052, RF-053,<br>RF-055, RF-056|CU-008,<br>CU-009|P-05|M-08|UI-011,<br>UI-012|Resultado, Partido,<br>Equipo|I · E (RF-050<br>pendiente)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 46 

|**Requisitos**|**Casos de**<br>**uso**|**Proces**<br>**o**|**Módul**<br>**o**|**Pantalla**|**Entidades**|**Entrega**<br>**[PROPUES**<br>**TA]**|
|---|---|---|---|---|---|---|
|RF-056, RF-082 a<br>RF-084, RF-089,<br>RF-090|CU-007,<br>CU-016|P-09|M-11|UI-020|Datos publicados de<br>programación,<br>resultados y tabla|I · E|
|RF-093|Transversal|Transve<br>rsal|M-01|UI-022<br>**[PENDIEN**<br>**TE]**|Auditoría|S · E|
|RF-057, RF-058,<br>RF-062, RF-063,<br>RF-065**[PENDIENTE]**|CU-010,<br>CU-011|P-06|M-09|UI-015|Incidente, Resolución,<br>Sanción|P · C|



**Trazabilidad [PROPUESTA].** La matriz cubre solo lo que forma parte de la entrega. Los requisitos aplazados y sus casos de uso, pantallas y entidades se listan en 2.6. 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 47 

## **Apéndice A. Pendientes por definir** 

**Nota de la revisión 0.3 [PROPUESTA].** Los pendientes se conservan con su identificador. La columna «Relación con la entrega» indica si el pendiente aplica a la entrega o a lo que queda fuera (2.6). Las preguntas nuevas están en el Apéndice C. 

Información faltante que debe definirse antes de convertir los elementos relacionados en requisitos definitivos. Se conservan los identificadores PEN de la fuente. 

#### **Requisitos** 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>01|Prioridad formal de cada<br>requisito|Permite ordenar backlog<br>y entregas|Equipo/cliente/<br>profesor|Aplica a la entrega|
|PEN-0<br>02|Alcance exacto de cada actor|Evita permisos<br>incorrectos|Liga /<br>autoridades|Aplica a la entrega|
|PEN-0<br>03|Requisitos de importación de<br>datos históricos|Afecta modelo y<br>migración|Liga|Fuera del alcance (2.6)|
|PEN-0<br>04|Qué operaciones son<br>obligatorias por temporada|Define validaciones y<br>flujos|Liga|Aplica a la entrega|



#### **Procesos** 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>05|Quién crea y quién aprueba<br>programación|Define separación de<br>funciones|Liga|Aplica a la entrega|
|PEN-0<br>06|Qué es obligatorio antes de<br>programar|Define precondiciones<br>del algoritmo|Liga|Aplica a la entrega|
|PEN-0<br>07|Qué ocurre formalmente al<br>bloquear una cancha|Define reprogramación y<br>conflictos|Liga|Aplica a la entrega|
|PEN-0<br>08|Qué sucede ante una<br>suspensión/cancelación|Define estados y<br>transiciones reales|Liga|Aplica a la entrega|
|PEN-0<br>09|Flujo exacto de<br>publicación/revisión|Define gobernanza del<br>portal|Liga|Aplica a la entrega|



#### **Usuarios y permisos** 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>10|Matriz rol → módulo → acción|Es necesaria para<br>implementar RBAC|Liga|Aplica a la entrega|
|PEN-0<br>11|Facultades exactas del Comité<br>Ejecutivo, Secretaría, Tesorería y<br>comisiones|El modelo organizacional<br>requiere facultades<br>explícitas|Liga|Aplica a la entrega|
|PEN-0<br>12|Acciones permitidas a<br>presidente/delegado de club|Define alcance de<br>autoservicio|Liga|Fuera del alcance (2.6)|
|PEN-0<br>13<br>**nterfaz**|Acciones permitidas al jugador|Define participación<br>directa o sólo consulta|Liga|Fuera del alcance (2.6)|
|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|PEN-0<br>14|Prototipo y navegación final|Reduce retrabajo de<br>desarrollo|Equipo +<br>cliente|Aplica a la entrega|



#### **Interfaz** 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 48 

#### **Base de datos** 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>18|Identificadores oficiales y claves|Evita duplicados y<br>ambigüedad|Liga + equipo|Aplica a la entrega|
|PEN-0<br>19|Atributos de persona/jugador|Define protección de<br>datos y formularios|Liga|Aplica a la entrega|
|PEN-0<br>20|Estructura detallada de cédula e<br>incidentes|Es núcleo del módulo<br>disciplinario|Liga / árbitros|Fuera del alcance (2.6)|
|PEN-0<br>21|Catálogo de artículos,<br>infracciones y sanciones|Necesario para motor de<br>reglas disciplinarias|Liga|Fuera del alcance (2.6)|
|PEN-0<br>22|Modelo definitivo de<br>disponibilidad de canchas|Crítico para<br>programación|Liga|Aplica a la entrega|
|PEN-0<br>23|Estructura de<br>documentos/evidencias|Afecta almacenamiento<br>documental|Liga|Fuera del alcance (2.6)|



#### **Arquitectura** 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>24|Stack tecnológico|Requisito para prototipos<br>e implementación|Equipo|Aplica a la entrega|
|PEN-0<br>25|Frontend separado o integrado|Afecta despliegue y<br>arquitectura|Equipo|Aplica a la entrega|
|PEN-0<br>26|Base de datos concreta|Afecta persistencia y<br>despliegue|Equipo|Aplica a la entrega|
|PEN-0<br>27|Estrategia del motor de reglas|Afecta mantenibilidad y<br>pruebas|Equipo|Fuera del alcance (2.6)|
|PEN-0<br>28|Algoritmo de programación|Es un problema técnico<br>central|Equipo +<br>validación con<br>reglas reales|Fuera del alcance (2.6)|



#### **Seguridad** 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>29|Matriz de permisos detallada|Sin ella no se puede<br>implementar autorización<br>correctamente|Liga|Aplica a la entrega|
|PEN-0<br>30|Políticas de<br>sesiones/contraseñas|Convierte seguridad<br>general en controles<br>verificables|Equipo|Aplica a la entrega|
|PEN-0<br>31|Política de respaldo/recuperación|Define continuidad<br>operativa|Liga + equipo|Aplica a la entrega|
|PEN-0<br>32|Datos públicos vs restringidos|Evita exposición de<br>información<br>personal/disciplinaria|Liga|Aplica a la entrega|



#### **Integraciones** 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>33|Integraciones realmente<br>necesarias|Evita sobrecoste y<br>dependencia innecesaria|Liga + equipo|Fuera del alcance (2.6)|
|PEN-0<br>34|Proveedor y presupuesto de<br>WhatsApp/SMS/correo|Afecta factibilidad|Liga|Fuera del alcance (2.6)|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 49 

|**ID**|**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|---|---|---|---|---|
|PEN-0<br>35|Necesidad real de mapas/API<br>pública/autenticación externa|Afecta alcance|Liga + equipo|Fuera del alcance (2.6)|
|**nfraes**<br>**ID**|**tructura**<br>**Pendiente**|**Por qué debe definirse**|**Quién debería**<br>**aclararlo**|**Relación con la**<br>**entrega**<br>**[PROPUESTA]**|
|PEN-0<br>36|Ambiente de<br>desarrollo/pruebas/producción|Necesario para<br>despliegue controlado|Equipo|Aplica a la entrega|
|PEN-0<br>37|Dominio/hosting/infraestructura|Necesario para<br>despliegue funcional|Liga + equipo|Aplica a la entrega|
|PEN-0<br>38|Estrategia CI/CD y contenedores|Necesaria sólo si se<br>adopta|Equipo|Fuera del alcance (2.6)|



#### **Infraestructura** 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 50 

## **Apéndice B. Ambigüedades, riesgos y verificación de fuentes** 

#### **Ambigüedades abiertas** 

|**ID**|**Ambigüedad**|**Impacto**|
|---|---|---|
|AMB-001|Alcance de la sanción: participación, programación o ambas|Afecta reglas, UI, programación y<br>BD|
|AMB-002|Qué resultado se considera oficial|Afecta tablas y publicación|
|AMB-003|Qué elementos pueden publicarse|Afecta privacidad y portal|
|AMB-005|Cardinalidades de datos preliminares|Afecta modelo ER|
|AMB-006|Permisos exactos por cargo/comisión|Afecta seguridad y procesos|



#### **Riesgos identificados** 

|**ID**|**Riesgo**|**Impacto**|**Mitigación**|
|---|---|---|---|
|RSK-001|Reglas pueden requerir<br>interpretación|Automatización incorrecta|Versionado, validación humana y<br>autorización|
|RSK-002|Convocatorias cambian por<br>temporada|Diseño rígido|Configuración versionable|
|RSK-003|Datos históricos no<br>estructurados|Migración/duplicados|Catálogos, identificadores,<br>validación|
|RSK-005|Disciplina exige trazabilidad|Riesgo de perder evidencia o<br>contexto|Modelo de expediente + auditoría +<br>historial inmutable|
|RSK-006|Automatización incorrecta por<br>mala parametrización|Decisiones<br>deportivas/disciplinares<br>erróneas|Validación humana y pruebas con<br>casos reales|
|RSK-007|Exposición de datos personales|Riesgo de privacidad|Separar datos internos/públicos y<br>permisos explícitos|
|RSK-008|Demasiadas decisiones<br>técnicas abiertas|Retraso del desarrollo|Cerrar arquitectura durante sprint de<br>arquitectura|



#### **Contradicciones y verificación del audio** 

**Nota de la revisión 0.3.** AMB-004 (excepciones en reglas) y RSK-004 (programación como problema de restricciones) se retiraron de las tablas porque corresponden a funciones fuera del alcance de la entrega (2.6). 

En el contenido textual de R1 no se identifica ninguna contradicción explícita entre las definiciones centrales. Sí existen varios puntos deliberadamente abiertos que no deben resolverse por suposición. 

El audio del levantamiento (R2) no pudo transcribirse de forma confiable. Antes de cerrar el ERS deben comprobarse las respuestas dadas verbalmente y registrar como contradicción cualquier respuesta que difiera de estas definiciones **[PENDIENTE]** . 

## **Apéndice C. Preguntas pendientes para el equipo, el profesor y la Liga** 

Estas preguntas bloquean o condicionan decisiones de alcance. Mientras no se respondan, los elementos relacionados conservan estado P (pendiente) o se mantienen fuera de la entrega. «Quién» indica quién debería responder **[PROPUESTA]** . 

Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 51 

|**ID**|**Tema**|**Pregunta**|**Elementos**<br>**afectados**|**Quién**|**Estado**|
|---|---|---|---|---|---|
|Q-01|Renovación y<br>transferencia<br>de jugadores|¿Son obligatorias para la evaluación o<br>para la operación real? Si lo son, ¿cuál es<br>la regla vigente de la Liga?|RF-015, RF-016,<br>VAL-001, M-04|Profesor /<br>Liga|Abierta|
|Q-02|Alcance que<br>exige la<br>rúbrica|¿El entregable académico exige<br>implementar todo el alcance del ERS o<br>basta una versión acotada y demostrable?<br>¿Qué funciones exige explícitamente la<br>rúbrica (se necesita la rúbrica por<br>escrito)?|Todo el alcance de<br>entrega|Profesor|Abierta|
|Q-03|Reglamento y<br>Convocatoria<br>como fuente|¿El Reglamento y la Convocatoria 2025–<br>2026 estarán disponibles y validados para<br>el equipo? Sin ellos no se fijan reglas<br>oficiales de puntos, desempates, registro,<br>sanciones ni ascensos.|RF-002, RF-006,<br>RF-007, RN-002, R4|Liga /<br>Profesor|Abierta|
|Q-04|Programación<br>automática|¿Es obligatoria en la evaluación? Si sí,<br>¿basta una primera versión que genere<br>enfrentamientos o debe asignar fechas,<br>horas y canchas?|RF-034, RF-035,<br>RF-037, RF-038,<br>RF-041, RF-042,<br>CU-006, P-03|Profesor|Abierta|
|Q-05|Disciplina en<br>el producto<br>demostrable|¿Debe aparecer? Si sí, ¿basta con<br>registrar manualmente incidencias y<br>resoluciones o se piden cédulas,<br>expediente, recursos, evidencias y<br>castigados? ¿Qué campos son<br>indispensables?|RF-057–RF-068,<br>CU-010, CU-011,<br>P-06, M-09|Profesor /<br>Liga|Abierta|
|Q-06|Arbitraje y<br>cédula|¿Basta con asignar un árbitro como dato<br>del partido y registrar una incidencia<br>textual? ¿Se exige catálogo,<br>disponibilidad y cédula?|RF-021–RF-026,<br>CU-010, UI-007,<br>UI-014|Profesor /<br>Liga|Abierta|
|Q-07|Matriz mínima<br>de permisos|¿Quién puede registrar y quién puede<br>aprobar o publicar programación,<br>resultados y sanciones? ¿Qué perfiles se<br>usarán en la demostración?|RF-040, RF-090,<br>DD-009, RNF-003,<br>PEN-005, PEN-010|Liga /<br>Profesor|Abierta|
|Q-08|Datos de<br>jugadores y<br>privacidad|¿Qué información de jugadores puede<br>almacenar y publicar el prototipo? ¿Deben<br>ser datos ficticios? ¿Qué datos son<br>públicos?|RNF-012, AMB-003,<br>PEN-019, PEN-032|Liga /<br>Profesor|Abierta|
|Q-09|Integraciones,<br>importación,<br>exportación y<br>alojamiento|¿Se requiere carga histórica,<br>notificaciones, exportación o alojamiento<br>accesible en internet? Hoy son<br>dependencias no resueltas.|Integraciones,<br>RF-092, REP-011,<br>PEN-003, PEN-037|Profesor /<br>Liga|Abierta|
|Q-10|Reglas de<br>demostración:<br>puntos y<br>desempates|¿Qué puntuación y criterios de desempate<br>se usarán en la demostración? Si no son<br>oficiales, deben rotularse como datos de<br>demostración.|RF-049, RF-050,<br>RN-023, VAL-011|Liga /<br>Profesor|Abierta|
|Q-11|Temporada,<br>categoría y<br>grupo de<br>demostración|¿Cuál temporada, categoría y grupo se<br>usarán y qué datos pueden usarse (reales<br>autorizados o ficticios)?|RF-001, RF-004,<br>RF-005, CU-001|Profesor /<br>Liga|Abierta|
|Q-12|Resultado<br>oficial|¿Qué se considera resultado oficial y<br>cuándo se vuelve oficial?|AMB-002, RF-048,<br>RF-055, VAL-009|Liga|Abierta|
|Q-13|Estados<br>mínimos del<br>partido|¿Qué estados y transiciones se usarán<br>(suspensión, cancelación, pospuesto)?|RF-043, P-04,<br>PEN-008|Liga|Abierta|
|Q-14|Competencia/<br>Fase en el<br>modelo|¿Debe existir la entidad<br>Competencia/Fase en la entrega o basta<br>temporada–categoría–grupo?|Entidad<br>Competencia/Fase,<br>RF-076|Equipo /<br>Profesor|Abierta|
|Q-15|Auditoría|¿Se requiere una pantalla de consulta de<br>auditoría o basta registrar las acciones<br>críticas?|RF-093, UI-022,<br>REP-010, VAL-016|Profesor /<br>Equipo|Abierta|
|Q-16|Reglas de<br>elegibilidad|¿Qué reglas de registro y bloqueo están<br>confirmadas por la Liga?|RF-017, RF-019,<br>RN-009, RN-010,<br>VAL-002, CA-006|Liga|Abierta|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 52 

|**ID**|**Tema**|**Pregunta**|**Elementos**<br>**afectados**|**Quién**|**Estado**|
|---|---|---|---|---|---|
|Q-17|AMB-001:<br>alcance de la<br>sanción|¿La sanción afecta participación,<br>programación o ambas?|RF-064, RF-020,<br>RN-011, RN-015,<br>VAL-006, CA-004|Liga|Abierta|
|Q-18|Ascensos,<br>descensos y<br>fases finales|¿Se piden en la evaluación? Si no, ¿se<br>registra el cierre fuera del sistema?<br>¿Cuáles son las reglas y el formato?|RF-069–RF-081,<br>CU-014, CU-015,<br>P-07, P-08|Profesor /<br>Liga|Abierta|
|Q-19|Valores<br>cuantitativos<br>de los RNF|¿Qué metas medibles (disponibilidad,<br>rendimiento, accesibilidad, respaldo)<br>acepta el equipo verificar y en qué<br>entorno?|RNF-001, 002, 008,<br>010, 011|Equipo /<br>Profesor|Abierta|
|Q-20|Roles de<br>Scrum y<br>revisión|¿Pueden combinarse responsabilidades<br>de Scrum, análisis, arquitectura,<br>desarrollo y pruebas? ¿Quién revisa<br>código e integración?|Sección 1.2|Equipo /<br>Profesor|Abierta|
|Q-21|RNF-006 y<br>RNF-009|¿Qué criterio medible tendrán la<br>usabilidad y la mantenibilidad?|RNF-006, RNF-009|Equipo|Abierta|
|Q-22|Tabla de<br>aprobaciones|En el registro de aprobaciones el nombre<br>del profesor aparece también como<br>representante de la Liga. ¿Quién es el<br>representante de la Liga? No se corrigió<br>por suposición.|Registro de<br>aprobaciones, 1.2|Equipo|Abierta|
|Q-23|Audio R2 y<br>fuentes R4|¿Quién verificará el audio del<br>levantamiento y consultará el Reglamento<br>y la Convocatoria directamente?|R2, R4, Apéndice B|Equipo|Abierta|
|Q-24|Calendario y<br>entregables|¿Las 10 semanas son el calendario<br>aplicable? ¿Qué se evaluará (ERS,<br>BPMN, arquitectura, prototipo, sistema<br>desplegado, pruebas)? ¿Hay hitos o<br>fechas de entrega?|Sección 2.4, plan|Profesor|Abierta|



## **Apéndice D. Supuestos inevitables [PROPUESTA]** 

Los siguientes supuestos son necesarios para poder proponer el alcance de entrega. **Son propuestas pendientes de aprobación, no requisitos aprobados.** 

|**ID**|**Supuesto**|**Relacionado con**|
|---|---|---|
|S-01|El calendario aplicable es de 10 semanas con un equipo de tres personas (2.4).|Q-24|
|S-02|La entrega cubre una temporada de trabajo y una categoría/grupo de demostración.|Q-11|
|S-03|Se usan datos ficticios o autorizados y reglas de puntos y desempates de demostración<br>rotuladas como no oficiales mientras no haya fuente validada.|Q-03, Q-08, Q-10|
|S-04|Los perfiles se reducen a administración, operación, disciplina (condicional) y público,<br>con nombres y permisos pendientes.|Q-07|
|S-05|La arquitectura es una aplicación modular única con base de datos relacional; el stack<br>y el despliegue son decisión técnica del equipo.|PEN-024 a 026|
|S-06|La prioridad de entrega (E/C/O) es una propuesta; la prioridad de producto<br>(Alta/Media/Baja) no cambia.|Q-02|
|S-07|La auditoría mínima cubre acciones críticas: cambios de programación, resultado y<br>corrección, transiciones de estado del partido y publicación; el contenido exacto está<br>pendiente.|Q-15|
|S-08|La disciplina solo se incluye como registro manual acotado si se valida; en caso<br>contrario queda fuera de la entrega.|Q-05|
|S-09|No se presume que el uso de IA reduzca el esfuerzo de análisis, integración, pruebas o<br>mantenimiento.|—|
|S-10|Mientras no se definan los estados mínimos del partido se mantienen los de la fuente<br>como preliminares.|Q-13|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

ERS · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia 

Rev. 0.3  |  Pág. 53 

|**ID**|**Supuesto**|**Relacionado con**|
|---|---|---|
|S-11|Lo que queda fuera se conserva solo por identificador en 2.6, para trazabilidad.|—|



Borrador para seguimiento · Octubre de 2026 

Descripción de requisitos del software 

