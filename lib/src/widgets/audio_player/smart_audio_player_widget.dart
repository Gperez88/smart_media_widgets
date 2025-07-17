import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import '../../utils/cache_manager.dart';
import '../../utils/media_utils.dart';
import 'global_audio_player_manager.dart';
import 'smart_audio_player_content.dart';
import 'smart_audio_player_error.dart';
import 'smart_audio_player_placeholder.dart';

/// SmartAudioPlayerWidget
///
/// A smart widget for playing audio files (local or remote) with progress bar visualization,
/// preloading, robust error handling, and modern UI. Uses the audio_waveforms package.
///
/// - Supports local and remote audio sources.
/// - Allows cache configuration (global or per instance).
/// - Modern bubble-style UI with play/pause control and progress bar.
/// - Handles errors and provides a fallback visual.
///
/// See README for usage details.
class SmartAudioPlayerWidget extends StatefulWidget {
  /// The audio source (URL or local file path)
  final String audioSource;

  /// Width of the audio player card
  final double? width;

  /// Height of the audio player card
  final double? height;

  /// Border radius for the card
  final BorderRadius? borderRadius;

  /// Placeholder widget to show while loading
  final Widget? placeholder;

  /// Error widget to show when audio fails to load
  final Widget? errorWidget;

  /// Whether to show a loading indicator
  final bool showLoadingIndicator;

  /// Local cache configuration for this widget (overrides global config)
  final CacheConfig? localCacheConfig;

  /// Whether to use the global cache configuration
  final bool useGlobalConfig;

  /// Callback when audio loads successfully
  final VoidCallback? onAudioLoaded;

  /// Callback when audio fails to load
  final Function(String error)? onAudioError;

  /// Main color for the card and waveform (default: blue)
  final Color color;

  /// Icon for play button (default: Icons.play_arrow)
  final IconData playIcon;

  /// Icon for pause button (default: Icons.pause)
  final IconData pauseIcon;

  /// Animation duration for play/pause transitions
  final Duration animationDuration;

  /// Whether to show duration text
  final bool showDuration;

  /// Whether to show current position text
  final bool showPosition;

  /// Text style for duration and position text
  final TextStyle? timeTextStyle;

  /// Background color for the player (default: transparent)
  final Color? backgroundColor;

  /// Whether to use bubble-style design (default: true)
  final bool useBubbleStyle;

  /// Padding around the player content
  final EdgeInsetsGeometry? padding;

  /// Margin around the player
  final EdgeInsetsGeometry? margin;

  /// Whether to disable caching for this specific audio
  final bool disableCache;

  /// Optional widget to display at the left side of the player (e.g., avatar, icon)
  final Widget? leftWidget;

  /// Optional widget to display at the right side of the player (e.g., trailing icon, status)
  final Widget? rightWidget;

  /// Whether to use the global audio player (default: false)
  final bool enableGlobal;

  /// Optional title for the audio (shown in global player)
  final String? title;

  const SmartAudioPlayerWidget({
    super.key,
    required this.audioSource,
    this.width,
    this.height = 80,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = true,
    this.localCacheConfig,
    this.useGlobalConfig = true,
    this.onAudioLoaded,
    this.onAudioError,
    this.color = const Color(0xFF1976D2),
    this.playIcon = Icons.play_arrow,
    this.pauseIcon = Icons.pause,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showDuration = true,
    this.showPosition = true,
    this.timeTextStyle,
    this.backgroundColor,
    this.useBubbleStyle = true,
    this.padding,
    this.margin,
    this.disableCache = false,
    this.leftWidget,
    this.rightWidget,
    this.enableGlobal = false,
    this.title,
  });

