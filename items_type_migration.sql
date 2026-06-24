-- =====================================================================
--  INOVANDO JUNTOS — NORMALIZACIÓN DE items_eroticos (item_type + external_url)
--  Proyecto: rsordtljnvxonaygyuxd
--  Ejecutar después de security_hardening.sql y optimization_cleanup.sql
--
--  OBJETIVO
--    Sacar la lógica de negocio del SLUG (hoy: slug.startsWith('adicionales_'))
--    y llevarla a columnas explícitas y consultables:
--      - item_type    : product | instruction | external_link | extra
--      - external_url : URL destino para los items de tipo external_link
--
--  REGLAS DE CLASIFICACIÓN (derivadas de los datos actuales)
--      slug 'adicionales_link_*'  -> external_link  (URL en video_url)
--      slug 'adicionales_*'       -> instruction
--      resto                      -> product
--
--  COMPATIBILIDAD
--    - Es 100% additivo. El frontend actual sigue funcionando (no se borra slug
--      ni video_url). La PARTE B actualiza las RPCs para EXPONER los campos
--      nuevos; el front los ignora hasta que migres su lógica.
--
--  Recomendado: snapshot previo. Transaccional.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- PARTE A — COLUMNAS, LIMPIEZA Y BACKFILL
-- ---------------------------------------------------------------------

-- 1) Nuevas columnas (idempotente)
ALTER TABLE public.items_eroticos ADD COLUMN IF NOT EXISTS item_type    text;
ALTER TABLE public.items_eroticos ADD COLUMN IF NOT EXISTS external_url text;

-- 2) Limpiar slugs con espacios / saltos de línea (ej: 'adicionales_link_04\r\n')
UPDATE public.items_eroticos
   SET slug = btrim(slug, E' \t\r\n')
 WHERE slug <> btrim(slug, E' \t\r\n');

-- 3) Backfill de item_type según el slug (el orden importa: link antes que instruction)
UPDATE public.items_eroticos
   SET item_type = CASE
     WHEN slug LIKE 'adicionales\_link\_%' THEN 'external_link'
     WHEN slug LIKE 'adicionales\_%'       THEN 'instruction'
     ELSE 'product'
   END;

-- 4) Backfill de external_url para los enlaces (hoy guardado en video_url)
UPDATE public.items_eroticos
   SET external_url = btrim(video_url, E' \t\r\n')
 WHERE item_type = 'external_link'
   AND coalesce(external_url, '') = ''
   AND coalesce(video_url, '')   <> '';

-- 5) Reglas de integridad: default, NOT NULL y CHECK
UPDATE public.items_eroticos SET item_type = 'product' WHERE item_type IS NULL;
ALTER TABLE public.items_eroticos ALTER COLUMN item_type SET DEFAULT 'product';
ALTER TABLE public.items_eroticos ALTER COLUMN item_type SET NOT NULL;

ALTER TABLE public.items_eroticos DROP CONSTRAINT IF EXISTS items_eroticos_item_type_chk;
ALTER TABLE public.items_eroticos
  ADD CONSTRAINT items_eroticos_item_type_chk
  CHECK (item_type IN ('product','instruction','external_link','extra'));

-- 6) Índice de apoyo (tabla pequeña, pero útil para filtros por tipo)
CREATE INDEX IF NOT EXISTS idx_items_eroticos_item_type
  ON public.items_eroticos (item_type);


-- ---------------------------------------------------------------------
-- PARTE B — EXPONER item_type / external_url EN LAS RPCs (additivo)
--   Se agregan los campos al JSON de items. El frontend antiguo los ignora;
--   el nuevo podrá usar item.item_type en vez de slug.startsWith(...).
-- ---------------------------------------------------------------------

-- B.1 get_challenge_full(p_slug)  [SECURITY DEFINER, ya endurecido]
CREATE OR REPLACE FUNCTION public.get_challenge_full(p_slug text)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare result json;
begin
  select json_build_object(
    'id', d.id, 'title', d.title, 'category', d.category, 'description', d.description,
    'media', d.media_url, 'audio', d.audio_url, 'presentation', d.presentation,
    'sku', d.sku, 'back', d.back_url, 'next', d.next_slug,
    'items', coalesce((
       select json_agg(json_build_object(
         'id', i.id, 'name', i.name, 'description', i.description, 'image', i.image_url,
         'audio', i.audio_url, 'video', i.video_url, 'category', i.category,
         'item_type', i.item_type, 'external_url', i.external_url,
         'price', i.price, 'currency', i.currency, 'slug', i.slug) order by di.sort_order, i.name)
       from public.desafio_items di join public.items_eroticos i on i.id = di.item_id
       where di.desafio_id = d.id and i.is_active = true), '[]'::json))
  into result
  from public.desafios d where d.slug = p_slug and d.is_active = true limit 1;
  return result;
end;$function$;

-- B.2 get_challenge_full(p_slug, p_distributor_id)  [SECURITY DEFINER]
CREATE OR REPLACE FUNCTION public.get_challenge_full(p_slug text, p_distributor_id uuid)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare result json;
begin
  select json_build_object(
    'id', d.id, 'title', d.title, 'category', d.category, 'description', d.description,
    'media', d.media_url, 'audio', d.audio_url, 'presentation', d.presentation,
    'sku', d.sku, 'back', d.back_url, 'next', d.next_slug,
    'items', coalesce((
       select json_agg(json_build_object(
         'id', i.id, 'name', i.name, 'description', i.description, 'image', i.image_url,
         'audio', i.audio_url, 'video', i.video_url, 'category', i.category,
         'item_type', i.item_type, 'external_url', i.external_url,
         'price', i.price, 'currency', i.currency, 'slug', i.slug)
         order by di.sort_order nulls last, i.slug, i.name)
       from public.desafio_items di join public.items_eroticos i on i.id = di.item_id
       where di.desafio_id = d.id and di.distributor_id = p_distributor_id and i.is_active = true), '[]'::json))
  into result
  from public.desafios d where d.slug = p_slug and d.is_active = true limit 1;
  return result;
end;$function$;

COMMIT;

-- =====================================================================
-- VERIFICACIÓN (SELECTs)
--   select item_type, count(*) from public.items_eroticos group by item_type;
--   -- esperado aprox: product 13, instruction 3, external_link 7
--   select slug, item_type, external_url from public.items_eroticos
--    where item_type='external_link' order by slug;
-- =====================================================================

-- =====================================================================
-- MIGRACIÓN POSTERIOR DEL FRONTEND (play.html) — cuando estés listo:
--   Sustituir:
--     isInstructionItem(item)          -> item.item_type !== 'product'
--     isInstructionExternalLinkItem(i) -> item.item_type === 'external_link'
--     getInstructionExternalUrl(item)  -> (item.external_url || item.video)
--   Así eliminas la dependencia de los prefijos de slug.
-- =====================================================================
