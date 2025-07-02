import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

/// Global audio player state
class GlobalAudioPlayerState {
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

  const GlobalAudioPlayerState({
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

  GlobalAudioPlayerState copyWith({
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
    return GlobalAudioPlayerState(
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
  static final GlobalAudioPlayerManager _instance = GlobalAudioPlayerManager._internal();
  static GlobalAudioPlayerManager get instance => _instance;
  
  GlobalAudioPlayerManager._internal();

  // State management
  GlobalAudioPlayerState? _currentState;
  final StreamController<GlobalAudioPlayerState?> _stateController = 
      StreamController<GlobalAudioPlayerState?>.broadcast();
  
  // Player management
  PlayerController? _playerController;
  StreamSubscription? _durationSubscription;
  
  // Getters
  GlobalAudioPlayerState? get currentState => _currentState;
  Stream<GlobalAudioPlayerState?> get stateStream => _stateController.stream;
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
  }) async {
    try {
      // Stop current player if any
      await stopGlobalPlayback();

      // Create new player controller
      _playerController = PlayerController();
      
      // Create initial state
      _currentState = GlobalAudioPlayerState(
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
            log('GlobalAudioPlayerManager: Warning - URL may not be a valid audio file: $audioPath');
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

        // Setup listeners (like local player)
        _setupPlayerListeners();

        // Mark as loaded (exactly like local player does)
        _currentState = _currentState!.copyWith(
          isLoading: false,
          duration: const Duration(minutes: 3), // Default, will be updated by listeners
        );
        
        _notifyStateChange();

        // Start playback immediately since user pressed play
        await togglePlayPause();

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
    if (_playerController == null || _currentState == null) {
      log('GlobalAudioPlayerManager: Cannot toggle - no controller or state');
      return;
    }

    try {
      log('GlobalAudioPlayerManager: Toggling playback - current isPlaying: ${_currentState!.isPlaying}');
      
      if (_currentState!.isPlaying) {
        log('GlobalAudioPlayerManager: Pausing player');
        await _playerController!.pausePlayer();
      } else {
        log('GlobalAudioPlayerManager: Starting player');
        await _playerController!.startPlayer();
      }

      _currentState = _currentState!.copyWith(
        isPlaying: !_currentState!.isPlaying,
      );
      
      log('GlobalAudioPlayerManager: Player state updated - new isPlaying: ${_currentState!.isPlaying}');
      _notifyStateChange();

    } catch (e, stackTrace) {
      log('GlobalAudioPlayerManager: Error toggling playback: $e');
      log('GlobalAudioPlayerManager: Stack trace: $stackTrace');
      
      _currentState = _currentState?.copyWith(
        errorMessage: e.toString(),
      );
      
      _notifyStateChange();
    }
  }

  /// Stop global playback and cleanup
  Future<void> stopGlobalPlayback() async {
    if (_playerController != null) {
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
    
    _notifyStateChange();
  }

  /// Check if this audio source is currently playing globally
  bool isCurrentlyPlayingGlobally(String audioSource) {
    return _currentState?.audioSource == audioSource && hasActivePlayer;
  }

  /// Setup player listeners
  void _setupPlayerListeners() {
    if (_playerController == null) return;

    _durationSubscription = _playerController!.onCurrentDurationChanged.listen((duration) {
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
        log('GlobalAudioPlayerManager: Using remote URL directly: $audioSource');
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
      return await Future(() => MediaUtils.isLocalSource(path) 
          ? File(path).existsSync() 
          : true);
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