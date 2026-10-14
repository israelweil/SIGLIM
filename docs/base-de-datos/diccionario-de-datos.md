# DICCIONARIO DE BASE DE DATOS 

#### **Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia** 

PostgreSQL / Supabase · ERS Rev. 0.3 · Octubre de 2026 

_Documento técnico derivado del ERS proporcionado._ 

## **1. Introducción** 

Este diccionario documenta el modelo lógico propuesto para la base de datos del Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia. La fuente principal es el ERS Rev. 0.3, cuyo alcance incluye temporadas, categorías, grupos, clubes, equipos, personas, registros de jugadores, canchas, programación manual, partidos, resultados, tabla, publicación y auditoría. Los elementos aplazados o condicionados no se incorporan al núcleo de esta entrega. 

## **2. Motor de base de datos** 

PostgreSQL sobre Supabase. La autenticación se delega a Supabase Auth mediante auth.users; la tabla public.perfiles contiene únicamente información adicional del usuario. 

## **3. Convenciones** 

- Nombres de tablas y columnas en snake_case. 

- Identificadores principales UUID cuando el dominio no exige una clave natural. 

- Fechas y horas operativas con timestamptz para conservar zona horaria. 

- PK y FK explícitas; ON DELETE RESTRICT para preservar historial y CASCADE solo en relaciones auxiliares. 

- CHECK y UNIQUE para reglas estructurales; reglas de negocio que dependen del contexto se implementan mediante funciones/triggers o aplicación. 

- created_at/updated_at solo se agregan a entidades donde aportan trazabilidad operativa. 

- La tabla de posiciones no se almacena: se calcula a partir de resultados oficiales mediante calcular_tabla(). 

## **4. Análisis del ERS y alcance de la BD** 

|**Elemento ERS**|**Tratamiento en BD**|
|---|---|
|M-01 Administraciónyseguridad|perfiles,roles, permisos, perfil_roles,rol_permisos,auditoria|
|M-02 Temporadasynormativa|temporadas,convocatorias,reglas/puntuación en temporada|
|M-03 Organización deportiva|clubes,equipos, personas,categorías, grupos|
|M-04 Registros y elegibilidad|registros_jugador; estados de elegibilidad detallados quedan [PENDIENTE<br>DE DEFINICIÓN]|
|M-06 Canchasyrecursos|canchas,disponibilidad_canchas|
|M-07 Programación|jornadas, partidosyvalidación de conflictos|
|M-08 Partidos y resultados|partidos, historial de estados, resultados, historial de resultados y cálculo<br>de tabla|
|M-11 Portalpúblico|estado depublicacióny políticas de lecturapública|
|M-09 Disciplina|No implementado: condicionado aQ-05; [PENDIENTE DE DEFINICIÓN]|
|Competencia/Fase|No implementada:Q-14; [PENDIENTE DE DEFINICIÓN]|
|Árbitros, fases finales, estadísticas de jugador, exportaciones e<br>integraciones|Fuera del alcance de esta entrega según sección 2.6 del ERS|



## **5. Modelo relacional propuesto** 

Cadena principal: temporada → categoría → grupo → equipo → jornada/partido → resultado oficial → tabla calculada → publicación. La relación persona-equipo-temporada se materializa mediante registros_jugador. La auditoría y el historial de estados/resultados preservan trazabilidad. 

[PROPUESTA TÉCNICA] Se modela 'jornada/programación' mediante la tabla jornadas, porque el ERS describe Programación como organización de partidos y la utiliza en el flujo de publicación. 

### **5.1 perfiles** 

Descripción: Información adicional de una cuenta autenticada de Supabase. 

Módulo: M-01 Administración y seguridad 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|—|PK|auth.users.id|No|Identificador<br>compartido con<br>Supabase Auth|
|nombre_completo|text|NOT NULL|—|No|—|No|Nombre mostrado<br>del usuario interno|
|activo|boolean|NOT NULL|true|No|—|No|Indica si la cuenta<br>está habilitada en<br>la aplicación|
|created_at|timestamptz|NOT NULL|now()|No|—|No|Fecha de creación<br>delperfil|
|updated_at|timestamptz|NOT NULL|now()|No|—|No|Última<br>modificación del<br>perfil|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.2 roles** 

Descripción: Catálogo de perfiles funcionales para RBAC. 

Módulo: M-01 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|bigint|NOT NULL|identity|PK|—|Sí|Identificador del<br>rol|
|nombre|varchar(50)|NOT NULL|—|No|—|Sí|Nombre del rol|
|descripcion|text|NULL|—|No|—|No|Descripción del<br>alcance del rol|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.3 permisos** 

Descripción: Catálogo de acciones por módulo. 

Módulo: M-01 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|bigint|NOT NULL|identity|PK|—|Sí|Identificador del<br>permiso|
|modulo|varchar(60)|NOT NULL|—|No|—|No|Módulo al que<br>pertenece la<br>acción|
|accion|varchar(60)|NOT NULL|—|No|—|No|Acción autorizable|



