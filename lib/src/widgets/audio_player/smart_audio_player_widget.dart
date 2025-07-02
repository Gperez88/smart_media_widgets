import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import 'smart_audio_player_content.dart';
import 'smart_audio_player_error.dart';
import 'smart_audio_player_placeholder.dart';

/// SmartAudioPlayerWidget
///
/// A smart widget for playing audio files (local or remote) with waveform visualization,
/// preloading, robust error handling, and modern UI. Uses the audio_waveforms package.
///
/// - Supports local and remote audio sources.
/// - Allows cache configuration (global or per instance).
/// - Modern bubble-style UI with play/pause control and waveform.
/// - Handles errors and provides a fallback visual.
///
/// See README for usage details.
class SmartAudioPlayerWidget extends StatefulWidget {
  /// The audio source (URL or local file path)
  final String audioSource;

  /// Width of the audio player card
  final double? width;

  /// Height of the audio player card
  final double? height;

  /// Border radius for the card
  final BorderRadius? borderRadius;

  /// Placeholder widget to show while loading
  final Widget? placeholder;

  /// Error widget to show when audio fails to load
  final Widget? errorWidget;

  /// Whether to show a loading indicator
  final bool showLoadingIndicator;

  /// Local cache configuration for this widget (overrides global config)
  final CacheConfig? localCacheConfig;

  /// Whether to use the global cache configuration
  final bool useGlobalConfig;

  /// Callback when audio loads successfully
  final VoidCallback? onAudioLoaded;

  /// Callback when audio fails to load
  final Function(String error)? onAudioError;

  /// Main color for the card and waveform (default: blue)
  final Color color;

  /// Icon for play button (default: Icons.play_arrow)
  final IconData playIcon;

  /// Icon for pause button (default: Icons.pause)
  final IconData pauseIcon;

  /// Animation duration for play/pause transitions
  final Duration animationDuration;

  /// Waveform style (optional, overrides default)
  final PlayerWaveStyle? waveStyle;

  /// Whether to show seek line in waveform
  final bool showSeekLine;

  /// Whether to show duration text
  final bool showDuration;

  /// Whether to show current position text
  final bool showPosition;

  /// Text style for duration and position text
  final TextStyle? timeTextStyle;

  /// Background color for the player (default: transparent)
  final Color? backgroundColor;

  /// Whether to use bubble-style design (default: true)
  final bool useBubbleStyle;

  /// Padding around the player content
  final EdgeInsetsGeometry? padding;

  /// Margin around the player
  final EdgeInsetsGeometry? margin;

  /// Whether to disable caching for this specific audio
  final bool disableCache;

  /// Whether to enable global player mode (WhatsApp/Telegram style)
  final bool enableGlobalPlayer;

  /// Optional widget to display at the left side of the player (e.g., avatar, icon)
  final Widget? leftWidget;

  /// Optional widget to display at the right side of the player (e.g., trailing icon, status)
  final Widget? rightWidget;

  const SmartAudioPlayerWidget({
    super.key,
    required this.audioSource,
    this.width,
    this.height = 80,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = true,
    this.localCacheConfig,
    this.useGlobalConfig = true,
    this.onAudioLoaded,
    this.onAudioError,
    this.color = const Color(0xFF1976D2),
    this.playIcon = Icons.play_arrow,
    this.pauseIcon = Icons.pause,
    this.animationDuration = const Duration(milliseconds: 300),
    this.waveStyle,
    this.showSeekLine = true,
    this.showDuration = true,
    this.showPosition = true,
    this.timeTextStyle,
    this.backgroundColor,
    this.useBubbleStyle = true,
    this.padding,
    this.margin,
    this.disableCache = false,
    this.enableGlobalPlayer = false,
    this.leftWidget,
    this.rightWidget,
  });

