import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import 'smart_audio_time_display.dart';

class AudioWaveformSection extends StatelessWidget {
  final PlayerController playerController;
  final double? width;
  final double? height;
  final PlayerWaveStyle? waveStyle;
  final bool showSeekLine;
  final bool showDuration;
  final bool showPosition;
  final bool isPlaying;
  final bool enableSeekGesture;
  final Duration position;
  final Duration duration;
  final TextStyle? timeTextStyle;

  const AudioWaveformSection({
    super.key,
    required this.playerController,
    this.width,
    this.height,
    this.waveStyle,
    required this.showSeekLine,
    required this.showDuration,
    required this.showPosition,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.timeTextStyle,
    this.enableSeekGesture = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: AudioFileWaveforms(
            size: Size((width ?? 240) - 80, (height ?? 80) - 60),
            playerController: playerController,
            waveformType: WaveformType.fitWidth,
            playerWaveStyle: waveStyle ?? _getDefaultWaveStyle(),
          ),
        ),
        if (showDuration || showPosition)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AudioTimeDisplay(
              isPlaying: isPlaying,
              position: position,
              duration: duration,
              timeTextStyle: timeTextStyle,
            ),
          ),
      ],
    );
  }

  PlayerWaveStyle _getDefaultWaveStyle() {
    return PlayerWaveStyle(
      fixedWaveColor: Colors.white.withValues(alpha: 0.7),
      liveWaveColor: Colors.white,
      showSeekLine: showSeekLine,
      waveThickness: 3,
      spacing: 5,
      scaleFactor: 80,
    );
  }
}
