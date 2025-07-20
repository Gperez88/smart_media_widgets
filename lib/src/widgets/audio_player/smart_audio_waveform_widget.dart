import 'package:flutter/material.dart';

/// SmartAudioProgressWidget
///
/// A widget that displays audio progress bar with gesture controls
/// for seeking through the audio.
class SmartAudioWaveformWidget extends StatefulWidget {
  /// Height of the progress bar widget
  final double height;

  /// Color of the progress bar
  final Color color;

  /// Background color of the progress bar
  final Color backgroundColor;

  /// Current playback position
  final Duration position;

  /// Total duration of the audio
  final Duration duration;

  /// Callback when user seeks to a position
  final Function(Duration)? onSeek;

  /// Width of the progress bar (optional, defaults to available width)
  final double? width;

  /// Whether to enable gesture interactions
  final bool enableGesture;

  const SmartAudioWaveformWidget({
    super.key,
    this.height = 10,
    required this.color,
    required this.backgroundColor,
    required this.position,
    required this.duration,
    this.onSeek,
    this.width,
    this.enableGesture = true,
  });

  @override
  State<SmartAudioWaveformWidget> createState() =>
      _SmartAudioWaveformWidgetState();
}

class _SmartAudioWaveformWidgetState extends State<SmartAudioWaveformWidget> {
  void _onProgressTap(double position) {
    if (widget.onSeek == null || widget.duration.inMilliseconds == 0) return;

    // Calculate the seek position based on tap position
    final seekPosition = Duration(
      milliseconds: (position * widget.duration.inMilliseconds).round(),
    );

    widget.onSeek!(seekPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _buildProgressBar(),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTapDown: widget.enableGesture
          ? (details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(
                details.globalPosition,
              );
              final tapPosition = localPosition.dx / renderBox.size.width;
              _onProgressTap(tapPosition.clamp(0.0, 1.0));
            }
          : null,
      onPanUpdate: widget.enableGesture
          ? (details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(
                details.globalPosition,
              );
              final dragPosition = localPosition.dx / renderBox.size.width;
              _onProgressTap(dragPosition.clamp(0.0, 1.0));
            }
          : null,
      child: Stack(
        children: [
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            height: widget.height,
            width: (widget.width ?? 200) * progress.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
