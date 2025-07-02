import 'package:flutter/material.dart';

import 'global_audio_player_manager.dart';

/// Global audio player overlay that appears below the AppBar
///
/// This widget provides a persistent audio player interface that remains
/// visible across different screens when global playback is active.
/// Features a minimal, WhatsApp-style design.
class GlobalAudioPlayerOverlay extends StatefulWidget {
  /// Height of the global player overlay
  final double height;

  /// Background color of the overlay
  final Color? backgroundColor;

  /// Border radius for the overlay
  final BorderRadius? borderRadius;

  /// Whether to show a close button
  final bool showCloseButton;

  /// Custom close icon
  final IconData closeIcon;

  /// Animation duration for show/hide transitions
  final Duration animationDuration;

  /// Whether to show playback speed button
  final bool showSpeedButton;

  /// Custom subtitle text to display above the time information.
  /// If null, defaults to "You yesterday at [current time]"
  final String? subtitleText;

  const GlobalAudioPlayerOverlay({
    super.key,
    this.height = 56,
    this.backgroundColor,
    this.borderRadius,
    this.showCloseButton = true,
    this.closeIcon = Icons.close,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showSpeedButton = true,
    this.subtitleText,
  });

  @override
  State<GlobalAudioPlayerOverlay> createState() =>
      _GlobalAudioPlayerOverlayState();
}

class _GlobalAudioPlayerOverlayState extends State<GlobalAudioPlayerOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  GlobalAudioPlayerState? _currentState;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenToGlobalPlayer();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Initialize animations
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  /// Listen to global player state changes
  void _listenToGlobalPlayer() {
    GlobalAudioPlayerManager.instance.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });

        // Show/hide overlay based on state
        if (state != null && state.errorMessage == null) {
          _slideController.forward();
        } else {
          _slideController.reverse();
        }
      }
    });
  }

  /// Handle play/pause button press
  Future<void> _onPlayPause() async {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    await GlobalAudioPlayerManager.instance.togglePlayPause();
  }

  /// Handle close button press
  Future<void> _onClose() async {
    await GlobalAudioPlayerManager.instance.stopGlobalPlayback();
  }

  /// Get effective background color
  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? const Color(0xFF2E2E2E) : const Color(0xFF4A4A4A);
  }

  /// Build main content - simplified text-based display
  Widget _buildMainContent() {
    if (_currentState == null) return const SizedBox.shrink();

    // Show loading indicator while audio is loading
    if (_currentState!.isLoading) {
      return const Expanded(
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subtitleText ?? 'Subtitle',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                _formatPosition(_currentState!.position),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const Text(
                ' / ',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                _formatPosition(_currentState!.duration),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format duration
  String _formatPosition(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Build play/pause button - simplified
  Widget _buildPlayPauseButton() {
    if (_currentState == null) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: _onPlayPause,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: _currentState!.isLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
              : Icon(
                  _currentState!.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black87,
                  size: 14,
                ),
        ),
      ),
    );
  }

  /// Build speed button
  Widget _buildSpeedButton() {
    if (!widget.showSpeedButton) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _toggleSpeed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          '${_playbackSpeed}X',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Toggle playback speed
  void _toggleSpeed() {
    setState(() {
      switch (_playbackSpeed) {
        case 1.0:
          _playbackSpeed = 1.5;
          break;
        case 1.5:
          _playbackSpeed = 2.0;
          break;
        case 2.0:
          _playbackSpeed = 1.0;
          break;
        default:
          _playbackSpeed = 1.0;
      }
    });

    // TODO: Implement actual speed change in player controller
    // This would require extending the GlobalAudioPlayerManager
  }

  /// Build close button - simplified
  Widget _buildCloseButton() {
    if (!widget.showCloseButton) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _onClose,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Icon(widget.closeIcon, size: 16, color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if no active global player
    if (_currentState == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildPlayPauseButton(),
              const SizedBox(width: 12),
              _buildMainContent(),
              const SizedBox(width: 12),
              _buildSpeedButton(),
              const SizedBox(width: 8),
              _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }
}
