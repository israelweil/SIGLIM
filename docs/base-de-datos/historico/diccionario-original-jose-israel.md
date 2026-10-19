DICCIONARIO DE BASE DE DATOS

**Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia**
PostgreSQL / Supabase · ERS Rev. 0.3 · Octubre de 2026

*Documento técnico derivado del ERS proporcionado. El ERS se encuentra en estado de borrador y pendiente de validación formal.*

# 1. Introducción

Este diccionario documenta el modelo lógico propuesto para la base de datos del Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia. La fuente principal es el ERS Rev. 0.3, cuyo alcance incluye temporadas, categorías, grupos, clubes, equipos, personas, registros de jugadores, canchas, programación manual, partidos, resultados, tabla, publicación y auditoría. Los elementos aplazados o condicionados no se incorporan al núcleo de esta entrega.

# 2. Motor de base de datos

PostgreSQL sobre Supabase. La autenticación se delega a Supabase Auth mediante auth.users; la tabla public.perfiles contiene únicamente información adicional del usuario.

# 3. Convenciones

* Nombres de tablas y columnas en snake\_case.
* Identificadores principales UUID cuando el dominio no exige una clave natural.
* Fechas y horas operativas con timestamptz para conservar zona horaria.
* PK y FK explícitas; ON DELETE RESTRICT para preservar historial y CASCADE solo en relaciones auxiliares.
* CHECK y UNIQUE para reglas estructurales; reglas de negocio que dependen del contexto se implementan mediante funciones/triggers o aplicación.
* created\_at/updated\_at solo se agregan a entidades donde aportan trazabilidad operativa.
* La tabla de posiciones no se almacena: se calcula a partir de resultados oficiales mediante calcular\_tabla().

# 4. Análisis del ERS y alcance de la BD

|  |  |
| --- | --- |
| **Elemento ERS** | **Tratamiento en BD** |
| M-01 Administración y seguridad | perfiles, roles, permisos, perfil\_roles, rol\_permisos, auditoria |
| M-02 Temporadas y normativa | temporadas, convocatorias, reglas/puntuación en temporada |
| M-03 Organización deportiva | clubes, equipos, personas, categorías, grupos |
| M-04 Registros y elegibilidad | registros\_jugador; estados de elegibilidad detallados quedan [PENDIENTE DE DEFINICIÓN] |
| M-06 Canchas y recursos | canchas, disponibilidad\_canchas |
| M-07 Programación | jornadas, partidos y validación de conflictos |
| M-08 Partidos y resultados | partidos, historial de estados, resultados, historial de resultados y cálculo de tabla |
| M-11 Portal público | estado de publicación y políticas de lectura pública |
| M-09 Disciplina | No implementado: condicionado a Q-05; [PENDIENTE DE DEFINICIÓN] |
| Competencia/Fase | No implementada: Q-14; [PENDIENTE DE DEFINICIÓN] |
| Árbitros, fases finales, estadísticas de jugador, exportaciones e integraciones | Fuera del alcance de esta entrega según sección 2.6 del ERS |

# 5. Modelo relacional propuesto

Cadena principal: temporada ? categoría ? grupo ? equipo ? jornada/partido ? resultado oficial ? tabla calculada ? publicación. La relación persona-equipo-temporada se materializa mediante registros\_jugador. La auditoría y el historial de estados/resultados preservan trazabilidad.

[PROPUESTA TÉCNICA] Se modela 'jornada/programación' mediante la tabla jornadas, porque el ERS describe Programación como organización de partidos y la utiliza en el flujo de publicación.

## 5.1 perfiles

Descripción: Información adicional de una cuenta autenticada de Supabase.

Módulo: M-01 Administración y seguridad

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | — | PK | auth.users.id | No | Identificador compartido con Supabase Auth |
| nombre\_completo | text | NOT NULL | — | No | — | No | Nombre mostrado del usuario interno |
| activo | boolean | NOT NULL | true | No | — | No | Indica si la cuenta está habilitada en la aplicación |
| created\_at | timestamptz | NOT NULL | now() | No | — | No | Fecha de creación del perfil |
| updated\_at | timestamptz | NOT NULL | now() | No | — | No | Última modificación del perfil |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.2 roles

Descripción: Catálogo de perfiles funcionales para RBAC.

Módulo: M-01

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | bigint | NOT NULL | identity | PK | — | Sí | Identificador del rol |
| nombre | varchar(50) | NOT NULL | — | No | — | Sí | Nombre del rol |
| descripcion | text | NULL | — | No | — | No | Descripción del alcance del rol |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.3 permisos

Descripción: Catálogo de acciones por módulo.

