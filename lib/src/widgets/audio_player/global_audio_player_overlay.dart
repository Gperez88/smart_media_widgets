import 'package:flutter/material.dart';

import 'global_audio_player_manager.dart';
import 'smart_audio_play_pause_button.dart';
import 'smart_audio_time_display.dart';

/// GlobalAudioPlayerOverlay
///
/// Widget que muestra un reproductor de audio flotante similar al de Telegram.
/// Se muestra cuando hay un audio global (enableGlobal=true) reproduciéndose
/// y permite controlar la reproducción desde cualquier parte de la app.
///
/// Solo muestra audios con isGlobal=true. Los audios globales tienen exclusividad:
/// cuando se reproduce uno, todos los otros audios globales se pausan automáticamente.
class GlobalAudioPlayerOverlay extends StatefulWidget {
  const GlobalAudioPlayerOverlay({super.key});

  @override
  State<GlobalAudioPlayerOverlay> createState() =>
      _GlobalAudioPlayerOverlayState();
}

class _GlobalAudioPlayerOverlayState extends State<GlobalAudioPlayerOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _overlayAnimationController;
  late final AnimationController _playPauseAnimationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // Variables para el audio activo actual
  String? _currentPlayerId;
  GlobalAudioInfo? _currentAudioInfo;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
    _updateCurrentAudio();
  }

  void _initializeAnimations() {
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _playPauseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _overlayAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Mostrar animación inicial solo si hay un audio activo y está reproduciéndose
    if (_currentAudioInfo != null && _currentAudioInfo!.isPlaying.value) {
      _overlayAnimationController.forward();
    }
  }

  void _setupListeners() {
    // Escuchar cambios en la lista de audios activos
    GlobalAudioPlayerManager.instance.activeAudiosStream.listen((audios) {
      _updateCurrentAudio();
    });
  }

  void _updateCurrentAudio() {
    final audios = GlobalAudioPlayerManager.instance.activeAudios;

    // Buscar el primer audio global que esté reproduciéndose
    GlobalAudioInfo? playingAudio;
    for (final audio in audios) {
      if (audio.isGlobal && audio.isPlaying.value) {
        playingAudio = audio;
        break;
      }
    }

    // Si no hay audio global reproduciéndose, usar el último audio global de la lista
    if (playingAudio == null) {
      for (final audio in audios.reversed) {
        if (audio.isGlobal) {
          playingAudio = audio;
          break;
        }
      }
    }

    if (playingAudio != null && playingAudio!.playerId != _currentPlayerId) {
      setState(() {
        _currentPlayerId = playingAudio!.playerId;
        _currentAudioInfo = playingAudio;
      });

      // Configurar listeners para el audio actual
      _setupAudioListeners();
    } else if (playingAudio == null && _currentAudioInfo != null) {
      setState(() {
        _currentPlayerId = null;
        _currentAudioInfo = null;
      });
    }

    _handleStateChange();
  }

  void _setupAudioListeners() {
    if (_currentAudioInfo != null) {
      _currentAudioInfo!.isPlaying.addListener(_handleStateChange);
    }
  }

  void _handleStateChange() {
    final hasAudio = _currentAudioInfo != null;
    final isPlaying = _currentAudioInfo?.isPlaying.value ?? false;

    if (hasAudio && isPlaying) {
      _overlayAnimationController.forward();
    } else {
      _overlayAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    if (_currentAudioInfo != null) {
      _currentAudioInfo!.isPlaying.removeListener(_handleStateChange);
    }
    _overlayAnimationController.dispose();
    _playPauseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 8,
          child: Container(
            height: 60,
            color: Theme.of(context).primaryColor,
            child: _currentAudioInfo == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      const SizedBox(width: 16),
                      _buildPlayPauseButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitle(),
                            const SizedBox(height: 4),
                            _buildProgressSection(),
                          ],
                        ),
                      ),
                      _buildCloseButton(),
                      const SizedBox(width: 16),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    if (_currentAudioInfo == null) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: _currentAudioInfo!.isPlaying,
      builder: (context, isPlaying, child) {
        return AudioPlayPauseButton(
          isPlaying: isPlaying,
          playIcon: Icons.play_arrow,
          pauseIcon: Icons.pause,
          color: Theme.of(context).primaryColor,
          animationDuration: const Duration(milliseconds: 300),
          animationController: _playPauseAnimationController,
          onTogglePlayPause: () {
            if (isPlaying) {
              GlobalAudioPlayerManager.instance.pause(_currentPlayerId!);
            } else {
              GlobalAudioPlayerManager.instance.play(_currentPlayerId!);
            }
          },
        );
      },
    );
  }

  Widget _buildTitle() {
    if (_currentAudioInfo == null) return const SizedBox.shrink();

    return Text(
      _currentAudioInfo!.title ?? 'Audio',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressSection() {
    if (_currentAudioInfo == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(child: _buildProgressBar()),
        const SizedBox(width: 8),
        _buildTimeDisplay(),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (_currentAudioInfo == null) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: _currentAudioInfo!.isPlaying,
      builder: (context, isPlaying, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: _currentAudioInfo!.position,
          builder: (context, position, child) {
            return ValueListenableBuilder<Duration>(
              valueListenable: _currentAudioInfo!.duration,
              builder: (context, duration, child) {
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                      minHeight: 2,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDisplay() {
    if (_currentAudioInfo == null) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: _currentAudioInfo!.isPlaying,
      builder: (context, isPlaying, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: _currentAudioInfo!.position,
          builder: (context, position, child) {
            return ValueListenableBuilder<Duration>(
              valueListenable: _currentAudioInfo!.duration,
              builder: (context, duration, child) {
                return AudioTimeDisplay(
                  isPlaying: isPlaying,
                  position: position,
                  duration: duration,
                  timeTextStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () async {
        if (_currentPlayerId != null) {
          await GlobalAudioPlayerManager.instance.stop(_currentPlayerId!);
        }
      },
      splashRadius: 24,
    );
  }
}
