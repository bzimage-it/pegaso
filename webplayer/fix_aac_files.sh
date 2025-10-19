#!/bin/bash
#
# Script per convertire e rinominare file AAC con metadata corretti
# Uso: ./fix_aac_files.sh <directory>
#

set -e  # Exit on error

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per stampare messaggi colorati
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Controlla se è stato passato un argomento
if [ $# -eq 0 ]; then
    print_error "Nessuna directory specificata!"
    echo ""
    echo "Uso: $0 <directory>"
    echo ""
    echo "Esempio:"
    echo "  $0 media/Album1"
    echo ""
    exit 1
fi

TARGET_DIR="$1"

# Verifica che la directory esista
if [ ! -d "$TARGET_DIR" ]; then
    print_error "La directory '$TARGET_DIR' non esiste!"
    exit 1
fi

# Verifica che ffmpeg sia installato
if ! command -v ffmpeg &> /dev/null; then
    print_error "ffmpeg non è installato!"
    echo ""
    echo "Per installare ffmpeg:"
    echo "  Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "  Fedora:        sudo dnf install ffmpeg"
    echo "  Arch:          sudo pacman -S ffmpeg"
    echo ""
    exit 1
fi

print_info "Directory target: $TARGET_DIR"
echo ""

# Conta i file AAC nella directory
shopt -s nullglob  # Evita problemi se non ci sono file
AAC_FILES=("$TARGET_DIR"/*.aac "$TARGET_DIR"/*.m4a "$TARGET_DIR"/*.AAC "$TARGET_DIR"/*.M4A)
shopt -u nullglob

if [ ${#AAC_FILES[@]} -eq 0 ]; then
    print_warning "Nessun file AAC/M4A trovato in '$TARGET_DIR'"
    exit 0
fi

print_info "Trovati ${#AAC_FILES[@]} file AAC/M4A"
echo ""

# Ordina i file lessicograficamente
IFS=$'\n' SORTED_FILES=($(sort -V <<<"${AAC_FILES[*]}"))
unset IFS

# Mostra i file che verranno processati
print_info "File da processare (in ordine):"
for i in "${!SORTED_FILES[@]}"; do
    filename=$(basename "${SORTED_FILES[$i]}")
    echo "  $((i+1)). $filename"
done
echo ""

# Chiedi conferma
read -p "Procedere con la conversione? I file originali verranno eliminati! (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Operazione annullata dall'utente"
    exit 0
fi

echo ""
print_info "Inizio conversione..."
echo ""

# Crea una directory temporanea per i file convertiti
TEMP_DIR=$(mktemp -d)
print_info "Directory temporanea: $TEMP_DIR"

# Contatori
SUCCESS_COUNT=0
ERROR_COUNT=0

# Processa ogni file
for i in "${!SORTED_FILES[@]}"; do
    SOURCE_FILE="${SORTED_FILES[$i]}"
    FILE_NUM=$((i+1))
    
    # Determina il numero di zeri da usare (per mantenere l'ordine con molti file)
    if [ ${#SORTED_FILES[@]} -lt 10 ]; then
        PART_NAME=$(printf "parte%d.aac" "$FILE_NUM")
    elif [ ${#SORTED_FILES[@]} -lt 100 ]; then
        PART_NAME=$(printf "parte%02d.aac" "$FILE_NUM")
    else
        PART_NAME=$(printf "parte%03d.aac" "$FILE_NUM")
    fi
    
    TEMP_FILE="$TEMP_DIR/$PART_NAME"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "[$FILE_NUM/${#SORTED_FILES[@]}] Conversione: $(basename "$SOURCE_FILE") → $PART_NAME"
    
    # Esegui la conversione con ffmpeg
    if ffmpeg -i "$SOURCE_FILE" -c:a copy -movflags +faststart -y "$TEMP_FILE" -loglevel warning -stats 2>&1; then
        print_success "Convertito con successo"
        ((SUCCESS_COUNT++))
    else
        print_error "Errore durante la conversione"
        ((ERROR_COUNT++))
        continue
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Se ci sono stati errori, chiedi se procedere comunque
if [ $ERROR_COUNT -gt 0 ]; then
    print_warning "Ci sono stati $ERROR_COUNT errori durante la conversione"
    read -p "Continuare comunque con la sostituzione dei file? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operazione annullata. File temporanei in: $TEMP_DIR"
        exit 1
    fi
fi

# Elimina i file originali
print_info "Eliminazione file originali..."
for FILE in "${SORTED_FILES[@]}"; do
    rm -f "$FILE"
    print_success "Eliminato: $(basename "$FILE")"
done
echo ""

# Sposta i file convertiti nella directory target
print_info "Spostamento file convertiti..."
mv "$TEMP_DIR"/*.aac "$TARGET_DIR/"
print_success "File spostati in $TARGET_DIR"
echo ""

# Rimuovi la directory temporanea
rmdir "$TEMP_DIR"

# Riepilogo finale
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "COMPLETATO!"
echo ""
echo "  📊 Statistiche:"
echo "     • File convertiti con successo: $SUCCESS_COUNT"
if [ $ERROR_COUNT -gt 0 ]; then
    echo "     • Errori:                       $ERROR_COUNT"
fi
echo ""
print_info "I file sono stati rinominati in ordine:"

# Mostra i nuovi file
NEW_FILES=("$TARGET_DIR"/parte*.aac)
for FILE in "${NEW_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        SIZE=$(du -h "$FILE" | cut -f1)
        echo "     • $(basename "$FILE") ($SIZE)"
    fi
done

echo ""
print_success "Operazione completata! I file ora hanno metadata corretti e il seek funzionerà correttamente."
echo ""