Módulo: M-01

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | bigint | NOT NULL | identity | PK | — | Sí | Identificador del permiso |
| modulo | varchar(60) | NOT NULL | — | No | — | No | Módulo al que pertenece la acción |
| accion | varchar(60) | NOT NULL | — | No | — | No | Acción autorizable |
| descripcion | text | NULL | — | No | — | No | Descripción del permiso |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.4 perfil\_roles

Descripción: Relación N:M entre usuarios internos y roles.

Módulo: M-01

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| perfil\_id | uuid | NOT NULL | — | PK | perfiles.id | No | Perfil asignado |
| rol\_id | bigint | NOT NULL | — | PK | roles.id | No | Rol asignado |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.5 rol\_permisos

Descripción: Relación N:M entre roles y permisos.

Módulo: M-01

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| rol\_id | bigint | NOT NULL | — | PK | roles.id | No | Rol |
| permiso\_id | bigint | NOT NULL | — | PK | permisos.id | No | Permiso |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.6 temporadas

Descripción: Periodo deportivo y referencia de reglas/puntuación.

Módulo: M-02

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador de temporada |
| nombre | varchar(100) | NOT NULL | — | No | — | No | Nombre del periodo deportivo |
| fecha\_inicio | date | NOT NULL | — | No | — | No | Inicio de temporada |
| fecha\_fin | date | NULL | — | No | — | No | Fin de temporada, si se conoce |
| estado | estado\_temporada | NOT NULL | CONFIGURACION | No | — | CHECK | Estado operativo |
| reglas\_version | varchar(100) | NULL | — | No | — | No | Versión/referencia normativa |
| reglas\_referencia | text | NULL | — | No | — | No | Referencia de reglas usadas |
| puntos\_victoria | integer | NULL | — | No | — | CHECK | Puntos por victoria |
| puntos\_empate | integer | NULL | — | No | — | CHECK | Puntos por empate |
| puntos\_derrota | integer | NULL | — | No | — | CHECK | Puntos por derrota |
| created\_at | timestamptz | NOT NULL | now() | No | — | No | Alta |
| updated\_at | timestamptz | NOT NULL | now() | No | — | No | Última modificación |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.7 convocatorias

Descripción: Referencia/versionado de la convocatoria asociada a una temporada.

Módulo: M-02

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| temporada\_id | uuid | NOT NULL | — | No | temporadas.id | Sí | Temporada a la que pertenece |
| version | varchar(50) | NULL | — | No | — | No | Versión conocida |
| referencia | text | NOT NULL | — | No | — | No | Referencia documental |
| observaciones | text | NULL | — | No | — | No | Notas sobre la referencia |
| created\_at | timestamptz | NOT NULL | now() | No | — | No | Alta |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.8 categorias

Descripción: Categorías deportivas configurables por temporada.

Módulo: M-02/M-03

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| temporada\_id | uuid | NOT NULL | — | No | temporadas.id | No | Temporada |
| nombre | varchar(100) | NOT NULL | — | No | — | Sí | Nombre dentro de la temporada |
| descripcion | text | NULL | — | No | — | No | Descripción |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.9 grupos

Descripción: Agrupaciones dentro de una categoría.

Módulo: M-02/M-03

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| categoria\_id | uuid | NOT NULL | — | No | categorias.id | No | Categoría |
| nombre | varchar(100) | NOT NULL | — | No | — | Sí | Nombre del grupo dentro de la categoría |
| descripcion | text | NULL | — | No | — | No | Descripción |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.10 clubes

Descripción: Entidad afiliada que agrupa representaciones deportivas.

Módulo: M-03

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| nombre | varchar(150) | NOT NULL | — | No | — | Sí | Nombre del club |
| observaciones | text | NULL | — | No | — | No | Notas administrativas |
| created\_at | timestamptz | NOT NULL | now() | No | — | No | Alta |
| updated\_at | timestamptz | NOT NULL | now() | No | — | No | Última modificación |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.11 equipos

Descripción: Representación deportiva de un club en un grupo/temporada.

Módulo: M-03

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| club\_id | uuid | NOT NULL | — | No | clubes.id | No | Club propietario/afiliado |
| grupo\_id | uuid | NOT NULL | — | No | grupos.id | No | Grupo deportivo |
| nombre | varchar(150) | NOT NULL | — | No | — | Sí | Nombre del equipo dentro del grupo |
| nombre\_corto | varchar(60) | NULL | — | No | — | No | Nombre abreviado opcional |
| activo | boolean | NOT NULL | true | No | — | No | Estado operativo |
| created\_at | timestamptz | NOT NULL | now() | No | — | No | Alta |
| updated\_at | timestamptz | NOT NULL | now() | No | — | No | Última modificación |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.12 personas

Descripción: Identidad reutilizable de una persona.