|descripcion|text|NULL<br>—<br>No<br>—<br>No<br>Descripción del<br>permiso|
|---|---|---|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.4 perfil_roles** 

Descripción: Relación N:M entre usuarios internos y roles. 

#### Módulo: M-01 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|perfil_id|uuid|NOT NULL|—|PK|perfiles.id|No|Perfil asignado|
|rol_id|bigint|NOT NULL|—|PK|roles.id|No|Rol asignado|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.5 rol_permisos** 

Descripción: Relación N:M entre roles y permisos. 

Módulo: M-01 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|rol_id|bigint|NOT NULL|—|PK|roles.id|No|Rol|
|permiso_id|bigint|NOT NULL|—|PK|permisos.id|No|Permiso|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.6 temporadas** 

Descripción: Periodo deportivo y referencia de reglas/puntuación. 

#### Módulo: M-02 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador de<br>temporada|
|nombre|varchar(100)|NOT NULL|—|No|—|No|Nombre del<br>periodo deportivo|
|fecha_inicio|date|NOT NULL|—|No|—|No|Inicio de<br>temporada|
|fecha_fin|date|NULL|—|No|—|No|Fin de temporada,<br>si se conoce|
|estado|estado_temporada|NOT NULL|CONFIGURACION|No|—|CHECK|Estado operativo|
|reglas_version|varchar(100)|NULL|—|No|—|No|Versión/referencia<br>normativa|
|reglas_referencia|text|NULL|—|No|—|No|Referencia de<br>reglas usadas|
|puntos_victoria|integer|NULL|—|No|—|CHECK|Puntospor victoria|
|puntos_empate|integer|NULL|—|No|—|CHECK|Puntospor|



||||||||empate|
|---|---|---|---|---|---|---|---|
|puntos_derrota|integer|NULL|—|No|—|CHECK|Puntospor derrota|
|created_at|timestamptz|NOT NULL|now()|No|—|No|Alta|
|updated_at|timestamptz|NOT NULL|now()|No|—|No|Última<br>modificación|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.7 convocatorias** 

Descripción: Referencia/versionado de la convocatoria asociada a una temporada. 

Módulo: M-02 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|temporada_id|uuid|NOT NULL|—|No|temporadas.id|Sí|Temporada a la<br>quepertenece|
|version|varchar(50)|NULL|—|No|—|No|Versión conocida|
|referencia|text|NOT NULL|—|No|—|No|Referencia<br>documental|
|observaciones|text|NULL|—|No|—|No|Notas sobre la<br>referencia|
|created_at|timestamptz|NOT NULL|now()|No|—|No|Alta|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.8 categorias** 

Descripción: Categorías deportivas configurables por temporada. 

Módulo: M-02/M-03 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|temporada_id|uuid|NOT NULL|—|No|temporadas.id|No|Temporada|
|nombre|varchar(100)|NOT NULL|—|No|—|Sí|Nombre dentro de<br>la temporada|
|descripcion|text|NULL|—|No|—|No|Descripción|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.9 grupos** 

Descripción: Agrupaciones dentro de una categoría. 

Módulo: M-02/M-03 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|categoria_id|uuid|NOT NULL|—|No|categorias.id|No|Categoría|



|nombre|varchar(100)|NOT NULL|—|No|—<br>Sí<br>Nombre del grupo<br>dentro de la|
|---|---|---|---|---|---|
||||||categoría|
|descripcion|text|NULL|—|No|—<br>No<br>Descripción|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.10 clubes** 

Descripción: Entidad afiliada que agrupa representaciones deportivas. 

Módulo: M-03 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|nombre|varchar(150)|NOT NULL|—|No|—|Sí|Nombre del club|
|observaciones|text|NULL|—|No|—|No|Notas<br>administrativas|
|created_at|timestamptz|NOT NULL|now()|No|—|No|Alta<br>|
|updated_at|timestamptz|NOT NULL|now()|No|—|No|Última<br>modificación|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.11 equipos** 

Descripción: Representación deportiva de un club en un grupo/temporada. 

Módulo: M-03 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|club_id|uuid|NOT NULL|—|No|clubes.id|No|Club<br>propietario/afiliado|
|grupo_id|uuid|NOT NULL|—|No|grupos.id|No|Grupo deportivo|
|nombre|varchar(150)|NOT NULL|—|No|—|Sí|Nombre del equipo<br>dentro delgrupo|
|nombre_corto|varchar(60)|NULL|—|No|—|No|Nombre abreviado<br>opcional|
|activo|boolean|NOT NULL|true|No|—|No|Estado operativo|
|created_at|timestamptz|NOT NULL|now()|No|—|No|Alta|
|updated_at|timestamptz|NOT NULL|now()|No|—|No|Última<br>modificación|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.12 personas** 