  @override
  State<SmartAudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

/// Main widget state that handles business logic
class _AudioPlayerWidgetState extends State<SmartAudioPlayerWidget>
    with TickerProviderStateMixin {
  // Only create PlayerController if not using global player mode
  PlayerController? _playerController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Player state
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _audioPath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Cache configuration management
  Function()? _restoreConfig;
  StreamSubscription? _durationSubscription;

  // Global player subscription for cleanup
  StreamSubscription? _globalPlayerSubscription;

  /// Get or create PlayerController based on mode
  PlayerController get _effectivePlayerController {
    // Both global and local players use their own controller
    return _playerController ??= PlayerController();
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _applyCacheConfig();

    // Register global player if enabled
    if (widget.enableGlobalPlayer) {
      GlobalAudioPlayerManager.instance.registerGlobalPlayer(
        widget.audioSource,
        _stopFromGlobalManager,
      );
    }

    // Both global and local players work exactly the same way now
    _prepareAudio();
    _setupPlayerListeners();
    
    // Global players no longer need complex listeners
    // They work as local players and only notify overlay when needed
  }

  @override
  void didUpdateWidget(SmartAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleWidgetUpdates(oldWidget);
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }



  /// Initialize widget animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  /// Handle widget updates
  void _handleWidgetUpdates(SmartAudioPlayerWidget oldWidget) {
    if (_hasCacheConfigChanged(oldWidget)) {
      _restoreConfig?.call();
      _applyCacheConfig();
    }
    if (oldWidget.audioSource != widget.audioSource &&
        !widget.enableGlobalPlayer) {
      // Only re-prepare audio in local mode
      _prepareAudio();
    }
  }

  /// Check if cache configuration has changed
  bool _hasCacheConfigChanged(SmartAudioPlayerWidget oldWidget) {
    return oldWidget.localCacheConfig != widget.localCacheConfig ||
        oldWidget.useGlobalConfig != widget.useGlobalConfig;
  }

  /// Setup player listeners
  void _setupPlayerListeners() {
    // Both global and local players setup listeners the same way

    _durationSubscription = _effectivePlayerController.onCurrentDurationChanged.listen((
      duration,
    ) {
      if (mounted) {
        setState(() {
          // Both global and local players update position the same way
          _position = Duration(milliseconds: duration);
        });
        
        // If this is a global player, update the overlay with position changes
        if (widget.enableGlobalPlayer && !_isLoading) {
          _notifyGlobalPlayback();
        }
      }
    });
  }

  /// Apply cache configuration
  void _applyCacheConfig() {
    if (!widget.useGlobalConfig && widget.localCacheConfig != null) {
      _restoreConfig = CacheManager.instance.applyTemporaryConfig(
        widget.localCacheConfig!,
      );
    } else if (widget.localCacheConfig != null) {
      final effectiveConfig = CacheManager.instance.getEffectiveConfig(
        widget.localCacheConfig,
      );
      _restoreConfig = CacheManager.instance.applyTemporaryConfig(
        effectiveConfig,
      );
    }
  }

  /// Prepare audio for playback
  Future<void> _prepareAudio() async {
    _setLoadingState(true);

    try {
      final path = await _resolveAudioPath();
      _audioPath = path;

      log('AudioPlayerWidget: Preparing player with path: $_audioPath');

      // If it's a remote audio and not cached, start background download
      if (MediaUtils.isRemoteSource(widget.audioSource)) {
        final cachedPath = await CacheManager.getCachedAudioPath(
          widget.audioSource,
        );
        if (cachedPath == null) {
          // Start background download for future cache
          _downloadAudioInBackground(widget.audioSource);
        }
      }

      // Validate the path before preparing the player
      if (MediaUtils.isRemoteSource(_audioPath!)) {
        if (!MediaUtils.isValidRemoteUrl(_audioPath!)) {
          throw Exception('Invalid remote URL: $_audioPath');
        }
        if (!MediaUtils.isValidAudioUrl(_audioPath!)) {
          debugPrint(
            'AudioPlayerWidget: Warning - URL may not be a valid audio file: $_audioPath',
          );
        }
      } else {
        // For local files (including cached files), verify they exist
        if (!File(_audioPath!).existsSync()) {
          debugPrint(
            'AudioPlayerWidget: File not found, attempting to re-resolve path: $_audioPath',
          );

          // Try to re-resolve the path in case cache was cleared
          final newPath = await _resolveAudioPath();
          if (newPath != _audioPath) {
            _audioPath = newPath;
            debugPrint('AudioPlayerWidget: Re-resolved path: $_audioPath');
          } else {
            throw Exception('Local audio file not found: $_audioPath');
          }
        }
      }

      // Additional validation: if this is a cached file path, double-check it exists
      if (_audioPath != null &&
          !MediaUtils.isRemoteSource(_audioPath!) &&
          MediaUtils.isRemoteSource(widget.audioSource)) {
        // This is a cached file path, verify it still exists
        if (!File(_audioPath!).existsSync()) {
          debugPrint(
            'AudioPlayerWidget: Cached file no longer exists, falling back to remote URL',
          );
          _audioPath = widget.audioSource;
        }
      }

      await _effectivePlayerController.preparePlayer(
        path: _audioPath!,
        shouldExtractWaveform: true,
      );

      _duration = const Duration(minutes: 3); // Default, will be updated
      widget.onAudioLoaded?.call();
      _setLoadingState(false);
    } catch (e) {
      debugPrint('AudioPlayerWidget: Error preparing audio: $e');
      await _handlePlayerError(e);
    }
  }

  /// Resolve audio path (local or remote)
  Future<String> _resolveAudioPath() async {
    debugPrint('AudioPlayerWidget: Resolving path for: ${widget.audioSource}');

    if (MediaUtils.isRemoteSource(widget.audioSource)) {
      debugPrint('AudioPlayerWidget: Detected remote source');

      // Check if already cached
      final cachedPath = await CacheManager.getCachedAudioPath(
        widget.audioSource,
      );

      if (cachedPath != null) {
        debugPrint('AudioPlayerWidget: Found cached path: $cachedPath');

        // Validate that the cached file still exists
        if (File(cachedPath).existsSync()) {
          debugPrint('AudioPlayerWidget: Using cached path: $cachedPath');
          return cachedPath;
        } else {
          debugPrint(
            'AudioPlayerWidget: Cached file no longer exists, falling back to remote URL',
          );
          // If cached file was deleted, fall back to remote URL
          return widget.audioSource;
        }
      } else {
        debugPrint(
          'AudioPlayerWidget: Using remote URL directly: ${widget.audioSource}',
        );
        // If not cached, use progressive streaming
        // The audio_waveforms package supports URLs directly
        return widget.audioSource;
      }
    } else if (MediaUtils.isLocalSource(widget.audioSource)) {
      debugPrint('AudioPlayerWidget: Detected local source');
      final path = MediaUtils.normalizeLocalPath(widget.audioSource);
      debugPrint('AudioPlayerWidget: Normalized local path: $path');

      if (!File(path).existsSync()) {
        throw Exception('Local audio file not found: $path');
      }
      return path;
    } else {
      debugPrint(
        'AudioPlayerWidget: Invalid source detected: ${widget.audioSource}',
      );
      throw Exception('Invalid audio source: ${widget.audioSource}');
    }
  }

  /// Download audio in background for future cache
  Future<void> _downloadAudioInBackground(String audioUrl) async {
    try {
      // Download without blocking the UI
      await CacheManager.cacheAudio(audioUrl);
    } catch (e) {
      // Ignore background download errors
      // Does not affect current playback
      debugPrint('Background audio download failed: $e');
    }
  }

  /// Handle audio errors
  void _handleAudioError(String error) {
    _hasError = true;
    _errorMessage = error;
    widget.onAudioError?.call(_errorMessage!);
    _setLoadingState(false);
  }

  /// Set loading state
  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) {
          _hasError = false;
          _errorMessage = null;
        }
      });
    }
  }

  /// Toggle between play and pause
  Future<void> _togglePlayPause() async {
    // Both global and local players now work the same way
    try {
      // If this is a global player starting to play, stop any existing global player first
      if (widget.enableGlobalPlayer && !_isPlaying) {
        await _stopOtherGlobalPlayers();
      }

      if (_isPlaying) {
        await _effectivePlayerController.pausePlayer();
      } else {
        await _effectivePlayerController.startPlayer();
      }

      if (mounted) {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }

      // If this is a global player, always notify the overlay of state changes
      if (widget.enableGlobalPlayer) {
        await _notifyGlobalPlayback();
      }
    } catch (e) {
      // Handle playback errors with recovery
      await _handlePlayerError(e);
    }
  }



  /// Notify the global overlay about this player becoming active
  Future<void> _notifyGlobalPlayback() async {
    try {
      // Create overlay state that mirrors this player's state
      await GlobalAudioPlayerManager.instance.syncWithLocalPlayer(
        audioSource: widget.audioSource,
        playerController: _effectivePlayerController,
        isPlaying: _isPlaying,
        position: _position,
        duration: _duration,
        color: widget.color,
        playIcon: widget.playIcon,
        pauseIcon: widget.pauseIcon,
        waveStyle: widget.waveStyle,
        showSeekLine: widget.showSeekLine,
      );
    } catch (e) {
      debugPrint('AudioPlayerWidget: Error notifying global playback: $e');
    }
  }

  /// Stop other global players before starting this one
  Future<void> _stopOtherGlobalPlayers() async {
    await GlobalAudioPlayerManager.instance.stopOtherGlobalPlayers(widget.audioSource);
  }

  /// Stop this player when called by global manager
  void _stopFromGlobalManager() {
    if (mounted && _isPlaying) {
      log('AudioPlayerWidget: Stopping due to global manager request: ${widget.audioSource}');
      _effectivePlayerController.pausePlayer().then((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }).catchError((e) {
        log('AudioPlayerWidget: Error stopping player: $e');
      });
    }
  }



  /// Clean up resources
  void _cleanup() {
    // Unregister global player if enabled
    if (widget.enableGlobalPlayer) {
      GlobalAudioPlayerManager.instance.unregisterGlobalPlayer(widget.audioSource);
    }

    _restoreConfig?.call();
    _durationSubscription?.cancel();
    _globalPlayerSubscription?.cancel();

    // Only dispose local player if it exists and we're not in global mode
    if (_playerController != null && !widget.enableGlobalPlayer) {
      _playerController!.dispose();
      _playerController = null;
    }

    _animationController.dispose();
  }

  /// Clear cached file reference if it no longer exists
  Future<void> _clearInvalidCacheReference() async {
    if (_audioPath != null &&
        MediaUtils.isRemoteSource(widget.audioSource) &&
        !MediaUtils.isRemoteSource(_audioPath!)) {
      // This is a cached file path, check if it still exists
      if (!File(_audioPath!).existsSync()) {
        debugPrint(
          'AudioPlayerWidget: Clearing invalid cache reference: $_audioPath',
        );
        _audioPath = null;
      }
    }
  }

  /// Handle player errors and attempt recovery
  Future<void> _handlePlayerError(dynamic error) async {
    debugPrint('AudioPlayerWidget: Player error: $error');

    // Check if it's a file not found error or platform exception with source error
    final errorString = error.toString();
    if (errorString.contains('FileNotFoundException') ||
        errorString.contains('ENOENT') ||
        errorString.contains('No such file or directory') ||
        (errorString.contains('PlatformException') &&
            errorString.contains('Source error') &&
            errorString.contains('Unable to load media source'))) {
      debugPrint(
        'AudioPlayerWidget: Detected file not found or source error, attempting recovery',
      );

      // Clear invalid cache reference
      await _clearInvalidCacheReference();

      // Try to re-prepare the audio
      try {
        await _prepareAudio();
        return; // Success, exit early
      } catch (e) {
        debugPrint('AudioPlayerWidget: Recovery failed: $e');
      }
    }

    // If recovery failed or it's a different error, handle normally
    _handleAudioError(error.toString());
  }

  @override
  Widget build(BuildContext context) {
    // Identical build logic for both global and local players
    if (_isLoading) {
      return AudioPlayerPlaceholder(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        borderRadius: widget.borderRadius,
        backgroundColor: widget.backgroundColor,
        color: widget.color,
        placeholder: widget.placeholder,
        showLoadingIndicator: widget.showLoadingIndicator,
      );
    }

    if (_hasError) {
      return AudioPlayerError(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        borderRadius: widget.borderRadius,
        backgroundColor: widget.backgroundColor,
        errorWidget: widget.errorWidget,
        errorMessage: _errorMessage,
      );
    }

    // Both global and local players show content the same way
    return AudioPlayerContent(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      borderRadius: widget.borderRadius,
      backgroundColor: widget.backgroundColor,
      color: widget.color,
      useBubbleStyle: widget.useBubbleStyle,
      padding: widget.padding,
      playerController: _effectivePlayerController,
      isPlaying: _isPlaying,
      position: _position,
      duration: _duration,
      playIcon: widget.playIcon,
      pauseIcon: widget.pauseIcon,
      animationDuration: widget.animationDuration,
      animationController: _animationController,
      scaleAnimation: _scaleAnimation,
      waveStyle: widget.waveStyle,
      showSeekLine: widget.showSeekLine,
      showDuration: widget.showDuration,
      showPosition: widget.showPosition,
      timeTextStyle: widget.timeTextStyle,
      onTogglePlayPause: _togglePlayPause,
      leftWidget: widget.leftWidget,
      rightWidget: widget.rightWidget,
      waveformData: null, // Waveform comes from the player controller itself
    );
  }
}
