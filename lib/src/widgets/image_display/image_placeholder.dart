import 'package:flutter/material.dart';

class ImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showLoadingIndicator;
  final Color? loadingColor;
  final Widget? placeholder;

  const ImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.showLoadingIndicator = true,
    this.loadingColor,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.grey[300],
      ),
      child: showLoadingIndicator
          ? Center(
              child: CircularProgressIndicator(
                color: loadingColor ?? Colors.grey[600],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
