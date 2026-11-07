<#
.SYNOPSIS
    Script automatizado de compilacion y publicacion de actualizaciones (OTA .pck + APK + EXE) en GitHub Releases.

.DESCRIPTION
    1. Incrementa la version en version.json y export_presets.cfg (o usa la indicada).
    2. Compila el paquete OTA ligero de Android (update_android.pck ~2.3 MB).
    3. Compila el paquete OTA ligero de Windows (update_windows.pck).
    4. Compila el APK completo para Android (build/Ajedrez_de_Pollito.apk).
    5. Compila el ejecutable para Windows (build/Ajedrez_de_Pollito.exe).
    6. Hace commit y push de los cambios al repositorio GitHub.
    7. Crea o actualiza la Release en GitHub con los artefactos y notas de version.

.PARAMETER VersionName
    Nombre semantico de la version (ej: 1.0.1). Si se omite, incrementa el ultimo digito.

.PARAMETER VersionCode
    Codigo numerico de compilacion (ej: 2). Si se omite, incrementa el actual.

.PARAMETER Notes
    Notas o novedades de la version.

.PARAMETER OnlyPck
    Si se activa, solo compila y sube los paquetes OTA .pck (actualizacion ultra rapida sin reconstruir APK).
#>
param(
    [string]$VersionName = "",
    [int]$VersionCode = 0,
    [string]$Notes = "",
    [switch]$OnlyPck
)

$ErrorActionPreference = "Stop"
$ProjectPath = $PSScriptRoot
Set-Location $ProjectPath

# Localizar ejecutables
$GodotExe = "C:\Herramientas\GODOT\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $GodotExe)) {
    throw "No se encontro el ejecutable de Godot en: $GodotExe"
}

$GhExe = "C:\Users\diego\AppData\Local\Programs\GitHub CLI\gh.exe"
if (-not (Test-Path $GhExe)) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $GhExe = "gh"
    } else {
        throw "No se encontro GitHub CLI (gh.exe)."
    }
}

# 1. Leer version.json actual
$VersionJsonPath = Join-Path $ProjectPath "version.json"
if (-not (Test-Path $VersionJsonPath)) {
    throw "No se encontro version.json en $VersionJsonPath"
}

$versionData = Get-Content $VersionJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($VersionCode -le 0) {
    $VersionCode = [int]$versionData.version_code + 1
}

if ([string]::IsNullOrWhiteSpace($VersionName)) {
    $parts = ([string]$versionData.version_name).Split('.')
    if ($parts.Length -eq 3) {
        $patch = [int]$parts[2] + 1
        $VersionName = "$($parts[0]).$($parts[1]).$patch"
    } else {
        $VersionName = "1.0.$VersionCode"
    }
}

if ([string]::IsNullOrWhiteSpace($Notes)) {
    $Notes = "Actualizacion v$VersionName (Build $VersionCode): Mejoras y correcciones generales."
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ">> Iniciando Deploy para Ajedrez de Pollito" -ForegroundColor Yellow
Write-Host "[*] Version: $VersionName (Build Code: $VersionCode)" -ForegroundColor Green
Write-Host "[*] Notas:   $Notes" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

# 2. Actualizar version.json
$versionData.version_code = $VersionCode
$versionData.version_name = $VersionName
$versionData.release_date = (Get-Date -Format "yyyy-MM-dd")
$versionData.notes = $Notes
$versionData.pck_url = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/update_android.pck"
$versionData.pck_win_url = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/update_windows.pck"
$versionData.apk_url = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/Ajedrez_de_Pollito.apk"
$versionData.exe_url = "https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/latest/download/Ajedrez_de_Pollito.exe"

$newJson = $versionData | ConvertTo-Json -Depth 4
Set-Content -Path $VersionJsonPath -Value $newJson -Encoding UTF8
Write-Host "[OK] version.json actualizado." -ForegroundColor Green

# 3. Actualizar export_presets.cfg (para Android)
$ExportPresetsPath = Join-Path $ProjectPath "export_presets.cfg"
if (Test-Path $ExportPresetsPath) {
    $cfgContent = Get-Content $ExportPresetsPath -Raw -Encoding UTF8
    $cfgContent = $cfgContent -replace 'version/code=\d+', "version/code=$VersionCode"
    $cfgContent = $cfgContent -replace 'version/name="[^"]*"', ('version/name="' + $VersionName + '"')
    Set-Content -Path $ExportPresetsPath -Value $cfgContent -Encoding UTF8
    Write-Host "[OK] export_presets.cfg sincronizado con v$VersionName." -ForegroundColor Green
}

# 4. Crear carpeta build si no existe
$BuildDir = Join-Path $ProjectPath "build"
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
}

