import 'package:flutter/material.dart';

class AudioTimeDisplay extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final TextStyle? timeTextStyle;

  const AudioTimeDisplay({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.timeTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isPlaying ? _formatDuration(position) : _formatDuration(duration),
          style: timeTextStyle ?? _getDefaultTextStyle(),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  TextStyle _getDefaultTextStyle() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
  }
}
