import 'dart:io';
import 'package:flutter/material.dart';
import 'image_error.dart';

class LocalImageContent extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final VoidCallback? onImageLoaded;
  final Function(String error)? onImageError;

  const LocalImageContent({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        onImageError?.call(error.toString());
        return ImageError(
          width: width,
          height: height,
          borderRadius: borderRadius,
          errorWidget: errorWidget,
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          onImageLoaded?.call();
        }
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(borderRadius: borderRadius),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: child,
          ),
        );
      },
    );
  }
}
