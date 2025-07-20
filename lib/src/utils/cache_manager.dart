import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Gestiona la concurrencia de descargas de manera thread-safe
class DownloadConcurrencyManager {
  int _audioDownloads = 0;
  int _videoDownloads = 0;
  int _maxAudioDownloads;
  int _maxVideoDownloads;
  
  // Mapas para rastrear descargas en progreso y evitar duplicados
  final Map<String, Completer<String?>> _audioDownloadsInProgress = {};
  final Map<String, Completer<String?>> _videoDownloadsInProgress = {};
  
  // Queue de prioridades para descargas pendientes
  final List<_DownloadRequest> _pendingDownloads = [];
  Timer? _downloadProcessorTimer;

  DownloadConcurrencyManager({
    int maxAudioDownloads = 3,
    int maxVideoDownloads = 2,
  }) : _maxAudioDownloads = maxAudioDownloads,
       _maxVideoDownloads = maxVideoDownloads {
    _startDownloadProcessor();
  }

  /// Obtiene límites dinámicos basados en dispositivo
  void updateLimits({int? maxAudio, int? maxVideo}) {
    _maxAudioDownloads = maxAudio ?? _maxAudioDownloads;
    _maxVideoDownloads = maxVideo ?? _maxVideoDownloads;
    log('DownloadConcurrencyManager: Updated limits - Audio: $_maxAudioDownloads, Video: $_maxVideoDownloads');
  }

  /// Verifica si se puede iniciar una descarga de audio
  bool canStartAudioDownload() => _audioDownloads < _maxAudioDownloads;

  /// Verifica si se puede iniciar una descarga de video
  bool canStartVideoDownload() => _videoDownloads < _maxVideoDownloads;

  /// Incrementa contador de audio de manera thread-safe
  void incrementAudioDownloads() {
    _audioDownloads++;
    log('DownloadConcurrencyManager: Audio downloads: $_audioDownloads/$_maxAudioDownloads');
  }

  /// Decrementa contador de audio de manera thread-safe
  void decrementAudioDownloads() {
    _audioDownloads = (_audioDownloads - 1).clamp(0, _maxAudioDownloads);
    log('DownloadConcurrencyManager: Audio downloads: $_audioDownloads/$_maxAudioDownloads');
    _processNextDownload();
  }

  /// Incrementa contador de video de manera thread-safe
  void incrementVideoDownloads() {
    _videoDownloads++;
    log('DownloadConcurrencyManager: Video downloads: $_videoDownloads/$_maxVideoDownloads');
  }

  /// Decrementa contador de video de manera thread-safe
  void decrementVideoDownloads() {
    _videoDownloads = (_videoDownloads - 1).clamp(0, _maxVideoDownloads);
    log('DownloadConcurrencyManager: Video downloads: $_videoDownloads/$_maxVideoDownloads');
    _processNextDownload();
  }

  /// Registra una descarga en progreso para evitar duplicados
  Future<String?> registerAudioDownload(String url, Future<String?> Function() downloadFunction) async {
    // Si ya está en progreso, esperar a que termine
    if (_audioDownloadsInProgress.containsKey(url)) {
      log('DownloadConcurrencyManager: Audio download already in progress for: $url');
      return await _audioDownloadsInProgress[url]!.future;
    }

    final completer = Completer<String?>();
    _audioDownloadsInProgress[url] = completer;

    try {
      final result = await downloadFunction();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _audioDownloadsInProgress.remove(url);
    }
  }

  /// Registra una descarga de video en progreso
  Future<String?> registerVideoDownload(String url, Future<String?> Function() downloadFunction) async {
    // Si ya está en progreso, esperar a que termine
    if (_videoDownloadsInProgress.containsKey(url)) {
      log('DownloadConcurrencyManager: Video download already in progress for: $url');
      return await _videoDownloadsInProgress[url]!.future;
    }

    final completer = Completer<String?>();
    _videoDownloadsInProgress[url] = completer;

    try {
      final result = await downloadFunction();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _videoDownloadsInProgress.remove(url);
    }
  }

  /// Agenda una descarga si no hay slots disponibles
  Future<String?> _scheduleDownload(_DownloadRequest request) async {
    _pendingDownloads.add(request);
    log('DownloadConcurrencyManager: Scheduled ${request.type} download: ${request.url} (queue: ${_pendingDownloads.length})');
    
    return await request.completer.future;
  }

  /// Procesa la siguiente descarga en la queue con prioridades
  void _processNextDownload() {
    if (_pendingDownloads.isEmpty) return;

    // Ordenar por prioridad (mayor prioridad primero) y luego por timestamp (FIFO para igual prioridad)
    _pendingDownloads.sort((a, b) {
      final priorityComparison = b.priorityValue.compareTo(a.priorityValue);
      if (priorityComparison != 0) return priorityComparison;
      return a.timestamp.compareTo(b.timestamp);
    });

    for (int i = 0; i < _pendingDownloads.length; i++) {
      final request = _pendingDownloads[i];
      bool canStart = false;

      if (request.type == _DownloadType.audio && canStartAudioDownload()) {
        canStart = true;
      } else if (request.type == _DownloadType.video && canStartVideoDownload()) {
        canStart = true;
      }

      if (canStart) {
        _pendingDownloads.removeAt(i);
        log('DownloadConcurrencyManager: Starting queued ${request.type} download (priority: ${request.priority}): ${request.url}');
        
        // Ejecutar la descarga
        _executeDownload(request);
        break; // Solo procesar una descarga por vez
      }
    }
  }

  /// Ejecuta una descarga desde la queue
  void _executeDownload(_DownloadRequest request) async {
    try {
      final result = await request.downloadFunction();
      request.completer.complete(result);
    } catch (e) {
      request.completer.completeError(e);
    }
  }

  /// Inicia el procesador de descargas
  void _startDownloadProcessor() {
    _downloadProcessorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _processNextDownload();
    });
  }

  /// Obtiene estadísticas de descargas
  Map<String, dynamic> getStats() {
    return {
      'audioDownloads': _audioDownloads,
      'maxAudioDownloads': _maxAudioDownloads,
      'videoDownloads': _videoDownloads,
      'maxVideoDownloads': _maxVideoDownloads,
      'audioInProgress': _audioDownloadsInProgress.length,
      'videoInProgress': _videoDownloadsInProgress.length,
      'pendingDownloads': _pendingDownloads.length,
    };
  }

  /// Limpia recursos
  void dispose() {
    _downloadProcessorTimer?.cancel();
    _downloadProcessorTimer = null;
    
    // Cancelar descargas pendientes
    for (final request in _pendingDownloads) {
      request.completer.completeError('Download manager disposed');
    }
    _pendingDownloads.clear();
    
    _audioDownloadsInProgress.clear();
    _videoDownloadsInProgress.clear();
  }
}

