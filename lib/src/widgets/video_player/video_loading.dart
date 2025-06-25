import 'package:flutter/material.dart';

class VideoLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? loadingColor;

  const VideoLoading({super.key, this.width, this.height, this.loadingColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: loadingColor ?? Colors.white),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: loadingColor ?? Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
