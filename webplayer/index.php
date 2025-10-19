<?php
/**
 * Audio Player - Main Page
 * Scans directories and embeds the data directly into the page
 */

// Get argomento ID from URL - this is now the directory name directly
$argomentoId = isset($_GET['id']) ? $_GET['id'] : null;

// Load configuration files
$baseDir = __DIR__;
$confFile = $baseDir . DIRECTORY_SEPARATOR . 'conf.json';

// Load global configuration
$globalConfig = [];
$themes = [];
$commonConfig = [];

if (file_exists($confFile)) {
    $confJson = file_get_contents($confFile);
    $globalConfig = json_decode($confJson, true);
    $themes = $globalConfig['themes'] ?? [];
    $commonConfig = $globalConfig['common'] ?? [];
}

// Load environment configuration if argomento ID is provided
$albumConfig = [];
$pageTitle = 'Audio Player';
$argomentoDir = $argomentoId;
$errorMessage = null;

if ($argomentoId) {
    $mediaDir = $baseDir . DIRECTORY_SEPARATOR . 'media' . DIRECTORY_SEPARATOR . $argomentoId;
    $infoFile = $mediaDir . DIRECTORY_SEPARATOR . 'info.json';
    
    // Check if directory exists
    if (!is_dir($mediaDir)) {
        $errorMessage = "ID non valido";
    } else if (!file_exists($infoFile)) {
        $errorMessage = "info.json inesistente";
    } else {
        // Load configuration
        $infoJson = file_get_contents($infoFile);
        $albumConfig = json_decode($infoJson, true);
        
        // Validate JSON
        if (json_last_error() !== JSON_ERROR_NONE) {
            $errorMessage = "Errore nel file di configurazione";
        } else {
            // Get title and theme from info.json
            $pageTitle = $albumConfig['title'] ?? $argomentoId;
            
            // Merge common configuration: global first, then environment-specific
            if (isset($albumConfig['common'])) {
                $commonConfig = array_merge($commonConfig, $albumConfig['common']);
            }
        }
    }
} else {
    // No ID provided
    $errorMessage = "ID non valido";
}

// If there's an error, show error page
if ($errorMessage) {
        ?>
        <!DOCTYPE html>
        <html lang="it">
        <head>
            <meta charset="UTF-8">
            <title>Errore - Audio Player</title>
        </head>
        <body>
            <h1>Errore di Configurazione</h1>
            <p>Non è stato possibile caricare l'ambiente audio richiesto.</p>
            <p><strong><?php echo htmlspecialchars($errorMessage); ?></strong></p>
        </body>
        </html>
        <?php
        exit;
    }

// Determine theme and configuration
$defaultTheme = [
    'primaryColor' => '#667eea',
    'secondaryColor' => '#c3cfe2',
    'accentColor' => '#764ba2',
    'backgroundColor' => '#ffffff',
    'surfaceColor' => '#f8f9fa',
    'gradientStart' => '#667eea',
    'gradientEnd' => '#764ba2',
    'fontFamily' => 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
    'fontWeight' => 'normal',
    'textColor' => '#333333',
    'textSecondary' => '#666666',
    'buttonStyle' => 'rounded'
];

$theme = $defaultTheme;
$selectedThemeName = $commonConfig['ui']['theme'] ?? 'default';

// Load theme from merged configuration
if (isset($themes[$selectedThemeName])) {
    $theme = array_merge($defaultTheme, $themes[$selectedThemeName]);
}

// Function to get audio metadata from file
function getAudioMetadata($filePath, $filename) {
    $extension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
    
    // Try to read metadata using ffprobe if available
    if (function_exists('shell_exec')) {
        $command = "ffprobe -v quiet -print_format json -show_format \"$filePath\" 2>/dev/null";
        $output = @shell_exec($command);
        
        if ($output) {
            $metadata = json_decode($output, true);
            if (isset($metadata['format']['tags']['title'])) {
                return trim($metadata['format']['tags']['title']);
            }
        }
    }
    
    // Fallback to filename without extension
    return pathinfo($filename, PATHINFO_FILENAME);
}

