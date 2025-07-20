import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import 'smart_audio_play_pause_button.dart';
import 'smart_audio_time_display.dart';
import 'smart_audio_waveform_widget.dart';

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
  final bool isLoading;
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
  final PlayerController? playerController;
  final Function(Duration)? onSeek;
  final double? waveformHeight;

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
    this.isLoading = false,
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
    this.playerController,
    this.onSeek,
    this.waveformHeight,
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
                      isLoading: isLoading,
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
    return SmartAudioWaveformWidget(
      height: waveformHeight ?? 10,
      color: Colors.white.withValues(alpha: 0.9),
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      position: position,
      duration: duration,
      onSeek: onSeek,
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
