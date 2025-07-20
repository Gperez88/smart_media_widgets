import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// Configuración para timeouts y reintentos de red
class NetworkConfig {
  /// Timeout base en segundos
  final int baseTimeoutSeconds;
  
  /// Timeout adicional por MB de archivo estimado
  final int timeoutPerMBSeconds;
  
  /// Número máximo de reintentos
  final int maxRetries;
  
  /// Factor de backoff exponencial
  final double backoffFactor;
  
  /// Delay inicial en milisegundos para el primer reintento
  final int initialDelayMs;
  
  /// Timeout máximo absoluto en segundos
  final int maxTimeoutSeconds;
  
  /// Detectar cambios de conectividad
  final bool enableConnectivityDetection;

  const NetworkConfig({
    this.baseTimeoutSeconds = 10,
    this.timeoutPerMBSeconds = 5,
    this.maxRetries = 3,
    this.backoffFactor = 2.0,
    this.initialDelayMs = 1000,
    this.maxTimeoutSeconds = 60,
    this.enableConnectivityDetection = true,
  });

  /// Calcula timeout basado en tamaño estimado de archivo
  Duration calculateTimeout({int? estimatedSizeMB}) {
    final baseDuration = Duration(seconds: baseTimeoutSeconds);
    if (estimatedSizeMB == null || estimatedSizeMB <= 0) {
      return baseDuration;
    }
    
    final additionalSeconds = (estimatedSizeMB * timeoutPerMBSeconds);
    final totalSeconds = math.min(baseTimeoutSeconds + additionalSeconds, maxTimeoutSeconds);
    
    return Duration(seconds: totalSeconds);
  }
  
  /// Calcula delay para reintento con backoff exponencial
  Duration calculateRetryDelay(int attemptNumber) {
    final delay = initialDelayMs * math.pow(backoffFactor, attemptNumber - 1);
    return Duration(milliseconds: delay.round());
  }

  @override
  String toString() {
    return 'NetworkConfig(baseTimeout: ${baseTimeoutSeconds}s, maxRetries: $maxRetries, backoffFactor: $backoffFactor)';
  }
}

/// Información de un audio global activo
class GlobalAudioInfo {
  final String audioSource;
  final String playerId;
  final String? title;
  final PlayerController playerController;
  final ValueNotifier<bool> isPlaying;
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueNotifier<List<double>?> waveformData;
  final StreamSubscription? positionSubscription;
  final StreamSubscription? waveformSubscription;
  final bool isGlobal;

  GlobalAudioInfo({
    required this.audioSource,
    required this.playerId,
    this.title,
    required this.playerController,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.waveformData,
    this.positionSubscription,
    this.waveformSubscription,
    this.isGlobal = true,
  });

  void dispose() {
    // Cancelar subscripciones de manera segura
    try {
      positionSubscription?.cancel();
    } catch (e) {
      log('GlobalAudioInfo: Error canceling position subscription for $playerId: $e');
    }
    
    try {
      waveformSubscription?.cancel();
    } catch (e) {
      log('GlobalAudioInfo: Error canceling waveform subscription for $playerId: $e');
    }
    
    // Dispose del player controller de manera segura
    try {
      playerController.dispose();
    } catch (e) {
      log('GlobalAudioInfo: Error disposing player controller for $playerId: $e');
    }
  }
}

/// GlobalAudioPlayerManager
///
/// Singleton que maneja múltiples audios globales con exclusividad.
/// Los audios con isGlobal=true no pueden reproducirse simultáneamente.
/// Cuando se reproduce un audio global, todos los otros audios globales se pausan automáticamente.
class GlobalAudioPlayerManager {
  static final GlobalAudioPlayerManager _instance =
      GlobalAudioPlayerManager._();
  static GlobalAudioPlayerManager get instance => _instance;

  GlobalAudioPlayerManager._();

  // Mutex para operaciones críticas
  final Map<String, Completer<void>> _preparingAudios = {};
  final Map<String, bool> _operationLocks = {};
  
  // Mutex para sincronización de callbacks
  final Map<String, bool> _callbackLocks = {};

  // Límites para callbacks (prevenir acumulación excesiva en apps de chat)
  static const int _maxCallbacksPerPlayer = 10;

  // Timer para limpieza automática de callbacks huérfanos
  Timer? _cleanupTimer;

  // Configuración de red y timeouts
  NetworkConfig _networkConfig = const NetworkConfig();