Módulo: M-03/M-04

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| nombre | varchar(100) | NOT NULL | — | No | — | No | Nombre |
| apellido\_paterno | varchar(100) | NOT NULL | — | No | — | No | Primer apellido |
| apellido\_materno | varchar(100) | NULL | — | No | — | No | Segundo apellido |
| fecha\_nacimiento | date | NULL | — | No | — | No | Fecha de nacimiento; requisito exacto [PENDIENTE DE DEFINICIÓN] |
| datos\_administrativos | jsonb | NULL | — | No | — | No | [PROPUESTA TÉCNICA] espacio para datos administrativos aún no especificados |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

[PROPUESTA TÉCNICA] fecha\_nacimiento y datos\_administrativos se mantienen porque el ERS indica datos personales/administrativos pero deja sus atributos exactos pendientes.

## 5.13 registros\_jugador

Descripción: Relación histórica persona-equipo para altas y bajas.

Módulo: M-04

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador del registro |
| persona\_id | uuid | NOT NULL | — | No | personas.id | No | Persona |
| equipo\_id | uuid | NOT NULL | — | No | equipos.id | No | Equipo |
| fecha\_alta | date | NOT NULL | — | No | — | No | Inicio de pertenencia |
| fecha\_baja | date | NULL | — | No | — | No | Fin de pertenencia |
| estado | estado\_registro\_jugador | NOT NULL | ACTIVO | No | — | CHECK | Estado de la relación |
| motivo\_baja | text | NULL | — | No | — | No | Motivo de baja si aplica |
| created\_at | timestamptz | NOT NULL | now() | No | — | No | Alta |
| updated\_at | timestamptz | NOT NULL | now() | No | — | No | Última modificación |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.14 canchas

Descripción: Catálogo de recursos físicos usados por la programación.

Módulo: M-06

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| nombre | varchar(150) | NOT NULL | — | No | — | Sí | Nombre de cancha |
| caracteristicas | text | NULL | — | No | — | No | Características conocidas |
| activa | boolean | NOT NULL | true | No | — | No | Disponibilidad operativa del recurso |
| created\_at | timestamptz | NOT NULL | now() | No | — | No | Alta |
| updated\_at | timestamptz | NOT NULL | now() | No | — | No | Última modificación |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.15 disponibilidad\_canchas

Descripción: Intervalos de disponibilidad o bloqueo de cancha.

Módulo: M-06

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| cancha\_id | uuid | NOT NULL | — | No | canchas.id | No | Cancha |
| periodo | tstzrange | NOT NULL | — | No | — | CHECK | Intervalo temporal |
| tipo | tipo\_disponibilidad\_cancha | NOT NULL | — | No | — | CHECK | Disponible o bloqueada |
| motivo | text | NULL | — | No | — | No | Motivo del intervalo |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.16 jornadas

Descripción: Unidad de programación que agrupa partidos y controla publicación.

Módulo: M-07/M-11

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| grupo\_id | uuid | NOT NULL | — | No | grupos.id | No | Grupo al que pertenece la jornada |
| numero | integer | NULL | — | No | — | CHECK | Número de jornada si se utiliza |
| nombre | varchar(100) | NULL | — | No | — | No | Nombre descriptivo |
| estado\_publicacion | estado\_publicacion | NOT NULL | BORRADOR | No | — | CHECK | Borrador, revisión o publicado |
| created\_by | uuid | NULL | — | No | perfiles.id | No | Usuario creador |
| approved\_by | uuid | NULL | — | No | perfiles.id | No | Usuario aprobador |
| approved\_at | timestamptz | NULL | — | No | — | No | Fecha de aprobación |
| published\_at | timestamptz | NULL | — | No | — | No | Fecha de publicación |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.17 partidos

Descripción: Unidad competitiva programada entre dos equipos.

Módulo: M-07/M-08

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| jornada\_id | uuid | NOT NULL | — | No | jornadas.id | No | Jornada |
| equipo\_local\_id | uuid | NOT NULL | — | No | equipos.id | No | Equipo local |
| equipo\_visitante\_id | uuid | NOT NULL | — | No | equipos.id | No | Equipo visitante |
| cancha\_id | uuid | NULL | — | No | canchas.id | No | Cancha asignada |
| inicio\_programado | timestamptz | NOT NULL | — | No | — | No | Inicio |
| fin\_programado | timestamptz | NOT NULL | — | No | — | No | Fin |
| estado | estado\_partido | NOT NULL | PROGRAMADO | No | — | CHECK | Estado del ciclo de vida |
| motivo\_estado | text | NULL | — | No | — | No | Motivo del estado/cambio |
| created\_by | uuid | NULL | — | No | perfiles.id | No | Usuario creador |
| updated\_by | uuid | NULL | — | No | perfiles.id | No | Usuario del último cambio |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

[PROPUESTA TÉCNICA] fin\_programado se incorpora para representar el intervalo necesario para detectar cancha/equipo ocupados. El ERS especifica fecha/hora y conflicto por intervalo, pero no fija una duración; la duración formal debe validarse.

