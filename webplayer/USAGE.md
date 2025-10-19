# 🎵 Guida Rapida - Audio Player

## 📋 Setup Iniziale

### 1. Organizza i File Originali

Metti i tuoi file audio in `media-orig/` organizzati per cartelle:

```bash
media-orig/
├── Album Rock/
│   ├── track_001.aac
│   ├── track_002.aac
│   └── track_003.aac
├── Podcast/
│   └── episodio_2024.m4a
└── Audiolibro/
    ├── capitolo1.aac
    └── capitolo2.aac
```

### 2. Converti i File

Esegui lo script di conversione:

```bash
# Converti TUTTO
./convert_media.sh

# Oppure converti solo una cartella specifica
./convert_media.sh "Album Rock"
./convert_media.sh Podcast
```

### 3. Avvia il Server

```bash
./START_SERVER.sh
```

Oppure manualmente:
```bash
php -S localhost:8000 serve_audio.php
```

### 4. Apri nel Browser

Vai su: **http://localhost:8000**

---

## 🔄 Aggiornamento File

### Quando aggiungi nuovi file:

1. Aggiungi i file in `media-orig/NuovaCartella/`
2. Esegui: `./convert_media.sh NuovaCartella`
3. Ricarica la pagina del browser

### Quando modifichi file esistenti:

1. Sostituisci i file in `media-orig/`
2. Esegui: `./convert_media.sh NomeCartella`
3. Lo script riconverte solo i file modificati

---

## 📁 Struttura File

```
player/
├── index.php                 # Pagina principale
├── style.css                 # Stili
├── script.js                 # Logica player
├── serve_audio.php          # Server con range requests
├── START_SERVER.sh          # Script avvio server
├── convert_media.sh         # Script conversione
│
├── media-orig/              # ← I TUOI FILE ORIGINALI
│   ├── Cartella1/
│   └── Cartella2/
│
└── media/                   # ← File per il player (generati)
    ├── Cartella1/
    │   ├── parte1.aac
    │   └── parte2.aac
    └── Cartella2/
        └── parte1.aac
```

---

## 🛠️ Comandi Utili

### Conversione

```bash
# Converti tutto
./convert_media.sh

# Converti una cartella
./convert_media.sh "Nome Cartella"

# Riconverti tutto (aggiorna solo file modificati)
./convert_media.sh
```

### Server

```bash
# Avvia server
./START_SERVER.sh

# O manualmente con porta personalizzata
php -S localhost:3000 serve_audio.php
```

### Gestione File

```bash
# Vedi cosa c'è in media-orig
ls -la media-orig/

# Vedi cosa c'è in media (convertiti)
ls -la media/

# Spazio occupato
du -sh media-orig/
du -sh media/
```

---

## ⚠️ Note Importanti

### ✅ DA FARE:
- Inserire file audio in `media-orig/`
- Usare sottocartelle per organizzare (ogni cartella = album/playlist)
- Eseguire `convert_media.sh` dopo ogni aggiunta

### ❌ NON FARE:
- NON modificare manualmente i file in `media/` (vengono rigenerati)
- NON eliminare `media-orig/` (è il tuo backup!)
- NON mettere file direttamente in `media-orig/` (usa sottocartelle)

---

## 🎯 Risoluzione Problemi

### Il seek non funziona correttamente
→ Riconverti i file: `./convert_media.sh`

### Nessuna cartella visualizzata
→ Verifica che `media/` contenga sottocartelle con file audio

### File non trovato (404)
→ Controlla che il server sia avviato con `serve_audio.php`

### ffmpeg non trovato
→ Installa ffmpeg:
```bash
# Ubuntu/Debian
sudo apt-get install ffmpeg

# Fedora
sudo dnf install ffmpeg

# Arch
sudo pacman -S ffmpeg
```

---

## 📊 Esempio Completo

```bash
# 1. Copia i tuoi file
cp -r ~/Audio/MioAlbum media-orig/

# 2. Converti
./convert_media.sh MioAlbum

# 3. Avvia server
./START_SERVER.sh

# 4. Apri browser
firefox http://localhost:8000
```

---

**Buon ascolto! 🎶**