$PckAndroid = Join-Path $BuildDir "update_android.pck"
$PckWindows = Join-Path $BuildDir "update_windows.pck"
$ApkAndroid = Join-Path $BuildDir "Ajedrez_de_Pollito.apk"
$ExeWindows = Join-Path $BuildDir "Ajedrez_de_Pollito.exe"

# 5. Compilacion con Godot
Write-Host "`n[PACK] Compilando paquete OTA para Android (update_android.pck)..." -ForegroundColor Cyan
& $GodotExe --headless --path $ProjectPath --export-pack "Android" $PckAndroid | Out-Null
if (-not (Test-Path $PckAndroid)) { throw "Error al compilar $PckAndroid" }
$pckSizeMB = [math]::Round((Get-Item $PckAndroid).Length / 1MB, 2)
Write-Host "[OK] Android PCK listo: $PckAndroid ($pckSizeMB MB)" -ForegroundColor Green

Write-Host "[PACK] Compilando paquete OTA para Windows (update_windows.pck)..." -ForegroundColor Cyan
& $GodotExe --headless --path $ProjectPath --export-pack "Windows Desktop" $PckWindows | Out-Null
if (-not (Test-Path $PckWindows)) { throw "Error al compilar $PckWindows" }
$pckWinSizeMB = [math]::Round((Get-Item $PckWindows).Length / 1MB, 2)
Write-Host "[OK] Windows PCK listo: $PckWindows ($pckWinSizeMB MB)" -ForegroundColor Green

if (-not $OnlyPck) {
    Write-Host "`n[APK] Compilando APK completo de Android (Ajedrez_de_Pollito.apk)..." -ForegroundColor Cyan
    & $GodotExe --headless --path $ProjectPath --export-release "Android" $ApkAndroid | Out-Null
    if (-not (Test-Path $ApkAndroid)) { throw "Error al compilar $ApkAndroid" }
    $apkSizeMB = [math]::Round((Get-Item $ApkAndroid).Length / 1MB, 2)
    Write-Host "[OK] APK listo: $ApkAndroid ($apkSizeMB MB)" -ForegroundColor Green

    Write-Host "[EXE] Compilando ejecutable de Windows (Ajedrez_de_Pollito.exe)..." -ForegroundColor Cyan
    & $GodotExe --headless --path $ProjectPath --export-release "Windows Desktop" $ExeWindows | Out-Null
    if (-not (Test-Path $ExeWindows)) { throw "Error al compilar $ExeWindows" }
    $exeSizeMB = [math]::Round((Get-Item $ExeWindows).Length / 1MB, 2)
    Write-Host "[OK] Windows EXE listo: $ExeWindows ($exeSizeMB MB)" -ForegroundColor Green
}

# 6. Git commit y push
Write-Host "`n[GIT] Sincronizando con repositorio Git..." -ForegroundColor Cyan
git add -A
$commitMsg = "Release v$VersionName (Build $VersionCode): $Notes"
git commit -m $commitMsg --allow-empty
git push origin main

# 7. Crear GitHub Release
Write-Host "`n[RELEASE] Publicando Release v$VersionName en GitHub..." -ForegroundColor Cyan
$Tag = "v$VersionName"

$ReleaseFiles = @(
    $PckAndroid,
    $PckWindows,
    $VersionJsonPath
)
if (-not $OnlyPck) {
    $ReleaseFiles += $ApkAndroid
    $ReleaseFiles += $ExeWindows
}

# Si la tag ya existe la borramos local/remota para sobrescribir limpiamente si es necesario
& $GhExe release delete $Tag --yes 2>$null
git push origin :refs/tags/$Tag 2>$null

& $GhExe release create $Tag $ReleaseFiles --title "Ajedrez de Pollito v$VersionName" --notes $Notes --latest

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "[DONE] Deploy completado con exito!" -ForegroundColor Yellow
Write-Host "URL de Release: https://github.com/Xx5n0wxX/ajedrez-de-pollito/releases/tag/$Tag" -ForegroundColor White
Write-Host "Los telefonos con el juego recibiran la notificacion automatica" -ForegroundColor White
Write-Host "y podran actualizarse en 2 segundos descargando solo $pckSizeMB MB." -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
