# 🎵 Audio Player

A modern and intuitive audio player for playing AAC (and other formats) files organized in folders. Works on any web hosting with PHP support.

## 📋 Features

- ✅ Playback of AAC, M4A, MP3, WAV, OGG, FLAC audio files
- 📁 Automatic folder organization
- 🔤 Alphabetical sorting of folders and files
- ⏯️ Complete controls: Play, Pause, Stop, Forward, Backward
- 📊 Interactive progress bar with visual feedback
- 🔊 Volume control with dynamic gradient
- 📑 Playlist queue
- 🎨 Modern responsive interface
- 🔄 Automatic playback of next track
- 🌐 Compatible with standard hosting (requires only PHP)
- ⚡ No API calls: everything integrated in a single page
- 📱 Mobile-optimized interface with touch controls
- 🎛️ Multiple playback modes (Single Track, Sequential, Repeat)
- ⚡ Speed control (0.75x, 1x, 1.5x, 2x)
- 🎨 Multiple themes with customizable colors and styles
- 🔧 Configurable settings per environment

## 🚀 How to Use

### 1. Setup

Upload the player files to your hosting:

```
yoursite.com/player/
├── index.php         ← Main file (contains everything)
├── style.css         ← Styles
├── script.js         ← JavaScript logic
├── conf.json         ← Global configuration
├── README.md
└── media/            ← Audio files folder
    ├── course1/
    │   ├── info.json ← Environment-specific config
    │   ├── lesson01/
    │   │   ├── part1.aac
    │   │   ├── part2.aac
    │   │   └── part3.aac
    │   └── lesson02/
    │       ├── part1.aac
    │       └── part2.aac
    └── course2/
        ├── info.json
        └── module1/
            ├── track1.m4a
            └── track2.m4a
```

### 2. Audio File Organization

The player uses a **dual structure** to keep original and converted files separate:

#### 📁 Directory Structure:

```
player/
├── media-orig/          ← ORIGINAL files (backup)
│   ├── Course1/
│   │   ├── audio1.aac
│   │   └── audio2.aac
│   └── Course2/
│       └── recording.m4a
│
└── media/               ← CONVERTED files (for player)
    ├── Course1/
    │   ├── info.json    ← Course configuration
    │   ├── lesson01/
    │   │   ├── part1.aac
    │   │   └── part2.aac
    │   └── lesson02/
    │       └── part1.aac
    └── Course2/
        ├── info.json
        └── module1/
            └── part1.aac
```

#### 🔄 Workflow:

1. **Insert original files** in `media-orig/` organized by folders
2. **Run the conversion script**:
   ```bash
   ./convert_audio.sh                 # Convert everything
   ./convert_audio.sh Course1         # Convert only one folder
   ```
3. **The player will read** files from `media/` (with correct metadata and perfect seeking)

#### ✨ Benefits:

- **Automatic backup**: Original files remain in `media-orig/`
- **Correct metadata**: Files in `media/` have perfect seeking
- **Ordered names**: `part1.aac`, `part2.aac`, etc. (original alphabetical order)
- **Easy reconversion**: Re-run the script if you add new files
- **Incremental**: Script converts only new or modified files

### 3. Configuration

#### Global Configuration (`conf.json`):

```json
{
  "common": {
    "settings": {
      "defaultVolume": 0.8,
      "defaultPlaybackMode": "sequential",
      "debug": false
    },
    "features": {
      "playbackSpeeds": [0.75, 1.0, 1.5, 2.0]
    },
    "ui": {
      "theme": "default",
      "showFileSize": true,
      "enableAnimations": true
    }
  },
  "themes": {
    "default": {
      "primaryColor": "#667eea",
      "secondaryColor": "#c3cfe2",
      "accentColor": "#764ba2",
      "backgroundColor": "#ffffff",
      "surfaceColor": "#f8f9fa",
      "gradientStart": "#667eea",
      "gradientEnd": "#764ba2",
      "fontFamily": "Segoe UI, Tahoma, Geneva, Verdana, sans-serif",
      "fontWeight": "normal",
      "textColor": "#333333",
      "buttonStyle": "rounded"
    }
  }
}
```

#### Environment-Specific Configuration (`media/course/info.json`):

```json
{
  "title": "Course Title",
  "common": {
    "settings": {
      "defaultVolume": 0.7,
      "defaultPlaybackMode": "repeat"
    },
    "ui": {
      "theme": "coral"
    }
  },
  "albums": [
    {
      "title": "Lesson 01",
      "tracks": [
        {
          "title": "Introduction",
          "file": "part1.aac"
        },
        {
          "title": "Main Content",
          "file": "part2.aac"
        }
      ]
    }
  ]
}
```