// Function to load albums from JSON configuration (authoritative)
function loadAlbumsFromJson($targetDir, $albumConfig = []) {
    $directories = [];
    $audioExtensions = ['aac', 'm4a', 'mp3', 'wav', 'ogg', 'flac', 'mp4'];
    
    // Check if target directory exists
    if (!is_dir($targetDir)) {
        return $directories;
    }
    
    // Only process albums defined in JSON
    if (!isset($albumConfig['albums'])) {
        return $directories;
    }
    
    foreach ($albumConfig['albums'] as $albumKey => $albumData) {
        $albumPath = $targetDir . DIRECTORY_SEPARATOR . $albumKey;
        
        // Verify album directory exists
        if (!is_dir($albumPath)) {
            error_log("Album directory not found: $albumKey");
            continue;
        }
        
        $audioFiles = [];
        
        // Scan all audio files in the directory
        $files = @scandir($albumPath);
        
        if ($files !== false) {
            foreach ($files as $file) {
                if ($file === '.' || $file === '..') {
                    continue;
                }
                
                $filePath = $albumPath . DIRECTORY_SEPARATOR . $file;
                $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
                
                if (is_file($filePath) && in_array($extension, $audioExtensions)) {
                    // 1. Check JSON configuration first
                    $trackTitle = null;
                    if (isset($albumData['tracks'])) {
                        foreach ($albumData['tracks'] as $track) {
                            if ($track['file'] === $file) {
                                $trackTitle = $track['title'];
                                break;
                            }
                        }
                    }
                    
                    // 2. If not found in JSON, try audio metadata
                    if (!$trackTitle) {
                        $trackTitle = getAudioMetadata($filePath, $file);
                    }
                    
                    $audioFiles[] = [
                        'name' => $trackTitle,
                        'file' => $file
                    ];
                }
            }
        }
        
        // Only add albums that contain audio files
        if (!empty($audioFiles)) {
            // Sort files alphabetically by name
            usort($audioFiles, function($a, $b) {
                return strcasecmp($a['name'], $b['name']);
            });
            
            $directories[] = [
                'name' => $albumData['title'],
                'key' => $albumKey,
                'description' => $albumData['description'] ?? '',
                'files' => $audioFiles
            ];
        }
    }
    
    // Sort directories alphabetically
    usort($directories, function($a, $b) {
        return strcasecmp($a['name'], $b['name']);
    });
    
    return $directories;
}

// Determine which directory to scan
$directories = [];
if ($argomentoDir) {
    $mediaDir = $baseDir . DIRECTORY_SEPARATOR . 'media' . DIRECTORY_SEPARATOR . $argomentoDir;
    $directories = loadAlbumsFromJson($mediaDir, $albumConfig);
}

