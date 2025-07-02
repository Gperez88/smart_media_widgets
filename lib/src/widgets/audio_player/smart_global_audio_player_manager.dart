import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

/// Global audio player state
class SmartGlobalAudioPlayerState {
  final String audioSource;
  final PlayerController playerController;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final Color color;
  final IconData playIcon;
  final IconData pauseIcon;
  final PlayerWaveStyle? waveStyle;
  final bool showSeekLine;

  const SmartGlobalAudioPlayerState({
    required this.audioSource,
    required this.playerController,
    this.isPlaying = false,
    this.isLoading = true,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
    this.color = const Color(0xFF1976D2),
    this.playIcon = Icons.play_arrow,
    this.pauseIcon = Icons.pause,
    this.waveStyle,
    this.showSeekLine = true,
  });

  SmartGlobalAudioPlayerState copyWith({
    String? audioSource,
    PlayerController? playerController,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    Color? color,
    IconData? playIcon,
    IconData? pauseIcon,
    PlayerWaveStyle? waveStyle,
    bool? showSeekLine,
  }) {
    return SmartGlobalAudioPlayerState(
      audioSource: audioSource ?? this.audioSource,
      playerController: playerController ?? this.playerController,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      color: color ?? this.color,
      playIcon: playIcon ?? this.playIcon,
      pauseIcon: pauseIcon ?? this.pauseIcon,
      waveStyle: waveStyle ?? this.waveStyle,
      showSeekLine: showSeekLine ?? this.showSeekLine,
    );
  }
}

/// Singleton manager for global audio player
class GlobalAudioPlayerManager {
  static final GlobalAudioPlayerManager _instance =
      GlobalAudioPlayerManager._internal();
  static GlobalAudioPlayerManager get instance => _instance;

  GlobalAudioPlayerManager._internal();

  // State management
  SmartGlobalAudioPlayerState? _currentState;
  final StreamController<SmartGlobalAudioPlayerState?> _stateController =
      StreamController<SmartGlobalAudioPlayerState?>.broadcast();

  // Player management
  PlayerController? _playerController;
  StreamSubscription? _durationSubscription;
  
  // Track if we're synced with a local player
  bool _isSyncedWithLocalPlayer = false;
  
  // Keep track of active global players to stop them when needed
  final Map<String, Function()> _activeGlobalPlayers = {};

  List<double>? _currentWaveformData;
  List<double>? get currentWaveformData => _currentWaveformData;
  
  // Cache de waveforms por audioSource
  final Map<String, List<double>> _waveformCache = {};
  
  /// Get waveform data for a specific audio source
  List<double>? getWaveformData(String audioSource) {
    return _waveformCache[audioSource];
  }
  
  /// Extract and cache waveform for an audio source (without starting playback)
  Future<List<double>?> extractWaveformForSource(String audioSource) async {
    // Check if already cached
    if (_waveformCache.containsKey(audioSource)) {
      return _waveformCache[audioSource];
    }
    
    try {
      log('GlobalAudioPlayerManager: Extracting waveform for: $audioSource');
      
      // Create temporary player controller for waveform extraction
      final tempController = PlayerController();
      
      try {
        // Resolve audio path
        final audioPath = await _resolveAudioPath(audioSource);
        
        // Prepare player for waveform extraction only
        await tempController.preparePlayer(
          path: audioPath,
          shouldExtractWaveform: true,
        );
        
        // Extract waveform
        final waveformData = await tempController.extractWaveformData(
          path: audioPath,
        );
        
        // Cache the result
        _waveformCache[audioSource] = waveformData;
        log('GlobalAudioPlayerManager: Successfully cached waveform for: $audioSource');
        
        return waveformData;
      } finally {
        // Always dispose temporary controller
        tempController.dispose();
      }
    } catch (e) {
      log('GlobalAudioPlayerManager: Error extracting waveform for $audioSource: $e');
      return null;
    }
  }

