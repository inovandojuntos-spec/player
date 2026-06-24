#!/usr/bin/env bash
# =====================================================================
#  Subida masiva de videos a Bunny Stream + mapeo archivo -> GUID
#  Uso (desde la carpeta player/):
#     export BUNNY_LIBRARY_ID="123456"
#     export BUNNY_API_KEY="xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx"
#     bash bunny/bunny_upload.sh
#
#  Requisitos: bash, curl, jq
#  NO compartas tu API key. Este script corre en tu máquina.
#  Resultado: bunny/bunny_guid_map.csv  (filename,guid)  -> me lo pasas.
# =====================================================================
set -euo pipefail

: "${BUNNY_LIBRARY_ID:?Define BUNNY_LIBRARY_ID}"
: "${BUNNY_API_KEY:?Define BUNNY_API_KEY}"

SRC_DIR="images"          # carpeta donde están los .mp4
OUT="bunny/bunny_guid_map.csv"
API="https://video.bunnycdn.com/library/${BUNNY_LIBRARY_ID}/videos"

mkdir -p bunny
echo "filename,guid" > "$OUT"

shopt -s nullglob
for f in "$SRC_DIR"/*.mp4; do
  base="$(basename "$f")"
  title="${base%.mp4}"
  echo "→ Creando: $title"

  # 1) Crear el objeto video (devuelve guid)
  guid="$(curl -s -X POST "$API" \
      -H "AccessKey: ${BUNNY_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"title\":\"${title}\"}" | jq -r '.guid')"

  if [ -z "$guid" ] || [ "$guid" = "null" ]; then
    echo "  ✗ Error creando $title"; continue
  fi

  # 2) Subir el binario
  http="$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${API}/${guid}" \
      -H "AccessKey: ${BUNNY_API_KEY}" \
      --data-binary @"$f")"

  if [ "$http" = "200" ]; then
    echo "  ✓ $base -> $guid"
    echo "${base},${guid}" >> "$OUT"
  else
    echo "  ✗ Falló subida de $base (HTTP $http)"
  fi
done

echo ""
echo "Listo. Mapeo en: $OUT"
echo "Bunny transcodifica a HLS automáticamente (puede tardar unos minutos)."
