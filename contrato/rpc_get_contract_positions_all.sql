-- RPC para cargar TODAS las posiciones disponibles en el contrato.
-- Orden: primero las curtidas por el usuario; luego las demás por cantidad total de curtidas.

DROP FUNCTION IF EXISTS public.get_contract_positions_all(uuid);

CREATE OR REPLACE FUNCTION public.get_contract_positions_all(p_user_id uuid)
RETURNS TABLE (
    posicion_id uuid,
    numero integer,
    slug text,
    nombre text,
    nivel text,
    grupo text,
    image_url text,
    is_liked boolean,
    likes_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        p.id AS posicion_id,
        p.numero,
        p.slug,
        p.nombre,
        p.nivel,
        p.grupo,
        'https://rsordtljnvxonaygyuxd.supabase.co/storage/v1/object/public/kamasutra/Kamasutra_pos_'
        || lpad(p.numero::text, 2, '0')
        || '.png' AS image_url,
        EXISTS (
            SELECT 1
            FROM public.target_likes tl_user
            WHERE tl_user.user_id = p_user_id
              AND tl_user.target_type = 'position'
              AND tl_user.target_id = p.id
        ) AS is_liked,
        COALESCE(lc.likes_count, 0) AS likes_count
    FROM public.posiciones p
    LEFT JOIN (
        SELECT
            target_id,
            COUNT(*)::bigint AS likes_count
        FROM public.target_likes
        WHERE target_type = 'position'
        GROUP BY target_id
    ) lc ON lc.target_id = p.id
    ORDER BY
        is_liked DESC,
        COALESCE(lc.likes_count, 0) DESC,
        p.numero ASC;
$$;

GRANT EXECUTE ON FUNCTION public.get_contract_positions_all(uuid) TO anon, authenticated;

-- Prueba rápida desde SQL Editor, reemplaza el UUID:
-- SELECT * FROM public.get_contract_positions_all('00000000-0000-0000-0000-000000000000');
