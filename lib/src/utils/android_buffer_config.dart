import 'dart:io';

/// Configuration class to handle Android-specific buffer management issues
///
/// This class provides configurations to prevent the buffer overflow issues
/// we saw in the logs:
/// - ImageReader buffer overflow
/// - CCodec buffer management problems
/// - BufferPool saturation
class AndroidBufferConfig {
  /// Maximum number of video buffers to use (default: 2 to prevent overflow)
  final int maxVideoBuffers;

  /// Maximum number of audio buffers to use (default: 3 to prevent overflow)
  final int maxAudioBuffers;

  /// Video buffer size in bytes (default: 2MB)
  final int videoBufferSize;

  /// Audio buffer size in bytes (default: 1MB)
  final int audioBufferSize;

  /// Whether to use hardware acceleration for video (default: true)
  final bool useVideoHardwareAcceleration;

  /// Whether to use hardware acceleration for audio (default: true)
  final bool useAudioHardwareAcceleration;

  /// Video format priority (default: h264)
  final String preferredVideoFormat;

  /// Audio format priority (default: aac)
  final String preferredAudioFormat;

  /// Whether to enable adaptive streaming for video
  final bool enableVideoAdaptiveStreaming;

  /// Whether to enable adaptive bitrate for audio
  final bool enableAudioAdaptiveBitrate;

  /// Sample rate for audio processing (default: 44100)
  final int audioSampleRate;

  /// Number of audio channels (default: 2 for stereo)
  final int audioChannels;

  /// Timeout for video initialization in seconds (default: 30)
  final int videoInitTimeoutSeconds;

  /// Timeout for audio initialization in seconds (default: 30)
  final int audioInitTimeoutSeconds;

  /// Whether to enable buffer pool monitoring
  final bool enableBufferPoolMonitoring;

  /// Maximum concurrent video players (default: 1 to prevent buffer saturation)
  final int maxConcurrentVideoPlayers;

  /// Maximum concurrent audio players (default: 2 to prevent buffer saturation)
  final int maxConcurrentAudioPlayers;

  const AndroidBufferConfig({
    this.maxVideoBuffers = 2,
    this.maxAudioBuffers = 3,
    this.videoBufferSize = 2 * 1024 * 1024, // 2MB
    this.audioBufferSize = 1024 * 1024, // 1MB
    this.useVideoHardwareAcceleration = true,
    this.useAudioHardwareAcceleration = true,
    this.preferredVideoFormat = 'h264',
    this.preferredAudioFormat = 'aac',
    this.enableVideoAdaptiveStreaming = true,
    this.enableAudioAdaptiveBitrate = true,
    this.audioSampleRate = 44100,
    this.audioChannels = 2,
    this.videoInitTimeoutSeconds = 30,
    this.audioInitTimeoutSeconds = 30,
    this.enableBufferPoolMonitoring = true,
    this.maxConcurrentVideoPlayers = 1,
    this.maxConcurrentAudioPlayers = 2,
  });

  /// Creates a conservative configuration for low-end devices
  factory AndroidBufferConfig.conservative() {
    return const AndroidBufferConfig(
      maxVideoBuffers: 1,
      maxAudioBuffers: 2,
      videoBufferSize: 1024 * 1024, // 1MB
      audioBufferSize: 512 * 1024, // 512KB
      useVideoHardwareAcceleration: true,
      useAudioHardwareAcceleration: true,
      preferredVideoFormat: 'h264',
      preferredAudioFormat: 'aac',
      enableVideoAdaptiveStreaming: false,
      enableAudioAdaptiveBitrate: false,
      audioSampleRate: 22050,
      audioChannels: 1,
      videoInitTimeoutSeconds: 45,
      audioInitTimeoutSeconds: 45,
      enableBufferPoolMonitoring: true,
      maxConcurrentVideoPlayers: 1,
      maxConcurrentAudioPlayers: 1,
    );
  }

  /// Creates an optimized configuration for high-end devices
  factory AndroidBufferConfig.optimized() {
    return const AndroidBufferConfig(
      maxVideoBuffers: 3,
      maxAudioBuffers: 4,
      videoBufferSize: 4 * 1024 * 1024, // 4MB
      audioBufferSize: 2 * 1024 * 1024, // 2MB
      useVideoHardwareAcceleration: true,
      useAudioHardwareAcceleration: true,
      preferredVideoFormat: 'h264',
      preferredAudioFormat: 'aac',
      enableVideoAdaptiveStreaming: true,
      enableAudioAdaptiveBitrate: true,
      audioSampleRate: 48000,
      audioChannels: 2,
      videoInitTimeoutSeconds: 20,
      audioInitTimeoutSeconds: 20,
      enableBufferPoolMonitoring: true,
      maxConcurrentVideoPlayers: 2,
      maxConcurrentAudioPlayers: 3,
    );
  }

