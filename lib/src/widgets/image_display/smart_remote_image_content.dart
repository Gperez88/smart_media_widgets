import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'smart_image_error.dart';
import 'smart_image_placeholder.dart';

class RemoteImageContent extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool disableCache;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingIndicator;
  final Color? loadingColor;
  final VoidCallback? onImageLoaded;
  final Function(String error)? onImageError;

  const RemoteImageContent({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.disableCache = false,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = true,
    this.loadingColor,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    if (disableCache) {
      return _buildNetworkImage();
    } else {
      return _buildCachedNetworkImage();
    }
  }

  Widget _buildNetworkImage() {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          onImageLoaded?.call();
          return _buildImageContainer(
            DecorationImage(image: NetworkImage(imageUrl), fit: fit),
          );
        }
        return ImagePlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
          showLoadingIndicator: showLoadingIndicator,
          loadingColor: loadingColor,
          placeholder: placeholder,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        onImageError?.call(error.toString());
        return ImageError(
          width: width,
          height: height,
          borderRadius: borderRadius,
          errorWidget: errorWidget,
        );
      },
    );
  }

  Widget _buildCachedNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => ImagePlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        showLoadingIndicator: showLoadingIndicator,
        loadingColor: loadingColor,
        placeholder: placeholder,
      ),
      errorWidget: (context, url, error) {
        onImageError?.call(error.toString());
        return ImageError(
          width: width,
          height: height,
          borderRadius: borderRadius,
          errorWidget: errorWidget,
        );
      },
      imageBuilder: (context, imageProvider) {
        onImageLoaded?.call();
        return _buildImageContainer(
          DecorationImage(image: imageProvider, fit: fit),
        );
      },
    );
  }

  Widget _buildImageContainer(DecorationImage decorationImage) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        image: decorationImage,
      ),
    );
  }
}
