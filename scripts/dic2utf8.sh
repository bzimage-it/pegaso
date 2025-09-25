#!/bin/bash
# Converts Word dictionary UTF-16LE + BOM + CRLF to UTF-8 text on stdout
# Complementary script to utf82dic.sh

# typically used to convert Word dictionary ".DIC" files to UTF-8 text

# How it works:
# 1. Save all stdin to a temporary file
# 2. Verify that the first 2 bytes are the UTF-16LE BOM (\xff\xfe)
# 3. dd bs=1 skip=2 → skip the first 2 bytes (UTF-16LE BOM)
# 4. iconv -f UTF-16LE -t UTF-8 → convert from UTF-16LE to UTF-8
# 5. sed 's/\r$//' → remove trailing CR converting CRLF to LF (Unix line endings)

# Create a temporary file to save stdin
temp_file=$(mktemp)
trap "rm -f '$temp_file'" EXIT

# Save stdin to the temporary file
cat > "$temp_file"

# Verify that the file has at least 2 bytes
if [ ! -s "$temp_file" ] || [ $(stat -c%s "$temp_file") -lt 2 ]; then
    echo "Error: File is empty or too small to contain a UTF-16LE BOM" >&2
    exit 1
fi

# Read the first 2 bytes to verify the UTF-16LE BOM
bom=$(dd if="$temp_file" bs=1 count=2 2>/dev/null | xxd -p)

# Verify that the BOM is correct (UTF-16LE: FF FE)
if [ "$bom" != "fffe" ]; then
    echo "Error: File does not have a valid UTF-16LE BOM. Found: $bom" >&2
    echo "Expected: fffe (UTF-16LE BOM)" >&2
    exit 1
fi

# Remove UTF-16LE BOM (first 2 bytes), convert to UTF-8 and normalize line endings to LF
dd if="$temp_file" bs=1 skip=2 2>/dev/null | iconv -f UTF-16LE -t UTF-8 | sed 's/\r$//'
