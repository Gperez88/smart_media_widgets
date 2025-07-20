import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// SmartAudioWaveformWidget
///
/// A widget that displays audio waveform visualization with gesture controls
/// for seeking through the audio. Uses the audio_waveforms package for
/// rendering and interaction.
class SmartAudioWaveformWidget extends StatefulWidget {
  /// The player controller from audio_waveforms
  final PlayerController playerController;

  /// Height of the waveform widget
  final double height;

  /// Color of the waveform
  final Color color;

  /// Background color of the waveform
  final Color backgroundColor;

  /// Current playback position
  final Duration position;

  /// Total duration of the audio
  final Duration duration;

  /// Callback when user seeks to a position
  final Function(Duration)? onSeek;

  /// Width of the waveform (optional, defaults to available width)
  final double? width;

  /// Whether to enable gesture interactions
  final bool enableGesture;

  /// Waveform type (fitWidth or long)
  final WaveformType waveformType;

  const SmartAudioWaveformWidget({
    super.key,
    required this.playerController,
    this.height = 20,
    required this.color,
    required this.backgroundColor,
    required this.position,
    required this.duration,
    this.onSeek,
    this.width,
    this.enableGesture = true,
    this.waveformType = WaveformType.fitWidth,
  });

  @override
  State<SmartAudioWaveformWidget> createState() =>
      _SmartAudioWaveformWidgetState();
}

class _SmartAudioWaveformWidgetState extends State<SmartAudioWaveformWidget> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  @override
  void didUpdateWidget(SmartAudioWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerController != widget.playerController) {
      _checkInitialization();
    }
  }

  void _checkInitialization() {
    // Check if the player controller is initialized
    setState(() {
      _isInitialized = widget.playerController.playerState != PlayerState.stopped;
    });
  }

  void _onWaveformTap(double position) {
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
        child: _isInitialized
            ? _buildWaveform()
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildWaveform() {
    return GestureDetector(
      onTapDown: widget.enableGesture
          ? (details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(details.globalPosition);
              final tapPosition = localPosition.dx / renderBox.size.width;
              _onWaveformTap(tapPosition.clamp(0.0, 1.0));
            }
          : null,
      onPanUpdate: widget.enableGesture
          ? (details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(details.globalPosition);
              final dragPosition = localPosition.dx / renderBox.size.width;
              _onWaveformTap(dragPosition.clamp(0.0, 1.0));
            }
          : null,
      child: AudioFileWaveforms(
        playerController: widget.playerController,
        size: Size(widget.width ?? double.infinity, widget.height),
        waveformType: widget.waveformType,
        playerWaveStyle: PlayerWaveStyle(
          fixedWaveColor: widget.color,
          liveWaveColor: widget.color.withValues(alpha: 0.8),
          spacing: 2,
          showSeekLine: true,
          seekLineColor: widget.color,
          seekLineThickness: 2,
          waveThickness: 2,
          scaleFactor: 150,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    // Fallback to a progress bar when waveform is not available
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTapDown: widget.enableGesture
          ? (details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(details.globalPosition);
              final tapPosition = localPosition.dx / renderBox.size.width;
              _onWaveformTap(tapPosition.clamp(0.0, 1.0));
            }
          : null,
      onPanUpdate: widget.enableGesture
          ? (details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(details.globalPosition);
              final dragPosition = localPosition.dx / renderBox.size.width;
              _onWaveformTap(dragPosition.clamp(0.0, 1.0));
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