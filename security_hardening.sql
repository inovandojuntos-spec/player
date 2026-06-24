-- =====================================================================
--  INOVANDO JUNTOS — SCRIPT DE BLINDAJE DE SEGURIDAD (Supabase / Postgres 17)
--  Proyecto: rsordtljnvxonaygyuxd
--  Generado: auditoría 2026-06-24
--
--  OBJETIVO
--    1) Quitar la suplantación de identidad en las RPCs (usar auth.uid()).
--    2) Cerrar el acceso anónimo a las funciones.
--    3) Activar RLS en las 18 tablas hoy expuestas.
--    4) Endurecer search_path y la vista SECURITY DEFINER.
--
--  COMPATIBILIDAD
--    - Se conservan las MISMAS firmas de funciones -> el frontend NO requiere cambios.
--    - Las tablas bloqueadas se acceden solo vía RPCs SECURITY DEFINER (que las leen sin RLS).
--    - Acceso directo del frontend (profiles, contract_questions, contract_responses)
--      ya tiene RLS y NO se toca.
--
--  ANTES DE EJECUTAR  (IMPRESCINDIBLE)
--    [ ] Toma un snapshot / backup del proyecto.
--    [ ] Confirma que las Edge Functions usan la SERVICE_ROLE key:
--          - IJ_events           -> inserta en public.ij_events
--          - registrar-cliente-brazil -> inserta en public.clientes_brazil
--          - snapshot            -> escribe en public.roulette_snapshots
--        service_role IGNORA RLS, así que seguirán funcionando. Si alguna usa la
--        anon key para INSERT directo, cámbiala a service_role ANTES de correr esto.
--    [ ] Ejecuta en un branch de Supabase primero si puedes.
--
--  DESPUÉS DE EJECUTAR
--    [ ] Dashboard -> Authentication -> Policies/Settings: activa
--        "Leaked password protection" (HaveIBeenPwned).
--    [ ] Smoke test: login, dar like, comentar, activar un código.
--    [ ] (Aparte) Proteger los .mp4 de pago con Storage privado + signed URLs.
-- =====================================================================

BEGIN;

-- =====================================================================
-- PARTE 1 — CERRAR EJECUCIÓN ANÓNIMA DE LAS RPCs  (mayor impacto inmediato)
--   La app exige login: ningún RPC necesita el rol anon.
--   Revocamos de anon y public; concedemos solo a authenticated.
-- =====================================================================

