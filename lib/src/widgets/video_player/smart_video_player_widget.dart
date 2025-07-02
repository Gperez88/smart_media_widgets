import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
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
    this.onVideoLoaded,
    this.onVideoError,
    this.onVideoPlay,
    this.onVideoPause,
    this.onVideoEnd,
  });

  @override
  State<SmartVideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<SmartVideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Function()? _restoreConfig;

  @override
  void initState() {
    super.initState();
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
    try {
      _isLoading = true;
      _hasError = false;

      if (mounted) setState(() {});

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

      // Initialize the controller
      await _videoPlayerController!.initialize();

      // Set up event listeners
      _videoPlayerController!.addListener(_videoListener);

      // Create Chewie controller
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
          _hasError = true;
          _errorMessage = errorMessage;
          widget.onVideoError?.call(errorMessage);
          return widget.errorWidget ?? _buildErrorWidget(errorMessage);
        },
      );

      _isLoading = false;
      widget.onVideoLoaded?.call();

      if (mounted) setState(() {});
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      _isLoading = false;
      widget.onVideoError?.call(e.toString());

      if (mounted) setState(() {});
    }
  }

  /// Descarga el video en segundo plano para caché futuro
  Future<void> _downloadVideoInBackground(String videoUrl) async {
    try {
      // Descargar sin bloquear la UI
      await CacheManager.cacheVideo(videoUrl);
    } catch (e) {
      // Ignorar errores de descarga en segundo plano
      // No afecta la reproducción actual
    }
  }

  void _videoListener() {
    if (_videoPlayerController == null) return;

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
