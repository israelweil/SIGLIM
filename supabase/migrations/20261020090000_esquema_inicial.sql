-- =====================================================================================
-- SIGLIM · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia
-- Migración inicial del esquema (reemplaza a 20261007000000_esquema_inicial.sql, DEC-42)
--
-- Fuente:   ERS Rev. 0.4.1 · Arquitectura v2.1 · ADR-0003 a ADR-0014
-- Motor:    PostgreSQL 15 o superior en Supabase
-- Esquema:  siglim (no expuesto por la API REST de Supabase; ADR-0014)
--
-- Cómo aplicarla (proyecto nuevo o sin el esquema siglim):
--   1. Supabase → SQL Editor → pegar este archivo completo → Run.
--      o bien: supabase db push (CLI), que aplica las migraciones en orden.
--   2. Invitar al primer administrador en Authentication → Users → Invite user.
--   3. Ejecutar: SELECT siglim.registrar_administrador_inicial('correo@dominio');
--
-- Convenciones: snake_case; tablas en plural; claves uuid (catálogos y bitácoras bigint);
-- fechas con timestamptz; nada con historial se borra (sin privilegio DELETE).
-- Los valores marcados [DEMO] son configuración de demostración y no son oficiales.
-- =====================================================================================

BEGIN;

-- -------------------------------------------------------------------------------------
-- 1. EXTENSIONES, ESQUEMA Y ROLES DE BASE DE DATOS
-- -------------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions;   -- exclusión por cancha y rango

CREATE SCHEMA siglim;
COMMENT ON SCHEMA siglim IS 'SIGLIM: datos de la liga. Solo lo usan el backend (siglim_app) y el portal (siglim_publico).';
REVOKE ALL ON SCHEMA siglim FROM PUBLIC;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'siglim_app') THEN
    CREATE ROLE siglim_app NOLOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'siglim_publico') THEN
    CREATE ROLE siglim_publico NOLOGIN NOINHERIT;
  END IF;
END $$;
COMMENT ON ROLE siglim_app IS 'Rol que adopta el backend en cada transacción autenticada (SET LOCAL ROLE). Sujeto a RLS.';
COMMENT ON ROLE siglim_publico IS 'Rol del portal público: solo lee vistas de datos publicados.';
-- El usuario de conexión del backend (postgres en Supabase) debe poder adoptar ambos roles.
GRANT siglim_app, siglim_publico TO CURRENT_USER;

-- -------------------------------------------------------------------------------------
-- 2. TIPOS ENUMERADOS (estados del ERS §4.3 y catálogos cerrados)
-- -------------------------------------------------------------------------------------
CREATE TYPE siglim.ambito AS ENUM ('LIGA', 'CLUB', 'PROPIO');
CREATE TYPE siglim.estado_solicitud_permisos AS ENUM ('SOLICITADO', 'APROBADO', 'RECHAZADO');
CREATE TYPE siglim.tipo_aviso_privacidad AS ENUM ('INTEGRAL', 'SIMPLIFICADO');
CREATE TYPE siglim.tipo_solicitud_arco AS ENUM ('ACCESO', 'RECTIFICACION', 'CANCELACION', 'OPOSICION');
CREATE TYPE siglim.estado_solicitud_arco AS ENUM ('RECIBIDA', 'EN_ATENCION', 'ATENDIDA', 'RECHAZADA');

CREATE TYPE siglim.estado_temporada AS ENUM ('CONFIGURACION', 'ACTIVA', 'CERRADA');
CREATE TYPE siglim.tipo_categoria AS ENUM ('INFANTIL', 'LIBRE', 'VETERANOS');
CREATE TYPE siglim.criterio_desempate AS ENUM (
  'PUNTOS', 'DIFERENCIA_GOLES', 'GOLES_FAVOR', 'MENOS_GOLES_CONTRA', 'PARTIDOS_GANADOS',
  'ENFRENTAMIENTO_DIRECTO', 'MENOS_EXPULSIONES', 'SORTEO');
CREATE TYPE siglim.formato_eliminatoria AS ENUM ('PARTIDO_UNICO', 'IDA_Y_VUELTA');
CREATE TYPE siglim.estado_interpretacion AS ENUM ('PENDIENTE', 'AUTORIZADA', 'RECHAZADA');

CREATE TYPE siglim.estado_club AS ENUM ('ACTIVO', 'CERRADO');
CREATE TYPE siglim.estado_afiliacion AS ENUM ('SOLICITADA', 'APROBADA', 'RECHAZADA');
CREATE TYPE siglim.cargo_directiva AS ENUM ('PRESIDENTE', 'SECRETARIO', 'TESORERO', 'DELEGADO');
CREATE TYPE siglim.estado_equipo AS ENUM ('ACTIVO', 'BAJA');
CREATE TYPE siglim.tipo_operacion_equipo AS ENUM ('VENTA', 'CONSERVACION_PLAZA');
CREATE TYPE siglim.estado_operacion_equipo AS ENUM ('SOLICITADA', 'AUTORIZADA', 'RECHAZADA', 'APLICADA');

CREATE TYPE siglim.estado_registro AS ENUM ('PENDIENTE_VALIDACION', 'ACTIVO', 'SUSPENDIDO', 'BAJA', 'RECHAZADO');
CREATE TYPE siglim.estado_validacion AS ENUM ('PENDIENTE', 'APROBADO', 'RECHAZADO');

CREATE TYPE siglim.estado_arbitro AS ENUM ('PROPUESTO', 'VALIDADO', 'RECHAZADO', 'BAJA');
CREATE TYPE siglim.funcion_arbitral AS ENUM ('CENTRAL', 'ASISTENTE');

CREATE TYPE siglim.ubicacion_cancha AS ENUM ('UNIDAD_DEPORTIVA', 'EXTERNA');
CREATE TYPE siglim.propietario_cancha AS ENUM ('LIGA', 'CLUB', 'EXTERNO');
CREATE TYPE siglim.tipo_disponibilidad AS ENUM ('DISPONIBLE', 'BLOQUEO', 'MANTENIMIENTO');
CREATE TYPE siglim.tipo_solicitud_cancha AS ENUM ('PRESTAMO', 'COMODATO', 'OFERTA');
CREATE TYPE siglim.estado_solicitud_cancha AS ENUM (
  'PENDIENTE', 'APROBADA', 'NO_APROBADA',                      -- Formato 1
  'PENDIENTE_NEGOCIACION', 'ACEPTADA', 'RECHAZADA');           -- Formato 2

CREATE TYPE siglim.estado_publicacion AS ENUM ('BORRADOR', 'REVISION', 'PUBLICADO');
CREATE TYPE siglim.estado_partido AS ENUM (
  'PROGRAMADO', 'EN_CURSO', 'FINALIZADO', 'SUSPENDIDO', 'REPROGRAMADO', 'CANCELADO');
CREATE TYPE siglim.estado_cedula AS ENUM ('EN_CAPTURA', 'PENDIENTE_VALIDACION', 'DEVUELTA', 'APROBADA');
CREATE TYPE siglim.tipo_evento_cedula AS ENUM (
  'GOL', 'AUTOGOL', 'TARJETA_AMARILLA', 'TARJETA_ROJA', 'SUSTITUCION');
CREATE TYPE siglim.origen_resultado AS ENUM ('CEDULA', 'RESOLUCION');

CREATE TYPE siglim.tipo_sancion AS ENUM (
  'SUSPENSION_PARTIDOS', 'MULTA', 'PERDIDA_PUNTOS', 'PERDIDA_PARTIDO', 'BAJA');
CREATE TYPE siglim.sujeto_sancion AS ENUM ('JUGADOR', 'EQUIPO', 'CLUB');
CREATE TYPE siglim.efecto_sancion AS ENUM ('HACIA_ADELANTE', 'RETROACTIVO');
CREATE TYPE siglim.estado_expediente AS ENUM ('ABIERTO', 'EN_REVISION', 'RESUELTO', 'EN_RECURSO', 'CERRADO');
CREATE TYPE siglim.origen_expediente AS ENUM ('INCIDENCIA', 'AUTOMATICO', 'MANUAL');
CREATE TYPE siglim.instancia_resolucion AS ENUM ('PRIMERA', 'RECURSO');
CREATE TYPE siglim.estado_sancion AS ENUM ('VIGENTE', 'CUMPLIDA', 'REVOCADA');
CREATE TYPE siglim.estado_recurso AS ENUM ('INTERPUESTO', 'RESUELTO');

CREATE TYPE siglim.tipo_fase AS ENUM ('LIGUILLA');
CREATE TYPE siglim.estado_fase AS ENUM ('CONFIGURACION', 'EN_JUEGO', 'CONCLUIDA');
CREATE TYPE siglim.estado_propuesta AS ENUM ('PROPUESTA', 'VALIDADA', 'OBSERVADA');
CREATE TYPE siglim.tipo_movimiento AS ENUM ('ASCENSO', 'DESCENSO');

CREATE TYPE siglim.concepto_tarifa AS ENUM ('ARBITRAJE', 'CANCHA');
CREATE TYPE siglim.tipo_cobro AS ENUM ('ARBITRAJE', 'CANCHA', 'MULTA', 'MANUAL');
CREATE TYPE siglim.estado_cobro AS ENUM ('PENDIENTE', 'PAGADO', 'RECHAZADO', 'VENCIDO');
CREATE TYPE siglim.estado_intento_pago AS ENUM ('PENDIENTE', 'APROBADO', 'RECHAZADO');
CREATE TYPE siglim.medio_pago AS ENUM ('EN_LINEA_SIMULADO', 'EFECTIVO', 'TRANSFERENCIA', 'OTRO');

CREATE TYPE siglim.estado_correo AS ENUM ('PENDIENTE', 'ENVIADO', 'FALLIDO');
CREATE TYPE siglim.entidad_publicable AS ENUM ('JORNADA', 'COMUNICADO');

-- -------------------------------------------------------------------------------------
-- 3. TABLAS
-- -------------------------------------------------------------------------------------

-- ===== M-01 Administración y seguridad =================================================