/// Tipo de descarga
enum _DownloadType { audio, video }

/// Prioridad de descarga
enum DownloadPriority { low, normal, high, urgent }

/// Request de descarga para la queue
class _DownloadRequest {
  final String url;
  final _DownloadType type;
  final Future<String?> Function() downloadFunction;
  final Completer<String?> completer;
  final DateTime timestamp;
  final DownloadPriority priority;

  _DownloadRequest({
    required this.url,
    required this.type,
    required this.downloadFunction,
    required this.completer,
    this.priority = DownloadPriority.normal,
  }) : timestamp = DateTime.now();

  /// Valor numérico para ordenamiento (mayor = más prioridad)
  int get priorityValue {
    switch (priority) {
      case DownloadPriority.urgent:
        return 4;
      case DownloadPriority.high:
        return 3;
      case DownloadPriority.normal:
        return 2;
      case DownloadPriority.low:
        return 1;
    }
  }
}

/// Gestiona locks de archivos durante operaciones de E/S
class FileLockManager {
  static final FileLockManager _instance = FileLockManager._internal();
  factory FileLockManager() => _instance;
  FileLockManager._internal();

  // Mapas para rastrear archivos que están siendo escritos o limpiados
  final Set<String> _filesBeingWritten = {};
  final Set<String> _filesBeingCleaned = {};

  /// Adquiere un lock de escritura para un archivo
  bool acquireWriteLock(String filePath) {
    if (_filesBeingCleaned.contains(filePath) || _filesBeingWritten.contains(filePath)) {
      return false;
    }
    _filesBeingWritten.add(filePath);
    log('FileLockManager: Acquired write lock for: $filePath');
    return true;
  }

  /// Libera un lock de escritura para un archivo
  void releaseWriteLock(String filePath) {
    _filesBeingWritten.remove(filePath);
    log('FileLockManager: Released write lock for: $filePath');
  }

  /// Adquiere un lock de limpieza para un archivo
  bool acquireCleanupLock(String filePath) {
    if (_filesBeingWritten.contains(filePath) || _filesBeingCleaned.contains(filePath)) {
      return false;
    }
    _filesBeingCleaned.add(filePath);
    return true;
  }

  /// Libera un lock de limpieza para un archivo
  void releaseCleanupLock(String filePath) {
    _filesBeingCleaned.remove(filePath);
  }

  /// Verifica si un archivo puede ser limpiado de manera segura
  bool canCleanupFile(String filePath) {
    return !_filesBeingWritten.contains(filePath) && !_filesBeingCleaned.contains(filePath);
  }

  /// Obtiene estadísticas de locks activos
  Map<String, dynamic> getStats() {
    return {
      'filesBeingWritten': _filesBeingWritten.length,
      'filesBeingCleaned': _filesBeingCleaned.length,
      'writtenFiles': _filesBeingWritten.toList(),
      'cleanedFiles': _filesBeingCleaned.toList(),
    };
  }
}

/// Gestiona el espacio en disco y archivos activos
class DiskSpaceManager {
  static final DiskSpaceManager _instance = DiskSpaceManager._internal();
  factory DiskSpaceManager() => _instance;
  DiskSpaceManager._internal();

  // Registro de archivos en uso activo (por URL para evitar cleanup)
  final Set<String> _activeFiles = {};
  final Map<String, DateTime> _lastAccessTime = {};

  /// Marca un archivo como activo (en uso)
  void markFileAsActive(String filePath) {
    _activeFiles.add(filePath);
    _lastAccessTime[filePath] = DateTime.now();
    log('DiskSpaceManager: Marked file as active: $filePath');
  }

  /// Desmarca un archivo como activo
  void unmarkFileAsActive(String filePath) {
    _activeFiles.remove(filePath);
    _lastAccessTime[filePath] = DateTime.now();
    log('DiskSpaceManager: Unmarked file as active: $filePath');
  }

  /// Verifica si un archivo está activamente en uso
  bool isFileActive(String filePath) {
    return _activeFiles.contains(filePath);
  }

  /// Verifica el espacio disponible en disco
  Future<int> getAvailableSpace(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // En sistemas móviles, esto es una aproximación
      // En un entorno real se usaría platform channels para obtener espacio exacto
      final tempFile = File('${directory.path}/.space_check.tmp');
      await tempFile.writeAsString('test');
      await tempFile.delete();
      
      // Retornamos un valor conservador (1GB disponible por defecto)
      // En producción esto debería ser implementado con platform channels
      return 1024 * 1024 * 1024; // 1GB
    } catch (e) {
      log('DiskSpaceManager: Error checking available space: $e');
      return 0;
    }
  }

  /// Verifica si hay suficiente espacio para un archivo
  Future<bool> hasEnoughSpace(String directoryPath, int requiredBytes) async {
    final availableSpace = await getAvailableSpace(directoryPath);
    final hasSpace = availableSpace >= requiredBytes * 1.2; // 20% buffer
    
    log('DiskSpaceManager: Space check - Required: ${requiredBytes ~/ 1024}KB, Available: ${availableSpace ~/ 1024}KB, HasSpace: $hasSpace');
    return hasSpace;
  }

  /// Obtiene archivos ordenados por prioridad de limpieza
  Future<List<File>> getFilesForCleanup(Directory directory, {bool includeActive = false}) async {
    if (!await directory.exists()) return [];

    final files = <File>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        // Saltar archivos activos si no se incluyen explícitamente
        if (!includeActive && isFileActive(entity.path)) {
          continue;
        }
        files.add(entity);
      }
    }

    // Ordenar por prioridad de limpieza (menos usados primero)
    files.sort((a, b) {
      final aLastAccess = _lastAccessTime[a.path];
      final bLastAccess = _lastAccessTime[b.path];
      
      // Archivos sin registro de acceso van primero
      if (aLastAccess == null && bLastAccess == null) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      }
      if (aLastAccess == null) return -1;
      if (bLastAccess == null) return 1;
      
      return aLastAccess.compareTo(bLastAccess);
    });

    return files;
  }

  /// Limpia archivos automáticamente respetando archivos activos
  Future<int> cleanupFilesRespectingActive(
    Directory directory, 
    int targetSizeReduction,
    {bool emergencyMode = false}
  ) async {
    int cleanedSize = 0;
    final fileLockManager = FileLockManager();
    
    final files = await getFilesForCleanup(directory, includeActive: emergencyMode);
    
    for (final file in files) {
      if (cleanedSize >= targetSizeReduction) break;
      
      // Intentar adquirir lock de limpieza
      if (!fileLockManager.acquireCleanupLock(file.path)) {
        log('DiskSpaceManager: Skipping locked file: ${file.path}');
        continue;
      }
      
      try {
        if (await file.exists()) {
          final fileSize = await file.length();
          await file.delete();
          cleanedSize += fileSize;
          
          // Limpiar registros del archivo eliminado
          _activeFiles.remove(file.path);
          _lastAccessTime.remove(file.path);
          
          log('DiskSpaceManager: Deleted file: ${file.path} (${fileSize ~/ 1024}KB)');
        }
      } catch (e) {
        log('DiskSpaceManager: Error deleting file ${file.path}: $e');
      } finally {
        fileLockManager.releaseCleanupLock(file.path);
      }
    }
    
    log('DiskSpaceManager: Cleanup completed - Target: ${targetSizeReduction ~/ 1024}KB, Cleaned: ${cleanedSize ~/ 1024}KB');
    return cleanedSize;
  }

  /// Obtiene estadísticas del gestor de espacio
  Map<String, dynamic> getStats() {
    return {
      'activeFiles': _activeFiles.length,
      'trackedFiles': _lastAccessTime.length,
      'activeFilesList': _activeFiles.toList(),
    };
  }
}