REVOKE EXECUTE ON FUNCTION public.toggle_target_like(uuid, text, uuid)                 FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.toggle_target_favorite(uuid, text, uuid)             FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.add_target_comment(uuid, text, uuid, text)           FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.create_target_comment(uuid, text, uuid, text, jsonb) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.register_target_whatsapp(uuid, text, uuid, text, text, text, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.activate_profile_with_code(uuid, text)               FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.check_activation_code_available(text)                FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_user_liked_positions(uuid)                       FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_contract_positions_all(uuid)                     FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_target_interaction_bundle(text, uuid, uuid)      FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_target_comments(text, uuid, integer, integer)    FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_kamasutra_positions(integer, boolean)            FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_challenge_full(text)                             FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_challenge_full(text, uuid)                       FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_movies()                                         FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_my_desafios_progress()                           FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.mark_desafio_played(uuid)                            FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_contract_response(text)                          FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_contract_template(text)                          FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.save_contract_response(text, jsonb, text, boolean)   FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.save_contract_response(text, jsonb, text, boolean, text, text) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.toggle_target_like(uuid, text, uuid)                 TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_target_favorite(uuid, text, uuid)             TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_target_comment(uuid, text, uuid, text)           TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_target_comment(uuid, text, uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.register_target_whatsapp(uuid, text, uuid, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activate_profile_with_code(uuid, text)               TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_activation_code_available(text)                TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_liked_positions(uuid)                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_contract_positions_all(uuid)                     TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_target_interaction_bundle(text, uuid, uuid)      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_target_comments(text, uuid, integer, integer)    TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_kamasutra_positions(integer, boolean)            TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_challenge_full(text)                             TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_challenge_full(text, uuid)                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_movies()                                         TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_desafios_progress()                           TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_desafio_played(uuid)                            TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_contract_response(text)                          TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_contract_template(text)                          TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_contract_response(text, jsonb, text, boolean)   TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_contract_response(text, jsonb, text, boolean, text, text) TO authenticated;

-- Función interna: nadie debe poder llamarla por API.
REVOKE EXECUTE ON FUNCTION public.recalc_target_stats(text, uuid) FROM anon, authenticated, public;


-- =====================================================================
-- PARTE 2 — REESCRITURA DE FUNCIONES: usar auth.uid() en vez de p_user_id
--   Se mantiene la firma (el frontend sigue mandando p_user_id, pero se IGNORA).
--   Esto elimina la suplantación de identidad / IDOR.
-- =====================================================================

-- 2.1 toggle_target_like ------------------------------------------------
CREATE OR REPLACE FUNCTION public.toggle_target_like(p_user_id uuid, p_target_type text, p_target_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare v_uid uuid; v_exists boolean; v_liked boolean;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'not_authenticated'; end if;

  select exists(select 1 from public.target_likes
                where user_id = v_uid and target_type = p_target_type and target_id = p_target_id)
    into v_exists;

  if v_exists then
    delete from public.target_likes
      where user_id = v_uid and target_type = p_target_type and target_id = p_target_id;
    insert into public.target_events_log(user_id, target_type, target_id, event_type)
      values (v_uid, p_target_type, p_target_id, 'unlike');
    insert into public.target_stats(target_type, target_id, likes_count, updated_at)
      values (p_target_type, p_target_id, 0, now())
      on conflict (target_type, target_id) do update
        set likes_count = greatest(public.target_stats.likes_count - 1, 0), updated_at = now();
    v_liked := false;
  else
    insert into public.target_likes(user_id, target_type, target_id)
      values (v_uid, p_target_type, p_target_id);
    insert into public.target_events_log(user_id, target_type, target_id, event_type)
      values (v_uid, p_target_type, p_target_id, 'like');
    insert into public.target_stats(target_type, target_id, likes_count, updated_at)
      values (p_target_type, p_target_id, 1, now())
      on conflict (target_type, target_id) do update
        set likes_count = public.target_stats.likes_count + 1, updated_at = now();
    v_liked := true;
  end if;

  return public.get_target_interaction_bundle(p_target_type, p_target_id, v_uid)
    || jsonb_build_object('ok', true, 'target_type', p_target_type, 'target_id', p_target_id);
end;$function$;

-- 2.2 toggle_target_favorite (también pasa a SECURITY DEFINER) -----------
CREATE OR REPLACE FUNCTION public.toggle_target_favorite(p_user_id uuid, p_target_type text, p_target_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare v_uid uuid; v_exists boolean; v_favorited boolean;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'not_authenticated'; end if;

  select exists(select 1 from public.target_favorites
                where user_id = v_uid and target_type = p_target_type and target_id = p_target_id)
    into v_exists;

  if v_exists then
    delete from public.target_favorites
      where user_id = v_uid and target_type = p_target_type and target_id = p_target_id;
    insert into public.target_events_log(user_id, target_type, target_id, event_type)
      values (v_uid, p_target_type, p_target_id, 'unfavorite');
    insert into public.target_stats(target_type, target_id, favorites_count, updated_at)
      values (p_target_type, p_target_id, 0, now())
      on conflict (target_type, target_id) do update
        set favorites_count = greatest(public.target_stats.favorites_count - 1, 0), updated_at = now();
    v_favorited := false;
  else
    insert into public.target_favorites(user_id, target_type, target_id)
      values (v_uid, p_target_type, p_target_id);
    insert into public.target_events_log(user_id, target_type, target_id, event_type)
      values (v_uid, p_target_type, p_target_id, 'favorite');
    insert into public.target_stats(target_type, target_id, favorites_count, updated_at)
      values (p_target_type, p_target_id, 1, now())
      on conflict (target_type, target_id) do update
        set favorites_count = public.target_stats.favorites_count + 1, updated_at = now();
    v_favorited := true;
  end if;

  return public.get_target_interaction_bundle(p_target_type, p_target_id, v_uid)
    || jsonb_build_object('ok', true, 'target_type', p_target_type, 'target_id', p_target_id);
end;$function$;

-- 2.3 add_target_comment ------------------------------------------------
CREATE OR REPLACE FUNCTION public.add_target_comment(p_user_id uuid, p_target_type text, p_target_id uuid, p_body text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare v_uid uuid; v_comment_id uuid; v_comment_count int;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if coalesce(trim(p_body), '') = '' then raise exception 'Comment body is required'; end if;

  insert into public.target_comments(user_id, target_type, target_id, body)
    values (v_uid, p_target_type, p_target_id, trim(p_body))
    returning id into v_comment_id;
  insert into public.target_events_log(user_id, target_type, target_id, event_type, metadata)
    values (v_uid, p_target_type, p_target_id, 'comment_created',
            jsonb_build_object('comment_id', v_comment_id));
  perform public.recalc_target_stats(p_target_type, p_target_id);

  select count(*) into v_comment_count from public.target_comments
    where target_type = p_target_type and target_id = p_target_id and coalesce(is_deleted,false)=false;

  return jsonb_build_object('ok', true, 'comment_id', v_comment_id, 'comment_count', v_comment_count);
end;$function$;

-- 2.4 create_target_comment --------------------------------------------
CREATE OR REPLACE FUNCTION public.create_target_comment(p_user_id uuid, p_target_type text, p_target_id uuid, p_body text, p_metadata jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare v_uid uuid; v_comment_id uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if coalesce(trim(p_body), '') = '' then raise exception 'Comment body is required'; end if;

  insert into public.target_comments(user_id, target_type, target_id, body)
    values (v_uid, p_target_type, p_target_id, trim(p_body))
    returning id into v_comment_id;
  insert into public.target_events_log(user_id, target_type, target_id, event_type, metadata)
    values (v_uid, p_target_type, p_target_id, 'comment_created',
            coalesce(p_metadata,'{}'::jsonb) || jsonb_build_object('comment_id', v_comment_id));
  perform public.recalc_target_stats(p_target_type, p_target_id);

  return jsonb_build_object('ok', true, 'comment_id', v_comment_id);
end;$function$;

-- 2.5 register_target_whatsapp (también pasa a SECURITY DEFINER) ---------
CREATE OR REPLACE FUNCTION public.register_target_whatsapp(p_user_id uuid, p_target_type text, p_target_id uuid, p_phone_number text, p_source text DEFAULT 'player'::text, p_session_id text DEFAULT NULL::text, p_user_agent text DEFAULT NULL::text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare v_uid uuid; v_product_name text; v_message_text text; v_whatsapp_url text; v_wp_click_count integer; v_phone_clean text;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'not_authenticated'; end if;

  v_phone_clean := regexp_replace(coalesce(p_phone_number,''), '[^0-9]', '', 'g');

  if    p_target_type = 'item'      then select i.name   into v_product_name from public.items_eroticos i where i.id = p_target_id;
  elsif p_target_type = 'challenge' then select d.title  into v_product_name from public.desafios d       where d.id = p_target_id;
  elsif p_target_type = 'position'  then select p.nombre into v_product_name from public.posiciones p     where p.id = p_target_id;
  else  v_product_name := null; end if;
  if v_product_name is null or btrim(v_product_name) = '' then v_product_name := 'Produto'; end if;

  v_message_text := format('Olá, tenho interesse neste produto: %s', v_product_name);
  v_whatsapp_url := 'https://wa.me/' || v_phone_clean || '?text=' ||
    replace(replace(replace(v_message_text,'%','%25'),' ','%20'), E'\n','%0A');

  insert into public.target_whatsapp(user_id, target_type, target_id, phone_number, whatsapp_url, source, metadata)
    values (v_uid, p_target_type, p_target_id, v_phone_clean, v_whatsapp_url, p_source,
            jsonb_build_object('product_name',v_product_name,'message_text',v_message_text,'session_id',p_session_id,'user_agent',p_user_agent));
  insert into public.target_events_log(user_id, target_type, target_id, event_type, metadata)
    values (v_uid, p_target_type, p_target_id, 'wp_click',
            jsonb_build_object('phone_number',v_phone_clean,'product_name',v_product_name,'message_text',v_message_text,'whatsapp_url',v_whatsapp_url,'source',p_source,'session_id',p_session_id,'user_agent',p_user_agent));
  insert into public.target_stats(target_type, target_id, wp_click_count, updated_at)
    values (p_target_type, p_target_id, 1, now())
    on conflict (target_type, target_id) do update
      set wp_click_count = coalesce(public.target_stats.wp_click_count,0)+1, updated_at = now();

  select coalesce(ts.wp_click_count,0) into v_wp_click_count
    from public.target_stats ts where ts.target_type = p_target_type and ts.target_id = p_target_id;

  return jsonb_build_object('ok',true,'target_type',p_target_type,'target_id',p_target_id,
    'product_name',v_product_name,'message_text',v_message_text,'whatsapp_url',v_whatsapp_url,
    'wp_click_count', coalesce(v_wp_click_count,0));
end;$function$;

-- 2.6 activate_profile_with_code  (clave para la monetización) -----------
CREATE OR REPLACE FUNCTION public.activate_profile_with_code(p_user_id uuid, p_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare v_uid uuid; v_code public.activation_codes%rowtype; v_profile public.profiles%rowtype; v_clean_code text;
begin
  v_uid := auth.uid();
  if v_uid is null then
    return jsonb_build_object('ok',false,'error','not_authenticated','message','Usuário não autenticado.');
  end if;

  v_clean_code := upper(trim(p_code));
  if v_clean_code is null or v_clean_code = '' then
    return jsonb_build_object('ok',false,'error','codigo_vazio','message','Informe um código de ativação.');
  end if;

  select * into v_profile from public.profiles where id = v_uid;
  if not found then
    return jsonb_build_object('ok',false,'error','perfil_nao_encontrado','message','Perfil de usuário não encontrado.');
  end if;
  if v_profile.is_activated = true and v_profile.activation_code_id is not null then
    return jsonb_build_object('ok',false,'error','perfil_ja_ativado','message','Este perfil já foi ativado com um código.');
  end if;

  select * into v_code from public.activation_codes where code = v_clean_code and is_active = true for update;
  if not found then
    return jsonb_build_object('ok',false,'error','codigo_invalido','message','Código de ativação inválido.');
  end if;
  if v_code.expires_at is not null and v_code.expires_at < now() then
    return jsonb_build_object('ok',false,'error','codigo_expirado','message','Este código de ativação expirou.');
  end if;
  if v_code.used_count >= v_code.max_uses then
    return jsonb_build_object('ok',false,'error','limite_atingido','message','Este código já atingiu o limite de ativações.');
  end if;

  update public.profiles
     set activation_code_id = v_code.id, distributor_id = v_code.distributor_id,
         is_activated = true, activated_at = now(), updated_at = now()
   where id = v_uid;
  update public.activation_codes
     set used_count = used_count + 1, first_used_at = coalesce(first_used_at, now()),
         last_used_at = now(), updated_at = now()
   where id = v_code.id;

  insert into public.profile_desafios (profile_id, desafio_id)
    select v_uid, d.id from public.desafios d
     where d.is_active = true and d.id <> '16859d64-1209-4b70-8de4-e8d16f8c8df7'
    on conflict (profile_id, desafio_id) do nothing;

  return jsonb_build_object('ok',true,'message','Código ativado com sucesso.',
    'activation_code_id',v_code.id,'distributor_id',v_code.distributor_id,
    'used_count',v_code.used_count + 1,'max_uses',v_code.max_uses);
end;$function$;

-- 2.7 get_user_liked_positions (IDOR de lectura) ------------------------
CREATE OR REPLACE FUNCTION public.get_user_liked_positions(p_user_id uuid)
RETURNS TABLE(posicion_id uuid, numero integer, slug text, nombre text, nivel integer, grupo text, image_url text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $function$
  select p.id, p.numero, p.slug, p.nombre, p.nivel, p.grupo,
         'https://rsordtljnvxonaygyuxd.supabase.co/storage/v1/object/public/kamasutra/Kamasutra_pos_' || lpad(p.numero::text,2,'0') || '.png'
  from public.target_likes tl
  join public.posiciones p on p.id = tl.target_id
  where tl.user_id = auth.uid() and tl.target_type = 'position'
  order by p.numero;
$function$;

-- 2.8 get_contract_positions_all (IDOR de lectura) ----------------------
CREATE OR REPLACE FUNCTION public.get_contract_positions_all(p_user_id uuid)
RETURNS TABLE(posicion_id uuid, numero integer, slug text, nombre text, nivel text, grupo text, image_url text, is_liked boolean, likes_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $function$
  SELECT p.id, p.numero, p.slug, p.nombre, p.nivel, p.grupo,
    'https://rsordtljnvxonaygyuxd.supabase.co/storage/v1/object/public/kamasutra/Kamasutra_pos_' || lpad(p.numero::text,2,'0') || '.png',
    EXISTS (SELECT 1 FROM public.target_likes tl
              WHERE tl.user_id = auth.uid() AND tl.target_type = 'position' AND tl.target_id = p.id) AS is_liked,
    COALESCE(lc.likes_count, 0)
  FROM public.posiciones p
  LEFT JOIN (SELECT target_id, COUNT(*)::bigint AS likes_count
               FROM public.target_likes WHERE target_type = 'position' GROUP BY target_id) lc
    ON lc.target_id = p.id
  ORDER BY is_liked DESC, COALESCE(lc.likes_count,0) DESC, p.numero ASC;
$function$;

-- 2.9 get_target_interaction_bundle (usa auth.uid() para liked/favorited)
CREATE OR REPLACE FUNCTION public.get_target_interaction_bundle(p_target_type text, p_target_id uuid, p_user_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare v_uid uuid;
  v_like_count int := 0; v_comment_count int := 0; v_favorite_count int := 0; v_whatsapp_count int := 0;
  v_liked boolean := false; v_favorited boolean := false;
  v_like_base int := 0; v_favorite_base int := 0;
begin
  v_uid := auth.uid();  -- se ignora p_user_id; el estado liked/favorited es del usuario autenticado

  select coalesce(ts.likes_count,0), coalesce(ts.comments_count,0),
         coalesce(ts.favorites_count,0), coalesce(ts.wp_click_count,0)
    into v_like_count, v_comment_count, v_favorite_count, v_whatsapp_count
    from public.target_stats ts
   where ts.target_type = p_target_type and ts.target_id = p_target_id;

  case p_target_type
    when 'desafio'  then v_like_base := 120; v_favorite_base := 35;
    when 'item'     then v_like_base := 80;  v_favorite_base := 20;
    when 'position' then v_like_base := 60;  v_favorite_base := 15;
    else                 v_like_base := 30;  v_favorite_base := 10;
  end case;

  if v_uid is not null then
    select exists(select 1 from public.target_likes tl
       where tl.target_type=p_target_type and tl.target_id=p_target_id and tl.user_id=v_uid) into v_liked;
    select exists(select 1 from public.target_favorites tf
       where tf.target_type=p_target_type and tf.target_id=p_target_id and tf.user_id=v_uid) into v_favorited;
  end if;

  return jsonb_build_object(
    'like_count', coalesce(v_like_count,0) + v_like_base,
    'comment_count', coalesce(v_comment_count,0),
    'favorite_count', coalesce(v_favorite_count,0) + v_favorite_base,
    'whatsapp_count', coalesce(v_whatsapp_count,0),
    'wp_click_count', coalesce(v_whatsapp_count,0),
    'liked', v_liked, 'favorited', v_favorited);
end;$function$;


-- =====================================================================
-- PARTE 3 — FUNCIONES DE SOLO-LECTURA QUE LEEN TABLAS QUE QUEDARÁN CON RLS
--   Deben ser SECURITY DEFINER para poder leer las tablas bloqueadas.
--   (No manejan identidad de usuario, así que no hay riesgo de IDOR.)
-- =====================================================================

-- 3.1 get_kamasutra_positions (era SECURITY INVOKER) --------------------
CREATE OR REPLACE FUNCTION public.get_kamasutra_positions(p_nivel integer DEFAULT NULL::integer, p_cadera boolean DEFAULT NULL::boolean)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare result json;
begin
  select json_build_object(
    'count', count(*),
    'data', json_agg(json_build_object(
       'id', q.id, 'numero', q.numero, 'nombre', q.nombre, 'nivel', q.nivel,
       'requiere_cadera', q.requiere_cadera,
       'svg', 'images/Kamasutra_pos_' || lpad(q.numero::text,2,'0') || '.svg') order by q.rnd)
  ) into result
  from (select id,numero,nombre,nivel,requiere_cadera, random() as rnd
          from public.posiciones
         where (p_nivel is null or nivel = p_nivel)
           and (p_cadera is null or requiere_cadera = p_cadera)) q;
  return result;
end;$function$;

-- 3.2 get_challenge_full(p_slug) — versión de 1 argumento ---------------
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
         'price', i.price, 'currency', i.currency, 'slug', i.slug) order by di.sort_order, i.name)
       from public.desafio_items di join public.items_eroticos i on i.id = di.item_id
       where di.desafio_id = d.id and i.is_active = true), '[]'::json))
  into result
  from public.desafios d where d.slug = p_slug and d.is_active = true limit 1;
  return result;
end;$function$;

-- 3.3 Asegurar search_path en el resto de funciones DEFINER ------------
ALTER FUNCTION public.get_challenge_full(text, uuid)              SET search_path = 'public';
ALTER FUNCTION public.get_movies()                               SET search_path = 'public';
ALTER FUNCTION public.get_target_comments(text, uuid, integer, integer) SET search_path = 'public';
ALTER FUNCTION public.save_contract_response(text, jsonb, text, boolean) SET search_path = 'public';
-- (recalc_target_stats / handle_new_user: añade SET search_path = 'public' si aún no lo tienen)


-- =====================================================================
-- PARTE 4 — ACTIVAR ROW LEVEL SECURITY EN LAS 18 TABLAS EXPUESTAS
--   Acceso solo vía RPCs SECURITY DEFINER (que ya bypassean RLS) o
--   vía Edge Functions con service_role. Sin políticas = acceso directo
--   con anon/authenticated queda BLOQUEADO (que es lo deseado).
-- =====================================================================

ALTER TABLE public.ij_events             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_brazil       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.desafios              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items_eroticos        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.desafio_items         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posiciones            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posicion_interacciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.target_likes          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.target_done           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.target_comments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.target_stats          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.target_favorites      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.target_whatsapp       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.target_events_log     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_desafios      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movies                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contract_templates    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.internal_seed_users   ENABLE ROW LEVEL SECURITY;

-- Nota: target_likes, target_comments y target_stats ya tenían policies
-- (para authenticated, por dueño). Se conservan y ahora SÍ tienen efecto.


-- =====================================================================
-- PARTE 5 — VISTA SECURITY DEFINER
--   posiciones_stats: convertir a security_invoker para no exponer datos
--   con privilegios del creador. (No la usa el frontend.)
-- =====================================================================
ALTER VIEW public.posiciones_stats SET (security_invoker = on);

COMMIT;

-- =====================================================================
-- PARTE 6 — VERIFICACIÓN (ejecutar DESPUÉS del COMMIT; son solo SELECTs)
-- =====================================================================
-- 6.1 ¿Quedan tablas públicas sin RLS?
-- select relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
--  where n.nspname='public' and c.relkind='r' and c.relrowsecurity=false;
--
-- 6.2 ¿Alguna función sigue ejecutable por anon?
-- select p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
--  where n.nspname='public'
--    and has_function_privilege('anon', p.oid, 'EXECUTE');
--
-- 6.3 Repite get_advisors (security) y confirma 0 errores críticos.
-- =====================================================================
