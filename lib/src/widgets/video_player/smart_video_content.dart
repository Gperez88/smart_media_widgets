import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class VideoContent extends StatelessWidget {
  final double? width;
  final double? height;
  final ChewieController chewieController;

  const VideoContent({
    super.key,
    this.width,
    this.height,
    required this.chewieController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Chewie(controller: chewieController),
    );
  }
}
