// =====================================================================
//  Edge Function: get-video-url   (Bunny Stream — CDN Token Auth, Advanced/HMAC)
//  Devuelve una URL HLS FIRMADA y temporal solo a usuarios autenticados.
//  Usa "directory token" en formato path-based -> los segmentos .ts del HLS
//  heredan la autenticación automáticamente (requisito para video streaming).
//
//  Requisitos en Bunny (Stream > Security):
//    - "CDN token authentication"  = ON
//    - "Block direct url file access" = ON (recomendado)
//    - Copia la "Token authentication key"
//
//  Despliegue (Supabase CLI):
//     supabase functions deploy get-video-url
//     supabase secrets set BUNNY_CDN_HOSTNAME="vz-xxxxx.b-cdn.net"
//     supabase secrets set BUNNY_TOKEN_KEY="<Token authentication key>"
//   (verify_jwt = true por defecto -> exige login)
//
//  Frontend:
//     const { data } = await supabase.functions.invoke('get-video-url',
//        { body: { guid: '<bunny_guid>' } });
//     // data.url -> reproducir con hls.js
// =====================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const HOSTNAME  = Deno.env.get("BUNNY_CDN_HOSTNAME")!;   // vz-xxxxx.b-cdn.net
const TOKEN_KEY = Deno.env.get("BUNNY_TOKEN_KEY")!;      // Token authentication key
const TTL = 60 * 60;                                     // 1 hora

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

// Bunny Advanced Token Auth (HMAC-SHA256), directory + path-based para HLS.
// token = "HS256-" + base64url( HMAC_SHA256(key, signature_path + expires + signing_data + user_ip) )
async function signDirectoryUrl(guid: string): Promise<string> {
  const dir = `/${guid}/`;                 // token_path (directorio del video)
  const file = "playlist.m3u8";            // master HLS de Bunny Stream
  const expires = Math.floor(Date.now() / 1000) + TTL;
  const signaturePath = dir;
  const signingData = `token_path=${dir}`; // único parámetro (sin token/expires), valor crudo
  const userIp = "";

  const message = `${signaturePath}${expires}${signingData}${userIp}`;
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(TOKEN_KEY),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  const token = "HS256-" + b64url(new Uint8Array(sig));

  // Formato path-based: el token va en el path para que el player firme los segmentos
  return `https://${HOSTNAME}/bcdn_token=${token}&expires=${expires}` +
         `&token_path=${encodeURIComponent(dir)}/${guid}/${file}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "not_authenticated" }),
        { status: 401, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const { guid } = await req.json();
    if (!guid || !/^[a-f0-9-]{36}$/i.test(guid)) {
      return new Response(JSON.stringify({ error: "invalid_guid" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }

    const url = await signDirectoryUrl(guid);
    return new Response(JSON.stringify({ url, type: "hls" }),
      { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
