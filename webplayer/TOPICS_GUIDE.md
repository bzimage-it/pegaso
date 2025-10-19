# 🎵 Guide - Topics System

## 📁 3-Level Structure

```
player/
├── conf.json                                    ← Global configuration
├── media/
│   ├── course_biblical-liturgical_2025_2026/    ← Topic 1
│   │   ├── info.json                           ← Topic configuration
│   │   ├── lesson01/                           ← Album 1
│   │   │   ├── part1.aac
│   │   │   ├── part2.aac
│   │   │   └── part3.aac
│   │   ├── lesson02/                           ← Album 2
│   │   │   ├── part1.aac
│   │   │   └── part2.aac
│   │   └── lesson03/
│   │       └── part1.aac
│   └── example_course/                         ← Topic 2
│       ├── info.json
│       ├── module1/
│       │   ├── part1.aac
│       │   └── part2.aac
│       └── module2/
│           └── part1.aac
```

## ⚙️ Configuration System

### Global Configuration (`conf.json`)

Contains global settings, themes, and default configurations:

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
    },
    "coral": {
      "primaryColor": "#ff6b6b",
      "secondaryColor": "#ffa8a8",
      "accentColor": "#ff8e8e",
      "backgroundColor": "#fff5f5",
      "surfaceColor": "#ffe0e0",
      "gradientStart": "#ff6b6b",
      "gradientEnd": "#ff8e8e",
      "fontFamily": "Segoe UI, Tahoma, Geneva, Verdana, sans-serif",
      "fontWeight": "normal",
      "textColor": "#333333",
      "buttonStyle": "rounded"
    }
  }
}
```

### Topic-Specific Configuration (`media/course/info.json`)

Each topic can override global settings and define its albums:

```json
{
  "title": "Biblical-Liturgical Formation Course 2025-2026",
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
      "title": "Lesson 01 - Introduction",
      "tracks": [
        {
          "title": "Welcome and Overview",
          "file": "part1.aac"
        },
        {
          "title": "Main Content",
          "file": "part2.aac"
        },
        {
          "title": "Conclusion",
          "file": "part3.aac"
        }
      ]
    },
    {
      "title": "Lesson 02 - Deep Dive",
      "tracks": [
        {
          "title": "Part 1",
          "file": "part1.aac"
        },
        {
          "title": "Part 2",
          "file": "part2.aac"
        }
      ]
    }
  ]
}
```

### Configuration Fields:

#### Global (`conf.json`):
- **`common.settings.defaultVolume`**: Default volume (0.0-1.0)
- **`common.settings.defaultPlaybackMode`**: Default mode (`single`, `sequential`, `repeat`)
- **`common.settings.debug`**: Enable debug mode
- **`common.features.playbackSpeeds`**: Available speed options
- **`common.ui.theme`**: Default theme name
- **`common.ui.showFileSize`**: Show file sizes in interface
- **`common.ui.enableAnimations`**: Enable UI animations
- **`themes`**: Theme definitions with colors and styles

#### Topic-Specific (`media/course/info.json`):
- **`title`**: Topic title (shown in header and browser title)
- **`common`**: Override global settings (optional)
- **`albums`**: Array of album definitions
  - **`title`**: Album name
  - **`tracks`**: Array of track definitions
    - **`title`**: Track name (optional, falls back to metadata or filename)
    - **`file`**: Audio filename

## 🌐 URL Access

```
http://yoursite.com/player/?id=course_biblical-liturgical_2025_2026
http://yoursite.com/player/?id=example_course
```

The player will show:
- **Title** in the header bar
- **Title** in the browser `<title>`
- **Albums** from the selected topic
- **Custom theme** if specified in topic config

## 🔄 File Conversion

### Syntax:

```bash
./convert_audio.sh <source-dir> <target-dir> [--profile <name>] [--fix-whatsapp-aac] [permutation...]
```

### Examples:

#### 1. Basic Conversion

```bash
# Convert files from media-orig/lesson1 to media/course_biblical-liturgical_2025_2026/lesson01
./convert_audio.sh media-orig/lesson1 media/course_biblical-liturgical_2025_2026/lesson01
```

#### 2. With Quality Profile

```bash
# Use specific quality profile
./convert_audio.sh media-orig/lesson1 media/course_biblical-liturgical_2025_2026/lesson01 --profile web
./convert_audio.sh media-orig/lesson1 media/course_biblical-liturgical_2025_2026/lesson01 --profile mobile
./convert_audio.sh media-orig/lesson1 media/course_biblical-liturgical_2025_2026/lesson01 --profile podcast
```

Available profiles:
- **`web`** (default): Balanced quality for web streaming (64kbps AAC)
- **`mobile`**: Optimized for mobile data (48kbps AAC)
- **`podcast`**: High quality for podcasts (96kbps AAC)
- **`best`**: Maximum quality (128kbps AAC)

#### 3. With Reordering

```bash
# File 2 becomes part1, file 3 becomes part2, file 1 becomes part3
./convert_audio.sh media-orig/lesson1 media/course_biblical-liturgical_2025_2026/lesson01 2 3 1
```

#### 4. Fix WhatsApp AAC Files

```bash
# Fix WhatsApp AAC files for proper playback and seeking
./convert_audio.sh media-orig/lesson1 media/course_biblical-liturgical_2025_2026/lesson01 --fix-whatsapp-aac
```

#### 5. From External Directory

```bash
# Convert from external directory
./convert_audio.sh ~/Audio/Recordings media/course/module1
```

## 📋 Complete Workflow

### 1. Add a New Topic

**a) Create structure in `media/`:**

```bash
mkdir -p media/new_course
mkdir -p media/new_course/lesson01
mkdir -p media/new_course/lesson02
```

**b) Create topic configuration `media/new_course/info.json`:**

```json
{
  "title": "New Course Example",
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
      "tracks": []
    },
    {
      "title": "Lesson 02", 
      "tracks": []
    }
  ]
}
```

### 2. Convert Audio Files

```bash
# Lesson 1
./convert_audio.sh media-orig/audio_lesson1 media/new_course/lesson01 --profile web

