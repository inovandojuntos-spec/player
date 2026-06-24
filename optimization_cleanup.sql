-- =====================================================================
--  INOVANDO JUNTOS — OPTIMIZACIÓN Y LIMPIEZA (Postgres 17)
--  Proyecto: rsordtljnvxonaygyuxd
--  Ejecutar DESPUÉS de security_hardening.sql
--
--  Contenido:
--    1) Índices faltantes en claves foráneas.
--    2) Borrado de índices/constraints DUPLICADOS (verificados: no rompen FKs).
--    3) Optimización de policies RLS (auth.uid() envuelto en SELECT).
--    4) Cierre de funciones de trigger frente a anon.
--    5) (Opcional) índices sin uso — comentados, revisar tras tener tráfico.
--
--  Seguro y transaccional. Las tablas son pequeñas, no se requiere CONCURRENTLY.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1) ÍNDICES EN CLAVES FORÁNEAS SIN COBERTURA
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_desafio_items_distributor_id
  ON public.desafio_items (distributor_id);

CREATE INDEX IF NOT EXISTS idx_desafio_items_item_id
  ON public.desafio_items (item_id);

CREATE INDEX IF NOT EXISTS idx_marketing_consents_user_id
  ON public.marketing_consents (user_id);


-- ---------------------------------------------------------------------
-- 2) ÍNDICES / CONSTRAINTS DUPLICADOS
--    Se conserva en cada caso el respaldado por constraint (PK/UNIQUE)
--    y se elimina el índice plano redundante.
-- ---------------------------------------------------------------------
-- contract_responses: conserva el UNIQUE constraint, borra el índice plano
DROP INDEX IF EXISTS public.contract_responses_user_desafio_uidx;

-- profile_desafios: dos índices planos idénticos, conserva _profile_id
DROP INDEX IF EXISTS public.idx_profile_desafios_profile;

-- target_done / favorites / likes: conserva el UNIQUE, borra el ux_ plano
DROP INDEX IF EXISTS public.ux_target_done_user_target;
DROP INDEX IF EXISTS public.ux_target_favorites_user_target;
DROP INDEX IF EXISTS public.ux_target_likes_user_target;

-- roulette_snapshots: PK y UNIQUE idénticos -> conserva PK, borra UNIQUE
ALTER TABLE public.roulette_snapshots
  DROP CONSTRAINT IF EXISTS snapshots_player_session_uniq;

-- desafio_items: dos UNIQUE idénticos -> conserva desafio_items_unique_assignment
--   (Si alguna FK apuntara a la que borramos fallaría; ninguna lo hace.)
ALTER TABLE public.desafio_items
  DROP CONSTRAINT IF EXISTS desafio_items_desafio_item_distributor_key;


-- ---------------------------------------------------------------------
-- 3) OPTIMIZAR POLICIES RLS (auth_rls_initplan)
--    Envolver auth.uid() en (select auth.uid()) evita reevaluarla por fila.
-- ---------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can read own contract responses"   ON public.contract_responses;
DROP POLICY IF EXISTS "Users can insert own contract responses" ON public.contract_responses;
DROP POLICY IF EXISTS "Users can update own contract responses" ON public.contract_responses;

CREATE POLICY "Users can read own contract responses"
  ON public.contract_responses FOR SELECT
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can insert own contract responses"
  ON public.contract_responses FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own contract responses"
  ON public.contract_responses FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);


-- ---------------------------------------------------------------------
-- 4) CERRAR FUNCIONES DE TRIGGER FRENTE A anon
--    Son disparadas por triggers, no deben exponerse a la API.
-- ---------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.set_updated_at()  FROM anon, authenticated, public;
-- Endurecer search_path por si faltara:
ALTER FUNCTION public.handle_new_user()      SET search_path = 'public';
ALTER FUNCTION public.set_updated_at()       SET search_path = 'public';
ALTER FUNCTION public.recalc_target_stats(text, uuid) SET search_path = 'public';

COMMIT;


-- =====================================================================
-- 5) ÍNDICES SIN USO  (OPCIONAL — NO ejecutar todavía)
--    El linter los marca "no usados", pero la base es joven y con poco
--    tráfico. Revisa estas estadísticas tras 2-4 semanas en producción
--    antes de borrarlos. Para decidir:
--      select relname, indexrelname, idx_scan
--        from pg_stat_user_indexes where schemaname='public'
--        order by idx_scan asc;
--    Candidatos marcados hoy:
--      roulette_snapshots_updated_at_idx, ix_target_events_log_target,
--      ij_events_created_at_idx, ij_events_player_session_idx,
--      ij_events_payload_gin_idx, idx_profiles_distributor_id,
--      idx_profiles_activation_code_id, idx_activation_codes_distributor_id,
--      idx_profile_desafios_last_played, idx_contract_templates_slug
-- =====================================================================
