#!/bin/bash
# Converte testo UTF-8 da stdin in dizionario Word UTF-16LE + BOM + CRLF
# Normalizza qualsiasi terminatore di riga in CRLF

# Come funziona:
# sed 's/\r$//' → rimuove eventuale CR finale in righe già terminate da CR o CRLF.
# sed 's/$/\r/' → aggiunge CR prima di LF (Word vuole CRLF in UTF‑16LE).
# iconv -f UTF-8 -t UTF-16LE → converte l’input normalizzato in UTF‑16LE.
# echo -ne '\xff\xfe' → scrive il BOM UTF-16LE all’inizio.


# Scrivi BOM UTF-16LE
echo -ne '\xff\xfe'

# Normalizza line ending a CRLF, poi converte in UTF-16LE
sed 's/\r$//' | sed 's/$/\r/' | iconv -f UTF-8 -t UTF-16LE