  /// Sync overlay with a local player that just started playing
  Future<void> syncWithLocalPlayer({
    required String audioSource,
    required PlayerController playerController,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    Color color = const Color(0xFF1976D2),
    IconData playIcon = Icons.play_arrow,
    IconData pauseIcon = Icons.pause,
    PlayerWaveStyle? waveStyle,
    bool showSeekLine = true,
  }) async {
    log('GlobalAudioPlayerManager: Syncing with local player: $audioSource');

    // Mark as synced mode
    _isSyncedWithLocalPlayer = true;

    // Create state that mirrors the local player
    _currentState = SmartGlobalAudioPlayerState(
      audioSource: audioSource,
      playerController: playerController, // Use the local player's controller
      isPlaying: isPlaying,
      isLoading: false,
      position: position,
      duration: duration,
      color: color,
      playIcon: playIcon,
      pauseIcon: pauseIcon,
      waveStyle: waveStyle,
      showSeekLine: showSeekLine,
    );

    // Use cached waveform if available
    _currentWaveformData = _waveformCache[audioSource];

    _notifyStateChange();
    
    log('GlobalAudioPlayerManager: Synced with local player for: $audioSource');
  }

  // Getters
  SmartGlobalAudioPlayerState? get currentState => _currentState;
  Stream<SmartGlobalAudioPlayerState?> get stateStream =>
      _stateController.stream;
  bool get hasActivePlayer => _currentState != null;
  bool get isPlaying => _currentState?.isPlaying ?? false;

  /// Start global playback for an audio source
  Future<void> startGlobalPlayback({
    required String audioSource,
    Color color = const Color(0xFF1976D2),
    IconData playIcon = Icons.play_arrow,
    IconData pauseIcon = Icons.pause,
    PlayerWaveStyle? waveStyle,
    bool showSeekLine = true,
    CacheConfig? cacheConfig,
    bool autoPlay = true,
  }) async {
    try {
      // Stop current player if any
      await stopGlobalPlayback();

      // Mark as global mode (not synced)
      _isSyncedWithLocalPlayer = false;

      // Create new player controller
      _playerController = PlayerController();
      _currentWaveformData = null;

      // Create initial state
      _currentState = SmartGlobalAudioPlayerState(
        audioSource: audioSource,
        playerController: _playerController!,
        isLoading: true,
        color: color,
        playIcon: playIcon,
        pauseIcon: pauseIcon,
        waveStyle: waveStyle,
        showSeekLine: showSeekLine,
      );

      _notifyStateChange();

      // Apply cache config temporarily if provided
      Function()? restoreConfig;
      if (cacheConfig != null) {
        restoreConfig = CacheManager.instance.applyTemporaryConfig(cacheConfig);
      }

      try {
        // Resolve audio path (exactly like local player)
        final audioPath = await _resolveAudioPath(audioSource);

        log('GlobalAudioPlayerManager: Preparing player with path: $audioPath');

        // Validate the path before preparing (like local player does)
        if (MediaUtils.isRemoteSource(audioPath)) {
          if (!MediaUtils.isValidRemoteUrl(audioPath)) {
            throw Exception('Invalid remote URL: $audioPath');
          }
          if (!MediaUtils.isValidAudioUrl(audioPath)) {
            log(
              'GlobalAudioPlayerManager: Warning - URL may not be a valid audio file: $audioPath',
            );
          }
        } else {
          // For local files (including cached files), verify they exist
          if (!File(audioPath).existsSync()) {
            throw Exception('Local audio file not found: $audioPath');
          }
        }

        // Prepare player (exactly like local player)
        await _playerController!.preparePlayer(
          path: audioPath,
          shouldExtractWaveform: true,
        );

        // EXTRAER Y GUARDAR EL WAVEFORM
        try {
          _currentWaveformData = await _playerController!.extractWaveformData(
            path: audioPath,
          );
          
          // Cache the waveform data for this audio source
          if (_currentWaveformData != null) {
            _waveformCache[audioSource] = _currentWaveformData!;
            log('GlobalAudioPlayerManager: Cached waveform for: $audioSource');
          }
        } catch (e) {
          log('GlobalAudioPlayerManager: Error extracting waveform: $e');
          _currentWaveformData = null;
        }
        _notifyStateChange(); // Notificar que el waveform está listo

        // Setup listeners (like local player)
        _setupPlayerListeners();

        // Mark as loaded (exactly like local player does)
        _currentState = _currentState!.copyWith(
          isLoading: false,
          duration: const Duration(
            minutes: 3,
          ), // Default, will be updated by listeners
        );

        _notifyStateChange();

        // Start playback inmediatamente solo si autoPlay es true
        if (autoPlay) {
          await togglePlayPause();
        }
      } finally {
        // Restore cache config
        restoreConfig?.call();
      }
    } catch (e, stackTrace) {
      log('GlobalAudioPlayerManager: Error starting global playback: $e');
      log('GlobalAudioPlayerManager: Stack trace: $stackTrace');

      _currentState = _currentState?.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );

      _notifyStateChange();
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_currentState == null) {
      log('GlobalAudioPlayerManager: Cannot toggle - no state');
      return;
    }