## 5.18 partido\_estados\_historial

Descripción: Historial de transiciones de estado de un partido.

Módulo: M-08

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | bigint | NOT NULL | identity | PK | — | No | Identificador |
| partido\_id | uuid | NOT NULL | — | No | partidos.id | No | Partido |
| estado\_anterior | estado\_partido | NULL | — | No | — | No | Estado previo |
| estado\_nuevo | estado\_partido | NOT NULL | — | No | — | No | Nuevo estado |
| usuario\_id | uuid | NULL | — | No | perfiles.id | No | Usuario que efectuó la transición |
| fecha | timestamptz | NOT NULL | now() | No | — | No | Fecha de transición |
| motivo | text | NOT NULL | — | No | — | No | Motivo obligatorio |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.19 resultados

Descripción: Marcador actual de un partido y su condición oficial.

Módulo: M-08

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| partido\_id | uuid | NOT NULL | — | No | partidos.id | Sí | Partido |
| goles\_local | integer | NOT NULL | — | No | — | CHECK | Goles del local |
| goles\_visitante | integer | NOT NULL | — | No | — | CHECK | Goles del visitante |
| estado | estado\_resultado | NOT NULL | CAPTURADO | No | — | CHECK | Estado del resultado |
| es\_oficial | boolean | NOT NULL | false | No | — | No | Indica si es resultado oficial |
| validado\_por | uuid | NULL | — | No | perfiles.id | No | Usuario validador |
| validado\_at | timestamptz | NULL | — | No | — | No | Fecha de validación |
| observaciones | text | NULL | — | No | — | No | Notas |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.20 resultados\_historial

Descripción: Versiones previas de resultados para conservar correcciones autorizadas.

Módulo: M-08

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | bigint | NOT NULL | identity | PK | — | No | Identificador |
| resultado\_id | uuid | NOT NULL | — | No | resultados.id | No | Resultado original |
| partido\_id | uuid | NOT NULL | — | No | partidos.id | No | Partido |
| version | integer | NOT NULL | — | No | — | Sí | Número de versión |
| goles\_local | integer | NOT NULL | — | No | — | CHECK | Marcador histórico |
| goles\_visitante | integer | NOT NULL | — | No | — | CHECK | Marcador histórico |
| estado | estado\_resultado | NOT NULL | — | No | — | No | Estado histórico |
| es\_oficial | boolean | NOT NULL | — | No | — | No | Condición oficial histórica |
| reemplazado\_at | timestamptz | NOT NULL | now() | No | — | No | Fecha de reemplazo |
| reemplazado\_por | uuid | NULL | — | No | perfiles.id | No | Usuario que efectuó corrección |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.21 publicaciones

Descripción: Control del flujo de publicación de información pública.

Módulo: M-11

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | uuid | NOT NULL | gen\_random\_uuid() | PK | — | No | Identificador |
| entidad | varchar(50) | NOT NULL | — | No | — | CHECK | Entidad publicable: JORNADA, RESULTADO o TABLA |
| entidad\_id | uuid | NOT NULL | — | No | — | No | Identificador de la entidad publicada |
| estado | estado\_publicacion | NOT NULL | BORRADOR | No | — | CHECK | Borrador, revisión o publicado |
| creado\_por | uuid | NULL | — | No | perfiles.id | No | Usuario creador |
| revisado\_por | uuid | NULL | — | No | perfiles.id | No | Usuario revisor |
| publicado\_por | uuid | NULL | — | No | perfiles.id | No | Usuario que publica |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

## 5.22 auditoria

Descripción: Registro de acciones críticas para trazabilidad.

Módulo: M-01

Tipo de entidad: entidad principal, catálogo o relación auxiliar según corresponda.

Requisitos relacionados: ver matriz de trazabilidad de la sección 6.

|  |  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Campo** | **Tipo PostgreSQL** | **Nullable** | **Default** | **PK** | **FK / referencia** | **UNIQUE** | **Descripción** |
| id | bigint | NOT NULL | identity | PK | — | No | Identificador |
| usuario\_id | uuid | NULL | — | No | perfiles.id | No | Usuario que ejecutó la acción |
| fecha | timestamptz | NOT NULL | now() | No | — | No | Fecha/hora |
| modulo | varchar(60) | NOT NULL | — | No | — | No | Módulo |
| accion | varchar(60) | NOT NULL | — | No | — | No | Acción |
| tabla\_afectada | varchar(100) | NULL | — | No | — | No | Tabla afectada |
| registro\_id | uuid | NULL | — | No | — | No | Registro afectado cuando tenga UUID |
| motivo | text | NULL | — | No | — | No | Motivo/contexto |
| contexto | jsonb | NULL | — | No | — | No | Contexto adicional de auditoría |

