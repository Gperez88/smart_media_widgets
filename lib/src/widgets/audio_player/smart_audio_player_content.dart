import 'package:flutter/material.dart';

import 'smart_audio_play_pause_button.dart';
import 'smart_audio_time_display.dart';

class AudioPlayerContent extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color color;
  final bool useBubbleStyle;
  final EdgeInsetsGeometry? padding;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final IconData playIcon;
  final IconData pauseIcon;
  final Duration animationDuration;
  final AnimationController animationController;
  final Animation<double> scaleAnimation;
  final bool showDuration;
  final bool showPosition;
  final TextStyle? timeTextStyle;
  final VoidCallback onTogglePlayPause;
  final Widget? leftWidget;
  final Widget? rightWidget;

  const AudioPlayerContent({
    super.key,
    this.width,
    this.height,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    required this.color,
    required this.useBubbleStyle,
    this.padding,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.playIcon,
    required this.pauseIcon,
    required this.animationDuration,
    required this.animationController,
    required this.scaleAnimation,
    required this.showDuration,
    required this.showPosition,
    this.timeTextStyle,
    required this.onTogglePlayPause,
    this.leftWidget,
    this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectiveMargin = margin ?? EdgeInsets.zero;

    return Container(
      width: width,
      height: height,
      margin: effectiveMargin,
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? color,
                borderRadius: borderRadius ?? BorderRadius.circular(16),
                boxShadow: useBubbleStyle
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: effectivePadding,
                child: Row(
                  children: [
                    if (leftWidget != null) ...[
                      leftWidget!,
                      const SizedBox(width: 8),
                    ],
                    AudioPlayPauseButton(
                      isPlaying: isPlaying,
                      playIcon: playIcon,
                      pauseIcon: pauseIcon,
                      color: color,
                      animationDuration: animationDuration,
                      animationController: animationController,
                      onTogglePlayPause: onTogglePlayPause,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressSection(),
                          if (showDuration || showPosition) ...[
                            const SizedBox(height: 4),
                            _buildTimeDisplay(),
                          ],
                        ],
                      ),
                    ),
                    if (rightWidget != null) ...[
                      const SizedBox(width: 8),
                      rightWidget!,
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    // Debug log para verificar los valores
    debugPrint(
      'AudioPlayerContent: Position: ${position.inSeconds}s, Duration: ${duration.inSeconds}s, Progress: ${(progress * 100).toStringAsFixed(1)}%',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withOpacity(0.8),
          ),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return AudioTimeDisplay(
      isPlaying: isPlaying,
      position: position,
      duration: duration,
      timeTextStyle:
          timeTextStyle ?? const TextStyle(color: Colors.white70, fontSize: 12),
    );
  }
}
