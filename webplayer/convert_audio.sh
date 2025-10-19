#!/bin/bash
#
# Audio conversion script with custom structure and metadata
#
# Usage: ./convert_audio.sh <source-dir> <target-base> [--profile <profile>] [--fix-whatsapp-aac] [permutation...]
#
# Examples:
#   ./convert_audio.sh media-orig/2025-10-03 media/FORM-BIBLIT-25-26
#   ./convert_audio.sh ~/audio/lesson1 media/course --profile quality 2 3 1
#   ./convert_audio.sh media-orig/2025-10-03 media/FORM-BIBLIT-25-26 --fix-whatsapp-aac
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
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

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Function to get file information
get_file_info() {
    local file="$1"
    local info=$(ffprobe -v quiet -print_format json -show_format "$file" 2>/dev/null)
    if [ $? -eq 0 ]; then
        local size=$(echo "$info" | grep -o '"size":"[^"]*"' | cut -d'"' -f4)
        local duration=$(echo "$info" | grep -o '"duration":"[^"]*"' | cut -d'"' -f4)
        local bitrate=$(echo "$info" | grep -o '"bit_rate":"[^"]*"' | cut -d'"' -f4)
        
        # Convert size from bytes to MB
        if [ -n "$size" ]; then
            size=$(echo "scale=1; $size / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
        fi
        
        # Convert duration from seconds to minutes
        if [ -n "$duration" ]; then
            duration=$(echo "scale=1; $duration / 60" | bc 2>/dev/null || echo "N/A")
        fi
        
        # Convert bitrate from bps to kbps
        if [ -n "$bitrate" ]; then
            bitrate=$(echo "scale=0; $bitrate / 1000" | bc 2>/dev/null || echo "N/A")
        fi
        
        echo "$size|$duration|$bitrate"
    else
        echo "N/A|N/A|N/A"
    fi
}

# Banner
echo ""
print_header "╔════════════════════════════════════════════════════╗"
print_header "║     Audio Converter with Metadata                   ║"
print_header "╚════════════════════════════════════════════════════╝"
echo ""

# Check arguments
if [ $# -lt 2 ]; then
    print_error "Insufficient arguments!"
    echo ""
    echo "Usage: $0 <source-dir> <target-base> [--profile <profile>] [--fix-whatsapp-aac] [permutation...]"
    echo ""
    echo "Available profiles:"
    echo "  mobile     - 32kbps (~7MB per 30min)  - Very slow connections"
    echo "  bandwidth  - 48kbps (~11MB per 30min) - Economic hosting"
    echo "  web        - 64kbps (~15MB per 30min) - Standard web streaming (default)"
    echo "  podcast    - 80kbps (~18MB per 30min) - Spoken content"
    echo "  quality    - 96kbps (~22MB per 30min) - High quality"
    echo "  archive    - 128kbps (~30MB per 30min) - Maximum quality"
    echo ""
    echo "Special options:"
    echo "  --fix-whatsapp-aac  - Fix WhatsApp AAC files for proper seeking and playback"
    echo ""
    echo "Examples:"
    echo "  $0 media-orig/2025-10-03 media/FORM-BIBLIT-25-26"
    echo "  $0 media-orig/2025-10-03 media/FORM-BIBLIT-25-26 --profile bandwidth"
    echo "  $0 media-orig/2025-10-03 media/FORM-BIBLIT-25-26 --fix-whatsapp-aac"
    echo "  $0 ~/audio/lesson1 media/course --profile quality 2 3 1"
    echo ""
    exit 1
fi

SOURCE_DIR="$1"
TARGET_BASE="$2"
shift 2

# Predefined conversion profiles
declare -A PROFILES
PROFILES["mobile"]="32k"
PROFILES["bandwidth"]="48k"
PROFILES["web"]="64k"
PROFILES["podcast"]="80k"
PROFILES["quality"]="96k"
PROFILES["archive"]="128k"

# Default profile
DEFAULT_PROFILE="web"
PROFILE="$DEFAULT_PROFILE"
PERMUTATION=()
FIX_WHATSAPP_AAC=false

# Parse arguments for --profile and --fix-whatsapp-aac
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --profile=*)
            PROFILE="${1#*=}"
            shift
            ;;
        --fix-whatsapp-aac)
            FIX_WHATSAPP_AAC=true
            shift
            ;;
        *)
            # If not a flag, it's probably a permutation
            PERMUTATION+=("$1")
            shift
            ;;
    esac
done

