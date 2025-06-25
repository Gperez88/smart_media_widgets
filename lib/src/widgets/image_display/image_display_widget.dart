import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import 'local_image_content.dart';
import 'remote_image_content.dart';

/// A smart widget for displaying images with preloading and error handling
class ImageDisplayWidget extends StatefulWidget {
  /// The image source (URL or local file path)
  final String imageSource;

  /// Width of the image container
  final double? width;

  /// Height of the image container
  final double? height;

  /// How to fit the image within its bounds
  final BoxFit fit;

  /// Border radius for the image
  final BorderRadius? borderRadius;

  /// Placeholder widget to show while loading
  final Widget? placeholder;

  /// Error widget to show when image fails to load
  final Widget? errorWidget;

  /// Whether to show a loading indicator
  final bool showLoadingIndicator;

  /// Color of the loading indicator
  final Color? loadingColor;

  /// Whether to preload the image
  final bool preload;

  /// Local cache configuration for this widget (overrides global config)
  final CacheConfig? localCacheConfig;

  /// Whether to use the global cache configuration
  final bool useGlobalConfig;

  /// Whether to disable caching for this specific image
  final bool disableCache;

  /// Callback when image loads successfully
  final VoidCallback? onImageLoaded;

  /// Callback when image fails to load
  final Function(String error)? onImageError;

  const ImageDisplayWidget({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = true,
    this.loadingColor,
    this.preload = true,
    this.localCacheConfig,
    this.useGlobalConfig = true,
    this.disableCache = false,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  State<ImageDisplayWidget> createState() => _ImageDisplayWidgetState();
}

class _ImageDisplayWidgetState extends State<ImageDisplayWidget> {
  Function()? _restoreConfig;

  @override
  void initState() {
    super.initState();
    if (widget.preload) {
      _preloadImage();
    }
    _applyCacheConfig();
  }

  @override
  void didUpdateWidget(ImageDisplayWidget oldWidget) {
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

  Future<void> _preloadImage() async {
    if (MediaUtils.isRemoteSource(widget.imageSource)) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(widget.imageSource),
          context,
        );
      } catch (e) {
        // Preload errors are handled silently
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaUtils.isRemoteSource(widget.imageSource)) {
      return RemoteImageContent(
        imageUrl: widget.imageSource,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        borderRadius: widget.borderRadius,
        disableCache: widget.disableCache,
        placeholder: widget.placeholder,
        errorWidget: widget.errorWidget,
        showLoadingIndicator: widget.showLoadingIndicator,
        loadingColor: widget.loadingColor,
        onImageLoaded: widget.onImageLoaded,
        onImageError: widget.onImageError,
      );
    } else {
      final localPath = MediaUtils.normalizeLocalPath(widget.imageSource);
      return LocalImageContent(
        imagePath: localPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        borderRadius: widget.borderRadius,
        errorWidget: widget.errorWidget,
        onImageLoaded: widget.onImageLoaded,
        onImageError: widget.onImageError,
      );
    }
  }
}
