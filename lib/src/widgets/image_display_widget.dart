import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/cache_manager.dart';
import '../utils/media_utils.dart';

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

  Widget _buildImage() {
    if (MediaUtils.isRemoteSource(widget.imageSource)) {
      if (widget.disableCache) {
        // Use NetworkImage instead of CachedNetworkImage when cache is disabled
        return Image.network(
          widget.imageSource,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              widget.onImageLoaded?.call();
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  image: DecorationImage(
                    image: NetworkImage(widget.imageSource),
                    fit: widget.fit,
                  ),
                ),
              );
            }
            return _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            widget.onImageError?.call(error.toString());
            return _buildErrorWidget(error.toString());
          },
        );
      } else {
        // Use CachedNetworkImage when cache is enabled
        return CachedNetworkImage(
          imageUrl: widget.imageSource,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) =>
              _buildErrorWidget(error.toString()),
          imageBuilder: (context, imageProvider) {
            widget.onImageLoaded?.call();
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                image: DecorationImage(image: imageProvider, fit: widget.fit),
              ),
            );
          },
        );
      }
    } else {
      // Local image
      final localPath = MediaUtils.normalizeLocalPath(widget.imageSource);
      return Image.file(
        File(localPath),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          widget.onImageError?.call(error.toString());
          return _buildErrorWidget(error.toString());
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            widget.onImageLoaded?.call();
          }
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(borderRadius: widget.borderRadius),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: child,
            ),
          );
        },
      );
    }
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: Colors.grey[300],
      ),
      child: widget.showLoadingIndicator
          ? Center(
              child: CircularProgressIndicator(
                color: widget.loadingColor ?? Colors.grey[600],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildErrorWidget(String error) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildImage();
  }
}
