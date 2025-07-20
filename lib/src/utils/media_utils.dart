import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utility class for media-related operations
class MediaUtils {
  /// Determines if the given source is a remote URL
  static bool isRemoteSource(String source) {
    final isRemote =
        source.startsWith('http://') || source.startsWith('https://');
    debugPrint('MediaUtils: isRemoteSource("$source") = $isRemote');
    return isRemote;
  }

  /// Determines if the given source is a local file path
  static bool isLocalSource(String source) {
    return source.startsWith('file://') ||
        source.startsWith('/') ||
        source.startsWith('./') ||
        source.startsWith('../');
  }

  /// Downloads a remote file and returns the local path
  /// This is needed because audio_waveforms plugin has issues with remote URLs
  static Future<String> downloadRemoteFile(
    String url, {
    String? customFileName,
  }) async {
    try {
      debugPrint('MediaUtils: Downloading remote file: $url');

      // Create a unique filename if not provided
      final fileName = customFileName ?? _generateFileNameFromUrl(url);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, fileName);

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('MediaUtils: File already exists at: $filePath');
        return filePath;
      }

      // Download the file
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Write the file
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('MediaUtils: File downloaded successfully to: $filePath');
        return filePath;
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MediaUtils: Error downloading file: $e');
      rethrow;
    }
  }

  /// Generates a filename from URL
  static String _generateFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final fileName = pathSegments.last;
      if (fileName.isNotEmpty && fileName.contains('.')) {
        return fileName;
      }
    }

    // Fallback: generate filename with extension
    final extension = getFileExtension(url) ?? 'mp3';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'audio_$timestamp.$extension';
  }

  /// Cleans up temporary files older than specified age
  static Future<void> cleanupTempFiles({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final cutoffTime = DateTime.now().subtract(maxAge);

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await file.delete();
            debugPrint('MediaUtils: Cleaned up old temp file: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('MediaUtils: Error cleaning up temp files: $e');
    }
  }

  /// Gets the appropriate source path for audio_waveforms plugin
  /// For remote URLs, downloads the file first
  static Future<String> getAudioSourcePath(String source) async {
    if (isRemoteSource(source)) {
      debugPrint(
        'MediaUtils: Remote audio source detected, downloading: $source',
      );
      return await downloadRemoteFile(source);
    } else {
      debugPrint('MediaUtils: Local audio source: $source');
      return normalizeLocalPath(source);
    }
  }

  /// Validates if the given URL is a valid image URL
  static bool isValidImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext)) ||
        lowerUrl.contains('image/');
  }

  /// Validates if the given URL is a valid video URL
  static bool isValidVideoUrl(String url) {
    final videoExtensions = [
      '.mp4',
      '.avi',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.mkv',
    ];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.contains(ext)) ||
        lowerUrl.contains('video/');
  }

  /// Validates if the given URL is a valid audio URL
  static bool isValidAudioUrl(String url) {
    final audioExtensions = [
      '.mp3',
      '.wav',
      '.aac',
      '.ogg',
      '.m4a',
      '.flac',
      '.wma',
    ];
    final lowerUrl = url.toLowerCase();
    return audioExtensions.any((ext) => lowerUrl.contains(ext)) ||
        lowerUrl.contains('audio/');
  }

  /// Validates if the given URL is a valid remote URL
  static bool isValidRemoteUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Gets the file extension from a URL or file path
  static String? getFileExtension(String source) {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final fileName = uri.pathSegments.last;
      final dotIndex = fileName.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < fileName.length - 1) {
        return fileName.substring(dotIndex + 1).toLowerCase();
      }
    }
    return null;
  }

  /// Checks if the platform supports video playback
  static bool supportsVideoPlayback() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Checks if the platform supports audio playback
  static bool supportsAudioPlayback() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Normalizes a file path for local sources
  static String normalizeLocalPath(String path) {
    if (path.startsWith('file://')) {
      return path.substring(7);
    }
    return path;
  }
}
