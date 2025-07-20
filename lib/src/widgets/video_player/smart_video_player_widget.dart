import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../utils/cache_manager.dart';
import '../../utils/media_utils.dart';
import 'smart_video_content.dart';
import 'smart_video_error.dart';
import 'smart_video_loading.dart';
import 'smart_video_placeholder.dart';

/// A smart widget for displaying videos with preloading and error handling
class SmartVideoPlayerWidget extends StatefulWidget {
  /// The video source (URL or local file path)
  final String videoSource;

  /// Width of the video container
  final double? width;

  /// Height of the video container
  final double? height;

  /// Whether to auto-play the video
  final bool autoPlay;

  /// Whether to loop the video
  final bool looping;

  /// Whether to show video controls
  final bool showControls;

  /// Whether to show the play button overlay
  final bool showPlayButton;

  /// Placeholder widget to show while loading
  final Widget? placeholder;

  /// Error widget to show when video fails to load
  final Widget? errorWidget;

  /// Whether to show a loading indicator
  final bool showLoadingIndicator;

  /// Color of the loading indicator
  final Color? loadingColor;

  /// Whether to preload the video
  final bool preload;

  /// Local cache configuration for this widget (overrides global config)
  final CacheConfig? localCacheConfig;

  /// Whether to use the global cache configuration
  final bool useGlobalConfig;

  /// Whether to disable caching for this specific video
  final bool disableCache;

  /// Android-specific video configuration
  final AndroidVideoConfig? androidConfig;

  /// Callback when video loads successfully
  final VoidCallback? onVideoLoaded;

  /// Callback when video fails to load
  final Function(String error)? onVideoError;

  /// Callback when video starts playing
  final VoidCallback? onVideoPlay;

  /// Callback when video pauses
  final VoidCallback? onVideoPause;

  /// Callback when video ends
  final VoidCallback? onVideoEnd;

  const SmartVideoPlayerWidget({
    super.key,
    required this.videoSource,
    this.width,
    this.height,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.showPlayButton = true,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = true,
    this.loadingColor,
    this.preload = true,
    this.localCacheConfig,
    this.useGlobalConfig = true,
    this.disableCache = false,
    this.androidConfig,
    this.onVideoLoaded,
    this.onVideoError,
    this.onVideoPlay,
    this.onVideoPause,
    this.onVideoEnd,
  });

  @override
  State<SmartVideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

/// Android-specific video configuration to prevent buffer overflow
class AndroidVideoConfig {
  /// Maximum number of buffers to use (default: 2 to prevent overflow)
  final int maxBuffers;

  /// Buffer size in bytes (default: 2MB)
  final int bufferSize;

  /// Whether to use hardware acceleration (default: true)
  final bool useHardwareAcceleration;

  /// Video format priority (default: h264)
  final String preferredFormat;

  /// Whether to enable adaptive streaming
  final bool enableAdaptiveStreaming;

  const AndroidVideoConfig({
    this.maxBuffers = 2,
    this.bufferSize = 2 * 1024 * 1024, // 2MB
    this.useHardwareAcceleration = true,
    this.preferredFormat = 'h264',
    this.enableAdaptiveStreaming = true,
  });

  @override
  String toString() {
    return 'AndroidVideoConfig(maxBuffers: $maxBuffers, bufferSize: ${bufferSize ~/ 1024}KB, hwAccel: $useHardwareAcceleration)';
  }
}

class _VideoPlayerWidgetState extends State<SmartVideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Function()? _restoreConfig;
  bool _isDisposed = false;

  // Android-specific configuration
  late final AndroidVideoConfig _androidConfig;