# Lesson 2 with reordering
./convert_audio.sh media-orig/audio_lesson2 media/new_course/lesson02 --profile mobile 3 1 2

# Lesson 3 with WhatsApp fix
./convert_audio.sh media-orig/whatsapp_audio media/new_course/lesson03 --fix-whatsapp-aac
```

### 3. Access the Player

```
http://localhost:8000/?id=new_course
```

## 🎯 Practical Examples

### Example 1: Training Course

```bash
# 1. Create structure
mkdir -p media/training_2025/{module1,module2,module3}

# 2. Create configuration
# Create media/training_2025/info.json:
{
  "title": "Training 2025",
  "common": {
    "ui": {
      "theme": "ocean"
    }
  },
  "albums": [
    {
      "title": "Module 1 - Basics",
      "tracks": []
    },
    {
      "title": "Module 2 - Advanced",
      "tracks": []
    },
    {
      "title": "Module 3 - Practice",
      "tracks": []
    }
  ]
}

# 3. Convert files
./convert_audio.sh ~/Recordings/Module1 media/training_2025/module1 --profile web
./convert_audio.sh ~/Recordings/Module2 media/training_2025/module2 --profile podcast
./convert_audio.sh ~/Recordings/Module3 media/training_2025/module3 --profile mobile

# 4. Access
# http://localhost:8000/?id=training_2025
```

### Example 2: Podcast Series

```bash
# 1. Create structure
mkdir -p media/podcast_2025/{january,february,march}

# 2. Create configuration
# Create media/podcast_2025/info.json:
{
  "title": "Podcast 2025",
  "common": {
    "settings": {
      "defaultPlaybackMode": "sequential"
    },
    "ui": {
      "theme": "sunset"
    }
  },
  "albums": [
    {
      "title": "January Episodes",
      "tracks": []
    },
    {
      "title": "February Episodes", 
      "tracks": []
    },
    {
      "title": "March Episodes",
      "tracks": []
    }
  ]
}

# 3. Convert files
./convert_audio.sh ~/Podcast/January media/podcast_2025/january --profile podcast
./convert_audio.sh ~/Podcast/February media/podcast_2025/february --profile podcast