Relaciones y restricciones: las FK y CHECK se detallan en las secciones 7 y 8. Los índices específicos se documentan en la sección 9.

# 6. Matriz de trazabilidad ERS ? BD

|  |  |  |  |
| --- | --- | --- | --- |
| **Requisito** | **Funcionalidad** | **Tabla(s) involucradas** | **Campos / mecanismo** |
| RF-001 a RF-007 | Temporadas, convocatoria, categorías, grupos | temporadas, convocatorias, categorias, grupos | fechas, reglas\_version, reglas\_referencia, relaciones FK |
| RF-008 a RF-012 | Clubes, equipos y personas | clubes, equipos, personas, registros\_jugador | club\_id, grupo\_id, persona\_id, equipo\_id |
| RF-013 a RF-014 | Alta/baja básica de jugador | personas, registros\_jugador | fecha\_alta, fecha\_baja, estado, motivo\_baja |
| RF-017, RF-019, RF-020 | Elegibilidad y sanción | — | [PENDIENTE DE DEFINICIÓN]; disciplina no incluida |
| RF-027, RF-029, RF-030 | Canchas y disponibilidad | canchas, disponibilidad\_canchas | periodo, tipo, motivo |
| RF-033, RF-036, RF-039, RF-040 | Programación manual y conflictos | jornadas, partidos, disponibilidad\_canchas | inicio\_programado, fin\_programado, cancha\_id; trigger de conflictos |
| RF-043 a RF-046 | Ciclo de vida e historial | partidos, partido\_estados\_historial | estado, motivo\_estado, historial de transición |
| RF-047 a RF-056 | Resultado, validación y tabla | resultados, resultados\_historial | goles, es\_oficial, validación, historial; calcular\_tabla() |
| RF-082 a RF-084, RF-089, RF-090 | Portal público | jornadas, publicaciones, resultados | estado\_publicacion, flujo BORRADOR/REVISION/PUBLICADO |
| RF-093 | Auditoría | auditoria | usuario\_id, fecha, acción, motivo/contexto |
| RN-005, RN-020, RN-024 | Preservación de históricos | resultados\_historial, partido\_estados\_historial | historial append-only mediante triggers |
| RNF-003, RNF-012, RNF-015 | Seguridad, datos personales, auditoría | perfiles, RLS, auditoria | Supabase Auth, RBAC, RLS, trazabilidad |

# 7. Claves foráneas y cardinalidades

|  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- |
| **Origen** | **FK** | **Destino** | **Cardinalidad** | **ON DELETE** | **Justificación** |
| perfiles | id | auth.users.id | 1:1 | CASCADE | El perfil depende de la cuenta Auth. |
| perfil\_roles | perfil\_id | perfiles.id | N:1 | CASCADE | Relación auxiliar de RBAC. |
| perfil\_roles | rol\_id | roles.id | N:1 | RESTRICT | No eliminar roles asignados. |
| rol\_permisos | rol\_id | roles.id | N:1 | CASCADE | Asignaciones auxiliares. |
| rol\_permisos | permiso\_id | permisos.id | N:1 | CASCADE | Asignaciones auxiliares. |
| convocatorias | temporada\_id | temporadas.id | 1:1 | RESTRICT | Una convocatoria de referencia por temporada en este alcance. |
| categorias | temporada\_id | temporadas.id | N:1 | RESTRICT | La categoría puede variar por temporada. |
| grupos | categoria\_id | categorias.id | N:1 | RESTRICT | Grupo pertenece a categoría. |
| equipos | club\_id | clubes.id | N:1 | RESTRICT | Equipo representa a un club. |
| equipos | grupo\_id | grupos.id | N:1 | RESTRICT | Equipo participa en grupo. |
| registros\_jugador | persona\_id | personas.id | N:1 | RESTRICT | Preserva historial de pertenencia. |
| registros\_jugador | equipo\_id | equipos.id | N:1 | RESTRICT | No destruir historial al eliminar equipo. |
| disponibilidad\_canchas | cancha\_id | canchas.id | N:1 | RESTRICT | El recurso físico no debe borrarse con historial. |
| jornadas | grupo\_id | grupos.id | N:1 | RESTRICT | Jornada pertenece a grupo. |
| partidos | jornada\_id | jornadas.id | N:1 | RESTRICT | No eliminar partidos históricos. |
| partidos | equipo\_local\_id / equipo\_visitante\_id | equipos.id | N:1 | RESTRICT | Evita equipos huérfanos en partidos. |
| partidos | cancha\_id | canchas.id | N:1 | RESTRICT | Conserva referencia histórica. |
| resultados | partido\_id | partidos.id | 1:1 | RESTRICT | Un partido tiene como máximo un resultado actual. |
| resultados\_historial | resultado\_id | resultados.id | N:1 | RESTRICT | Versionado histórico. |
| publicaciones | entidad\_id | entidad lógica | N:1 lógico | — | Referencia polimórfica controlada por CHECK; no FK física por diseño. |
| auditoria | usuario\_id | perfiles.id | N:1 | SET NULL | La auditoría debe conservarse aunque el perfil deje de existir. |

