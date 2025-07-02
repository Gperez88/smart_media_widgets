import 'package:flutter/material.dart';

class VideoError extends StatelessWidget {
  final double? width;
  final double? height;
  final String? errorMessage;
  final Widget? errorWidget;

  const VideoError({
    super.key,
    this.width,
    this.height,
    this.errorMessage,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, size: 48, color: Colors.white54),
          const SizedBox(height: 8),
          const Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage ?? 'Unknown error',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