Descripción: Identidad reutilizable de una persona. 

Módulo: M-03/M-04 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|nombre|varchar(100)|NOT NULL|—|No|—|No|Nombre|
|apellido_paterno|varchar(100)|NOT NULL|—|No|—|No|Primer apellido|
|apellido_materno|varchar(100)|NULL|—|No|—|No|Segundo apellido|
|fecha_nacimiento|date|NULL|—|No|—|No|Fecha de<br>nacimiento;<br>requisito exacto<br>[PENDIENTE DE<br>DEFINICIÓN]|
|datos_administrativos|jsonb|NULL|—|No|—|No|[PROPUESTA<br>TÉCNICA] espacio<br>para datos<br>administrativos<br>aún no<br>especificados|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

[PROPUESTA TÉCNICA] fecha_nacimiento y datos_administrativos se mantienen porque el ERS indica datos personales/administrativos pero deja sus atributos exactos pendientes. 

### **5.13 registros_jugador** 

Descripción: Relación histórica persona-equipo para altas y bajas. 

Módulo: M-04 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador del<br>registro|
|persona_id|uuid|NOT NULL|—|No|personas.id|No|Persona|
|equipo_id|uuid|NOT NULL|—|No|equipos.id|No|Equipo|
|fecha_alta|date|NOT NULL|—|No|—|No|Inicio de<br>pertenencia|
|fecha_baja|date|NULL|—|No|—|No|Fin depertenencia|
|estado|estado_registro_jugador|NOT NULL|ACTIVO|No|—|CHECK|Estado de la<br>relación|
|motivo_baja|text|NULL|—|No|—|No|Motivo de baja si<br>aplica|
|created_at|timestamptz|NOT NULL|now()|No|—|No|Alta<br>|
|updated_at|timestamptz|NOT NULL|now()|No|—|No|Última<br>modificación|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.14 canchas** 

Descripción: Catálogo de recursos físicos usados por la programación. 

#### Módulo: M-06 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|nombre|varchar(150)|NOT NULL|—|No|—|Sí|Nombre de<br>cancha|
|caracteristicas|text|NULL|—|No|—|No|Características<br>conocidas|
|activa|boolean|NOT NULL|true|No|—|No|Disponibilidad<br>operativa del<br>recurso|



|created_at|timestamptz|NOT NULL|now()|No|—<br>No|Alta<br>|
|---|---|---|---|---|---|---|
|updated_at|timestamptz|NOT NULL|now()|No|—<br>No|Última<br>modificación|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.15 disponibilidad_canchas** 

Descripción: Intervalos de disponibilidad o bloqueo de cancha. 

Módulo: M-06 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|cancha_id|uuid|NOT NULL|—|No|canchas.id|No|Cancha|
|periodo|tstzrange|NOT NULL|—|No|—|CHECK|Intervalo<br>temporal|
|tipo|tipo_disponibilidad_cancha|NOT NULL|—|No|—|CHECK|Disponible o<br>bloqueada|
|motivo|text|NULL|—|No|—|No|Motivo del<br>intervalo|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.16 jornadas** 

Descripción: Unidad de programación que agrupa partidos y controla publicación. 

Módulo: M-07/M-11 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|grupo_id|uuid|NOT NULL|—|No|grupos.id|No|Grupo al que<br>pertenece la<br>jornada|
|numero|integer|NULL|—|No|—|CHECK|Número de<br>jornada si se<br>utiliza|
|nombre|varchar(100)|NULL|—|No|—|No|Nombre<br>descriptivo|
|estado_publicacion|estado_publicacion|NOT NULL|BORRADOR|No|—|CHECK|Borrador, revisión<br>opublicado|
|created_by|uuid|NULL|—|No|perfiles.id|No|Usuario creador|
|approved_by|uuid|NULL|—|No|perfiles.id|No|Usuario aprobador|
|approved_at|timestamptz|NULL|—|No|—|No|Fecha de<br>aprobación|
|published_at|timestamptz|NULL|—|No|—|No|Fecha de<br>publicación|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.17 partidos** 

Descripción: Unidad competitiva programada entre dos equipos. 

Módulo: M-07/M-08 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|jornada_id|uuid|NOT NULL|—|No|jornadas.id|No|Jornada|
|equipo_local_id|uuid|NOT NULL|—|No|equipos.id|No|Equipo local|
|equipo_visitante_id|uuid|NOT NULL|—|No|equipos.id|No|Equipo visitante|
|cancha_id|uuid|NULL|—|No|canchas.id|No|Cancha asignada|
|inicio_programado|timestamptz|NOT NULL|—|No|—|No|Inicio|
|fin_programado|timestamptz|NOT NULL|—|No|—|No|Fin|
|estado|estado_partido|NOT NULL|PROGRAMADO|No|—|CHECK|Estado del ciclo de<br>vida|
|motivo_estado|text|NULL|—|No|—|No|Motivo del<br>estado/cambio|
|created_by|uuid|NULL|—|No|perfiles.id|No|Usuario creador|
|updated_by|uuid|NULL|—|No|perfiles.id|No|Usuario del último<br>cambio|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