### 4. Hosting Configuration

**Minimum requirements:**
- ✅ PHP 5.6 or higher (recommended PHP 7.4+)
- ✅ Basic PHP functions (`scandir`, `is_dir`, `is_file`)
- ✅ No database required
- ✅ No additional modules needed

**File permissions:**
- `index.php` must be executable by the web server
- The `media/` folder and its subfolders must be readable
- Audio files must be readable

### 5. Access

Open your browser and go to your URL:

```
https://yoursite.com/player/?id=course1
```

or

```
https://yoursite.com/player/?id=course2
```

💡 **Tip**: If your hosting supports "index.php" as the default page, you can omit "index.php" from the URL.

### 6. Using the Player

1. **Expand a folder**: Click on the folder name in the left sidebar
2. **Choose a track**: Click on an audio file - playback starts automatically
3. **Control playback**:
   - ⏯️ **Play/Pause** - Start or pause
   - ⏹️ **Stop** - Stop and return to beginning
   - ⏮️ **Previous** - Go to previous track in folder
   - ⏭️ **Next** - Go to next track
4. **Adjust volume**: Use the volume slider
5. **Skip to a point**: Click on the progress bar
6. **Playlist queue**: Click on any track in the queue to play it
7. **Playback modes**: Switch between Single Track, Sequential, and Repeat
8. **Speed control**: Adjust playback speed (0.75x to 2x)

## 🎛️ Advanced Features

- **Automatic queue**: When you select a file, all tracks from the same folder are added to the queue
- **Current track**: Highlighted in blue both in the list and in the queue
- **Sequential auto-play**: When a track ends, the next one starts automatically
- **Smart sorting**: All files and folders are sorted alphabetically (natural)
- **Quick click**: Click on any track in the queue to jump directly to that track
- **Live information**: See the current track title and belonging folder
- **Mobile optimization**: Touch-friendly interface with dropdown album selection
- **Theme system**: Multiple themes with customizable colors and styles
- **Responsive design**: Works perfectly on desktop and mobile devices

## 🔧 Technical Requirements

**Server:**
- PHP 5.6+ (recommended PHP 7.4 or PHP 8.x)
- No database
- No additional server processes
- No complex configuration

**Client (Browser):**
- Modern browser with HTML5 Audio support
- JavaScript enabled
- CSS3 support for interface

## 📁 Project File Structure

```
player/
├── index.php        # Main page with integrated folder scanning
├── style.css        # Styles and responsive design
├── script.js        # Player logic and audio management
├── conf.json        # Global configuration
├── README.md        # This documentation
└── media/           # Main audio files folder
    └── [courses]/  # Your subfolders with audio files
        ├── info.json ← Course configuration
        └── [albums]/ ← Album folders
            └── *.aac # Your audio files
```

**What index.php does:**
1. Automatically scans the `media/` folder and its subfolders
2. Finds all audio files (aac, m4a, mp3, wav, ogg, flac)
3. Sorts folders and files alphabetically
4. Injects data directly into the HTML page
5. Serves the player interface

## 🎨 Design and UI

The interface has been designed with:
- ✨ Modern purple/blue gradient
- 📱 Responsive design (works on mobile and desktop)
- 🎯 Vector SVG icons for clear controls
- 🎭 Smooth animations and transitions
- 📐 Optimized grid layout
- 🎨 Hover effects and visual feedback
- 🎨 Multiple themes with customizable colors
- 📱 Mobile-optimized touch controls

## 🌐 Supported Audio Formats

| Format | Extension | Browser Support |
|--------|-----------|-----------------|
| AAC | `.aac`, `.m4a` | Chrome, Firefox, Safari, Edge |
| MP3 | `.mp3` | All modern browsers |
| WAV | `.wav` | All modern browsers |
| OGG | `.ogg` | Chrome, Firefox, Edge |
| FLAC | `.flac` | Chrome, Firefox, Edge (limited) |

💡 **Note**: AAC/M4A and MP3 have the best cross-browser support.

## 🎨 Themes

The player includes multiple built-in themes:

- **Default**: Blue-purple gradient with rounded buttons
- **Coral**: Warm coral colors with rounded buttons
- **Rose**: Pink rose colors with rounded buttons
- **Ocean**: Blue ocean colors with rounded buttons
- **Forest**: Green forest colors with rounded buttons
- **Sunset**: Orange sunset colors with rounded buttons
- **Midnight**: Dark theme with rounded buttons
- **Minimal**: Clean minimal design with square buttons
- **Modern**: Contemporary design with pill-shaped buttons
- **Classic**: Traditional design with square buttons

Each theme includes:
- Primary and secondary colors
- Background gradients
- Font settings
- Button styles (rounded, square, pill)

## 🐛 Troubleshooting

### No folders displayed

**Possible causes:**
- ✗ No subfolders in the player directory
- ✗ Folders don't contain audio files
- ✗ Folder permissions are incorrect

**Solutions:**
1. Verify there are subfolders (not files in the main directory)
2. Check that files have supported extensions
3. Verify permissions: `chmod 755` for folders
4. Check that `index.php` can execute `scandir()`

### Audio files don't play

**Possible causes:**
- ✗ Browser doesn't support the audio format
- ✗ File is corrupted or not a real audio file
- ✗ Problem with file permissions

**Solutions:**
1. Open browser Console (F12 > Console) to see errors
2. Try with an MP3 file (maximum compatibility)
3. Verify the file is accessible: try opening the URL directly
4. Check permissions: `chmod 644` for audio files

### PHP error or blank page

**Possible causes:**
- ✗ PHP is not enabled
- ✗ PHP version too old
- ✗ Syntax error

**Solutions:**
1. Verify PHP is enabled: create an `info.php` file with `<?php phpinfo(); ?>`
2. Check PHP version in hosting control panel
3. Enable PHP error logs to see what's wrong
4. Contact your hosting support if necessary

### Local testing

To test the player on your computer:

**With PHP installed:**
```bash
cd /path/to/player
php -S localhost:8000

# Open in browser: http://localhost:8000
```

**With XAMPP/WAMP/MAMP:**
- Copy files to `htdocs` folder (or equivalent)
- Open `http://localhost/player/`

**With Docker:**
```bash
docker run -d -p 8080:80 -v $(pwd):/var/www/html php:7.4-apache
# Open: http://localhost:8080
```

## 📝 Important Notes

- ✅ The player scans **only the media/** folder and its subfolders
- ✅ Audio files must be inside subfolders in `media/`, not directly in `media/`
- ✅ Hidden files/folders (starting with `.`) are ignored
- ✅ Only files with audio extensions are processed
- ✅ Full UTF-8 support for international file names
- ✅ No database or configuration modifications needed
- ✅ Mobile-optimized interface with touch controls
- ✅ Multiple themes and customizable settings

## 🔒 Security

The player implements basic security measures:
- ✅ Automatic filtering of system and hidden files
- ✅ Only audio extensions are accepted
- ✅ No access to parent directories
- ✅ No server-side code execution from user input
- ✅ UTF-8 encoding to prevent XSS

## 🌐 Supported Browsers

| Browser | Version | Support |
|---------|---------|---------|
| Chrome | 50+ | ✅ Complete |
| Firefox | 52+ | ✅ Complete |
| Safari | 11+ | ✅ Complete |
| Edge | 79+ | ✅ Complete |
| Opera | 37+ | ✅ Complete |
| IE | - | ❌ Not supported |

## 🚀 Optimizations

The player is optimized for:
- ⚡ Fast loading (everything in one page)
- 📦 No external dependencies (no jQuery, no libraries)
- 🎯 Minimal and efficient code
- 💾 No database usage
- 🔄 No AJAX calls (embedded data)
- 📱 Mobile-first responsive design
- 🎨 CSS variables for theme switching
- ⚡ Efficient audio metadata extraction

## 💡 Tips

1. **File naming**: Use numeric prefixes for sorting (e.g. "01 -", "02 -")
2. **Formats**: Prefer MP3 or AAC/M4A for maximum compatibility
3. **Organization**: One folder = one album/playlist
4. **Backup**: Always backup original audio files
5. **Testing**: Test on different browsers before deployment
6. **Mobile**: Test on real mobile devices, not just simulators
7. **Themes**: Choose themes that match your content style

## 📄 License

This project is open source and available for personal and commercial use.

## 🆘 Support

For problems or questions:
1. Check this documentation
2. Verify server error logs
3. Check browser JavaScript console (F12)
4. Verify PHP is enabled and working
5. Test with different browsers and devices

---

**Happy listening! 🎶**

Version: 3.0 (Enhanced with themes, mobile optimization, and advanced features)