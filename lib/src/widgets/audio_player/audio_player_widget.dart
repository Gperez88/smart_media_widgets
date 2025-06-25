import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import 'audio_player_content.dart';
import 'audio_player_error.dart';
import 'audio_player_placeholder.dart';

/// AudioPlayerWidget
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
class AudioPlayerWidget extends StatefulWidget {
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

  const AudioPlayerWidget({
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
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

/// Main widget state that handles business logic
class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin {
  final PlayerController _playerController = PlayerController();
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _applyCacheConfig();
    _prepareAudio();
    _setupPlayerListeners();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
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
  void _handleWidgetUpdates(AudioPlayerWidget oldWidget) {
    if (_hasCacheConfigChanged(oldWidget)) {
      _restoreConfig?.call();
      _applyCacheConfig();
    }
    if (oldWidget.audioSource != widget.audioSource) {
      _prepareAudio();
    }
  }

  /// Check if cache configuration has changed
  bool _hasCacheConfigChanged(AudioPlayerWidget oldWidget) {
    return oldWidget.localCacheConfig != widget.localCacheConfig ||
        oldWidget.useGlobalConfig != widget.useGlobalConfig;
  }

  /// Setup player listeners
  void _setupPlayerListeners() {
    _durationSubscription = _playerController.onCurrentDurationChanged.listen((
      duration,
    ) {
      if (mounted) {
        setState(() {
          _position = Duration(milliseconds: duration);
        });
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

      await _playerController.preparePlayer(
        path: _audioPath!,
        shouldExtractWaveform: true,
      );

      _duration = const Duration(minutes: 3); // Default, will be updated
      widget.onAudioLoaded?.call();
      _setLoadingState(false);
    } catch (e) {
      _handleAudioError(e.toString());
    }
  }

  /// Resolve audio path (local or remote)
  Future<String> _resolveAudioPath() async {
    if (MediaUtils.isRemoteSource(widget.audioSource)) {
      // Check if already cached
      final cachedPath = await CacheManager.getCachedAudioPath(
        widget.audioSource,
      );

      if (cachedPath != null) {
        // If cached, use local file (faster)
        return cachedPath;
      } else {
        // If not cached, use progressive streaming
        // The audio_waveforms package supports URLs directly
        return widget.audioSource;
      }
    } else if (MediaUtils.isLocalSource(widget.audioSource)) {
      final path = MediaUtils.normalizeLocalPath(widget.audioSource);
      if (!File(path).existsSync()) {
        throw Exception('Local audio file not found');
      }
      return path;
    } else {
      throw Exception('Invalid audio source');
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
    try {
      if (_isPlaying) {
        await _playerController.pausePlayer();
      } else {
        await _playerController.startPlayer();
      }

      if (mounted) {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
    } catch (e) {
      // Handle playback errors silently
      debugPrint('Error toggling play/pause: $e');
    }
  }

  /// Clean up resources
  void _cleanup() {
    _restoreConfig?.call();
    _durationSubscription?.cancel();
    _playerController.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return AudioPlayerContent(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      borderRadius: widget.borderRadius,
      backgroundColor: widget.backgroundColor,
      color: widget.color,
      useBubbleStyle: widget.useBubbleStyle,
      padding: widget.padding,
      playerController: _playerController,
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
    );
  }
}