[PROPUESTA TÉCNICA] fin_programado se incorpora para representar el intervalo necesario para detectar cancha/equipo ocupados. El ERS especifica fecha/hora y conflicto por intervalo, pero no fija una duración; la duración formal debe validarse. 

### **5.18 partido_estados_historial** 

Descripción: Historial de transiciones de estado de un partido. 

Módulo: M-08 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|bigint|NOT NULL|identity|PK|—|No|Identificador|
|partido_id|uuid|NOT NULL|—|No|partidos.id|No|Partido|
|estado_anterior|estado_partido|NULL|—|No|—|No|Estadoprevio|
|estado_nuevo|estado_partido|NOT NULL|—|No|—|No|Nuevo estado|
|usuario_id|uuid|NULL|—|No|perfiles.id|No|Usuario que<br>efectuó la<br>transición|
|fecha|timestamptz|NOT NULL|now()|No|—|No|Fecha de<br>transición|
|motivo|text|NOT NULL|—|No|—|No|Motivo obligatorio|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.19 resultados** 

Descripción: Marcador actual de un partido y su condición oficial. 

#### Módulo: M-08 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|partido_id|uuid|NOT NULL|—|No|partidos.id|Sí|Partido|
|goles_local|integer|NOT NULL|—|No|—|CHECK|Goles del local|
|goles_visitante|integer|NOT NULL|—|No|—|CHECK|Goles del visitante|
|estado|estado_resultado|NOT NULL|CAPTURADO|No|—|CHECK|Estado del<br>resultado|
|es_oficial|boolean|NOT NULL|false|No|—|No|Indica si es|



||||||||resultado oficial|
|---|---|---|---|---|---|---|---|
|validado_por|uuid|NULL|—|No|perfiles.id|No|Usuario validador|
|validado_at|timestamptz|NULL|—|No|—|No|Fecha de<br>validación|
|observaciones|text|NULL|—|No|—|No|Notas|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.20 resultados_historial** 

Descripción: Versiones previas de resultados para conservar correcciones autorizadas. 

#### Módulo: M-08 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|bigint|NOT NULL|identity|PK|—|No|Identificador|
|resultado_id|uuid|NOT NULL|—|No|resultados.id|No|Resultado original|
|partido_id|uuid|NOT NULL|—|No|partidos.id|No|Partido|
|version|integer|NOT NULL|—|No|—|Sí|Número de versión|
|goles_local|integer|NOT NULL|—|No|—|CHECK|Marcador histórico|
|goles_visitante|integer|NOT NULL|—|No|—|CHECK|Marcador histórico|
|estado|estado_resultado|NOT NULL|—|No|—|No|Estado histórico|
|es_oficial|boolean|NOT NULL|—|No|—|No|Condición oficial<br>histórica|
|reemplazado_at|timestamptz|NOT NULL|now()|No|—|No|Fecha de<br>reemplazo|
|reemplazado_por|uuid|NULL|—|No|perfiles.id|No|Usuario que<br>efectuó<br>corrección|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.21 publicaciones** 

Descripción: Control del flujo de publicación de información pública. 

#### Módulo: M-11 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|uuid|NOT NULL|gen_random_uuid()|PK|—|No|Identificador|
|entidad|varchar(50)|NOT NULL|—|No|—|CHECK|Entidad<br>publicable:<br>JORNADA,<br>RESULTADO o<br>TABLA|
|entidad_id|uuid|NOT NULL|—|No|—|No|Identificador de la<br>entidadpublicada|
|estado|estado_publicacion|NOT NULL|BORRADOR|No|—|CHECK|Borrador, revisión<br>opublicado|
|creado_por|uuid|NULL|—|No|perfiles.id|No|Usuario creador|
|revisado_por|uuid|NULL|—|No|perfiles.id|No|Usuario revisor|
|publicado_por|uuid|NULL|—|No|perfiles.id|No|Usuario que<br>publica|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

### **5.22 auditoria** 

Descripción: Registro de acciones críticas para trazabilidad. 

Módulo: M-01 

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda. 

Requisitos relacionados: ver matriz de trazabilidad de la sección 6. 

|**Campo**|**Tipo PostgreSQL**|**Nullable**|**Default**|**PK**|**FK / referencia**|**UNIQUE**|**Descripción**|
|---|---|---|---|---|---|---|---|
|id|bigint|NOT NULL|identity|PK|—|No|Identificador|
|usuario_id|uuid|NULL|—|No|perfiles.id|No|Usuario que<br>ejecutó la acción|
|fecha|timestamptz|NOT NULL|now()|No|—|No|Fecha/hora|
|modulo|varchar(60)|NOT NULL|—|No|—|No|Módulo|
|accion|varchar(60)|NOT NULL|—|No|—|No|Acción|
|tabla_afectada|varchar(100)|NULL|—|No|—|No|Tabla afectada|
|registro_id|uuid|NULL|—|No|—|No|Registro afectado<br>cuando tenga<br>UUID|
|motivo|text|NULL|—|No|—|No|Motivo/contexto|
|contexto|jsonb|NULL|—|No|—|No|Contexto adicional<br>de auditoría|



Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9. 

