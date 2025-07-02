import 'package:flutter/material.dart';

class VideoPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showLoadingIndicator;
  final Color? loadingColor;
  final Widget? placeholder;

  const VideoPlaceholder({
    super.key,
    this.width,
    this.height,
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
      color: Colors.black,
      child: showLoadingIndicator
          ? Center(
              child: CircularProgressIndicator(
                color: loadingColor ?? Colors.white,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
