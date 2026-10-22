-- =====================================================================================================
-- Fija el search_path de siglim.error_negocio
--
-- Motivo: el asesor de seguridad de Supabase (lint 0011 «function_search_path_mutable») marcó que
-- siglim.error_negocio era la única función del esquema sin search_path fijo. Una función sin
-- search_path resuelve los nombres con el search_path de quien la llama, que un rol con permisos
-- de creación podría alterar para sustituir objetos. Las demás funciones de la migración inicial ya
-- usan «siglim, pg_temp»; esta migración alinea la que faltaba.
--
-- Efecto: ninguno en el comportamiento. La función sigue lanzando P0001 con el código del ERS en
-- HINT, que el backend traduce a RFC 9457 (T-02.4, convenciones de API §3.2).
--
-- Regla: no se edita la migración inicial ya aplicada (supabase/README.md, ADR-0004).
-- Refs: RNF-013, ADR-0004, ADR-0014
-- =====================================================================================================

ALTER FUNCTION siglim.error_negocio(text, text) SET search_path = siglim, pg_temp;