/// Configuration class for cache settings
class CacheConfig {
  /// Maximum size for image cache in bytes (default: 100MB)
  final int maxImageCacheSize;

  /// Maximum size for video cache in bytes (default: 500MB)
  final int maxVideoCacheSize;

  /// Maximum size for audio cache in bytes (default: 200MB)
  final int maxAudioCacheSize;

  /// Whether to enable automatic cache cleanup
  final bool enableAutoCleanup;

  /// Cleanup threshold percentage (0.0 to 1.0) - when to start cleanup
  final double cleanupThreshold;

  /// Maximum age of cached files in days (default: 30 days)
  final int maxCacheAgeDays;

  const CacheConfig({
    this.maxImageCacheSize = 100 * 1024 * 1024, // 100MB
    this.maxVideoCacheSize = 500 * 1024 * 1024, // 500MB
    this.maxAudioCacheSize = 200 * 1024 * 1024, // 200MB
    this.enableAutoCleanup = true,
    this.cleanupThreshold = 0.8, // 80%
    this.maxCacheAgeDays = 30,
  });

  /// Create a copy with updated values
  CacheConfig copyWith({
    int? maxImageCacheSize,
    int? maxVideoCacheSize,
    int? maxAudioCacheSize,
    bool? enableAutoCleanup,
    double? cleanupThreshold,
    int? maxCacheAgeDays,
  }) {
    return CacheConfig(
      maxImageCacheSize: maxImageCacheSize ?? this.maxImageCacheSize,
      maxVideoCacheSize: maxVideoCacheSize ?? this.maxVideoCacheSize,
      maxAudioCacheSize: maxAudioCacheSize ?? this.maxAudioCacheSize,
      enableAutoCleanup: enableAutoCleanup ?? this.enableAutoCleanup,
      cleanupThreshold: cleanupThreshold ?? this.cleanupThreshold,
      maxCacheAgeDays: maxCacheAgeDays ?? this.maxCacheAgeDays,
    );
  }

  /// Merge this config with another config, using the other config's values for non-null fields
  CacheConfig merge(CacheConfig other) {
    return CacheConfig(
      maxImageCacheSize: other.maxImageCacheSize,
      maxVideoCacheSize: other.maxVideoCacheSize,
      maxAudioCacheSize: other.maxAudioCacheSize,
      enableAutoCleanup: other.enableAutoCleanup,
      cleanupThreshold: other.cleanupThreshold,
      maxCacheAgeDays: other.maxCacheAgeDays,
    );
  }

  /// Merge this config with another config, using this config's values as defaults
  CacheConfig mergeWithDefaults(CacheConfig defaults) {
    return CacheConfig(
      maxImageCacheSize: maxImageCacheSize,
      maxVideoCacheSize: maxVideoCacheSize,
      maxAudioCacheSize: maxAudioCacheSize,
      enableAutoCleanup: enableAutoCleanup,
      cleanupThreshold: cleanupThreshold,
      maxCacheAgeDays: maxCacheAgeDays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheConfig &&
        other.maxImageCacheSize == maxImageCacheSize &&
        other.maxVideoCacheSize == maxVideoCacheSize &&
        other.maxAudioCacheSize == maxAudioCacheSize &&
        other.enableAutoCleanup == enableAutoCleanup &&
        other.cleanupThreshold == cleanupThreshold &&
        other.maxCacheAgeDays == maxCacheAgeDays;
  }

  @override
  int get hashCode {
    return Object.hash(
      maxImageCacheSize,
      maxVideoCacheSize,
      maxAudioCacheSize,
      enableAutoCleanup,
      cleanupThreshold,
      maxCacheAgeDays,
    );
  }

  @override
  String toString() {
    return 'CacheConfig('
        'maxImageCacheSize: ${formatCacheSize(maxImageCacheSize)}, '
        'maxVideoCacheSize: ${formatCacheSize(maxVideoCacheSize)}, '
        'maxAudioCacheSize: ${formatCacheSize(maxAudioCacheSize)}, '
        'enableAutoCleanup: $enableAutoCleanup, '
        'cleanupThreshold: ${(cleanupThreshold * 100).toInt()}%, '
        'maxCacheAgeDays: $maxCacheAgeDays)';
  }

  /// Helper method to format cache size
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// InheritedWidget for providing cache configuration to widget tree
class CacheConfigScope extends InheritedWidget {
  final CacheConfig config;

  const CacheConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  /// Get the cache configuration from the nearest CacheConfigScope
  static CacheConfig of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CacheConfigScope>();
    return scope?.config ?? CacheManager.instance.config;
  }

  @override
  bool updateShouldNotify(CacheConfigScope oldWidget) {
    return config != oldWidget.config;
  }
}

/// Cache manager for media files with configurable limits
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._internal();

  CacheConfig _config = const CacheConfig();
  CacheConfig? _originalConfig;
  
  // Gestor de concurrencia de descargas
  late final DownloadConcurrencyManager _downloadManager;
  