# 4. URL: ?id=podcast_2025
```

## 🎨 Themes

### Available Themes:

- **`default`**: Blue-purple gradient with rounded buttons
- **`coral`**: Warm coral colors with rounded buttons
- **`rose`**: Pink rose colors with rounded buttons
- **`ocean`**: Blue ocean colors with rounded buttons
- **`forest`**: Green forest colors with rounded buttons
- **`sunset`**: Orange sunset colors with rounded buttons
- **`midnight`**: Dark theme with rounded buttons
- **`minimal`**: Clean minimal design with square buttons
- **`modern`**: Contemporary design with pill-shaped buttons
- **`classic`**: Traditional design with square buttons

### Theme Structure:

```json
{
  "primaryColor": "#667eea",        // Main accent color
  "secondaryColor": "#c3cfe2",     // Secondary color
  "accentColor": "#764ba2",        // Accent color
  "backgroundColor": "#ffffff",    // Background color
  "surfaceColor": "#f8f9fa",       // Surface color
  "gradientStart": "#667eea",      // Gradient start
  "gradientEnd": "#764ba2",        // Gradient end
  "fontFamily": "Segoe UI, ...",   // Font family
  "fontWeight": "normal",          // Font weight
  "textColor": "#333333",          // Text color
  "buttonStyle": "rounded"         // Button style (rounded, square, pill)
}
```

## 📝 Important Notes

### ✅ TO DO:

- Use unique IDs in topic directory names
- Create target directories before conversion
- Verify that `info.json` files are valid JSON
- Use directory names without spaces (use `_` or `-`)
- Test on both desktop and mobile devices
- Choose appropriate themes for your content

### ❌ DON'T DO:

- Don't use spaces in directory names (e.g. `"course 2025"` ❌, use `"course_2025"` ✅)
- Don't put audio files directly in `media/topic/` (use subfolders/albums)
- Don't manually modify converted files
- Don't forget to create `info.json` for each topic
- Don't use unsupported audio formats

## 🔍 Troubleshooting

### Player shows "Invalid ID" or "info.json not found"

**Cause:** Topic ID not found or directory doesn't exist

**Solution:**
1. Verify the ID in the URL matches the directory name
2. Check that `media/topic_name/info.json` exists
3. Verify the directory structure is correct

### Audio files not found (404)

**Cause:** Incorrect path

**Solution:**
1. Verify files are in `media/topic_name/album_name/part*.aac`
2. Check file permissions
3. Ensure conversion script ran successfully

### JSON Error

**Cause:** Invalid `info.json` or `conf.json`

**Solution:**
Validate JSON: `python3 -m json.tool conf.json`
Validate JSON: `python3 -m json.tool media/topic_name/info.json`

### Theme not applied

**Cause:** Theme name not found or CSS not loading

**Solution:**
1. Check theme name in `conf.json` or `info.json`
2. Verify CSS file is loading
3. Check browser console for errors

### Mobile interface issues

**Cause:** CSS or JavaScript not loading properly

**Solution:**
1. Check file paths are correct
2. Verify mobile detection is working
3. Test on real mobile device, not just simulator

## 📊 Useful Commands

```bash
# View structure
tree media/ -L 3

# Validate conf.json
python3 -m json.tool conf.json

# Validate topic info.json
python3 -m json.tool media/topic_name/info.json

# Count files per topic
find media/training_2025 -name "*.aac" | wc -l

# List all topics
ls media/

# Check conversion script help
./convert_audio.sh --help

# Test conversion with dry run
./convert_audio.sh --help
```

## 🎛️ Advanced Features

### Playback Modes:
- **Single Track**: Play only the selected track
- **Sequential**: Play tracks in order, stop at the end
- **Repeat**: Play tracks in order, loop continuously

### Speed Control:
- **0.75x**: Slower playback
- **1.0x**: Normal speed
- **1.5x**: Faster playback
- **2.0x**: Maximum speed

### Mobile Optimization:
- **Touch-friendly controls**: Larger buttons and touch targets
- **Dropdown album selection**: Space-efficient album chooser
- **Tab-based track selection**: Easy track navigation
- **Responsive layout**: Adapts to different screen sizes

---

**Happy working! 🎶**