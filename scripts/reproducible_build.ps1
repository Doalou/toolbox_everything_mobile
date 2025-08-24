# Script PowerShell pour vérifier la reproductibilité des builds
# Usage: .\scripts\reproducible_build.ps1 [--clean] [--compare] [--BuildType release|debug]

param(
    [switch]$Clean,
    [switch]$Compare,
    [string]$BuildType = "release"
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        "Gray" { Write-Host $Message -ForegroundColor Gray }
        default { Write-Host $Message -ForegroundColor White }
    }
}

# Configuration
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BuildsDir = Join-Path $ProjectRoot "reproducible_builds"
$Build1Dir = Join-Path $BuildsDir "build1"
$Build2Dir = Join-Path $BuildsDir "build2"

Write-ColorOutput "🔧 Script de vérification des Reproducible Builds" "Cyan"
Write-ColorOutput "Type de build : $BuildType" "Yellow"

# Nettoyage si demandé
if ($Clean) {
    Write-ColorOutput "🧹 Nettoyage des builds précédents..." "Yellow"
    if (Test-Path $BuildsDir) {
        Remove-Item $BuildsDir -Recurse -Force
    }
    flutter clean
    exit 0
}

# Création des dossiers
if (-not (Test-Path $BuildsDir)) {
    New-Item -ItemType Directory -Path $BuildsDir | Out-Null
}

# Variables d'environnement pour la reproductibilité
$env:SOURCE_DATE_EPOCH = "1704067200" # 2024-01-01 00:00:00 UTC
$env:GIT_COMMIT = try { git rev-parse HEAD } catch { "unknown" }

Write-ColorOutput "📅 SOURCE_DATE_EPOCH: $env:SOURCE_DATE_EPOCH" "Gray"
Write-ColorOutput "📝 GIT_COMMIT: $env:GIT_COMMIT" "Gray"

function Start-ReproducibleBuild {
    param([string]$BuildDir, [int]$BuildNumber)
    
    Write-ColorOutput "🏗️ Build $BuildNumber en cours..." "Green"
    
    # Nettoyage complet
    flutter clean | Out-Null
    
    # Installation des dépendances
    flutter pub get | Out-Null
    
    # Build de l'APK
    if ($BuildType -eq "release") {
        flutter build apk --release --split-per-abi | Out-Null
    } else {
        flutter build apk --debug | Out-Null
    }
    
    # Copie des artefacts
    $SourceDir = "build\app\outputs\flutter-apk"
    if (Test-Path $SourceDir) {
        if (-not (Test-Path $BuildDir)) {
            New-Item -ItemType Directory -Path $BuildDir | Out-Null
        }
        Copy-Item "$SourceDir\*" $BuildDir -Recurse -Force
        
        # Calcul des hashes
        $HashFile = Join-Path $BuildDir "checksums.txt"
        Get-ChildItem $BuildDir -Filter "*.apk" | Sort-Object Name | ForEach-Object {
            $hash = Get-FileHash $_.FullName -Algorithm SHA256
            "$($hash.Hash)  $($_.Name)" | Out-File $HashFile -Append -Encoding UTF8
        }
        
        Write-ColorOutput "✅ Build $BuildNumber terminé" "Green"
    } else {
        Write-ColorOutput "❌ Erreur : Répertoire de build introuvable" "Red"
        exit 1
    }
}

# Premier build
Start-ReproducibleBuild $Build1Dir 1

# Attente pour éviter les problèmes de timing
Start-Sleep -Seconds 2

# Deuxième build
Start-ReproducibleBuild $Build2Dir 2

# Comparaison si demandée
if ($Compare) {
    Write-ColorOutput "" "White"
    Write-ColorOutput "🔍 Comparaison des builds..." "Cyan"
    
    $Build1Hashes = Join-Path $Build1Dir "checksums.txt"
    $Build2Hashes = Join-Path $Build2Dir "checksums.txt"
    
    if ((Test-Path $Build1Hashes) -and (Test-Path $Build2Hashes)) {
        $Hash1Content = Get-Content $Build1Hashes
        $Hash2Content = Get-Content $Build2Hashes
        
        $Identical = $true
        if ($Hash1Content.Count -ne $Hash2Content.Count) {
            $Identical = $false
        } else {
            for ($i = 0; $i -lt $Hash1Content.Count; $i++) {
                if ($Hash1Content[$i] -ne $Hash2Content[$i]) {
                    $Identical = $false
                    break
                }
            }
        }
        
        if ($Identical) {
            Write-ColorOutput "✅ SUCCÈS : Les builds sont identiques !" "Green"
            Write-ColorOutput "🎉 Votre configuration produit des builds reproductibles." "Green"
        } else {
            Write-ColorOutput "❌ ÉCHEC : Les builds diffèrent" "Red"
            Write-ColorOutput "Build 1 hashes:" "Yellow"
            $Hash1Content | ForEach-Object { Write-ColorOutput "  $_" "Gray" }
            Write-ColorOutput "Build 2 hashes:" "Yellow"
            $Hash2Content | ForEach-Object { Write-ColorOutput "  $_" "Gray" }
        }
    } else {
        Write-ColorOutput "❌ Erreur : Fichiers de hashes introuvables" "Red"
    }
    
    # Taille des fichiers
    Write-ColorOutput "" "White"
    Write-ColorOutput "📊 Comparaison des tailles :" "Cyan"
    Get-ChildItem $Build1Dir -Filter "*.apk" | ForEach-Object {
        $File1 = $_.FullName
        $File2 = Join-Path $Build2Dir $_.Name
        if (Test-Path $File2) {
            $Size1 = (Get-Item $File1).Length
            $Size2 = (Get-Item $File2).Length
            $SizeDiff = $Size2 - $Size1
            
            Write-ColorOutput "📱 $($_.Name):" "White"
            Write-ColorOutput "   Build 1: $([math]::Round($Size1/1MB, 2)) MB" "Gray"
            Write-ColorOutput "   Build 2: $([math]::Round($Size2/1MB, 2)) MB" "Gray"
            
            if ($SizeDiff -eq 0) {
                Write-ColorOutput "   Différence: 0 bytes ✅" "Green"
            } else {
                Write-ColorOutput "   Différence: $SizeDiff bytes ❌" "Red"
            }
        }
    }
}

Write-ColorOutput "" "White"
Write-ColorOutput "🏁 Script terminé." "Cyan"
Write-ColorOutput "📁 Builds disponibles dans : $BuildsDir" "Gray"