# 8. Restricciones y reglas implementadas

* PK en todas las tablas; UUID para entidades de dominio y BIGINT identity para bitácoras/catálogos auxiliares.
* UNIQUE en nombres donde el ERS requiere evitar duplicados dentro del contexto correspondiente.
* CHECK de fechas de temporada y registros de jugador.
* CHECK que impide que un partido enfrente al mismo equipo contra sí mismo.
* CHECK de goles no negativos.
* CHECK que exige validador y fecha cuando un resultado se marca como oficial.
* Índice UNIQUE parcial para impedir dos registros ACTIVO simultáneos de la misma persona en el mismo equipo.
* Trigger de conflictos: equipo duplicado en intervalo, cancha ocupada y cancha bloqueada.
* Trigger de historial de estados del partido con usuario, fecha y motivo.
* Trigger de historial de resultados antes de correcciones.
* Tabla de posiciones calculada; no se persiste como dato duplicado.
* No se utiliza ON DELETE CASCADE en entidades deportivas históricas.

# 9. Índices

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **Índice** | **Tabla** | **Campo(s)** | **Tipo** | **Motivo** |
| uq\_registro\_jugador\_activo | registros\_jugador | persona\_id, equipo\_id | B-tree UNIQUE parcial | Evitar duplicidad de registro activo. |
| uq\_jornada\_grupo\_numero | jornadas | grupo\_id, numero | B-tree UNIQUE parcial | Evitar jornadas repetidas en un grupo. |
| idx\_categorias\_temporada | categorias | temporada\_id | B-tree | FK y consultas por temporada. |
| idx\_grupos\_categoria | grupos | categoria\_id | B-tree | FK y navegación de grupos. |
| idx\_equipos\_club | equipos | club\_id | B-tree | Búsquedas por club. |
| idx\_equipos\_grupo | equipos | grupo\_id | B-tree | Búsquedas por grupo. |
| idx\_registros\_jugador\_persona | registros\_jugador | persona\_id | B-tree | Historial de una persona. |
| idx\_registros\_jugador\_equipo | registros\_jugador | equipo\_id | B-tree | Jugadores de un equipo. |
| idx\_disponibilidad\_cancha\_periodo | disponibilidad\_canchas | cancha\_id, periodo | GiST | Solapamiento temporal. |
| idx\_jornadas\_grupo | jornadas | grupo\_id | B-tree | Jornadas de grupo. |
| idx\_partidos\_jornada | partidos | jornada\_id | B-tree | Partidos de una jornada. |
| idx\_partidos\_inicio | partidos | inicio\_programado | B-tree | Próximos partidos y filtros por fecha. |
| idx\_partidos\_cancha\_inicio | partidos | cancha\_id, inicio\_programado | B-tree | Consultas de ocupación. |
| idx\_partidos\_equipo\_local/visitante | partidos | equipo\_local\_id / equipo\_visitante\_id | B-tree | Historial por equipo. |
| idx\_resultados\_oficiales | resultados | partido\_id WHERE es\_oficial | B-tree parcial | Consultas de resultados oficiales. |
| idx\_auditoria\_usuario\_fecha | auditoria | usuario\_id, fecha DESC | B-tree | Auditoría por usuario y fecha. |
| idx\_auditoria\_fecha | auditoria | fecha DESC | B-tree | Auditoría cronológica. |
| idx\_publicaciones\_entidad\_estado | publicaciones | entidad, entidad\_id, estado | B-tree | Consulta del estado de publicación. |

# 10. Supabase, autenticación y RLS

Supabase Auth es la fuente de credenciales. No se crea una tabla de contraseñas. public.perfiles referencia auth.users.id. El acceso interno se plantea con RBAC mínimo y RLS.