  /// Creates a configuration based on device capabilities
  factory AndroidBufferConfig.adaptive() {
    // In a real implementation, this would detect device capabilities
    // For now, we'll use a conservative approach
    return AndroidBufferConfig.conservative();
  }

  /// Returns a copy of this configuration with the given fields replaced
  AndroidBufferConfig copyWith({
    int? maxVideoBuffers,
    int? maxAudioBuffers,
    int? videoBufferSize,
    int? audioBufferSize,
    bool? useVideoHardwareAcceleration,
    bool? useAudioHardwareAcceleration,
    String? preferredVideoFormat,
    String? preferredAudioFormat,
    bool? enableVideoAdaptiveStreaming,
    bool? enableAudioAdaptiveBitrate,
    int? audioSampleRate,
    int? audioChannels,
    int? videoInitTimeoutSeconds,
    int? audioInitTimeoutSeconds,
    bool? enableBufferPoolMonitoring,
    int? maxConcurrentVideoPlayers,
    int? maxConcurrentAudioPlayers,
  }) {
    return AndroidBufferConfig(
      maxVideoBuffers: maxVideoBuffers ?? this.maxVideoBuffers,
      maxAudioBuffers: maxAudioBuffers ?? this.maxAudioBuffers,
      videoBufferSize: videoBufferSize ?? this.videoBufferSize,
      audioBufferSize: audioBufferSize ?? this.audioBufferSize,
      useVideoHardwareAcceleration:
          useVideoHardwareAcceleration ?? this.useVideoHardwareAcceleration,
      useAudioHardwareAcceleration:
          useAudioHardwareAcceleration ?? this.useAudioHardwareAcceleration,
      preferredVideoFormat: preferredVideoFormat ?? this.preferredVideoFormat,
      preferredAudioFormat: preferredAudioFormat ?? this.preferredAudioFormat,
      enableVideoAdaptiveStreaming:
          enableVideoAdaptiveStreaming ?? this.enableVideoAdaptiveStreaming,
      enableAudioAdaptiveBitrate:
          enableAudioAdaptiveBitrate ?? this.enableAudioAdaptiveBitrate,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      audioChannels: audioChannels ?? this.audioChannels,
      videoInitTimeoutSeconds:
          videoInitTimeoutSeconds ?? this.videoInitTimeoutSeconds,
      audioInitTimeoutSeconds:
          audioInitTimeoutSeconds ?? this.audioInitTimeoutSeconds,
      enableBufferPoolMonitoring:
          enableBufferPoolMonitoring ?? this.enableBufferPoolMonitoring,
      maxConcurrentVideoPlayers:
          maxConcurrentVideoPlayers ?? this.maxConcurrentVideoPlayers,
      maxConcurrentAudioPlayers:
          maxConcurrentAudioPlayers ?? this.maxConcurrentAudioPlayers,
    );
  }

  /// Merges this configuration with another one
  AndroidBufferConfig merge(AndroidBufferConfig other) {
    return AndroidBufferConfig(
      maxVideoBuffers: other.maxVideoBuffers,
      maxAudioBuffers: other.maxAudioBuffers,
      videoBufferSize: other.videoBufferSize,
      audioBufferSize: other.audioBufferSize,
      useVideoHardwareAcceleration: other.useVideoHardwareAcceleration,
      useAudioHardwareAcceleration: other.useAudioHardwareAcceleration,
      preferredVideoFormat: other.preferredVideoFormat,
      preferredAudioFormat: other.preferredAudioFormat,
      enableVideoAdaptiveStreaming: other.enableVideoAdaptiveStreaming,
      enableAudioAdaptiveBitrate: other.enableAudioAdaptiveBitrate,
      audioSampleRate: other.audioSampleRate,
      audioChannels: other.audioChannels,
      videoInitTimeoutSeconds: other.videoInitTimeoutSeconds,
      audioInitTimeoutSeconds: other.audioInitTimeoutSeconds,
      enableBufferPoolMonitoring: other.enableBufferPoolMonitoring,
      maxConcurrentVideoPlayers: other.maxConcurrentVideoPlayers,
      maxConcurrentAudioPlayers: other.maxConcurrentAudioPlayers,
    );
  }

