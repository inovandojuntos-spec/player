-- =====================================================================
--  INOVANDO JUNTOS — CONTENIDO SENSIBLE A BUCKETS PRIVADOS
--  Proyecto: rsordtljnvxonaygyuxd
--
--  ESTADO ACTUAL (auditoría):
--    bucket "contracts"  PUBLIC  -> 45 PDFs de contratos firmados {user_id}/*.pdf  (PII!)
--    bucket "kamasutra"  PUBLIC  -> 94 imágenes de contenido de pago
--    bucket "avatars"    PUBLIC  -> 2 fotos de perfil (se puede dejar público)
--
--  ⚠️  IMPACTO EN LA APP (leer antes de ejecutar)
--    Al pasar un bucket a privado, las URLs ".../object/public/..." dejan de
--    funcionar (403). El contenido se sirve con SIGNED URLs temporales.
--    Hay que ajustar:
--      - get_contract_positions_all / get_user_liked_positions: hoy devuelven
--        URL pública de kamasutra -> deben devolver el PATH y el frontend firma
--        con supabase.storage.from('kamasutra').createSignedUrl(path, 3600).
--      - Recuperación de contratos: usar createSignedUrl sobre el path guardado
--        en contract_responses.pdf_url / signature_image.
--    (Puedo entregarte las RPCs y el JS ya adaptados — pídemelo.)
--
--  RECOMENDACIÓN DE DESPLIEGUE
--    1) Ejecuta primero la PARTE A (contracts) — es la urgente (PII) y NO afecta
--       la navegación principal, solo la descarga del PDF del contrato.
--    2) Ejecuta la PARTE B (kamasutra) junto con el cambio de RPC+frontend.
-- =====================================================================

BEGIN;

-- =====================================================================
-- PARTE A — BUCKET "contracts"  (URGENTE: contiene PII)
-- =====================================================================
UPDATE storage.buckets SET public = false WHERE id = 'contracts';

-- Política: cada usuario solo accede a SUS archivos (carpeta = su user_id).
DROP POLICY IF EXISTS "contracts_owner_select" ON storage.objects;
DROP POLICY IF EXISTS "contracts_owner_insert" ON storage.objects;
DROP POLICY IF EXISTS "contracts_owner_update" ON storage.objects;

CREATE POLICY "contracts_owner_select" ON storage.objects
  FOR SELECT TO authenticated
  USING ( bucket_id = 'contracts'
          AND (storage.foldername(name))[1] = (select auth.uid())::text );

CREATE POLICY "contracts_owner_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK ( bucket_id = 'contracts'
               AND (storage.foldername(name))[1] = (select auth.uid())::text );

CREATE POLICY "contracts_owner_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING ( bucket_id = 'contracts'
          AND (storage.foldername(name))[1] = (select auth.uid())::text );
-- Nota: las Edge Functions / RPCs con service_role siguen pudiendo escribir
--       los PDFs sin problema (service_role ignora RLS).


-- =====================================================================
-- PARTE B — BUCKET "kamasutra"  (contenido de pago)
--   Ejecuta junto con el ajuste de RPC + frontend a signed URLs.
-- =====================================================================
UPDATE storage.buckets SET public = false WHERE id = 'kamasutra';

DROP POLICY IF EXISTS "kamasutra_auth_select" ON storage.objects;
CREATE POLICY "kamasutra_auth_select" ON storage.objects
  FOR SELECT TO authenticated
  USING ( bucket_id = 'kamasutra' );
-- Con esto, un usuario logueado puede generar signed URLs de las imágenes,
-- pero el público anónimo ya no puede leerlas por URL directa.

COMMIT;

-- =====================================================================
-- VERIFICACIÓN
--   select id, public from storage.buckets;            -- contracts/kamasutra = false
--   select policyname from pg_policies
--     where schemaname='storage' and tablename='objects';
-- =====================================================================

-- =====================================================================
-- FASE SIGUIENTE (no en este script) — VIDEOS .mp4 DE PAGO
--   Hoy viven en GitHub Pages (inovandojuntos.com/images/*.mp4) -> descargables
--   sin login. Plan:
--     1) Crear bucket privado, p.ej. "content":
--          insert into storage.buckets (id, name, public) values ('content','content', false);
--     2) Subir los .mp4 (CLI o Dashboard).
--     3) Apuntar items_eroticos.video_url / desafios.media_url al path del bucket.
--     4) Servir con createSignedUrl(path, 3600) desde el reproductor.
--   (Puedo prepararte la migración de rutas + el reproductor con signed URLs.)
-- =====================================================================