# Extract source directory name to create target structure
SOURCE_DIR_NAME=$(basename "$SOURCE_DIR")
TARGET_DIR="$TARGET_BASE/$SOURCE_DIR_NAME"

# Validate profile
if [[ ! ${PROFILES[$PROFILE]} ]]; then
    print_error "Invalid profile: $PROFILE"
    echo ""
    echo "Available profiles:"
    for profile in "${!PROFILES[@]}"; do
        echo "  $profile (${PROFILES[$profile]})"
    done
    echo ""
    exit 1
fi

BITRATE="${PROFILES[$PROFILE]}"

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    print_error "ffmpeg is not installed!"
    echo ""
    echo "To install ffmpeg:"
    echo "  Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "  Fedora:        sudo dnf install ffmpeg"
    echo "  Arch:          sudo pacman -S ffmpeg"
    echo ""
    exit 1
fi

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    print_error "Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Check if target directory already exists
if [ -d "$TARGET_DIR" ]; then
    print_warning "Target directory already exists: $TARGET_DIR"
    echo ""
    echo "Current content:"
    ls -la "$TARGET_DIR" 2>/dev/null | head -10
    if [ $(ls -1 "$TARGET_DIR" 2>/dev/null | wc -l) -gt 10 ]; then
        echo "  ... and other files"
    fi
    echo ""
    
    while true; do
        echo -n "Do you want to completely remove the target directory? (y/N): "
        read -r response
        case $response in
            [Yy]* )
                print_info "Removing target directory..."
                rm -rf "$TARGET_DIR"
                print_success "Directory removed"
                break
                ;;
            [Nn]* | "" )
                print_warning "Proceeding without removing existing directory"
                print_info "Existing files may be overwritten"
                break
                ;;
            * )
                echo "Answer 'y' for yes or 'n' for no"
                ;;
        esac
    done
fi

print_info "Source: $SOURCE_DIR"
print_info "Target: $TARGET_DIR"
print_info "Profile: $PROFILE (${BITRATE})"
if [ "$FIX_WHATSAPP_AAC" = true ]; then
    print_info "WhatsApp AAC fix: ENABLED"
fi
echo ""

# Create target directory (now we know it doesn't exist or was removed)
mkdir -p "$TARGET_DIR"