  @override
  String toString() {
    return 'AndroidBufferConfig('
        'videoBuffers: $maxVideoBuffers, '
        'audioBuffers: $maxAudioBuffers, '
        'videoBufferSize: ${videoBufferSize ~/ 1024}KB, '
        'audioBufferSize: ${audioBufferSize ~/ 1024}KB, '
        'videoHwAccel: $useVideoHardwareAcceleration, '
        'audioHwAccel: $useAudioHardwareAcceleration, '
        'videoFormat: $preferredVideoFormat, '
        'audioFormat: $preferredAudioFormat, '
        'maxConcurrentVideo: $maxConcurrentVideoPlayers, '
        'maxConcurrentAudio: $maxConcurrentAudioPlayers'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AndroidBufferConfig &&
        other.maxVideoBuffers == maxVideoBuffers &&
        other.maxAudioBuffers == maxAudioBuffers &&
        other.videoBufferSize == videoBufferSize &&
        other.audioBufferSize == audioBufferSize &&
        other.useVideoHardwareAcceleration == useVideoHardwareAcceleration &&
        other.useAudioHardwareAcceleration == useAudioHardwareAcceleration &&
        other.preferredVideoFormat == preferredVideoFormat &&
        other.preferredAudioFormat == preferredAudioFormat &&
        other.enableVideoAdaptiveStreaming == enableVideoAdaptiveStreaming &&
        other.enableAudioAdaptiveBitrate == enableAudioAdaptiveBitrate &&
        other.audioSampleRate == audioSampleRate &&
        other.audioChannels == audioChannels &&
        other.videoInitTimeoutSeconds == videoInitTimeoutSeconds &&
        other.audioInitTimeoutSeconds == audioInitTimeoutSeconds &&
        other.enableBufferPoolMonitoring == enableBufferPoolMonitoring &&
        other.maxConcurrentVideoPlayers == maxConcurrentVideoPlayers &&
        other.maxConcurrentAudioPlayers == maxConcurrentAudioPlayers;
  }

  @override
  int get hashCode {
    return Object.hash(
      maxVideoBuffers,
      maxAudioBuffers,
      videoBufferSize,
      audioBufferSize,
      useVideoHardwareAcceleration,
      useAudioHardwareAcceleration,
      preferredVideoFormat,
      preferredAudioFormat,
      enableVideoAdaptiveStreaming,
      enableAudioAdaptiveBitrate,
      audioSampleRate,
      audioChannels,
      videoInitTimeoutSeconds,
      audioInitTimeoutSeconds,
      enableBufferPoolMonitoring,
      maxConcurrentVideoPlayers,
      maxConcurrentAudioPlayers,
    );
  }
}

/// Global instance for Android buffer configuration
class AndroidBufferManager {
  static final AndroidBufferManager _instance =
      AndroidBufferManager._internal();
  factory AndroidBufferManager() => _instance;
  AndroidBufferManager._internal();

  AndroidBufferConfig _config = const AndroidBufferConfig();

  /// Get the current configuration
  AndroidBufferConfig get config => _config;

  /// Update the configuration
  void updateConfig(AndroidBufferConfig newConfig) {
    _config = newConfig;
    print('AndroidBufferManager: Updated config: $_config');
  }

  /// Get a conservative configuration for low-end devices
  void useConservativeConfig() {
    updateConfig(AndroidBufferConfig.conservative());
  }

  /// Get an optimized configuration for high-end devices
  void useOptimizedConfig() {
    updateConfig(AndroidBufferConfig.optimized());
  }

  /// Get an adaptive configuration based on device capabilities
  void useAdaptiveConfig() {
    updateConfig(AndroidBufferConfig.adaptive());
  }

  /// Check if we're running on Android
  bool get isAndroid => Platform.isAndroid;

  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigSummary() {
    return {
      'isAndroid': isAndroid,
      'maxVideoBuffers': _config.maxVideoBuffers,
      'maxAudioBuffers': _config.maxAudioBuffers,
      'videoBufferSizeKB': _config.videoBufferSize ~/ 1024,
      'audioBufferSizeKB': _config.audioBufferSize ~/ 1024,
      'maxConcurrentVideoPlayers': _config.maxConcurrentVideoPlayers,
      'maxConcurrentAudioPlayers': _config.maxConcurrentAudioPlayers,
      'videoInitTimeoutSeconds': _config.videoInitTimeoutSeconds,
      'audioInitTimeoutSeconds': _config.audioInitTimeoutSeconds,
    };
  }
}