$directoriesJson = json_encode($directories, JSON_UNESCAPED_UNICODE);
$argomentoPath = $argomentoDir ? $argomentoDir : '';
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title><?php echo htmlspecialchars($pageTitle); ?></title>
    <link rel="stylesheet" href="style.css">
    <style>
        /* Fallback CSS for Android */
        body { margin: 0; padding: 0; font-family: Arial, sans-serif; }
        .container { max-width: 100%; }
        .player-wrapper { padding: 10px; }
        .player-header h1 { color: #333; margin: 10px 0; }
        .main-content { display: flex; flex-direction: column; }
        .file-browser { background: #f5f5f5; padding: 10px; margin: 10px 0; }
        .directory-list { list-style: none; padding: 0; }
        .directory-list li { padding: 5px; border-bottom: 1px solid #ddd; }
        .controls { display: flex; gap: 10px; margin: 10px 0; }
        .control-btn { padding: 10px; border: 1px solid #ccc; background: #fff; }
        .progress-container { margin: 10px 0; }
        .progress-bar { width: 100%; height: 20px; background: #ddd; }
        .volume-container { margin: 10px 0; }
        @media (max-width: 768px) {
            .mobile-album-selector { display: block; }
            .file-browser { display: none; }
            .mobile-track-tabs { display: block; }
            .playlist-queue { display: none; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="player-wrapper">
            <!-- Header -->
            <header class="player-header">
                <h1>🎵 <?php echo htmlspecialchars($pageTitle); ?></h1>
            </header>

            <!-- Main Content -->
            <div class="main-content">
                <!-- Mobile Album Selector -->
                <div class="mobile-album-selector">
                    <label for="album-dropdown">Album:</label>
                    <select id="album-dropdown" class="album-dropdown">
                        <option value="">Seleziona un album...</option>
                    </select>
                </div>

                <!-- File Browser -->
                <aside class="file-browser">
                    <h2>Cartelle e File</h2>
                    <div id="directory-list" class="directory-list">
                        <div class="loading">Caricamento...</div>
                    </div>
                </aside>

                <!-- Player Section -->
                <main class="player-section">
                    <!-- Now Playing Info -->
                    <div class="now-playing">
                        <div class="track-info">
                            <h3 id="track-title">Nessun brano selezionato</h3>
                            <p id="track-folder">-</p>
                        </div>
                    </div>

                    <!-- Progress Bar -->
                    <div class="progress-container">
                        <span id="current-time">0:00</span>
                        <div class="progress-bar" id="progress-bar">
                            <div class="progress-fill" id="progress-fill"></div>
                            <div class="progress-handle" id="progress-handle"></div>
                        </div>
                        <span id="duration">0:00</span>
                    </div>

                    <!-- Controls -->
                    <div class="controls">
                        <button id="prev-btn" class="control-btn" title="Precedente">
                            <svg viewBox="0 0 24 24" width="24" height="24">
                                <path fill="currentColor" d="M6 6h2v12H6zm3.5 6l8.5 6V6z"/>
                            </svg>
                        </button>
                        <button id="skip-back-btn" class="control-btn control-btn-skip" title="Indietro">
                            <svg viewBox="0 0 24 24" width="24" height="24">
                                <path fill="currentColor" d="M11 18V6l-8.5 6 8.5 6zm.5-6l8.5 6V6l-8.5 6z"/>
                            </svg>
                        </button>
                        <button id="play-pause-btn" class="control-btn play-btn" title="Play">
                            <svg id="play-icon" viewBox="0 0 24 24" width="32" height="32" style="fill: white;">
                                <path fill="white" d="M8 5v14l11-7z"/>
                            </svg>
                            <svg id="pause-icon" viewBox="0 0 24 24" width="32" height="32" style="fill: white; display: none;">
                                <path fill="white" d="M6 4h4v16H6zm8 0h4v16h-4z"/>
                            </svg>
                        </button>
                        <button id="skip-forward-btn" class="control-btn control-btn-skip" title="Avanti">
                            <svg viewBox="0 0 24 24" width="24" height="24">
                                <path fill="currentColor" d="M4 18l8.5-6L4 6v12zm9-12v12l8.5-6L13 6z"/>
                            </svg>
                        </button>
                        <button id="stop-btn" class="control-btn" title="Stop">
                            <svg viewBox="0 0 24 24" width="24" height="24">
                                <path fill="currentColor" d="M6 6h12v12H6z"/>
                            </svg>
                        </button>
                        <button id="next-btn" class="control-btn" title="Successivo">
                            <svg viewBox="0 0 24 24" width="24" height="24">
                                <path fill="currentColor" d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"/>
                            </svg>
                        </button>
                        <button id="playback-mode-btn" class="control-btn" title="Modalità di riproduzione">
                            <span id="mode-icon">⏭️</span>
                        </button>
                        <button id="speed-btn" class="control-btn" title="Velocità di riproduzione">
                            <span id="speed-text">1x</span>
                        </button>
                    </div>
                    
                    <!-- Skip Time Display -->
                    <div id="skip-display" class="skip-display">
                        <div class="skip-info">
                            <span id="skip-direction-inline" class="skip-direction-inline"></span>
                            <span id="skip-time-inline" class="skip-time-inline">--:--</span>
                            <span id="skip-speed-inline" class="skip-speed-inline"></span>
                        </div>
                    </div>

                    <!-- Volume Control -->
                    <div class="volume-container">
                        <svg viewBox="0 0 24 24" width="20" height="20">
                            <path fill="currentColor" d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02z"/>
                        </svg>
                        <input type="range" id="volume-slider" min="0" max="100" value="<?php echo ($commonConfig['settings']['defaultVolume'] ?? 0.8) * 100; ?>" class="volume-slider">
                        <span id="volume-value"><?php echo round(($commonConfig['settings']['defaultVolume'] ?? 0.8) * 100); ?>%</span>
                    </div>


                    <!-- Playlist Queue -->
                    <div class="playlist-queue">
                        <h3>Coda di riproduzione</h3>
                        <div id="queue-list" class="queue-list">
                            <p class="empty-queue">Nessun file nella coda</p>
                        </div>
                    </div>
                </main>

                <!-- Mobile Track Tabs -->
                <div class="mobile-track-tabs">
                    <div class="track-tabs-header">
                        <h3>Brani</h3>
                    </div>
                    <div id="track-tabs" class="track-tabs">
                        <p class="no-tracks">Seleziona un album per vedere i brani</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Hidden Audio Element -->
    <audio id="audio-player" preload="metadata"></audio>

    <!-- Embed directory data -->
    <script>
        window.AUDIO_DIRECTORIES = <?php echo $directoriesJson; ?>;
        window.ARGOMENTO_PATH = '<?php echo $argomentoPath; ?>';
        window.THEME = <?php echo json_encode($theme); ?>;
        window.SETTINGS = <?php echo json_encode($commonConfig['settings'] ?? []); ?>;
        window.FEATURES = <?php echo json_encode($commonConfig['features'] ?? []); ?>;
        window.UI = <?php echo json_encode($commonConfig['ui'] ?? []); ?>;
        window.SELECTED_THEME = <?php echo json_encode($selectedThemeName); ?>;
        
        // Debug mode (configurable via settings)
        const debugMode = <?php echo json_encode($commonConfig['settings']['debug'] ?? false); ?>;
        
        if (debugMode) {
            console.log('=== DEBUG MODE ENABLED ===');
            console.log('Directories:', window.AUDIO_DIRECTORIES);
            console.log('Theme:', window.THEME);
            console.log('Settings:', window.SETTINGS);
            console.log('UI:', window.UI);
            console.log('Selected Theme:', window.SELECTED_THEME);
            console.log('========================');
        }
        
        // Visual debug (only in debug mode and non-localhost)
        if (debugMode && window.location.hostname !== 'localhost') {
            const debugDiv = document.createElement('div');
            debugDiv.id = 'android-debug';
            debugDiv.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:350px;background:black;color:white;font-size:12px;overflow:auto;z-index:9999;padding:10px;';
            debugDiv.innerHTML = `
                <strong>🔧 DEBUG MODE ACTIVE</strong><br>
                <small>Debug enabled via settings.debug = true</small><br><br>
                Directories: ${JSON.stringify(window.AUDIO_DIRECTORIES).substring(0, 200)}...<br>
                Theme: ${JSON.stringify(window.THEME).substring(0, 100)}...<br>
                Settings: ${JSON.stringify(window.SETTINGS).substring(0, 100)}...<br>
                UI: ${JSON.stringify(window.UI).substring(0, 100)}...<br>
                CSS Loaded: ${document.styleSheets.length > 0 ? 'YES' : 'NO'}<br>
                <button onclick="this.parentElement.remove()">Chiudi Debug</button>
            `;
            document.body.appendChild(debugDiv);
            
            // Check if applyTheme is called
            setTimeout(() => {
                const root = document.documentElement;
                const primaryColor = getComputedStyle(root).getPropertyValue('--primary-color');
                debugDiv.innerHTML += `<br>CSS Variables Applied: ${primaryColor ? 'YES' : 'NO'}<br>Primary Color: ${primaryColor}`;
                
                // Fallback: Apply theme manually if not applied
                if (!primaryColor && window.THEME) {
                    debugDiv.innerHTML += `<br><strong>APPLYING FALLBACK THEME...</strong>`;
                    root.style.setProperty('--primary-color', window.THEME.primaryColor);
                    root.style.setProperty('--secondary-color', window.THEME.secondaryColor);
                    root.style.setProperty('--accent-color', window.THEME.accentColor);
                    root.style.setProperty('--background-color', window.THEME.backgroundColor);
                    root.style.setProperty('--surface-color', window.THEME.surfaceColor);
                    root.style.setProperty('--gradient-start', window.THEME.gradientStart);
                    root.style.setProperty('--gradient-end', window.THEME.gradientEnd);
                    root.style.setProperty('--font-family', window.THEME.fontFamily);
                    root.style.setProperty('--text-color', window.THEME.textColor);
                    root.style.setProperty('--text-secondary', window.THEME.textSecondary);
                    
                    // Force body background as fallback (solid color + gradient)
                    document.body.style.backgroundColor = window.THEME.backgroundColor;
                    document.body.style.background = `linear-gradient(135deg, ${window.THEME.gradientStart} 0%, ${window.THEME.gradientEnd} 100%)`;
                    
                    // Immediate Android fix: force solid color if gradient fails
                    debugDiv.innerHTML += `<br><strong>FORCING SOLID BACKGROUND FOR ANDROID</strong>`;
                    document.body.style.background = window.THEME.backgroundColor;
                    document.body.style.backgroundColor = window.THEME.backgroundColor;
                    
                    // Additional Android fallback: if gradient doesn't work, use solid color
                    setTimeout(() => {
                        const currentBg = getComputedStyle(document.body).backgroundColor;
                        debugDiv.innerHTML += `<br>200ms check - Body BG: ${currentBg}`;
                        if (currentBg === 'rgba(0, 0, 0, 0)' || currentBg === 'transparent') {
                            debugDiv.innerHTML += `<br><strong>IMMEDIATE ANDROID FALLBACK APPLIED</strong>`;
                            document.body.style.background = window.THEME.backgroundColor;
                            document.body.style.backgroundColor = window.THEME.backgroundColor;
                            
                            // Check result
                            setTimeout(() => {
                                const newBg = getComputedStyle(document.body).backgroundColor;
                                debugDiv.innerHTML += `<br>After fallback - Body BG: ${newBg}`;
                            }, 100);
                        }
                    }, 200);
                    
                    // Check again
                    setTimeout(() => {
                        const newPrimaryColor = getComputedStyle(root).getPropertyValue('--primary-color');
                        debugDiv.innerHTML += `<br>Fallback Applied: ${newPrimaryColor ? 'YES' : 'NO'}<br>New Primary Color: ${newPrimaryColor}`;
                        
                        // Check if theme is actually visible
                        const bodyBg = getComputedStyle(document.body).backgroundColor;
                        const bodyBgImage = getComputedStyle(document.body).backgroundImage;
                        const headerColor = getComputedStyle(document.querySelector('.player-header h1')).color;
                        debugDiv.innerHTML += `<br>Body BG Color: ${bodyBg}<br>Body BG Image: ${bodyBgImage}<br>Header Color: ${headerColor}`;
                        
                        // Check CSS variables on root
                        const rootBg = getComputedStyle(root).getPropertyValue('--background-color');
                        const rootGradientStart = getComputedStyle(root).getPropertyValue('--gradient-start');
                        const rootGradientEnd = getComputedStyle(root).getPropertyValue('--gradient-end');
                        debugDiv.innerHTML += `<br>Root --background-color: ${rootBg}<br>Root --gradient-start: ${rootGradientStart}<br>Root --gradient-end: ${rootGradientEnd}`;
                        
                        // Check if gradient is working, if not use solid color
                        // Android Chrome often shows gradient in backgroundImage but doesn't render it
                        if (bodyBgColor === 'rgba(0, 0, 0, 0)' || bodyBgColor === 'transparent') {
                            debugDiv.innerHTML += `<br><strong>GRADIENT NOT VISIBLE - USING SOLID COLOR</strong>`;
                            document.body.style.background = window.THEME.backgroundColor;
                            document.body.style.backgroundColor = window.THEME.backgroundColor;
                            
                            // Check again after applying solid color
                            setTimeout(() => {
                                const newBodyBg = getComputedStyle(document.body).backgroundColor;
                                debugDiv.innerHTML += `<br>New Body BG Color: ${newBodyBg}`;
                            }, 50);
                        }
                    }, 100);
                }
            }, 1000);
        }
    </script>
    <script src="script.js"></script>
</body>
</html>