## **6. Matriz de trazabilidad ERS → BD** 

|**Requisito**|**Funcionalidad**|**Tabla(s) involucradas**|**Campos / mecanismo**|
|---|---|---|---|
|RF-001 a RF-007|Temporadas, convocatoria,<br>categorías, grupos|temporadas, convocatorias,<br>categorias, grupos|fechas, reglas_version,<br>reglas_referencia,relaciones FK|
|RF-008 a RF-012|Clubes, equipos y personas|clubes, equipos, personas,<br>registros_jugador|club_id, grupo_id, persona_id,<br>equipo_id|
|RF-013 a RF-014|Alta/baja básica de jugador|personas, registros_jugador|fecha_alta, fecha_baja, estado,<br>motivo_baja|
|RF-017, RF-019, RF-020|Elegibilidad y sanción|—|[PENDIENTE DE DEFINICIÓN];<br>disciplina no incluida|
|RF-027,RF-029,RF-030|Canchasydisponibilidad|canchas,disponibilidad_canchas|periodo,tipo,motivo|
|RF-033, RF-036, RF-039, RF-040|Programación manual y conflictos|jornadas, partidos,<br>disponibilidad_canchas|inicio_programado, fin_programado,<br>cancha_id;trigger de conflictos|
|RF-043 a RF-046|Ciclo de vida e historial|partidos, partido_estados_historial|estado, motivo_estado, historial de<br>transición|
|RF-047 a RF-056|Resultado, validación y tabla|resultados, resultados_historial|goles, es_oficial, validación, historial;<br>calcular_tabla()|
|RF-082 a RF-084, RF-089, RF-090|Portal público|jornadas, publicaciones, resultados|estado_publicacion, flujo<br>BORRADOR/REVISION/PUBLICADO|
|RF-093|Auditoría|auditoria|usuario_id, fecha, acción,<br>motivo/contexto|
|RN-005, RN-020, RN-024|Preservación de históricos|resultados_historial,<br>partido_estados_historial|historial append-only mediante<br>triggers|
|RNF-003, RNF-012, RNF-015|Seguridad, datos personales, auditoría|perfiles, RLS, auditoria|Supabase Auth, RBAC, RLS,<br>trazabilidad|



## **7. Claves foráneas y cardinalidades** 

|**Origen**|**FK**|**Destino**|**Cardinalidad**|**ON DELETE**|**Justificación**|
|---|---|---|---|---|---|
|perfiles|id|auth.users.id|1:1|CASCADE|El perfil depende de la<br>cuenta Auth.|
|perfil_roles|perfil_id|perfiles.id|N:1|CASCADE|Relación auxiliar de RBAC.|
|perfil_roles|rol_id|roles.id|N:1|RESTRICT|No eliminar roles<br>asignados.|
|rol_permisos|rol_id|roles.id|N:1|CASCADE|Asignaciones auxiliares.|
|rol_permisos|permiso_id|permisos.id|N:1|CASCADE|Asignaciones auxiliares.|
|convocatorias|temporada_id|temporadas.id|1:1|RESTRICT|Una convocatoria de<br>referencia por temporada<br>en este alcance.|
|categorias|temporada_id|temporadas.id|N:1|RESTRICT|La categoría puede variar<br>por temporada.|



|grupos|categoria_id|categorias.id|N:1|RESTRICT|Grupo pertenece a<br>categoría.|
|---|---|---|---|---|---|
|equipos|club_id|clubes.id|N:1|RESTRICT|Equipo representa a un<br>club.|
|equipos|grupo_id|grupos.id|N:1|RESTRICT|Equipoparticipa engrupo.|
|registros_jugador|persona_id|personas.id|N:1|RESTRICT|Preserva historial de<br>pertenencia.|
|registros_jugador|equipo_id|equipos.id|N:1|RESTRICT|No destruir historial al<br>eliminar equipo.|
|disponibilidad_canchas|cancha_id|canchas.id|N:1|RESTRICT|El recurso físico no debe<br>borrarse con historial.|
|jornadas|grupo_id|grupos.id|N:1|RESTRICT|Jornada pertenece a<br>grupo.|
|partidos|jornada_id|jornadas.id|N:1|RESTRICT|No eliminar partidos<br>históricos.|
|partidos|equipo_local_id /<br>equipo_visitante_id|equipos.id|N:1|RESTRICT|Evita equipos huérfanos<br>enpartidos.|
|partidos|cancha_id|canchas.id|N:1|RESTRICT|Conserva referencia<br>histórica.|
|resultados|partido_id|partidos.id|1:1|RESTRICT|Un partido tiene como<br>máximo un resultado<br>actual.|
|resultados_historial|resultado_id|resultados.id|N:1|RESTRICT|Versionado histórico.|
|publicaciones|entidad_id|entidad lógica|N:1 lógico|—|Referencia polimórfica<br>controlada por CHECK; no<br>FK físicapor diseño.|
|auditoria|usuario_id|perfiles.id|N:1|SET NULL|La auditoría debe<br>conservarse aunque el<br>perfil deje de existir.|



