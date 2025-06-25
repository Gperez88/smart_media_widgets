import 'package:flutter/material.dart';

class AudioPlayerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color color;
  final Widget? placeholder;
  final bool showLoadingIndicator;

  const AudioPlayerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    required this.color,
    this.placeholder,
    required this.showLoadingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        color: backgroundColor ?? color.withOpacity(0.1),
      ),
      child: showLoadingIndicator
          ? Center(child: CircularProgressIndicator(color: color))
          : const SizedBox.shrink(),
    );
  }
}
