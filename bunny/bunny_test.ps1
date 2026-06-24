# =====================================================================
#  TEST de credenciales Bunny Stream (no sube nada, solo verifica)
#  Uso:
#     cd D:\Calude\player
#     $env:BUNNY_LIBRARY_ID = "690484"
#     $env:BUNNY_API_KEY    = "TU_API_KEY_DE_LA_LIBRERIA"
#     powershell -ExecutionPolicy Bypass -File .\bunny\bunny_test.ps1
# =====================================================================
$ErrorActionPreference = "Stop"

$libraryId = $env:BUNNY_LIBRARY_ID
$apiKey    = $env:BUNNY_API_KEY

Write-Host "Library ID : $libraryId"
if ($apiKey) {
    $len = $apiKey.Length
    $masked = $apiKey.Substring(0,[Math]::Min(4,$len)) + "..." + $apiKey.Substring([Math]::Max(0,$len-4))
    Write-Host "API Key    : $masked  (longitud: $len)"
    if ($apiKey -ne $apiKey.Trim()) { Write-Host "  AVISO: la clave tiene espacios al inicio/fin -> corrige." -ForegroundColor Yellow }
} else {
    Write-Host "API Key    : (VACIA) -> define `$env:BUNNY_API_KEY" -ForegroundColor Red
    return
}

$uri = "https://video.bunnycdn.com/library/$libraryId/videos?page=1&itemsPerPage=1"
Write-Host "`nProbando: GET $uri`n"

try {
    $resp = Invoke-RestMethod -Uri $uri -Method Get -Headers @{ "AccessKey" = $apiKey.Trim() }
    Write-Host "OK - credenciales validas." -ForegroundColor Green
    Write-Host ("Videos actuales en la libreria: {0}" -f $resp.totalItems)
    Write-Host "`nYa puedes correr:  .\bunny\bunny_upload.ps1"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Write-Host "FALLO (HTTP $code): $($_.Exception.Message)" -ForegroundColor Red
    if ($code -eq 401) {
        Write-Host "`n401 = clave incorrecta. Revisa que sea la API Key DE LA LIBRERIA:" -ForegroundColor Yellow
        Write-Host "  Bunny -> Stream -> libreria 'IJ' -> pestana 'API' -> 'API Key'"
        Write-Host "  (NO la 'Token authentication key', NI la API key de la cuenta)."
    }
}