|  |  |  |  |
| --- | --- | --- | --- |
| **Tabla / ámbito** | **Operación** | **Condición** | **Justificación** |
| perfiles | SELECT | propio usuario o ADMINISTRADOR | Privacidad de datos de usuario. |
| perfiles | ALL | ADMINISTRADOR | Administración de perfiles. |
| roles/permisos | SELECT | authenticated | Consulta del catálogo RBAC. |
| perfil\_roles/rol\_permisos | ALL | ADMINISTRADOR | Asignación administrativa. |
| temporadas/categorías/grupos/clubes/equipos | SELECT | authenticated | Operación interna. |
| temporadas/categorías/grupos/clubes/equipos | ALL | ADMINISTRADOR | Gestión administrativa. |
| personas/registros\_jugador | SELECT/INSERT/UPDATE | ADMINISTRADOR o CAPTURISTA | Captura operativa; datos personales restringidos. |
| canchas/disponibilidad | ALL | ADMINISTRADOR o PROGRAMADOR | Gestión de recursos. |
| jornadas/partidos | INSERT/UPDATE | ADMINISTRADOR o PROGRAMADOR | Programación manual. |
| resultados | INSERT/UPDATE | ADMINISTRADOR o CAPTURISTA | Captura de resultados. |
| resultados\_historial | SELECT | ADMINISTRADOR | Historial sensible y de trazabilidad. |
| publicaciones | SELECT | anon/authenticated si PUBLICADO | Portal público de solo lectura. |
| publicaciones | ALL | ADMINISTRADOR | Control del flujo de publicación. |
| auditoria | SELECT | ADMINISTRADOR | Consulta de trazabilidad. |

[PENDIENTE DE DEFINICIÓN] La matriz exacta perfil ? acción del ERS no está aprobada. Las policies son por tanto una [PROPUESTA TÉCNICA] coherente con los perfiles mínimos de la entrega.

# 11. Triggers y funciones

|  |  |  |  |
| --- | --- | --- | --- |
| **Elemento** | **Tipo** | **Propósito** | **Justificación** |
| set\_updated\_at | Función + trigger | Actualizar updated\_at | Trazabilidad operativa sin repetir lógica en la aplicación. |
| registrar\_transicion\_partido | Función + trigger | Guardar estado anterior/nuevo, usuario, fecha y motivo | RF-045 / RN-021. |
| historial\_resultado | Función + trigger | Conservar versión anterior antes de una corrección | RF-052 / RN-024 y preservación histórica. |
| validar\_conflictos\_partido | Función + trigger | Detectar equipo duplicado, cancha ocupada y cancha bloqueada | RF-039 / RN-012 a RN-014. |
| usuario\_tiene\_rol | Función SECURITY DEFINER | Consultar roles para policies RLS | Implementación RBAC de Supabase. |

# 12. Consultas SQL relacionadas con funcionalidades

## Equipos de un grupo

SELECT e.id, e.nombre, c.nombre AS club
FROM equipos e JOIN clubes c ON c.id = e.club\_id
WHERE e.grupo\_id = $1 ORDER BY e.nombre;

## Jugadores activos de un equipo

SELECT p.id, p.nombre, p.apellido\_paterno, p.apellido\_materno, r.fecha\_alta
FROM registros\_jugador r JOIN personas p ON p.id = r.persona\_id
WHERE r.equipo\_id = $1 AND r.estado = 'ACTIVO';

## Partidos de una jornada

SELECT p.id, p.inicio\_programado, el.nombre AS equipo\_local,
ev.nombre AS equipo\_visitante, c.nombre AS cancha, p.estado
FROM partidos p JOIN equipos el ON el.id=p.equipo\_local\_id
JOIN equipos ev ON ev.id=p.equipo\_visitante\_id LEFT JOIN canchas c ON c.id=p.cancha\_id
WHERE p.jornada\_id=$1 ORDER BY p.inicio\_programado;

## Resultados oficiales

SELECT p.id, p.inicio\_programado, el.nombre AS equipo\_local,
ev.nombre AS equipo\_visitante, r.goles\_local, r.goles\_visitante
FROM resultados r JOIN partidos p ON p.id=r.partido\_id
JOIN equipos el ON el.id=p.equipo\_local\_id JOIN equipos ev ON ev.id=p.equipo\_visitante\_id
WHERE r.es\_oficial=true ORDER BY p.inicio\_programado DESC;

## Tabla de posiciones

SELECT \* FROM public.calcular\_tabla($1::uuid);

## Auditoría

SELECT \* FROM public.auditoria
WHERE ($1::uuid IS NULL OR usuario\_id=$1::uuid)
AND fecha >= COALESCE($2::timestamptz,'-infinity'::timestamptz)
AND fecha < COALESCE($3::timestamptz,'infinity'::timestamptz)
ORDER BY fecha DESC;

## Programación publicada

SELECT j.id AS jornada\_id,p.id AS partido\_id,p.inicio\_programado,
el.nombre AS equipo\_local,ev.nombre AS equipo\_visitante,c.nombre AS cancha
FROM jornadas j JOIN partidos p ON p.jornada\_id=j.id
JOIN equipos el ON el.id=p.equipo\_local\_id JOIN equipos ev ON ev.id=p.equipo\_visitante\_id
LEFT JOIN canchas c ON c.id=p.cancha\_id
WHERE j.estado\_publicacion='PUBLICADO' AND p.inicio\_programado >= $1::timestamptz
AND p.inicio\_programado < $2::timestamptz ORDER BY p.inicio\_programado;

