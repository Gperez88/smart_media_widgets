import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Configuration class for cache settings
class CacheConfig {
  /// Maximum size for image cache in bytes (default: 100MB)
  final int maxImageCacheSize;

  /// Maximum size for video cache in bytes (default: 500MB)
  final int maxVideoCacheSize;

  /// Whether to enable automatic cache cleanup
  final bool enableAutoCleanup;

  /// Cleanup threshold percentage (0.0 to 1.0) - when to start cleanup
  final double cleanupThreshold;

  /// Maximum age of cached files in days (default: 30 days)
  final int maxCacheAgeDays;

  const CacheConfig({
    this.maxImageCacheSize = 100 * 1024 * 1024, // 100MB
    this.maxVideoCacheSize = 500 * 1024 * 1024, // 500MB
    this.enableAutoCleanup = true,
    this.cleanupThreshold = 0.8, // 80%
    this.maxCacheAgeDays = 30,
  });

  /// Create a copy with updated values
  CacheConfig copyWith({
    int? maxImageCacheSize,
    int? maxVideoCacheSize,
    bool? enableAutoCleanup,
    double? cleanupThreshold,
    int? maxCacheAgeDays,
  }) {
    return CacheConfig(
      maxImageCacheSize: maxImageCacheSize ?? this.maxImageCacheSize,
      maxVideoCacheSize: maxVideoCacheSize ?? this.maxVideoCacheSize,
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
        other.enableAutoCleanup == enableAutoCleanup &&
        other.cleanupThreshold == cleanupThreshold &&
        other.maxCacheAgeDays == maxCacheAgeDays;
  }

  @override
  int get hashCode {
    return Object.hash(
      maxImageCacheSize,
      maxVideoCacheSize,
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

  CacheManager._internal();

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

  /// Clears all cached images
  static Future<void> clearImageCache() async {
    // Clear the default image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Clear cached_network_image cache - this method doesn't take parameters
    // The cache is cleared globally
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

    if (preloadAfterClear && context != null) {
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

  /// Gets total cache size (images + videos)
  static Future<int> getTotalCacheSize() async {
    final imageSize = await getImageCacheSize();
    final videoSize = await getVideoCacheSize();
    return imageSize + videoSize;
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

  /// Descarga y almacena un video en caché
  static Future<String?> cacheVideo(String videoUrl) async {
    try {
      final videoCacheDir = await getVideoCacheDirectory();
      final fileName = _generateVideoFileName(videoUrl);
      final videoFile = File('${videoCacheDir.path}/$fileName');

      // Si ya está en caché, retornar path
      if (await videoFile.exists()) {
        return videoFile.path;
      }

      // Descargar video
      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
        await videoFile.writeAsBytes(response.bodyBytes);
        return videoFile.path;
      }
      return null;
    } catch (e) {
      return null;
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

  /// Cleanup video cache to reduce size
  Future<void> _cleanupVideoCache(int currentSize) async {
    if (currentSize <= _config.maxVideoCacheSize) return;

    try {
      final videoCacheDir = await getVideoCacheDirectory();
      final files = <File>[];

      // Collect all files with their modification times
      await for (final file in videoCacheDir.list(recursive: true)) {
        if (file is File) {
          files.add(file);
        }
      }

      // Sort by modification time (oldest first)
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });

      // Remove oldest files until we're under the limit
      final int sizeToRemove = currentSize - _config.maxVideoCacheSize;
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

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    final imageSize = await getImageCacheSize();
    final videoSize = await getVideoCacheSize();
    final totalSize = imageSize + videoSize;

    return {
      'imageCacheSize': imageSize,
      'videoCacheSize': videoSize,
      'totalCacheSize': totalSize,
      'imageCacheSizeFormatted': formatCacheSize(imageSize),
      'videoCacheSizeFormatted': formatCacheSize(videoSize),
      'totalCacheSizeFormatted': formatCacheSize(totalSize),
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

    return {
      'temporaryDirectory': tempDir.path,
      'ourImageCacheDirectory': ourImageDir.path,
      'ourVideoCacheDirectory': ourVideoDir.path,
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
}
