# 🎵 Quick Start Guide - Audio Player

## 📋 Initial Setup

### 1. Organize Original Files

Put your audio files in `media-orig/` organized by folders:

```bash
media-orig/
├── Rock Album/
│   ├── track_001.aac
│   ├── track_002.aac
│   └── track_003.aac
├── Podcast/
│   └── episode_2024.m4a
└── Audiobook/
    ├── chapter1.aac
    └── chapter2.aac
```

### 2. Convert Files

Run the conversion script:

```bash
# Convert from source directory to target directory
./convert_audio.sh media-orig/RockAlbum media/RockAlbum

# With quality profile
./convert_audio.sh media-orig/Podcast media/Podcast --profile podcast

# Fix AAC Duration/Seeking Issues

```bash
# Fix AAC files with corrupted metadata for proper seeking and playback
./convert_audio.sh media-orig/Audiobook media/Audiobook --fix-duration-seeking-aac
```

#### Available Quality Profiles:

- **`mobile`** - 32kbps (~7MB per 30min) - Very slow connections
- **`bandwidth`** - 48kbps (~11MB per 30min) - Economic hosting  
- **`web`** - 64kbps (~15MB per 30min) - Standard web streaming (default)
- **`podcast`** - 80kbps (~18MB per 30min) - Spoken content
- **`quality`** - 96kbps (~22MB per 30min) - High quality
- **`archive`** - 128kbps (~30MB per 30min) - Maximum quality

### 3. Start the Server

```bash
./START_SERVER.sh
```

Or manually:
```bash
php -S localhost:8000 serve_audio.php
```

### 4. Open in Browser

Go to: **http://localhost:8000**

---

## 🔄 File Updates

### When adding new files:

1. Add files to `media-orig/NewFolder/`
2. Run: `./convert_audio.sh media-orig/NewFolder media/NewFolder`
3. Reload the browser page

### When modifying existing files:

1. Replace files in `media-orig/`
2. Run: `./convert_audio.sh media-orig/FolderName media/FolderName`
3. The script will ask if you want to overwrite existing files

---

## 📁 File Structure

```
player/
├── index.php                 # Main page
├── style.css                 # Styles
├── script.js                 # Player logic
├── serve_audio.php          # Server with range requests
├── START_SERVER.sh          # Server startup script
├── convert_audio.sh         # Conversion script
│
├── media-orig/              # ← YOUR ORIGINAL FILES
│   ├── Folder1/
│   └── Folder2/
│
└── media/                   # ← Files for the player (generated)
    ├── Folder1/
    │   ├── part1.aac
    │   └── part2.aac
    └── Folder2/
        └── part1.aac
```

---

## 🛠️ Useful Commands

### Conversion

```bash
# Convert from source to target directory
./convert_audio.sh media-orig/FolderName media/FolderName

# With quality profile
./convert_audio.sh media-orig/FolderName media/FolderName --profile quality

# Fix WhatsApp AAC files
./convert_audio.sh media-orig/FolderName media/FolderName --fix-whatsapp-aac

# Reorder files (file 2 becomes part1, file 3 becomes part2, file 1 becomes part3)
./convert_audio.sh media-orig/FolderName media/FolderName 2 3 1
```

### Server

```bash
# Start server
./START_SERVER.sh

# Or manually with custom port
php -S localhost:3000 serve_audio.php
```

### File Management

```bash
# See what's in media-orig
ls -la media-orig/

# See what's in media (converted)
ls -la media/

# Space used
du -sh media-orig/
du -sh media/
```

---

## ⚠️ Important Notes

### ✅ TO DO:
- Put audio files in `media-orig/`
- Use subfolders to organize (each folder = album/playlist)
- Run `convert_audio.sh` after every addition

### ❌ DON'T DO:
- DON'T manually modify files in `media/` (they get regenerated)
- DON'T delete `media-orig/` (it's your backup!)
- DON'T put files directly in `media-orig/` (use subfolders)

---

## 🎯 Troubleshooting

### Seek doesn't work correctly
→ Reconvert files: `./convert_audio.sh media-orig/FolderName media/FolderName`

### No folders displayed
→ Check that `media/` contains subfolders with audio files

### File not found (404)
→ Make sure server is started with `serve_audio.php`

### ffmpeg not found
→ Install ffmpeg:
```bash
# Ubuntu/Debian
sudo apt-get install ffmpeg

# Fedora
sudo dnf install ffmpeg

# Arch
sudo pacman -S ffmpeg
```

---

## 📊 Complete Example

```bash
# 1. Copy your files
cp -r ~/Audio/MyAlbum media-orig/

# 2. Convert
./convert_audio.sh media-orig/MyAlbum media/MyAlbum

# 3. Start server
./START_SERVER.sh

# 4. Open browser
firefox http://localhost:8000
```

---

**Happy listening! 🎶**