  @override
  State<SmartAudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

/// Main widget state that handles business logic
class _AudioPlayerWidgetState extends State<SmartAudioPlayerWidget>
    with TickerProviderStateMixin {
  PlayerController? _playerController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Player state
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _audioPath;
  Duration _duration = const Duration(minutes: 3); // Default duration
  Duration _position = Duration.zero;

  // ID único para este player
  late final String _playerId;

  // Cache configuration management
  Function()? _restoreConfig;
  StreamSubscription? _durationSubscription;

  // Memory management
  bool _isDisposed = false;
  bool _isPreparing = false;

  /// Get or create PlayerController
  PlayerController get _effectivePlayerController {
    if (widget.enableGlobal) {
      return GlobalAudioPlayerManager.instance.effectivePlayerController;
    }
    return _playerController ??= PlayerController();
  }

  @override
  void initState() {
    super.initState();
    _playerId =
        '${widget.audioSource}_${DateTime.now().millisecondsSinceEpoch}';
    _initializeAnimations();
    _applyCacheConfig();
    _prepareAudio();
    _setupPlayerListeners();
  }

  @override
  void didUpdateWidget(SmartAudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleWidgetUpdates(oldWidget);
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (widget.enableGlobal) {
      GlobalAudioPlayerManager.instance.unregisterPlayer(_playerId);
    }
    _cleanup();
    super.dispose();
  }

  /// Initialize widget animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  /// Handle widget updates
  void _handleWidgetUpdates(SmartAudioPlayerWidget oldWidget) {
    if (_hasCacheConfigChanged(oldWidget)) {
      _restoreConfig?.call();
      _applyCacheConfig();
    }
    if (oldWidget.audioSource != widget.audioSource) {
      _prepareAudio();
    }
  }

  /// Check if cache configuration has changed
  bool _hasCacheConfigChanged(SmartAudioPlayerWidget oldWidget) {
    return oldWidget.localCacheConfig != widget.localCacheConfig ||
        oldWidget.useGlobalConfig != widget.useGlobalConfig;
  }

  /// Setup player listeners
  void _setupPlayerListeners() {
    if (widget.enableGlobal) {
      // Para reproductores globales, nos suscribimos a los cambios del manager global
      GlobalAudioPlayerManager.instance.registerCallbacks(
        playerId: _playerId,
        onPlay: () {
          if (mounted) setState(() => _isPlaying = true);
        },
        onPause: () {
          if (mounted) setState(() => _isPlaying = false);
        },
        onStop: () {
          if (mounted) setState(() => _isPlaying = false);
        },
        onPositionChanged: (position) {
          if (mounted) setState(() => _position = position);
        },
      );

      // Sincronizar estado inicial
      if (mounted) {
        final manager = GlobalAudioPlayerManager.instance;
        final isCurrentSource =
            manager.currentAudioSource.value == widget.audioSource;

        setState(() {
          _isPlaying = manager.isPlaying.value;
          _position = manager.position.value;
          _duration = manager.duration.value;

          // Si este audio ya está cargado en el manager global, salir del estado de loading
          if (isCurrentSource) {
            _isLoading = false;
            _hasError = false;
            _errorMessage = null;
          }
        });
      }
    } else {
      // Para reproductores locales, configuramos listeners para posición y duración
      _durationSubscription = _effectivePlayerController
          .onCurrentDurationChanged
          .listen((duration) {
            if (mounted && !_isDisposed) {
              setState(() {
                _position = Duration(milliseconds: duration);
              });
            }
          });

      // Configurar listener para cambios de estado del player
      _effectivePlayerController.onPlayerStateChanged.listen((state) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      // Obtener la duración inicial si está disponible
      _effectivePlayerController.getDuration().then((duration) {
        if (duration != null && mounted && !_isDisposed) {
          setState(() {
            _duration = Duration(milliseconds: duration);
          });
        }
      });
    }
  }

  /// Apply cache configuration
  void _applyCacheConfig() {
    if (!widget.useGlobalConfig && widget.localCacheConfig != null) {
      _restoreConfig = CacheManager.instance.applyTemporaryConfig(
        widget.localCacheConfig!,
      );
    } else if (widget.localCacheConfig != null) {
      final effectiveConfig = CacheManager.instance.getEffectiveConfig(
        widget.localCacheConfig,
      );
      _restoreConfig = CacheManager.instance.applyTemporaryConfig(
        effectiveConfig,
      );
    }
  }

  /// Prepare audio for playback
  Future<void> _prepareAudio() async {
    if (_isDisposed || _isPreparing) return;

    _isPreparing = true;
    _setLoadingState(true);

    try {
      final path = await _resolveAudioPath();
      if (_isDisposed) return;

      _audioPath = path;

      log('AudioPlayerWidget: Preparing player with path: $_audioPath');

      // Si es un reproductor global, delegamos en el manager global
      if (widget.enableGlobal) {
        final manager = GlobalAudioPlayerManager.instance;
        final isAudioActive = manager.isAudioActive(_playerId);

        log(
          'AudioPlayerWidget: Global player - isAudioActive: $isAudioActive, playerId: $_playerId',
        );

        // Si el audio ya está activo, solo sincronizar estado
        if (isAudioActive) {
          log('AudioPlayerWidget: Audio already active, syncing state');
          final audioInfo = manager.getAudioInfo(_playerId);
          if (audioInfo != null) {
            setState(() {
              _isPlaying = audioInfo.isPlaying.value;
              _position = audioInfo.position.value;
              _duration = audioInfo.duration.value;
              _isLoading = false;
              _hasError = false;
              _errorMessage = null;
            });
          }
          _isPreparing = false;
          return;
        }

        // Si no está activo, preparar el audio
        log('AudioPlayerWidget: Preparing audio in global manager');
        try {
          // Agregar timeout de 15 segundos para audios remotos
          await Future.any([
            manager.prepareAudio(
              _audioPath!,
              title: widget.title,
              playerId: _playerId,
              isGlobal: widget.enableGlobal,
              shouldExtractWaveform: false,
            ),
            Future.delayed(const Duration(seconds: 15)).then((_) {
              throw TimeoutException(
                'Audio preparation timeout',
                const Duration(seconds: 15),
              );
            }),
          ]);

          if (_isDisposed) return;

          // Verificar si el audio se cargó correctamente
          final finalIsAudioActive = manager.isAudioActive(_playerId);
          log(
            'AudioPlayerWidget: After preparation - finalIsAudioActive: $finalIsAudioActive',
          );

          if (finalIsAudioActive) {
            log(
              'AudioPlayerWidget: Audio prepared successfully, syncing state',
            );
            final audioInfo = manager.getAudioInfo(_playerId);
            if (audioInfo != null) {
              // Sincronizar estado con el manager global
              setState(() {
                _isPlaying = audioInfo.isPlaying.value;
                _position = audioInfo.position.value;
                _duration = audioInfo.duration.value;
                _isLoading = false;
                _hasError = false;
                _errorMessage = null;
              });
            }
          } else {
            log('AudioPlayerWidget: Audio preparation failed');
            _handleAudioError('Audio preparation failed');
          }
        } catch (e) {
          log('AudioPlayerWidget: Error preparing audio in global manager: $e');
          if (e is TimeoutException) {
            _handleAudioError(
              'Audio preparation timeout - the audio may be too large or the connection too slow',
            );
          } else {
            _handleAudioError('Failed to load audio: ${e.toString()}');
          }
        }
      } else {
        // Lógica original para reproductores locales
        await _effectivePlayerController.preparePlayer(
          path: _audioPath!,
          shouldExtractWaveform: false,
        );

        if (_isDisposed) return;

        // Configurar suscripción a duración y estado
        _durationSubscription?.cancel();
        _durationSubscription = _effectivePlayerController.onPlayerStateChanged
            .listen((state) {
              if (mounted && !_isDisposed) {
                setState(() {
                  _isPlaying = state == PlayerState.playing;
                });

                // Obtener duración cuando el player esté inicializado
                if (state == PlayerState.initialized) {
                  _effectivePlayerController
                      .getDuration()
                      .then((duration) {
                        if (duration != null && mounted && !_isDisposed) {
                          setState(() {
                            _duration = Duration(milliseconds: duration);
                          });
                          debugPrint(
                            'AudioPlayerWidget: Duration set to ${_duration.inSeconds} seconds',
                          );
                        }
                      })
                      .catchError((error) {
                        debugPrint(
                          'AudioPlayerWidget: Error getting duration: $error',
                        );
                      });
                }
              }
            });

        // Intentar obtener la duración inmediatamente si el player ya está inicializado
        _effectivePlayerController
            .getDuration()
            .then((duration) {
              if (duration != null && mounted && !_isDisposed) {
                setState(() {
                  _duration = Duration(milliseconds: duration);
                });
                debugPrint(
                  'AudioPlayerWidget: Initial duration set to ${_duration.inSeconds} seconds',
                );
              }
            })
            .catchError((error) {
              debugPrint(
                'AudioPlayerWidget: Error getting initial duration: $error',
              );
            });

        // Configurar listener de posición después de preparar el audio
        _effectivePlayerController.onCurrentDurationChanged.listen((duration) {
          if (mounted && !_isDisposed) {
            setState(() {
              _position = Duration(milliseconds: duration);
            });
            debugPrint(
              'AudioPlayerWidget: Position updated to ${_position.inSeconds} seconds, duration: ${_duration.inSeconds} seconds',
            );
          }
        });

        // Forzar la obtención de la duración después de preparar
        _updateDuration();

        setState(() {
          _isLoading = false;
          _hasError = false;
          _errorMessage = null;
        });
      }

      widget.onAudioLoaded?.call();
    } catch (e) {
      if (!_isDisposed) {
        await _handlePlayerError(e);
      }
    } finally {
      _isPreparing = false;
    }
  }

  /// Resolve audio path (local or remote)
  Future<String> _resolveAudioPath() async {
    debugPrint('AudioPlayerWidget: Resolving path for: ${widget.audioSource}');

    if (MediaUtils.isRemoteSource(widget.audioSource)) {
      debugPrint('AudioPlayerWidget: Detected remote source');

      // Check if already cached
      final cachedPath = await CacheManager.getCachedAudioPath(
        widget.audioSource,
      );

      if (cachedPath != null) {
        debugPrint('AudioPlayerWidget: Found cached path: $cachedPath');

        // Validate that the cached file still exists
        if (File(cachedPath).existsSync()) {
          debugPrint('AudioPlayerWidget: Using cached path: $cachedPath');
          return cachedPath;
        } else {
          debugPrint(
            'AudioPlayerWidget: Cached file no longer exists, falling back to remote URL',
          );
          // If cached file was deleted, fall back to remote URL
          return widget.audioSource;
        }
      } else {
        debugPrint(
          'AudioPlayerWidget: Using remote URL directly: ${widget.audioSource}',
        );
        // If not cached, use progressive streaming
        // The audio_waveforms package supports URLs directly
        return widget.audioSource;
      }
    } else if (MediaUtils.isLocalSource(widget.audioSource)) {
      debugPrint('AudioPlayerWidget: Detected local source');
      final path = MediaUtils.normalizeLocalPath(widget.audioSource);
      debugPrint('AudioPlayerWidget: Normalized local path: $path');

      if (!File(path).existsSync()) {
        throw Exception('Local audio file not found: $path');
      }
      return path;
    } else {
      debugPrint(
        'AudioPlayerWidget: Invalid source detected: ${widget.audioSource}',
      );
      throw Exception('Invalid audio source: ${widget.audioSource}');
    }
  }

  /// Download audio in background for future cache
  Future<void> _downloadAudioInBackground(String audioUrl) async {
    try {
      // Download without blocking the UI
      await CacheManager.cacheAudio(audioUrl);
    } catch (e) {
      // Ignore background download errors
      // Does not affect current playback
      debugPrint('Background audio download failed: $e');
    }
  }

  /// Handle audio errors
  void _handleAudioError(String error) {
    _hasError = true;
    _errorMessage = error;
    widget.onAudioError?.call(_errorMessage!);
    _setLoadingState(false);
  }

  /// Set loading state
  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) {
          _hasError = false;
          _errorMessage = null;
        }
      });
    }
  }

  /// Toggle between play and pause
  Future<void> _togglePlayPause() async {
    if (_isDisposed) return;

    try {
      if (widget.enableGlobal) {
        final manager = GlobalAudioPlayerManager.instance;

        // Si este player no es el activo, prepararlo primero
        if (manager.activePlayerId.value != _playerId) {
          await _prepareAudio();
          if (_isDisposed) return;
        }

        // Alternar reproducción
        if (_isPlaying) {
          await manager.pause(_playerId);
        } else {
          await manager.play(_playerId);
        }
      } else {
        // Lógica original para reproductores locales
        if (_isPlaying) {
          await _effectivePlayerController.pausePlayer();
          if (mounted && !_isDisposed) {
            setState(() => _isPlaying = false);
          }
        } else {
          await _effectivePlayerController.startPlayer();
          if (mounted && !_isDisposed) {
            setState(() => _isPlaying = true);
          }
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        await _handlePlayerError(e);
      }
    }
  }

  /// Clean up resources
  void _cleanup() {
    _restoreConfig?.call();
    _durationSubscription?.cancel();

    if (widget.enableGlobal) {
      // Eliminar callbacks del manager global
      GlobalAudioPlayerManager.instance.unregisterCallbacks(
        playerId: _playerId,
        onPlay: () {
          if (mounted) setState(() => _isPlaying = true);
        },
        onPause: () {
          if (mounted) setState(() => _isPlaying = false);
        },
        onStop: () {
          if (mounted) setState(() => _isPlaying = false);
        },
        onPositionChanged: (position) {
          if (mounted) setState(() => _position = position);
        },
      );
    } else {
      // Limpiar recursos del reproductor local
      if (_playerController != null) {
        try {
          _playerController!.dispose();
        } catch (e) {
          debugPrint(
            'AudioPlayerWidget: Error disposing player controller: $e',
          );
        }
        _playerController = null;
      }
    }

    _animationController.dispose();
  }

  /// Clear cached file reference if it no longer exists
  Future<void> _clearInvalidCacheReference() async {
    if (_audioPath != null &&
        MediaUtils.isRemoteSource(widget.audioSource) &&
        !MediaUtils.isRemoteSource(_audioPath!)) {
      // This is a cached file path, check if it still exists
      if (!File(_audioPath!).existsSync()) {
        debugPrint(
          'AudioPlayerWidget: Clearing invalid cache reference: $_audioPath',
        );
        _audioPath = null;
      }
    }
  }

  /// Update duration from player controller
  Future<void> _updateDuration() async {
    try {
      final duration = await _effectivePlayerController.getDuration();
      if (duration != null && mounted && !_isDisposed) {
        setState(() {
          _duration = Duration(milliseconds: duration);
        });
        debugPrint(
          'AudioPlayerWidget: Duration updated to ${_duration.inSeconds} seconds',
        );
      }
    } catch (e) {
      debugPrint('AudioPlayerWidget: Error updating duration: $e');
    }
  }

  /// Prepare player with timeout
  Future<void> _preparePlayerWithTimeout({required String path}) async {
    try {
      await _effectivePlayerController
          .preparePlayer(path: path, shouldExtractWaveform: false)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('AudioPlayerWidget: Player preparation timed out');
              throw TimeoutException(
                'Player preparation timeout',
                const Duration(seconds: 10),
              );
            },
          );
    } catch (e) {
      debugPrint('AudioPlayerWidget: Error during player preparation: $e');
      rethrow;
    }
  }

  /// Handle player errors and attempt recovery
  Future<void> _handlePlayerError(dynamic error) async {
    if (_isDisposed) return;

    debugPrint('AudioPlayerWidget: Player error: $error');

    // Check if it's a file not found error or platform exception with source error
    final errorString = error.toString();
    if (errorString.contains('FileNotFoundException') ||
        errorString.contains('ENOENT') ||
        errorString.contains('No such file or directory') ||
        (errorString.contains('PlatformException') &&
            errorString.contains('Source error') &&
            errorString.contains('Unable to load media source'))) {
      debugPrint(
        'AudioPlayerWidget: Detected file not found or source error, attempting recovery',
      );

      // Clear invalid cache reference
      await _clearInvalidCacheReference();

      // Try to re-prepare the audio
      try {
        await _prepareAudio();
        return; // Success, exit early
      } catch (e) {
        debugPrint('AudioPlayerWidget: Recovery failed: $e');
      }
    }

    // If recovery failed or it's a different error, handle normally
    if (!_isDisposed) {
      _handleAudioError(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Identical build logic for both global and local players
    if (_isLoading) {
      return AudioPlayerPlaceholder(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        borderRadius: widget.borderRadius,
        backgroundColor: widget.backgroundColor,
        color: widget.color,
        placeholder: widget.placeholder,
        showLoadingIndicator: widget.showLoadingIndicator,
      );
    }

    if (_hasError) {
      return AudioPlayerError(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        borderRadius: widget.borderRadius,
        backgroundColor: widget.backgroundColor,
        errorWidget: widget.errorWidget,
        errorMessage: _errorMessage,
      );
    }

    // Both global and local players show content the same way
    return AudioPlayerContent(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      borderRadius: widget.borderRadius,
      backgroundColor: widget.backgroundColor,
      color: widget.color,
      useBubbleStyle: widget.useBubbleStyle,
      padding: widget.padding,
      isPlaying: _isPlaying,
      position: _position,
      duration: _duration,
      playIcon: widget.playIcon,
      pauseIcon: widget.pauseIcon,
      animationDuration: widget.animationDuration,
      animationController: _animationController,
      scaleAnimation: _scaleAnimation,
      showDuration: widget.showDuration,
      showPosition: widget.showPosition,
      timeTextStyle: widget.timeTextStyle,
      onTogglePlayPause: _togglePlayPause,
      leftWidget: widget.leftWidget,
      rightWidget: widget.rightWidget,
    );
  }
}
