<#
.SYNOPSIS
  Sube archivos de una fuente (lyfta, demic, synaptixfit, musculos) a Cloudflare R2.
  Para ejercicios lee URLs del dataset_final.json; para musculos lee musculos.json.

.PARAMETER Source
  Fuente a subir: "lyfta", "demic", "synaptixfit", o "musculos".

.PARAMETER PreviewsOnly
  Sube solo las previews (imágenes .webp).

.PARAMETER VideosOnly
  Sube solo los videos (.mp4).

.EJEMPLO
  .\upload_media_r2.ps1 -Source lyfta
  .\upload_media_r2.ps1 -Source demic -PreviewsOnly
  .\upload_media_r2.ps1 -Source musculos
#>

param(
    [Parameter(Mandatory)]
        [ValidateSet("lyfta", "demic", "synaptixfit", "musculos")]
        [string]$Source,

    [switch]$PreviewsOnly,
    [switch]$VideosOnly
)

$BUCKET = "synaptixfit"

# Mapeo fuente -> directorio local
$SOURCE_DIRS = @{
    lyfta        = "D:\Dataset\Deporte\lyfta"
    demic        = "D:\Dataset\Deporte\demic"
    synaptixfit  = "D:\Dataset\Deporte\synaptixfit"
    musculos     = "D:\Dataset\Deporte\musculos\webp"
}

$BASE_DIR = $SOURCE_DIRS[$Source]

if (-not (Test-Path $BASE_DIR)) {
    Write-Host "[ERROR] Directorio no encontrado: $BASE_DIR" -ForegroundColor Red
    exit 1
}

# Construir lista de subida
$upload = @()
$notFound = @()

if ($Source -eq "musculos") {
    $musculosJson = Get-Content -Path "supabase/musculos.json" -Encoding UTF8 | ConvertFrom-Json

    foreach ($m in $musculosJson) {
        if (-not $m.url_imagen) { continue }
        $key = ($m.url_imagen -split "ejercicios/")[1]
        $fname = $key -split "/" | Select-Object -Last 1
        $local = Join-Path $BASE_DIR $fname
        if (Test-Path $local) {
            $upload += [PSCustomObject]@{ Type = "preview"; Key = "ejercicios/$key"; Path = $local }
        } else {
            $notFound += "preview: $fname ($($m.nombre))"
        }
    }
} else {
    $json = Get-Content -Path "supabase/dataset_final.json" -Encoding UTF8 | ConvertFrom-Json

    foreach ($e in $json) {
        if ($e.fuente -ne $Source) { continue }

        if (-not $VideosOnly -and $e.url_preview) {
            $key = ($e.url_preview -split "ejercicios/")[1]
            $fname = $key -split "/" | Select-Object -Last 1
            $local = Get-ChildItem -LiteralPath $BASE_DIR -Recurse -Filter $fname -File | Select-Object -First 1 -ExpandProperty FullName
            if ($local) {
                $upload += [PSCustomObject]@{ Type = "preview"; Key = "ejercicios/$key"; Path = $local }
            } else {
                $notFound += "preview: $fname ($($e.nombre_ejercicio))"
            }
        }

        if (-not $PreviewsOnly -and $e.url_video) {
            $key = ($e.url_video -split "ejercicios/")[1]
            $fname = $key -split "/" | Select-Object -Last 1
            $local = Get-ChildItem -LiteralPath $BASE_DIR -Recurse -Filter $fname -File | Select-Object -First 1 -ExpandProperty FullName
            if ($local) {
                $upload += [PSCustomObject]@{ Type = "video"; Key = "ejercicios/$key"; Path = $local }
            } else {
                $notFound += "video: $fname ($($e.nombre_ejercicio))"
            }
        }
    }
}

$total = $upload.Count
$pCount = ($upload | Where-Object { $_.Type -eq "preview" }).Count
$vCount = ($upload | Where-Object { $_.Type -eq "video" }).Count

Write-Host "=== Subida $Source a Cloudflare R2 ($BUCKET) ===" -ForegroundColor Cyan
Write-Host "Total: $total ($pCount previews, $vCount videos)" -ForegroundColor Cyan

if ($notFound.Count -gt 0) {
    Write-Host ""
    Write-Host "Archivos no encontrados en disco ($($notFound.Count)):" -ForegroundColor Yellow
    foreach ($nf in $notFound) { Write-Host "  $nf" -ForegroundColor Yellow }
}

if ($total -eq 0) {
    Write-Host "[ERROR] No hay archivos para subir." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Presiona Enter para comenzar o Ctrl+C para cancelar..."
Read-Host

$i = 0; $err = 0
$sw = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($item in $upload) {
    $i++
    $pct = [math]::Round(($i / $total) * 100, 1)
    Write-Progress -Activity "Subiendo $Source a R2" -Status "$i / $total ($pct%)" -PercentComplete $pct

    $ext = [System.IO.Path]::GetExtension($item.Path)
    $ct = switch ($ext) {
        ".mp4"  { "video/mp4" }
        ".webp" { "image/webp" }
        default { "application/octet-stream" }
    }

    $wranglerArgs = @(
        "r2", "object", "put",
        "synaptixfit/$($item.Key)",
        "--file", $item.Path,
        "--content-type", $ct,
        "--remote"
    )
    $result = & wrangler @wranglerArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] $($item.Key)" -ForegroundColor Red
        $err++
    }
}

$sw.Stop()
$t = $sw.Elapsed
Write-Host ""
Write-Host "=== COMPLETADO ===" -ForegroundColor Green
Write-Host "OK: $($i - $err) / $total  |  Errores: $err"
Write-Host "Tiempo: $($t.Hours)h $($t.Minutes)m $($t.Seconds)s"
