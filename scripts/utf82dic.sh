#!/bin/bash
# Converts UTF-8 text from stdin to Word dictionary UTF-16LE + BOM + CRLF
# Normalizes any line terminator to CRLF

# typically used to convert UTF-8 text to Word dictionary ".DIC" format

# How it works:
# 1. Save stdin to temporary file for validation and processing
# 2. Validate that input is valid UTF-8
# 3. sed 's/\r$//' → remove any trailing CR from lines already terminated by CR or CRLF.
# 4. sed 's/$/\r/' → add CR before LF (Word wants CRLF in UTF-16LE).
# 5. iconv -f UTF-8 -t UTF-16LE → convert the normalized input to UTF-16LE.
# 6. echo -ne '\xff\xfe' → write the UTF-16LE BOM at the beginning.

# Enable strict error handling
set -e
set -o pipefail

# Create a temporary file to save stdin
temp_file=$(mktemp)
trap "rm -f '$temp_file'" EXIT

# Save stdin to the temporary file
cat > "$temp_file"

# Validate that the input is valid UTF-8
if ! iconv -f UTF-8 -t UTF-8 < "$temp_file" > /dev/null 2>&1; then
    echo "Error: Input contains invalid UTF-8 sequences" >&2
    exit 1
fi

# Write UTF-16LE BOM
echo -ne '\xff\xfe'

# Normalize line endings to CRLF, then convert to UTF-16LE
sed 's/\r$//' < "$temp_file" | sed 's/$/\r/' | iconv -f UTF-8 -t UTF-16LE