  // Estado de conectividad estimado
  bool _isConnected = true;
  DateTime? _lastNetworkError;
  int _consecutiveNetworkErrors = 0;

  // Mapa de audios activos por playerId
  final Map<String, GlobalAudioInfo> _activeAudios = {};

  // Stream para notificar cambios en la lista de audios activos
  final StreamController<List<GlobalAudioInfo>> _activeAudiosController =
      StreamController<List<GlobalAudioInfo>>.broadcast();

  // Callbacks para sincronización
  final Map<String, List<VoidCallback>> _onPlayCallbacks = {};
  final Map<String, List<VoidCallback>> _onPauseCallbacks = {};
  final Map<String, List<VoidCallback>> _onStopCallbacks = {};
  final Map<String, List<Function(Duration)>> _onPositionChangedCallbacks = {};
  final Map<String, List<Function(List<double>)>> _onWaveformDataCallbacks = {};

  /// Stream público para escuchar cambios en audios activos
  Stream<List<GlobalAudioInfo>> get activeAudiosStream =>
      _activeAudiosController.stream;

  /// Lista de audios activos
  List<GlobalAudioInfo> get activeAudios => _activeAudios.values.toList();

  /// Obtiene información de un audio específico
  GlobalAudioInfo? getAudioInfo(String playerId) {
    // No devolver información si el audio está en preparación
    if (isAudioPreparing(playerId)) {
      return null;
    }
    return _activeAudios[playerId];
  }

  /// Verifica si un audio está activo
  bool isAudioActive(String playerId) {
    return _activeAudios.containsKey(playerId);
  }

  /// Verifica si un audio está en proceso de preparación
  bool isAudioPreparing(String playerId) {
    return _preparingAudios.containsKey(playerId);
  }

  /// Actualiza la configuración de red
  void updateNetworkConfig(NetworkConfig config) {
    _networkConfig = config;
    log('GlobalAudioPlayerManager: Updated network config: $config');
  }

  /// Obtiene la configuración de red actual
  NetworkConfig get networkConfig => _networkConfig;

  /// Indica si hay conectividad estimada
  bool get isConnected => _isConnected;

  /// Número de errores de red consecutivos
  int get consecutiveNetworkErrors => _consecutiveNetworkErrors;

  /// Última vez que se detectó un error de red
  DateTime? get lastNetworkError => _lastNetworkError;

  /// Registra un error de red para actualizar estado de conectividad
  void _recordNetworkError(dynamic error) {
    if (!_networkConfig.enableConnectivityDetection) return;

    _lastNetworkError = DateTime.now();
    _consecutiveNetworkErrors++;
    
    // Considerar desconectado después de 3 errores consecutivos
    if (_consecutiveNetworkErrors >= 3) {
      _isConnected = false;
      log('GlobalAudioPlayerManager: Network connectivity lost ($_consecutiveNetworkErrors consecutive errors)');
    }
    
    log('GlobalAudioPlayerManager: Network error recorded: $error (consecutive: $_consecutiveNetworkErrors)');
    
    // Adaptar configuración automáticamente
    adaptNetworkConfig();
  }

  /// Registra recuperación de conectividad
  void _recordNetworkRecovery() {
    if (!_networkConfig.enableConnectivityDetection) return;

    if (!_isConnected || _consecutiveNetworkErrors > 0) {
      _isConnected = true;
      _consecutiveNetworkErrors = 0;
      _lastNetworkError = null;
      log('GlobalAudioPlayerManager: Network connectivity recovered');
      
      // Adaptar configuración automáticamente tras recuperación
      adaptNetworkConfig();
    }
  }

  /// Verifica si un error es relacionado con red
  bool _isNetworkError(dynamic error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable') ||
           errorString.contains('dns');
  }

