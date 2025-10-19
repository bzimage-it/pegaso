// Audio Player Application
console.log('=== SCRIPT.JS LOADED ===');

class AudioPlayer {
    constructor() {
        console.log('=== AudioPlayer constructor called ===');
        this.audio = document.getElementById('audio-player');
        this.playlist = [];
        this.currentIndex = -1;
        this.isPlaying = false;
        this.isMobile = this.detectMobile();
        
        // Load configuration from window objects FIRST
        this.settings = window.SETTINGS || {};
        this.features = window.FEATURES || {};
        this.ui = window.UI || {};
        
        // Fix desktop layout issue immediately
        this.fixDesktopLayout();
        
        // Android debug (only if debug mode is enabled)
        if (this.settings.debug) {
            console.log('AudioPlayer initialized');
            console.log('Is Mobile:', this.isMobile);
            console.log('Window width:', window.innerWidth);
            console.log('User Agent:', navigator.userAgent);
            
            // Check volume slider
            const volumeSlider = document.querySelector('.volume-slider');
            if (volumeSlider) {
                console.log('Volume slider found:', volumeSlider);
                console.log('Volume slider computed styles:', {
                    height: getComputedStyle(volumeSlider).height,
                    background: getComputedStyle(volumeSlider).background,
                    backgroundColor: getComputedStyle(volumeSlider).backgroundColor,
                    display: getComputedStyle(volumeSlider).display,
                    visibility: getComputedStyle(volumeSlider).visibility,
                    opacity: getComputedStyle(volumeSlider).opacity
                });
            }
            
            // Check CSS classes
            const mobileSelector = document.querySelector('.mobile-album-selector');
            const fileBrowser = document.querySelector('.file-browser');
            const mainContent = document.querySelector('.main-content');
            console.log('Mobile selector element:', mobileSelector);
            console.log('File browser element:', fileBrowser);
            console.log('Main content element:', mainContent);
            if (mobileSelector) {
                console.log('Mobile selector display:', getComputedStyle(mobileSelector).display);
            }
            if (fileBrowser) {
                console.log('File browser display:', getComputedStyle(fileBrowser).display);
            }
            if (mainContent) {
                console.log('Main content grid columns:', getComputedStyle(mainContent).gridTemplateColumns);
                console.log('Main content grid rows:', getComputedStyle(mainContent).gridTemplateRows);
            }
        }
        
        // Playback modes from configuration
        const availableModes = this.features.playbackModes || ['single', 'sequential', 'repeat'];
        this.playbackModes = [
            { id: 'single', name: 'Una Traccia', icon: '⏹️' },
            { id: 'sequential', name: 'Sequenziale', icon: '⏭️' },
            { id: 'repeat', name: 'Ripeti', icon: '🔄' }
        ].filter(mode => availableModes.includes(mode.id));
        
        // Find default mode index
        const defaultMode = this.settings.defaultPlaybackMode || 'sequential';
        this.currentModeIndex = this.playbackModes.findIndex(mode => mode.id === defaultMode);
        if (this.currentModeIndex === -1) this.currentModeIndex = 1; // Fallback to sequential
        
        // Playback speeds from configuration
        this.playbackSpeeds = this.features.playbackSpeeds || [0.5, 1.0, 1.25, 1.5, 2.0];
        const defaultSpeed = this.settings.defaultPlaybackSpeed || 1.0;
        this.currentSpeedIndex = this.playbackSpeeds.findIndex(speed => speed === defaultSpeed);
        if (this.currentSpeedIndex === -1) this.currentSpeedIndex = 1; // Fallback to 1x
        
        this.applyTheme();
        this.initElements();
        this.initEventListeners();
        this.loadDirectoryStructure();
        this.optimizeForMobile();
        
        // Ensure desktop layout is applied after everything loads
        setTimeout(() => this.fixDesktopLayout(), 100);
    }
    
    detectMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
               window.innerWidth <= 768;
    }
    
    fixDesktopLayout() {
        // Force desktop grid layout to prevent mobile layout on desktop
        const mainContent = document.querySelector('.main-content');
        if (mainContent && !this.isMobile) {
            mainContent.style.display = 'grid';
            mainContent.style.gridTemplateColumns = '350px 1fr';
            mainContent.style.gridTemplateRows = 'none';
            if (this.settings.debug) {
                console.log('Fixed desktop layout - forced grid display');
            }
        }
    }
    
    initializeIcons() {
        // Force initial state: show play icon, hide pause icon
        if (this.playIcon && this.pauseIcon) {
            // Show play icon
            this.playIcon.style.setProperty('display', 'block', 'important');
            this.playIcon.style.setProperty('fill', 'white', 'important');
            
            // Hide pause icon completely
            this.pauseIcon.style.setProperty('display', 'none', 'important');
            
            if (this.settings.debug) {
                console.log('Icons initialized - play visible, pause hidden');
                console.log('Play icon display:', this.playIcon.style.display);
                console.log('Pause icon display:', this.pauseIcon.style.display);
            }
        }
    }
    
    updateVolumeSliderGradient() {
        const volumeSlider = document.querySelector('.volume-slider');
        if (!volumeSlider) return;
        
        // Always read the current value from the DOM to ensure sync
        const value = parseFloat(volumeSlider.value);
        const percentage = value;
        
        // Create dynamic gradient: colored part up to current value, gray for the rest
        const gradient = `linear-gradient(to right, var(--primary-color) 0%, var(--primary-color) ${percentage}%, #e0e0e0 ${percentage}%, #e0e0e0 100%)`;
        
        // Apply to all track selectors
        const style = document.createElement('style');
        style.textContent = `
            .mobile-device .volume-slider::-webkit-slider-track {
                background: ${gradient} !important;
            }
            .mobile-device .volume-slider::-moz-range-track {
                background: ${gradient} !important;
            }
            .mobile-device .volume-slider::-webkit-slider-runnable-track {
                background: ${gradient} !important;
            }
        `;
        
        // Remove old style if exists
        const oldStyle = document.getElementById('volume-gradient-style');
        if (oldStyle) {
            oldStyle.remove();
        }
        
        style.id = 'volume-gradient-style';
        document.head.appendChild(style);
        
        if (this.settings.debug) {
            console.log(`Volume gradient updated: ${percentage}% colored (value: ${value})`);
        }
    }
    
    optimizeForMobile() {
        if (this.isMobile) {
            // Add mobile class to body for CSS targeting
            document.body.classList.add('mobile-device');
            
            // Optimize audio settings for mobile
            this.audio.preload = 'metadata'; // Reduce initial load
            
            // Add mobile-specific event listeners
            this.addMobileOptimizations();
        }
    }
    
    addMobileOptimizations() {
        // Prevent zoom on double tap
        let lastTouchEnd = 0;
        document.addEventListener('touchend', (e) => {
            const now = (new Date()).getTime();
            if (now - lastTouchEnd <= 300) {
                e.preventDefault();
            }
            lastTouchEnd = now;
        }, false);
        
        // Handle orientation change
        window.addEventListener('orientationchange', () => {
            setTimeout(() => {
                this.updateProgress();
            }, 100);
        });
        
        // Prevent pull-to-refresh on mobile
        document.addEventListener('touchmove', (e) => {
            if (e.touches.length > 1) {
                e.preventDefault();
            }
        }, { passive: false });
    }
    
    initMobileElements() {
        // Album dropdown
        this.albumDropdown.addEventListener('change', (e) => {
            const selectedAlbum = e.target.value;
            if (selectedAlbum) {
                this.loadAlbumForMobile(selectedAlbum);
            }
        });
        
        // Initialize mobile UI
        this.populateAlbumDropdown();
    }
    
    populateAlbumDropdown() {
        const directories = window.AUDIO_DIRECTORIES || [];
        
        // Debug: Check dropdown population
        if (this.settings.debug) {
            console.log('populateAlbumDropdown called');
            console.log('directories for dropdown:', directories);
            console.log('albumDropdown element:', this.albumDropdown);
        }
        
        // Clear existing options except the first one
        this.albumDropdown.innerHTML = '<option value="">Seleziona un album...</option>';
        
        directories.forEach(dir => {
            const option = document.createElement('option');
            option.value = dir.name;
            option.textContent = dir.name;
            this.albumDropdown.appendChild(option);
        });
        
        if (this.settings.debug) {
            console.log('Dropdown populated with', directories.length, 'albums');
        }
    }
    
    loadAlbumForMobile(albumName) {
        const directories = window.AUDIO_DIRECTORIES || [];
        const album = directories.find(dir => dir.name === albumName);
        
        if (!album) return;
        
        // Load the album (same as desktop)
        this.loadFolder(albumName, album.files, album.key);
        
        // Update mobile track tabs
        this.updateMobileTrackTabs(album.files);
    }
    
    updateMobileTrackTabs(files) {
        this.trackTabs.innerHTML = '';
        
        if (!files || files.length === 0) {
            this.trackTabs.innerHTML = '<p class="no-tracks">Nessuna traccia disponibile</p>';
            return;
        }
        
        files.forEach((file, index) => {
            const fileName = typeof file === 'string' ? file : file.name;
            
            const tab = document.createElement('div');
            tab.className = 'track-tab';
            tab.textContent = fileName;
            tab.dataset.index = index;
            
            // Add click handler
            tab.addEventListener('click', () => {
                this.playTrack(index);
                this.updateMobileTrackSelection();
            });
            
            this.trackTabs.appendChild(tab);
        });
        
        this.updateMobileTrackSelection();
    }
    
    updateMobileTrackSelection() {
        if (!this.isMobile) return;
        
        // Remove all active classes
        document.querySelectorAll('.track-tab').forEach(tab => {
            tab.classList.remove('active', 'playing');
        });
        
        // Add active class to current track
        if (this.currentIndex >= 0) {
            const currentTab = document.querySelector(`.track-tab[data-index="${this.currentIndex}"]`);
            if (currentTab) {
                currentTab.classList.add('playing');
            }
        }
    }
    
    applyTheme() {
        // Debug (only if debug mode is enabled)
        if (this.settings.debug) {
            console.log('applyTheme() called');
            console.log('window.THEME:', window.THEME);
        }
        
        // Get theme from window object (set by PHP)
        const theme = window.THEME || {
            primaryColor: '#667eea',
            secondaryColor: '#c3cfe2',
            accentColor: '#764ba2',
            backgroundColor: '#ffffff',
            surfaceColor: '#f8f9fa',
            gradientStart: '#667eea',
            gradientEnd: '#764ba2',
            fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
            fontWeight: 'normal',
            textColor: '#333333',
            textSecondary: '#666666',
            buttonStyle: 'rounded'
        };
        
        if (this.settings.debug) {
            console.log('Using theme:', theme);
        }
        
        // Create CSS variables
        const root = document.documentElement;
        root.style.setProperty('--primary-color', theme.primaryColor);
        root.style.setProperty('--secondary-color', theme.secondaryColor);
        root.style.setProperty('--accent-color', theme.accentColor);
        root.style.setProperty('--background-color', theme.backgroundColor);
        root.style.setProperty('--surface-color', theme.surfaceColor);
        root.style.setProperty('--gradient-start', theme.gradientStart);
        root.style.setProperty('--gradient-end', theme.gradientEnd);
        root.style.setProperty('--font-family', theme.fontFamily);
        root.style.setProperty('--font-weight', theme.fontWeight);
        root.style.setProperty('--text-color', theme.textColor);
        root.style.setProperty('--text-secondary', theme.textSecondary);
        
        // Apply font family to body
        document.body.style.fontFamily = theme.fontFamily;
        document.body.style.fontWeight = theme.fontWeight;
        
        // Apply button style
        this.applyButtonStyle(theme.buttonStyle);
        
        // Debug: Check if CSS variables are actually applied
        if (this.settings.debug) {
            setTimeout(() => {
                const root = document.documentElement;
                const primaryColor = getComputedStyle(root).getPropertyValue('--primary-color');
                const backgroundColor = getComputedStyle(root).getPropertyValue('--background-color');
                console.log('CSS Variables Check:');
                console.log('--primary-color:', primaryColor);
                console.log('--background-color:', backgroundColor);
                
                // Check if elements are actually styled
                const body = document.body;
                const header = document.querySelector('.player-header h1');
                if (body) console.log('Body computed background:', getComputedStyle(body).backgroundColor);
                if (header) console.log('Header computed color:', getComputedStyle(header).color);
            }, 100);
            
            console.log('Theme applied successfully');
        }
    }
    
    applyButtonStyle(buttonStyle) {
        // Remove existing button style classes
        document.body.classList.remove('button-rounded', 'button-square', 'button-pill');
        
        // Add the new button style class
        document.body.classList.add(`button-${buttonStyle}`);
        
        // Apply the style to all control buttons
        const controlButtons = document.querySelectorAll('.control-btn, .play-btn, .mode-btn, .track-tab, .queue-item, .file-item, .folder-header');
        controlButtons.forEach(button => {
            // Remove existing button style classes
            button.classList.remove('button-rounded', 'button-square', 'button-pill');
            
            // Add the new button style class
            button.classList.add(`button-${buttonStyle}`);
        });
    }
    
    initElements() {
        // Controls
        this.playPauseBtn = document.getElementById('play-pause-btn');
        this.stopBtn = document.getElementById('stop-btn');
        this.prevBtn = document.getElementById('prev-btn');
        this.nextBtn = document.getElementById('next-btn');
        this.skipBackBtn = document.getElementById('skip-back-btn');
        this.skipForwardBtn = document.getElementById('skip-forward-btn');
        
        // Skip display elements (inline)
        this.skipDisplay = document.getElementById('skip-display');
        this.skipDirectionInline = document.getElementById('skip-direction-inline');
        this.skipTimeInline = document.getElementById('skip-time-inline');
        this.skipSpeedInline = document.getElementById('skip-speed-inline');
        
        // Icons
        this.playIcon = document.getElementById('play-icon');
        this.pauseIcon = document.getElementById('pause-icon');
        
        if (this.settings.debug) {
            console.log('Icons initialized:');
            console.log('playIcon:', this.playIcon);
            console.log('pauseIcon:', this.pauseIcon);
            console.log('playIcon classes:', this.playIcon ? this.playIcon.className : 'null');
            console.log('pauseIcon classes:', this.pauseIcon ? this.pauseIcon.className : 'null');
        }
        
        // Initialize icon visibility
        this.initializeIcons();
        
        // Initialize volume slider gradient
        this.updateVolumeSliderGradient();
        
        // Ensure icons are properly styled after CSS loads
        setTimeout(() => this.initializeIcons(), 100);
        
        // Ensure volume gradient is synced after everything loads
        setTimeout(() => this.updateVolumeSliderGradient(), 200);
        
        // Track info
        this.trackTitle = document.getElementById('track-title');
        this.trackFolder = document.getElementById('track-folder');
        
        // Progress
        this.progressBar = document.getElementById('progress-bar');
        this.progressFill = document.getElementById('progress-fill');
        this.progressHandle = document.getElementById('progress-handle');
        this.currentTimeEl = document.getElementById('current-time');
        this.durationEl = document.getElementById('duration');
        
        // Volume
        this.volumeSlider = document.getElementById('volume-slider');
        this.volumeValue = document.getElementById('volume-value');
        
        // Lists
        this.directoryList = document.getElementById('directory-list');
        this.queueList = document.getElementById('queue-list');
        
        // Mobile elements
        this.albumDropdown = document.getElementById('album-dropdown');
        this.trackTabs = document.getElementById('track-tabs');
        
        // Playback mode elements
        this.playbackModeBtn = document.getElementById('playback-mode-btn');
        this.modeIcon = document.getElementById('mode-icon');
        this.speedBtn = document.getElementById('speed-btn');
        this.speedText = document.getElementById('speed-text');
    }

    initEventListeners() {
        // Control buttons with touch support
        this.initControlButtons();
        
        // Skip buttons with hold functionality
        this.initSkipButtons();
        
        // Audio events
        this.audio.addEventListener('timeupdate', () => this.updateProgress());
        this.audio.addEventListener('loadedmetadata', () => this.updateDuration());
        this.audio.addEventListener('durationchange', () => this.updateDuration());
        this.audio.addEventListener('canplay', () => this.updateDuration());
        this.audio.addEventListener('ended', () => this.onTrackEnded());
        
        // Progress bar - handle both click and drag (mouse and touch)
        this.initProgressBar();
        
        // Volume
        this.volumeSlider.addEventListener('input', (e) => {
            this.setVolume(e.target.value);
            this.updateVolumeSliderGradient();
        });
        
        // Playback mode
        this.playbackModeBtn.addEventListener('click', () => this.togglePlaybackMode());
        
        // Speed control
        this.speedBtn.addEventListener('click', () => this.togglePlaybackSpeed());
        
        // Mobile elements
        if (this.isMobile) {
            this.initMobileElements();
        }
        
        // Set initial volume from settings
        const defaultVolume = this.settings.defaultVolume || 0.8;
        this.volumeSlider.value = defaultVolume * 100;
        this.setVolume(defaultVolume * 100);
        
        // Initialize playback mode and speed display
        this.updatePlaybackModeDisplay();
        this.updatePlaybackSpeedDisplay();
    }
    
    initControlButtons() {
        // Add touch support to control buttons
        const controlButtons = [
            { element: this.playPauseBtn, action: () => this.togglePlayPause() },
            { element: this.stopBtn, action: () => this.stop() },
            { element: this.prevBtn, action: () => this.playPrevious() },
            { element: this.nextBtn, action: () => this.playNext() }
        ];
        
        controlButtons.forEach(({ element, action }) => {
            // Click event
            element.addEventListener('click', action);
            
            // Touch event for better mobile response
            element.addEventListener('touchend', (e) => {
                e.preventDefault();
                action();
            }, { passive: false });
            
            // Prevent context menu on long press
            element.addEventListener('contextmenu', (e) => {
                e.preventDefault();
            });
        });
    }
    
    initProgressBar() {
        let isDragging = false;
        
        // Mouse events
        this.progressBar.addEventListener('click', (e) => this.seek(e));
        this.progressBar.addEventListener('mousedown', (e) => {
            isDragging = true;
            this.seek(e);
        });
        
        document.addEventListener('mousemove', (e) => {
            if (isDragging) {
                this.seek(e);
            }
        });
        
        document.addEventListener('mouseup', () => {
            isDragging = false;
        });
        
        // Touch events for mobile
        this.progressBar.addEventListener('touchstart', (e) => {
            e.preventDefault();
            isDragging = true;
            const touch = e.touches[0];
            this.seek(touch);
        }, { passive: false });
        
        document.addEventListener('touchmove', (e) => {
            if (isDragging) {
                e.preventDefault();
                const touch = e.touches[0];
                this.seek(touch);
            }
        }, { passive: false });
        
        document.addEventListener('touchend', () => {
            isDragging = false;
        });
        
        // Prevent context menu on long press
        this.progressBar.addEventListener('contextmenu', (e) => {
            e.preventDefault();
        });
    }
    
    initSkipButtons() {
        // State for dynamic skip system
        this.skipState = {
            isSkipping: false,
            direction: 0, // -1 = back, 1 = forward
            currentSpeed: 10, // Start at 10 seconds
            speedMultiplier: 1,
            startTime: 0,
            interval: null
        };
        
        const INITIAL_SPEED = 10; // seconds
        const ACCELERATION_INTERVAL = 1000; // ms - increase speed by 1x every 1000ms
        const SKIP_RATE = 100; // ms - update position every 100ms
        
        const startSkip = (direction) => {
            if (!this.audio.duration) return;
            
            // If already skipping, don't restart
            if (this.skipState.isSkipping) {
                console.log('Already skipping, ignoring...');
                return;
            }
            
            console.log('Starting skip:', direction < 0 ? 'backward' : 'forward');
            
            this.skipState.isSkipping = true;
            this.skipState.direction = direction;
            this.skipState.currentSpeed = INITIAL_SPEED;
            this.skipState.speedMultiplier = 1;
            this.skipState.startTime = Date.now();
            
            // Show inline display
            this.skipDisplay.classList.add('active');
            this.skipDirectionInline.textContent = direction < 0 ? '⏪' : '⏩';
            this.updateSkipDisplay();
            
            // Immediate first skip
            this.performSkip();
            
            // Set up continuous skipping
            this.skipState.interval = setInterval(() => {
                // Check if we should accelerate (linear: +1 every ACCELERATION_INTERVAL)
                const elapsedTime = Date.now() - this.skipState.startTime;
                const newMultiplier = 1 + Math.floor(elapsedTime / ACCELERATION_INTERVAL);
                
                if (newMultiplier !== this.skipState.speedMultiplier) {
                    this.skipState.speedMultiplier = newMultiplier;
                    this.skipState.currentSpeed = INITIAL_SPEED * newMultiplier;
                    console.log('Speed increased to:', this.skipState.currentSpeed, 's (×' + newMultiplier + ')');
                }
                
                this.performSkip();
            }, SKIP_RATE);
        };
        
        const stopSkip = () => {
            if (!this.skipState.isSkipping) return;
            
            console.log('Stopping skip');
            
            this.skipState.isSkipping = false;
            clearInterval(this.skipState.interval);
            this.skipState.interval = null;
            
            // Remove active class (to hide direction arrow and speed)
            this.skipDisplay.classList.remove('active');
        };
        
        // Global mouse/touch tracking
        let isMouseDown = false;
        
        // Skip Back Button
        this.skipBackBtn.addEventListener('mousedown', (e) => {
            e.preventDefault();
            e.stopPropagation();
            console.log('MOUSEDOWN on skip back');
            isMouseDown = true;
            startSkip(-1);
            return false;
        }, true);
        
        this.skipBackBtn.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            return false;
        }, true);
        
        // Skip Forward Button
        this.skipForwardBtn.addEventListener('mousedown', (e) => {
            e.preventDefault();
            e.stopPropagation();
            console.log('MOUSEDOWN on skip forward');
            isMouseDown = true;
            startSkip(1);
            return false;
        }, true);
        
        this.skipForwardBtn.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            return false;
        }, true);
        
        // Global mouseup and mouseleave handlers
        document.addEventListener('mouseup', (e) => {
            if (isMouseDown) {
                console.log('MOUSEUP detected');
                isMouseDown = false;
                stopSkip();
            }
        });
        
        document.addEventListener('mouseleave', (e) => {
            if (isMouseDown) {
                console.log('MOUSE LEFT document');
                isMouseDown = false;
                stopSkip();
            }
        });
        
        // Touch support
        this.skipBackBtn.addEventListener('touchstart', (e) => {
            e.preventDefault();
            e.stopPropagation();
            startSkip(-1);
            return false;
        }, true);
        
        this.skipBackBtn.addEventListener('touchend', (e) => {
            e.preventDefault();
            e.stopPropagation();
            stopSkip();
            return false;
        }, true);
        
        this.skipForwardBtn.addEventListener('touchstart', (e) => {
            e.preventDefault();
            e.stopPropagation();
            startSkip(1);
            return false;
        }, true);
        
        this.skipForwardBtn.addEventListener('touchend', (e) => {
            e.preventDefault();
            e.stopPropagation();
            stopSkip();
            return false;
        }, true);
    }
    
    performSkip() {
        if (!this.audio.duration) return;
        
        const skipAmount = this.skipState.currentSpeed * this.skipState.direction * (100 / 1000); // Adjust for interval rate
        const newTime = this.audio.currentTime + skipAmount;
        
        // Clamp to valid range
        this.audio.currentTime = Math.max(0, Math.min(this.audio.duration, newTime));
        
        this.updateProgress();
        this.updateSkipDisplay();
    }
    
    updateCurrentTimeDisplay() {
        const currentTime = this.audio.currentTime;
        const mins = Math.floor(currentTime / 60);
        const secs = Math.floor(currentTime % 60);
        
        this.skipTimeInline.textContent = `${mins}:${secs.toString().padStart(2, '0')}`;
    }
    
    updateSkipDisplay() {
        // Update time
        this.updateCurrentTimeDisplay();
        
        // Update speed info
        this.skipSpeedInline.textContent = `×${this.skipState.speedMultiplier} (${this.skipState.currentSpeed}s)`;
    }

    loadDirectoryStructure() {
        try {
            // Data is embedded directly in the page by PHP
            const directories = window.AUDIO_DIRECTORIES || [];
            
            // Debug: Check directories data
            if (this.settings.debug) {
                console.log('loadDirectoryStructure called');
                console.log('window.AUDIO_DIRECTORIES:', window.AUDIO_DIRECTORIES);
                console.log('directories array:', directories);
                console.log('directories length:', directories.length);
            }
            
            if (!directories || directories.length === 0) {
                console.log('No directories found - showing empty message');
                this.directoryList.innerHTML = '<div class="loading">Nessun album con tracce audio trovato</div>';
                if (this.isMobile) {
                    this.trackTabs.innerHTML = '<p class="no-tracks">Nessun album con tracce audio trovato</p>';
                }
                return;
            }
            
            this.renderDirectories(directories);
            
            // Debug: Check if directories were rendered
            if (this.settings.debug) {
                console.log('After renderDirectories - directoryList children:', this.directoryList.children.length);
                console.log('directoryList innerHTML length:', this.directoryList.innerHTML.length);
                
                // Check if elements are visible
                const firstChild = this.directoryList.firstElementChild;
                if (firstChild) {
                    console.log('First child element:', firstChild);
                    console.log('First child display:', getComputedStyle(firstChild).display);
                    console.log('First child visibility:', getComputedStyle(firstChild).visibility);
                    console.log('First child opacity:', getComputedStyle(firstChild).opacity);
                    
                    // Check dimensions and position
                    const rect = firstChild.getBoundingClientRect();
                    console.log('First child dimensions:', rect.width, 'x', rect.height);
                    console.log('First child position:', rect.left, rect.top);
                    console.log('First child in viewport:', rect.top >= 0 && rect.left >= 0 && rect.bottom <= window.innerHeight && rect.right <= window.innerWidth);
                }
                
                // Check parent container
                console.log('File browser display:', getComputedStyle(this.directoryList.parentElement).display);
                console.log('File browser visibility:', getComputedStyle(this.directoryList.parentElement).visibility);
                
            }
            
            // Initialize mobile elements if on mobile
            if (this.isMobile) {
                this.populateAlbumDropdown();
            }
        } catch (error) {
            console.error('Error loading directories:', error);
            this.directoryList.innerHTML = '<div class="loading">Errore nel caricamento delle cartelle</div>';
            if (this.isMobile) {
                this.trackTabs.innerHTML = '<p class="no-tracks">Errore nel caricamento delle cartelle</p>';
            }
        }
    }

    renderDirectories(directories) {
        if (this.settings.debug) {
            console.log('renderDirectories called with:', directories.length, 'directories');
            console.log('directoryList element:', this.directoryList);
        }
        
        if (!directories || directories.length === 0) {
            this.directoryList.innerHTML = '<div class="loading">Nessuna cartella trovata</div>';
            return;
        }

        this.directoryList.innerHTML = '';
        
        // Sort directories alphabetically
        directories.sort((a, b) => a.name.localeCompare(b.name));
        
        directories.forEach(dir => {
            const folderItem = document.createElement('div');
            folderItem.className = 'folder-item';
            
            const folderHeader = document.createElement('div');
            folderHeader.className = 'folder-header';
            folderHeader.innerHTML = `
                <span class="folder-icon">📁</span>
                <span>${dir.name}</span>
            `;
            
            folderHeader.addEventListener('click', () => {
                const wasExpanded = folderItem.classList.contains('expanded');
                folderItem.classList.toggle('expanded');
                
                // Se la cartella viene espansa, carica la playlist senza far partire la riproduzione
                if (!wasExpanded) {
                    this.loadFolder(dir.name, dir.files, dir.key);
                }
            });
            
            const folderFiles = document.createElement('div');
            folderFiles.className = 'folder-files';
            
            // Sort files alphabetically by name
            const sortedFiles = dir.files.sort((a, b) => {
                if (typeof a === 'object' && typeof b === 'object') {
                    return a.name.localeCompare(b.name);
                }
                return a.localeCompare(b);
            });
            
            sortedFiles.forEach((file, sortedIndex) => {
                const fileName = typeof file === 'string' ? file : file.name;
                const fileData = typeof file === 'string' ? file : file.file;
                
                const fileItem = document.createElement('div');
                fileItem.className = 'file-item';
                fileItem.dataset.folder = dir.name;
                fileItem.dataset.file = fileData;
                fileItem.innerHTML = `
                    <span class="file-icon">🎵</span>
                    <span>${fileName}</span>
                `;
                
                fileItem.addEventListener('click', () => {
                    this.loadFolder(dir.name, dir.files, dir.key);
                    // Find the original index in dir.files
                    const originalIndex = dir.files.findIndex(f => {
                        if (typeof f === 'string') {
                            return f === fileData;
                        } else {
                            return f.file === fileData;
                        }
                    });
                    this.playTrack(originalIndex);
                    
                    // Update active state
                    document.querySelectorAll('.file-item').forEach(item => {
                        item.classList.remove('active');
                    });
                    fileItem.classList.add('active');
                });
                
                folderFiles.appendChild(fileItem);
            });
            
            folderItem.appendChild(folderHeader);
            folderItem.appendChild(folderFiles);
            this.directoryList.appendChild(folderItem);
        });
    }

    loadFolder(folderName, files, folderKey = null) {
        // Se cambia cartella, reset completo
        const folderChanged = this.currentFolder !== folderName;
        
        this.currentFolder = folderName;
        const basePath = window.ARGOMENTO_PATH ? `media/${window.ARGOMENTO_PATH}` : 'media';
        
        // Use folderKey if provided, otherwise use folderName
        const actualFolderName = folderKey || folderName;
        
        // Handle both old format (strings) and new format (objects)
        this.playlist = files.map(file => {
            if (typeof file === 'string') {
                // Old format: just filename
                return {
                    name: file,
                    folder: folderName,
                    url: `${basePath}/${encodeURIComponent(actualFolderName)}/${encodeURIComponent(file)}`
                };
            } else {
                // New format: object with name, file
                return {
                    name: file.name,
                    file: file.file,
                    folder: folderName,
                    url: `${basePath}/${encodeURIComponent(actualFolderName)}/${encodeURIComponent(file.file)}`
                };
            }
        });
        
        // Sort alphabetically by name
        this.playlist.sort((a, b) => a.name.localeCompare(b.name));
        
        // Reset currentIndex quando si carica una nuova cartella
        if (folderChanged) {
            this.currentIndex = -1;
            // Ferma l'audio se sta suonando
            if (this.isPlaying) {
                this.audio.pause();
                this.isPlaying = false;
                this.updatePlayPauseIcon();
            }
        }
        
        this.updateQueue();
        this.updateTrackInfo();
        this.updateFileSelection();
        this.updateNavigationButtons();
    }

    playTrack(index) {
        if (index < 0 || index >= this.playlist.length) {
            return;
        }
        
        this.currentIndex = index;
        const track = this.playlist[index];
        
        this.audio.src = track.url;
        this.audio.load();
        this.applyPlaybackSpeed(); // Apply current speed
        this.audio.play();
        
        this.isPlaying = true;
        this.updatePlayPauseIcon();
        this.updateTrackInfo();
        this.updateQueue();
        this.updateFileSelection();
        this.updateNavigationButtons();
        
        // Update mobile track selection
        if (this.isMobile) {
            this.updateMobileTrackSelection();
        }
    }
    
    updateFileSelection() {
        // Aggiorna la selezione nell'albero dei file
        if (this.currentIndex < 0 || this.currentIndex >= this.playlist.length) {
            return;
        }
        
        const currentTrack = this.playlist[this.currentIndex];
        
        // Rimuovi tutte le classi active
        document.querySelectorAll('.file-item').forEach(item => {
            item.classList.remove('active');
        });
        
        // Trova e attiva il file corrente usando gli attributi data
        document.querySelectorAll('.file-item').forEach(item => {
            const itemFolder = item.dataset.folder;
            const itemFile = item.dataset.file;
            
            if (itemFolder === currentTrack.folder && itemFile === currentTrack.name) {
                item.classList.add('active');
                
                // Assicurati che la cartella sia espansa
                const folderItem = item.closest('.folder-item');
                if (folderItem && !folderItem.classList.contains('expanded')) {
                    folderItem.classList.add('expanded');
                }
            }
        });
    }

    togglePlayPause() {
        if (this.settings.debug) {
            console.log('togglePlayPause called');
            console.log('playlist.length:', this.playlist.length);
            console.log('currentIndex:', this.currentIndex);
            console.log('isPlaying:', this.isPlaying);
        }
        
        if (this.playlist.length === 0) {
            alert('Seleziona una traccia audio da riprodurre');
            return;
        }
        
        if (this.currentIndex === -1) {
            this.playTrack(0);
            return;
        }
        
        if (this.isPlaying) {
            this.audio.pause();
            this.isPlaying = false;
        } else {
            this.audio.play();
            this.isPlaying = true;
        }
        
        this.updatePlayPauseIcon();
    }

    stop() {
        this.audio.pause();
        this.audio.currentTime = 0;
        this.isPlaying = false;
        this.updatePlayPauseIcon();
        this.updateProgress();
    }

    playPrevious() {
        if (this.currentIndex > 0 && !this.prevBtn.disabled) {
            this.playTrack(this.currentIndex - 1);
        }
    }

    playNext() {
        if (this.currentIndex < this.playlist.length - 1 && !this.nextBtn.disabled) {
            this.playTrack(this.currentIndex + 1);
        }
    }

    onTrackEnded() {
        const currentMode = this.playbackModes[this.currentModeIndex];
        
        switch (currentMode.id) {
            case 'single':
                // Una traccia: si ferma
                this.isPlaying = false;
                this.updatePlayPauseIcon();
                break;
                
            case 'sequential':
                // Sequenziale: passa alla prossima traccia
                if (this.currentIndex < this.playlist.length - 1) {
                    this.playNext();
                } else {
                    this.isPlaying = false;
                    this.updatePlayPauseIcon();
                }
                break;
                
            case 'repeat':
                // Ripeti: ricomincia la stessa traccia
                this.audio.currentTime = 0;
                this.audio.play();
                break;
        }
    }
    
    togglePlaybackMode() {
        // Cicla tra le modalità
        this.currentModeIndex = (this.currentModeIndex + 1) % this.playbackModes.length;
        this.updatePlaybackModeDisplay();
    }
    
    updatePlaybackModeDisplay() {
        const currentMode = this.playbackModes[this.currentModeIndex];
        this.modeIcon.textContent = currentMode.icon;
        
        // Update tooltip
        this.playbackModeBtn.title = `Modalità: ${currentMode.name}`;
    }
    
    togglePlaybackSpeed() {
        // Cicla tra le velocità
        this.currentSpeedIndex = (this.currentSpeedIndex + 1) % this.playbackSpeeds.length;
        this.updatePlaybackSpeedDisplay();
        this.applyPlaybackSpeed();
    }
    
    updatePlaybackSpeedDisplay() {
        const currentSpeed = this.playbackSpeeds[this.currentSpeedIndex];
        this.speedText.textContent = `${currentSpeed}x`;
        
        // Update tooltip
        this.speedBtn.title = `Velocità: ${currentSpeed}x`;
    }
    
    applyPlaybackSpeed() {
        const currentSpeed = this.playbackSpeeds[this.currentSpeedIndex];
        this.audio.playbackRate = currentSpeed;
    }

    updatePlayPauseIcon() {
        if (this.settings.debug) {
            console.log('updatePlayPauseIcon called - isPlaying:', this.isPlaying);
            console.log('playIcon element:', this.playIcon);
            console.log('pauseIcon element:', this.pauseIcon);
        }
        
        if (this.isPlaying) {
            // Hide play icon, show pause icon
            this.playIcon.style.setProperty('display', 'none', 'important');
            this.pauseIcon.style.setProperty('display', 'block', 'important');
            this.pauseIcon.style.setProperty('fill', 'white', 'important');
            
            if (this.settings.debug) {
                console.log('Showing pause icon, hiding play icon');
            }
        } else {
            // Show play icon, hide pause icon
            this.playIcon.style.setProperty('display', 'block', 'important');
            this.playIcon.style.setProperty('fill', 'white', 'important');
            this.pauseIcon.style.setProperty('display', 'none', 'important');
            
            if (this.settings.debug) {
                console.log('Showing play icon, hiding pause icon');
            }
        }
        
        if (this.settings.debug) {
            console.log('After update - playIcon display:', this.playIcon.style.display);
            console.log('After update - pauseIcon display:', this.pauseIcon.style.display);
            console.log('After update - playIcon fill:', this.playIcon.style.fill);
            console.log('After update - pauseIcon fill:', this.pauseIcon.style.fill);
        }
    }
    
    updateNavigationButtons() {
        // Disable/enable prev button
        if (this.currentIndex <= 0) {
            this.prevBtn.disabled = true;
            this.prevBtn.style.opacity = '0.3';
            this.prevBtn.style.cursor = 'not-allowed';
        } else {
            this.prevBtn.disabled = false;
            this.prevBtn.style.opacity = '1';
            this.prevBtn.style.cursor = 'pointer';
        }
        
        // Disable/enable next button
        if (this.currentIndex >= this.playlist.length - 1) {
            this.nextBtn.disabled = true;
            this.nextBtn.style.opacity = '0.3';
            this.nextBtn.style.cursor = 'not-allowed';
        } else {
            this.nextBtn.disabled = false;
            this.nextBtn.style.opacity = '1';
            this.nextBtn.style.cursor = 'pointer';
        }
    }

    updateTrackInfo() {
        if (this.currentIndex >= 0 && this.currentIndex < this.playlist.length) {
            const track = this.playlist[this.currentIndex];
            this.trackTitle.textContent = track.name;
            this.trackFolder.textContent = `Album: ${track.folder}`;
        } else if (this.currentFolder && this.playlist.length > 0) {
            // Album caricato ma nessuna traccia in riproduzione
            this.trackTitle.textContent = `${this.currentFolder} (${this.playlist.length} traccia${this.playlist.length !== 1 ? 'e' : ''})`;
            this.trackFolder.textContent = 'Premi play per iniziare';
        } else {
            this.trackTitle.textContent = 'Nessuna traccia selezionata';
            this.trackFolder.textContent = '-';
        }
    }

    updateProgress() {
        if (this.audio.duration) {
            const progress = (this.audio.currentTime / this.audio.duration) * 100;
            this.progressFill.style.width = `${progress}%`;
            this.progressHandle.style.left = `${progress}%`;
            this.currentTimeEl.textContent = this.formatTime(this.audio.currentTime);
            
            // Update skip display time (always visible now)
            this.updateCurrentTimeDisplay();
            
            // Update seekable range visualization
            this.updateSeekableRange();
        }
    }
    
    updateSeekableRange() {
        // Show how much of the file is actually seekable
        if (this.audio.seekable.length > 0 && this.audio.duration) {
            const seekableEnd = this.audio.seekable.end(this.audio.seekable.length - 1);
            const seekablePercent = (seekableEnd / this.audio.duration) * 100;
            
            // Update duration display to show seekable range if different
            if (seekableEnd < this.audio.duration * 0.95) {
                this.durationEl.textContent = `${this.formatTime(seekableEnd)} / ${this.formatTime(this.audio.duration)}`;
                this.durationEl.title = `Solo ${this.formatTime(seekableEnd)} è attualmente accessibile`;
            }
        }
    }

    updateDuration() {
        if (this.audio.duration && isFinite(this.audio.duration)) {
            this.durationEl.textContent = this.formatTime(this.audio.duration);
            this.updateSeekableRange();
        } else {
            this.durationEl.textContent = '--:--';
        }
    }

    seek(e) {
        // Check if duration is valid and finite
        if (!this.audio.duration || !isFinite(this.audio.duration)) {
            console.warn('Cannot seek: duration is not available or infinite');
            return;
        }
        
        // Get the bounding rectangle of the progress bar
        const rect = this.progressBar.getBoundingClientRect();
        
        // Calculate the click position relative to the progress bar
        const clickX = e.clientX - rect.left;
        
        // Make sure we're within bounds
        if (clickX < 0 || clickX > rect.width) {
            return;
        }
        
        const percent = clickX / rect.width;
        let newTime = percent * this.audio.duration;
        
        // Check if the requested time is within seekable range
        if (this.audio.seekable.length > 0) {
            const seekableEnd = this.audio.seekable.end(this.audio.seekable.length - 1);
            
            // If trying to seek beyond what's actually seekable, limit it
            if (newTime > seekableEnd) {
                newTime = Math.max(0, seekableEnd - 0.5); // Go to 0.5 seconds before the end of seekable range
            }
        }
        
        // Set the new time
        try {
            this.audio.currentTime = newTime;
        } catch (error) {
            console.error('Seek error:', error);
        }
        
        // Update UI immediately
        this.updateProgress();
    }

    setVolume(value) {
        this.audio.volume = value / 100;
        this.volumeValue.textContent = `${value}%`;
    }

    formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return '0:00';
        
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }

    updateQueue() {
        if (this.playlist.length === 0) {
            this.queueList.innerHTML = '<p class="empty-queue">Nessuna traccia nella coda</p>';
            return;
        }
        
        this.queueList.innerHTML = '';
        
        this.playlist.forEach((track, index) => {
            const queueItem = document.createElement('div');
            queueItem.className = 'queue-item';
            if (index === this.currentIndex) {
                queueItem.classList.add('current');
            }
            
            queueItem.innerHTML = `
                <span class="queue-item-number">${index + 1}.</span>
                <span>${track.name}</span>
            `;
            
            queueItem.addEventListener('click', () => {
                this.playTrack(index);
            });
            
            this.queueList.appendChild(queueItem);
        });
    }
}

// Initialize the player when DOM is loaded
// Initialize the audio player when the page loads
console.log('=== INITIALIZING AUDIO PLAYER ===');
document.addEventListener('DOMContentLoaded', () => {
    console.log('=== DOM CONTENT LOADED ===');
    window.audioPlayer = new AudioPlayer();
    console.log('=== AUDIO PLAYER CREATED ===');
});