    try {
      log(
        'GlobalAudioPlayerManager: Toggling playback - current isPlaying: ${_currentState!.isPlaying}, synced: $_isSyncedWithLocalPlayer',
      );

      PlayerController? controllerToUse;
      
      if (_isSyncedWithLocalPlayer) {
        // In synced mode, use the local player's controller from the state
        controllerToUse = _currentState!.playerController;
      } else {
        // In global mode, use our own controller
        controllerToUse = _playerController;
      }

      if (controllerToUse == null) {
        log('GlobalAudioPlayerManager: Cannot toggle - no controller available');
        return;
      }

      if (_currentState!.isPlaying) {
        log('GlobalAudioPlayerManager: Pausing player');
        await controllerToUse.pausePlayer();
      } else {
        log('GlobalAudioPlayerManager: Starting player');
        await controllerToUse.startPlayer();
      }

      _currentState = _currentState!.copyWith(
        isPlaying: !_currentState!.isPlaying,
      );

      log(
        'GlobalAudioPlayerManager: Player state updated - new isPlaying: ${_currentState!.isPlaying}',
      );
      _notifyStateChange();
    } catch (e, stackTrace) {
      log('GlobalAudioPlayerManager: Error toggling playback: $e');
      log('GlobalAudioPlayerManager: Stack trace: $stackTrace');

      _currentState = _currentState?.copyWith(errorMessage: e.toString());

      _notifyStateChange();
    }
  }

  /// Stop global playback and cleanup
  Future<void> stopGlobalPlayback() async {
    if (_playerController != null && !_isSyncedWithLocalPlayer) {
      // Only dispose our own controller, not the local player's controller
      try {
        await _playerController!.stopPlayer();
        _playerController!.dispose();
      } catch (e) {
        log('GlobalAudioPlayerManager: Error stopping player: $e');
      }
    }

    _durationSubscription?.cancel();
    _playerController = null;
    _currentState = null;
    _isSyncedWithLocalPlayer = false; // Reset sync flag
    _activeGlobalPlayers.clear(); // Clear all registered players

    _notifyStateChange();
  }

  /// Register a global player
  void registerGlobalPlayer(String audioSource, Function() stopCallback) {
    _activeGlobalPlayers[audioSource] = stopCallback;
    log('GlobalAudioPlayerManager: Registered global player: $audioSource');
  }

  /// Unregister a global player
  void unregisterGlobalPlayer(String audioSource) {
    _activeGlobalPlayers.remove(audioSource);
    log('GlobalAudioPlayerManager: Unregistered global player: $audioSource');
  }

  /// Stop all other global players except the specified one
  /// If exceptAudioSource is empty, stops all players
  Future<void> stopOtherGlobalPlayers(String exceptAudioSource) async {
    final playersToStop = exceptAudioSource.isEmpty 
        ? _activeGlobalPlayers.entries.toList()
        : _activeGlobalPlayers.entries
            .where((entry) => entry.key != exceptAudioSource)
            .toList();
    
    for (final entry in playersToStop) {
      log('GlobalAudioPlayerManager: Stopping global player: ${entry.key}');
      try {
        entry.value(); // Call the stop callback
      } catch (e) {
        log('GlobalAudioPlayerManager: Error stopping player ${entry.key}: $e');
      }
    }
  }

  /// Check if this audio source is currently playing globally
  bool isCurrentlyPlayingGlobally(String audioSource) {
    return _currentState?.audioSource == audioSource && hasActivePlayer;
  }

  /// Seek to specific position in global player
  Future<void> seekTo(Duration position) async {
    if (_playerController == null || _currentState == null) {
      log('GlobalAudioPlayerManager: Cannot seek - no controller or state');
      return;
    }

    try {
      log('GlobalAudioPlayerManager: Seeking to ${position.inSeconds}s');

      // Seek in player controller
      await _playerController!.seekTo(position.inMilliseconds);

      // Update state immediately for responsive UI
      _currentState = _currentState!.copyWith(position: position);

      _notifyStateChange();
    } catch (e, stackTrace) {
      log('GlobalAudioPlayerManager: Error seeking: $e');
      log('GlobalAudioPlayerManager: Stack trace: $stackTrace');

      _currentState = _currentState?.copyWith(errorMessage: e.toString());

      _notifyStateChange();
    }
  }

  /// Setup player listeners
  void _setupPlayerListeners() {
    if (_playerController == null) return;

    _durationSubscription = _playerController!.onCurrentDurationChanged.listen((
      duration,
    ) {
      if (_currentState != null) {
        _currentState = _currentState!.copyWith(
          position: Duration(milliseconds: duration),
        );
        _notifyStateChange();
      }
    });
  }

  /// Resolve audio path (similar to AudioPlayerWidget logic)
  Future<String> _resolveAudioPath(String audioSource) async {
    log('GlobalAudioPlayerManager: Resolving path for: $audioSource');

    if (MediaUtils.isRemoteSource(audioSource)) {
      log('GlobalAudioPlayerManager: Detected remote source');

      // Check if already cached
      final cachedPath = await CacheManager.getCachedAudioPath(audioSource);

      if (cachedPath != null && await _fileExists(cachedPath)) {
        log('GlobalAudioPlayerManager: Using cached path: $cachedPath');
        return cachedPath;
      } else {
        log(
          'GlobalAudioPlayerManager: Using remote URL directly: $audioSource',
        );
        // Start background download for future cache
        _downloadAudioInBackground(audioSource);
        // Use remote URL directly
        return audioSource;
      }
    } else if (MediaUtils.isLocalSource(audioSource)) {
      log('GlobalAudioPlayerManager: Detected local source');
      final path = MediaUtils.normalizeLocalPath(audioSource);

      if (!await _fileExists(path)) {
        throw Exception('Local audio file not found: $path');
      }
      log('GlobalAudioPlayerManager: Using local path: $path');
      return path;
    } else {
      throw Exception('Invalid audio source: $audioSource');
    }
  }

  /// Check if file exists
  Future<bool> _fileExists(String path) async {
    try {
      return await Future(
        () => MediaUtils.isLocalSource(path) ? File(path).existsSync() : true,
      );
    } catch (e) {
      return false;
    }
  }

  /// Download audio in background for future cache
  Future<void> _downloadAudioInBackground(String audioUrl) async {
    try {
      await CacheManager.cacheAudio(audioUrl);
    } catch (e) {
      log('Background audio download failed: $e');
    }
  }

  /// Notify state change to listeners
  void _notifyStateChange() {
    _stateController.add(_currentState);
  }

  /// Dispose manager
  void dispose() {
    stopGlobalPlayback();
    _stateController.close();
  }
}
