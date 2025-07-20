import 'dart:async';

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

  /// Wave thickness
  final double waveThickness;

  /// Spacing between wave elements
  final double spacing;

  /// Scale factor for waveform amplification
  final double scaleFactor;

  /// Whether to show seek line
  final bool showSeekLine;

  /// Seek line thickness
  final double seekLineThickness;

  /// Wave cap style (round, square, butt)
  final StrokeCap waveCap;

  /// Whether to show continuous waveform updates
  final bool continuousWaveform;

  const SmartAudioWaveformWidget({
    super.key,
    required this.playerController,
    this.height = 10,
    required this.color,
    required this.backgroundColor,
    required this.position,
    required this.duration,
    this.onSeek,
    this.width,
    this.enableGesture = true,
    this.waveformType = WaveformType.fitWidth,
    this.waveThickness = 2.0,
    this.spacing = 3.0,
    this.scaleFactor = 200,
    this.showSeekLine = true,
    this.seekLineThickness = 3.0,
    this.waveCap = StrokeCap.round,
    this.continuousWaveform = true,
  });

  @override
  State<SmartAudioWaveformWidget> createState() =>
      _SmartAudioWaveformWidgetState();
}

class _SmartAudioWaveformWidgetState extends State<SmartAudioWaveformWidget> {
  bool _isInitialized = false;
  bool _hasWaveformData = false;
  StreamSubscription? _waveformDataSubscription;

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

  @override
  void dispose() {
    _waveformDataSubscription?.cancel();
    super.dispose();
  }

  void _checkInitialization() {
    setState(() {
      _isInitialized =
          widget.playerController.playerState == PlayerState.initialized ||
          widget.playerController.playerState == PlayerState.playing ||
          widget.playerController.playerState == PlayerState.paused;
    });

    // Escuchar datos del waveform
    _setupWaveformDataListener();

    // Intentar extraer waveform si está inicializado
    if (_isInitialized) {
      _tryExtractWaveform();
    }
  }

  void _tryExtractWaveform() async {
    // No necesitamos extraer manualmente si ya se está haciendo en preparePlayer
  }

  void _setupWaveformDataListener() {
    _waveformDataSubscription?.cancel();

    _waveformDataSubscription = widget
        .playerController
        .onCurrentExtractedWaveformData
        .listen((waveformData) {
          if (mounted && waveformData.isNotEmpty) {
            setState(() {
              _hasWaveformData = true;
            });
          }
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
        child: (_isInitialized && _hasWaveformData)
            ? _buildWaveform()
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildWaveform() {
    return AudioFileWaveforms(
      playerController: widget.playerController,
      size: Size.fromHeight(widget.height),
      waveformType: WaveformType.fitWidth,
      playerWaveStyle: PlayerWaveStyle(
        fixedWaveColor: widget.backgroundColor,
        liveWaveColor: widget.color,
        spacing: widget.spacing,
        showSeekLine: widget.showSeekLine,
        seekLineColor: widget.color,
        seekLineThickness: widget.seekLineThickness,
        waveThickness: widget.waveThickness,
        scaleFactor: widget.scaleFactor,
        waveCap: widget.waveCap,
        showTop: true,
        showBottom: true,
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
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(
                details.globalPosition,
              );
              final tapPosition = localPosition.dx / renderBox.size.width;
              _onWaveformTap(tapPosition.clamp(0.0, 1.0));
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
