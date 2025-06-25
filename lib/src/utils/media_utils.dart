import 'dart:io';
import 'package:flutter/foundation.dart';

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