## **8. Restricciones y reglas implementadas** 

- PK en todas las tablas; UUID para entidades de dominio y BIGINT identity para bitácoras/catálogos auxiliares. 

- UNIQUE en nombres donde el ERS requiere evitar duplicados dentro del contexto correspondiente. 

- CHECK de fechas de temporada y registros de jugador. 

- CHECK que impide que un partido enfrente al mismo equipo contra sí mismo. 

- CHECK de goles no negativos. 

- CHECK que exige validador y fecha cuando un resultado se marca como oficial. 

- Índice UNIQUE parcial para impedir dos registros ACTIVO simultáneos de la misma persona en el mismo equipo. 

- Trigger de conflictos: equipo duplicado en intervalo, cancha ocupada y cancha bloqueada. 

- Trigger de historial de estados del partido con usuario, fecha y motivo. 

- Trigger de historial de resultados antes de correcciones. 

- Tabla de posiciones calculada; no se persiste como dato duplicado. 

- No se utiliza ON DELETE CASCADE en entidades deportivas históricas. 

## **9. Índices** 

|**Índice**|**Tabla**|**Campo(s)**|**Tipo**|**Motivo**|
|---|---|---|---|---|
|uq_registro_jugador_activo|registros_jugador|persona_id, equipo_id|B-tree UNIQUE parcial|Evitar duplicidad de registro<br>activo.|
|uq_jornada_grupo_numero|jornadas|grupo_id, numero|B-tree UNIQUE parcial|Evitar jornadas repetidas en un<br>grupo.|
|idx_categorias_temporada|categorias|temporada_id|B-tree|FKyconsultaspor temporada.|
|idx_grupos_categoria|grupos|categoria_id|B-tree|FKynavegación degrupos.|
|idx_equipos_club|equipos|club_id|B-tree|Búsquedaspor club.|
|idx_equipos_grupo|equipos|grupo_id|B-tree|Búsquedasporgrupo.|
|idx_registros_jugador_persona|registros_jugador|persona_id|B-tree|Historial de unapersona.|
|idx_registros_jugador_equipo|registros_jugador|equipo_id|B-tree|Jugadores de un equipo.|
|idx_disponibilidad_cancha_periodo|disponibilidad_canchas|cancha_id, periodo|GiST|Solapamiento temporal.|
|idx_jornadas_grupo|jornadas|grupo_id|B-tree|Jornadas degrupo.|
|idx_partidos_jornada|partidos|jornada_id|B-tree|Partidos de unajornada.|
|idx_partidos_inicio|partidos|inicio_programado|B-tree|Próximos partidos y filtros por<br>fecha.|
|idx_partidos_cancha_inicio|partidos|cancha_id,inicio_programado|B-tree|Consultas de ocupación.|
|idx_partidos_equipo_local/visitante|partidos|equipo_local_id /<br>equipo_visitante_id|B-tree|Historial por equipo.|
|idx_resultados_oficiales|resultados|partido_id WHERE es_oficial|B-tree parcial|Consultas de resultados<br>oficiales.|
|idx_auditoria_usuario_fecha|auditoria|usuario_id,fecha DESC|B-tree|Auditoríapor usuarioyfecha.|
|idx_auditoria_fecha|auditoria|fecha DESC|B-tree|Auditoría cronológica.|



idx_publicaciones_entidad_estado publicaciones entidad, entidad_id, estado 

|B-tree|Consulta del estado de<br>publicación.|
|---|---|



## **10. Supabase, autenticación y RLS** 

Supabase Auth es la fuente de credenciales. No se crea una tabla de contraseñas. public.perfiles referencia auth.users.id. El acceso interno se plantea con RBAC mínimo y RLS. 