  /// Adapta automáticamente la configuración de red basada en condiciones actuales
  void adaptNetworkConfig() {
    if (!_networkConfig.enableConnectivityDetection) return;

    final now = DateTime.now();
    final hasRecentErrors = _lastNetworkError != null && 
                           now.difference(_lastNetworkError!).inMinutes < 5;

    NetworkConfig newConfig;

    if (!_isConnected || _consecutiveNetworkErrors >= 3) {
      // Red inestable: configuración conservadora
      newConfig = NetworkConfig(
        baseTimeoutSeconds: _networkConfig.baseTimeoutSeconds * 2,
        timeoutPerMBSeconds: _networkConfig.timeoutPerMBSeconds * 2,
        maxRetries: math.max(_networkConfig.maxRetries, 5),
        backoffFactor: math.max(_networkConfig.backoffFactor, 3.0),
        initialDelayMs: _networkConfig.initialDelayMs * 2,
        maxTimeoutSeconds: math.min(_networkConfig.maxTimeoutSeconds * 2, 120),
        enableConnectivityDetection: _networkConfig.enableConnectivityDetection,
      );
      log('GlobalAudioPlayerManager: Adapted to unstable network configuration');
      
    } else if (hasRecentErrors) {
      // Red con errores recientes: configuración intermedia
      newConfig = NetworkConfig(
        baseTimeoutSeconds: (_networkConfig.baseTimeoutSeconds * 1.5).round(),
        timeoutPerMBSeconds: (_networkConfig.timeoutPerMBSeconds * 1.5).round(),
        maxRetries: math.max(_networkConfig.maxRetries, 4),
        backoffFactor: math.max(_networkConfig.backoffFactor, 2.5),
        initialDelayMs: (_networkConfig.initialDelayMs * 1.5).round(),
        maxTimeoutSeconds: _networkConfig.maxTimeoutSeconds,
        enableConnectivityDetection: _networkConfig.enableConnectivityDetection,
      );
      log('GlobalAudioPlayerManager: Adapted to moderate network conditions');
      
    } else {
      // Red estable: usar configuración original o optimizada
      const baseConfig = NetworkConfig();
      newConfig = NetworkConfig(
        baseTimeoutSeconds: math.min(_networkConfig.baseTimeoutSeconds, baseConfig.baseTimeoutSeconds),
        timeoutPerMBSeconds: math.min(_networkConfig.timeoutPerMBSeconds, baseConfig.timeoutPerMBSeconds),
        maxRetries: math.min(_networkConfig.maxRetries, baseConfig.maxRetries),
        backoffFactor: math.min(_networkConfig.backoffFactor, baseConfig.backoffFactor),
        initialDelayMs: math.min(_networkConfig.initialDelayMs, baseConfig.initialDelayMs),
        maxTimeoutSeconds: _networkConfig.maxTimeoutSeconds,
        enableConnectivityDetection: _networkConfig.enableConnectivityDetection,
      );
      log('GlobalAudioPlayerManager: Adapted to stable network configuration');
    }

    if (newConfig.toString() != _networkConfig.toString()) {
      _networkConfig = newConfig;
      log('GlobalAudioPlayerManager: Network config adapted: $newConfig');
    }
  }

  /// Obtiene estadísticas de red para monitoreo
  Map<String, dynamic> getNetworkStats() {
    final now = DateTime.now();
    final minutesSinceLastError = _lastNetworkError != null 
        ? now.difference(_lastNetworkError!).inMinutes 
        : null;

    return {
      'isConnected': _isConnected,
      'consecutiveNetworkErrors': _consecutiveNetworkErrors,
      'lastNetworkError': _lastNetworkError?.toIso8601String(),
      'minutesSinceLastError': minutesSinceLastError,
      'currentConfig': _networkConfig.toString(),
    };
  }

  /// Adquiere un lock para operaciones críticas
  Future<void> _acquireOperationLock(String playerId) async {
    // Esperar si ya hay una operación en progreso
    if (_preparingAudios.containsKey(playerId)) {
      await _preparingAudios[playerId]!.future;
    }

    // Marcar como en preparación
    _preparingAudios[playerId] = Completer<void>();
    _operationLocks[playerId] = true;
  }

