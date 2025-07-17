import 'package:flutter/material.dart';

class AudioPlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final IconData playIcon;
  final IconData pauseIcon;
  final Color color;
  final Duration animationDuration;
  final AnimationController animationController;
  final VoidCallback onTogglePlayPause;

  const AudioPlayPauseButton({
    super.key,
    required this.isPlaying,
    this.isLoading = false,
    required this.playIcon,
    required this.pauseIcon,
    required this.color,
    required this.animationDuration,
    required this.animationController,
    required this.onTogglePlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => animationController.forward(),
      onTapUp: (_) => animationController.reverse(),
      onTapCancel: () => animationController.reverse(),
      onTap: onTogglePlayPause,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: animationDuration,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    key: const ValueKey('loading'),
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(
                  isPlaying ? pauseIcon : playIcon,
                  key: ValueKey(isPlaying),
                  color: color,
                  size: 24,
                ),
        ),
      ),
    );
  }
}