|**Tabla / ámbito**|**Operación**|**Condición**|**Justificación**|
|---|---|---|---|
|perfiles|SELECT|propio usuario o ADMINISTRADOR|Privacidad de datos de usuario.|
|perfiles|ALL|ADMINISTRADOR|Administración deperfiles.|
|roles/permisos|SELECT|authenticated|Consulta del catálogo RBAC.|
|perfil_roles/rol_permisos|ALL|ADMINISTRADOR|Asignación administrativa.|
|temporadas/categorías/grupos/clubes/equipos|SELECT|authenticated|Operación interna.|
|temporadas/categorías/grupos/clubes/equipos|ALL|ADMINISTRADOR|Gestión administrativa.|
|personas/registros_jugador|SELECT/INSERT/UPDATE|ADMINISTRADOR o CAPTURISTA|Captura operativa; datos personales<br>restringidos.|
|canchas/disponibilidad|ALL|ADMINISTRADOR o PROGRAMADOR|Gestión de recursos.|
|jornadas/partidos|INSERT/UPDATE|ADMINISTRADOR o PROGRAMADOR|Programación manual.|
|resultados|INSERT/UPDATE|ADMINISTRADOR o CAPTURISTA|Captura de resultados.|
|resultados_historial|SELECT|ADMINISTRADOR|Historial sensibleyde trazabilidad.|
|publicaciones|SELECT|anon/authenticated si PUBLICADO|Portalpúblico de solo lectura.|
|publicaciones|ALL|ADMINISTRADOR|Control del flujo depublicación.|
|auditoria|SELECT|ADMINISTRADOR|Consulta de trazabilidad.|



[PENDIENTE DE DEFINICIÓN] La matriz exacta perfil → acción del ERS no está aprobada. Las policies son por tanto una [PROPUESTA TÉCNICA] coherente con los perfiles mínimos de la entrega. 

## **11. Triggers y funciones** 

|**Elemento**|**Tipo**|**Propósito**|**Justificación**|
|---|---|---|---|
|set_updated_at|Función + trigger|Actualizar updated_at|Trazabilidad operativa sin repetir lógica<br>en la aplicación.|
|registrar_transicion_partido|Función + trigger|Guardar estado anterior/nuevo, usuario,<br>fechaymotivo|RF-045 / RN-021.|
|historial_resultado|Función + trigger|Conservar versión anterior antes de una<br>corrección|RF-052 / RN-024 y preservación histórica.|
|validar_conflictos_partido|Función + trigger|Detectar equipo duplicado, cancha<br>ocupadaycancha bloqueada|RF-039 / RN-012 a RN-014.|
|usuario_tiene_rol|Función SECURITY DEFINER|Consultar rolesparapolicies RLS|Implementación RBAC de Supabase.|



## **12. Consultas SQL relacionadas con funcionalidades** 

### **Equipos de un grupo** 

```
SELECT e.id, e.nombre, c.nombre AS club
FROM equipos e JOIN clubes c ON c.id = e.club_id
WHERE e.grupo_id = $1 ORDER BY e.nombre;
```

### **Jugadores activos de un equipo** 

```
SELECT p.id, p.nombre, p.apellido_paterno, p.apellido_materno, r.fecha_alta
FROM registros_jugador r JOIN personas p ON p.id = r.persona_id
WHERE r.equipo_id = $1 AND r.estado = 'ACTIVO';
```

### **Partidos de una jornada** 

```
SELECT p.id, p.inicio_programado, el.nombre AS equipo_local,
ev.nombre AS equipo_visitante, c.nombre AS cancha, p.estado
FROM partidos p JOIN equipos el ON el.id=p.equipo_local_id
JOIN equipos ev ON ev.id=p.equipo_visitante_id LEFT JOIN canchas c ON c.id=p.cancha_id
WHERE p.jornada_id=$1 ORDER BY p.inicio_programado;
```

### **Resultados oficiales** 

```
SELECT p.id, p.inicio_programado, el.nombre AS equipo_local,
ev.nombre AS equipo_visitante, r.goles_local, r.goles_visitante
FROM resultados r JOIN partidos p ON p.id=r.partido_id
JOIN equipos el ON el.id=p.equipo_local_id JOIN equipos ev ON ev.id=p.equipo_visitante_id
WHERE r.es_oficial=true ORDER BY p.inicio_programado DESC;
```

### **Tabla de posiciones** 

```
SELECT * FROM public.calcular_tabla($1::uuid);
```

### **Auditoría** 

```
SELECT * FROM public.auditoria
WHERE ($1::uuid IS NULL OR usuario_id=$1::uuid)
AND fecha >= COALESCE($2::timestamptz,'-infinity'::timestamptz)
AND fecha < COALESCE($3::timestamptz,'infinity'::timestamptz)
ORDER BY fecha DESC;
```

### **Programación publicada** 

```
SELECT j.id AS jornada_id,p.id AS partido_id,p.inicio_programado,
el.nombre AS equipo_local,ev.nombre AS equipo_visitante,c.nombre AS cancha
FROM jornadas j JOIN partidos p ON p.jornada_id=j.id
JOIN equipos el ON el.id=p.equipo_local_id JOIN equipos ev ON ev.id=p.equipo_visitante_id
LEFT JOIN canchas c ON c.id=p.cancha_id
WHERE j.estado_publicacion='PUBLICADO' AND p.inicio_programado >= $1::timestamptz
AND p.inicio_programado < $2::timestamptz ORDER BY p.inicio_programado;
```

