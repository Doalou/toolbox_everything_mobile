#!/bin/bash
# Script bash pour vérifier la reproductibilité des builds (Linux/macOS)
# Usage: ./scripts/reproducible_build.sh [--clean] [--compare] [--build-type=release|debug]

set -euo pipefail

# Configuration par défaut
CLEAN=false
COMPARE=false
BUILD_TYPE="release"

# Parse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=true
            shift
            ;;
        --compare)
            COMPARE=true
            shift
            ;;
        --build-type=*)
            BUILD_TYPE="${1#*=}"
            shift
            ;;
        *)
            echo "❌ Argument inconnu: $1"
            exit 1
            ;;
    esac
done

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${CYAN}$1${NC}"
}

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${RED}$1${NC}"
}

log_gray() {
    echo -e "${GRAY}$1${NC}"
}

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDS_DIR="$PROJECT_ROOT/reproducible_builds"
BUILD1_DIR="$BUILDS_DIR/build1"
BUILD2_DIR="$BUILDS_DIR/build2"

log_info "🔧 Script de vérification des Reproducible Builds"
log_warning "Type de build : $BUILD_TYPE"

# Nettoyage si demandé
if [[ "$CLEAN" == "true" ]]; then
    log_warning "🧹 Nettoyage des builds précédents..."
    rm -rf "$BUILDS_DIR"
    flutter clean
    exit 0
fi

# Création des dossiers
mkdir -p "$BUILDS_DIR"

# Variables d'environnement pour la reproductibilité
export SOURCE_DATE_EPOCH="1704067200" # 2024-01-01 00:00:00 UTC
export GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

log_gray "📅 SOURCE_DATE_EPOCH: $SOURCE_DATE_EPOCH"
log_gray "📝 GIT_COMMIT: $GIT_COMMIT"

perform_build() {
    local build_dir="$1"
    local build_number="$2"
    
    log_success "🏗️ Build $build_number en cours..."
    
    # Nettoyage complet
    flutter clean > /dev/null
    
    # Installation des dépendances
    flutter pub get > /dev/null
    
    # Build de l'APK
    if [[ "$BUILD_TYPE" == "release" ]]; then
        flutter build apk --release --split-per-abi > /dev/null
    else
        flutter build apk --debug > /dev/null
    fi
    
    # Copie des artefacts
    local source_dir="build/app/outputs/flutter-apk"
    if [[ -d "$source_dir" ]]; then
        mkdir -p "$build_dir"
        cp -r "$source_dir"/* "$build_dir/"
        
        # Calcul des hashes
        local hash_file="$build_dir/checksums.txt"
        find "$build_dir" -name "*.apk" -type f | sort | while read -r file; do
            sha256sum "$file" >> "$hash_file"
        done
        
        log_success "✅ Build $build_number terminé"
    else
        log_error "❌ Erreur : Répertoire de build introuvable"
        exit 1
    fi
}

# Premier build
perform_build "$BUILD1_DIR" 1

# Attente pour éviter les problèmes de timing
sleep 2

# Deuxième build
perform_build "$BUILD2_DIR" 2

# Comparaison si demandée
if [[ "$COMPARE" == "true" ]]; then
    log_info ""
    log_info "🔍 Comparaison des builds..."
    
    local build1_hashes="$BUILD1_DIR/checksums.txt"
    local build2_hashes="$BUILD2_DIR/checksums.txt"
    
    if [[ -f "$build1_hashes" && -f "$build2_hashes" ]]; then
        if diff -q "$build1_hashes" "$build2_hashes" > /dev/null; then
            log_success "✅ SUCCÈS : Les builds sont identiques !"
            log_success "🎉 Votre configuration produit des builds reproductibles."
        else
            log_error "❌ ÉCHEC : Les builds diffèrent"
            log_warning "Build 1 hashes:"
            while IFS= read -r line; do
                log_gray "  $line"
            done < "$build1_hashes"
            log_warning "Build 2 hashes:"
            while IFS= read -r line; do
                log_gray "  $line"
            done < "$build2_hashes"
        fi
    else
        log_error "❌ Erreur : Fichiers de hashes introuvables"
    fi
    
    # Taille des fichiers
    log_info ""
    log_info "📊 Comparaison des tailles :"
    find "$BUILD1_DIR" -name "*.apk" -type f | while read -r file1; do
        local filename=$(basename "$file1")
        local file2="$BUILD2_DIR/$filename"
        
        if [[ -f "$file2" ]]; then
            local size1=$(stat -f%z "$file1" 2>/dev/null || stat -c%s "$file1")
            local size2=$(stat -f%z "$file2" 2>/dev/null || stat -c%s "$file2")
            local size_diff=$((size2 - size1))
            
            echo "📱 $filename:"
            log_gray "   Build 1: $(echo "scale=2; $size1/1024/1024" | bc) MB"
            log_gray "   Build 2: $(echo "scale=2; $size2/1024/1024" | bc) MB"
            
            if [[ $size_diff -eq 0 ]]; then
                log_success "   Différence: 0 bytes ✅"
            else
                log_error "   Différence: $size_diff bytes ❌"
            fi
        fi
    done
fi

log_info ""
log_info "🏁 Script terminé."
log_gray "📁 Builds disponibles dans : $BUILDS_DIR"