  // Gestores de locks y espacio en disco
  late final FileLockManager _fileLockManager;
  late final DiskSpaceManager _diskSpaceManager;

  CacheManager._internal() {
    _downloadManager = DownloadConcurrencyManager();
    _fileLockManager = FileLockManager();
    _diskSpaceManager = DiskSpaceManager();
  }

  /// Get current cache configuration
  CacheConfig get config => _config;

  /// Get the original global configuration (before any temporary changes)
  CacheConfig get originalConfig => _originalConfig ?? _config;

  /// Update cache configuration globally
  void updateConfig(CacheConfig newConfig) {
    _originalConfig ??= _config; // Save original config on first update
    _config = newConfig;
    if (_config.enableAutoCleanup) {
      _performAutoCleanup();
    }
  }

  /// Temporarily apply a configuration without changing the global config
  /// Returns a function to restore the original configuration
  Function() applyTemporaryConfig(CacheConfig tempConfig) {
    final originalConfig = _config;
    _config = tempConfig;

    return () {
      _config = originalConfig;
    };
  }

  /// Get effective configuration by combining global config with local overrides
  CacheConfig getEffectiveConfig(CacheConfig? localConfig) {
    if (localConfig == null) return _config;

    // Use local config values, fallback to global config
    return CacheConfig(
      maxImageCacheSize: localConfig.maxImageCacheSize,
      maxVideoCacheSize: localConfig.maxVideoCacheSize,
      maxAudioCacheSize: localConfig.maxAudioCacheSize,
      enableAutoCleanup: localConfig.enableAutoCleanup,
      cleanupThreshold: localConfig.cleanupThreshold,
      maxCacheAgeDays: localConfig.maxCacheAgeDays,
    );
  }

  /// Reset to original configuration
  void resetToOriginal() {
    if (_originalConfig != null) {
      _config = _originalConfig!;
    }
  }

  /// Configura límites de descarga dinámicos basados en dispositivo
  void configureDynamicDownloadLimits() {
    int audioLimit = 3;
    int videoLimit = 2;

    try {
      // En una implementación real, aquí se detectaría el tipo de dispositivo
      // Por ahora, usamos una lógica simple basada en platform
      if (Platform.isAndroid || Platform.isIOS) {
        // Dispositivos móviles: límites conservadores
        audioLimit = 2;
        videoLimit = 1;
      } else {
        // Desktop/Web: límites más altos
        audioLimit = 4;
        videoLimit = 3;
      }

      _downloadManager.updateLimits(maxAudio: audioLimit, maxVideo: videoLimit);
      log('CacheManager: Configured dynamic download limits - Audio: $audioLimit, Video: $videoLimit');
    } catch (e) {
      log('CacheManager: Error configuring dynamic limits: $e');
    }
  }

  /// Obtiene estadísticas de descargas
  Map<String, dynamic> getDownloadStats() {
    return _downloadManager.getStats();
  }

  /// Actualiza límites de descarga manualmente
  void updateDownloadLimits({int? maxAudio, int? maxVideo}) {
    _downloadManager.updateLimits(maxAudio: maxAudio, maxVideo: maxVideo);
  }

