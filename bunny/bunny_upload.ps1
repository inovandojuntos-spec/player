# =====================================================================
#  Subida masiva de videos a Bunny Stream (PowerShell, Windows)
#  + genera bunny_guid_map.csv (archivo -> GUID)
#
#  CÓMO USARLO:
#   1) Abre PowerShell.
#   2) Ve a la carpeta del proyecto:
#         cd D:\Calude\player
#   3) Pon tus datos (Library ID 690484 y tu API Key de Stream > API):
#         $env:BUNNY_LIBRARY_ID = "690484"
#         $env:BUNNY_API_KEY    = "TU_API_KEY"
#   4) Ejecuta el script:
#         powershell -ExecutionPolicy Bypass -File .\bunny\bunny_upload.ps1
#
#  Resultado: bunny\bunny_guid_map.csv  -> me lo pasas.
#  NO compartas tu API Key. Esto corre solo en tu PC.
# =====================================================================

$ErrorActionPreference = "Stop"

if (-not $env:BUNNY_LIBRARY_ID) { throw "Falta `$env:BUNNY_LIBRARY_ID (ej: 690484)" }
if (-not $env:BUNNY_API_KEY)    { throw "Falta `$env:BUNNY_API_KEY" }

$libraryId = $env:BUNNY_LIBRARY_ID
$apiKey    = $env:BUNNY_API_KEY
$srcDir    = "images"
$outFile   = "bunny\bunny_guid_map.csv"
$api       = "https://video.bunnycdn.com/library/$libraryId/videos"

New-Item -ItemType Directory -Force -Path "bunny" | Out-Null
"filename,guid" | Out-File -FilePath $outFile -Encoding utf8

$videos = Get-ChildItem -Path $srcDir -Filter *.mp4
Write-Host "Encontrados $($videos.Count) videos en $srcDir`n"

foreach ($f in $videos) {
    $title = $f.BaseName
    Write-Host "-> Creando: $title"

    # 1) Crear el objeto video (devuelve guid)
    try {
        $created = Invoke-RestMethod -Uri $api -Method Post `
            -Headers @{ "AccessKey" = $apiKey } `
            -ContentType "application/json" `
            -Body (@{ title = $title } | ConvertTo-Json)
    } catch {
        Write-Host "   x Error creando $title : $($_.Exception.Message)"; continue
    }

    $guid = $created.guid
    if (-not $guid) { Write-Host "   x Sin GUID para $title"; continue }

    # 2) Subir el binario
    try {
        Invoke-RestMethod -Uri "$api/$guid" -Method Put `
            -Headers @{ "AccessKey" = $apiKey } `
            -InFile $f.FullName -ContentType "application/octet-stream" | Out-Null
        Write-Host "   OK $($f.Name) -> $guid"
        "$($f.Name),$guid" | Out-File -FilePath $outFile -Append -Encoding utf8
    } catch {
        Write-Host "   x Fallo subida $($f.Name): $($_.Exception.Message)"
    }
}

Write-Host "`nListo. Mapeo en: $outFile"
Write-Host "Bunny transcodifica a HLS automaticamente (puede tardar unos minutos)."