CREATE TABLE siglim.ligas (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre        varchar(150) NOT NULL UNIQUE,
  nombre_corto  varchar(40),
  activa        boolean NOT NULL DEFAULT true,
  creado_en     timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE siglim.ligas IS 'M-01 · Organización que opera el sistema. Una sola fila en esta entrega (ADR-0011, DD-011).';

CREATE TABLE siglim.personas (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  curp              char(18) NOT NULL UNIQUE,
  nombre            varchar(100) NOT NULL,
  apellido_paterno  varchar(100) NOT NULL,
  apellido_materno  varchar(100),
  fecha_nacimiento  date NOT NULL,
  correo            varchar(254),
  telefono          varchar(20),
  creado_por        uuid,                               -- FK a perfiles agregada después
  creado_en         timestamptz NOT NULL DEFAULT now(),
  actualizado_en    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_personas_curp CHECK (curp ~ '^[A-Z][AEIOUX][A-Z]{2}[0-9]{6}[HMX][A-Z]{5}[0-9A-Z][0-9]$'),
  CONSTRAINT ck_personas_correo CHECK (correo IS NULL OR correo ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);
COMMENT ON TABLE siglim.personas IS 'M-03 · Identidad única por CURP, reutilizable como jugador, tutor, directivo o árbitro (RF-010, RF-011, DEC-10). Global a todas las ligas.';

CREATE TABLE siglim.perfiles (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_auth_id  uuid UNIQUE REFERENCES auth.users (id) ON DELETE SET NULL,
  persona_id       uuid UNIQUE REFERENCES siglim.personas (id) ON DELETE RESTRICT,
  nombre_mostrado  varchar(150) NOT NULL,
  correo           varchar(254),
  activo           boolean NOT NULL DEFAULT true,
  es_sistema       boolean NOT NULL DEFAULT false,
  creado_en        timestamptz NOT NULL DEFAULT now(),
  actualizado_en   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_perfiles_sistema CHECK (NOT es_sistema OR usuario_auth_id IS NULL)
);
ALTER TABLE siglim.personas
  ADD CONSTRAINT fk_personas_creado_por FOREIGN KEY (creado_por) REFERENCES siglim.perfiles (id);
COMMENT ON TABLE siglim.perfiles IS 'M-01 · Cuenta de SIGLIM. usuario_auth_id enlaza con Supabase Auth; el perfil Sistema no tiene cuenta (ADR-0003, ADR-0014).';

CREATE TABLE siglim.roles (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id                uuid NOT NULL REFERENCES siglim.ligas (id),
  codigo                 varchar(40) NOT NULL,
  nombre                 varchar(100) NOT NULL,
  descripcion            text,
  ambito_predeterminado  siglim.ambito NOT NULL,
  asignable              boolean NOT NULL DEFAULT true,
  creado_en              timestamptz NOT NULL DEFAULT now(),
  UNIQUE (liga_id, codigo)
);
COMMENT ON TABLE siglim.roles IS 'M-01 · Tipos de usuario (ERS §2.3). Sus permisos son configurables (RF-095).';

CREATE TABLE siglim.permisos (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo       varchar(80) NOT NULL UNIQUE,
  modulo       char(4) NOT NULL,
  descripcion  text NOT NULL,
  CONSTRAINT ck_permisos_codigo CHECK (codigo ~ '^[a-z]+\.[a-z_]+:[A-Z_]+$'),
  CONSTRAINT ck_permisos_modulo CHECK (modulo ~ '^M-[0-9]{2}$')
);
COMMENT ON TABLE siglim.permisos IS 'M-01 · Catálogo de permisos modulo.recurso:ACCION (ADR-0007). Semilla de la migración.';

CREATE TABLE siglim.rol_permisos (
  rol_id      uuid NOT NULL REFERENCES siglim.roles (id),
  permiso_id  bigint NOT NULL REFERENCES siglim.permisos (id),
  PRIMARY KEY (rol_id, permiso_id)
);
COMMENT ON TABLE siglim.rol_permisos IS 'M-01 · Permisos de cada rol (matriz del Apéndice E del ERS).';

CREATE TABLE siglim.asignaciones_rol (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  perfil_id    uuid NOT NULL REFERENCES siglim.perfiles (id),
  rol_id       uuid NOT NULL REFERENCES siglim.roles (id),
  liga_id      uuid NOT NULL REFERENCES siglim.ligas (id),
  ambito       siglim.ambito NOT NULL,
  club_id      uuid,                                  -- FK agregada tras crear clubes
  activa       boolean NOT NULL DEFAULT true,
  creado_por   uuid REFERENCES siglim.perfiles (id),
  creado_en    timestamptz NOT NULL DEFAULT now(),
  revocada_en  timestamptz,
  CONSTRAINT ck_asignaciones_club CHECK ((ambito = 'CLUB') = (club_id IS NOT NULL))
);
COMMENT ON TABLE siglim.asignaciones_rol IS 'M-01 · Rol de un perfil con su ámbito: liga, club (club_id) o propio (RF-094, RN-054).';

CREATE TABLE siglim.pares_incompatibles (
  permiso_a_id  bigint NOT NULL REFERENCES siglim.permisos (id),
  permiso_b_id  bigint NOT NULL REFERENCES siglim.permisos (id),
  motivo        text NOT NULL,
  PRIMARY KEY (permiso_a_id, permiso_b_id),
  CONSTRAINT ck_pares_orden CHECK (permiso_a_id < permiso_b_id)
);
COMMENT ON TABLE siglim.pares_incompatibles IS 'M-01 · Pares que no deben concentrarse en un rol sin aprobación del Presidente (RF-096, RN-053).';

CREATE TABLE siglim.solicitudes_cambio_permisos (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rol_id              uuid NOT NULL REFERENCES siglim.roles (id),
  permisos_agregados  bigint[] NOT NULL DEFAULT '{}',
  permisos_quitados   bigint[] NOT NULL DEFAULT '{}',
  motivo              text NOT NULL,
  estado              siglim.estado_solicitud_permisos NOT NULL DEFAULT 'SOLICITADO',
  solicitado_por      uuid NOT NULL REFERENCES siglim.perfiles (id),
  solicitado_en       timestamptz NOT NULL DEFAULT now(),
  resuelto_por        uuid REFERENCES siglim.perfiles (id),
  resuelto_en         timestamptz,
  observaciones       text,
  CONSTRAINT ck_solicitudes_permisos_dual CHECK (resuelto_por IS NULL OR resuelto_por <> solicitado_por),
  CONSTRAINT ck_solicitudes_permisos_resolucion CHECK ((estado = 'SOLICITADO') = (resuelto_por IS NULL))
);
COMMENT ON TABLE siglim.solicitudes_cambio_permisos IS 'M-01 · Control dual: cambio que crea un par incompatible, pendiente del Presidente (P-13, VAL-023).';

CREATE TABLE siglim.avisos_privacidad (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id         uuid NOT NULL REFERENCES siglim.ligas (id),
  tipo            siglim.tipo_aviso_privacidad NOT NULL,
  version         varchar(20) NOT NULL,
  contenido       text NOT NULL,
  finalidades     text[] NOT NULL,
  vigente_desde   date NOT NULL,
  creado_en       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (liga_id, tipo, version)
);
COMMENT ON TABLE siglim.avisos_privacidad IS 'M-01 · Versiones del aviso de privacidad integral y simplificado (RF-097, DEC-40).';

CREATE TABLE siglim.consentimientos (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  persona_id          uuid NOT NULL REFERENCES siglim.personas (id),
  otorgado_por_id     uuid NOT NULL REFERENCES siglim.personas (id),
  aviso_id            uuid NOT NULL REFERENCES siglim.avisos_privacidad (id),
  finalidades         text[] NOT NULL,
  otorgado_en         timestamptz NOT NULL DEFAULT now(),
  revocado_en         timestamptz,
  registrado_por      uuid REFERENCES siglim.perfiles (id),
  CONSTRAINT ck_consentimientos_finalidades CHECK (cardinality(finalidades) > 0)
);
COMMENT ON TABLE siglim.consentimientos IS 'M-01 · Consentimiento expreso del titular o, si es menor, de su tutor (otorgado_por_id) (RF-097, RN-055).';

CREATE TABLE siglim.solicitudes_arco (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id        uuid NOT NULL REFERENCES siglim.ligas (id),
  persona_id     uuid NOT NULL REFERENCES siglim.personas (id),
  tipo           siglim.tipo_solicitud_arco NOT NULL,
  descripcion    text NOT NULL,
  estado         siglim.estado_solicitud_arco NOT NULL DEFAULT 'RECIBIDA',
  recibida_en    timestamptz NOT NULL DEFAULT now(),
  atendida_por   uuid REFERENCES siglim.perfiles (id),
  atendida_en    timestamptz,
  respuesta      text
);
COMMENT ON TABLE siglim.solicitudes_arco IS 'M-01 · Solicitudes de acceso, rectificación, cancelación y oposición (RF-098, backlog).';

CREATE TABLE siglim.auditoria (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  liga_id      uuid REFERENCES siglim.ligas (id),
  perfil_id    uuid REFERENCES siglim.perfiles (id),
  ocurrido_en  timestamptz NOT NULL DEFAULT now(),
  modulo       char(4) NOT NULL,
  accion       varchar(80) NOT NULL,
  entidad      varchar(60) NOT NULL,
  entidad_id   text,
  motivo       text,
  detalle      jsonb,
  CONSTRAINT ck_auditoria_modulo CHECK (modulo ~ '^M-[0-9]{2}$')
);
COMMENT ON TABLE siglim.auditoria IS 'M-01 · Auditoría inalterable: solo INSERT y SELECT (RF-093, RNF-015). detalle no debe contener datos personales.';

-- ===== M-02 Temporadas y normativa =====================================================

CREATE TABLE siglim.temporadas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id         uuid NOT NULL REFERENCES siglim.ligas (id),
  nombre          varchar(100) NOT NULL,
  fecha_inicio    date NOT NULL,
  fecha_fin       date,
  estado          siglim.estado_temporada NOT NULL DEFAULT 'CONFIGURACION',
  creado_por      uuid REFERENCES siglim.perfiles (id),
  creado_en       timestamptz NOT NULL DEFAULT now(),
  actualizado_en  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (liga_id, nombre),
  CONSTRAINT ck_temporadas_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
COMMENT ON TABLE siglim.temporadas IS 'M-02 · Periodo deportivo; una sola ACTIVA por liga (RF-001, RN-058). No se borra (RF-003).';

CREATE TABLE siglim.convocatorias (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  temporada_id  uuid NOT NULL UNIQUE REFERENCES siglim.temporadas (id),
  referencia    text NOT NULL,
  version       varchar(30),
  documento_url text,
  creado_en     timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE siglim.convocatorias IS 'M-02 · Referencia de la convocatoria de la temporada (RF-002, backlog).';

CREATE TABLE siglim.categorias (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id                uuid NOT NULL REFERENCES siglim.ligas (id),
  nombre                 varchar(80) NOT NULL,
  tipo                   siglim.tipo_categoria NOT NULL,
  orden                  smallint NOT NULL,
  categoria_superior_id  uuid REFERENCES siglim.categorias (id),
  activa                 boolean NOT NULL DEFAULT true,
  creado_en              timestamptz NOT NULL DEFAULT now(),
  UNIQUE (liga_id, nombre),
  CONSTRAINT ck_categorias_superior CHECK (categoria_superior_id IS NULL OR categoria_superior_id <> id)
);
COMMENT ON TABLE siglim.categorias IS 'M-02 · Catálogo con orden y categoría superior inmediata configurables (RF-099, DEC-16).';

CREATE TABLE siglim.categorias_temporada (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  temporada_id  uuid NOT NULL REFERENCES siglim.temporadas (id),
  categoria_id  uuid NOT NULL REFERENCES siglim.categorias (id),
  UNIQUE (temporada_id, categoria_id)
);
COMMENT ON TABLE siglim.categorias_temporada IS 'M-02 · Categorías que participan en la temporada (RF-004).';

CREATE TABLE siglim.grupos (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  categoria_temporada_id uuid NOT NULL REFERENCES siglim.categorias_temporada (id),
  nombre                 varchar(60) NOT NULL,
  UNIQUE (categoria_temporada_id, nombre)
);
COMMENT ON TABLE siglim.grupos IS 'M-02 · Uno o varios grupos por categoría de la temporada (RF-005).';

CREATE TABLE siglim.parametros_temporada (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  temporada_id                uuid NOT NULL REFERENCES siglim.temporadas (id),
  version                     integer NOT NULL,
  puntos_victoria             smallint NOT NULL DEFAULT 3,
  puntos_empate               smallint NOT NULL DEFAULT 1,
  puntos_derrota              smallint NOT NULL DEFAULT 0,
  criterios_desempate         siglim.criterio_desempate[] NOT NULL DEFAULT
    '{PUNTOS,DIFERENCIA_GOLES,GOLES_FAVOR,ENFRENTAMIENTO_DIRECTO,MENOS_EXPULSIONES,SORTEO}',
  goles_default_ganador       smallint NOT NULL DEFAULT 3,
  goles_default_perdedor      smallint NOT NULL DEFAULT 0,
  plazo_validacion_cedula     interval NOT NULL DEFAULT interval '48 hours',
  duracion_juego_min          smallint NOT NULL DEFAULT 90,
  bloque_cancha_min           smallint NOT NULL DEFAULT 120,
  clasificados_liguilla       smallint NOT NULL DEFAULT 8,
  formato_liguilla            siglim.formato_eliminatoria NOT NULL DEFAULT 'PARTIDO_UNICO',
  empate_liguilla_por_penales boolean NOT NULL DEFAULT true,
  equipos_ascienden           smallint NOT NULL DEFAULT 2,
  equipos_descienden          smallint NOT NULL DEFAULT 2,
  permite_cambio_club         boolean NOT NULL DEFAULT true,
  es_demo                     boolean NOT NULL DEFAULT true,
  motivo                      text NOT NULL,
  creado_por                  uuid REFERENCES siglim.perfiles (id),
  creado_en                   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (temporada_id, version),
  CONSTRAINT ck_parametros_puntos CHECK (puntos_victoria >= puntos_empate AND puntos_empate >= puntos_derrota AND puntos_derrota >= 0),
  CONSTRAINT ck_parametros_criterios CHECK (criterios_desempate[1] = 'PUNTOS'),
  CONSTRAINT ck_parametros_default CHECK (goles_default_ganador > goles_default_perdedor AND goles_default_perdedor >= 0),
  CONSTRAINT ck_parametros_tiempos CHECK (duracion_juego_min > 0 AND bloque_cancha_min >= duracion_juego_min AND plazo_validacion_cedula > interval '0'),
  CONSTRAINT ck_parametros_liguilla CHECK (clasificados_liguilla IN (2, 4, 8, 16, 32)),
  CONSTRAINT ck_parametros_movimientos CHECK (equipos_ascienden >= 0 AND equipos_descienden >= 0)
);
COMMENT ON TABLE siglim.parametros_temporada IS 'M-02 · Reglas versionadas de la temporada; la versión mayor es la vigente (RF-006, RF-100, DP-002). Valores por defecto [DEMO] (DEC-25 a DEC-29).';

CREATE TABLE siglim.parametros_categoria (
  parametros_id       uuid NOT NULL REFERENCES siglim.parametros_temporada (id),
  categoria_id        uuid NOT NULL REFERENCES siglim.categorias (id),
  duracion_juego_min  smallint NOT NULL,
  bloque_cancha_min   smallint NOT NULL,
  PRIMARY KEY (parametros_id, categoria_id),
  CONSTRAINT ck_parametros_categoria CHECK (duracion_juego_min > 0 AND bloque_cancha_min >= duracion_juego_min)
);
COMMENT ON TABLE siglim.parametros_categoria IS 'M-02 · Duración de juego y bloque de cancha por categoría; sin fila se usan los de la temporada (RF-100, DEC-25).';

CREATE TABLE siglim.interpretaciones_regla (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  temporada_id   uuid NOT NULL REFERENCES siglim.temporadas (id),
  descripcion    text NOT NULL,
  estado         siglim.estado_interpretacion NOT NULL DEFAULT 'PENDIENTE',
  registrada_por uuid NOT NULL REFERENCES siglim.perfiles (id),
  registrada_en  timestamptz NOT NULL DEFAULT now(),
  resuelta_por   uuid REFERENCES siglim.perfiles (id),
  resuelta_en    timestamptz,
  observaciones  text
);
COMMENT ON TABLE siglim.interpretaciones_regla IS 'M-02 · Interpretación administrativa pendiente de autorización del Presidente (RF-007, backlog).';

-- ===== M-03 Organización deportiva ======================================================

CREATE TABLE siglim.clubes (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id           uuid NOT NULL REFERENCES siglim.ligas (id),
  nombre            varchar(150) NOT NULL,
  estado            siglim.estado_club NOT NULL DEFAULT 'ACTIVO',
  club_anterior_id  uuid REFERENCES siglim.clubes (id),
  cerrado_en        date,
  motivo_cierre     text,
  creado_en         timestamptz NOT NULL DEFAULT now(),
  actualizado_en    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (liga_id, nombre),
  CONSTRAINT ck_clubes_cierre CHECK ((estado = 'CERRADO') = (cerrado_en IS NOT NULL))
);
COMMENT ON TABLE siglim.clubes IS 'M-03 · Club afiliado. Un cambio de nombre crea un club nuevo y cierra el anterior (RF-008, RF-105, DEC-15).';

ALTER TABLE siglim.asignaciones_rol
  ADD CONSTRAINT fk_asignaciones_club FOREIGN KEY (club_id) REFERENCES siglim.clubes (id);

CREATE TABLE siglim.afiliaciones (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id           uuid NOT NULL REFERENCES siglim.clubes (id),
  temporada_id      uuid NOT NULL REFERENCES siglim.temporadas (id),
  folio             varchar(30) NOT NULL,
  colores_uniforme  varchar(120) NOT NULL,
  estado            siglim.estado_afiliacion NOT NULL DEFAULT 'SOLICITADA',
  capturada_por     uuid NOT NULL REFERENCES siglim.perfiles (id),
  capturada_en      timestamptz NOT NULL DEFAULT now(),
  resuelta_por      uuid REFERENCES siglim.perfiles (id),
  resuelta_en       timestamptz,
  observaciones     text,
  UNIQUE (club_id, temporada_id),
  UNIQUE (temporada_id, folio)
);
COMMENT ON TABLE siglim.afiliaciones IS 'M-03 · Tarjetón del club por temporada con folio, sujeto a aprobación del Presidente (RF-101, DEC-09). Firmas: documento TARJETON_FIRMADO.';

CREATE TABLE siglim.afiliacion_categorias (
  afiliacion_id  uuid NOT NULL REFERENCES siglim.afiliaciones (id),
  categoria_id   uuid NOT NULL REFERENCES siglim.categorias (id),
  PRIMARY KEY (afiliacion_id, categoria_id)
);
COMMENT ON TABLE siglim.afiliacion_categorias IS 'M-03 · Categorías en que se inscribe el club en el tarjetón (DEC-09).';

CREATE TABLE siglim.cargos_directiva (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id        uuid NOT NULL REFERENCES siglim.clubes (id),
  persona_id     uuid NOT NULL REFERENCES siglim.personas (id),
  cargo          siglim.cargo_directiva NOT NULL,
  desde          date NOT NULL,
  hasta          date,
  autorizado_por uuid REFERENCES siglim.perfiles (id),
  creado_en      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_cargos_vigencia CHECK (hasta IS NULL OR hasta >= desde)
);
COMMENT ON TABLE siglim.cargos_directiva IS 'M-03 · Directiva del club (presidente, secretario, tesorero, delegado) con vigencia (RF-102).';

CREATE TABLE siglim.tutelas (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  menor_id    uuid NOT NULL REFERENCES siglim.personas (id),
  tutor_id    uuid NOT NULL REFERENCES siglim.personas (id),
  parentesco  varchar(40) NOT NULL,
  vigente     boolean NOT NULL DEFAULT true,
  creado_por  uuid REFERENCES siglim.perfiles (id),
  creado_en   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_tutelas_distintos CHECK (menor_id <> tutor_id)
);
COMMENT ON TABLE siglim.tutelas IS 'M-03 · Vínculo menor–tutor; la cuenta del tutor gestiona al menor (RF-106, DEC-11).';

CREATE TABLE siglim.equipos (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id            uuid NOT NULL REFERENCES siglim.clubes (id),
  grupo_id           uuid NOT NULL REFERENCES siglim.grupos (id),
  nombre             varchar(150) NOT NULL,
  estado             siglim.estado_equipo NOT NULL DEFAULT 'ACTIVO',
  equipo_anterior_id uuid REFERENCES siglim.equipos (id),
  baja_en            date,
  motivo_baja        text,
  creado_en          timestamptz NOT NULL DEFAULT now(),
  actualizado_en     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grupo_id, nombre),
  CONSTRAINT ck_equipos_baja CHECK ((estado = 'BAJA') = (baja_en IS NOT NULL AND motivo_baja IS NOT NULL))
);
COMMENT ON TABLE siglim.equipos IS 'M-03 · Representación del club en un grupo de la temporada (RF-009). equipo_anterior_id liga la plaza entre temporadas (RF-104).';

CREATE TABLE siglim.operaciones_equipo (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo               siglim.tipo_operacion_equipo NOT NULL,
  equipo_id          uuid NOT NULL REFERENCES siglim.equipos (id),
  club_origen_id     uuid NOT NULL REFERENCES siglim.clubes (id),
  club_destino_id    uuid REFERENCES siglim.clubes (id),
  estado             siglim.estado_operacion_equipo NOT NULL DEFAULT 'SOLICITADA',
  solicitada_por     uuid NOT NULL REFERENCES siglim.perfiles (id),
  solicitada_en      timestamptz NOT NULL DEFAULT now(),
  autorizada_por     uuid REFERENCES siglim.perfiles (id),
  autorizada_en      timestamptz,
  aplicada_en        timestamptz,
  observaciones      text,
  CONSTRAINT ck_operaciones_venta CHECK (tipo <> 'VENTA' OR (club_destino_id IS NOT NULL AND club_destino_id <> club_origen_id))
);
COMMENT ON TABLE siglim.operaciones_equipo IS 'M-03 · Venta de equipo y conservación de plaza, autorizadas por el Presidente y aplicadas al cierre (RF-103, RF-104, RN-040; backlog). Es el historial de propietarios.';

-- ===== M-04 Registros y elegibilidad ====================================================

CREATE TABLE siglim.registros_jugador (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  persona_id      uuid NOT NULL REFERENCES siglim.personas (id),
  equipo_id       uuid NOT NULL REFERENCES siglim.equipos (id),
  temporada_id    uuid NOT NULL REFERENCES siglim.temporadas (id),
  estado          siglim.estado_registro NOT NULL DEFAULT 'PENDIENTE_VALIDACION',
  registro_anterior_id uuid REFERENCES siglim.registros_jugador (id),
  alta_en         date NOT NULL DEFAULT current_date,
  baja_en         date,
  validado_por    uuid REFERENCES siglim.perfiles (id),
  validado_en     timestamptz,
  observaciones   text,
  creado_por      uuid REFERENCES siglim.perfiles (id),
  creado_en       timestamptz NOT NULL DEFAULT now(),
  actualizado_en  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_registros_baja CHECK ((estado = 'BAJA') = (baja_en IS NOT NULL))
);
COMMENT ON TABLE siglim.registros_jugador IS 'M-04 · Persona en un equipo por temporada. Una CURP con un solo registro activo por temporada (RF-013, RF-107, RN-037). temporada_id lo fija un trigger.';

CREATE TABLE siglim.registro_estado_historial (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  registro_id      uuid NOT NULL REFERENCES siglim.registros_jugador (id),
  estado_anterior  siglim.estado_registro,
  estado_nuevo     siglim.estado_registro NOT NULL,
  motivo           text NOT NULL,
  cambiado_por     uuid REFERENCES siglim.perfiles (id),
  cambiado_en      timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE siglim.registro_estado_historial IS 'M-04 · Cambios de estado del registro con usuario y motivo (RF-017, RF-018).';

CREATE TABLE siglim.tipos_documento (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo       varchar(40) NOT NULL UNIQUE,
  nombre       varchar(100) NOT NULL,
  descripcion  text
);
COMMENT ON TABLE siglim.tipos_documento IS 'M-04 · Catálogo de tipos de documento (DEC-10).';

CREATE TABLE siglim.requisitos_documento (
  id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  liga_id            uuid NOT NULL REFERENCES siglim.ligas (id),
  tipo_categoria     siglim.tipo_categoria NOT NULL,
  tipo_documento_id  bigint NOT NULL REFERENCES siglim.tipos_documento (id),
  cantidad           smallint NOT NULL DEFAULT 1,
  solo_menores       boolean NOT NULL DEFAULT false,
  es_demo            boolean NOT NULL DEFAULT false,
  UNIQUE (liga_id, tipo_categoria, tipo_documento_id),
  CONSTRAINT ck_requisitos_cantidad CHECK (cantidad > 0)
);
COMMENT ON TABLE siglim.requisitos_documento IS 'M-04 · Documentos exigidos por tipo de categoría y para menores (RF-108, DEC-10). Configurable.';

-- ===== M-05 Árbitros (catálogo) =========================================================

CREATE TABLE siglim.arbitros (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  persona_id     uuid NOT NULL UNIQUE REFERENCES siglim.personas (id),
  club_id        uuid NOT NULL REFERENCES siglim.clubes (id),
  estado         siglim.estado_arbitro NOT NULL DEFAULT 'PROPUESTO',
  propuesto_por  uuid REFERENCES siglim.perfiles (id),
  propuesto_en   timestamptz NOT NULL DEFAULT now(),
  validado_por   uuid REFERENCES siglim.perfiles (id),
  validado_en    timestamptz,
  observaciones  text
);
COMMENT ON TABLE siglim.arbitros IS 'M-05 · Árbitros presentados por los clubes y validados por la Comisión de Arbitraje (RF-021, RF-112, RF-113).';

CREATE TABLE siglim.disponibilidad_arbitral (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  arbitro_id  uuid NOT NULL REFERENCES siglim.arbitros (id),
  periodo     tstzrange NOT NULL,
  disponible  boolean NOT NULL DEFAULT true,
  creado_en   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_disponibilidad_arbitral CHECK (NOT isempty(periodo))
);
COMMENT ON TABLE siglim.disponibilidad_arbitral IS 'M-05 · Disponibilidad por fecha y horario (RF-022, backlog).';

-- ===== M-06 Canchas y recursos ==========================================================

CREATE TABLE siglim.sedes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id    uuid NOT NULL REFERENCES siglim.ligas (id),
  nombre     varchar(120) NOT NULL,
  direccion  text,
  UNIQUE (liga_id, nombre)
);
COMMENT ON TABLE siglim.sedes IS 'M-06 · Sede o unidad deportiva que agrupa canchas (RF-028, backlog).';

CREATE TABLE siglim.canchas (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id              uuid NOT NULL REFERENCES siglim.ligas (id),
  sede_id              uuid REFERENCES siglim.sedes (id),
  nombre               varchar(120) NOT NULL,
  ubicacion            siglim.ubicacion_cancha NOT NULL,
  direccion            text,
  propietario          siglim.propietario_cancha NOT NULL,
  club_id              uuid REFERENCES siglim.clubes (id),
  propietario_externo  varchar(150),
  caracteristicas      text,
  activa               boolean NOT NULL DEFAULT true,
  creado_en            timestamptz NOT NULL DEFAULT now(),
  UNIQUE (liga_id, nombre),
  CONSTRAINT ck_canchas_propietario CHECK (
    (propietario = 'CLUB') = (club_id IS NOT NULL)
    AND (propietario = 'EXTERNO') = (propietario_externo IS NOT NULL))
);
COMMENT ON TABLE siglim.canchas IS 'M-06 · Canchas con ubicación y propietario (RF-027, DEC-33).';

CREATE TABLE siglim.disponibilidad_canchas (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cancha_id   uuid NOT NULL REFERENCES siglim.canchas (id),
  tipo        siglim.tipo_disponibilidad NOT NULL,
  periodo     tstzrange NOT NULL,
  motivo      text,
  creado_por  uuid REFERENCES siglim.perfiles (id),
  creado_en   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_disponibilidad_cancha_motivo CHECK (tipo = 'DISPONIBLE' OR motivo IS NOT NULL),
  CONSTRAINT ck_disponibilidad_cancha_periodo CHECK (NOT isempty(periodo))
);
COMMENT ON TABLE siglim.disponibilidad_canchas IS 'M-06 · Disponibilidad, bloqueos con motivo y mantenimiento (RF-029 a RF-031).';

CREATE TABLE siglim.horarios_cancha_club (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cancha_id     uuid NOT NULL REFERENCES siglim.canchas (id),
  club_id       uuid NOT NULL REFERENCES siglim.clubes (id),
  temporada_id  uuid NOT NULL REFERENCES siglim.temporadas (id),
  categoria_id  uuid NOT NULL REFERENCES siglim.categorias (id),
  dia_semana    smallint NOT NULL,
  hora_inicio   time NOT NULL,
  hora_fin      time NOT NULL,
  es_comodato   boolean NOT NULL DEFAULT false,
  CONSTRAINT ck_horarios_dia CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT ck_horarios_horas CHECK (hora_fin > hora_inicio)
);
COMMENT ON TABLE siglim.horarios_cancha_club IS 'M-06 · Horarios por categoría de la cancha que ofrece un club o que tiene en comodato (RF-119, DEC-33; backlog).';

CREATE TABLE siglim.solicitudes_cancha (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id               uuid NOT NULL REFERENCES siglim.ligas (id),
  tipo                  siglim.tipo_solicitud_cancha NOT NULL,
  numero_oficio         varchar(30),
  club_id               uuid REFERENCES siglim.clubes (id),
  solicitante_externo   varchar(150),
  cancha_id             uuid REFERENCES siglim.canchas (id),
  temporada_id          uuid REFERENCES siglim.temporadas (id),
  datos_formato         jsonb NOT NULL,
  estado                siglim.estado_solicitud_cancha NOT NULL,
  capturada_por         uuid NOT NULL REFERENCES siglim.perfiles (id),
  capturada_en          timestamptz NOT NULL DEFAULT now(),
  resuelta_por          uuid REFERENCES siglim.perfiles (id),
  resuelta_en           timestamptz,
  observaciones         text,
  UNIQUE (liga_id, numero_oficio),
  CONSTRAINT ck_solicitudes_cancha_solicitante CHECK ((club_id IS NULL) <> (solicitante_externo IS NULL)),
  CONSTRAINT ck_solicitudes_cancha_estado CHECK (
    (tipo IN ('PRESTAMO', 'COMODATO') AND estado IN ('PENDIENTE', 'APROBADA', 'NO_APROBADA'))
    OR (tipo = 'OFERTA' AND estado IN ('PENDIENTE_NEGOCIACION', 'ACEPTADA', 'RECHAZADA')))
);
COMMENT ON TABLE siglim.solicitudes_cancha IS 'M-06 · Formato 1 (préstamo o comodato) y Formato 2 (oferta) con número de oficio (RF-116 a RF-118, DEC-35; backlog).';

-- ===== M-10 Competencias (fase final; requerida por jornadas y partidos) =================

CREATE TABLE siglim.fases (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grupo_id           uuid NOT NULL REFERENCES siglim.grupos (id),
  tipo               siglim.tipo_fase NOT NULL DEFAULT 'LIGUILLA',
  parametros_id      uuid NOT NULL REFERENCES siglim.parametros_temporada (id),
  estado             siglim.estado_fase NOT NULL DEFAULT 'CONFIGURACION',
  campeon_id         uuid REFERENCES siglim.equipos (id),
  subcampeon_id      uuid REFERENCES siglim.equipos (id),
  configurada_por    uuid REFERENCES siglim.perfiles (id),
  creado_en          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grupo_id, tipo)
);
COMMENT ON TABLE siglim.fases IS 'M-10 · Fase final (liguilla) del grupo con la versión de parámetros usada (RF-076 a RF-081; backlog). La fase regular no tiene fila.';

CREATE TABLE siglim.llaves (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fase_id            uuid NOT NULL REFERENCES siglim.fases (id),
  ronda              smallint NOT NULL,
  orden              smallint NOT NULL,
  equipo_a_id        uuid REFERENCES siglim.equipos (id),
  equipo_b_id        uuid REFERENCES siglim.equipos (id),
  ganador_id         uuid REFERENCES siglim.equipos (id),
  siguiente_llave_id uuid REFERENCES siglim.llaves (id),
  UNIQUE (fase_id, ronda, orden),
  CONSTRAINT ck_llaves_equipos CHECK (equipo_a_id IS NULL OR equipo_b_id IS NULL OR equipo_a_id <> equipo_b_id),
  CONSTRAINT ck_llaves_ganador CHECK (ganador_id IS NULL OR ganador_id IN (equipo_a_id, equipo_b_id))
);
COMMENT ON TABLE siglim.llaves IS 'M-10 · Llaves de eliminación; sus partidos se programan manualmente (RF-078, RF-080; backlog).';

-- ===== M-07 Programación manual =========================================================

CREATE TABLE siglim.jornadas (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grupo_id            uuid NOT NULL REFERENCES siglim.grupos (id),
  fase_id             uuid REFERENCES siglim.fases (id),
  numero              smallint NOT NULL,
  estado_publicacion  siglim.estado_publicacion NOT NULL DEFAULT 'BORRADOR',
  enviada_por         uuid REFERENCES siglim.perfiles (id),
  enviada_en          timestamptz,
  aprobada_por        uuid REFERENCES siglim.perfiles (id),
  aprobada_en         timestamptz,
  publicada_en        timestamptz,
  observaciones       text,
  creado_por          uuid REFERENCES siglim.perfiles (id),
  creado_en           timestamptz NOT NULL DEFAULT now(),
  actualizado_en      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_jornadas_numero CHECK (numero > 0),
  CONSTRAINT ck_jornadas_aprobacion CHECK (aprobada_por IS NULL OR enviada_por IS NULL OR aprobada_por <> enviada_por)
);
CREATE UNIQUE INDEX ux_jornadas_regular ON siglim.jornadas (grupo_id, numero) WHERE fase_id IS NULL;
CREATE UNIQUE INDEX ux_jornadas_fase ON siglim.jornadas (fase_id, numero) WHERE fase_id IS NOT NULL;
COMMENT ON TABLE siglim.jornadas IS 'M-07 · Jornada con estado de publicación Borrador → Revisión → Publicado; la aprueba el Presidente (RF-033, RF-121, DP-004).';

CREATE TABLE siglim.partidos (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  jornada_id           uuid NOT NULL REFERENCES siglim.jornadas (id),
  llave_id             uuid REFERENCES siglim.llaves (id),
  equipo_local_id      uuid NOT NULL REFERENCES siglim.equipos (id),
  equipo_visitante_id  uuid NOT NULL REFERENCES siglim.equipos (id),
  cancha_id            uuid NOT NULL REFERENCES siglim.canchas (id),
  inicio               timestamptz NOT NULL,
  fin_bloque           timestamptz NOT NULL,
  estado               siglim.estado_partido NOT NULL DEFAULT 'PROGRAMADO',
  motivo_localia       text,
  creado_por           uuid REFERENCES siglim.perfiles (id),
  creado_en            timestamptz NOT NULL DEFAULT now(),
  actualizado_en       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_partidos_equipos CHECK (equipo_local_id <> equipo_visitante_id),
  CONSTRAINT ck_partidos_bloque CHECK (fin_bloque > inicio),
  CONSTRAINT ex_partidos_cancha_ocupada EXCLUDE USING gist (
    cancha_id WITH =, tstzrange(inicio, fin_bloque) WITH &&) WHERE (estado <> 'CANCELADO')
);
COMMENT ON TABLE siglim.partidos IS 'M-07/M-08 · Partido programado manualmente. fin_bloque = inicio + bloque de cancha de la categoría (DEC-25). Sin traslapes de cancha (VAL-004) ni de equipo (trigger, VAL-003).';
COMMENT ON CONSTRAINT ex_partidos_cancha_ocupada ON siglim.partidos IS 'VAL-004: la cancha ya está ocupada en ese horario.';

CREATE TABLE siglim.partido_estado_historial (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  partido_id       uuid NOT NULL REFERENCES siglim.partidos (id),
  estado_anterior  siglim.estado_partido,
  estado_nuevo     siglim.estado_partido NOT NULL,
  motivo           text NOT NULL,
  cambiado_por     uuid REFERENCES siglim.perfiles (id),
  cambiado_en      timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE siglim.partido_estado_historial IS 'M-08 · Transiciones del partido con usuario, fecha y motivo (RF-045, RN-021).';

CREATE TABLE siglim.historial_publicacion (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  entidad          siglim.entidad_publicable NOT NULL,
  entidad_id       uuid NOT NULL,
  estado_anterior  siglim.estado_publicacion,
  estado_nuevo     siglim.estado_publicacion NOT NULL,
  motivo           text,
  cambiado_por     uuid REFERENCES siglim.perfiles (id),
  cambiado_en      timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE siglim.historial_publicacion IS 'M-07/M-11 · Cambios Borrador → Revisión → Publicado de jornadas y comunicados (RF-090, RF-121).';

-- ===== M-05 Designaciones ===============================================================

CREATE TABLE siglim.designaciones (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partido_id    uuid NOT NULL REFERENCES siglim.partidos (id),
  arbitro_id    uuid NOT NULL REFERENCES siglim.arbitros (id),
  funcion       siglim.funcion_arbitral NOT NULL DEFAULT 'CENTRAL',
  vigente       boolean NOT NULL DEFAULT true,
  designado_por uuid REFERENCES siglim.perfiles (id),
  designado_en  timestamptz NOT NULL DEFAULT now(),
  motivo_cambio text
);
CREATE UNIQUE INDEX ux_designaciones_arbitro ON siglim.designaciones (partido_id, arbitro_id) WHERE vigente;
CREATE UNIQUE INDEX ux_designaciones_central ON siglim.designaciones (partido_id) WHERE vigente AND funcion = 'CENTRAL';
COMMENT ON TABLE siglim.designaciones IS 'M-05 · Árbitros designados a un partido; un central vigente; nunca del club de un equipo (RF-023, RF-115, VAL-019).';

-- ===== M-08 Partidos, cédula y resultados ===============================================

CREATE TABLE siglim.cedulas (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partido_id                uuid NOT NULL UNIQUE REFERENCES siglim.partidos (id),
  estado                    siglim.estado_cedula NOT NULL DEFAULT 'EN_CAPTURA',
  capturista_id             uuid NOT NULL REFERENCES siglim.perfiles (id),
  goles_local               smallint,
  goles_visitante           smallint,
  penales_local             smallint,
  penales_visitante         smallint,
  no_presentado_equipo_id   uuid REFERENCES siglim.equipos (id),
  observaciones             text,
  enviada_en                timestamptz,
  plazo_vence_en            timestamptz,
  plazo_vencido             boolean NOT NULL DEFAULT false,
  devuelta_observaciones    text,
  aprobada_por              uuid REFERENCES siglim.perfiles (id),
  aprobada_en               timestamptz,
  aprobada_por_comision     boolean NOT NULL DEFAULT false,
  creado_en                 timestamptz NOT NULL DEFAULT now(),
  actualizado_en            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_cedulas_goles CHECK (goles_local >= 0 AND goles_visitante >= 0 AND coalesce(penales_local, 0) >= 0 AND coalesce(penales_visitante, 0) >= 0),
  CONSTRAINT ck_cedulas_penales CHECK ((penales_local IS NULL) = (penales_visitante IS NULL)),
  CONSTRAINT ck_cedulas_separacion CHECK (aprobada_por IS NULL OR aprobada_por <> capturista_id),
  CONSTRAINT ck_cedulas_aprobacion CHECK ((estado = 'APROBADA') = (aprobada_por IS NOT NULL AND aprobada_en IS NOT NULL)),
  CONSTRAINT ck_cedulas_comision CHECK (NOT aprobada_por_comision OR plazo_vencido)
);
COMMENT ON TABLE siglim.cedulas IS 'M-08 · Cédula del partido: la captura el Capturista y la aprueba el árbitro designado o, con plazo vencido, la Comisión (RF-025, RF-122 a RF-124, VAL-021).';

CREATE TABLE siglim.cedula_estado_historial (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cedula_id        uuid NOT NULL REFERENCES siglim.cedulas (id),
  estado_anterior  siglim.estado_cedula,
  estado_nuevo     siglim.estado_cedula NOT NULL,
  motivo           text,
  cambiado_por     uuid REFERENCES siglim.perfiles (id),
  cambiado_en      timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE siglim.cedula_estado_historial IS 'M-08 · Transiciones de la cédula (ERS §4.3.2).';

CREATE TABLE siglim.alineaciones (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cedula_id             uuid NOT NULL REFERENCES siglim.cedulas (id),
  registro_jugador_id   uuid NOT NULL REFERENCES siglim.registros_jugador (id),
  equipo_id             uuid NOT NULL REFERENCES siglim.equipos (id),
  numero_playera        smallint,
  titular               boolean NOT NULL DEFAULT true,
  categoria_superior    boolean NOT NULL DEFAULT false,
  UNIQUE (cedula_id, registro_jugador_id),
  CONSTRAINT ck_alineaciones_playera CHECK (numero_playera IS NULL OR numero_playera BETWEEN 0 AND 99)
);
COMMENT ON TABLE siglim.alineaciones IS 'M-08 · Jugadores del partido; categoria_superior indica alineación en la categoría inmediata superior de su club (RF-019, RF-110, DEC-12).';

CREATE TABLE siglim.eventos_cedula (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cedula_id           uuid NOT NULL REFERENCES siglim.cedulas (id),
  tipo                siglim.tipo_evento_cedula NOT NULL,
  minuto              smallint,
  equipo_id           uuid NOT NULL REFERENCES siglim.equipos (id),
  alineacion_id       uuid NOT NULL REFERENCES siglim.alineaciones (id),
  alineacion_entra_id uuid REFERENCES siglim.alineaciones (id),
  observaciones       text,
  CONSTRAINT ck_eventos_minuto CHECK (minuto IS NULL OR minuto BETWEEN 0 AND 150),
  CONSTRAINT ck_eventos_sustitucion CHECK ((tipo = 'SUSTITUCION') = (alineacion_entra_id IS NOT NULL))
);
COMMENT ON TABLE siglim.eventos_cedula IS 'M-08 · Goles, tarjetas y sustituciones de la cédula (RF-025, DEC-19).';

CREATE TABLE siglim.tipos_incidencia (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  liga_id          uuid NOT NULL REFERENCES siglim.ligas (id),
  codigo           varchar(40) NOT NULL,
  nombre           varchar(100) NOT NULL,
  abre_expediente  boolean NOT NULL,
  activo           boolean NOT NULL DEFAULT true,
  es_demo          boolean NOT NULL DEFAULT false,
  UNIQUE (liga_id, codigo)
);
COMMENT ON TABLE siglim.tipos_incidencia IS 'M-09 · Catálogo configurable; cada tipo indica si abre expediente (RF-128, DEC-22).';

CREATE TABLE siglim.incidencias (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cedula_id           uuid NOT NULL REFERENCES siglim.cedulas (id),
  tipo_incidencia_id  bigint NOT NULL REFERENCES siglim.tipos_incidencia (id),
  minuto              smallint,
  descripcion         text NOT NULL
);
COMMENT ON TABLE siglim.incidencias IS 'M-08 · Incidencias de la cédula (RF-026).';

CREATE TABLE siglim.incidencia_involucrados (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incidencia_id  uuid NOT NULL REFERENCES siglim.incidencias (id),
  persona_id     uuid REFERENCES siglim.personas (id),
  equipo_id      uuid REFERENCES siglim.equipos (id),
  CONSTRAINT ck_involucrados_uno CHECK ((persona_id IS NULL) <> (equipo_id IS NULL))
);
COMMENT ON TABLE siglim.incidencia_involucrados IS 'M-08 · Personas o equipos involucrados en una incidencia (RF-026, RF-058).';

-- ===== M-09 Disciplina ==================================================================

CREATE TABLE siglim.articulos (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id               uuid NOT NULL REFERENCES siglim.ligas (id),
  numero                varchar(20) NOT NULL,
  descripcion           text NOT NULL,
  tipo_sancion          siglim.tipo_sancion NOT NULL,
  sujeto                siglim.sujeto_sancion NOT NULL,
  efecto                siglim.efecto_sancion NOT NULL DEFAULT 'HACIA_ADELANTE',
  aplicacion_automatica boolean NOT NULL DEFAULT false,
  partidos_suspension   smallint,
  puntos                smallint,
  monto_multa           numeric(12, 2),
  otorga_default_restantes boolean NOT NULL DEFAULT true,
  activo                boolean NOT NULL DEFAULT true,
  es_demo               boolean NOT NULL DEFAULT false,
  UNIQUE (liga_id, numero),
  CONSTRAINT ck_articulos_valores CHECK (
    (tipo_sancion <> 'SUSPENSION_PARTIDOS' OR partidos_suspension > 0)
    AND (tipo_sancion <> 'PERDIDA_PUNTOS' OR puntos > 0)
    AND (tipo_sancion <> 'MULTA' OR monto_multa > 0))
);
COMMENT ON TABLE siglim.articulos IS 'M-09 · Artículos del reglamento con sanción, sujeto, efecto y aplicación automática (RF-129, DEC-30). Semilla [DEMO].';

CREATE TABLE siglim.expedientes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id         uuid NOT NULL REFERENCES siglim.ligas (id),
  temporada_id    uuid NOT NULL REFERENCES siglim.temporadas (id),
  folio           varchar(30) NOT NULL,
  origen          siglim.origen_expediente NOT NULL,
  incidencia_id   uuid UNIQUE REFERENCES siglim.incidencias (id),
  articulo_id     uuid REFERENCES siglim.articulos (id),
  estado          siglim.estado_expediente NOT NULL DEFAULT 'ABIERTO',
  descripcion     text,
  abierto_por     uuid REFERENCES siglim.perfiles (id),
  abierto_en      timestamptz NOT NULL DEFAULT now(),
  actualizado_en  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (liga_id, folio),
  CONSTRAINT ck_expedientes_origen CHECK ((origen = 'INCIDENCIA') = (incidencia_id IS NOT NULL))
);
COMMENT ON TABLE siglim.expedientes IS 'M-09 · Caso disciplinario; uno por incidencia que lo requiere, o automático por artículo (RF-057, RF-130).';

CREATE TABLE siglim.expediente_estado_historial (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  expediente_id    uuid NOT NULL REFERENCES siglim.expedientes (id),
  estado_anterior  siglim.estado_expediente,
  estado_nuevo     siglim.estado_expediente NOT NULL,
  motivo           text,
  cambiado_por     uuid REFERENCES siglim.perfiles (id),
  cambiado_en      timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE siglim.expediente_estado_historial IS 'M-09 · Transiciones del expediente (ERS §4.3.4).';

CREATE TABLE siglim.resoluciones (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  expediente_id  uuid NOT NULL REFERENCES siglim.expedientes (id),
  instancia      siglim.instancia_resolucion NOT NULL DEFAULT 'PRIMERA',
  articulo_id    uuid REFERENCES siglim.articulos (id),
  fundamentos    text NOT NULL,
  sin_sancion    boolean NOT NULL DEFAULT false,
  resuelta_por   uuid NOT NULL REFERENCES siglim.perfiles (id),
  resuelta_en    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_resoluciones_articulo CHECK (sin_sancion OR articulo_id IS NOT NULL)
);
COMMENT ON TABLE siglim.resoluciones IS 'M-09 · Resolución inmutable de primera instancia o de recurso (RF-062, RF-065, RF-067).';

CREATE TABLE siglim.sanciones (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  resolucion_id        uuid NOT NULL REFERENCES siglim.resoluciones (id),
  tipo                 siglim.tipo_sancion NOT NULL,
  sujeto               siglim.sujeto_sancion NOT NULL,
  efecto               siglim.efecto_sancion NOT NULL,
  persona_id           uuid REFERENCES siglim.personas (id),
  equipo_id            uuid REFERENCES siglim.equipos (id),
  club_id              uuid REFERENCES siglim.clubes (id),
  temporada_id         uuid NOT NULL REFERENCES siglim.temporadas (id),
  partidos             smallint,
  partidos_cumplidos   smallint NOT NULL DEFAULT 0,
  puntos               smallint,
  monto                numeric(12, 2),
  vigente_desde        date NOT NULL DEFAULT current_date,
  vigente_hasta        date,
  estado               siglim.estado_sancion NOT NULL DEFAULT 'VIGENTE',
  publicable           boolean NOT NULL DEFAULT false,
  publicada_en         timestamptz,
  creado_en            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_sanciones_sujeto CHECK (
    (sujeto = 'JUGADOR' AND persona_id IS NOT NULL AND equipo_id IS NULL AND club_id IS NULL)
    OR (sujeto = 'EQUIPO' AND equipo_id IS NOT NULL AND persona_id IS NULL AND club_id IS NULL)
    OR (sujeto = 'CLUB' AND club_id IS NOT NULL AND persona_id IS NULL AND equipo_id IS NULL)),
  CONSTRAINT ck_sanciones_valores CHECK (
    (tipo <> 'SUSPENSION_PARTIDOS' OR partidos > 0)
    AND (tipo <> 'PERDIDA_PUNTOS' OR puntos > 0)
    AND (tipo <> 'MULTA' OR monto > 0)
    AND partidos_cumplidos >= 0 AND (partidos IS NULL OR partidos_cumplidos <= partidos)),
  CONSTRAINT ck_sanciones_vigencia CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde),
  CONSTRAINT ck_sanciones_publicacion CHECK (publicada_en IS NULL OR publicable)
);
COMMENT ON TABLE siglim.sanciones IS 'M-09 · Consecuencia de una resolución con vigencia por partidos o fechas; bloquea alineación o programación (RF-063, RF-064, RN-057).';

CREATE TABLE siglim.recursos (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  expediente_id      uuid NOT NULL REFERENCES siglim.expedientes (id),
  resolucion_id      uuid NOT NULL REFERENCES siglim.resoluciones (id),
  club_id            uuid NOT NULL REFERENCES siglim.clubes (id),
  motivo             text NOT NULL,
  estado             siglim.estado_recurso NOT NULL DEFAULT 'INTERPUESTO',
  interpuesto_por    uuid NOT NULL REFERENCES siglim.perfiles (id),
  interpuesto_en     timestamptz NOT NULL DEFAULT now(),
  resolucion_final_id uuid REFERENCES siglim.resoluciones (id),
  CONSTRAINT ck_recursos_resolucion CHECK ((estado = 'RESUELTO') = (resolucion_final_id IS NOT NULL))
);
COMMENT ON TABLE siglim.recursos IS 'M-09 · Recurso de inconformidad resuelto por el Presidente en segunda instancia (RF-067, DEC-31; backlog). Plazo: PEN-041.';

-- ===== M-08 Resultados (después de resoluciones) ========================================

CREATE TABLE siglim.resultados (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partido_id         uuid NOT NULL REFERENCES siglim.partidos (id),
  version            integer NOT NULL,
  goles_local        smallint NOT NULL,
  goles_visitante    smallint NOT NULL,
  penales_local      smallint,
  penales_visitante  smallint,
  origen             siglim.origen_resultado NOT NULL,
  cedula_id          uuid REFERENCES siglim.cedulas (id),
  resolucion_id      uuid REFERENCES siglim.resoluciones (id),
  por_default        boolean NOT NULL DEFAULT false,
  vigente            boolean NOT NULL DEFAULT true,
  motivo             text NOT NULL,
  registrado_por     uuid REFERENCES siglim.perfiles (id),
  registrado_en      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (partido_id, version),
  CONSTRAINT ck_resultados_goles CHECK (goles_local >= 0 AND goles_visitante >= 0),
  CONSTRAINT ck_resultados_penales CHECK ((penales_local IS NULL) = (penales_visitante IS NULL)),
  CONSTRAINT ck_resultados_origen CHECK (
    (origen = 'CEDULA' AND cedula_id IS NOT NULL AND resolucion_id IS NULL)
    OR (origen = 'RESOLUCION' AND resolucion_id IS NOT NULL))
);
CREATE UNIQUE INDEX ux_resultados_vigente ON siglim.resultados (partido_id) WHERE vigente;
COMMENT ON TABLE siglim.resultados IS 'M-08 · Resultado oficial versionado: la versión vigente es la oficial; corregir crea una versión nueva (RF-048, RF-052, RN-024).';

CREATE TABLE siglim.sorteos_desempate (
  grupo_id        uuid NOT NULL REFERENCES siglim.grupos (id),
  equipo_id       uuid NOT NULL REFERENCES siglim.equipos (id),
  orden           smallint NOT NULL,
  registrado_por  uuid NOT NULL REFERENCES siglim.perfiles (id),
  registrado_en   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (grupo_id, equipo_id),
  UNIQUE (grupo_id, orden)
);
COMMENT ON TABLE siglim.sorteos_desempate IS 'M-08 · Sorteo registrado por el Presidente como último criterio de desempate (DEC-27).';

CREATE TABLE siglim.tabla_historial (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grupo_id     uuid NOT NULL REFERENCES siglim.grupos (id),
  jornada_id   uuid NOT NULL REFERENCES siglim.jornadas (id),
  datos        jsonb NOT NULL,
  generada_en  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (jornada_id)
);
COMMENT ON TABLE siglim.tabla_historial IS 'M-08 · Instantánea de la tabla al cerrar cada jornada, solo lectura (RF-051; backlog). La tabla vigente siempre se calcula.';

-- ===== M-10 Ascenso y descenso ==========================================================

CREATE TABLE siglim.propuestas_movimiento (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  temporada_id   uuid NOT NULL REFERENCES siglim.temporadas (id),
  parametros_id  uuid NOT NULL REFERENCES siglim.parametros_temporada (id),
  estado         siglim.estado_propuesta NOT NULL DEFAULT 'PROPUESTA',
  generada_en    timestamptz NOT NULL DEFAULT now(),
  validada_por   uuid REFERENCES siglim.perfiles (id),
  validada_en    timestamptz,
  observaciones  text
);
COMMENT ON TABLE siglim.propuestas_movimiento IS 'M-10 · Propuesta de ascensos y descensos con la versión de reglas usada; la valida el Presidente (RF-073 a RF-075; backlog).';

CREATE TABLE siglim.propuesta_movimiento_detalle (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  propuesta_id         uuid NOT NULL REFERENCES siglim.propuestas_movimiento (id),
  equipo_id            uuid NOT NULL REFERENCES siglim.equipos (id),
  tipo                 siglim.tipo_movimiento NOT NULL,
  categoria_origen_id  uuid NOT NULL REFERENCES siglim.categorias (id),
  categoria_destino_id uuid NOT NULL REFERENCES siglim.categorias (id),
  posicion_final       smallint NOT NULL,
  excluido             boolean NOT NULL DEFAULT false,
  motivo_exclusion     text,
  UNIQUE (propuesta_id, equipo_id),
  CONSTRAINT ck_detalle_exclusion CHECK (NOT excluido OR motivo_exclusion IS NOT NULL)
);
COMMENT ON TABLE siglim.propuesta_movimiento_detalle IS 'M-10 · Equipos que suben o bajan y exclusiones por RN-052 (RF-070, RF-071; backlog).';

-- ===== M-11 Publicación =================================================================

CREATE TABLE siglim.comunicados (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id             uuid NOT NULL REFERENCES siglim.ligas (id),
  titulo              varchar(200) NOT NULL,
  cuerpo              text NOT NULL,
  estado_publicacion  siglim.estado_publicacion NOT NULL DEFAULT 'BORRADOR',
  redactado_por       uuid NOT NULL REFERENCES siglim.perfiles (id),
  aprobado_por        uuid REFERENCES siglim.perfiles (id),
  aprobado_en         timestamptz,
  publicado_en        timestamptz,
  observaciones       text,
  creado_en           timestamptz NOT NULL DEFAULT now(),
  actualizado_en      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_comunicados_dual CHECK (aprobado_por IS NULL OR aprobado_por <> redactado_por)
);
COMMENT ON TABLE siglim.comunicados IS 'M-11 · Comunicados con flujo Borrador → Revisión → Publicado y aprobación del Presidente (RF-086, RF-090, P-09).';

-- ===== M-13 Tesorería ===================================================================

CREATE TABLE siglim.tarifas (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  temporada_id  uuid NOT NULL REFERENCES siglim.temporadas (id),
  categoria_id  uuid NOT NULL REFERENCES siglim.categorias (id),
  concepto      siglim.concepto_tarifa NOT NULL,
  monto         numeric(12, 2) NOT NULL,
  UNIQUE (temporada_id, categoria_id, concepto),
  CONSTRAINT ck_tarifas_monto CHECK (monto >= 0)
);
COMMENT ON TABLE siglim.tarifas IS 'M-13 · Tarifas de arbitraje y cancha por temporada y categoría (RF-135; backlog). Montos reales: PEN-042.';

CREATE TABLE siglim.cobros (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  liga_id         uuid NOT NULL REFERENCES siglim.ligas (id),
  club_id         uuid NOT NULL REFERENCES siglim.clubes (id),
  equipo_id       uuid REFERENCES siglim.equipos (id),
  tipo            siglim.tipo_cobro NOT NULL,
  concepto        varchar(200) NOT NULL,
  monto           numeric(12, 2) NOT NULL,
  periodo_inicio  date NOT NULL DEFAULT current_date,
  fecha_limite    date NOT NULL,
  estado          siglim.estado_cobro NOT NULL DEFAULT 'PENDIENTE',
  partido_id      uuid REFERENCES siglim.partidos (id),
  sancion_id      uuid REFERENCES siglim.sanciones (id),
  creado_por      uuid REFERENCES siglim.perfiles (id),
  creado_en       timestamptz NOT NULL DEFAULT now(),
  actualizado_en  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_cobros_monto CHECK (monto > 0),
  CONSTRAINT ck_cobros_periodo CHECK (fecha_limite >= periodo_inicio),
  CONSTRAINT ck_cobros_origen CHECK (
    (tipo IN ('ARBITRAJE', 'CANCHA') AND partido_id IS NOT NULL AND equipo_id IS NOT NULL)
    OR (tipo = 'MULTA' AND sancion_id IS NOT NULL)
    OR (tipo = 'MANUAL'))
);
CREATE UNIQUE INDEX ux_cobros_partido ON siglim.cobros (partido_id, equipo_id, tipo) WHERE partido_id IS NOT NULL;
CREATE UNIQUE INDEX ux_cobros_sancion ON siglim.cobros (sancion_id) WHERE sancion_id IS NOT NULL;
COMMENT ON TABLE siglim.cobros IS 'M-13 · Cargos a club o equipo: automáticos por partido, por multa o manuales (RF-133, RF-136, RF-137). Estados ERS §4.3.5.';

CREATE TABLE siglim.intentos_pago (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cobro_id      uuid NOT NULL REFERENCES siglim.cobros (id),
  referencia    varchar(40) NOT NULL UNIQUE,
  estado        siglim.estado_intento_pago NOT NULL DEFAULT 'PENDIENTE',
  iniciado_por  uuid NOT NULL REFERENCES siglim.perfiles (id),
  iniciado_en   timestamptz NOT NULL DEFAULT now(),
  resuelto_en   timestamptz,
  CONSTRAINT ck_intentos_referencia CHECK (referencia ~ '^SIM-[0-9]{8}-[A-Z0-9]{6}$')
);
CREATE UNIQUE INDEX ux_intentos_pendiente ON siglim.intentos_pago (cobro_id) WHERE estado = 'PENDIENTE';
COMMENT ON TABLE siglim.intentos_pago IS 'M-13 · Intento de pago simulado con referencia ficticia; no guarda datos de tarjeta (RF-138, ADR-0012).';

CREATE TABLE siglim.pagos (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cobro_id         uuid NOT NULL UNIQUE REFERENCES siglim.cobros (id),
  intento_id       uuid UNIQUE REFERENCES siglim.intentos_pago (id),
  medio            siglim.medio_pago NOT NULL,
  monto            numeric(12, 2) NOT NULL,
  referencia       varchar(60),
  pagado_en        timestamptz NOT NULL DEFAULT now(),
  registrado_por   uuid NOT NULL REFERENCES siglim.perfiles (id),
  CONSTRAINT ck_pagos_monto CHECK (monto > 0),
  CONSTRAINT ck_pagos_medio CHECK ((medio = 'EN_LINEA_SIMULADO') = (intento_id IS NOT NULL))
);
COMMENT ON TABLE siglim.pagos IS 'M-13 · Pago de un cobro, en línea simulado o registrado por el Tesorero con comprobante (RF-138, RF-139).';

-- ===== Documentos en AWS S3 (ADR-0013) ==================================================

CREATE TABLE siglim.documentos (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo_documento_id  bigint NOT NULL REFERENCES siglim.tipos_documento (id),
  registro_id        uuid REFERENCES siglim.registros_jugador (id),
  persona_id         uuid REFERENCES siglim.personas (id),
  afiliacion_id      uuid REFERENCES siglim.afiliaciones (id),
  expediente_id      uuid REFERENCES siglim.expedientes (id),
  pago_id            uuid REFERENCES siglim.pagos (id),
  s3_bucket          varchar(63) NOT NULL,
  s3_clave           varchar(512) NOT NULL,
  url                text NOT NULL,
  tipo_mime          varchar(60) NOT NULL,
  tamano_bytes       integer NOT NULL,
  sha256             char(64) NOT NULL,
  estado_validacion  siglim.estado_validacion NOT NULL DEFAULT 'PENDIENTE',
  validado_por       uuid REFERENCES siglim.perfiles (id),
  validado_en        timestamptz,
  observaciones      text,
  reemplazado_por_id uuid REFERENCES siglim.documentos (id),
  cargado_por        uuid NOT NULL REFERENCES siglim.perfiles (id),
  cargado_en         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (s3_bucket, s3_clave),
  CONSTRAINT ck_documentos_dueno CHECK (num_nonnulls(registro_id, persona_id, afiliacion_id, expediente_id, pago_id) = 1),
  CONSTRAINT ck_documentos_tipo CHECK (tipo_mime IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')),
  CONSTRAINT ck_documentos_tamano CHECK (tamano_bytes > 0 AND tamano_bytes <= 5242880),
  CONSTRAINT ck_documentos_url CHECK (url ~ '^https://'),
  CONSTRAINT ck_documentos_clave CHECK (s3_clave !~ '\.\.')
);
COMMENT ON TABLE siglim.documentos IS 'Documentos, fotos, evidencias y comprobantes en un bucket privado de AWS S3; aquí se guardan bucket, clave y URL del objeto. Se leen con URL prefirmadas (RF-059, RF-108, RF-139, RNF-018, ADR-0013).';

-- ===== M-14 Notificaciones ==============================================================

CREATE TABLE siglim.notificaciones (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  perfil_id   uuid NOT NULL REFERENCES siglim.perfiles (id),
  evento      varchar(60) NOT NULL,
  titulo      varchar(200) NOT NULL,
  cuerpo      text,
  enlace      varchar(300),
  creada_en   timestamptz NOT NULL DEFAULT now(),
  leida_en    timestamptz
);
COMMENT ON TABLE siglim.notificaciones IS 'M-14 · Avisos dentro de la aplicación (RF-142, ADR-0010).';

CREATE TABLE siglim.correos_salientes (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notificacion_id    uuid REFERENCES siglim.notificaciones (id),
  destinatario       varchar(254) NOT NULL,
  asunto             varchar(200) NOT NULL,
  cuerpo             text NOT NULL,
  estado             siglim.estado_correo NOT NULL DEFAULT 'PENDIENTE',
  intentos           smallint NOT NULL DEFAULT 0,
  proximo_intento_en timestamptz NOT NULL DEFAULT now(),
  ultimo_error       text,
  enviado_en         timestamptz,
  creado_en          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_correos_intentos CHECK (intentos BETWEEN 0 AND 5)
);
COMMENT ON TABLE siglim.correos_salientes IS 'M-14 · Bandeja de salida de correos (patrón transactional outbox, RF-143, ADR-0010).';

-- -------------------------------------------------------------------------------------
-- 4. ÍNDICES Y UNICIDADES PARCIALES
-- -------------------------------------------------------------------------------------
CREATE UNIQUE INDEX ux_temporadas_activa ON siglim.temporadas (liga_id) WHERE estado = 'ACTIVA';         -- RN-058
CREATE UNIQUE INDEX ux_registros_activo ON siglim.registros_jugador (persona_id, temporada_id)
  WHERE estado IN ('PENDIENTE_VALIDACION', 'ACTIVO', 'SUSPENDIDO');                                    -- RF-107, RN-037
CREATE UNIQUE INDEX ux_cargos_vigentes ON siglim.cargos_directiva (club_id, cargo) WHERE hasta IS NULL;
CREATE UNIQUE INDEX ux_tutelas_vigente ON siglim.tutelas (menor_id, tutor_id) WHERE vigente;
CREATE UNIQUE INDEX ux_asignaciones_activa ON siglim.asignaciones_rol (perfil_id, rol_id, coalesce(club_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE activa;
CREATE UNIQUE INDEX ux_categorias_orden ON siglim.categorias (liga_id, orden) WHERE activa;

CREATE INDEX ix_asignaciones_perfil ON siglim.asignaciones_rol (perfil_id) WHERE activa;
CREATE INDEX ix_personas_apellidos ON siglim.personas (apellido_paterno, apellido_materno, nombre);
CREATE INDEX ix_equipos_club ON siglim.equipos (club_id);
CREATE INDEX ix_equipos_grupo ON siglim.equipos (grupo_id);
CREATE INDEX ix_registros_equipo ON siglim.registros_jugador (equipo_id, estado);
CREATE INDEX ix_registros_persona ON siglim.registros_jugador (persona_id);
CREATE INDEX ix_documentos_registro ON siglim.documentos (registro_id) WHERE registro_id IS NOT NULL;
CREATE INDEX ix_documentos_persona ON siglim.documentos (persona_id) WHERE persona_id IS NOT NULL;
CREATE INDEX ix_arbitros_club ON siglim.arbitros (club_id);
CREATE INDEX ix_disponibilidad_cancha ON siglim.disponibilidad_canchas USING gist (cancha_id, periodo);
CREATE INDEX ix_jornadas_grupo ON siglim.jornadas (grupo_id, estado_publicacion);
CREATE INDEX ix_partidos_jornada ON siglim.partidos (jornada_id);
CREATE INDEX ix_partidos_local ON siglim.partidos (equipo_local_id, inicio);
CREATE INDEX ix_partidos_visitante ON siglim.partidos (equipo_visitante_id, inicio);
CREATE INDEX ix_partidos_estado_inicio ON siglim.partidos (estado, inicio);
CREATE INDEX ix_partido_historial ON siglim.partido_estado_historial (partido_id);
CREATE INDEX ix_designaciones_arbitro ON siglim.designaciones (arbitro_id) WHERE vigente;
CREATE INDEX ix_cedulas_pendientes ON siglim.cedulas (plazo_vence_en) WHERE estado = 'PENDIENTE_VALIDACION';
CREATE INDEX ix_alineaciones_registro ON siglim.alineaciones (registro_jugador_id);
CREATE INDEX ix_eventos_cedula ON siglim.eventos_cedula (cedula_id);
CREATE INDEX ix_incidencias_cedula ON siglim.incidencias (cedula_id);
CREATE INDEX ix_sanciones_persona ON siglim.sanciones (persona_id) WHERE estado = 'VIGENTE';
CREATE INDEX ix_sanciones_equipo ON siglim.sanciones (equipo_id) WHERE equipo_id IS NOT NULL;
CREATE INDEX ix_expedientes_estado ON siglim.expedientes (liga_id, estado);
CREATE INDEX ix_cobros_club ON siglim.cobros (club_id, estado);
CREATE INDEX ix_cobros_vencimiento ON siglim.cobros (fecha_limite) WHERE estado = 'PENDIENTE';
CREATE INDEX ix_notificaciones_perfil ON siglim.notificaciones (perfil_id, creada_en DESC);
CREATE INDEX ix_correos_pendientes ON siglim.correos_salientes (proximo_intento_en) WHERE estado = 'PENDIENTE';
CREATE INDEX ix_auditoria_fecha ON siglim.auditoria (ocurrido_en DESC);
CREATE INDEX ix_auditoria_entidad ON siglim.auditoria (entidad, entidad_id);
CREATE INDEX ix_auditoria_perfil ON siglim.auditoria (perfil_id, ocurrido_en DESC);

-- -------------------------------------------------------------------------------------
-- 5. FUNCIONES DE CONTEXTO (ADR-0014)
--    El backend, al iniciar cada transacción, ejecuta:
--      SELECT set_config('request.jwt.claims', '{"sub":"<auth uuid>","perfil_id":"<uuid>"}', true);
--      SELECT set_config('siglim.motivo', '<motivo de la operación>', true);   -- cuando aplica
--      SET LOCAL ROLE siglim_app;
-- -------------------------------------------------------------------------------------

CREATE FUNCTION siglim.usuario_actual() RETURNS uuid
LANGUAGE sql STABLE
SET search_path = siglim, pg_temp
AS $$
  SELECT nullif(nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'perfil_id', '')::uuid
$$;
COMMENT ON FUNCTION siglim.usuario_actual() IS 'Perfil de SIGLIM que ejecuta la transacción (claim perfil_id que fija el backend).';

CREATE FUNCTION siglim.motivo_actual() RETURNS text
LANGUAGE sql STABLE
SET search_path = siglim, pg_temp
AS $$ SELECT nullif(btrim(current_setting('siglim.motivo', true)), '') $$;
COMMENT ON FUNCTION siglim.motivo_actual() IS 'Motivo de la operación en curso (siglim.motivo), exigido en las transiciones de estado (RN-021).';

CREATE FUNCTION siglim.es_usuario_liga() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM asignaciones_rol a JOIN perfiles p ON p.id = a.perfil_id
    WHERE a.perfil_id = usuario_actual() AND a.activa AND p.activo AND a.ambito = 'LIGA')
$$;

CREATE FUNCTION siglim.clubes_usuario() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
  SELECT a.club_id FROM asignaciones_rol a JOIN perfiles p ON p.id = a.perfil_id
  WHERE a.perfil_id = usuario_actual() AND a.activa AND p.activo AND a.ambito = 'CLUB'
$$;

CREATE FUNCTION siglim.club_visible(p_club uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$ SELECT es_usuario_liga() OR p_club IN (SELECT clubes_usuario()) $$;

CREATE FUNCTION siglim.persona_usuario() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$ SELECT persona_id FROM perfiles WHERE id = usuario_actual() AND activo $$;

CREATE FUNCTION siglim.es_titular(p_persona uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
  SELECT p_persona = persona_usuario()
      OR EXISTS (SELECT 1 FROM tutelas t WHERE t.vigente AND t.menor_id = p_persona AND t.tutor_id = persona_usuario())
$$;
COMMENT ON FUNCTION siglim.es_titular(uuid) IS 'Verdadero si la persona es el usuario actual o un menor bajo su tutela (ámbito propio, RF-144).';

CREATE FUNCTION siglim.club_de_equipo(p_equipo uuid) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$ SELECT club_id FROM equipos WHERE id = p_equipo $$;

CREATE FUNCTION siglim.persona_visible(p_persona uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
  SELECT es_usuario_liga()
      OR es_titular(p_persona)
      OR EXISTS (SELECT 1 FROM registros_jugador r JOIN equipos e ON e.id = r.equipo_id
                 WHERE r.persona_id = p_persona AND e.club_id IN (SELECT clubes_usuario()))
      OR EXISTS (SELECT 1 FROM tutelas t JOIN registros_jugador r ON r.persona_id = t.menor_id
                 JOIN equipos e ON e.id = r.equipo_id
                 WHERE t.tutor_id = p_persona AND e.club_id IN (SELECT clubes_usuario()))
      OR EXISTS (SELECT 1 FROM cargos_directiva c
                 WHERE c.persona_id = p_persona AND c.club_id IN (SELECT clubes_usuario()))
      OR EXISTS (SELECT 1 FROM arbitros a
                 WHERE a.persona_id = p_persona AND a.club_id IN (SELECT clubes_usuario()))
$$;
COMMENT ON FUNCTION siglim.persona_visible(uuid) IS 'Ámbito de datos personales: liga, club (jugadores, tutores, directivos y árbitros del club) o propio (RN-054, RNF-012).';

CREATE FUNCTION siglim.registro_visible(p_registro uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
  SELECT EXISTS (SELECT 1 FROM registros_jugador r JOIN equipos e ON e.id = r.equipo_id
                 WHERE r.id = p_registro AND (club_visible(e.club_id) OR es_titular(r.persona_id)))
$$;

CREATE FUNCTION siglim.expediente_visible(p_expediente uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
  SELECT es_usuario_liga()
      OR EXISTS (SELECT 1 FROM incidencias i
                 JOIN expedientes x ON x.incidencia_id = i.id
                 JOIN incidencia_involucrados v ON v.incidencia_id = i.id
                 WHERE x.id = p_expediente
                   AND ((v.equipo_id IS NOT NULL AND club_de_equipo(v.equipo_id) IN (SELECT clubes_usuario()))
                     OR (v.persona_id IS NOT NULL AND persona_visible(v.persona_id))))
      OR EXISTS (SELECT 1 FROM resoluciones r JOIN sanciones s ON s.resolucion_id = r.id
                 WHERE r.expediente_id = p_expediente
                   AND (s.club_id IN (SELECT clubes_usuario())
                     OR club_de_equipo(s.equipo_id) IN (SELECT clubes_usuario())
                     OR (s.persona_id IS NOT NULL AND persona_visible(s.persona_id))))
$$;

CREATE FUNCTION siglim.cobro_visible(p_cobro uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$ SELECT EXISTS (SELECT 1 FROM cobros c WHERE c.id = p_cobro AND club_visible(c.club_id)) $$;

-- -------------------------------------------------------------------------------------
-- 6. FUNCIONES DE APOYO DEL DOMINIO
-- -------------------------------------------------------------------------------------

CREATE FUNCTION siglim.temporada_de_grupo(p_grupo uuid) RETURNS uuid
LANGUAGE sql STABLE
SET search_path = siglim, pg_temp
AS $$
  SELECT ct.temporada_id FROM grupos g JOIN categorias_temporada ct ON ct.id = g.categoria_temporada_id
  WHERE g.id = p_grupo
$$;

CREATE FUNCTION siglim.categoria_de_equipo(p_equipo uuid) RETURNS uuid
LANGUAGE sql STABLE
SET search_path = siglim, pg_temp
AS $$
  SELECT ct.categoria_id FROM equipos e
  JOIN grupos g ON g.id = e.grupo_id
  JOIN categorias_temporada ct ON ct.id = g.categoria_temporada_id
  WHERE e.id = p_equipo
$$;

CREATE FUNCTION siglim.parametros_vigentes(p_temporada uuid) RETURNS siglim.parametros_temporada
LANGUAGE sql STABLE
SET search_path = siglim, pg_temp
AS $$
  SELECT * FROM parametros_temporada WHERE temporada_id = p_temporada ORDER BY version DESC LIMIT 1
$$;
COMMENT ON FUNCTION siglim.parametros_vigentes(uuid) IS 'Versión vigente (la mayor) de los parámetros de la temporada (RF-006, DP-002).';

CREATE FUNCTION siglim.bloque_cancha(p_temporada uuid, p_categoria uuid) RETURNS interval
LANGUAGE sql STABLE
SET search_path = siglim, pg_temp
AS $$
  SELECT make_interval(mins => coalesce(pc.bloque_cancha_min, p.bloque_cancha_min))
  FROM parametros_vigentes(p_temporada) p
  LEFT JOIN parametros_categoria pc ON pc.parametros_id = p.id AND pc.categoria_id = p_categoria
$$;
COMMENT ON FUNCTION siglim.bloque_cancha(uuid, uuid) IS 'Bloque de cancha de la categoría (120 min [DEMO], DEC-25) usado para detectar choques.';

CREATE FUNCTION siglim.es_menor(p_persona uuid, p_fecha date DEFAULT current_date) RETURNS boolean
LANGUAGE sql STABLE
SET search_path = siglim, pg_temp
AS $$ SELECT fecha_nacimiento > (p_fecha - interval '18 years')::date FROM personas WHERE id = p_persona $$;

CREATE FUNCTION siglim.error_negocio(p_codigo text, p_mensaje text) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = p_codigo || ': ' || p_mensaje, HINT = p_codigo;
END $$;
COMMENT ON FUNCTION siglim.error_negocio(text, text) IS 'Lanza un error de negocio con el código del ERS (VAL-xxx, RN-xxx) en HINT para que el backend lo traduzca a RFC 9457.';

-- -------------------------------------------------------------------------------------
-- 7. TRIGGERS
-- -------------------------------------------------------------------------------------

-- 7.1 Fecha de actualización ----------------------------------------------------------
CREATE FUNCTION siglim.tg_actualizado_en() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$ BEGIN NEW.actualizado_en := now(); RETURN NEW; END $$;

DO $$
DECLARE t text;
BEGIN
  FOR t IN SELECT c.table_name FROM information_schema.columns c
           WHERE c.table_schema = 'siglim' AND c.column_name = 'actualizado_en'
  LOOP
    EXECUTE format('CREATE TRIGGER tg_%s_actualizado_en BEFORE UPDATE ON siglim.%I
                    FOR EACH ROW EXECUTE FUNCTION siglim.tg_actualizado_en()', t, t);
  END LOOP;
END $$;

-- 7.2 Inmutabilidad (auditoría y resoluciones) -----------------------------------------
CREATE FUNCTION siglim.tg_inmutable() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  PERFORM siglim.error_negocio('RNF-015', format('La tabla %s no admite modificaciones ni borrado.', TG_TABLE_NAME));
  RETURN NULL;
END $$;
CREATE TRIGGER tg_auditoria_inmutable BEFORE UPDATE OR DELETE ON siglim.auditoria
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_inmutable();
CREATE TRIGGER tg_resoluciones_inmutable BEFORE UPDATE OR DELETE ON siglim.resoluciones
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_inmutable();

-- 7.3 Temporadas: transiciones CONFIGURACION → ACTIVA → CERRADA --------------------------
CREATE FUNCTION siglim.tg_temporadas_estado() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF NEW.estado IS DISTINCT FROM OLD.estado AND NOT (
       (OLD.estado = 'CONFIGURACION' AND NEW.estado = 'ACTIVA')
    OR (OLD.estado = 'ACTIVA' AND NEW.estado = 'CERRADA')) THEN
    PERFORM siglim.error_negocio('RF-001', format('Transición de temporada no permitida: %s → %s.', OLD.estado, NEW.estado));
  END IF;
  IF NEW.estado = 'ACTIVA' AND OLD.estado = 'CONFIGURACION'
     AND NOT EXISTS (SELECT 1 FROM siglim.parametros_temporada WHERE temporada_id = NEW.id) THEN
    PERFORM siglim.error_negocio('RF-100', 'La temporada necesita parámetros deportivos antes de activarse.');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_temporadas_estado BEFORE UPDATE OF estado ON siglim.temporadas
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_temporadas_estado();

-- 7.4 Parámetros: versión consecutiva ---------------------------------------------------
CREATE FUNCTION siglim.tg_parametros_version() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  SELECT coalesce(max(version), 0) + 1 INTO NEW.version
  FROM siglim.parametros_temporada WHERE temporada_id = NEW.temporada_id;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_parametros_version BEFORE INSERT ON siglim.parametros_temporada
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_parametros_version();
CREATE TRIGGER tg_parametros_inmutable BEFORE UPDATE OR DELETE ON siglim.parametros_temporada
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_inmutable();

-- 7.5 Registro de jugador ---------------------------------------------------------------
CREATE FUNCTION siglim.tg_registros_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_equipo   siglim.equipos%ROWTYPE;
  v_otro     record;
BEGIN
  SELECT * INTO v_equipo FROM siglim.equipos WHERE id = NEW.equipo_id;
  NEW.temporada_id := siglim.temporada_de_grupo(v_equipo.grupo_id);

  IF TG_OP = 'INSERT' THEN
    IF v_equipo.estado <> 'ACTIVO' THEN
      PERFORM siglim.error_negocio('RF-013', 'El equipo está dado de baja y no admite registros.');
    END IF;
    -- VAL-017: CURP con registro activo en la temporada (mensaje explicativo antes del índice único)
    SELECT c.nombre AS club, e.nombre AS equipo INTO v_otro
    FROM siglim.registros_jugador r JOIN siglim.equipos e ON e.id = r.equipo_id JOIN siglim.clubes c ON c.id = e.club_id
    WHERE r.persona_id = NEW.persona_id AND r.temporada_id = NEW.temporada_id
      AND r.estado IN ('PENDIENTE_VALIDACION', 'ACTIVO', 'SUSPENDIDO')
    LIMIT 1;
    IF FOUND THEN
      PERFORM siglim.error_negocio('VAL-017', format('La CURP ya tiene registro en la temporada: club %s, equipo %s.', v_otro.club, v_otro.equipo));
    END IF;
    -- VAL-026 / RN-039: sin cambio de club dentro de la temporada
    IF EXISTS (SELECT 1 FROM siglim.registros_jugador r JOIN siglim.equipos e ON e.id = r.equipo_id
               WHERE r.persona_id = NEW.persona_id AND r.temporada_id = NEW.temporada_id
                 AND r.estado <> 'RECHAZADO' AND e.club_id <> v_equipo.club_id) THEN
      PERFORM siglim.error_negocio('VAL-026', 'No se permite cambiar de club dentro de la misma temporada.');
    END IF;
  ELSIF NEW.equipo_id <> OLD.equipo_id THEN
    PERFORM siglim.error_negocio('RN-039', 'Un registro no cambia de equipo; dé de baja y registre de nuevo si la regla lo permite.');
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.estado IS DISTINCT FROM OLD.estado THEN
    IF NOT ((OLD.estado = 'PENDIENTE_VALIDACION' AND NEW.estado IN ('ACTIVO', 'RECHAZADO'))
         OR (OLD.estado = 'ACTIVO' AND NEW.estado IN ('SUSPENDIDO', 'BAJA'))
         OR (OLD.estado = 'SUSPENDIDO' AND NEW.estado IN ('ACTIVO', 'BAJA'))) THEN
      PERFORM siglim.error_negocio('RF-017', format('Transición de registro no permitida: %s → %s.', OLD.estado, NEW.estado));
    END IF;
    IF siglim.motivo_actual() IS NULL THEN
      PERFORM siglim.error_negocio('RN-021', 'El cambio de estado del registro requiere motivo.');
    END IF;
    -- VAL-025: un menor necesita tutor vigente y consentimiento antes de activarse
    IF NEW.estado = 'ACTIVO' AND OLD.estado = 'PENDIENTE_VALIDACION' AND siglim.es_menor(NEW.persona_id, NEW.alta_en) THEN
      IF NOT EXISTS (SELECT 1 FROM siglim.tutelas t WHERE t.menor_id = NEW.persona_id AND t.vigente)
         OR NOT EXISTS (SELECT 1 FROM siglim.consentimientos c JOIN siglim.tutelas t
                          ON t.menor_id = c.persona_id AND t.tutor_id = c.otorgado_por_id AND t.vigente
                        WHERE c.persona_id = NEW.persona_id AND c.revocado_en IS NULL) THEN
        PERFORM siglim.error_negocio('VAL-025', 'El registro de un menor requiere tutor vigente y su consentimiento.');
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_registros_validar BEFORE INSERT OR UPDATE ON siglim.registros_jugador
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_registros_validar();

CREATE FUNCTION siglim.tg_registros_historial() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.estado IS DISTINCT FROM OLD.estado THEN
    INSERT INTO siglim.registro_estado_historial (registro_id, estado_anterior, estado_nuevo, motivo, cambiado_por)
    VALUES (NEW.id, CASE WHEN TG_OP = 'UPDATE' THEN OLD.estado END, NEW.estado,
            coalesce(siglim.motivo_actual(), 'Alta del registro'), siglim.usuario_actual());
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER tg_registros_historial AFTER INSERT OR UPDATE ON siglim.registros_jugador
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_registros_historial();

-- 7.6 Partido: bloque de cancha, conflictos duros (VAL-003 a VAL-005) --------------------
CREATE FUNCTION siglim.tg_partidos_programacion() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_jornada  siglim.jornadas%ROWTYPE;
  v_temp     uuid;
  v_choque   record;
BEGIN
  SELECT * INTO v_jornada FROM siglim.jornadas WHERE id = NEW.jornada_id;
  v_temp := siglim.temporada_de_grupo(v_jornada.grupo_id);

  IF NOT EXISTS (SELECT 1 FROM siglim.equipos WHERE id = NEW.equipo_local_id AND grupo_id = v_jornada.grupo_id)
     OR NOT EXISTS (SELECT 1 FROM siglim.equipos WHERE id = NEW.equipo_visitante_id AND grupo_id = v_jornada.grupo_id) THEN
    PERFORM siglim.error_negocio('RF-033', 'Ambos equipos deben pertenecer al grupo de la jornada.');
  END IF;

  NEW.fin_bloque := NEW.inicio + siglim.bloque_cancha(v_temp, siglim.categoria_de_equipo(NEW.equipo_local_id));
  IF NEW.fin_bloque IS NULL THEN
    PERFORM siglim.error_negocio('RF-100', 'La temporada no tiene parámetros: no se puede calcular el bloque de cancha.');
  END IF;

  IF NEW.estado = 'CANCELADO' THEN
    RETURN NEW;
  END IF;

  IF EXISTS (SELECT 1 FROM siglim.equipos WHERE id IN (NEW.equipo_local_id, NEW.equipo_visitante_id) AND estado = 'BAJA') THEN
    PERFORM siglim.error_negocio('RF-039', 'Uno de los equipos está dado de baja.');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM siglim.canchas WHERE id = NEW.cancha_id AND activa) THEN
    PERFORM siglim.error_negocio('VAL-005', 'La cancha no está activa.');
  END IF;

  SELECT d.tipo, d.motivo INTO v_choque FROM siglim.disponibilidad_canchas d
  WHERE d.cancha_id = NEW.cancha_id AND d.tipo IN ('BLOQUEO', 'MANTENIMIENTO')
    AND d.periodo && tstzrange(NEW.inicio, NEW.fin_bloque)
  LIMIT 1;
  IF FOUND THEN
    PERFORM siglim.error_negocio('VAL-005', format('La cancha tiene %s en ese horario: %s.', lower(v_choque.tipo::text), v_choque.motivo));
  END IF;

  SELECT e.nombre, p.inicio INTO v_choque FROM siglim.partidos p JOIN siglim.equipos e
    ON e.id IN (p.equipo_local_id, p.equipo_visitante_id)
  WHERE p.id <> NEW.id AND p.estado <> 'CANCELADO'
    AND e.id IN (NEW.equipo_local_id, NEW.equipo_visitante_id)
    AND tstzrange(p.inicio, p.fin_bloque) && tstzrange(NEW.inicio, NEW.fin_bloque)
  LIMIT 1;
  IF FOUND THEN
    PERFORM siglim.error_negocio('VAL-003', format('El equipo %s ya juega en un horario que se traslapa (%s).', v_choque.nombre, to_char(v_choque.inicio AT TIME ZONE 'America/Mexico_City', 'DD/MM/YYYY HH24:MI')));
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_partidos_programacion BEFORE INSERT OR UPDATE OF jornada_id, equipo_local_id, equipo_visitante_id, cancha_id, inicio
  ON siglim.partidos FOR EACH ROW EXECUTE FUNCTION siglim.tg_partidos_programacion();

-- 7.7 Partido: máquina de estados (DEC-23, ERS §4.3.1) y su historial --------------------
CREATE FUNCTION siglim.tg_partidos_estado() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF NEW.estado IS DISTINCT FROM OLD.estado THEN
    IF NOT ((OLD.estado = 'PROGRAMADO' AND NEW.estado IN ('EN_CURSO', 'REPROGRAMADO', 'CANCELADO'))
         OR (OLD.estado = 'EN_CURSO' AND NEW.estado IN ('FINALIZADO', 'SUSPENDIDO'))
         OR (OLD.estado = 'SUSPENDIDO' AND NEW.estado IN ('REPROGRAMADO', 'CANCELADO'))
         OR (OLD.estado = 'REPROGRAMADO' AND NEW.estado = 'EN_CURSO')) THEN
      PERFORM siglim.error_negocio('RF-046', format('Transición de partido no permitida: %s → %s.', OLD.estado, NEW.estado));
    END IF;
    IF siglim.motivo_actual() IS NULL THEN
      PERFORM siglim.error_negocio('RN-021', 'Toda transición del partido requiere motivo.');
    END IF;
    IF NEW.estado = 'FINALIZADO' AND NOT EXISTS (
         SELECT 1 FROM siglim.cedulas WHERE partido_id = NEW.id AND estado = 'APROBADA') THEN
      PERFORM siglim.error_negocio('RF-127', 'El partido solo se finaliza al aprobarse su cédula.');
    END IF;
  ELSIF OLD.estado IN ('FINALIZADO', 'CANCELADO')
        AND (NEW.inicio, NEW.cancha_id, NEW.equipo_local_id, NEW.equipo_visitante_id)
            IS DISTINCT FROM (OLD.inicio, OLD.cancha_id, OLD.equipo_local_id, OLD.equipo_visitante_id) THEN
    PERFORM siglim.error_negocio('RF-046', 'Un partido finalizado o cancelado no se modifica.');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_partidos_estado BEFORE UPDATE ON siglim.partidos
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_partidos_estado();

CREATE FUNCTION siglim.tg_partidos_historial() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.estado IS DISTINCT FROM OLD.estado THEN
    INSERT INTO siglim.partido_estado_historial (partido_id, estado_anterior, estado_nuevo, motivo, cambiado_por)
    VALUES (NEW.id, CASE WHEN TG_OP = 'UPDATE' THEN OLD.estado END, NEW.estado,
            coalesce(siglim.motivo_actual(), 'Programación del partido'), siglim.usuario_actual());
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER tg_partidos_historial AFTER INSERT OR UPDATE ON siglim.partidos
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_partidos_historial();

-- 7.8 Designaciones (RF-115, VAL-019 y choque de horario del árbitro) -------------------
CREATE FUNCTION siglim.tg_designaciones_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_arbitro siglim.arbitros%ROWTYPE;
  v_partido siglim.partidos%ROWTYPE;
BEGIN
  IF NOT NEW.vigente THEN RETURN NEW; END IF;
  SELECT * INTO v_arbitro FROM siglim.arbitros WHERE id = NEW.arbitro_id;
  SELECT * INTO v_partido FROM siglim.partidos WHERE id = NEW.partido_id;
  IF v_arbitro.estado <> 'VALIDADO' THEN
    PERFORM siglim.error_negocio('RF-113', 'Solo se designan árbitros validados.');
  END IF;
  IF v_arbitro.club_id IN (siglim.club_de_equipo(v_partido.equipo_local_id), siglim.club_de_equipo(v_partido.equipo_visitante_id)) THEN
    PERFORM siglim.error_negocio('VAL-019', 'El árbitro pertenece al club de uno de los equipos.');
  END IF;
  IF EXISTS (SELECT 1 FROM siglim.designaciones d JOIN siglim.partidos p ON p.id = d.partido_id
             WHERE d.arbitro_id = NEW.arbitro_id AND d.vigente AND d.id <> NEW.id AND p.id <> NEW.partido_id
               AND p.estado <> 'CANCELADO'
               AND tstzrange(p.inicio, p.fin_bloque) && tstzrange(v_partido.inicio, v_partido.fin_bloque)) THEN
    PERFORM siglim.error_negocio('RF-039', 'El árbitro ya está designado en otro partido en ese horario.');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_designaciones_validar BEFORE INSERT OR UPDATE ON siglim.designaciones
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_designaciones_validar();

-- 7.9 Cédula: máquina de estados (ERS §4.3.2), plazo y separación de funciones -----------
CREATE FUNCTION siglim.tg_cedulas_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_partido siglim.partidos%ROWTYPE;
  v_temp    uuid;
BEGIN
  SELECT * INTO v_partido FROM siglim.partidos WHERE id = NEW.partido_id;
  IF TG_OP = 'INSERT' THEN
    IF v_partido.estado <> 'EN_CURSO' THEN
      PERFORM siglim.error_negocio('RF-046', 'La cédula se captura cuando el partido está en curso.');
    END IF;
    IF NEW.estado <> 'EN_CAPTURA' THEN
      PERFORM siglim.error_negocio('RF-025', 'La cédula inicia en captura.');
    END IF;
    RETURN NEW;
  END IF;

  IF OLD.estado = 'APROBADA' THEN
    PERFORM siglim.error_negocio('RF-048', 'Una cédula aprobada no se modifica; el resultado solo cambia por resolución.');
  END IF;

  IF NEW.estado IS DISTINCT FROM OLD.estado THEN
    IF NOT ((OLD.estado = 'EN_CAPTURA' AND NEW.estado = 'PENDIENTE_VALIDACION')
         OR (OLD.estado = 'PENDIENTE_VALIDACION' AND NEW.estado IN ('APROBADA', 'DEVUELTA'))
         OR (OLD.estado = 'DEVUELTA' AND NEW.estado = 'EN_CAPTURA')) THEN
      PERFORM siglim.error_negocio('RF-123', format('Transición de cédula no permitida: %s → %s.', OLD.estado, NEW.estado));
    END IF;

    IF NEW.estado = 'PENDIENTE_VALIDACION' THEN
      IF NEW.goles_local IS NULL OR NEW.goles_visitante IS NULL
         OR NOT EXISTS (SELECT 1 FROM siglim.alineaciones a WHERE a.cedula_id = NEW.id AND a.equipo_id = v_partido.equipo_local_id)
            AND NEW.no_presentado_equipo_id IS DISTINCT FROM v_partido.equipo_local_id
         OR NOT EXISTS (SELECT 1 FROM siglim.alineaciones a WHERE a.cedula_id = NEW.id AND a.equipo_id = v_partido.equipo_visitante_id)
            AND NEW.no_presentado_equipo_id IS DISTINCT FROM v_partido.equipo_visitante_id THEN
        PERFORM siglim.error_negocio('VAL-020', 'Faltan campos obligatorios: marcador y alineación de los equipos presentes.');
      END IF;
      v_temp := siglim.temporada_de_grupo((SELECT grupo_id FROM siglim.jornadas WHERE id = v_partido.jornada_id));
      NEW.enviada_en := now();
      NEW.plazo_vence_en := now() + (siglim.parametros_vigentes(v_temp)).plazo_validacion_cedula;
      NEW.plazo_vencido := false;
      NEW.devuelta_observaciones := NULL;
    ELSIF NEW.estado = 'DEVUELTA' AND NEW.devuelta_observaciones IS NULL THEN
      PERFORM siglim.error_negocio('RF-123', 'La devolución requiere observaciones.');
    ELSIF NEW.estado = 'APROBADA' THEN
      NEW.aprobada_en := coalesce(NEW.aprobada_en, now());
      IF NEW.aprobada_por = NEW.capturista_id THEN
        PERFORM siglim.error_negocio('VAL-021', 'Quien capturó la cédula no puede aprobarla.');
      END IF;
      IF NEW.aprobada_por_comision THEN
        IF NOT NEW.plazo_vencido THEN
          PERFORM siglim.error_negocio('RF-124', 'La Comisión solo aprueba cédulas con plazo vencido.');
        END IF;
      ELSIF NOT EXISTS (SELECT 1 FROM siglim.designaciones d JOIN siglim.arbitros a ON a.id = d.arbitro_id
                        JOIN siglim.perfiles pf ON pf.persona_id = a.persona_id
                        WHERE d.partido_id = NEW.partido_id AND d.vigente AND d.funcion = 'CENTRAL'
                          AND pf.id = NEW.aprobada_por) THEN
        PERFORM siglim.error_negocio('RF-123', 'Solo el árbitro central designado aprueba la cédula.');
      END IF;
    END IF;
  ELSIF OLD.estado = 'PENDIENTE_VALIDACION'
        AND (NEW.goles_local, NEW.goles_visitante, NEW.penales_local, NEW.penales_visitante, NEW.no_presentado_equipo_id)
            IS DISTINCT FROM (OLD.goles_local, OLD.goles_visitante, OLD.penales_local, OLD.penales_visitante, OLD.no_presentado_equipo_id) THEN
    PERFORM siglim.error_negocio('RF-122', 'La cédula en validación no se edita; debe devolverse a captura.');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_cedulas_validar BEFORE INSERT OR UPDATE ON siglim.cedulas
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_cedulas_validar();

CREATE FUNCTION siglim.tg_cedulas_historial() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.estado IS DISTINCT FROM OLD.estado THEN
    INSERT INTO siglim.cedula_estado_historial (cedula_id, estado_anterior, estado_nuevo, motivo, cambiado_por)
    VALUES (NEW.id, CASE WHEN TG_OP = 'UPDATE' THEN OLD.estado END, NEW.estado,
            coalesce(siglim.motivo_actual(), NEW.devuelta_observaciones), siglim.usuario_actual());
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER tg_cedulas_historial AFTER INSERT OR UPDATE ON siglim.cedulas
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_cedulas_historial();

-- 7.10 Contenido de la cédula solo editable en captura ----------------------------------
CREATE FUNCTION siglim.tg_cedula_en_captura() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_fila   jsonb := to_jsonb(CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END);
  v_cedula uuid;
BEGIN
  IF TG_TABLE_NAME = 'incidencia_involucrados' THEN
    SELECT cedula_id INTO v_cedula FROM siglim.incidencias WHERE id = (v_fila ->> 'incidencia_id')::uuid;
  ELSE
    v_cedula := (v_fila ->> 'cedula_id')::uuid;
  END IF;
  IF (SELECT estado FROM siglim.cedulas WHERE id = v_cedula) <> 'EN_CAPTURA' THEN
    PERFORM siglim.error_negocio('RF-122', 'El contenido de la cédula solo se modifica mientras está en captura.');
  END IF;
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;

-- 7.11 Alineación: elegibilidad (RF-019, RF-020, RF-110, VAL-018) -----------------------
CREATE FUNCTION siglim.tg_alineaciones_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_partido   siglim.partidos%ROWTYPE;
  v_registro  siglim.registros_jugador%ROWTYPE;
  v_temp      uuid;
  v_cat_reg   uuid;
  v_cat_eq    uuid;
BEGIN
  SELECT p.* INTO v_partido FROM siglim.partidos p JOIN siglim.cedulas c ON c.partido_id = p.id WHERE c.id = NEW.cedula_id;
  SELECT * INTO v_registro FROM siglim.registros_jugador WHERE id = NEW.registro_jugador_id;
  v_temp := siglim.temporada_de_grupo((SELECT grupo_id FROM siglim.jornadas WHERE id = v_partido.jornada_id));

  IF NEW.equipo_id NOT IN (v_partido.equipo_local_id, v_partido.equipo_visitante_id) THEN
    PERFORM siglim.error_negocio('RF-025', 'El equipo de la alineación no juega este partido.');
  END IF;
  IF v_registro.estado <> 'ACTIVO' OR v_registro.temporada_id <> v_temp THEN
    PERFORM siglim.error_negocio('RF-019', 'El jugador no tiene registro activo y validado en la temporada.');
  END IF;
  IF EXISTS (SELECT 1 FROM siglim.sanciones s
             WHERE s.persona_id = v_registro.persona_id AND s.estado = 'VIGENTE'
               AND s.tipo IN ('SUSPENSION_PARTIDOS', 'BAJA')) THEN
    PERFORM siglim.error_negocio('RF-020', 'El jugador tiene una sanción vigente que le impide jugar.');
  END IF;

  NEW.categoria_superior := (v_registro.equipo_id <> NEW.equipo_id);
  IF NEW.categoria_superior THEN
    v_cat_reg := siglim.categoria_de_equipo(v_registro.equipo_id);
    v_cat_eq  := siglim.categoria_de_equipo(NEW.equipo_id);
    IF siglim.club_de_equipo(v_registro.equipo_id) <> siglim.club_de_equipo(NEW.equipo_id)
       OR (SELECT categoria_superior_id FROM siglim.categorias WHERE id = v_cat_reg) IS DISTINCT FROM v_cat_eq THEN
      PERFORM siglim.error_negocio('VAL-018', 'Solo puede alinearse en la categoría inmediata superior de su mismo club.');
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_alineaciones_validar BEFORE INSERT OR UPDATE ON siglim.alineaciones
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_alineaciones_validar();
CREATE TRIGGER tg_alineaciones_en_captura BEFORE INSERT OR UPDATE OR DELETE ON siglim.alineaciones
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_cedula_en_captura();
CREATE TRIGGER tg_eventos_en_captura BEFORE INSERT OR UPDATE OR DELETE ON siglim.eventos_cedula
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_cedula_en_captura();
CREATE TRIGGER tg_incidencias_en_captura BEFORE INSERT OR UPDATE OR DELETE ON siglim.incidencias
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_cedula_en_captura();
CREATE TRIGGER tg_involucrados_en_captura BEFORE INSERT OR UPDATE OR DELETE ON siglim.incidencia_involucrados
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_cedula_en_captura();

-- 7.12 Resultados versionados (RF-048, RF-052, RN-024) ----------------------------------
CREATE FUNCTION siglim.tg_resultados_version() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF NEW.origen = 'CEDULA' AND NOT EXISTS (
       SELECT 1 FROM siglim.cedulas WHERE id = NEW.cedula_id AND partido_id = NEW.partido_id AND estado = 'APROBADA') THEN
    PERFORM siglim.error_negocio('RF-048', 'El resultado oficial por cédula requiere una cédula aprobada del partido.');
  END IF;
  SELECT coalesce(max(version), 0) + 1 INTO NEW.version FROM siglim.resultados WHERE partido_id = NEW.partido_id;
  UPDATE siglim.resultados SET vigente = false WHERE partido_id = NEW.partido_id AND vigente;
  NEW.vigente := true;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_resultados_version BEFORE INSERT ON siglim.resultados
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_resultados_version();

CREATE FUNCTION siglim.tg_resultados_inmutable() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF TG_OP = 'DELETE' OR (to_jsonb(NEW) - 'vigente') IS DISTINCT FROM (to_jsonb(OLD) - 'vigente')
     OR (NEW.vigente AND NOT OLD.vigente) THEN
    PERFORM siglim.error_negocio('RN-024', 'Un resultado oficial no se modifica: se registra una versión nueva.');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_resultados_inmutable BEFORE UPDATE OR DELETE ON siglim.resultados
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_resultados_inmutable();

-- 7.13 Expedientes (ERS §4.3.4) ---------------------------------------------------------
CREATE FUNCTION siglim.tg_expedientes_estado() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.estado IS DISTINCT FROM OLD.estado THEN
    IF NOT ((OLD.estado = 'ABIERTO' AND NEW.estado = 'EN_REVISION')
         OR (OLD.estado = 'EN_REVISION' AND NEW.estado = 'RESUELTO')
         OR (OLD.estado = 'RESUELTO' AND NEW.estado IN ('EN_RECURSO', 'CERRADO'))
         OR (OLD.estado = 'EN_RECURSO' AND NEW.estado = 'CERRADO')) THEN
      PERFORM siglim.error_negocio('RF-062', format('Transición de expediente no permitida: %s → %s.', OLD.estado, NEW.estado));
    END IF;
    IF NEW.estado = 'RESUELTO' AND NOT EXISTS (SELECT 1 FROM siglim.resoluciones WHERE expediente_id = NEW.id) THEN
      PERFORM siglim.error_negocio('RF-062', 'El expediente se resuelve con una resolución registrada.');
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_expedientes_estado BEFORE UPDATE ON siglim.expedientes
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_expedientes_estado();

CREATE FUNCTION siglim.tg_expedientes_historial() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.estado IS DISTINCT FROM OLD.estado THEN
    INSERT INTO siglim.expediente_estado_historial (expediente_id, estado_anterior, estado_nuevo, motivo, cambiado_por)
    VALUES (NEW.id, CASE WHEN TG_OP = 'UPDATE' THEN OLD.estado END, NEW.estado, siglim.motivo_actual(), siglim.usuario_actual());
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER tg_expedientes_historial AFTER INSERT OR UPDATE ON siglim.expedientes
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_expedientes_historial();

-- 7.14 Cobros (ERS §4.3.5, VAL-028) -----------------------------------------------------
CREATE FUNCTION siglim.tg_cobros_estado() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF NEW.estado IS DISTINCT FROM OLD.estado AND NOT (
       (OLD.estado = 'PENDIENTE' AND NEW.estado IN ('PAGADO', 'RECHAZADO', 'VENCIDO'))
    OR (OLD.estado = 'RECHAZADO' AND NEW.estado = 'PENDIENTE')
    OR (OLD.estado = 'VENCIDO' AND NEW.estado = 'PAGADO')) THEN
    PERFORM siglim.error_negocio('VAL-028', format('El cobro está %s y no admite pasar a %s.', OLD.estado, NEW.estado));
  END IF;
  IF OLD.estado = 'PAGADO' AND (NEW.monto, NEW.club_id) IS DISTINCT FROM (OLD.monto, OLD.club_id) THEN
    PERFORM siglim.error_negocio('VAL-028', 'Un cobro pagado no se modifica.');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_cobros_estado BEFORE UPDATE ON siglim.cobros
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_cobros_estado();

CREATE FUNCTION siglim.tg_pagos_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE v_cobro siglim.cobros%ROWTYPE;
BEGIN
  SELECT * INTO v_cobro FROM siglim.cobros WHERE id = NEW.cobro_id FOR UPDATE;
  IF v_cobro.estado = 'PAGADO' OR (NEW.medio = 'EN_LINEA_SIMULADO' AND v_cobro.estado <> 'PENDIENTE') THEN
    PERFORM siglim.error_negocio('VAL-028', format('El cobro está %s; no se puede pagar.', v_cobro.estado));
  END IF;
  IF NEW.monto <> v_cobro.monto THEN
    PERFORM siglim.error_negocio('RF-139', 'El pago debe cubrir el monto total del cobro.');
  END IF;
  UPDATE siglim.cobros SET estado = 'PAGADO' WHERE id = NEW.cobro_id;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_pagos_validar BEFORE INSERT ON siglim.pagos
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_pagos_validar();

-- 7.15 Publicación de jornadas y comunicados (ERS §4.3.6) --------------------------------
CREATE FUNCTION siglim.tg_publicacion_estado() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_entidad siglim.entidad_publicable := CASE TG_TABLE_NAME WHEN 'jornadas' THEN 'JORNADA' ELSE 'COMUNICADO' END;
BEGIN
  IF NEW.estado_publicacion IS DISTINCT FROM OLD.estado_publicacion THEN
    IF NOT ((OLD.estado_publicacion = 'BORRADOR' AND NEW.estado_publicacion = 'REVISION')
         OR (OLD.estado_publicacion = 'REVISION' AND NEW.estado_publicacion IN ('PUBLICADO', 'BORRADOR'))) THEN
      PERFORM siglim.error_negocio('RF-090', format('Transición de publicación no permitida: %s → %s.', OLD.estado_publicacion, NEW.estado_publicacion));
    END IF;
    IF OLD.estado_publicacion = 'REVISION' AND NEW.estado_publicacion = 'BORRADOR' AND siglim.motivo_actual() IS NULL THEN
      PERFORM siglim.error_negocio('RF-121', 'La devolución requiere observaciones.');
    END IF;
    IF NEW.estado_publicacion = 'PUBLICADO' THEN
      IF TG_TABLE_NAME = 'jornadas' THEN
        IF NEW.aprobada_por IS NULL THEN
          PERFORM siglim.error_negocio('RF-121', 'La jornada se publica con la aprobación del Presidente.');
        END IF;
        NEW.publicada_en := now();
      ELSE
        IF NEW.aprobado_por IS NULL THEN
          PERFORM siglim.error_negocio('RF-090', 'El comunicado se publica con la aprobación del Presidente.');
        END IF;
        NEW.publicado_en := now();
      END IF;
    END IF;
    INSERT INTO siglim.historial_publicacion (entidad, entidad_id, estado_anterior, estado_nuevo, motivo, cambiado_por)
    VALUES (v_entidad, NEW.id, OLD.estado_publicacion, NEW.estado_publicacion, siglim.motivo_actual(), siglim.usuario_actual());
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_jornadas_publicacion BEFORE UPDATE OF estado_publicacion ON siglim.jornadas
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_publicacion_estado();
CREATE TRIGGER tg_comunicados_publicacion BEFORE UPDATE OF estado_publicacion ON siglim.comunicados
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_publicacion_estado();

-- 7.16 Control dual: el administrador no modifica los permisos de su propio rol (VAL-022) --
CREATE FUNCTION siglim.tg_rol_permisos_propio() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE v_rol uuid := CASE WHEN TG_OP = 'DELETE' THEN OLD.rol_id ELSE NEW.rol_id END;
BEGIN
  IF EXISTS (SELECT 1 FROM siglim.asignaciones_rol
             WHERE perfil_id = siglim.usuario_actual() AND rol_id = v_rol AND activa) THEN
    PERFORM siglim.error_negocio('VAL-022', 'No puede modificar los permisos de un rol que usted tiene asignado.');
  END IF;
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;
CREATE TRIGGER tg_rol_permisos_propio BEFORE INSERT OR UPDATE OR DELETE ON siglim.rol_permisos
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_rol_permisos_propio();

-- 7.17 Documentos: el reemplazo nunca borra el anterior ---------------------------------
CREATE FUNCTION siglim.tg_documentos_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
BEGIN
  IF (NEW.s3_bucket, NEW.s3_clave, NEW.url, NEW.sha256, NEW.tamano_bytes)
     IS DISTINCT FROM (OLD.s3_bucket, OLD.s3_clave, OLD.url, OLD.sha256, OLD.tamano_bytes) THEN
    PERFORM siglim.error_negocio('RNF-018', 'El archivo de un documento no cambia; cargue un documento nuevo que lo reemplace.');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER tg_documentos_validar BEFORE UPDATE ON siglim.documentos
  FOR EACH ROW EXECUTE FUNCTION siglim.tg_documentos_validar();

COMMENT ON FUNCTION siglim.es_usuario_liga() IS 'Verdadero si el usuario actual tiene una asignación activa con ámbito LIGA.';
COMMENT ON FUNCTION siglim.clubes_usuario() IS 'Clubes de las asignaciones activas con ámbito CLUB del usuario actual.';
COMMENT ON FUNCTION siglim.club_visible(uuid) IS 'Verdadero si el club está en el ámbito del usuario (liga o su club).';
COMMENT ON FUNCTION siglim.persona_usuario() IS 'Persona asociada al perfil del usuario actual.';
COMMENT ON FUNCTION siglim.club_de_equipo(uuid) IS 'Club propietario del equipo.';
COMMENT ON FUNCTION siglim.registro_visible(uuid) IS 'Verdadero si el registro de jugador está en el ámbito del usuario.';
COMMENT ON FUNCTION siglim.expediente_visible(uuid) IS 'Verdadero si el expediente involucra al ámbito del usuario (liga, club o propio).';
COMMENT ON FUNCTION siglim.cobro_visible(uuid) IS 'Verdadero si el cobro pertenece a un club del ámbito del usuario.';
COMMENT ON FUNCTION siglim.temporada_de_grupo(uuid) IS 'Temporada a la que pertenece el grupo.';
COMMENT ON FUNCTION siglim.categoria_de_equipo(uuid) IS 'Categoría del catálogo en que juega el equipo.';
COMMENT ON FUNCTION siglim.es_menor(uuid, date) IS 'Verdadero si la persona tiene menos de 18 años en la fecha indicada (RN-055).';

-- -------------------------------------------------------------------------------------
-- 8. TABLA DE POSICIONES CALCULADA (RF-049, RF-050, RF-053, RN-022; DEC-26, DEC-27)
--    Nunca se guarda: se calcula a partir de los resultados oficiales vigentes de la fase
--    regular y de la versión vigente de los parámetros. El nombre del equipo nunca decide
--    una posición: los equipos empatados en todos los criterios comparten posición.
-- -------------------------------------------------------------------------------------

CREATE FUNCTION siglim.calcular_tabla(p_grupo uuid)
RETURNS TABLE (
  posicion     integer,
  equipo_id    uuid,
  equipo       varchar,
  pj           integer,
  pg           integer,
  pe           integer,
  pp           integer,
  gf           integer,
  gc           integer,
  dg           integer,
  puntos       integer,
  expulsiones  integer
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_par       parametros_temporada;
  v_criterio  criterio_desempate;
  v_base      jsonb;          -- {equipo_id: {equipo, pj, pg, pe, pp, gf, gc, puntos, expulsiones, sorteo}}
  v_clave     jsonb;          -- {equipo_id: clave de ordenamiento}
  v_empate    record;
  v_h2h       record;
BEGIN
  v_par := parametros_vigentes(temporada_de_grupo(p_grupo));
  IF v_par.id IS NULL THEN
    RETURN;
  END IF;

  -- 1. Estadística base: partidos FINALIZADO de la fase regular con resultado oficial vigente
  WITH partidos_grupo AS (
    SELECT p.equipo_local_id AS loc, p.equipo_visitante_id AS vis, r.goles_local AS gl, r.goles_visitante AS gv
    FROM partidos p
    JOIN jornadas j ON j.id = p.jornada_id AND j.grupo_id = p_grupo AND j.fase_id IS NULL
    JOIN resultados r ON r.partido_id = p.id AND r.vigente
    WHERE p.estado = 'FINALIZADO'
  ), por_equipo AS (
    SELECT loc AS eq, gl AS a_favor, gv AS en_contra FROM partidos_grupo
    UNION ALL
    SELECT vis, gv, gl FROM partidos_grupo
  ), base AS (
    SELECT e.id, e.nombre,
           count(x.eq)::int AS pj,
           count(*) FILTER (WHERE x.a_favor > x.en_contra)::int AS pg,
           count(*) FILTER (WHERE x.a_favor = x.en_contra)::int AS pe,
           count(*) FILTER (WHERE x.a_favor < x.en_contra)::int AS pp,
           coalesce(sum(x.a_favor), 0)::int AS gf,
           coalesce(sum(x.en_contra), 0)::int AS gc
    FROM equipos e LEFT JOIN por_equipo x ON x.eq = e.id
    WHERE e.grupo_id = p_grupo
    GROUP BY e.id, e.nombre
  )
  SELECT jsonb_object_agg(b.id::text, jsonb_build_object(
           'equipo', b.nombre, 'pj', b.pj, 'pg', b.pg, 'pe', b.pe, 'pp', b.pp, 'gf', b.gf, 'gc', b.gc,
           'puntos', b.pg * v_par.puntos_victoria + b.pe * v_par.puntos_empate + b.pp * v_par.puntos_derrota
                     - coalesce((SELECT sum(s.puntos) FROM sanciones s
                                 WHERE s.equipo_id = b.id AND s.tipo = 'PERDIDA_PUNTOS' AND s.estado <> 'REVOCADA'), 0),
           'expulsiones', (SELECT count(*) FROM eventos_cedula ev
                           JOIN cedulas c ON c.id = ev.cedula_id AND c.estado = 'APROBADA'
                           JOIN partidos p ON p.id = c.partido_id
                           JOIN jornadas j ON j.id = p.jornada_id AND j.grupo_id = p_grupo AND j.fase_id IS NULL
                           WHERE ev.equipo_id = b.id AND ev.tipo = 'TARJETA_ROJA'),
           'sorteo', coalesce((SELECT 1000 - s.orden FROM sorteos_desempate s WHERE s.grupo_id = p_grupo AND s.equipo_id = b.id), 0)))
  INTO v_base FROM base b;

  IF v_base IS NULL THEN
    RETURN;
  END IF;
  SELECT jsonb_object_agg(k, '') INTO v_clave FROM jsonb_object_keys(v_base) AS k;

  -- 2. Clave de ordenamiento: un segmento de 7 dígitos por criterio, en el orden configurado
  FOREACH v_criterio IN ARRAY v_par.criterios_desempate LOOP
    IF v_criterio = 'ENFRENTAMIENTO_DIRECTO' THEN
      -- Puntos obtenidos solo entre los equipos que siguen empatados hasta este criterio
      FOR v_empate IN
        SELECT array_agg(c.k::uuid) AS equipos FROM jsonb_each_text(v_clave) AS c(k, v) GROUP BY c.v HAVING count(*) > 1
      LOOP
        FOR v_h2h IN
          SELECT e AS id, coalesce(sum(x.pts), 0)::int AS pts FROM unnest(v_empate.equipos) AS e
          LEFT JOIN LATERAL (
            SELECT CASE
                     WHEN (p.equipo_local_id = e AND r.goles_local > r.goles_visitante)
                       OR (p.equipo_visitante_id = e AND r.goles_visitante > r.goles_local) THEN v_par.puntos_victoria
                     WHEN r.goles_local = r.goles_visitante THEN v_par.puntos_empate
                     ELSE v_par.puntos_derrota END AS pts
            FROM partidos p
            JOIN jornadas j ON j.id = p.jornada_id AND j.grupo_id = p_grupo AND j.fase_id IS NULL
            JOIN resultados r ON r.partido_id = p.id AND r.vigente
            WHERE p.estado = 'FINALIZADO'
              AND e IN (p.equipo_local_id, p.equipo_visitante_id)
              AND p.equipo_local_id = ANY (v_empate.equipos)
              AND p.equipo_visitante_id = ANY (v_empate.equipos)
          ) x ON true
          GROUP BY e
        LOOP
          v_clave := jsonb_set(v_clave, ARRAY[v_h2h.id::text],
                       to_jsonb((v_clave ->> v_h2h.id::text) || lpad((1000000 + v_h2h.pts)::text, 7, '0')));
        END LOOP;
      END LOOP;
      -- Los equipos sin empate reciben un segmento neutro para conservar la longitud de la clave
      SELECT jsonb_object_agg(t.k, CASE WHEN length(t.v) < t.largo THEN t.v || '1000000' ELSE t.v END) INTO v_clave
      FROM (SELECT c.k, c.v, max(length(c.v)) OVER () AS largo FROM jsonb_each_text(v_clave) AS c(k, v)) t;
    ELSE
      SELECT jsonb_object_agg(b.k, (v_clave ->> b.k) || lpad((1000000 +
               CASE v_criterio
                 WHEN 'PUNTOS'             THEN (b.d ->> 'puntos')::int
                 WHEN 'DIFERENCIA_GOLES'   THEN (b.d ->> 'gf')::int - (b.d ->> 'gc')::int
                 WHEN 'GOLES_FAVOR'        THEN (b.d ->> 'gf')::int
                 WHEN 'MENOS_GOLES_CONTRA' THEN -(b.d ->> 'gc')::int
                 WHEN 'PARTIDOS_GANADOS'   THEN (b.d ->> 'pg')::int
                 WHEN 'MENOS_EXPULSIONES'  THEN -(b.d ->> 'expulsiones')::int
                 WHEN 'SORTEO'             THEN (b.d ->> 'sorteo')::int
               END)::text, 7, '0'))
      INTO v_clave FROM jsonb_each(v_base) AS b(k, d);
    END IF;
  END LOOP;

  -- 3. Posición: empates totales comparten posición (rank); el nombre solo ordena la presentación
  RETURN QUERY
  SELECT (rank() OVER (ORDER BY c.v DESC))::int, b.k::uuid, (b.d ->> 'equipo')::varchar,
         (b.d ->> 'pj')::int, (b.d ->> 'pg')::int, (b.d ->> 'pe')::int, (b.d ->> 'pp')::int,
         (b.d ->> 'gf')::int, (b.d ->> 'gc')::int, (b.d ->> 'gf')::int - (b.d ->> 'gc')::int,
         (b.d ->> 'puntos')::int, (b.d ->> 'expulsiones')::int
  FROM jsonb_each(v_base) AS b(k, d) JOIN jsonb_each_text(v_clave) AS c(k, v) ON c.k = b.k
  ORDER BY 1, 3;
END $$;
COMMENT ON FUNCTION siglim.calcular_tabla(uuid) IS 'Tabla de posiciones del grupo (fase regular) con puntos y desempates de la versión vigente de parámetros. Empate total = misma posición.';

-- -------------------------------------------------------------------------------------
-- 9. VISTAS DEL PORTAL PÚBLICO (DP-006, RF-056, RF-082 a RF-088, RNF-012)
--    Solo datos publicados y sin datos personales; las lee el rol siglim_publico.
-- -------------------------------------------------------------------------------------

CREATE VIEW siglim.v_publica_programacion AS
SELECT p.id AS partido_id, t.liga_id, t.id AS temporada_id, t.nombre AS temporada,
       cat.id AS categoria_id, cat.nombre AS categoria, g.id AS grupo_id, g.nombre AS grupo,
       j.id AS jornada_id, j.numero AS jornada, (j.fase_id IS NOT NULL) AS es_fase_final,
       p.inicio, el.id AS equipo_local_id, el.nombre AS equipo_local,
       ev.id AS equipo_visitante_id, ev.nombre AS equipo_visitante,
       ca.nombre AS cancha, s.nombre AS sede, p.estado
FROM siglim.partidos p
JOIN siglim.jornadas j ON j.id = p.jornada_id AND j.estado_publicacion = 'PUBLICADO'
JOIN siglim.grupos g ON g.id = j.grupo_id
JOIN siglim.categorias_temporada ct ON ct.id = g.categoria_temporada_id
JOIN siglim.categorias cat ON cat.id = ct.categoria_id
JOIN siglim.temporadas t ON t.id = ct.temporada_id
JOIN siglim.equipos el ON el.id = p.equipo_local_id
JOIN siglim.equipos ev ON ev.id = p.equipo_visitante_id
JOIN siglim.canchas ca ON ca.id = p.cancha_id
LEFT JOIN siglim.sedes s ON s.id = ca.sede_id;
COMMENT ON VIEW siglim.v_publica_programacion IS 'M-11 · Programación de jornadas PUBLICADAS (RF-082, RF-085, RF-089).';

CREATE VIEW siglim.v_publica_resultados AS
SELECT p.id AS partido_id, t.liga_id, t.id AS temporada_id, cat.id AS categoria_id, cat.nombre AS categoria,
       g.id AS grupo_id, g.nombre AS grupo, j.numero AS jornada, (j.fase_id IS NOT NULL) AS es_fase_final,
       p.inicio, el.id AS equipo_local_id, el.nombre AS equipo_local,
       ev.id AS equipo_visitante_id, ev.nombre AS equipo_visitante,
       r.goles_local, r.goles_visitante, r.penales_local, r.penales_visitante,
       r.por_default, r.version AS version_resultado, r.origen, r.registrado_en AS oficial_desde
FROM siglim.resultados r
JOIN siglim.partidos p ON p.id = r.partido_id AND p.estado = 'FINALIZADO'
JOIN siglim.jornadas j ON j.id = p.jornada_id
JOIN siglim.grupos g ON g.id = j.grupo_id
JOIN siglim.categorias_temporada ct ON ct.id = g.categoria_temporada_id
JOIN siglim.categorias cat ON cat.id = ct.categoria_id
JOIN siglim.temporadas t ON t.id = ct.temporada_id
JOIN siglim.equipos el ON el.id = p.equipo_local_id
JOIN siglim.equipos ev ON ev.id = p.equipo_visitante_id
WHERE r.vigente;
COMMENT ON VIEW siglim.v_publica_resultados IS 'M-11 · Resultados oficiales vigentes; se publican al aprobarse la cédula (RF-083, RF-125, DEC-21).';

CREATE VIEW siglim.v_publica_comunicados AS
SELECT c.id AS comunicado_id, c.liga_id, c.titulo, c.cuerpo, c.publicado_en
FROM siglim.comunicados c
WHERE c.estado_publicacion = 'PUBLICADO';
COMMENT ON VIEW siglim.v_publica_comunicados IS 'M-11 · Comunicados aprobados por el Presidente (RF-086, P-09).';

CREATE VIEW siglim.v_publica_equipos AS
SELECT e.id AS equipo_id, t.liga_id, t.id AS temporada_id, t.nombre AS temporada, cat.id AS categoria_id,
       cat.nombre AS categoria, g.id AS grupo_id, g.nombre AS grupo, e.nombre AS equipo,
       cl.nombre AS club, e.estado
FROM siglim.equipos e
JOIN siglim.clubes cl ON cl.id = e.club_id
JOIN siglim.grupos g ON g.id = e.grupo_id
JOIN siglim.categorias_temporada ct ON ct.id = g.categoria_temporada_id
JOIN siglim.categorias cat ON cat.id = ct.categoria_id
JOIN siglim.temporadas t ON t.id = ct.temporada_id
WHERE t.estado <> 'CONFIGURACION';
COMMENT ON VIEW siglim.v_publica_equipos IS 'M-11 · Equipos de temporadas activas o cerradas (RF-088).';

CREATE VIEW siglim.v_publica_sanciones AS
SELECT s.id AS sancion_id, t.liga_id, s.temporada_id, s.tipo, s.sujeto, s.partidos, s.vigente_desde, s.vigente_hasta,
       CASE s.sujeto
         WHEN 'EQUIPO' THEN e.nombre
         WHEN 'CLUB'   THEN cl.nombre
         ELSE CASE WHEN EXISTS (SELECT 1 FROM siglim.consentimientos k
                                WHERE k.persona_id = s.persona_id AND k.revocado_en IS NULL
                                  AND 'DIFUSION' = ANY (k.finalidades))
                   THEN pe.nombre || ' ' || pe.apellido_paterno
                   ELSE 'Jugador (dato reservado)' END
       END AS sancionado,
       a.numero AS articulo, s.publicada_en
FROM siglim.sanciones s
JOIN siglim.temporadas t ON t.id = s.temporada_id
JOIN siglim.resoluciones r ON r.id = s.resolucion_id
LEFT JOIN siglim.articulos a ON a.id = r.articulo_id
LEFT JOIN siglim.equipos e ON e.id = s.equipo_id
LEFT JOIN siglim.clubes cl ON cl.id = s.club_id
LEFT JOIN siglim.personas pe ON pe.id = s.persona_id
WHERE s.publicada_en IS NOT NULL AND s.estado = 'VIGENTE';
COMMENT ON VIEW siglim.v_publica_sanciones IS 'M-11 · Sanciones vigentes autorizadas para difusión; el nombre del jugador solo con consentimiento de la finalidad DIFUSION (RF-068, RF-087, RF-145).';

-- -------------------------------------------------------------------------------------
-- 10. SEGURIDAD A NIVEL DE FILA (ADR-0007, ADR-0014)
--     RLS evalúa el ÁMBITO (liga, club, propio); los permisos finos los evalúa el backend.
--     Todas las tablas tienen RLS. Las de datos personales o de ámbito de club tienen
--     políticas específicas; el resto permite al rol siglim_app operar sin restricción de fila.
--     Las inserciones se permiten (las autoriza el backend) y las lecturas y cambios se acotan.
-- -------------------------------------------------------------------------------------

DO $$
DECLARE t text;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'siglim' LOOP
    EXECUTE format('ALTER TABLE siglim.%I ENABLE ROW LEVEL SECURITY', t);
    IF t NOT IN ('personas', 'perfiles', 'tutelas', 'consentimientos', 'solicitudes_arco', 'documentos',
                 'registros_jugador', 'registro_estado_historial', 'cobros', 'intentos_pago', 'pagos',
                 'expedientes', 'expediente_estado_historial', 'sanciones', 'notificaciones',
                 'correos_salientes', 'auditoria') THEN
      EXECUTE format('CREATE POLICY app_sin_restriccion ON siglim.%I TO siglim_app USING (true) WITH CHECK (true)', t);
    END IF;
  END LOOP;
END $$;

-- Personas y tutela ---------------------------------------------------------------------
CREATE POLICY personas_leer ON siglim.personas FOR SELECT TO siglim_app
  USING (siglim.persona_visible(id) OR creado_por = siglim.usuario_actual());
CREATE POLICY personas_crear ON siglim.personas FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY personas_editar ON siglim.personas FOR UPDATE TO siglim_app
  USING (siglim.persona_visible(id) OR creado_por = siglim.usuario_actual());

CREATE POLICY perfiles_leer ON siglim.perfiles FOR SELECT TO siglim_app
  USING (id = siglim.usuario_actual() OR siglim.es_usuario_liga());
CREATE POLICY perfiles_crear ON siglim.perfiles FOR INSERT TO siglim_app WITH CHECK (siglim.es_usuario_liga());
CREATE POLICY perfiles_editar ON siglim.perfiles FOR UPDATE TO siglim_app
  USING (id = siglim.usuario_actual() OR siglim.es_usuario_liga());

CREATE POLICY tutelas_leer ON siglim.tutelas FOR SELECT TO siglim_app
  USING (siglim.persona_visible(menor_id) OR creado_por = siglim.usuario_actual());
CREATE POLICY tutelas_crear ON siglim.tutelas FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY tutelas_editar ON siglim.tutelas FOR UPDATE TO siglim_app USING (siglim.persona_visible(menor_id));

CREATE POLICY consentimientos_leer ON siglim.consentimientos FOR SELECT TO siglim_app
  USING (siglim.persona_visible(persona_id) OR registrado_por = siglim.usuario_actual());
CREATE POLICY consentimientos_crear ON siglim.consentimientos FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY consentimientos_editar ON siglim.consentimientos FOR UPDATE TO siglim_app
  USING (siglim.persona_visible(persona_id));

CREATE POLICY arco_leer ON siglim.solicitudes_arco FOR SELECT TO siglim_app
  USING (siglim.es_usuario_liga() OR siglim.es_titular(persona_id));
CREATE POLICY arco_crear ON siglim.solicitudes_arco FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY arco_editar ON siglim.solicitudes_arco FOR UPDATE TO siglim_app USING (siglim.es_usuario_liga());

-- Registros y documentos ----------------------------------------------------------------
CREATE POLICY registros_leer ON siglim.registros_jugador FOR SELECT TO siglim_app
  USING (siglim.club_visible(siglim.club_de_equipo(equipo_id)) OR siglim.es_titular(persona_id));
CREATE POLICY registros_crear ON siglim.registros_jugador FOR INSERT TO siglim_app
  WITH CHECK (siglim.club_visible(siglim.club_de_equipo(equipo_id)));
CREATE POLICY registros_editar ON siglim.registros_jugador FOR UPDATE TO siglim_app
  USING (siglim.club_visible(siglim.club_de_equipo(equipo_id)))
  WITH CHECK (siglim.club_visible(siglim.club_de_equipo(equipo_id)));

CREATE POLICY registro_historial_leer ON siglim.registro_estado_historial FOR SELECT TO siglim_app
  USING (siglim.registro_visible(registro_id));
CREATE POLICY registro_historial_crear ON siglim.registro_estado_historial FOR INSERT TO siglim_app WITH CHECK (true);

CREATE POLICY documentos_leer ON siglim.documentos FOR SELECT TO siglim_app
  USING (cargado_por = siglim.usuario_actual()
      OR (registro_id IS NOT NULL AND siglim.registro_visible(registro_id))
      OR (persona_id IS NOT NULL AND siglim.persona_visible(persona_id))
      OR (afiliacion_id IS NOT NULL AND siglim.club_visible((SELECT club_id FROM siglim.afiliaciones WHERE id = afiliacion_id)))
      OR (expediente_id IS NOT NULL AND siglim.expediente_visible(expediente_id))
      OR (pago_id IS NOT NULL AND siglim.cobro_visible((SELECT cobro_id FROM siglim.pagos WHERE id = pago_id))));
CREATE POLICY documentos_crear ON siglim.documentos FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY documentos_editar ON siglim.documentos FOR UPDATE TO siglim_app
  USING (siglim.es_usuario_liga() OR cargado_por = siglim.usuario_actual());

-- Tesorería -----------------------------------------------------------------------------
CREATE POLICY cobros_leer ON siglim.cobros FOR SELECT TO siglim_app USING (siglim.club_visible(club_id));
CREATE POLICY cobros_crear ON siglim.cobros FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY cobros_editar ON siglim.cobros FOR UPDATE TO siglim_app
  USING (siglim.club_visible(club_id)) WITH CHECK (siglim.club_visible(club_id));

CREATE POLICY intentos_leer ON siglim.intentos_pago FOR SELECT TO siglim_app USING (siglim.cobro_visible(cobro_id));
CREATE POLICY intentos_crear ON siglim.intentos_pago FOR INSERT TO siglim_app WITH CHECK (siglim.cobro_visible(cobro_id));
CREATE POLICY intentos_editar ON siglim.intentos_pago FOR UPDATE TO siglim_app USING (siglim.cobro_visible(cobro_id));

CREATE POLICY pagos_leer ON siglim.pagos FOR SELECT TO siglim_app USING (siglim.cobro_visible(cobro_id));
CREATE POLICY pagos_crear ON siglim.pagos FOR INSERT TO siglim_app WITH CHECK (siglim.cobro_visible(cobro_id));

-- Disciplina ----------------------------------------------------------------------------
CREATE POLICY expedientes_leer ON siglim.expedientes FOR SELECT TO siglim_app USING (siglim.expediente_visible(id));
CREATE POLICY expedientes_crear ON siglim.expedientes FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY expedientes_editar ON siglim.expedientes FOR UPDATE TO siglim_app USING (siglim.es_usuario_liga());

CREATE POLICY expediente_historial_leer ON siglim.expediente_estado_historial FOR SELECT TO siglim_app
  USING (siglim.expediente_visible(expediente_id));
CREATE POLICY expediente_historial_crear ON siglim.expediente_estado_historial FOR INSERT TO siglim_app WITH CHECK (true);

CREATE POLICY sanciones_leer ON siglim.sanciones FOR SELECT TO siglim_app
  USING (siglim.es_usuario_liga()
      OR club_id IN (SELECT siglim.clubes_usuario())
      OR siglim.club_de_equipo(equipo_id) IN (SELECT siglim.clubes_usuario())
      OR (persona_id IS NOT NULL AND siglim.persona_visible(persona_id)));
CREATE POLICY sanciones_crear ON siglim.sanciones FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY sanciones_editar ON siglim.sanciones FOR UPDATE TO siglim_app USING (siglim.es_usuario_liga());

-- Notificaciones, correo y auditoría ----------------------------------------------------
CREATE POLICY notificaciones_leer ON siglim.notificaciones FOR SELECT TO siglim_app
  USING (perfil_id = siglim.usuario_actual());
CREATE POLICY notificaciones_crear ON siglim.notificaciones FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY notificaciones_editar ON siglim.notificaciones FOR UPDATE TO siglim_app
  USING (perfil_id = siglim.usuario_actual());

CREATE POLICY correos_leer ON siglim.correos_salientes FOR SELECT TO siglim_app USING (siglim.es_usuario_liga());
CREATE POLICY correos_crear ON siglim.correos_salientes FOR INSERT TO siglim_app WITH CHECK (true);
CREATE POLICY correos_editar ON siglim.correos_salientes FOR UPDATE TO siglim_app USING (siglim.es_usuario_liga());

CREATE POLICY auditoria_leer ON siglim.auditoria FOR SELECT TO siglim_app USING (siglim.es_usuario_liga());
CREATE POLICY auditoria_crear ON siglim.auditoria FOR INSERT TO siglim_app WITH CHECK (true);

-- -------------------------------------------------------------------------------------
-- 11. PRIVILEGIOS
--     Sin DELETE en tablas con historial; auditoría, historiales, parámetros y resoluciones
--     solo admiten INSERT; del resultado solo puede cambiar la marca «vigente».
-- -------------------------------------------------------------------------------------
GRANT USAGE ON SCHEMA siglim TO siglim_app, siglim_publico;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA siglim TO siglim_app;
REVOKE UPDATE ON siglim.auditoria, siglim.resoluciones, siglim.parametros_temporada, siglim.resultados,
                 siglim.partido_estado_historial, siglim.cedula_estado_historial, siglim.registro_estado_historial,
                 siglim.expediente_estado_historial, siglim.historial_publicacion, siglim.tabla_historial
  FROM siglim_app;
GRANT UPDATE (vigente) ON siglim.resultados TO siglim_app;
GRANT DELETE ON siglim.rol_permisos, siglim.pares_incompatibles, siglim.parametros_categoria,
                siglim.afiliacion_categorias, siglim.requisitos_documento, siglim.disponibilidad_canchas,
                siglim.disponibilidad_arbitral, siglim.horarios_cancha_club, siglim.alineaciones,
                siglim.eventos_cedula, siglim.incidencias, siglim.incidencia_involucrados, siglim.sorteos_desempate
  TO siglim_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA siglim TO siglim_app;

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA siglim FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA siglim TO siglim_app;

GRANT SELECT ON siglim.v_publica_programacion, siglim.v_publica_resultados, siglim.v_publica_comunicados,
                siglim.v_publica_equipos, siglim.v_publica_sanciones TO siglim_publico, siglim_app;
GRANT EXECUTE ON FUNCTION siglim.calcular_tabla(uuid) TO siglim_publico;

-- Migraciones futuras: los objetos nuevos heredan los mismos privilegios básicos
ALTER DEFAULT PRIVILEGES IN SCHEMA siglim GRANT SELECT, INSERT, UPDATE ON TABLES TO siglim_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA siglim GRANT USAGE, SELECT ON SEQUENCES TO siglim_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA siglim REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA siglim GRANT EXECUTE ON FUNCTIONS TO siglim_app;

-- -------------------------------------------------------------------------------------
-- 14. DESCRIPCIÓN DE COLUMNAS (se muestra en el editor de tablas de Supabase)
-- -------------------------------------------------------------------------------------
COMMENT ON COLUMN siglim.afiliacion_categorias.afiliacion_id IS 'Afiliación (tarjetón).';
COMMENT ON COLUMN siglim.afiliacion_categorias.categoria_id IS 'Categoría del catálogo.';
COMMENT ON COLUMN siglim.afiliaciones.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.afiliaciones.club_id IS 'Club.';
COMMENT ON COLUMN siglim.afiliaciones.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.afiliaciones.folio IS 'Folio del tarjetón, único por temporada (DEC-09).';
COMMENT ON COLUMN siglim.afiliaciones.colores_uniforme IS 'Colores del uniforme declarados en el tarjetón.';
COMMENT ON COLUMN siglim.afiliaciones.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.afiliaciones.capturada_por IS 'Perfil que capturó.';
COMMENT ON COLUMN siglim.afiliaciones.capturada_en IS 'Fecha y hora de captura.';
COMMENT ON COLUMN siglim.afiliaciones.resuelta_por IS 'Perfil que resolvió.';
COMMENT ON COLUMN siglim.afiliaciones.resuelta_en IS 'Fecha y hora de resolución.';
COMMENT ON COLUMN siglim.afiliaciones.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.alineaciones.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.alineaciones.cedula_id IS 'Cédula del partido.';
COMMENT ON COLUMN siglim.alineaciones.registro_jugador_id IS 'Registro activo del jugador en la temporada.';
COMMENT ON COLUMN siglim.alineaciones.equipo_id IS 'Equipo con el que juega este partido.';
COMMENT ON COLUMN siglim.alineaciones.numero_playera IS 'Número de playera.';
COMMENT ON COLUMN siglim.alineaciones.titular IS 'Verdadero si inicia el partido.';
COMMENT ON COLUMN siglim.alineaciones.categoria_superior IS 'Juega con el equipo de la categoría inmediata superior de su club (lo fija un trigger).';
COMMENT ON COLUMN siglim.arbitros.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.arbitros.persona_id IS 'Persona que actúa como árbitro.';
COMMENT ON COLUMN siglim.arbitros.club_id IS 'Club que presenta al árbitro (RF-112).';
COMMENT ON COLUMN siglim.arbitros.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.arbitros.propuesto_por IS 'Perfil que propuso.';
COMMENT ON COLUMN siglim.arbitros.propuesto_en IS 'Fecha y hora de propuesta.';
COMMENT ON COLUMN siglim.arbitros.validado_por IS 'Perfil que validó.';
COMMENT ON COLUMN siglim.arbitros.validado_en IS 'Fecha y hora de validación.';
COMMENT ON COLUMN siglim.arbitros.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.articulos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.articulos.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.articulos.numero IS 'Número del artículo del reglamento.';
COMMENT ON COLUMN siglim.articulos.descripcion IS 'Descripción.';
COMMENT ON COLUMN siglim.articulos.tipo_sancion IS 'Tipo de sanción (DEC-30).';
COMMENT ON COLUMN siglim.articulos.sujeto IS 'A quién aplica: jugador, equipo o club.';
COMMENT ON COLUMN siglim.articulos.efecto IS 'Hacia adelante o retroactivo (RF-131).';
COMMENT ON COLUMN siglim.articulos.aplicacion_automatica IS 'Se aplica sin resolución (DEC-31).';
COMMENT ON COLUMN siglim.articulos.partidos_suspension IS 'Partidos de suspensión.';
COMMENT ON COLUMN siglim.articulos.puntos IS 'Puntos que se restan en la tabla.';
COMMENT ON COLUMN siglim.articulos.monto_multa IS 'Monto de la multa que genera un cobro (RF-133).';
COMMENT ON COLUMN siglim.articulos.otorga_default_restantes IS 'En una baja, otorga por default al rival los partidos pendientes (DEC-32).';
COMMENT ON COLUMN siglim.articulos.activo IS 'Indica si está activo.';
COMMENT ON COLUMN siglim.articulos.es_demo IS 'Valor de demostración [DEMO]: configurable y rotulado «no oficial» en la interfaz.';
COMMENT ON COLUMN siglim.asignaciones_rol.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.asignaciones_rol.perfil_id IS 'Perfil de usuario.';
COMMENT ON COLUMN siglim.asignaciones_rol.rol_id IS 'Rol.';
COMMENT ON COLUMN siglim.asignaciones_rol.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.asignaciones_rol.ambito IS 'Ámbito de la asignación: LIGA, CLUB o PROPIO (RN-054).';
COMMENT ON COLUMN siglim.asignaciones_rol.club_id IS 'Club de la asignación; obligatorio solo con ámbito CLUB.';
COMMENT ON COLUMN siglim.asignaciones_rol.activa IS 'Las asignaciones no se borran: se desactivan.';
COMMENT ON COLUMN siglim.asignaciones_rol.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.asignaciones_rol.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.asignaciones_rol.revocada_en IS 'Fecha y hora en que se desactivó.';
COMMENT ON COLUMN siglim.auditoria.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.auditoria.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.auditoria.perfil_id IS 'Perfil que ejecutó la acción.';
COMMENT ON COLUMN siglim.auditoria.ocurrido_en IS 'Fecha y hora de la acción.';
COMMENT ON COLUMN siglim.auditoria.modulo IS 'Módulo del ERS donde ocurrió la acción.';
COMMENT ON COLUMN siglim.auditoria.accion IS 'Acción realizada (por ejemplo APROBAR_CEDULA).';
COMMENT ON COLUMN siglim.auditoria.entidad IS 'Tabla o recurso afectado.';
COMMENT ON COLUMN siglim.auditoria.entidad_id IS 'Identificador del registro afectado.';
COMMENT ON COLUMN siglim.auditoria.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.auditoria.detalle IS 'Datos adicionales en JSON, sin datos personales.';
COMMENT ON COLUMN siglim.avisos_privacidad.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.avisos_privacidad.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.avisos_privacidad.tipo IS 'Aviso integral o simplificado (LFPDPPP).';
COMMENT ON COLUMN siglim.avisos_privacidad.version IS 'Versión.';
COMMENT ON COLUMN siglim.avisos_privacidad.contenido IS 'Texto del aviso aprobado por la Liga.';
COMMENT ON COLUMN siglim.avisos_privacidad.finalidades IS 'Finalidades que el titular puede aceptar por separado.';
COMMENT ON COLUMN siglim.avisos_privacidad.vigente_desde IS 'Fecha desde la que se usa esta versión.';
COMMENT ON COLUMN siglim.avisos_privacidad.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.canchas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.canchas.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.canchas.sede_id IS 'Sede o unidad deportiva.';
COMMENT ON COLUMN siglim.canchas.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.canchas.ubicacion IS 'Unidad deportiva o externa.';
COMMENT ON COLUMN siglim.canchas.direccion IS 'Domicilio o ubicación descriptiva.';
COMMENT ON COLUMN siglim.canchas.propietario IS 'Liga, club o externo (DEC-33).';
COMMENT ON COLUMN siglim.canchas.club_id IS 'Club propietario cuando el propietario es CLUB.';
COMMENT ON COLUMN siglim.canchas.propietario_externo IS 'Nombre del dueño cuando es EXTERNO.';
COMMENT ON COLUMN siglim.canchas.caracteristicas IS 'Características conocidas (superficie, medidas, iluminación).';
COMMENT ON COLUMN siglim.canchas.activa IS 'Indica si está activa.';
COMMENT ON COLUMN siglim.canchas.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.cargos_directiva.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.cargos_directiva.club_id IS 'Club.';
COMMENT ON COLUMN siglim.cargos_directiva.persona_id IS 'Persona.';
COMMENT ON COLUMN siglim.cargos_directiva.cargo IS 'Presidente, secretario, tesorero o delegado del club.';
COMMENT ON COLUMN siglim.cargos_directiva.desde IS 'Inicio del cargo.';
COMMENT ON COLUMN siglim.cargos_directiva.hasta IS 'Fin del cargo; nulo si está vigente.';
COMMENT ON COLUMN siglim.cargos_directiva.autorizado_por IS 'Perfil que autorizó el cambio de directiva.';
COMMENT ON COLUMN siglim.cargos_directiva.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.categorias.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.categorias.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.categorias.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.categorias.tipo IS 'Tipo de categoría que define los documentos exigidos (DEC-10).';
COMMENT ON COLUMN siglim.categorias.orden IS 'Posición en el catálogo (configurable).';
COMMENT ON COLUMN siglim.categorias.categoria_superior_id IS 'Categoría inmediata superior para alinear jugadores (RF-110, DEC-12).';
COMMENT ON COLUMN siglim.categorias.activa IS 'Indica si está activa.';
COMMENT ON COLUMN siglim.categorias.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.categorias_temporada.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.categorias_temporada.temporada_id IS 'Temporada en que participa la categoría.';
COMMENT ON COLUMN siglim.categorias_temporada.categoria_id IS 'Categoría del catálogo.';
COMMENT ON COLUMN siglim.cedula_estado_historial.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.cedula_estado_historial.cedula_id IS 'Cédula del partido.';
COMMENT ON COLUMN siglim.cedula_estado_historial.estado_anterior IS 'Estado antes del cambio (nulo en la creación).';
COMMENT ON COLUMN siglim.cedula_estado_historial.estado_nuevo IS 'Estado después del cambio.';
COMMENT ON COLUMN siglim.cedula_estado_historial.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.cedula_estado_historial.cambiado_por IS 'Perfil que hizo el cambio (usuario Sistema en procesos automáticos).';
COMMENT ON COLUMN siglim.cedula_estado_historial.cambiado_en IS 'Fecha y hora del cambio.';
COMMENT ON COLUMN siglim.cedulas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.cedulas.partido_id IS 'Partido.';
COMMENT ON COLUMN siglim.cedulas.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.cedulas.capturista_id IS 'Perfil que captura la cédula; no puede aprobarla (VAL-021).';
COMMENT ON COLUMN siglim.cedulas.goles_local IS 'Goles del local según la cédula.';
COMMENT ON COLUMN siglim.cedulas.goles_visitante IS 'Goles del visitante según la cédula.';
COMMENT ON COLUMN siglim.cedulas.penales_local IS 'Penales anotados por el local en tanda de desempate (liguilla).';
COMMENT ON COLUMN siglim.cedulas.penales_visitante IS 'Penales anotados por el visitante en tanda de desempate.';
COMMENT ON COLUMN siglim.cedulas.no_presentado_equipo_id IS 'Equipo que no se presentó; el marcador es el de default (RF-126).';
COMMENT ON COLUMN siglim.cedulas.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.cedulas.enviada_en IS 'Fecha y hora del envío a validación.';
COMMENT ON COLUMN siglim.cedulas.plazo_vence_en IS 'Vencimiento del plazo del árbitro (envío + plazo de la temporada).';
COMMENT ON COLUMN siglim.cedulas.plazo_vencido IS 'Lo marca la tarea programada; habilita a la Comisión de Arbitraje (RF-124).';
COMMENT ON COLUMN siglim.cedulas.devuelta_observaciones IS 'Observaciones del árbitro al devolver la cédula.';
COMMENT ON COLUMN siglim.cedulas.aprobada_por IS 'Árbitro central designado o integrante de la Comisión de Arbitraje.';
COMMENT ON COLUMN siglim.cedulas.aprobada_en IS 'Fecha y hora de aprobación.';
COMMENT ON COLUMN siglim.cedulas.aprobada_por_comision IS 'Verdadero si la aprobó la Comisión por plazo vencido.';
COMMENT ON COLUMN siglim.cedulas.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.cedulas.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.clubes.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.clubes.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.clubes.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.clubes.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.clubes.club_anterior_id IS 'Club cerrado del que proviene por cambio de nombre (DEC-15).';
COMMENT ON COLUMN siglim.clubes.cerrado_en IS 'Fecha de cierre del club.';
COMMENT ON COLUMN siglim.clubes.motivo_cierre IS 'Motivo del cierre (por ejemplo, cambio de nombre).';
COMMENT ON COLUMN siglim.clubes.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.clubes.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.cobros.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.cobros.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.cobros.club_id IS 'Club.';
COMMENT ON COLUMN siglim.cobros.equipo_id IS 'Equipo al que se carga, si el cobro es por equipo.';
COMMENT ON COLUMN siglim.cobros.tipo IS 'Arbitraje, cancha, multa o manual.';
COMMENT ON COLUMN siglim.cobros.concepto IS 'Concepto que ve el club.';
COMMENT ON COLUMN siglim.cobros.monto IS 'Importe en pesos mexicanos.';
COMMENT ON COLUMN siglim.cobros.periodo_inicio IS 'Inicio del periodo de pago.';
COMMENT ON COLUMN siglim.cobros.fecha_limite IS 'Último día para pagar; después la tarea lo vence (RF-141).';
COMMENT ON COLUMN siglim.cobros.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.cobros.partido_id IS 'Partido que generó el cobro automático (RF-136).';
COMMENT ON COLUMN siglim.cobros.sancion_id IS 'Sanción de multa que generó el cobro (RF-133).';
COMMENT ON COLUMN siglim.cobros.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.cobros.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.cobros.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.comunicados.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.comunicados.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.comunicados.titulo IS 'Título.';
COMMENT ON COLUMN siglim.comunicados.cuerpo IS 'Texto completo.';
COMMENT ON COLUMN siglim.comunicados.estado_publicacion IS 'Borrador, revisión o publicado (ERS §4.3.6).';
COMMENT ON COLUMN siglim.comunicados.redactado_por IS 'Secretario que redactó el comunicado.';
COMMENT ON COLUMN siglim.comunicados.aprobado_por IS 'Presidente que aprobó; distinto de quien redactó.';
COMMENT ON COLUMN siglim.comunicados.aprobado_en IS 'Fecha y hora de aprobación.';
COMMENT ON COLUMN siglim.comunicados.publicado_en IS 'Fecha y hora de publicación.';
COMMENT ON COLUMN siglim.comunicados.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.comunicados.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.comunicados.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.consentimientos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.consentimientos.persona_id IS 'Titular de los datos.';
COMMENT ON COLUMN siglim.consentimientos.otorgado_por_id IS 'Quien otorga: el propio titular o, si es menor, su tutor.';
COMMENT ON COLUMN siglim.consentimientos.aviso_id IS 'Versión del aviso de privacidad aceptada.';
COMMENT ON COLUMN siglim.consentimientos.finalidades IS 'Finalidades aceptadas (DIFUSION habilita mostrar el nombre en el portal).';
COMMENT ON COLUMN siglim.consentimientos.otorgado_en IS 'Fecha y hora de otorgamiento.';
COMMENT ON COLUMN siglim.consentimientos.revocado_en IS 'Fecha y hora de revocación.';
COMMENT ON COLUMN siglim.consentimientos.registrado_por IS 'Perfil que registró el consentimiento.';
COMMENT ON COLUMN siglim.convocatorias.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.convocatorias.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.convocatorias.referencia IS 'Referencia o título de la convocatoria.';
COMMENT ON COLUMN siglim.convocatorias.version IS 'Versión.';
COMMENT ON COLUMN siglim.convocatorias.documento_url IS 'Enlace al documento de la convocatoria.';
COMMENT ON COLUMN siglim.convocatorias.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.correos_salientes.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.correos_salientes.notificacion_id IS 'Aviso que originó el correo.';
COMMENT ON COLUMN siglim.correos_salientes.destinatario IS 'Correo del destinatario.';
COMMENT ON COLUMN siglim.correos_salientes.asunto IS 'Asunto del correo.';
COMMENT ON COLUMN siglim.correos_salientes.cuerpo IS 'Texto completo.';
COMMENT ON COLUMN siglim.correos_salientes.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.correos_salientes.intentos IS 'Intentos de envío realizados (máximo 5).';
COMMENT ON COLUMN siglim.correos_salientes.proximo_intento_en IS 'Fecha y hora del siguiente intento.';
COMMENT ON COLUMN siglim.correos_salientes.ultimo_error IS 'Último error del proveedor SMTP.';
COMMENT ON COLUMN siglim.correos_salientes.enviado_en IS 'Fecha y hora de envío.';
COMMENT ON COLUMN siglim.correos_salientes.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.designaciones.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.designaciones.partido_id IS 'Partido.';
COMMENT ON COLUMN siglim.designaciones.arbitro_id IS 'Árbitro.';
COMMENT ON COLUMN siglim.designaciones.funcion IS 'Central o asistente; un solo central vigente por partido.';
COMMENT ON COLUMN siglim.designaciones.vigente IS 'Indica si es la versión o relación vigente.';
COMMENT ON COLUMN siglim.designaciones.designado_por IS 'Perfil que designó.';
COMMENT ON COLUMN siglim.designaciones.designado_en IS 'Fecha y hora de designación.';
COMMENT ON COLUMN siglim.designaciones.motivo_cambio IS 'Motivo al sustituir una designación.';
COMMENT ON COLUMN siglim.disponibilidad_arbitral.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.disponibilidad_arbitral.arbitro_id IS 'Árbitro.';
COMMENT ON COLUMN siglim.disponibilidad_arbitral.periodo IS 'Intervalo de fecha y hora (tstzrange).';
COMMENT ON COLUMN siglim.disponibilidad_arbitral.disponible IS 'Verdadero si está disponible en el periodo; falso si no.';
COMMENT ON COLUMN siglim.disponibilidad_arbitral.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.disponibilidad_canchas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.disponibilidad_canchas.cancha_id IS 'Cancha.';
COMMENT ON COLUMN siglim.disponibilidad_canchas.tipo IS 'Disponible, bloqueo o mantenimiento; los dos últimos impiden programar (VAL-005).';
COMMENT ON COLUMN siglim.disponibilidad_canchas.periodo IS 'Intervalo de fecha y hora (tstzrange).';
COMMENT ON COLUMN siglim.disponibilidad_canchas.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.disponibilidad_canchas.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.disponibilidad_canchas.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.documentos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.documentos.tipo_documento_id IS 'Tipo de documento.';
COMMENT ON COLUMN siglim.documentos.registro_id IS 'Registro de jugador al que pertenece (exactamente un dueño por documento).';
COMMENT ON COLUMN siglim.documentos.persona_id IS 'Persona dueña del documento (por ejemplo, INE del tutor).';
COMMENT ON COLUMN siglim.documentos.afiliacion_id IS 'Afiliación (tarjetón firmado).';
COMMENT ON COLUMN siglim.documentos.expediente_id IS 'Expediente (evidencia disciplinaria).';
COMMENT ON COLUMN siglim.documentos.pago_id IS 'Pago (comprobante).';
COMMENT ON COLUMN siglim.documentos.s3_bucket IS 'Bucket privado de AWS S3 (ADR-0013).';
COMMENT ON COLUMN siglim.documentos.s3_clave IS 'Clave del objeto en S3; sin nombres ni CURP.';
COMMENT ON COLUMN siglim.documentos.url IS 'URL del objeto en S3 (no pública: se lee con una URL prefirmada de 60 s).';
COMMENT ON COLUMN siglim.documentos.tipo_mime IS 'Tipo verificado por la firma binaria del archivo.';
COMMENT ON COLUMN siglim.documentos.tamano_bytes IS 'Tamaño del archivo (máximo 5 MB [PROPUESTA]).';
COMMENT ON COLUMN siglim.documentos.sha256 IS 'Huella SHA-256 para verificar integridad.';
COMMENT ON COLUMN siglim.documentos.estado_validacion IS 'Pendiente, aprobado o rechazado por el Secretario (RF-109).';
COMMENT ON COLUMN siglim.documentos.validado_por IS 'Perfil que validó.';
COMMENT ON COLUMN siglim.documentos.validado_en IS 'Fecha y hora de validación.';
COMMENT ON COLUMN siglim.documentos.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.documentos.reemplazado_por_id IS 'Documento nuevo que lo reemplaza (el anterior se conserva).';
COMMENT ON COLUMN siglim.documentos.cargado_por IS 'Perfil que cargó.';
COMMENT ON COLUMN siglim.documentos.cargado_en IS 'Fecha y hora de carga.';
COMMENT ON COLUMN siglim.equipos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.equipos.club_id IS 'Club.';
COMMENT ON COLUMN siglim.equipos.grupo_id IS 'Grupo de la categoría en la temporada.';
COMMENT ON COLUMN siglim.equipos.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.equipos.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.equipos.equipo_anterior_id IS 'Equipo de la temporada anterior que conserva la plaza (RF-104).';
COMMENT ON COLUMN siglim.equipos.baja_en IS 'Fecha de baja del equipo.';
COMMENT ON COLUMN siglim.equipos.motivo_baja IS 'Motivo de la baja (por ejemplo, artículo aplicado).';
COMMENT ON COLUMN siglim.equipos.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.equipos.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.eventos_cedula.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.eventos_cedula.cedula_id IS 'Cédula del partido.';
COMMENT ON COLUMN siglim.eventos_cedula.tipo IS 'Gol, autogol, tarjeta amarilla, tarjeta roja o sustitución.';
COMMENT ON COLUMN siglim.eventos_cedula.minuto IS 'Minuto de juego.';
COMMENT ON COLUMN siglim.eventos_cedula.equipo_id IS 'Equipo al que se atribuye el evento.';
COMMENT ON COLUMN siglim.eventos_cedula.alineacion_id IS 'Jugador del evento (en sustitución, el que sale).';
COMMENT ON COLUMN siglim.eventos_cedula.alineacion_entra_id IS 'Jugador que entra (solo en sustitución).';
COMMENT ON COLUMN siglim.eventos_cedula.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.expediente_estado_historial.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.expediente_estado_historial.expediente_id IS 'Expediente disciplinario.';
COMMENT ON COLUMN siglim.expediente_estado_historial.estado_anterior IS 'Estado antes del cambio (nulo en la creación).';
COMMENT ON COLUMN siglim.expediente_estado_historial.estado_nuevo IS 'Estado después del cambio.';
COMMENT ON COLUMN siglim.expediente_estado_historial.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.expediente_estado_historial.cambiado_por IS 'Perfil que hizo el cambio (usuario Sistema en procesos automáticos).';
COMMENT ON COLUMN siglim.expediente_estado_historial.cambiado_en IS 'Fecha y hora del cambio.';
COMMENT ON COLUMN siglim.expedientes.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.expedientes.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.expedientes.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.expedientes.folio IS 'Folio del expediente, único por liga.';
COMMENT ON COLUMN siglim.expedientes.origen IS 'Incidencia de cédula, artículo automático o apertura manual.';
COMMENT ON COLUMN siglim.expedientes.incidencia_id IS 'Incidencia de la cédula.';
COMMENT ON COLUMN siglim.expedientes.articulo_id IS 'Artículo automático que lo originó, si aplica.';
COMMENT ON COLUMN siglim.expedientes.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.expedientes.descripcion IS 'Descripción.';
COMMENT ON COLUMN siglim.expedientes.abierto_por IS 'Perfil que abrió.';
COMMENT ON COLUMN siglim.expedientes.abierto_en IS 'Fecha y hora de apertura.';
COMMENT ON COLUMN siglim.expedientes.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.fases.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.fases.grupo_id IS 'Grupo de la categoría en la temporada.';
COMMENT ON COLUMN siglim.fases.tipo IS 'Tipo de fase final.';
COMMENT ON COLUMN siglim.fases.parametros_id IS 'Versión de parámetros de la temporada usada.';
COMMENT ON COLUMN siglim.fases.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.fases.campeon_id IS 'Equipo campeón (RF-081).';
COMMENT ON COLUMN siglim.fases.subcampeon_id IS 'Equipo subcampeón (RF-081).';
COMMENT ON COLUMN siglim.fases.configurada_por IS 'Perfil que configuró.';
COMMENT ON COLUMN siglim.fases.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.grupos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.grupos.categoria_temporada_id IS 'Categoría de la temporada a la que pertenece el grupo.';
COMMENT ON COLUMN siglim.grupos.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.historial_publicacion.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.historial_publicacion.entidad IS 'Jornada o comunicado.';
COMMENT ON COLUMN siglim.historial_publicacion.entidad_id IS 'Identificador de la jornada o el comunicado.';
COMMENT ON COLUMN siglim.historial_publicacion.estado_anterior IS 'Estado antes del cambio (nulo en la creación).';
COMMENT ON COLUMN siglim.historial_publicacion.estado_nuevo IS 'Estado después del cambio.';
COMMENT ON COLUMN siglim.historial_publicacion.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.historial_publicacion.cambiado_por IS 'Perfil que hizo el cambio (usuario Sistema en procesos automáticos).';
COMMENT ON COLUMN siglim.historial_publicacion.cambiado_en IS 'Fecha y hora del cambio.';
COMMENT ON COLUMN siglim.horarios_cancha_club.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.horarios_cancha_club.cancha_id IS 'Cancha.';
COMMENT ON COLUMN siglim.horarios_cancha_club.club_id IS 'Club.';
COMMENT ON COLUMN siglim.horarios_cancha_club.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.horarios_cancha_club.categoria_id IS 'Categoría del catálogo.';
COMMENT ON COLUMN siglim.horarios_cancha_club.dia_semana IS 'Día de la semana (1 = lunes … 7 = domingo).';
COMMENT ON COLUMN siglim.horarios_cancha_club.hora_inicio IS 'Hora de inicio del horario ofrecido.';
COMMENT ON COLUMN siglim.horarios_cancha_club.hora_fin IS 'Hora de fin del horario ofrecido.';
COMMENT ON COLUMN siglim.horarios_cancha_club.es_comodato IS 'Verdadero si la cancha está en comodato del club por la temporada.';
COMMENT ON COLUMN siglim.incidencia_involucrados.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.incidencia_involucrados.incidencia_id IS 'Incidencia de la cédula.';
COMMENT ON COLUMN siglim.incidencia_involucrados.persona_id IS 'Persona involucrada.';
COMMENT ON COLUMN siglim.incidencia_involucrados.equipo_id IS 'Equipo involucrado.';
COMMENT ON COLUMN siglim.incidencias.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.incidencias.cedula_id IS 'Cédula del partido.';
COMMENT ON COLUMN siglim.incidencias.tipo_incidencia_id IS 'Tipo de incidencia.';
COMMENT ON COLUMN siglim.incidencias.minuto IS 'Minuto de juego.';
COMMENT ON COLUMN siglim.incidencias.descripcion IS 'Descripción de los hechos.';
COMMENT ON COLUMN siglim.intentos_pago.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.intentos_pago.cobro_id IS 'Cobro.';
COMMENT ON COLUMN siglim.intentos_pago.referencia IS 'Referencia ficticia SIM-AAAAMMDD-XXXXXX (ADR-0012).';
COMMENT ON COLUMN siglim.intentos_pago.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.intentos_pago.iniciado_por IS 'Perfil que inició.';
COMMENT ON COLUMN siglim.intentos_pago.iniciado_en IS 'Fecha y hora de inicio.';
COMMENT ON COLUMN siglim.intentos_pago.resuelto_en IS 'Fecha y hora de resolución.';
COMMENT ON COLUMN siglim.interpretaciones_regla.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.interpretaciones_regla.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.interpretaciones_regla.descripcion IS 'Descripción.';
COMMENT ON COLUMN siglim.interpretaciones_regla.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.interpretaciones_regla.registrada_por IS 'Perfil que registró.';
COMMENT ON COLUMN siglim.interpretaciones_regla.registrada_en IS 'Fecha y hora de registro.';
COMMENT ON COLUMN siglim.interpretaciones_regla.resuelta_por IS 'Perfil que resolvió.';
COMMENT ON COLUMN siglim.interpretaciones_regla.resuelta_en IS 'Fecha y hora de resolución.';
COMMENT ON COLUMN siglim.interpretaciones_regla.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.jornadas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.jornadas.grupo_id IS 'Grupo de la categoría en la temporada.';
COMMENT ON COLUMN siglim.jornadas.fase_id IS 'Fase final (liguilla); nulo en la fase regular.';
COMMENT ON COLUMN siglim.jornadas.numero IS 'Número de la jornada en el grupo o en la fase.';
COMMENT ON COLUMN siglim.jornadas.estado_publicacion IS 'Borrador, revisión o publicado (ERS §4.3.6).';
COMMENT ON COLUMN siglim.jornadas.enviada_por IS 'Programador que envió a aprobación.';
COMMENT ON COLUMN siglim.jornadas.enviada_en IS 'Fecha y hora del envío a aprobación del Presidente.';
COMMENT ON COLUMN siglim.jornadas.aprobada_por IS 'Presidente que aprobó la publicación.';
COMMENT ON COLUMN siglim.jornadas.aprobada_en IS 'Fecha y hora de aprobación.';
COMMENT ON COLUMN siglim.jornadas.publicada_en IS 'Fecha y hora de publicación (la fija un trigger).';
COMMENT ON COLUMN siglim.jornadas.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.jornadas.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.jornadas.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.jornadas.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.ligas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.ligas.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.ligas.nombre_corto IS 'Siglas de la liga.';
COMMENT ON COLUMN siglim.ligas.activa IS 'Indica si está activa.';
COMMENT ON COLUMN siglim.ligas.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.llaves.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.llaves.fase_id IS 'Fase final (liguilla); nulo en la fase regular.';
COMMENT ON COLUMN siglim.llaves.ronda IS 'Ronda de eliminación (1 = primera ronda).';
COMMENT ON COLUMN siglim.llaves.orden IS 'Posición de la llave dentro de la ronda.';
COMMENT ON COLUMN siglim.llaves.equipo_a_id IS 'Primer equipo de la llave.';
COMMENT ON COLUMN siglim.llaves.equipo_b_id IS 'Segundo equipo de la llave.';
COMMENT ON COLUMN siglim.llaves.ganador_id IS 'Equipo que avanza.';
COMMENT ON COLUMN siglim.llaves.siguiente_llave_id IS 'Llave a la que avanza el ganador.';
COMMENT ON COLUMN siglim.notificaciones.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.notificaciones.perfil_id IS 'Perfil de usuario.';
COMMENT ON COLUMN siglim.notificaciones.evento IS 'Evento de dominio que originó el aviso (por ejemplo CEDULA_APROBADA).';
COMMENT ON COLUMN siglim.notificaciones.titulo IS 'Título.';
COMMENT ON COLUMN siglim.notificaciones.cuerpo IS 'Texto completo.';
COMMENT ON COLUMN siglim.notificaciones.enlace IS 'Ruta de la pantalla relacionada en la aplicación.';
COMMENT ON COLUMN siglim.notificaciones.creada_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.notificaciones.leida_en IS 'Fecha y hora de lectura.';
COMMENT ON COLUMN siglim.operaciones_equipo.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.operaciones_equipo.tipo IS 'Venta del equipo o conservación de la plaza (operaciones independientes, DEC-14).';
COMMENT ON COLUMN siglim.operaciones_equipo.equipo_id IS 'Equipo.';
COMMENT ON COLUMN siglim.operaciones_equipo.club_origen_id IS 'Club propietario al solicitar.';
COMMENT ON COLUMN siglim.operaciones_equipo.club_destino_id IS 'Club comprador (solo en venta).';
COMMENT ON COLUMN siglim.operaciones_equipo.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.operaciones_equipo.solicitada_por IS 'Perfil que solicitó.';
COMMENT ON COLUMN siglim.operaciones_equipo.solicitada_en IS 'Fecha y hora de solicitud.';
COMMENT ON COLUMN siglim.operaciones_equipo.autorizada_por IS 'Perfil que autorizó.';
COMMENT ON COLUMN siglim.operaciones_equipo.autorizada_en IS 'Fecha y hora de autorización.';
COMMENT ON COLUMN siglim.operaciones_equipo.aplicada_en IS 'Fecha y hora en que se aplicó al cierre de la temporada.';
COMMENT ON COLUMN siglim.operaciones_equipo.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.pagos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.pagos.cobro_id IS 'Cobro.';
COMMENT ON COLUMN siglim.pagos.intento_id IS 'Intento de pago simulado que originó el pago.';
COMMENT ON COLUMN siglim.pagos.medio IS 'En línea simulado, efectivo, transferencia u otro.';
COMMENT ON COLUMN siglim.pagos.monto IS 'Importe pagado; igual al del cobro.';
COMMENT ON COLUMN siglim.pagos.referencia IS 'Referencia del pago o del comprobante.';
COMMENT ON COLUMN siglim.pagos.pagado_en IS 'Fecha y hora del pago.';
COMMENT ON COLUMN siglim.pagos.registrado_por IS 'Perfil que registró.';
COMMENT ON COLUMN siglim.parametros_categoria.parametros_id IS 'Versión de parámetros de la temporada usada.';
COMMENT ON COLUMN siglim.parametros_categoria.categoria_id IS 'Categoría del catálogo.';
COMMENT ON COLUMN siglim.parametros_categoria.duracion_juego_min IS 'Duración de juego de la categoría en minutos.';
COMMENT ON COLUMN siglim.parametros_categoria.bloque_cancha_min IS 'Bloque de cancha de la categoría en minutos.';
COMMENT ON COLUMN siglim.parametros_temporada.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.parametros_temporada.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.parametros_temporada.version IS 'Versión consecutiva por temporada (la fija un trigger); la mayor es la vigente.';
COMMENT ON COLUMN siglim.parametros_temporada.puntos_victoria IS 'Puntos por victoria (3 [DEMO], DEC-26).';
COMMENT ON COLUMN siglim.parametros_temporada.puntos_empate IS 'Puntos por empate (1 [DEMO]).';
COMMENT ON COLUMN siglim.parametros_temporada.puntos_derrota IS 'Puntos por derrota (0 [DEMO]).';
COMMENT ON COLUMN siglim.parametros_temporada.criterios_desempate IS 'Orden de criterios; siempre inicia en PUNTOS (DEC-27).';
COMMENT ON COLUMN siglim.parametros_temporada.goles_default_ganador IS 'Goles del equipo presente en una no presentación (3 [DEMO], DEC-24).';
COMMENT ON COLUMN siglim.parametros_temporada.goles_default_perdedor IS 'Goles del equipo no presentado (0 [DEMO]).';
COMMENT ON COLUMN siglim.parametros_temporada.plazo_validacion_cedula IS 'Plazo del árbitro para validar la cédula (48 h [DEMO], DEC-20).';
COMMENT ON COLUMN siglim.parametros_temporada.duracion_juego_min IS 'Duración de juego base en minutos (90, DEC-25).';
COMMENT ON COLUMN siglim.parametros_temporada.bloque_cancha_min IS 'Bloque de cancha en minutos para detectar choques (120 [DEMO]).';
COMMENT ON COLUMN siglim.parametros_temporada.clasificados_liguilla IS 'Equipos que clasifican a la liguilla por grupo (8 [DEMO], DEC-28).';
COMMENT ON COLUMN siglim.parametros_temporada.formato_liguilla IS 'Partido único o ida y vuelta.';
COMMENT ON COLUMN siglim.parametros_temporada.empate_liguilla_por_penales IS 'Si un empate en liguilla se define por penales registrados en la cédula.';
COMMENT ON COLUMN siglim.parametros_temporada.equipos_ascienden IS 'Equipos que suben por categoría (2 [DEMO], DEC-29).';
COMMENT ON COLUMN siglim.parametros_temporada.equipos_descienden IS 'Equipos que bajan por categoría (2 [DEMO]).';
COMMENT ON COLUMN siglim.parametros_temporada.permite_cambio_club IS 'Si se aceptan cambios de club entre temporadas (RF-111, DEC-13).';
COMMENT ON COLUMN siglim.parametros_temporada.es_demo IS 'Valor de demostración [DEMO]: configurable y rotulado «no oficial» en la interfaz.';
COMMENT ON COLUMN siglim.parametros_temporada.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.parametros_temporada.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.parametros_temporada.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.pares_incompatibles.permiso_a_id IS 'Primer permiso del par (menor identificador).';
COMMENT ON COLUMN siglim.pares_incompatibles.permiso_b_id IS 'Segundo permiso del par.';
COMMENT ON COLUMN siglim.pares_incompatibles.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.partido_estado_historial.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.partido_estado_historial.partido_id IS 'Partido.';
COMMENT ON COLUMN siglim.partido_estado_historial.estado_anterior IS 'Estado antes del cambio (nulo en la creación).';
COMMENT ON COLUMN siglim.partido_estado_historial.estado_nuevo IS 'Estado después del cambio.';
COMMENT ON COLUMN siglim.partido_estado_historial.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.partido_estado_historial.cambiado_por IS 'Perfil que hizo el cambio (usuario Sistema en procesos automáticos).';
COMMENT ON COLUMN siglim.partido_estado_historial.cambiado_en IS 'Fecha y hora del cambio.';
COMMENT ON COLUMN siglim.partidos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.partidos.jornada_id IS 'Jornada.';
COMMENT ON COLUMN siglim.partidos.llave_id IS 'Llave de la fase final a la que pertenece el partido.';
COMMENT ON COLUMN siglim.partidos.equipo_local_id IS 'Equipo local.';
COMMENT ON COLUMN siglim.partidos.equipo_visitante_id IS 'Equipo visitante.';
COMMENT ON COLUMN siglim.partidos.cancha_id IS 'Cancha.';
COMMENT ON COLUMN siglim.partidos.inicio IS 'Fecha y hora de inicio programada.';
COMMENT ON COLUMN siglim.partidos.fin_bloque IS 'Fin del bloque de cancha = inicio + bloque de la categoría (lo calcula un trigger).';
COMMENT ON COLUMN siglim.partidos.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.partidos.motivo_localia IS 'Motivo con el que se aceptó una advertencia de localía (RF-120).';
COMMENT ON COLUMN siglim.partidos.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.partidos.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.partidos.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.perfiles.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.perfiles.usuario_auth_id IS 'Usuario de Supabase Auth (auth.users.id); nulo para el perfil Sistema.';
COMMENT ON COLUMN siglim.perfiles.persona_id IS 'Persona asociada a la cuenta (árbitro, directivo, tutor o jugador adulto).';
COMMENT ON COLUMN siglim.perfiles.nombre_mostrado IS 'Nombre que muestra la aplicación.';
COMMENT ON COLUMN siglim.perfiles.correo IS 'Correo de la cuenta.';
COMMENT ON COLUMN siglim.perfiles.activo IS 'Una cuenta inactiva se rechaza aunque su token siga vigente (ADR-0003).';
COMMENT ON COLUMN siglim.perfiles.es_sistema IS 'Marca el perfil técnico «Sistema» de las tareas programadas (ADR-0009).';
COMMENT ON COLUMN siglim.perfiles.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.perfiles.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.permisos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.permisos.codigo IS 'Código modulo.recurso:ACCION que evalúa el backend (ADR-0007).';
COMMENT ON COLUMN siglim.permisos.modulo IS 'Módulo del ERS (M-01 a M-14).';
COMMENT ON COLUMN siglim.permisos.descripcion IS 'Descripción.';
COMMENT ON COLUMN siglim.personas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.personas.curp IS 'CURP de 18 caracteres; clave única de la persona en todo el sistema (DEC-10).';
COMMENT ON COLUMN siglim.personas.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.personas.apellido_paterno IS 'Apellido paterno.';
COMMENT ON COLUMN siglim.personas.apellido_materno IS 'Apellido materno (opcional).';
COMMENT ON COLUMN siglim.personas.fecha_nacimiento IS 'Fecha de nacimiento; determina si es menor de edad (RN-055).';
COMMENT ON COLUMN siglim.personas.correo IS 'Correo de contacto (el del tutor se usa para su invitación).';
COMMENT ON COLUMN siglim.personas.telefono IS 'Teléfono de contacto.';
COMMENT ON COLUMN siglim.personas.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.personas.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.personas.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.propuesta_id IS 'Propuesta de ascenso y descenso.';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.equipo_id IS 'Equipo.';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.tipo IS 'Ascenso o descenso.';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.categoria_origen_id IS 'Categoría actual del equipo.';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.categoria_destino_id IS 'Categoría a la que se movería.';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.posicion_final IS 'Posición final en la tabla.';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.excluido IS 'Excluido por RN-052 (adeudos, baja o club con equipo arriba).';
COMMENT ON COLUMN siglim.propuesta_movimiento_detalle.motivo_exclusion IS 'Causa de la exclusión.';
COMMENT ON COLUMN siglim.propuestas_movimiento.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.propuestas_movimiento.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.propuestas_movimiento.parametros_id IS 'Versión de reglas que produjo la propuesta (RF-075).';
COMMENT ON COLUMN siglim.propuestas_movimiento.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.propuestas_movimiento.generada_en IS 'Fecha y hora de generación.';
COMMENT ON COLUMN siglim.propuestas_movimiento.validada_por IS 'Perfil que validó.';
COMMENT ON COLUMN siglim.propuestas_movimiento.validada_en IS 'Fecha y hora de validación.';
COMMENT ON COLUMN siglim.propuestas_movimiento.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.recursos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.recursos.expediente_id IS 'Expediente disciplinario.';
COMMENT ON COLUMN siglim.recursos.resolucion_id IS 'Resolución impugnada.';
COMMENT ON COLUMN siglim.recursos.club_id IS 'Club.';
COMMENT ON COLUMN siglim.recursos.motivo IS 'Argumentos del club.';
COMMENT ON COLUMN siglim.recursos.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.recursos.interpuesto_por IS 'Perfil que interpuso.';
COMMENT ON COLUMN siglim.recursos.interpuesto_en IS 'Fecha y hora de interposición.';
COMMENT ON COLUMN siglim.recursos.resolucion_final_id IS 'Resolución del Presidente en segunda instancia.';
COMMENT ON COLUMN siglim.registro_estado_historial.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.registro_estado_historial.registro_id IS 'Registro de jugador.';
COMMENT ON COLUMN siglim.registro_estado_historial.estado_anterior IS 'Estado antes del cambio (nulo en la creación).';
COMMENT ON COLUMN siglim.registro_estado_historial.estado_nuevo IS 'Estado después del cambio.';
COMMENT ON COLUMN siglim.registro_estado_historial.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.registro_estado_historial.cambiado_por IS 'Perfil que hizo el cambio (usuario Sistema en procesos automáticos).';
COMMENT ON COLUMN siglim.registro_estado_historial.cambiado_en IS 'Fecha y hora del cambio.';
COMMENT ON COLUMN siglim.registros_jugador.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.registros_jugador.persona_id IS 'Persona.';
COMMENT ON COLUMN siglim.registros_jugador.equipo_id IS 'Equipo.';
COMMENT ON COLUMN siglim.registros_jugador.temporada_id IS 'Temporada del equipo; la fija un trigger para validar la unicidad por CURP.';
COMMENT ON COLUMN siglim.registros_jugador.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.registros_jugador.registro_anterior_id IS 'Registro de la temporada anterior (renovación o transferencia).';
COMMENT ON COLUMN siglim.registros_jugador.alta_en IS 'Fecha de alta.';
COMMENT ON COLUMN siglim.registros_jugador.baja_en IS 'Fecha de baja; obligatoria con estado BAJA.';
COMMENT ON COLUMN siglim.registros_jugador.validado_por IS 'Perfil que validó.';
COMMENT ON COLUMN siglim.registros_jugador.validado_en IS 'Fecha y hora de validación.';
COMMENT ON COLUMN siglim.registros_jugador.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.registros_jugador.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.registros_jugador.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.registros_jugador.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.requisitos_documento.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.requisitos_documento.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.requisitos_documento.tipo_categoria IS 'Tipo de categoría al que aplica el requisito.';
COMMENT ON COLUMN siglim.requisitos_documento.tipo_documento_id IS 'Tipo de documento.';
COMMENT ON COLUMN siglim.requisitos_documento.cantidad IS 'Número de archivos exigidos.';
COMMENT ON COLUMN siglim.requisitos_documento.solo_menores IS 'Se exige solo cuando el jugador es menor (INE del tutor).';
COMMENT ON COLUMN siglim.requisitos_documento.es_demo IS 'Valor de demostración [DEMO]: configurable y rotulado «no oficial» en la interfaz.';
COMMENT ON COLUMN siglim.resoluciones.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.resoluciones.expediente_id IS 'Expediente disciplinario.';
COMMENT ON COLUMN siglim.resoluciones.instancia IS 'Primera instancia (Comisión Disciplinaria) o recurso (Presidente).';
COMMENT ON COLUMN siglim.resoluciones.articulo_id IS 'Artículo del reglamento aplicado.';
COMMENT ON COLUMN siglim.resoluciones.fundamentos IS 'Fundamentos de la resolución.';
COMMENT ON COLUMN siglim.resoluciones.sin_sancion IS 'Verdadero si se resuelve sin sanción.';
COMMENT ON COLUMN siglim.resoluciones.resuelta_por IS 'Perfil que resolvió.';
COMMENT ON COLUMN siglim.resoluciones.resuelta_en IS 'Fecha y hora de resolución.';
COMMENT ON COLUMN siglim.resultados.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.resultados.partido_id IS 'Partido.';
COMMENT ON COLUMN siglim.resultados.version IS 'Versión consecutiva del resultado del partido (la fija un trigger).';
COMMENT ON COLUMN siglim.resultados.goles_local IS 'Goles oficiales del local.';
COMMENT ON COLUMN siglim.resultados.goles_visitante IS 'Goles oficiales del visitante.';
COMMENT ON COLUMN siglim.resultados.penales_local IS 'Penales del local en tanda de desempate.';
COMMENT ON COLUMN siglim.resultados.penales_visitante IS 'Penales del visitante en tanda de desempate.';
COMMENT ON COLUMN siglim.resultados.origen IS 'Cédula aprobada o resolución disciplinaria (RF-048).';
COMMENT ON COLUMN siglim.resultados.cedula_id IS 'Cédula aprobada que lo oficializó.';
COMMENT ON COLUMN siglim.resultados.resolucion_id IS 'Resolución que lo modificó.';
COMMENT ON COLUMN siglim.resultados.por_default IS 'Marcador asignado por no presentación o por resolución (DEC-24, DEC-32).';
COMMENT ON COLUMN siglim.resultados.vigente IS 'Verdadero en la versión oficial vigente; solo esta columna admite cambios.';
COMMENT ON COLUMN siglim.resultados.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.resultados.registrado_por IS 'Perfil que registró.';
COMMENT ON COLUMN siglim.resultados.registrado_en IS 'Fecha y hora de registro.';
COMMENT ON COLUMN siglim.rol_permisos.rol_id IS 'Rol.';
COMMENT ON COLUMN siglim.rol_permisos.permiso_id IS 'Permiso.';
COMMENT ON COLUMN siglim.roles.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.roles.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.roles.codigo IS 'Código único legible por el sistema.';
COMMENT ON COLUMN siglim.roles.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.roles.descripcion IS 'Descripción.';
COMMENT ON COLUMN siglim.roles.ambito_predeterminado IS 'Ámbito con que se asigna normalmente el rol (liga, club o propio).';
COMMENT ON COLUMN siglim.roles.asignable IS 'Falso para roles técnicos o sin cuenta (Sistema, Usuario público).';
COMMENT ON COLUMN siglim.roles.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.sanciones.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.sanciones.resolucion_id IS 'Resolución.';
COMMENT ON COLUMN siglim.sanciones.tipo IS 'Tipo de sanción.';
COMMENT ON COLUMN siglim.sanciones.sujeto IS 'Jugador, equipo o club sancionado.';
COMMENT ON COLUMN siglim.sanciones.efecto IS 'Hacia adelante o retroactivo.';
COMMENT ON COLUMN siglim.sanciones.persona_id IS 'Jugador sancionado.';
COMMENT ON COLUMN siglim.sanciones.equipo_id IS 'Equipo.';
COMMENT ON COLUMN siglim.sanciones.club_id IS 'Club.';
COMMENT ON COLUMN siglim.sanciones.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.sanciones.partidos IS 'Partidos de suspensión.';
COMMENT ON COLUMN siglim.sanciones.partidos_cumplidos IS 'Partidos ya cumplidos de la suspensión.';
COMMENT ON COLUMN siglim.sanciones.puntos IS 'Puntos restados en la tabla.';
COMMENT ON COLUMN siglim.sanciones.monto IS 'Monto de la multa.';
COMMENT ON COLUMN siglim.sanciones.vigente_desde IS 'Inicio de la vigencia.';
COMMENT ON COLUMN siglim.sanciones.vigente_hasta IS 'Fin de la vigencia por fecha, si aplica.';
COMMENT ON COLUMN siglim.sanciones.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.sanciones.publicable IS 'La Comisión autorizó su difusión (RF-068).';
COMMENT ON COLUMN siglim.sanciones.publicada_en IS 'Fecha y hora de publicación en el portal.';
COMMENT ON COLUMN siglim.sanciones.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.sedes.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.sedes.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.sedes.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.sedes.direccion IS 'Domicilio o ubicación descriptiva.';
COMMENT ON COLUMN siglim.solicitudes_arco.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.solicitudes_arco.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.solicitudes_arco.persona_id IS 'Persona.';
COMMENT ON COLUMN siglim.solicitudes_arco.tipo IS 'Acceso, rectificación, cancelación u oposición.';
COMMENT ON COLUMN siglim.solicitudes_arco.descripcion IS 'Descripción.';
COMMENT ON COLUMN siglim.solicitudes_arco.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.solicitudes_arco.recibida_en IS 'Fecha y hora de recepción.';
COMMENT ON COLUMN siglim.solicitudes_arco.atendida_por IS 'Perfil que atendió.';
COMMENT ON COLUMN siglim.solicitudes_arco.atendida_en IS 'Fecha y hora de atención.';
COMMENT ON COLUMN siglim.solicitudes_arco.respuesta IS 'Respuesta entregada al titular.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.rol_id IS 'Rol.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.permisos_agregados IS 'Identificadores de permisos que se agregarían al rol.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.permisos_quitados IS 'Identificadores de permisos que se quitarían al rol.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.motivo IS 'Motivo de la operación o del cambio.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.solicitado_por IS 'Perfil que solicitó.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.solicitado_en IS 'Fecha y hora de solicitud.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.resuelto_por IS 'Perfil que resolvió.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.resuelto_en IS 'Fecha y hora de resolución.';
COMMENT ON COLUMN siglim.solicitudes_cambio_permisos.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.solicitudes_cancha.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.solicitudes_cancha.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.solicitudes_cancha.tipo IS 'Préstamo o comodato (Formato 1) u oferta (Formato 2).';
COMMENT ON COLUMN siglim.solicitudes_cancha.numero_oficio IS 'Número de oficio de la carta generada (RF-118).';
COMMENT ON COLUMN siglim.solicitudes_cancha.club_id IS 'Club solicitante u oferente.';
COMMENT ON COLUMN siglim.solicitudes_cancha.solicitante_externo IS 'Nombre del oferente externo sin cuenta (lo captura el Secretario).';
COMMENT ON COLUMN siglim.solicitudes_cancha.cancha_id IS 'Cancha.';
COMMENT ON COLUMN siglim.solicitudes_cancha.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.solicitudes_cancha.datos_formato IS 'Campos del Formato 1 o 2 en JSON (R8).';
COMMENT ON COLUMN siglim.solicitudes_cancha.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.solicitudes_cancha.capturada_por IS 'Perfil que capturó.';
COMMENT ON COLUMN siglim.solicitudes_cancha.capturada_en IS 'Fecha y hora de captura.';
COMMENT ON COLUMN siglim.solicitudes_cancha.resuelta_por IS 'Perfil que resolvió.';
COMMENT ON COLUMN siglim.solicitudes_cancha.resuelta_en IS 'Fecha y hora de resolución.';
COMMENT ON COLUMN siglim.solicitudes_cancha.observaciones IS 'Observaciones del usuario que resolvió o capturó.';
COMMENT ON COLUMN siglim.sorteos_desempate.grupo_id IS 'Grupo de la categoría en la temporada.';
COMMENT ON COLUMN siglim.sorteos_desempate.equipo_id IS 'Equipo.';
COMMENT ON COLUMN siglim.sorteos_desempate.orden IS 'Lugar asignado por sorteo (1 = mejor), último criterio de DEC-27.';
COMMENT ON COLUMN siglim.sorteos_desempate.registrado_por IS 'Perfil que registró.';
COMMENT ON COLUMN siglim.sorteos_desempate.registrado_en IS 'Fecha y hora de registro.';
COMMENT ON COLUMN siglim.tabla_historial.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.tabla_historial.grupo_id IS 'Grupo de la categoría en la temporada.';
COMMENT ON COLUMN siglim.tabla_historial.jornada_id IS 'Jornada.';
COMMENT ON COLUMN siglim.tabla_historial.datos IS 'Tabla calculada al cierre de la jornada, en JSON.';
COMMENT ON COLUMN siglim.tabla_historial.generada_en IS 'Fecha y hora de generación.';
COMMENT ON COLUMN siglim.tarifas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.tarifas.temporada_id IS 'Temporada.';
COMMENT ON COLUMN siglim.tarifas.categoria_id IS 'Categoría del catálogo.';
COMMENT ON COLUMN siglim.tarifas.concepto IS 'Arbitraje o cancha.';
COMMENT ON COLUMN siglim.tarifas.monto IS 'Importe en pesos mexicanos.';
COMMENT ON COLUMN siglim.temporadas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.temporadas.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.temporadas.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.temporadas.fecha_inicio IS 'Primer día de la temporada.';
COMMENT ON COLUMN siglim.temporadas.fecha_fin IS 'Último día de la temporada.';
COMMENT ON COLUMN siglim.temporadas.estado IS 'Estado actual (máquinas de estado del ERS §4.3).';
COMMENT ON COLUMN siglim.temporadas.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.temporadas.creado_en IS 'Fecha y hora de creación.';
COMMENT ON COLUMN siglim.temporadas.actualizado_en IS 'Fecha y hora de la última modificación (la fija un trigger).';
COMMENT ON COLUMN siglim.tipos_documento.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.tipos_documento.codigo IS 'Código del tipo de documento.';
COMMENT ON COLUMN siglim.tipos_documento.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.tipos_documento.descripcion IS 'Descripción.';
COMMENT ON COLUMN siglim.tipos_incidencia.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.tipos_incidencia.liga_id IS 'Liga a la que pertenece (ADR-0011).';
COMMENT ON COLUMN siglim.tipos_incidencia.codigo IS 'Código único legible por el sistema.';
COMMENT ON COLUMN siglim.tipos_incidencia.nombre IS 'Nombre.';
COMMENT ON COLUMN siglim.tipos_incidencia.abre_expediente IS 'Si la incidencia abre expediente al aprobarse la cédula (DEC-22).';
COMMENT ON COLUMN siglim.tipos_incidencia.activo IS 'Indica si está activo.';
COMMENT ON COLUMN siglim.tipos_incidencia.es_demo IS 'Valor de demostración [DEMO]: configurable y rotulado «no oficial» en la interfaz.';
COMMENT ON COLUMN siglim.tutelas.id IS 'Identificador único.';
COMMENT ON COLUMN siglim.tutelas.menor_id IS 'Persona menor de edad.';
COMMENT ON COLUMN siglim.tutelas.tutor_id IS 'Persona tutora, cuya cuenta gestiona al menor (DEC-11).';
COMMENT ON COLUMN siglim.tutelas.parentesco IS 'Parentesco o relación con el menor.';
COMMENT ON COLUMN siglim.tutelas.vigente IS 'Indica si es la versión o relación vigente.';
COMMENT ON COLUMN siglim.tutelas.creado_por IS 'Perfil que creó el registro.';
COMMENT ON COLUMN siglim.tutelas.creado_en IS 'Fecha y hora de creación.';

-- -------------------------------------------------------------------------------------
-- 12. DATOS SEMILLA
--     Liga, perfil Sistema, los 12 tipos de usuario, catálogo de permisos y matriz inicial
--     del Apéndice E (configurable), pares incompatibles y catálogos [DEMO] del ERS.
-- -------------------------------------------------------------------------------------

-- 12.1 Liga y perfil Sistema (ADR-0009, ADR-0011) ----------------------------------------
INSERT INTO siglim.ligas (id, nombre, nombre_corto)
VALUES ('a0000000-0000-4000-8000-000000000001', 'Liga Municipal de Futbol Amateur Morelia', 'LMFAM');

INSERT INTO siglim.perfiles (id, nombre_mostrado, es_sistema)
VALUES ('a0000000-0000-4000-8000-000000000002', 'Sistema', true);

-- 12.2 Roles (ERS §2.3) -----------------------------------------------------------------
INSERT INTO siglim.roles (liga_id, codigo, nombre, ambito_predeterminado, asignable, descripcion)
SELECT 'a0000000-0000-4000-8000-000000000001', r.codigo, r.nombre, r.ambito::siglim.ambito, r.asignable, r.descripcion
FROM (VALUES
  ('ADMINISTRADOR_GENERAL',  'Administrador general',            'LIGA',   true,  'Usuarios, roles, permisos, catálogos y temporadas. No aprueba decisiones del negocio.'),
  ('PRESIDENTE',             'Presidente del Comité Ejecutivo',  'LIGA',   true,  'Autoridad de la Liga: aprueba afiliaciones, programación, comunicados, trámites y pares de permisos incompatibles.'),
  ('SECRETARIO',             'Secretario (liga)',                'LIGA',   true,  'Tarjetones, validación de documentos e identidad, oficios y comunicados.'),
  ('TESORERO',               'Tesorero (liga)',                  'LIGA',   true,  'Tarifas, cobros, pagos y adeudos.'),
  ('COMISION_DISCIPLINARIA', 'Comisión Disciplinaria',           'LIGA',   true,  'Expedientes, resoluciones y sanciones.'),
  ('COMISION_ARBITRAJE',     'Comisión de Arbitraje',            'LIGA',   true,  'Validación y designación de árbitros; cédulas con plazo vencido.'),
  ('PROGRAMADOR',            'Programador de partidos',          'LIGA',   true,  'Jornadas, canchas, horarios y cambios de estado del partido.'),
  ('DIRECTIVA_CLUB',         'Directiva de club',                'CLUB',   true,  'Tarjetón, equipos, jugadores, árbitros, trámites y pagos de su club.'),
  ('ARBITRO',                'Árbitro',                          'PROPIO', true,  'Designaciones propias y aprobación de la cédula de sus partidos.'),
  ('CAPTURISTA',             'Capturista',                       'LIGA',   true,  'Captura de la cédula y envío a validación.'),
  ('JUGADOR_TUTOR',          'Jugador o tutor',                  'PROPIO', true,  'Consulta de su información o la del menor bajo su tutela.'),
  ('USUARIO_PUBLICO',        'Usuario público',                  'LIGA',   false, 'Sin cuenta: consulta el portal (rol de base de datos siglim_publico).'),
  ('SISTEMA',                'Sistema',                          'LIGA',   false, 'Tareas programadas y procesos automáticos (ADR-0009).')
) AS r (codigo, nombre, ambito, asignable, descripcion);

INSERT INTO siglim.asignaciones_rol (perfil_id, rol_id, liga_id, ambito)
SELECT 'a0000000-0000-4000-8000-000000000002', id, liga_id, 'LIGA' FROM siglim.roles WHERE codigo = 'SISTEMA';

-- 12.3 Catálogo de permisos (ADR-0007) --------------------------------------------------
INSERT INTO siglim.permisos (codigo, modulo, descripcion)
VALUES
  ('seguridad.usuario:CONSULTAR',             'M-01', 'Consultar cuentas y sus roles'),
  ('seguridad.usuario:CREAR',                 'M-01', 'Invitar cuentas y asignar roles con ámbito'),
  ('seguridad.usuario:EDITAR',                'M-01', 'Activar, desactivar o cambiar roles de una cuenta'),
  ('seguridad.rol:CONSULTAR',                 'M-01', 'Consultar roles y permisos'),
  ('seguridad.rol:EDITAR',                    'M-01', 'Modificar los permisos de un rol (RF-095)'),
  ('seguridad.permisos:APROBAR_INCOMPATIBLE', 'M-01', 'Aprobar o rechazar un par de permisos incompatibles (RF-096)'),
  ('seguridad.consentimiento:REGISTRAR',      'M-01', 'Registrar el consentimiento del titular o del tutor (RF-097)'),
  ('seguridad.arco:GESTIONAR',                'M-01', 'Atender solicitudes ARCO (RF-098)'),
  ('auditoria.registro:CONSULTAR',            'M-01', 'Consultar la auditoría (RF-134)'),
  ('temporadas.temporada:CONSULTAR',          'M-02', 'Consultar temporadas, categorías, grupos y parámetros'),
  ('temporadas.temporada:EDITAR',             'M-02', 'Crear, activar y cerrar temporadas; categorías y grupos'),
  ('temporadas.parametros:EDITAR',            'M-02', 'Registrar una versión de parámetros deportivos (RF-100)'),
  ('temporadas.convocatoria:EDITAR',          'M-02', 'Asociar la convocatoria (RF-002)'),
  ('temporadas.interpretacion:REGISTRAR',     'M-02', 'Registrar una regla interpretada (RF-007)'),
  ('temporadas.interpretacion:APROBAR',       'M-02', 'Autorizar o rechazar una regla interpretada (RF-007)'),
  ('organizacion.club:CONSULTAR',             'M-03', 'Consultar clubes, afiliaciones y directivas'),
  ('organizacion.club:EDITAR',                'M-03', 'Registrar y editar clubes; cambio de nombre'),
  ('organizacion.afiliacion:CAPTURAR',        'M-03', 'Capturar el tarjetón de afiliación (RF-101)'),
  ('organizacion.afiliacion:APROBAR',         'M-03', 'Aprobar o rechazar la afiliación (RF-101)'),
  ('organizacion.directiva:EDITAR',           'M-03', 'Registrar cambios de directiva (RF-102)'),
  ('organizacion.directiva:APROBAR',          'M-03', 'Autorizar cambios de directiva (RF-102)'),
  ('organizacion.equipo:CONSULTAR',           'M-03', 'Consultar equipos'),
  ('organizacion.equipo:EDITAR',              'M-03', 'Registrar equipos y su baja (RF-009)'),
  ('organizacion.venta:SOLICITAR',            'M-03', 'Registrar venta de equipo o conservación de plaza (RF-103, RF-104)'),
  ('organizacion.venta:APROBAR',              'M-03', 'Autorizar venta de equipo o conservación de plaza (RF-103, RF-104)'),
  ('organizacion.persona:CONSULTAR',          'M-03', 'Consultar personas de su ámbito'),
  ('organizacion.persona:EDITAR',             'M-03', 'Registrar personas y tutores (RF-010, RF-106)'),
  ('registros.registro:CONSULTAR',            'M-04', 'Consultar registros de jugadores y elegibilidad'),
  ('registros.registro:EDITAR',               'M-04', 'Dar de alta, renovar o dar de baja jugadores (RF-013 a RF-016)'),
  ('registros.registro:VALIDAR',              'M-04', 'Validar o rechazar un registro (RF-109)'),
  ('registros.documento:CONSULTAR',           'M-04', 'Ver documentos con URL prefirmada (RNF-018)'),
  ('registros.documento:CREAR',               'M-04', 'Cargar documentos y fotos (RF-108)'),
  ('registros.documento:VALIDAR',             'M-04', 'Aprobar o rechazar documentos (RF-109)'),
  ('arbitraje.arbitro:CONSULTAR',             'M-05', 'Consultar árbitros'),
  ('arbitraje.arbitro:PROPONER',              'M-05', 'Registrar árbitros del club (RF-112)'),
  ('arbitraje.arbitro:VALIDAR',               'M-05', 'Validar árbitros (RF-113)'),
  ('arbitraje.disponibilidad:EDITAR',         'M-05', 'Registrar disponibilidad arbitral (RF-022)'),
  ('arbitraje.designacion:CONSULTAR',         'M-05', 'Consultar designaciones'),
  ('arbitraje.designacion:EDITAR',            'M-05', 'Designar árbitros a partidos (RF-023)'),
  ('canchas.cancha:CONSULTAR',                'M-06', 'Consultar canchas y disponibilidad'),
  ('canchas.cancha:EDITAR',                   'M-06', 'Registrar canchas, sedes, disponibilidad y bloqueos (RF-027 a RF-031)'),
  ('canchas.solicitud:CREAR',                 'M-06', 'Capturar Formato 1 u oferta Formato 2 (RF-116, RF-117)'),
  ('canchas.solicitud:APROBAR',               'M-06', 'Aprobar o aceptar trámites de cancha (RF-116, RF-117)'),
  ('canchas.oficio:GENERAR',                  'M-06', 'Generar cartas con número de oficio (RF-118)'),
  ('programacion.jornada:CONSULTAR',          'M-07', 'Consultar jornadas y partidos internos'),
  ('programacion.jornada:EDITAR',             'M-07', 'Registrar y ajustar jornadas y partidos (RF-033, RF-036, RF-040)'),
  ('programacion.jornada:ENVIAR',             'M-07', 'Enviar la jornada a aprobación'),
  ('programacion.jornada:APROBAR',            'M-07', 'Aprobar o devolver la jornada (RF-121)'),
  ('partidos.partido:CONSULTAR',              'M-08', 'Consultar partidos, resultados y tabla'),
  ('partidos.partido:CAMBIAR_ESTADO',         'M-08', 'Suspender, reprogramar o cancelar con motivo (RF-043)'),
  ('partidos.cedula:CONSULTAR',               'M-08', 'Consultar cédulas'),
  ('partidos.cedula:CAPTURAR',                'M-08', 'Capturar la cédula y enviarla a validación (RF-025, RF-122)'),
  ('partidos.cedula:APROBAR',                 'M-08', 'Aprobar o devolver la cédula como árbitro designado (RF-123)'),
  ('partidos.cedula:APROBAR_VENCIDA',         'M-08', 'Aprobar la cédula con plazo vencido (RF-124)'),
  ('partidos.sorteo:REGISTRAR',               'M-08', 'Registrar el sorteo de desempate (DEC-27)'),
  ('disciplina.catalogo:EDITAR',              'M-09', 'Configurar tipos de incidencia y artículos (RF-128, RF-129)'),
  ('disciplina.expediente:CONSULTAR',         'M-09', 'Consultar expedientes y sanciones de su ámbito'),
  ('disciplina.expediente:RESOLVER',          'M-09', 'Revisar y resolver expedientes (RF-062)'),
  ('disciplina.sancion:PUBLICAR',             'M-09', 'Autorizar la difusión de sanciones (RF-068)'),
  ('disciplina.recurso:INTERPONER',           'M-09', 'Interponer recurso de inconformidad (RF-067)'),
  ('disciplina.recurso:RESOLVER',             'M-09', 'Resolver el recurso en segunda instancia (RF-067)'),
  ('competencias.fase:EDITAR',                'M-10', 'Configurar fases finales y llaves (RF-076, RF-078)'),
  ('competencias.propuesta:APROBAR',          'M-10', 'Validar ascensos y descensos (RF-074)'),
  ('publicacion.comunicado:REDACTAR',         'M-11', 'Redactar comunicados y enviarlos a revisión'),
  ('publicacion.comunicado:APROBAR',          'M-11', 'Aprobar o devolver comunicados (RF-090)'),
  ('reportes.reporte:CONSULTAR',              'M-12', 'Consultar reportes de su ámbito (RF-091)'),
  ('reportes.reporte:EXPORTAR',               'M-12', 'Exportar reportes a PDF o Excel (RF-092)'),
  ('tesoreria.tarifa:EDITAR',                 'M-13', 'Configurar tarifas (RF-135)'),
  ('tesoreria.cobro:CONSULTAR',               'M-13', 'Consultar cobros y adeudos de su ámbito (RF-140)'),
  ('tesoreria.cobro:CREAR',                   'M-13', 'Crear cobros manuales (RF-137)'),
  ('tesoreria.pago:REGISTRAR',                'M-13', 'Registrar pagos recibidos fuera del sistema (RF-139)'),
  ('tesoreria.pago:PAGAR',                    'M-13', 'Pagar en línea (simulado) los cobros de su club (RF-138)'),
  ('notificaciones.aviso:CONSULTAR',          'M-14', 'Consultar y marcar como leídos sus avisos (RF-142)');

-- 12.4 Matriz inicial rol → permisos (Apéndice E; configurable, DEC-04) -----------------
INSERT INTO siglim.rol_permisos (rol_id, permiso_id)
SELECT r.id, p.id
FROM (VALUES
  ('ADMINISTRADOR_GENERAL', '{seguridad.usuario:CONSULTAR,seguridad.usuario:CREAR,seguridad.usuario:EDITAR,seguridad.rol:CONSULTAR,seguridad.rol:EDITAR,seguridad.arco:GESTIONAR,auditoria.registro:CONSULTAR,temporadas.temporada:CONSULTAR,temporadas.temporada:EDITAR,temporadas.parametros:EDITAR,temporadas.interpretacion:REGISTRAR,organizacion.club:CONSULTAR,organizacion.club:EDITAR,organizacion.equipo:CONSULTAR,organizacion.equipo:EDITAR,canchas.cancha:CONSULTAR,canchas.cancha:EDITAR,disciplina.catalogo:EDITAR,reportes.reporte:CONSULTAR,reportes.reporte:EXPORTAR}'),
  ('PRESIDENTE', '{seguridad.permisos:APROBAR_INCOMPATIBLE,seguridad.rol:CONSULTAR,auditoria.registro:CONSULTAR,temporadas.temporada:CONSULTAR,temporadas.interpretacion:APROBAR,organizacion.club:CONSULTAR,organizacion.afiliacion:APROBAR,organizacion.directiva:APROBAR,organizacion.equipo:CONSULTAR,organizacion.venta:APROBAR,canchas.cancha:CONSULTAR,canchas.solicitud:APROBAR,programacion.jornada:CONSULTAR,programacion.jornada:APROBAR,partidos.partido:CONSULTAR,partidos.sorteo:REGISTRAR,disciplina.expediente:CONSULTAR,disciplina.recurso:RESOLVER,competencias.propuesta:APROBAR,publicacion.comunicado:APROBAR,reportes.reporte:CONSULTAR,reportes.reporte:EXPORTAR}'),
  ('SECRETARIO', '{temporadas.temporada:CONSULTAR,temporadas.convocatoria:EDITAR,organizacion.club:CONSULTAR,organizacion.club:EDITAR,organizacion.afiliacion:CAPTURAR,organizacion.directiva:EDITAR,organizacion.equipo:CONSULTAR,organizacion.persona:CONSULTAR,organizacion.persona:EDITAR,seguridad.consentimiento:REGISTRAR,registros.registro:CONSULTAR,registros.registro:VALIDAR,registros.documento:CONSULTAR,registros.documento:VALIDAR,canchas.cancha:CONSULTAR,canchas.solicitud:CREAR,canchas.oficio:GENERAR,publicacion.comunicado:REDACTAR,reportes.reporte:CONSULTAR,reportes.reporte:EXPORTAR}'),
  ('TESORERO', '{tesoreria.tarifa:EDITAR,tesoreria.cobro:CONSULTAR,tesoreria.cobro:CREAR,tesoreria.pago:REGISTRAR,canchas.cancha:CONSULTAR,organizacion.club:CONSULTAR,reportes.reporte:CONSULTAR,reportes.reporte:EXPORTAR}'),
  ('COMISION_DISCIPLINARIA', '{disciplina.catalogo:EDITAR,disciplina.expediente:CONSULTAR,disciplina.expediente:RESOLVER,disciplina.sancion:PUBLICAR,partidos.partido:CONSULTAR,partidos.cedula:CONSULTAR,registros.registro:CONSULTAR,reportes.reporte:CONSULTAR,reportes.reporte:EXPORTAR}'),
  ('COMISION_ARBITRAJE', '{arbitraje.arbitro:CONSULTAR,arbitraje.arbitro:VALIDAR,arbitraje.disponibilidad:EDITAR,arbitraje.designacion:CONSULTAR,arbitraje.designacion:EDITAR,partidos.partido:CONSULTAR,partidos.cedula:CONSULTAR,partidos.cedula:APROBAR_VENCIDA,programacion.jornada:CONSULTAR,reportes.reporte:CONSULTAR,reportes.reporte:EXPORTAR}'),
  ('PROGRAMADOR', '{programacion.jornada:CONSULTAR,programacion.jornada:EDITAR,programacion.jornada:ENVIAR,partidos.partido:CONSULTAR,partidos.partido:CAMBIAR_ESTADO,competencias.fase:EDITAR,arbitraje.arbitro:CONSULTAR,arbitraje.designacion:CONSULTAR,canchas.cancha:CONSULTAR,organizacion.equipo:CONSULTAR,temporadas.temporada:CONSULTAR}'),
  ('DIRECTIVA_CLUB', '{organizacion.club:CONSULTAR,organizacion.afiliacion:CAPTURAR,organizacion.directiva:EDITAR,organizacion.equipo:CONSULTAR,organizacion.equipo:EDITAR,organizacion.venta:SOLICITAR,organizacion.persona:CONSULTAR,organizacion.persona:EDITAR,seguridad.consentimiento:REGISTRAR,registros.registro:CONSULTAR,registros.registro:EDITAR,registros.documento:CONSULTAR,registros.documento:CREAR,arbitraje.arbitro:CONSULTAR,arbitraje.arbitro:PROPONER,canchas.solicitud:CREAR,programacion.jornada:CONSULTAR,partidos.partido:CONSULTAR,disciplina.expediente:CONSULTAR,disciplina.recurso:INTERPONER,tesoreria.cobro:CONSULTAR,tesoreria.pago:PAGAR,reportes.reporte:CONSULTAR,reportes.reporte:EXPORTAR}'),
  ('ARBITRO', '{arbitraje.designacion:CONSULTAR,arbitraje.disponibilidad:EDITAR,partidos.partido:CONSULTAR,partidos.cedula:CONSULTAR,partidos.cedula:APROBAR}'),
  ('CAPTURISTA', '{partidos.partido:CONSULTAR,partidos.cedula:CONSULTAR,partidos.cedula:CAPTURAR}'),
  ('JUGADOR_TUTOR', '{registros.registro:CONSULTAR,registros.documento:CONSULTAR,partidos.partido:CONSULTAR,disciplina.expediente:CONSULTAR}')
) AS m (rol, permisos)
JOIN siglim.roles r ON r.codigo = m.rol
CROSS JOIN LATERAL unnest(m.permisos::text[]) AS c (codigo)
JOIN siglim.permisos p ON p.codigo = c.codigo;

-- Todos los roles con cuenta consultan sus avisos
INSERT INTO siglim.rol_permisos (rol_id, permiso_id)
SELECT r.id, p.id FROM siglim.roles r CROSS JOIN siglim.permisos p
WHERE r.asignable AND p.codigo = 'notificaciones.aviso:CONSULTAR';

-- 12.5 Pares de permisos incompatibles (ERS Apéndice E [PROPUESTA]) ----------------------
INSERT INTO siglim.pares_incompatibles (permiso_a_id, permiso_b_id, motivo)
SELECT least(a.id, b.id), greatest(a.id, b.id), x.motivo
FROM (VALUES
  ('partidos.cedula:CAPTURAR', 'partidos.cedula:APROBAR', 'Capturar y validar la cédula (RN-044)'),
  ('partidos.cedula:CAPTURAR', 'partidos.cedula:APROBAR_VENCIDA', 'Capturar y validar la cédula con plazo vencido (RN-044)'),
  ('programacion.jornada:EDITAR', 'programacion.jornada:APROBAR', 'Programar y aprobar la programación'),
  ('disciplina.expediente:RESOLVER', 'disciplina.recurso:RESOLVER', 'Resolver un expediente y su recurso'),
  ('publicacion.comunicado:REDACTAR', 'publicacion.comunicado:APROBAR', 'Redactar y aprobar comunicados'),
  ('seguridad.rol:EDITAR', 'seguridad.permisos:APROBAR_INCOMPATIBLE', 'Modificar permisos y aprobar pares incompatibles (RN-053)')
) AS x (a, b, motivo)
JOIN siglim.permisos a ON a.codigo = x.a
JOIN siglim.permisos b ON b.codigo = x.b;

-- 12.6 Documentos por tipo de categoría (DEC-10) ----------------------------------------
INSERT INTO siglim.tipos_documento (codigo, nombre, descripcion) VALUES
  ('CONSTANCIA_ESTUDIOS',   'Constancia de estudios',     'Categorías infantiles'),
  ('IDENTIFICACION',        'Identificación',             'Identificación oficial o escolar'),
  ('INE',                   'Credencial INE',             'Identificación del jugador adulto'),
  ('COMPROBANTE_DOMICILIO', 'Comprobante de domicilio',   'Categoría de veteranos'),
  ('FOTOGRAFIA',            'Fotografía',                 'Fotografía del jugador'),
  ('INE_TUTOR',             'Credencial INE del tutor',   'Obligatoria cuando el jugador es menor (RN-055)'),
  ('TARJETON_FIRMADO',      'Tarjetón firmado',           'Firmas del presidente, secretario y tesorero del club (DEC-09)'),
  ('EVIDENCIA',             'Evidencia disciplinaria',    'Evidencia de un expediente (RF-059)'),
  ('COMPROBANTE_PAGO',      'Comprobante de pago',        'Pago recibido fuera del sistema (RF-139)');

INSERT INTO siglim.requisitos_documento (liga_id, tipo_categoria, tipo_documento_id, cantidad, solo_menores, es_demo)
SELECT 'a0000000-0000-4000-8000-000000000001', x.tipo::siglim.tipo_categoria, d.id, x.cantidad, x.solo_menores, x.es_demo
FROM (VALUES
  ('INFANTIL',  'CONSTANCIA_ESTUDIOS',   1, false, false),
  ('INFANTIL',  'IDENTIFICACION',        1, false, false),
  ('INFANTIL',  'FOTOGRAFIA',            2, false, true),   -- R2 dice «fotos» sin número [DEMO]
  ('VETERANOS', 'INE',                   1, false, false),
  ('VETERANOS', 'COMPROBANTE_DOMICILIO', 1, false, false),
  ('VETERANOS', 'FOTOGRAFIA',            2, false, true),   -- [DEMO]
  ('LIBRE',     'IDENTIFICACION',        1, false, false),
  ('LIBRE',     'FOTOGRAFIA',            2, false, false),
  ('INFANTIL',  'INE_TUTOR',             1, true,  false),
  ('LIBRE',     'INE_TUTOR',             1, true,  false),
  ('VETERANOS', 'INE_TUTOR',             1, true,  false)
) AS x (tipo, documento, cantidad, solo_menores, es_demo)
JOIN siglim.tipos_documento d ON d.codigo = x.documento;

-- 12.7 Disciplina [DEMO] (DEC-22, DEC-30, DEC-31) ---------------------------------------
INSERT INTO siglim.tipos_incidencia (liga_id, codigo, nombre, abre_expediente, es_demo) VALUES
  ('a0000000-0000-4000-8000-000000000001', 'AMONESTACION', 'Amonestación',    false, true),
  ('a0000000-0000-4000-8000-000000000001', 'EXPULSION',    'Expulsión',       true,  true),
  ('a0000000-0000-4000-8000-000000000001', 'RINA',         'Riña',            true,  true);

INSERT INTO siglim.articulos (liga_id, numero, descripcion, tipo_sancion, sujeto, efecto, aplicacion_automatica, es_demo) VALUES
  ('a0000000-0000-4000-8000-000000000001', 'DEMO-1', 'Baja del equipo por riña (requiere resolución de la Comisión Disciplinaria).', 'BAJA', 'EQUIPO', 'HACIA_ADELANTE', false, true),
  ('a0000000-0000-4000-8000-000000000001', 'DEMO-2', 'Baja del equipo por 5 partidos perdidos por default.',                         'BAJA', 'EQUIPO', 'HACIA_ADELANTE', true,  true),
  ('a0000000-0000-4000-8000-000000000001', 'DEMO-3', 'Baja del equipo por falta de pago.',                                          'BAJA', 'EQUIPO', 'HACIA_ADELANTE', true,  true);

-- -------------------------------------------------------------------------------------
-- 13. ALTA DEL PRIMER ADMINISTRADOR
--     1) Authentication → Users → Invite user (correo del administrador).
--     2) SELECT siglim.registrar_administrador_inicial('correo@dominio');
--     Solo funciona mientras no exista otro Administrador general.
-- -------------------------------------------------------------------------------------
CREATE FUNCTION siglim.registrar_administrador_inicial(p_correo text) RETURNS uuid
LANGUAGE plpgsql
SET search_path = siglim, pg_temp
AS $$
DECLARE
  v_auth   uuid;
  v_perfil uuid;
  v_rol    siglim.roles%ROWTYPE;
BEGIN
  SELECT * INTO v_rol FROM roles WHERE codigo = 'ADMINISTRADOR_GENERAL';
  IF EXISTS (SELECT 1 FROM asignaciones_rol WHERE rol_id = v_rol.id AND activa) THEN
    RAISE EXCEPTION 'Ya existe un Administrador general; use la aplicación para crear más cuentas.';
  END IF;
  SELECT id INTO v_auth FROM auth.users WHERE lower(email) = lower(p_correo);
  IF v_auth IS NULL THEN
    RAISE EXCEPTION 'No existe una cuenta de Supabase Auth con el correo %; invítela primero.', p_correo;
  END IF;
  INSERT INTO perfiles (usuario_auth_id, nombre_mostrado, correo)
  VALUES (v_auth, split_part(p_correo, '@', 1), lower(p_correo))
  RETURNING id INTO v_perfil;
  INSERT INTO asignaciones_rol (perfil_id, rol_id, liga_id, ambito)
  VALUES (v_perfil, v_rol.id, v_rol.liga_id, 'LIGA');
  INSERT INTO auditoria (liga_id, perfil_id, modulo, accion, entidad, entidad_id, motivo)
  VALUES (v_rol.liga_id, v_perfil, 'M-01', 'REGISTRAR_ADMINISTRADOR_INICIAL', 'perfiles', v_perfil::text,
          'Alta del primer Administrador general desde el SQL Editor');
  RETURN v_perfil;
END $$;
REVOKE EXECUTE ON FUNCTION siglim.registrar_administrador_inicial(text) FROM PUBLIC, siglim_app;
COMMENT ON FUNCTION siglim.registrar_administrador_inicial(text) IS 'Arranque: crea el perfil y la asignación del primer Administrador general. Solo el dueño del esquema la ejecuta.';

COMMIT;