# Find all audio files in source directory
shopt -s nullglob
AUDIO_FILES=("$SOURCE_DIR"/*.aac "$SOURCE_DIR"/*.m4a "$SOURCE_DIR"/*.AAC "$SOURCE_DIR"/*.M4A "$SOURCE_DIR"/*.mp3 "$SOURCE_DIR"/*.MP3 "$SOURCE_DIR"/*.wav "$SOURCE_DIR"/*.WAV "$SOURCE_DIR"/*.ogg "$SOURCE_DIR"/*.OGG "$SOURCE_DIR"/*.flac "$SOURCE_DIR"/*.FLAC)
shopt -u nullglob

if [ ${#AUDIO_FILES[@]} -eq 0 ]; then
    print_warning "No audio files found in '$SOURCE_DIR'"
    exit 0
fi

# Sort files lexicographically
IFS=$'\n' SORTED_FILES=($(sort -V <<<"${AUDIO_FILES[*]}"))
unset IFS

NUM_FILES=${#SORTED_FILES[@]}

print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Files found: $NUM_FILES"
echo ""

# Validate permutation if provided
USE_PERMUTATION=false
if [ ${#PERMUTATION[@]} -gt 0 ]; then
    # Check that the number of elements is correct
    if [ ${#PERMUTATION[@]} -ne $NUM_FILES ]; then
        print_error "Error: Permutation has ${#PERMUTATION[@]} elements, but there are $NUM_FILES files!"
        print_warning "Using lexicographic order by default"
        PERMUTATION=()
    else
        # Check that all numbers are present and unique
        SEEN=()
        VALID=true
        for num in "${PERMUTATION[@]}"; do
            # Check that it's a number
            if ! [[ "$num" =~ ^[0-9]+$ ]]; then
                print_error "Error: '$num' is not a valid number!"
                VALID=false
                break
            fi
            # Check that it's in range
            if [ "$num" -lt 1 ] || [ "$num" -gt $NUM_FILES ]; then
                print_error "Error: $num out of range (must be between 1 and $NUM_FILES)!"
                VALID=false
                break
            fi
            # Check for duplicates
            if [[ " ${SEEN[@]} " =~ " ${num} " ]]; then
                print_error "Error: Number $num is duplicated!"
                VALID=false
                break
            fi
            SEEN+=("$num")
        done
        
        if [ "$VALID" = true ]; then
            USE_PERMUTATION=true
            print_info "Using permutation: ${PERMUTATION[*]}"
        else
            print_warning "Invalid permutation, using lexicographic order"
            PERMUTATION=()
        fi
    fi
fi
echo ""

# Determine file name format with numeric prefix for ordering
if [ $NUM_FILES -lt 10 ]; then
    NAME_FORMAT="%d_part_%d.m4a"
    PREFIX_FORMAT="%d"
elif [ $NUM_FILES -lt 100 ]; then
    NAME_FORMAT="%02d_part_%02d.m4a"
    PREFIX_FORMAT="%02d"
else
    NAME_FORMAT="%03d_part_%03d.m4a"
    PREFIX_FORMAT="%03d"
fi

# Show mapping
if [ "$USE_PERMUTATION" = true ]; then
    print_info "File mapping (with reordering):"
    for i in "${!PERMUTATION[@]}"; do
        SOURCE_INDEX=$((${PERMUTATION[$i]} - 1))
        SOURCE_FILE="${SORTED_FILES[$SOURCE_INDEX]}"
        DEST_NUM=$((i+1))
        ORDER_PREFIX=$(printf "$PREFIX_FORMAT" "$DEST_NUM")
        PART_NAME=$(printf "$NAME_FORMAT" "$DEST_NUM" "$DEST_NUM")
        echo "  $((SOURCE_INDEX+1)). $(basename "$SOURCE_FILE") → $PART_NAME (Title: 'Part $DEST_NUM')"
    done
else
    print_info "File mapping (lexicographic order):"
    for i in "${!SORTED_FILES[@]}"; do
        FILE_NUM=$((i+1))
        ORDER_PREFIX=$(printf "$PREFIX_FORMAT" "$FILE_NUM")
        PART_NAME=$(printf "$NAME_FORMAT" "$FILE_NUM" "$FILE_NUM")
        echo "  $FILE_NUM. $(basename "${SORTED_FILES[$i]}") → $PART_NAME (Title: 'Part $FILE_NUM')"
    done
fi
echo ""

# Process files
SUCCESS=0
ERROR=0

if [ "$USE_PERMUTATION" = true ]; then
    # With permutation
    for i in "${!PERMUTATION[@]}"; do
        SOURCE_INDEX=$((${PERMUTATION[$i]} - 1))
        SOURCE_FILE="${SORTED_FILES[$SOURCE_INDEX]}"
        DEST_NUM=$((i+1))
        ORDER_PREFIX=$(printf "$PREFIX_FORMAT" "$DEST_NUM")
        PART_NAME=$(printf "$NAME_FORMAT" "$DEST_NUM" "$DEST_NUM")
        DEST_FILE="$TARGET_DIR/$PART_NAME"
        
        SOURCE_NAME=$(basename "$SOURCE_FILE")
        if [ "$FIX_WHATSAPP_AAC" = true ]; then
            echo -n "  🔧 [$DEST_NUM/$NUM_FILES] $SOURCE_NAME → $PART_NAME (WhatsApp fix) ... "
        else
            echo -n "  🔄 [$DEST_NUM/$NUM_FILES] $SOURCE_NAME → $PART_NAME ... "
        fi
        
        # Get source file information
        SOURCE_INFO=$(get_file_info "$SOURCE_FILE")
        SOURCE_SIZE=$(echo "$SOURCE_INFO" | cut -d'|' -f1)
        SOURCE_DURATION=$(echo "$SOURCE_INFO" | cut -d'|' -f2)
        SOURCE_BITRATE=$(echo "$SOURCE_INFO" | cut -d'|' -f3)
        
        # Convert with metadata and lexicographic ordering (web optimized)
        if [ "$FIX_WHATSAPP_AAC" = true ]; then
            # WhatsApp AAC fix: copy codec without re-encoding to fix seeking issues
            FFMPEG_OUTPUT=$(ffmpeg -i "$SOURCE_FILE" \
                -c:a copy \
                -metadata title="Part $DEST_NUM" \
                -metadata track="$DEST_NUM" \
                -movflags +faststart \
                -y "$DEST_FILE" \
                -loglevel warning 2>&1)
        else
            # Normal conversion with specified bitrate
            FFMPEG_OUTPUT=$(ffmpeg -i "$SOURCE_FILE" \
                -c:a aac \
                -b:a "$BITRATE" \
                -metadata title="Part $DEST_NUM" \
                -metadata track="$DEST_NUM" \
                -movflags +faststart \
                -y "$DEST_FILE" \
                -loglevel warning 2>&1)
        fi
        FFMPEG_EXIT=$?
        
        if [ $FFMPEG_EXIT -eq 0 ]; then
            # Get converted file information
            DEST_INFO=$(get_file_info "$DEST_FILE")
            DEST_SIZE=$(echo "$DEST_INFO" | cut -d'|' -f1)
            DEST_BITRATE=$(echo "$DEST_INFO" | cut -d'|' -f3)
            
            echo -e "${GREEN}✓${NC}"
            echo "     Orig: ${SOURCE_SIZE}MB (${SOURCE_BITRATE}kbps) → Dest: ${DEST_SIZE}MB (${DEST_BITRATE}kbps)"
            ((SUCCESS++))
        else
            echo -e "${RED}✗${NC}"
            if [ -n "$FFMPEG_OUTPUT" ]; then
                echo "     Error: $FFMPEG_OUTPUT"
            fi
            ((ERROR++))
        fi
    done
else
    # Normal order
    for i in "${!SORTED_FILES[@]}"; do
        SOURCE_FILE="${SORTED_FILES[$i]}"
        FILE_NUM=$((i+1))
        ORDER_PREFIX=$(printf "$PREFIX_FORMAT" "$FILE_NUM")
        PART_NAME=$(printf "$NAME_FORMAT" "$FILE_NUM" "$FILE_NUM")
        DEST_FILE="$TARGET_DIR/$PART_NAME"
        
        if [ "$FIX_WHATSAPP_AAC" = true ]; then
            echo -n "  🔧 [$FILE_NUM/$NUM_FILES] $(basename "$SOURCE_FILE") → $PART_NAME (WhatsApp fix) ... "
        else
            echo -n "  🔄 [$FILE_NUM/$NUM_FILES] $(basename "$SOURCE_FILE") → $PART_NAME ... "
        fi
        
        # Get source file information
        SOURCE_INFO=$(get_file_info "$SOURCE_FILE")
        SOURCE_SIZE=$(echo "$SOURCE_INFO" | cut -d'|' -f1)
        SOURCE_DURATION=$(echo "$SOURCE_INFO" | cut -d'|' -f2)
        SOURCE_BITRATE=$(echo "$SOURCE_INFO" | cut -d'|' -f3)
        
        # Convert with metadata and lexicographic ordering (web optimized)
        if [ "$FIX_WHATSAPP_AAC" = true ]; then
            # WhatsApp AAC fix: copy codec without re-encoding to fix seeking issues
            FFMPEG_OUTPUT=$(ffmpeg -i "$SOURCE_FILE" \
                -c:a copy \
                -metadata title="Part $FILE_NUM" \
                -metadata track="$FILE_NUM" \
                -movflags +faststart \
                -y "$DEST_FILE" \
                -loglevel warning 2>&1)
        else
            # Normal conversion with specified bitrate
            FFMPEG_OUTPUT=$(ffmpeg -i "$SOURCE_FILE" \
                -c:a aac \
                -b:a "$BITRATE" \
                -metadata title="Part $FILE_NUM" \
                -metadata track="$FILE_NUM" \
                -movflags +faststart \
                -y "$DEST_FILE" \
                -loglevel warning 2>&1)
        fi
        FFMPEG_EXIT=$?
        
        if [ $FFMPEG_EXIT -eq 0 ]; then
            # Get converted file information
            DEST_INFO=$(get_file_info "$DEST_FILE")
            DEST_SIZE=$(echo "$DEST_INFO" | cut -d'|' -f1)
            DEST_BITRATE=$(echo "$DEST_INFO" | cut -d'|' -f3)
            
            echo -e "${GREEN}✓${NC}"
            echo "     Orig: ${SOURCE_SIZE}MB (${SOURCE_BITRATE}kbps) → Dest: ${DEST_SIZE}MB (${DEST_BITRATE}kbps)"
            ((SUCCESS++))
        else
            echo -e "${RED}✗${NC}"
            if [ -n "$FFMPEG_OUTPUT" ]; then
                echo "     Error: $FFMPEG_OUTPUT"
            fi
            ((ERROR++))
        fi
    done
fi

# Summary
echo ""
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERROR -eq 0 ]; then
    print_success "COMPLETED! $SUCCESS files converted"
    if [ "$FIX_WHATSAPP_AAC" = true ]; then
        print_info "WhatsApp AAC fix applied - files optimized for web playback"
    fi
else
    print_warning "Completed with errors: $SUCCESS converted, $ERROR errors"
fi

echo ""
print_info "Files saved in: $TARGET_DIR"
echo ""

