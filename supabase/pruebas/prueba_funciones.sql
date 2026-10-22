-- Prueba de regresión: toda función del esquema siglim fija su search_path.
-- Evita que vuelva el aviso 0011 del asesor de seguridad de Supabase («function_search_path_mutable»)
-- al agregar funciones en migraciones futuras. Refs: RNF-013, ADR-0014.
DO $$
DECLARE
  v_sin_search_path text;
  v_total integer;
BEGIN
  SELECT count(*),
         string_agg(p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')', ', ')
           FILTER (WHERE NOT EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig, '{}')) c
                                     WHERE c LIKE 'search_path=%'))
    INTO v_total, v_sin_search_path
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'siglim' AND p.prokind IN ('f', 'p');

  IF v_sin_search_path IS NOT NULL THEN
    RAISE EXCEPTION 'Funciones de siglim sin search_path fijo: %', v_sin_search_path;
  END IF;
  RAISE NOTICE 'OK  RNF-013: las % funciones de siglim fijan search_path', v_total;
END $$;
