#!/usr/bin/env bash
# Aplica la migración inicial en una base de prueba con el entorno de Supabase simulado y ejecuta
# las pruebas de integración del esquema. Requiere PostgreSQL 15+ local y un usuario superusuario.
#
# Uso:  PGHOST=localhost PGPORT=5432 PGUSER=postgres ./ejecutar.sh
# La base «siglim_pruebas» se borra y se crea de nuevo en cada ejecución.
set -euo pipefail
cd "$(dirname "$0")"
BD=siglim_pruebas
MIGRACION=$(ls ../migrations/*_esquema_inicial.sql | tail -1)

psql -q -d postgres -c "DROP DATABASE IF EXISTS $BD" >/dev/null
for rol in siglim_app siglim_publico anon authenticated service_role; do
  psql -q -d postgres -c "DROP ROLE IF EXISTS $rol" >/dev/null 2>&1 || true
done
psql -q -d postgres -c "CREATE DATABASE $BD" >/dev/null

psql -q -d $BD -v ON_ERROR_STOP=1 -f mock_supabase.sql
psql -q -d $BD -v ON_ERROR_STOP=1 -f "$MIGRACION" 2>&1 | grep -v NOTICE || true
psql -q -d $BD -v ON_ERROR_STOP=1 -o /dev/null -f prueba_flujo.sql 2>&1 | sed 's/^psql:[^ ]* //'
psql -q -d $BD -v ON_ERROR_STOP=1 -f prueba_tabla.sql
echo "Pruebas del esquema completadas sin errores."