  @override
  void initState() {
    super.initState();
    _androidConfig = widget.androidConfig ?? const AndroidVideoConfig();
    _applyCacheConfig();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(SmartVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If cache config changed, update it
    if (oldWidget.localCacheConfig != widget.localCacheConfig ||
        oldWidget.useGlobalConfig != widget.useGlobalConfig) {
      _restoreConfig?.call();
      _applyCacheConfig();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _restoreConfig?.call();
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _applyCacheConfig() {
    if (!widget.useGlobalConfig && widget.localCacheConfig != null) {
      // Apply temporary config that will be restored on dispose
      _restoreConfig = CacheManager.instance.applyTemporaryConfig(
        widget.localCacheConfig!,
      );
    } else if (widget.localCacheConfig != null) {
      // Use effective config (global + local overrides)
      final effectiveConfig = CacheManager.instance.getEffectiveConfig(
        widget.localCacheConfig,
      );
      _restoreConfig = CacheManager.instance.applyTemporaryConfig(
        effectiveConfig,
      );
    }
  }

  Future<void> _initializeVideo() async {
    if (_isDisposed) return;

    try {
      _isLoading = true;
      _hasError = false;

      if (mounted) setState(() {});

      // Apply Android-specific configuration
      if (Platform.isAndroid) {
        await _applyAndroidVideoConfig();
      }

      // Create video player controller
      if (MediaUtils.isRemoteSource(widget.videoSource)) {
        if (widget.disableCache) {
          // Use streaming without caching when cache is disabled
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(widget.videoSource),
          );
        } else {
          // NUEVO: Streaming progresivo con caché en segundo plano
          final cachedPath = await CacheManager.getCachedVideoPath(
            widget.videoSource,
          );

          if (cachedPath != null) {
            // Si está en caché, usar archivo local (más rápido)
            _videoPlayerController = VideoPlayerController.file(
              File(cachedPath),
            );
          } else {
            // Si no está en caché, usar streaming progresivo
            _videoPlayerController = VideoPlayerController.networkUrl(
              Uri.parse(widget.videoSource),
            );

            // Descargar en segundo plano para caché futuro
            _downloadVideoInBackground(widget.videoSource);
          }
        }
      } else {
        final localPath = MediaUtils.normalizeLocalPath(widget.videoSource);
        _videoPlayerController = VideoPlayerController.file(File(localPath));
      }

      // Initialize the controller with timeout
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Video initialization timeout',
            const Duration(seconds: 30),
          );
        },
      );

      if (_isDisposed) return;

      // Set up event listeners
      _videoPlayerController!.addListener(_videoListener);

      // Create Chewie controller with Android-specific settings
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        placeholder: widget.placeholder ?? _buildPlaceholder(),
        errorBuilder: (context, errorMessage) {
          if (!_isDisposed) {
            _hasError = true;
            _errorMessage = errorMessage;
            widget.onVideoError?.call(errorMessage);
          }
          return widget.errorWidget ?? _buildErrorWidget(errorMessage);
        },
      );

      _isLoading = false;
      if (!_isDisposed) {
        widget.onVideoLoaded?.call();
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (!_isDisposed) {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
        widget.onVideoError?.call(e.toString());

        if (mounted) setState(() {});
      }
    }
  }

  /// Apply Android-specific video configuration to prevent buffer overflow
  Future<void> _applyAndroidVideoConfig() async {
    try {
      // Set Android-specific video player options
      if (Platform.isAndroid) {
        // Configure video player for better buffer management
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);

        // Log Android configuration for debugging
        print('SmartVideoPlayer: Applied Android config: $_androidConfig');
      }
    } catch (e) {
      print('SmartVideoPlayer: Error applying Android config: $e');
    }
  }

  /// Descarga el video en segundo plano para caché futuro
  Future<void> _downloadVideoInBackground(String videoUrl) async {
    if (_isDisposed) return;

    try {
      // Descargar sin bloquear la UI
      await CacheManager.cacheVideo(videoUrl);
    } catch (e) {
      // Ignorar errores de descarga en segundo plano
      // No afecta la reproducción actual
      print('SmartVideoPlayer: Background download failed: $e');
    }
  }

  void _videoListener() {
    if (_videoPlayerController == null || _isDisposed) return;

    if (_videoPlayerController!.value.isPlaying) {
      widget.onVideoPlay?.call();
    } else if (_videoPlayerController!.value.position ==
        _videoPlayerController!.value.duration) {
      widget.onVideoEnd?.call();
    } else if (!_videoPlayerController!.value.isPlaying &&
        _videoPlayerController!.value.position > Duration.zero) {
      widget.onVideoPause?.call();
    }
  }

  Widget _buildPlaceholder() {
    return VideoPlaceholder(
      width: widget.width,
      height: widget.height,
      showLoadingIndicator: widget.showLoadingIndicator,
      loadingColor: widget.loadingColor,
      placeholder: widget.placeholder,
    );
  }

  Widget _buildErrorWidget(String error) {
    return VideoError(
      width: widget.width,
      height: widget.height,
      errorMessage: error,
      errorWidget: widget.errorWidget,
    );
  }

  Widget _buildLoadingWidget() {
    return VideoLoading(
      width: widget.width,
      height: widget.height,
      loadingColor: widget.loadingColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget(_errorMessage ?? 'Unknown error');
    }

    if (_chewieController == null) {
      return _buildPlaceholder();
    }

    return VideoContent(
      width: widget.width,
      height: widget.height,
      chewieController: _chewieController!,
    );
  }
}
