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

  // Memory management
  bool _isDisposed = false;
  bool _isPreparing = false;

  /// Get or create PlayerController
  PlayerController get _effectivePlayerController {
    return _playerController ??= PlayerController();
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _applyCacheConfig();
    _prepareAudio();
    _setupPlayerListeners();
  }

  @override
  void didUpdateWidget(SmartAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleWidgetUpdates(oldWidget);
  }

  @override
  void dispose() {
    _isDisposed = true;
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
    if (oldWidget.audioSource != widget.audioSource) {
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

    _durationSubscription = _effectivePlayerController.onCurrentDurationChanged
        .listen((duration) {
          if (mounted) {
            setState(() {
              // Both global and local players update position the same way
              _position = Duration(milliseconds: duration);
            });

            // For global players, we don't need to sync on every position update
            // The global manager will handle position updates through its own listeners
            // Only sync when playback state changes (play/pause/stop)
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
    if (_isDisposed || _isPreparing) return;

    _isPreparing = true;
    _setLoadingState(true);

    try {
      final path = await _resolveAudioPath();
      if (_isDisposed) return;

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
          if (_isDisposed) return;

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
        if (!File(_audioPath!).existsSync()) {
          debugPrint(
            'AudioPlayerWidget: Cached file no longer exists, falling back to remote URL',
          );
          _audioPath = widget.audioSource;
        }
      }

      if (_isDisposed) return;

      // Determine if we should extract waveform based on source type and size
      final shouldExtract = await _shouldExtractWaveform(_audioPath!);

      // Add timeout to prevent infinite loading
      await _preparePlayerWithTimeout(
        path: _audioPath!,
        shouldExtractWaveform: shouldExtract,
      );

      if (_isDisposed) return;

      _duration = const Duration(minutes: 3); // Default, will be updated
      widget.onAudioLoaded?.call();
      _setLoadingState(false);
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('AudioPlayerWidget: Error preparing audio: $e');
        await _handlePlayerError(e);
      }
    } finally {
      _isPreparing = false;
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
    if (_isDisposed) return;

    // Both global and local players now work the same way
    try {
      if (_isPlaying) {
        // Pausing current player
        await _effectivePlayerController.pausePlayer();

        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        // Starting to play - ALWAYS ensure single audio playback first
        await _effectivePlayerController.startPlayer();

        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      // Handle playback errors with recovery
      if (!_isDisposed) {
        await _handlePlayerError(e);
      }
    }
  }

  /// Clean up resources
  void _cleanup() {
    _restoreConfig?.call();
    _durationSubscription?.cancel();

    // Always dispose local player controller to prevent memory leaks
    if (_playerController != null) {
      try {
        _playerController!.dispose();
      } catch (e) {
        debugPrint('AudioPlayerWidget: Error disposing player controller: $e');
      }
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

  /// Determine if waveform extraction should be enabled
  Future<bool> _shouldExtractWaveform(String path) async {
    try {
      // For remote sources, check if it's a reasonable size
      if (MediaUtils.isRemoteSource(path)) {
        // For remote URLs, disable waveform extraction by default to prevent timeouts
        // Only enable for specific trusted domains or smaller files
        if (path.contains('soundhelix.com') && path.endsWith('.mp3')) {
          // Enable for known small test files
          return true;
        }
        // Disable for other remote sources to prevent loading issues
        return false;
      }

      // For local files, check file size
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        // Only extract waveform for files smaller than 10MB
        return size < (10 * 1024 * 1024);
      }

      return false;
    } catch (e) {
      debugPrint('AudioPlayerWidget: Error checking waveform extraction: $e');
      return false;
    }
  }

  /// Prepare player with timeout and fallback
  Future<void> _preparePlayerWithTimeout({
    required String path,
    required bool shouldExtractWaveform,
  }) async {
    try {
      // First attempt with waveform extraction if enabled
      if (shouldExtractWaveform) {
        await _effectivePlayerController
            .preparePlayer(path: path, shouldExtractWaveform: true)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint(
                  'AudioPlayerWidget: Waveform extraction timed out, retrying without waveform',
                );
                throw TimeoutException(
                  'Waveform extraction timeout',
                  const Duration(seconds: 15),
                );
              },
            );
      } else {
        // Prepare without waveform extraction
        await _effectivePlayerController
            .preparePlayer(path: path, shouldExtractWaveform: false)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('AudioPlayerWidget: Player preparation timed out');
                throw TimeoutException(
                  'Player preparation timeout',
                  const Duration(seconds: 10),
                );
              },
            );
      }
    } on TimeoutException catch (e) {
      debugPrint('AudioPlayerWidget: Timeout during preparation: $e');

      // Fallback: try without waveform extraction
      if (shouldExtractWaveform) {
        debugPrint('AudioPlayerWidget: Retrying without waveform extraction');
        await _effectivePlayerController
            .preparePlayer(path: path, shouldExtractWaveform: false)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException(
                  'Final player preparation timeout',
                  const Duration(seconds: 10),
                );
              },
            );
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('AudioPlayerWidget: Error during player preparation: $e');
      rethrow;
    }
  }

  /// Handle player errors and attempt recovery
  Future<void> _handlePlayerError(dynamic error) async {
    if (_isDisposed) return;

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
    if (!_isDisposed) {
      _handleAudioError(error.toString());
    }
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