# 13. Entidades no implementadas en esta entrega

|  |  |  |
| --- | --- | --- |
| **Elemento del ERS** | **Estado** | **Motivo** |
| Competencia/Fase | [PENDIENTE DE DEFINICIÓN] | Q-14: no se ha confirmado si es necesaria para la entrega. |
| Incidente / Resolución / Sanción | [PENDIENTE DE DEFINICIÓN] | M-09 y RF-057/058/062/063/065 dependen de Q-05. |
| Elegibilidad detallada | [PENDIENTE DE DEFINICIÓN] | RF-017/RF-019/RF-020 dependen de reglas confirmadas. |
| Árbitros y designaciones | Fuera de alcance | Sección 2.6. |
| Programación automática | Fuera de alcance | Sección 2.6. |
| Renovación/transferencia | Fuera de alcance | Sección 2.6. |
| Histórico de tabla / estadísticas de jugador | Fuera de alcance | Sección 2.6. |
| Ascensos, descensos, liguilla y fases finales | Fuera de alcance | Sección 2.6. |
| Portal ampliado, reportes/exportación e integraciones | Fuera de alcance | Sección 2.6. |

# 14. Observaciones y decisiones técnicas

|  |  |
| --- | --- |
| **Tipo** | **Decisión / observación** |
| Requisito del ERS | El ERS exige conservar históricos y no sobrescribir temporadas/partidos/resultados. |
| Decisión técnica | Se implementan historiales para transiciones de partido y versiones de resultados. [PROPUESTA TÉCNICA]. |
| Requisito del ERS | La tabla debe calcularse desde resultados validados. |
| Decisión técnica | Se utiliza calcular\_tabla() y no una tabla persistente de posiciones. [PROPUESTA TÉCNICA]. |
| Requisito del ERS | La programación debe detectar conflictos por equipo, cancha y disponibilidad. |
| Decisión técnica | Se requiere un intervalo inicio/fin en partidos. fin\_programado es [PROPUESTA TÉCNICA] porque el ERS no fija duración. |
| Requisito del ERS | Supabase/Auth y la estrategia concreta de autenticación no estaban definidos en el ERS. |
| Decisión técnica | Por el encargo actual se adopta auth.users + public.perfiles. [PROPUESTA TÉCNICA]. |
| Pendiente | La matriz exacta de permisos por rol sigue abierta (PEN-010/Q-07). |
| Pendiente | Atributos obligatorios de persona, club, equipo, convocatoria, resultado y disponibilidad siguen pendientes (PEN-018/PEN-019/PEN-022). |
| Pendiente | Las cardinalidades del modelo conceptual requieren validación (AMB-005). |
| Pendiente | La duración formal de partidos y las reglas oficiales de desempate deben validarse. |
| Pendiente | No se almacenan contraseñas ni credenciales propias. |

# 15. Revisión de consistencia

* ERS ? BD: los módulos incluidos tienen representación en tablas, funciones, RLS o auditoría.
* BD ? ERS: las tablas principales se justifican por las entidades/funciones del alcance; las auxiliares se marcan como decisiones técnicas.
* Relaciones: las FK apuntan a columnas existentes y las relaciones N:M se resuelven con tablas intermedias.
* PostgreSQL: se usan tipos, ENUM, CHECK, índices GiST, funciones PL/pgSQL y sintaxis PostgreSQL.
* Supabase: la identidad se vincula a auth.users y las policies utilizan auth.uid().
* Seguridad: no se almacenan contraseñas; los datos personales tienen acceso restringido.
* Histórico: no se usa CASCADE sobre entidades deportivas que podrían tener historial.
* Ejecución: extensiones/tipos ? tablas ? funciones ? triggers ? índices ? RLS ? policies ? seeds ? consultas comentadas.
* Consultas parametrizadas: se dejan como ejemplos comentados con $1/$2 para no romper la ejecución del SQL Editor.

# 16. Nota sobre el estado del documento

El ERS fuente indica que la revisión 0.3 es un borrador para seguimiento académico y que el alcance propuesto está pendiente de validación. Por ello este diccionario y database.sql deben considerarse una propuesta de diseño derivada del ERS, no una sustitución ni modificación del ERS original.

# 17. Control de acceso público

Para el portal público se evita conceder acceso general de lectura a las tablas internas. Se incorporan tres funciones SECURITY DEFINER, marcadas como [PROPUESTA TÉCNICA], que exponen únicamente programación publicada, resultados oficiales de jornadas publicadas y tabla calculada cuando existe contenido publicado para el grupo. Se concede EXECUTE a anon y authenticated; las tablas internas permanecen protegidas por RLS.

Consultas públicas previstas: consultar\_programacion\_publica(desde, hasta), consultar\_resultados\_publicos(desde, hasta) y consultar\_tabla\_publica(grupo\_id).