## **13. Entidades no implementadas en esta entrega** 

|**Elemento del ERS**|**Estado**|**Motivo**|
|---|---|---|
|Competencia/Fase|[PENDIENTE DE DEFINICIÓN]|Q-14: no se ha confirmado si es necesaria para la<br>entrega.|
|Incidente / Resolución / Sanción|[PENDIENTE DE DEFINICIÓN]|M-09yRF-057/058/062/063/065 dependen deQ-05.|
|Elegibilidad detallada|[PENDIENTE DE DEFINICIÓN]|RF-017/RF-019/RF-020 dependen de reglas<br>confirmadas.|
|Árbitrosydesignaciones|Fuera de alcance|Sección 2.6.|
|Programación automática|Fuera de alcance|Sección 2.6.|
|Renovación/transferencia|Fuera de alcance|Sección 2.6.|
|Histórico de tabla / estadísticas dejugador|Fuera de alcance|Sección 2.6.|
|Ascensos,descensos,liguillayfases finales|Fuera de alcance|Sección 2.6.|
|Portal ampliado, reportes/exportación e<br>integraciones|Fuera de alcance|Sección 2.6.|



## **14. Observaciones y decisiones técnicas** 

|**Tipo**|**Decisión / observación**|
|---|---|
|Requisito del ERS|El ERS exige conservar históricos y no sobrescribir<br>temporadas/partidos/resultados.|
|Decisión técnica|Se implementan historiales para transiciones de partido y versiones de<br>resultados.[PROPUESTA TÉCNICA].|
|Requisito del ERS|La tabla debe calcularse desde resultados validados.|
|Decisión técnica|Se utiliza calcular_tabla() y no una tabla persistente de posiciones. [PROPUESTA<br>TÉCNICA].|
|Requisito del ERS|Laprogramación debe detectar conflictospor equipo,canchaydisponibilidad.|
|Decisión técnica|Se requiere un intervalo inicio/fin en partidos. fin_programado es [PROPUESTA<br>TÉCNICA] porque el ERS no fija duración.|
|Requisito del ERS|Supabase/Auth y la estrategia concreta de autenticación no estaban definidos en<br>el ERS.|
|Decisión técnica|Por el encargo actual se adopta auth.users + public.perfiles. [PROPUESTA<br>TÉCNICA].|
|Pendiente|La matriz exacta depermisospor rol sigue abierta(PEN-010/Q-07).|
|Pendiente|Atributos obligatorios de persona, club, equipo, convocatoria, resultado y<br>disponibilidad siguenpendientes(PEN-018/PEN-019/PEN-022).|
|Pendiente|Las cardinalidades del modelo conceptual requieren validación(AMB-005).|
|Pendiente|La duración formal de partidos y las reglas oficiales de desempate deben<br>validarse.|
|Pendiente|No se almacenan contraseñas ni credencialespropias.|



## **15. Revisión de consistencia** 

- ERS → BD: los módulos incluidos tienen representación en tablas, funciones, RLS o auditoría. 

- BD → ERS: las tablas principales se justifican por las entidades/funciones del alcance; las auxiliares se marcan como decisiones técnicas. 

- Relaciones: las FK apuntan a columnas existentes y las relaciones N:M se resuelven con tablas intermedias. 

- PostgreSQL: se usan tipos, ENUM, CHECK, índices GiST, funciones PL/pgSQL y sintaxis PostgreSQL. 

- Supabase: la identidad se vincula a auth.users y las policies utilizan auth.uid(). 

- Seguridad: no se almacenan contraseñas; los datos personales tienen acceso restringido. 

- Histórico: no se usa CASCADE sobre entidades deportivas que podrían tener historial. 

- Ejecución: extensiones/tipos → tablas → funciones → triggers → índices → RLS → policies → seeds → consultas comentadas. 

- Consultas parametrizadas: se dejan como ejemplos comentados con $1/$2 para no romper la ejecución del SQL Editor. 

## **16. Nota sobre el estado del documento** 

El ERS fuente indica que la revisión 0.3 es un borrador para seguimiento académico y que el alcance propuesto está pendiente de validación. Por ello este diccionario y database.sql deben considerarse una propuesta de diseño derivada del ERS, no una sustitución ni modificación del ERS original. 

## **17. Control de acceso público** 

Para el portal público se evita conceder acceso general de lectura a las tablas internas. Se incorporan tres funciones SECURITY DEFINER, marcadas como [PROPUESTA TÉCNICA], que exponen únicamente programación publicada, resultados oficiales de jornadas publicadas y tabla calculada cuando existe contenido publicado para el grupo. Se concede EXECUTE a anon y authenticated; las tablas internas permanecen protegidas por RLS. 

Consultas públicas previstas: consultar_programacion_publica(desde, hasta), consultar_resultados_publicos(desde, hasta) y consultar_tabla_publica(grupo_id). 