  /// Libera un lock para operaciones críticas
  void _releaseOperationLock(String playerId) {
    final completer = _preparingAudios.remove(playerId);
    _operationLocks.remove(playerId);
    
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// Ejecuta callbacks de manera segura
  void _safeExecuteCallbacks(String playerId, List<VoidCallback>? callbacks) {
    if (callbacks == null || callbacks.isEmpty) return;
    
    // Evitar ejecución concurrente de callbacks para el mismo playerId
    if (_callbackLocks[playerId] == true) {
      log('GlobalAudioPlayerManager: Skipping callback execution, already in progress for: $playerId');
      return;
    }
    
    _callbackLocks[playerId] = true;
    try {
      for (final callback in List.from(callbacks)) {
        try {
          callback();
        } catch (e) {
          log('GlobalAudioPlayerManager: Error executing callback for $playerId: $e');
        }
      }
    } finally {
      _callbackLocks.remove(playerId);
    }
  }

  /// Ejecuta callbacks con parámetros de manera segura
  void _safeExecuteParameterCallbacks<T>(String playerId, List<Function(T)>? callbacks, T parameter) {
    if (callbacks == null || callbacks.isEmpty) return;
    
    // Evitar ejecución concurrente de callbacks para el mismo playerId
    if (_callbackLocks[playerId] == true) {
      log('GlobalAudioPlayerManager: Skipping parameter callback execution, already in progress for: $playerId');
      return;
    }
    
    _callbackLocks[playerId] = true;
    try {
      for (final callback in List.from(callbacks)) {
        try {
          callback(parameter);
        } catch (e) {
          log('GlobalAudioPlayerManager: Error executing parameter callback for $playerId: $e');
        }
      }
    } finally {
      _callbackLocks.remove(playerId);
    }
  }

  /// Agrega un callback a una lista con límite máximo
  void _addCallbackWithLimit<T>(Map<String, List<T>> callbackMap, String playerId, T callback) {
    callbackMap[playerId] ??= [];
    final callbacks = callbackMap[playerId]!;
    
    // Si se alcanza el límite, remover el más antiguo
    if (callbacks.length >= _maxCallbacksPerPlayer) {
      callbacks.removeAt(0);
      log('GlobalAudioPlayerManager: Callback limit reached for $playerId, removing oldest callback');
    }
    
    callbacks.add(callback);
  }

  /// Obtiene estadísticas de callbacks para un playerId
  Map<String, int> getCallbackStats(String playerId) {
    return {
      'onPlay': _onPlayCallbacks[playerId]?.length ?? 0,
      'onPause': _onPauseCallbacks[playerId]?.length ?? 0,
      'onStop': _onStopCallbacks[playerId]?.length ?? 0,
      'onPositionChanged': _onPositionChangedCallbacks[playerId]?.length ?? 0,
      'onWaveformData': _onWaveformDataCallbacks[playerId]?.length ?? 0,
    };
  }

  /// Limpia callbacks huérfanos (para playerIds que ya no existen)
  void _cleanupOrphanedCallbacks() {
    final activePlayerIds = Set.from(_activeAudios.keys);
    final preparingPlayerIds = Set.from(_preparingAudios.keys);
    final allValidPlayerIds = activePlayerIds.union(preparingPlayerIds);

    // Limpiar callbacks para playerIds que ya no están activos ni preparándose
    _onPlayCallbacks.removeWhere((playerId, _) => !allValidPlayerIds.contains(playerId));
    _onPauseCallbacks.removeWhere((playerId, _) => !allValidPlayerIds.contains(playerId));
    _onStopCallbacks.removeWhere((playerId, _) => !allValidPlayerIds.contains(playerId));
    _onPositionChangedCallbacks.removeWhere((playerId, _) => !allValidPlayerIds.contains(playerId));
    _onWaveformDataCallbacks.removeWhere((playerId, _) => !allValidPlayerIds.contains(playerId));
    _callbackLocks.removeWhere((playerId, _) => !allValidPlayerIds.contains(playerId));

    log('GlobalAudioPlayerManager: Cleaned up orphaned callbacks. Active players: ${activePlayerIds.length}, Preparing: ${preparingPlayerIds.length}');
  }

  /// Ejecuta limpieza automática de callbacks huérfanos periódicamente
  void _scheduleOrphanedCallbackCleanup() {
    // Solo crear un timer si no existe uno
    if (_cleanupTimer?.isActive != true) {
      _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _cleanupOrphanedCallbacks();
        
        // Si no hay audios activos ni preparándose, cancelar el timer
        if (_activeAudios.isEmpty && _preparingAudios.isEmpty) {
          timer.cancel();
          _cleanupTimer = null;
          log('GlobalAudioPlayerManager: Canceled orphaned callback cleanup timer');
        }
      });
      log('GlobalAudioPlayerManager: Started orphaned callback cleanup timer');
    }
  }

  /// Prepara un PlayerController con reintentos y timeout adaptativo
  Future<void> _preparePlayerWithRetries({
    required PlayerController playerController,
    required String audioSource,
    required bool shouldExtractWaveform,
    int? estimatedSizeMB,
  }) async {
    final timeout = _networkConfig.calculateTimeout(estimatedSizeMB: estimatedSizeMB);
    
    for (int attempt = 1; attempt <= _networkConfig.maxRetries + 1; attempt++) {
      try {
        log('GlobalAudioPlayerManager: Preparing audio attempt $attempt/${_networkConfig.maxRetries + 1} for: $audioSource (timeout: ${timeout.inSeconds}s)');
        
        await playerController
            .preparePlayer(
              path: audioSource,
              shouldExtractWaveform: shouldExtractWaveform,
            )
            .timeout(
              timeout,
              onTimeout: () {
                throw TimeoutException(
                  'Audio preparation timeout after ${timeout.inSeconds}s',
                  timeout,
                );
              },
            );
        
        // Si llegamos aquí, la preparación fue exitosa
        log('GlobalAudioPlayerManager: Audio prepared successfully on attempt $attempt for: $audioSource');
        _recordNetworkRecovery();
        return;
        
      } catch (e) {
        final isLastAttempt = attempt > _networkConfig.maxRetries;
        final isNetworkRelated = _isNetworkError(e);
        
        if (isNetworkRelated) {
          _recordNetworkError(e);
        }
        
        if (isLastAttempt) {
          log('GlobalAudioPlayerManager: All attempts failed for: $audioSource. Last error: $e');
          rethrow;
        }
        
        // Calcular delay para el siguiente intento
        final delay = _networkConfig.calculateRetryDelay(attempt);
        
        // Si hay problemas de conectividad, usar delay más largo
        final adjustedDelay = isNetworkRelated && !_isConnected 
            ? Duration(milliseconds: (delay.inMilliseconds * 2).round())
            : delay;
            
        log('GlobalAudioPlayerManager: Attempt $attempt failed for: $audioSource. Retrying in ${adjustedDelay.inMilliseconds}ms. Error: $e');
        
        // Esperar antes del siguiente intento
        await Future.delayed(adjustedDelay);
      }
    }
  }

  /// Prepara un nuevo audio para reproducción
  Future<void> prepareAudio(
    String audioSource, {
    String? title,
    required String playerId,
    bool shouldExtractWaveform = true,
    bool isGlobal = true,
  }) async {
    log(
      'GlobalAudioPlayerManager: prepareAudio called - audioSource: $audioSource, playerId: $playerId',
    );

    // Adquirir lock para operaciones críticas
    await _acquireOperationLock(playerId);

    try {
      // Si ya existe este audio, verificar si está listo
      if (_activeAudios.containsKey(playerId)) {
        log(
          'GlobalAudioPlayerManager: Audio already exists for playerId: $playerId',
        );

        final existingAudio = _activeAudios[playerId]!;

        // Si el audio source es diferente, reemplazar el audio existente
        if (existingAudio.audioSource != audioSource) {
          log(
            'GlobalAudioPlayerManager: Audio source changed, replacing existing audio for playerId: $playerId',
          );
          await stop(playerId);
        } else {
          // El audio ya existe y tiene la misma fuente, no hacer nada
          log(
            'GlobalAudioPlayerManager: Audio already prepared with same source for playerId: $playerId',
          );
          return;
        }
      }

      log(
        'GlobalAudioPlayerManager: Creating new player controller for: $audioSource',
      );

      // Crear un nuevo controlador para este audio
      final playerController = PlayerController();
      StreamSubscription? positionSubscription;
      StreamSubscription? waveformSubscription;

      try {
        // Preparar el audio con reintentos y timeout adaptativo
        await _preparePlayerWithRetries(
          playerController: playerController,
          audioSource: audioSource,
          shouldExtractWaveform: shouldExtractWaveform,
          estimatedSizeMB: null, // TODO: Implementar estimación de tamaño
        );

        // Crear notifiers para este audio
        final isPlaying = ValueNotifier<bool>(false);
        final position = ValueNotifier<Duration>(Duration.zero);
        final duration = ValueNotifier<Duration>(const Duration(minutes: 3));
        final waveformData = ValueNotifier<List<double>?>(null);

        // Obtener la duración real del audio
        try {
          final actualDuration = await playerController.getDuration();
          if (actualDuration > 0) {
            duration.value = Duration(milliseconds: actualDuration);
          }
        } catch (e) {
          log('GlobalAudioPlayerManager: Error getting duration: $e');
        }

        // Configurar listeners
        positionSubscription = playerController.onCurrentDurationChanged
            .listen((durationInMillis) {
              final newPosition = Duration(milliseconds: durationInMillis);
              position.value = newPosition;

              // Notificar callbacks
              _safeExecuteParameterCallbacks(playerId, _onPositionChangedCallbacks[playerId], newPosition);
            });

        if (shouldExtractWaveform) {
          waveformSubscription = playerController.onCurrentExtractedWaveformData
              .listen((data) {
                waveformData.value = data;

                // Notificar callbacks
                _safeExecuteParameterCallbacks(playerId, _onWaveformDataCallbacks[playerId], data);
              });
        }

        // Crear la información del audio
        final audioInfo = GlobalAudioInfo(
          audioSource: audioSource,
          playerId: playerId,
          title: title,
          playerController: playerController,
          isPlaying: isPlaying,
          position: position,
          duration: duration,
          waveformData: waveformData,
          positionSubscription: positionSubscription,
          waveformSubscription: waveformSubscription,
          isGlobal: isGlobal,
        );

        // Agregar a la lista de audios activos
        _activeAudios[playerId] = audioInfo;

        // Notificar cambio en la lista
        _activeAudiosController.add(_activeAudios.values.toList());

        log(
          'GlobalAudioPlayerManager: Audio prepared successfully for playerId: $playerId',
        );
      } catch (e) {
        // Limpiar recursos si hay error durante la preparación
        log('GlobalAudioPlayerManager: Error during preparation, cleaning up resources for: $playerId');
        
        // Cancelar subscripciones si fueron creadas
        await positionSubscription?.cancel();
        await waveformSubscription?.cancel();
        
        // Intentar dispose del player controller
        try {
          playerController.dispose();
        } catch (disposeError) {
          log('GlobalAudioPlayerManager: Error disposing playerController: $disposeError');
        }
        
        rethrow;
      }
    } catch (e) {
      log('GlobalAudioPlayerManager: Error preparing audio: $e');
      rethrow;
    } finally {
      // Liberar lock siempre, incluso si hay errores
      _releaseOperationLock(playerId);
    }
  }

  /// Inicia la reproducción de un audio específico
  Future<void> play(String playerId) async {
    // Verificar si el audio está en preparación
    if (isAudioPreparing(playerId)) {
      log('GlobalAudioPlayerManager: Audio is still preparing for playerId: $playerId');
      return;
    }

    final audioInfo = _activeAudios[playerId];
    if (audioInfo == null) {
      log('GlobalAudioPlayerManager: Audio not found for playerId: $playerId');
      return;
    }

    if (!audioInfo.isPlaying.value) {
      try {
        // Si este audio es global, pausar todos los otros audios globales
        if (audioInfo.isGlobal) {
          await _pauseAllOtherGlobalAudios(playerId);
        }

        await audioInfo.playerController.startPlayer();
        audioInfo.isPlaying.value = true;

        // Notificar callbacks
        _safeExecuteCallbacks(playerId, _onPlayCallbacks[playerId]);

        log(
          'GlobalAudioPlayerManager: Started playback for playerId: $playerId (isGlobal: ${audioInfo.isGlobal})',
        );
      } catch (e) {
        log(
          'GlobalAudioPlayerManager: Error starting playback for playerId: $playerId - $e',
        );
        rethrow;
      }
    }
  }

  /// Pausa todos los otros audios globales excepto el especificado
  Future<void> _pauseAllOtherGlobalAudios(String excludePlayerId) async {
    for (final entry in _activeAudios.entries) {
      final otherPlayerId = entry.key;
      final otherAudioInfo = entry.value;

      // Pausar solo audios globales que no sean el actual y que estén reproduciéndose
      if (otherPlayerId != excludePlayerId &&
          otherAudioInfo.isGlobal &&
          otherAudioInfo.isPlaying.value) {
        try {
          await otherAudioInfo.playerController.pausePlayer();
          otherAudioInfo.isPlaying.value = false;

          // Notificar callbacks de pausa
          _safeExecuteCallbacks(otherPlayerId, _onPauseCallbacks[otherPlayerId]);

          log(
            'GlobalAudioPlayerManager: Paused other global audio: $otherPlayerId',
          );
        } catch (e) {
          log(
            'GlobalAudioPlayerManager: Error pausing other global audio: $otherPlayerId - $e',
          );
        }
      }
    }
  }

  /// Pausa la reproducción de un audio específico
  Future<void> pause(String playerId) async {
    // Verificar si el audio está en preparación
    if (isAudioPreparing(playerId)) {
      log('GlobalAudioPlayerManager: Audio is still preparing for playerId: $playerId');
      return;
    }

    final audioInfo = _activeAudios[playerId];
    if (audioInfo == null) {
      log('GlobalAudioPlayerManager: Audio not found for playerId: $playerId');
      return;
    }

    if (audioInfo.isPlaying.value) {
      try {
        await audioInfo.playerController.pausePlayer();
        audioInfo.isPlaying.value = false;

        // Notificar callbacks
        _safeExecuteCallbacks(playerId, _onPauseCallbacks[playerId]);
      } catch (e) {
        log(
          'GlobalAudioPlayerManager: Error pausing playback for playerId: $playerId - $e',
        );
        rethrow;
      }
    }
  }

  /// Detiene y elimina un audio específico
  Future<void> stop(String playerId) async {
    // Verificar si el audio está en preparación
    if (isAudioPreparing(playerId)) {
      log('GlobalAudioPlayerManager: Audio is still preparing, waiting to stop for playerId: $playerId');
      // Esperar a que termine la preparación antes de detener
      await _preparingAudios[playerId]?.future;
    }

    final audioInfo = _activeAudios[playerId];
    if (audioInfo == null) {
      log('GlobalAudioPlayerManager: Audio not found for playerId: $playerId');
      return;
    }

    bool playerStopped = false;
    bool resourcesDisposed = false;

    try {
      // Intentar detener el player
      if (audioInfo.isPlaying.value) {
        try {
          await audioInfo.playerController.stopPlayer();
          playerStopped = true;
        } catch (e) {
          log('GlobalAudioPlayerManager: Error stopping player for $playerId: $e');
          // Continuar con cleanup aunque falle el stop
        }
      } else {
        playerStopped = true;
      }

      // Notificar callbacks antes de eliminar (independientemente del estado del player)
      _safeExecuteCallbacks(playerId, _onStopCallbacks[playerId]);

    } finally {
      // Garantizar limpieza de recursos incluso si hay errores
      try {
        // Limpiar recursos
        audioInfo.dispose();
        resourcesDisposed = true;
      } catch (e) {
        log('GlobalAudioPlayerManager: Error disposing resources for $playerId: $e');
      }

      // Eliminar de la lista (siempre)
      _activeAudios.remove(playerId);

      // Limpiar callbacks (siempre)
      _onPlayCallbacks.remove(playerId);
      _onPauseCallbacks.remove(playerId);
      _onStopCallbacks.remove(playerId);
      _onPositionChangedCallbacks.remove(playerId);
      _onWaveformDataCallbacks.remove(playerId);

      // Notificar cambio en la lista (siempre)
      _activeAudiosController.add(_activeAudios.values.toList());

      if (playerStopped && resourcesDisposed) {
        log('GlobalAudioPlayerManager: Audio stopped and removed successfully for playerId: $playerId');
      } else {
        log('GlobalAudioPlayerManager: Audio removed with partial cleanup for playerId: $playerId (player stopped: $playerStopped, resources disposed: $resourcesDisposed)');
      }
    }
  }

  /// Busca una posición específica en un audio
  Future<void> seekTo(String playerId, Duration position) async {
    // Verificar si el audio está en preparación
    if (isAudioPreparing(playerId)) {
      log('GlobalAudioPlayerManager: Audio is still preparing for playerId: $playerId');
      return;
    }

    final audioInfo = _activeAudios[playerId];
    if (audioInfo == null) {
      log('GlobalAudioPlayerManager: Audio not found for playerId: $playerId');
      return;
    }

    try {
      await audioInfo.playerController.seekTo(position.inMilliseconds);
      audioInfo.position.value = position;

      // Notificar callbacks
      _safeExecuteParameterCallbacks(playerId, _onPositionChangedCallbacks[playerId], position);
    } catch (e) {
      log(
        'GlobalAudioPlayerManager: Error seeking for playerId: $playerId - $e',
      );
      rethrow;
    }
  }

  /// Registra callbacks para un audio específico
  void registerCallbacks({
    required String playerId,
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onStop,
    Function(Duration)? onPositionChanged,
    Function(List<double>)? onWaveformData,
  }) {
    if (onPlay != null) {
      _addCallbackWithLimit(_onPlayCallbacks, playerId, onPlay);
    }
    if (onPause != null) {
      _addCallbackWithLimit(_onPauseCallbacks, playerId, onPause);
    }
    if (onStop != null) {
      _addCallbackWithLimit(_onStopCallbacks, playerId, onStop);
    }
    if (onPositionChanged != null) {
      _addCallbackWithLimit(_onPositionChangedCallbacks, playerId, onPositionChanged);
    }
    if (onWaveformData != null) {
      _addCallbackWithLimit(_onWaveformDataCallbacks, playerId, onWaveformData);

      // Enviar datos actuales si existen
      final audioInfo = _activeAudios[playerId];
      if (audioInfo?.waveformData.value != null) {
        onWaveformData(audioInfo!.waveformData.value!);
      }
    }
    
    // Log estadísticas de callbacks para debugging
    final stats = getCallbackStats(playerId);
    log('GlobalAudioPlayerManager: Callback stats for $playerId: $stats');
    
    // Iniciar limpieza automática de callbacks huérfanos si es necesario
    _scheduleOrphanedCallbackCleanup();
  }

  /// Elimina callbacks para un audio específico
  void unregisterCallbacks({
    required String playerId,
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onStop,
    Function(Duration)? onPositionChanged,
    Function(List<double>)? onWaveformData,
  }) {
    if (onPlay != null) {
      _onPlayCallbacks[playerId]?.remove(onPlay);
    }
    if (onPause != null) {
      _onPauseCallbacks[playerId]?.remove(onPause);
    }
    if (onStop != null) {
      _onStopCallbacks[playerId]?.remove(onStop);
    }
    if (onPositionChanged != null) {
      _onPositionChangedCallbacks[playerId]?.remove(onPositionChanged);
    }
    if (onWaveformData != null) {
      _onWaveformDataCallbacks[playerId]?.remove(onWaveformData);
    }
  }

  /// Limpia solo los callbacks de un audio sin detenerlo
  void clearCallbacks(String playerId) {
    _onPlayCallbacks.remove(playerId);
    _onPauseCallbacks.remove(playerId);
    _onStopCallbacks.remove(playerId);
    _onPositionChangedCallbacks.remove(playerId);
    _onWaveformDataCallbacks.remove(playerId);
    
    // Limpiar locks de callbacks si existen
    _callbackLocks.remove(playerId);
  }

  /// Detiene todos los audios activos
  Future<void> stopAll() async {
    log('GlobalAudioPlayerManager: Stopping all audios');
    final playerIds = _activeAudios.keys.toList();
    for (final playerId in playerIds) {
      await stop(playerId);
    }
  }

  /// Limpia todos los recursos
  void dispose() {
    log('GlobalAudioPlayerManager: Disposing all resources');
    stopAll();
    
    // Cancelar timer de limpieza
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    // Limpiar todos los locks
    _preparingAudios.clear();
    _operationLocks.clear();
    _callbackLocks.clear();
    
    // Limpiar todos los callbacks
    _onPlayCallbacks.clear();
    _onPauseCallbacks.clear();
    _onStopCallbacks.clear();
    _onPositionChangedCallbacks.clear();
    _onWaveformDataCallbacks.clear();
    
    _activeAudiosController.close();
  }

  // Métodos de compatibilidad (para no romper código existente)
  // Estos métodos devuelven valores estáticos para compatibilidad
  // Para obtener valores dinámicos, usar los métodos específicos del audio activo
  ValueNotifier<bool> get isPlaying => ValueNotifier<bool>(false);
  ValueNotifier<Duration> get position =>
      ValueNotifier<Duration>(Duration.zero);
  ValueNotifier<Duration> get duration =>
      ValueNotifier<Duration>(Duration.zero);
  ValueNotifier<String?> get currentAudioSource => ValueNotifier<String?>(null);
  ValueNotifier<String?> get title => ValueNotifier<String?>(null);
  ValueNotifier<String?> get activePlayerId => ValueNotifier<String?>(null);
  ValueNotifier<List<double>?> get waveformData =>
      ValueNotifier<List<double>?>(null);
  PlayerController get effectivePlayerController => PlayerController();

  void registerPlayer(String playerId, String audioSource) {
    // No necesario en el nuevo sistema
  }

  void unregisterPlayer(String playerId) {
    // Solo limpiar callbacks, no detener el audio
    // El audio se mantiene activo para el overlay
    clearCallbacks(playerId);
  }
}