  /// Clears all cached images
  static Future<void> clearImageCache() async {
    // Clear the default image cache
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final imageCacheDir = await getImageCacheDirectory();
      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Handle cache clearing errors silently
    }
  }

  /// Clears all cached videos
  static Future<void> clearVideoCache() async {
    try {
      final videoCacheDir = await getVideoCacheDirectory();
      if (await videoCacheDir.exists()) {
        await videoCacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Handle cache clearing errors silently
    }
  }

  /// Clears all cached audio
  static Future<void> clearAudioCache() async {
    try {
      final audioCacheDir = await getAudioCacheDirectory();
      if (await audioCacheDir.exists()) {
        await audioCacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Handle cache clearing errors silently
    }
  }

  /// Clears all cached content (images, videos, and audio)
  static Future<void> clearAllCache() async {
    try {
      await clearImageCache();
      await clearVideoCache();
      await clearAudioCache();
    } catch (e) {
      // Handle cache clearing errors silently
    }
  }

  /// Clears cache for a specific image URL
  static Future<void> clearImageCacheForUrl(String imageUrl) async {
    try {
      // Clear from Flutter's image cache
      PaintingBinding.instance.imageCache.evict(NetworkImage(imageUrl));

      // Clear from CachedNetworkImage cache
      final imageCacheDir = await getImageCacheDirectory();
      final fileName = _generateImageFileName(imageUrl);
      final imageFile = File('${imageCacheDir.path}/$fileName');

      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      // Handle cache clearing errors silently
    }
  }

  /// Clears cache for a specific video URL
  static Future<void> clearVideoCacheForUrl(String videoUrl) async {
    try {
      final videoCacheDir = await getVideoCacheDirectory();
      final fileName = _generateVideoFileName(videoUrl);
      final videoFile = File('${videoCacheDir.path}/$fileName');

      if (await videoFile.exists()) {
        await videoFile.delete();
      }
    } catch (e) {
      // Handle cache clearing errors silently
    }
  }

  /// Clears cache for multiple image URLs
  static Future<void> clearImageCacheForUrls(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await clearImageCacheForUrl(url);
    }
  }

  /// Clears cache for multiple video URLs
  static Future<void> clearVideoCacheForUrls(List<String> videoUrls) async {
    for (final url in videoUrls) {
      await clearVideoCacheForUrl(url);
    }
  }

  /// Refreshes an image by clearing its cache and optionally preloading it again
  static Future<void> refreshImage(
    String imageUrl, {
    BuildContext? context,
    bool preloadAfterClear = true,
  }) async {
    await clearImageCacheForUrl(imageUrl);

    if (preloadAfterClear && context != null && context.mounted) {
      await preloadImage(imageUrl, context);
    }
  }

  /// Refreshes a video by clearing its cache and optionally preloading it again
  static Future<void> refreshVideo(
    String videoUrl, {
    bool preloadAfterClear = true,
  }) async {
    await clearVideoCacheForUrl(videoUrl);

    if (preloadAfterClear) {
      await preloadVideo(videoUrl);
    }
  }

  /// Refreshes multiple images
  static Future<void> refreshImages(
    List<String> imageUrls, {
    BuildContext? context,
    bool preloadAfterClear = true,
  }) async {
    for (final url in imageUrls) {
      await refreshImage(
        url,
        context: context,
        preloadAfterClear: preloadAfterClear,
      );
    }
  }

  /// Refreshes multiple videos
  static Future<void> refreshVideos(
    List<String> videoUrls, {
    bool preloadAfterClear = true,
  }) async {
    for (final url in videoUrls) {
      await refreshVideo(url, preloadAfterClear: preloadAfterClear);
    }
  }

  /// Gets the cache directory for videos
  static Future<Directory> getVideoCacheDirectory() async {
    final cacheDir = await getTemporaryDirectory();
    final videoCacheDir = Directory('${cacheDir.path}/video_cache');
    if (!await videoCacheDir.exists()) {
      await videoCacheDir.create(recursive: true);
    }
    return videoCacheDir;
  }

  /// Gets the cache directory for images
  static Future<Directory> getImageCacheDirectory() async {
    try {
      // Use the actual directory that CachedNetworkImage uses
      // DefaultCacheManager uses a specific directory structure
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      return imageCacheDir;
    } catch (e) {
      // Fallback to our custom directory if DefaultCacheManager fails
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/image_cache');
      if (!await imageCacheDir.exists()) {
        await imageCacheDir.create(recursive: true);
      }
      return imageCacheDir;
    }
  }

  /// Gets the size of the video cache in bytes
  static Future<int> getVideoCacheSize() async {
    try {
      final videoCacheDir = await getVideoCacheDirectory();
      int totalSize = 0;

      await for (final file in videoCacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Gets the size of the image cache in bytes
  static Future<int> getImageCacheSize() async {
    try {
      final imageCacheDir = await getImageCacheDirectory();
      int totalSize = 0;

      await for (final file in imageCacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Gets the cache directory for audio files
  static Future<Directory> getAudioCacheDirectory() async {
    final cacheDir = await getTemporaryDirectory();
    final audioCacheDir = Directory('${cacheDir.path}/audio_cache');
    if (!await audioCacheDir.exists()) {
      await audioCacheDir.create(recursive: true);
    }
    return audioCacheDir;
  }

  /// Gets the size of the audio cache in bytes
  static Future<int> getAudioCacheSize() async {
    try {
      final audioCacheDir = await getAudioCacheDirectory();
      int totalSize = 0;
      await for (final file in audioCacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Gets total cache size (images + videos + audio)
  static Future<int> getTotalCacheSize() async {
    final imageSize = await getImageCacheSize();
    final videoSize = await getVideoCacheSize();
    final audioSize = await getAudioCacheSize();
    return imageSize + videoSize + audioSize;
  }

  /// Preloads an image into cache
  static Future<void> preloadImage(
    String imageUrl,
    BuildContext context,
  ) async {
    try {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    } catch (e) {
      // Handle preload errors silently
    }
  }

  /// Preloads multiple images into cache
  static Future<void> preloadImages(
    List<String> imageUrls,
    BuildContext context,
  ) async {
    for (final url in imageUrls) {
      await preloadImage(url, context);
    }
  }

  /// Downloads and caches an audio file from a remote URL. Returns the local path if successful, or null if failed.
  static Future<String?> cacheAudio(
    String audioUrl, {
    DownloadPriority priority = DownloadPriority.normal,
  }) async {
    final manager = CacheManager.instance;

    // Verificar si se puede iniciar inmediatamente o si hay que agendar
    if (manager._downloadManager.canStartAudioDownload()) {
      return await manager._downloadManager.registerAudioDownload(audioUrl, () => _downloadAudioFile(audioUrl));
    } else {
      // Agendar la descarga con prioridad
      final request = _DownloadRequest(
        url: audioUrl,
        type: _DownloadType.audio,
        downloadFunction: () => _downloadAudioFile(audioUrl),
        completer: Completer<String?>(),
        priority: priority,
      );
      return await manager._downloadManager._scheduleDownload(request);
    }
  }

  /// Descarga el archivo de audio (método auxiliar) con verificación de espacio y locks
  static Future<String?> _downloadAudioFile(String audioUrl) async {
    final manager = CacheManager.instance;
    
    // Verificar si ya está en caché
    final cachedPath = await getCachedAudioPath(audioUrl);
    if (cachedPath != null) {
      log('CacheManager: Audio already cached: $audioUrl');
      // Marcar archivo como activo al accederlo
      manager._diskSpaceManager.markFileAsActive(cachedPath);
      return cachedPath;
    }

    manager._downloadManager.incrementAudioDownloads();

    try {
      final audioCacheDir = await getAudioCacheDirectory();
      final fileName = _generateAudioFileName(audioUrl);
      final audioFile = File('${audioCacheDir.path}/$fileName');

      if (await audioFile.exists()) {
        log('CacheManager: Audio already cached: $fileName');
        manager._diskSpaceManager.markFileAsActive(audioFile.path);
        return audioFile.path;
      }

      // Verificar espacio disponible antes de descargar
      const estimatedSize = 5 * 1024 * 1024; // Estimación conservadora de 5MB
      final hasSpace = await manager._diskSpaceManager.hasEnoughSpace(
        audioCacheDir.path, 
        estimatedSize
      );
      
      if (!hasSpace) {
        log('CacheManager: Insufficient disk space for audio download: $audioUrl');
        // Intentar limpiar espacio automáticamente
        await manager._performSmartCleanup(audioType: true);
        
        // Verificar espacio nuevamente después del cleanup
        final hasSpaceAfterCleanup = await manager._diskSpaceManager.hasEnoughSpace(
          audioCacheDir.path, 
          estimatedSize
        );
        
        if (!hasSpaceAfterCleanup) {
          log('CacheManager: Still insufficient space after cleanup for: $audioUrl');
          return null;
        }
      }

      // Intentar adquirir lock de escritura
      if (!manager._fileLockManager.acquireWriteLock(audioFile.path)) {
        log('CacheManager: Could not acquire write lock for: ${audioFile.path}');
        return null;
      }

      try {
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(audioUrl));
          final response = await client.send(request);

          if (response.statusCode == 200) {
            final sink = audioFile.openWrite();
            try {
              int totalBytes = 0;
              await for (final chunk in response.stream) {
                sink.add(chunk);
                totalBytes += chunk.length;

                if (totalBytes % (1024 * 1024) == 0) {
                  log(
                    'CacheManager: Downloaded ${totalBytes ~/ (1024 * 1024)}MB for: $fileName',
                  );
                }
              }
              await sink.close();

              // Marcar archivo como activo al completar la descarga
              manager._diskSpaceManager.markFileAsActive(audioFile.path);

              log(
                'CacheManager: Successfully cached audio: $fileName (${totalBytes ~/ 1024}KB)',
              );
              return audioFile.path;
            } catch (e) {
              await sink.close();
              if (await audioFile.exists()) {
                await audioFile.delete();
              }
              log('CacheManager: Error writing audio file: $e');
              rethrow;
            }
          } else {
            log('CacheManager: HTTP error ${response.statusCode} for: $audioUrl');
            return null;
          }
        } finally {
          client.close();
        }
      } finally {
        // Siempre liberar el lock de escritura
        manager._fileLockManager.releaseWriteLock(audioFile.path);
      }
    } catch (e) {
      log('CacheManager: Error caching audio: $e');
      return null;
    } finally {
      manager._downloadManager.decrementAudioDownloads();
    }
  }

  /// Gets the path of the cached audio file if it exists, or null if not cached.
  static Future<String?> getCachedAudioPath(String audioUrl) async {
    try {
      final audioCacheDir = await getAudioCacheDirectory();
      final fileName = _generateAudioFileName(audioUrl);
      final audioFile = File('${audioCacheDir.path}/$fileName');
      if (await audioFile.exists()) {
        return audioFile.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generates a unique file name for an audio file based on its URL
  static String _generateAudioFileName(String audioUrl) {
    try {
      final uri = Uri.parse(audioUrl);
      final path = uri.path;

      // Extract extension from path
      String extension = 'mp3'; // Default extension
      if (path.contains('.')) {
        final pathExtension = path.split('.').last.toLowerCase();
        // Validate that it's a known audio extension
        final validExtensions = ['mp3', 'wav', 'aac', 'ogg', 'm4a', 'flac'];
        if (validExtensions.contains(pathExtension)) {
          extension = pathExtension;
        }
      }

      final hash = audioUrl.hashCode.abs();
      return 'audio_$hash.$extension';
    } catch (e) {
      // Fallback to a safe default
      final hash = audioUrl.hashCode.abs();
      return 'audio_$hash.mp3';
    }
  }

  /// Downloads and caches a video file from a remote URL. Returns the local path if successful, or null if failed.
  static Future<String?> cacheVideo(
    String videoUrl, {
    DownloadPriority priority = DownloadPriority.normal,
  }) async {
    final manager = CacheManager.instance;

    // Verificar si se puede iniciar inmediatamente o si hay que agendar
    if (manager._downloadManager.canStartVideoDownload()) {
      return await manager._downloadManager.registerVideoDownload(videoUrl, () => _downloadVideoFile(videoUrl));
    } else {
      // Agendar la descarga con prioridad
      final request = _DownloadRequest(
        url: videoUrl,
        type: _DownloadType.video,
        downloadFunction: () => _downloadVideoFile(videoUrl),
        completer: Completer<String?>(),
        priority: priority,
      );
      return await manager._downloadManager._scheduleDownload(request);
    }
  }

  /// Realiza limpieza inteligente respetando archivos activos
  Future<void> _performSmartCleanup({bool audioType = false, bool videoType = false}) async {
    log('CacheManager: Starting smart cleanup - Audio: $audioType, Video: $videoType');
    
    try {
      if (audioType) {
        final audioCacheDir = await getAudioCacheDirectory();
        const targetReduction = 50 * 1024 * 1024; // 50MB
        final cleanedSize = await _diskSpaceManager.cleanupFilesRespectingActive(
          audioCacheDir, 
          targetReduction
        );
        log('CacheManager: Smart cleanup audio - Cleaned: ${cleanedSize ~/ 1024}KB');
      }
      
      if (videoType) {
        final videoCacheDir = await getVideoCacheDirectory();
        const targetReduction = 100 * 1024 * 1024; // 100MB
        final cleanedSize = await _diskSpaceManager.cleanupFilesRespectingActive(
          videoCacheDir, 
          targetReduction
        );
        log('CacheManager: Smart cleanup video - Cleaned: ${cleanedSize ~/ 1024}KB');
      }
      
      // Si no se especifica tipo, limpiar ambos con moderación
      if (!audioType && !videoType) {
        final audioCacheDir = await getAudioCacheDirectory();
        final videoCacheDir = await getVideoCacheDirectory();
        
        await Future.wait([
          _diskSpaceManager.cleanupFilesRespectingActive(audioCacheDir, 25 * 1024 * 1024), // 25MB
          _diskSpaceManager.cleanupFilesRespectingActive(videoCacheDir, 50 * 1024 * 1024), // 50MB
        ]);
        
        log('CacheManager: Smart cleanup completed for both audio and video');
      }
    } catch (e) {
      log('CacheManager: Error during smart cleanup: $e');
    }
  }

  /// Descarga el archivo de video (método auxiliar) con verificación de espacio y locks
  static Future<String?> _downloadVideoFile(String videoUrl) async {
    final manager = CacheManager.instance;
    
    // Verificar si ya está en caché
    final cachedPath = await getCachedVideoPath(videoUrl);
    if (cachedPath != null) {
      log('CacheManager: Video already cached: $videoUrl');
      // Marcar archivo como activo al accederlo
      manager._diskSpaceManager.markFileAsActive(cachedPath);
      return cachedPath;
    }

    manager._downloadManager.incrementVideoDownloads();

    try {
      final videoCacheDir = await getVideoCacheDirectory();
      final fileName = _generateVideoFileName(videoUrl);
      final videoFile = File('${videoCacheDir.path}/$fileName');

      if (await videoFile.exists()) {
        log('CacheManager: Video already cached: $fileName');
        manager._diskSpaceManager.markFileAsActive(videoFile.path);
        return videoFile.path;
      }

      // Verificar espacio disponible antes de descargar (estimación más alta para videos)
      const estimatedSize = 50 * 1024 * 1024; // Estimación conservadora de 50MB
      final hasSpace = await manager._diskSpaceManager.hasEnoughSpace(
        videoCacheDir.path, 
        estimatedSize
      );
      
      if (!hasSpace) {
        log('CacheManager: Insufficient disk space for video download: $videoUrl');
        // Intentar limpiar espacio automáticamente
        await manager._performSmartCleanup(videoType: true);
        
        // Verificar espacio nuevamente después del cleanup
        final hasSpaceAfterCleanup = await manager._diskSpaceManager.hasEnoughSpace(
          videoCacheDir.path, 
          estimatedSize
        );
        
        if (!hasSpaceAfterCleanup) {
          log('CacheManager: Still insufficient space after cleanup for: $videoUrl');
          return null;
        }
      }

      // Intentar adquirir lock de escritura
      if (!manager._fileLockManager.acquireWriteLock(videoFile.path)) {
        log('CacheManager: Could not acquire write lock for: ${videoFile.path}');
        return null;
      }

      try {
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(videoUrl));
          final response = await client.send(request);

          if (response.statusCode == 200) {
            final sink = videoFile.openWrite();
            try {
              int totalBytes = 0;
              await for (final chunk in response.stream) {
                sink.add(chunk);
                totalBytes += chunk.length;

                if (totalBytes % (5 * 1024 * 1024) == 0) {
                  log(
                    'CacheManager: Downloaded ${totalBytes ~/ (1024 * 1024)}MB for: $fileName',
                  );
                }
              }
              await sink.close();

              // Marcar archivo como activo al completar la descarga
              manager._diskSpaceManager.markFileAsActive(videoFile.path);

              log(
                'CacheManager: Successfully cached video: $fileName (${totalBytes ~/ 1024}MB)',
              );
              return videoFile.path;
            } catch (e) {
              await sink.close();
              if (await videoFile.exists()) {
                await videoFile.delete();
              }
              log('CacheManager: Error writing video file: $e');
              rethrow;
            }
          } else {
            log('CacheManager: HTTP error ${response.statusCode} for: $videoUrl');
            return null;
          }
        } finally {
          client.close();
        }
      } finally {
        // Siempre liberar el lock de escritura
        manager._fileLockManager.releaseWriteLock(videoFile.path);
      }
    } catch (e) {
      log('CacheManager: Error caching video: $e');
      return null;
    } finally {
      manager._downloadManager.decrementVideoDownloads();
    }
  }

  /// Precarga un video en caché
  static Future<void> preloadVideo(String videoUrl) async {
    await cacheVideo(videoUrl);
  }

  /// Precarga múltiples videos en caché
  static Future<void> preloadVideos(List<String> videoUrls) async {
    for (final url in videoUrls) {
      await preloadVideo(url);
    }
  }

  /// Precarga un video con streaming progresivo (descarga en segundo plano)
  static Future<void> preloadVideoWithStreaming(String videoUrl) async {
    // Verificar si ya está en caché
    final cachedPath = await getCachedVideoPath(videoUrl);
    if (cachedPath != null) {
      return; // Ya está en caché
    }

    // Descargar en segundo plano sin bloquear
    unawaited(cacheVideo(videoUrl));
  }

  /// Precarga múltiples videos con streaming progresivo
  static Future<void> preloadVideosWithStreaming(List<String> videoUrls) async {
    for (final url in videoUrls) {
      await preloadVideoWithStreaming(url);
    }
  }

  /// Obtiene el path del video en caché si existe
  static Future<String?> getCachedVideoPath(String videoUrl) async {
    try {
      final videoCacheDir = await getVideoCacheDirectory();
      final fileName = _generateVideoFileName(videoUrl);
      final videoFile = File('${videoCacheDir.path}/$fileName');
      if (await videoFile.exists()) {
        return videoFile.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Genera un nombre de archivo único para un video
  static String _generateVideoFileName(String videoUrl) {
    final uri = Uri.parse(videoUrl);
    final path = uri.path;
    final extension = path.split('.').last;
    final hash = videoUrl.hashCode.abs();
    return 'video_$hash.$extension';
  }

  /// Genera un nombre de archivo único para una imagen
  static String _generateImageFileName(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final path = uri.path;
    final extension = path.split('.').last;
    final hash = imageUrl.hashCode.abs();
    return 'image_$hash.$extension';
  }

  /// Check if cache size exceeds limits and perform cleanup if needed
  Future<void> checkCacheLimits() async {
    if (!_config.enableAutoCleanup) return;

    final imageSize = await getImageCacheSize();
    final videoSize = await getVideoCacheSize();
    final audioSize = await getAudioCacheSize();

    bool needsCleanup = false;

    // Check image cache
    if (imageSize > _config.maxImageCacheSize * _config.cleanupThreshold) {
      await _cleanupImageCache(imageSize);
      needsCleanup = true;
    }

    // Check video cache
    if (videoSize > _config.maxVideoCacheSize * _config.cleanupThreshold) {
      await _cleanupVideoCache(videoSize);
      needsCleanup = true;
    }

    // Check audio cache
    if (audioSize > _config.maxAudioCacheSize * _config.cleanupThreshold) {
      await _cleanupAudioCache(audioSize);
      needsCleanup = true;
    }

    if (needsCleanup) {
      _performAutoCleanup();
    }
  }

  /// Perform automatic cache cleanup
  Future<void> _performAutoCleanup() async {
    try {
      final now = DateTime.now();
      final maxAge = Duration(days: _config.maxCacheAgeDays);

      // Cleanup old image files
      final imageCacheDir = await getImageCacheDirectory();
      await _cleanupOldFiles(imageCacheDir, maxAge, now);

      // Cleanup old video files
      final videoCacheDir = await getVideoCacheDirectory();
      await _cleanupOldFiles(videoCacheDir, maxAge, now);

      // Cleanup old audio files
      final audioCacheDir = await getAudioCacheDirectory();
      await _cleanupOldFiles(audioCacheDir, maxAge, now);
    } catch (e) {
      // Handle cleanup errors silently
    }
  }

  /// Cleanup old files based on age
  Future<void> _cleanupOldFiles(
    Directory cacheDir,
    Duration maxAge,
    DateTime now,
  ) async {
    if (!await cacheDir.exists()) return;

    await for (final file in cacheDir.list(recursive: true)) {
      if (file is File) {
        try {
          final stat = await file.stat();
          if (now.difference(stat.modified) > maxAge) {
            await file.delete();
          }
        } catch (e) {
          // Skip files that can't be accessed
        }
      }
    }
  }

  /// Cleanup image cache to reduce size
  Future<void> _cleanupImageCache(int currentSize) async {
    if (currentSize <= _config.maxImageCacheSize) return;

    try {
      final imageCacheDir = await getImageCacheDirectory();
      final files = <File>[];

      // Collect all files with their modification times
      await for (final file in imageCacheDir.list(recursive: true)) {
        if (file is File) {
          files.add(file);
        }
      }

      // Sort by modification time (oldest first)
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });

      // Remove oldest files until we're under the limit
      final int sizeToRemove = currentSize - _config.maxImageCacheSize;
      int removedSize = 0;

      for (final file in files) {
        if (removedSize >= sizeToRemove) break;

        try {
          final fileSize = await file.length();
          await file.delete();
          removedSize += fileSize;
        } catch (e) {
          // Skip files that can't be deleted
        }
      }
    } catch (e) {
      // Handle cleanup errors silently
    }
  }

  /// Cleanup video cache to reduce size respetando archivos activos y locks
  Future<void> _cleanupVideoCache(int currentSize) async {
    if (currentSize <= _config.maxVideoCacheSize) return;

    try {
      final videoCacheDir = await getVideoCacheDirectory();
      final sizeToRemove = currentSize - _config.maxVideoCacheSize;
      
      log('CacheManager: Starting video cleanup - Current: ${currentSize ~/ 1024}KB, Target: ${_config.maxVideoCacheSize ~/ 1024}KB, ToRemove: ${sizeToRemove ~/ 1024}KB');
      
      // Usar el nuevo sistema de cleanup inteligente
      final cleanedSize = await _diskSpaceManager.cleanupFilesRespectingActive(
        videoCacheDir, 
        sizeToRemove
      );
      
      log('CacheManager: Video cleanup completed - Cleaned: ${cleanedSize ~/ 1024}KB');
    } catch (e) {
      log('CacheManager: Error during video cleanup: $e');
    }
  }

  /// Cleanup audio cache to reduce size respetando archivos activos y locks
  Future<void> _cleanupAudioCache(int currentSize) async {
    if (currentSize <= _config.maxAudioCacheSize) return;
    
    try {
      final audioCacheDir = await getAudioCacheDirectory();
      final sizeToRemove = currentSize - _config.maxAudioCacheSize;
      
      log('CacheManager: Starting audio cleanup - Current: ${currentSize ~/ 1024}KB, Target: ${_config.maxAudioCacheSize ~/ 1024}KB, ToRemove: ${sizeToRemove ~/ 1024}KB');
      
      // Usar el nuevo sistema de cleanup inteligente
      final cleanedSize = await _diskSpaceManager.cleanupFilesRespectingActive(
        audioCacheDir, 
        sizeToRemove
      );
      
      log('CacheManager: Audio cleanup completed - Cleaned: ${cleanedSize ~/ 1024}KB');
    } catch (e) {
      log('CacheManager: Error during audio cleanup: $e');
    }
  }

  /// Get cache statistics including new disk management stats
  static Future<Map<String, dynamic>> getCacheStats() async {
    final manager = CacheManager.instance;
    final imageSize = await getImageCacheSize();
    final videoSize = await getVideoCacheSize();
    final audioSize = await getAudioCacheSize();
    final totalSize = imageSize + videoSize + audioSize;

    return {
      'imageCacheSize': imageSize,
      'videoCacheSize': videoSize,
      'audioCacheSize': audioSize,
      'totalCacheSize': totalSize,
      'imageCacheSizeFormatted': formatCacheSize(imageSize),
      'videoCacheSizeFormatted': formatCacheSize(videoSize),
      'audioCacheSizeFormatted': formatCacheSize(audioSize),
      'totalCacheSizeFormatted': formatCacheSize(totalSize),
      // Estadísticas de gestión de concurrencia
      'downloadStats': manager._downloadManager.getStats(),
      // Estadísticas de locks de archivos
      'fileLockStats': manager._fileLockManager.getStats(),
      // Estadísticas de gestión de espacio
      'diskSpaceStats': manager._diskSpaceManager.getStats(),
    };
  }

  /// Formats cache size for display (maintained for backward compatibility)
  static String formatCacheSize(int bytes) {
    return CacheConfig.formatCacheSize(bytes);
  }

  /// Debug method to check cache directories
  static Future<Map<String, String>> debugCacheDirectories() async {
    final tempDir = await getTemporaryDirectory();
    final ourImageDir = await getImageCacheDirectory();
    final ourVideoDir = await getVideoCacheDirectory();
    final ourAudioDir = await getAudioCacheDirectory();

    return {
      'temporaryDirectory': tempDir.path,
      'ourImageCacheDirectory': ourImageDir.path,
      'ourVideoCacheDirectory': ourVideoDir.path,
      'ourAudioCacheDirectory': ourAudioDir.path,
      'cachedNetworkImageDirectory': '${tempDir.path}/libCachedImageData',
    };
  }

  /// Obtiene información de streaming para un video
  static Future<Map<String, dynamic>> getVideoStreamingInfo(
    String videoUrl,
  ) async {
    final cachedPath = await getCachedVideoPath(videoUrl);
    final isCached = cachedPath != null;

    return {
      'isCached': isCached,
      'cachedPath': cachedPath,
      'shouldUseStreaming': !isCached,
      'recommendedApproach': isCached ? 'local_file' : 'network_streaming',
    };
  }

  /// Marca un archivo como activo (en uso) para protegerlo del cleanup
  static void markFileAsActive(String filePath) {
    final manager = CacheManager.instance;
    manager._diskSpaceManager.markFileAsActive(filePath);
  }

  /// Desmarca un archivo como activo
  static void unmarkFileAsActive(String filePath) {
    final manager = CacheManager.instance;
    manager._diskSpaceManager.unmarkFileAsActive(filePath);
  }

  /// Verifica si un archivo está activo (protegido del cleanup)
  static bool isFileActive(String filePath) {
    final manager = CacheManager.instance;
    return manager._diskSpaceManager.isFileActive(filePath);
  }

  /// Realiza cleanup inteligente manual respetando archivos activos
  static Future<void> performSmartCleanup({
    bool audioType = false, 
    bool videoType = false,
  }) async {
    final manager = CacheManager.instance;
    await manager._performSmartCleanup(audioType: audioType, videoType: videoType);
  }

  /// Verifica el espacio disponible en disco para el directorio de cache
  static Future<int> getAvailableSpace() async {
    final manager = CacheManager.instance;
    final tempDir = await getTemporaryDirectory();
    return await manager._diskSpaceManager.getAvailableSpace(tempDir.path);
  }

  /// Verifica si hay suficiente espacio para un archivo de tamaño estimado
  static Future<bool> hasEnoughSpace(int requiredBytes) async {
    final manager = CacheManager.instance;
    final tempDir = await getTemporaryDirectory();
    return await manager._diskSpaceManager.hasEnoughSpace(tempDir.path, requiredBytes);
  }

  /// Configura límites de concurrencia de descargas
  static void configureConcurrencyLimits({int? maxAudio, int? maxVideo}) {
    final manager = CacheManager.instance;
    manager._downloadManager.updateLimits(maxAudio: maxAudio, maxVideo: maxVideo);
  }
}

// Variables de concurrencia obsoletas removidas - ahora se usa DownloadConcurrencyManager
