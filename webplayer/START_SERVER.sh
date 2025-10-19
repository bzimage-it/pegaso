#!/bin/bash
# Script per avviare il server PHP con supporto Range Requests

echo "╔══════════════════════════════════════════════╗"
echo "║        Audio Player Server                   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "🎵 Avvio server su: http://localhost:8000"
echo "📁 Directory: $(pwd)"
echo ""
echo "⚠️  Per fermare il server premi Ctrl+C"
echo ""

# Avvia il server PHP con il router per le range requests
php -S localhost:8000 serve_audio.php

