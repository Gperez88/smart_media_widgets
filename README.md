<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Smart Media Widgets

A Flutter package providing smart, reusable widgets for displaying images, videos, and audio with preloading, error handling, and optimization features.

> **⚠️ Development Status**: This package is currently in internal development phase and has not been officially released to pub.dev yet.

## Features

- **ImageDisplayWidget**: Smart image display with support for local and remote images
- **VideoDisplayWidget**: Advanced video player with support for local and remote videos
- **AudioPlayerWidget**: Modern audio player with waveform visualization and bubble-style UI
- **Preloading**: Built-in preloading for better user experience
- **Error Handling**: Robust error handling with customizable error widgets
- **Caching**: Intelligent caching for images, videos, and audio with configurable limits
- **Cross-Platform**: Compatible with Android and iOS
- **Customizable**: Highly customizable with various configuration options

## Installation

> **Note**: Since this package is not yet published to pub.dev, you'll need to use it as a local dependency or from a Git repository.

### Local Development

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  smart_media_widgets:
    path: ../path/to/smart_media_widgets
```

### From Git Repository (when available)

```yaml
dependencies:
  smart_media_widgets:
    git:
      url: https://github.com/Gperez88/smart_media_widgets.git
      ref: main
```

## Usage

### ImageDisplayWidget

The `ImageDisplayWidget` provides a smart way to display images from both local and remote sources.

```dart
import 'package:smart_media_widgets/smart_media_widgets.dart';

// Remote image with cache configuration
ImageDisplayWidget(
  imageSource: 'https://example.com/image.jpg',
  width: 300,
  height: 200,
  borderRadius: BorderRadius.circular(12),
  localCacheConfig: CacheConfig(
    maxImageCacheSize: 50 * 1024 * 1024, // 50MB
    enableAutoCleanup: true,
    cleanupThreshold: 0.8, // 80%
  ),
  onImageLoaded: () => print('Image loaded successfully'),
  onImageError: (error) => print('Failed to load image: $error'),
)

// Local image
ImageDisplayWidget(
  imageSource: '/path/to/local/image.jpg',
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)

// Image with cache disabled
ImageDisplayWidget(
  imageSource: 'https://example.com/sensitive-image.jpg',
  width: 300,
  height: 200,
  disableCache: true, // No caching for sensitive content
  onImageLoaded: () => print('Image loaded without cache'),
)
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `imageSource` | `String` | Required | URL or local file path |
| `width` | `double?` | `null` | Width of the image container |
| `height` | `double?` | `null` | Height of the image container |
| `fit` | `BoxFit` | `BoxFit.cover` | How to fit the image within bounds |
| `borderRadius` | `BorderRadius?` | `null` | Border radius for the image |
| `placeholder` | `Widget?` | `null` | Custom placeholder widget |
| `errorWidget` | `Widget?` | `null` | Custom error widget |
| `showLoadingIndicator` | `bool` | `true` | Show loading indicator |
| `loadingColor` | `Color?` | `null` | Color of loading indicator |
| `preload` | `bool` | `true` | Whether to preload the image |
| `localCacheConfig` | `CacheConfig?` | `null` | Local cache configuration for this widget |
| `useGlobalConfig` | `bool` | `true` | Whether to use global cache configuration |
| `disableCache` | `bool` | `false` | Whether to disable caching for this specific image |
| `onImageLoaded` | `VoidCallback?` | `null` | Callback when image loads |
| `onImageError` | `Function(String)?` | `null` | Callback when image fails |

### VideoDisplayWidget

The `VideoDisplayWidget` provides a comprehensive video player with advanced features.

```dart
import 'package:smart_media_widgets/smart_media_widgets.dart';

// Remote video with cache configuration
VideoDisplayWidget(
  videoSource: 'https://example.com/video.mp4',
  width: 400,
  height: 300,
  autoPlay: false,
  looping: true,
  showControls: true,
  localCacheConfig: CacheConfig(
    maxVideoCacheSize: 200 * 1024 * 1024, // 200MB
    enableAutoCleanup: true,
    cleanupThreshold: 0.7, // 70%
  ),
  onVideoLoaded: () => print('Video loaded successfully'),
  onVideoPlay: () => print('Video started playing'),
  onVideoPause: () => print('Video paused'),
  onVideoEnd: () => print('Video ended'),
)

// Local video
VideoDisplayWidget(
  videoSource: '/path/to/local/video.mp4',
  width: 400,
  height: 300,
  autoPlay: true,
)

// Video with cache disabled
VideoDisplayWidget(
  videoSource: 'https://example.com/live-stream.mp4',
  width: 400,
  height: 300,
  disableCache: true, // No caching for live content
  onVideoLoaded: () => print('Video loaded without cache'),
)
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `videoSource` | `String` | Required | URL or local file path |
| `width` | `double?` | `null` | Width of the video container |
| `height` | `double?` | `null` | Height of the video container |
| `autoPlay` | `bool` | `false` | Whether to auto-play the video |
| `looping` | `bool` | `false` | Whether to loop the video |
| `showControls` | `bool` | `true` | Whether to show video controls |
| `showPlayButton` | `bool` | `true` | Whether to show play button overlay |
| `placeholder` | `Widget?` | `null` | Custom placeholder widget |
| `errorWidget` | `Widget?` | `null` | Custom error widget |
| `showLoadingIndicator` | `bool` | `true` | Show loading indicator |
| `loadingColor` | `Color?` | `null` | Color of loading indicator |
| `preload` | `bool` | `true` | Whether to preload the video |
| `localCacheConfig` | `CacheConfig?` | `null` | Local cache configuration for this widget |
| `useGlobalConfig` | `bool` | `true` | Whether to use global cache configuration |
| `disableCache` | `bool` | `false` | Whether to disable caching for this specific image |
| `onVideoLoaded` | `VoidCallback?` | `null` | Callback when video loads |
| `onVideoError` | `Function(String)?` | `null` | Callback when video fails |
| `onVideoPlay` | `VoidCallback?` | `null` | Callback when video starts playing |
| `onVideoPause` | `VoidCallback?` | `null` | Callback when video pauses |
| `onVideoEnd` | `VoidCallback?` | `null` | Callback when video ends |

### AudioPlayerWidget

The `AudioPlayerWidget` provides a modern audio player with waveform visualization, preloading, robust error handling, and advanced cache management. It supports both local and remote audio files, and offers a clean, customizable bubble-style UI with play/pause controls and animated waveform.

```dart
import 'package:smart_media_widgets/smart_media_widgets.dart';

// Basic remote audio with cache configuration
AudioPlayerWidget(
  audioSource: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  width: double.infinity,
  height: 100,
  color: Colors.blueAccent,
  playIcon: Icons.play_arrow_rounded,
  pauseIcon: Icons.pause_rounded,
  borderRadius: BorderRadius.circular(20),
  onAudioLoaded: () => print('Remote audio loaded!'),
  onAudioError: (err) => print('Remote audio error: $err'),
  localCacheConfig: CacheConfig(maxAudioCacheSize: 50 * 1024 * 1024), // 50MB for this instance
  showLoadingIndicator: true,
  showSeekLine: true,
  showDuration: true,
  showPosition: true,
  useBubbleStyle: true,
)

// Custom styled audio player
AudioPlayerWidget(
  audioSource: 'https://example.com/audio.mp3',
  width: double.infinity,
  height: 120,
  color: Colors.deepPurple,
  backgroundColor: Colors.deepPurple.withValues(alpha: 0.9),
  playIcon: Icons.play_circle_fill,
  pauseIcon: Icons.pause_circle_filled,
  borderRadius: BorderRadius.circular(25),
  showSeekLine: false,
  showDuration: true,
  showPosition: true,
  timeTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  ),
  useBubbleStyle: true,
  padding: EdgeInsets.all(20),
  margin: EdgeInsets.symmetric(vertical: 8),
)

// Minimal audio player
AudioPlayerWidget(
  audioSource: '/path/to/local/audio.mp3',
  width: double.infinity,
  height: 80,
  color: Colors.green,
  backgroundColor: Colors.green.withValues(alpha: 0.8),
  borderRadius: BorderRadius.circular(12),
  showLoadingIndicator: false,
  showSeekLine: false,
  showDuration: false,
  showPosition: false,
  useBubbleStyle: false,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
)

// Audio with cache disabled
AudioPlayerWidget(
  audioSource: 'https://example.com/live-audio.mp3',
  disableCache: true, // No caching for live content
  onAudioLoaded: () => print('Live audio loaded without cache'),
)
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `audioSource` | `String` | Required | URL or local file path |
| `width` | `double?` | `null` | Width of the audio player card |
| `height` | `double?` | `80` | Height of the audio player card |
| `borderRadius` | `BorderRadius?` | `null` | Border radius for the card |
| `placeholder` | `Widget?` | `null` | Custom placeholder widget |
| `errorWidget` | `Widget?` | `null` | Custom error widget |
| `showLoadingIndicator` | `bool` | `true` | Show loading indicator |
| `localCacheConfig` | `CacheConfig?` | `null` | Local cache configuration for this widget |
| `useGlobalConfig` | `bool` | `true` | Whether to use global cache configuration |
| `disableCache` | `bool` | `false` | Whether to disable caching for this specific audio |
| `onAudioLoaded` | `VoidCallback?` | `null` | Callback when audio loads |
| `onAudioError` | `Function(String)?` | `null` | Callback when audio fails |
| `color` | `Color` | `Color(0xFF1976D2)` | Main color for the card and waveform |
| `playIcon` | `IconData` | `Icons.play_arrow` | Icon for play button |
| `pauseIcon` | `IconData` | `Icons.pause` | Icon for pause button |
| `animationDuration` | `Duration` | `300ms` | Animation duration for play/pause transitions |
| `waveStyle` | `PlayerWaveStyle?` | `null` | Custom waveform style (see audio_waveforms) |
| `showSeekLine` | `bool` | `true` | Whether to show seek line in waveform |
| `showDuration` | `bool` | `true` | Whether to show total duration text (smart display based on play state) |
| `showPosition` | `bool` | `true` | Whether to show current position text (smart display based on play state) |
| `timeTextStyle` | `TextStyle?` | `null` | Text style for duration and position text |
| `backgroundColor` | `Color?` | `null` | Background color for the player (default: color) |
| `useBubbleStyle` | `bool` | `true` | Whether to use bubble-style design with shadows |
| `padding` | `EdgeInsetsGeometry?` | `null` | Padding around the player content |
| `margin` | `EdgeInsetsGeometry?` | `null` | Margin around the player |

#### Design Features

The `AudioPlayerWidget` features a modern bubble-style design inspired by chat applications:

- **Bubble Design**: Modern rounded corners with subtle shadows
- **Animated Controls**: Smooth scale animations on button press
- **Smart Time Display**: 
  - **When playing**: Shows current position (left) and total duration (right)
  - **When paused**: Shows total duration (left) and current position (right)
- **Customizable UI**: Full control over colors, icons, and layout
- **Responsive Layout**: Adapts to different screen sizes
- **Touch Feedback**: Visual feedback on button interactions
- **Waveform Visualization**: Real-time waveform display with seek functionality

#### Audio Cache Configuration

You can configure the maximum audio cache size globally or per widget using `CacheConfig`:

```dart
// Global audio cache (all audio widgets)
CacheManager.instance.updateConfig(CacheConfig(
  maxAudioCacheSize: 100 * 1024 * 1024, // 100MB
));

// Local audio cache (per widget)
AudioPlayerWidget(
  audioSource: 'https://example.com/audio.mp3',
  localCacheConfig: CacheConfig(maxAudioCacheSize: 20 * 1024 * 1024), // 20MB
  useGlobalConfig: false, // Only use local config
)
```

- The cache will automatically clean up old audio files when the limit is exceeded.
- Both local and remote audio sources are supported. Remote files are downloaded and cached for fast replay.
- All configuration options are fully compatible with the existing cache system.

### Cache Configuration

The package includes a powerful cache management system with configurable limits and automatic cleanup. The new hybrid configuration system allows for flexible cache management at different levels.

#### Configuration Levels

1. **Global Configuration**: Set once for the entire app
2. **Local Configuration**: Override per widget without affecting global settings
3. **Context Configuration**: Provide configuration to a widget subtree
4. **Hybrid Configuration**: Combine global and local settings

#### CacheConfig Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `maxImageCacheSize` | `int` | `100MB` | Maximum size for image cache in bytes |
| `maxVideoCacheSize` | `int` | `500MB` | Maximum size for video cache in bytes |
| `maxAudioCacheSize` | `int` | `50MB` | Maximum size for audio cache in bytes |
| `enableAutoCleanup` | `bool` | `true` | Whether to enable automatic cache cleanup |
| `cleanupThreshold` | `double` | `0.8` | Cleanup threshold percentage (0.0 to 1.0) |
| `maxCacheAgeDays` | `int` | `30` | Maximum age of cached files in days |

#### Configuration Methods

##### 1. Global Configuration

```dart
// Configure cache globally for the entire app
CacheManager.instance.updateConfig(CacheConfig(
  maxImageCacheSize: 50 * 1024 * 1024, // 50MB
  maxVideoCacheSize: 200 * 1024 * 1024, // 200MB
  maxAudioCacheSize: 100 * 1024 * 1024, // 100MB
  enableAutoCleanup: true,
  cleanupThreshold: 0.7, // 70%
  maxCacheAgeDays: 7, // 7 days
));
```

##### 2. Local Configuration (Per Widget)

```dart
// Local config that doesn't affect global settings
ImageDisplayWidget(
  imageSource: 'https://example.com/image.jpg',
  localCacheConfig: CacheConfig(
    maxImageCacheSize: 10 * 1024 * 1024, // 10MB
    maxCacheAgeDays: 1, // 1 day
  ),
  useGlobalConfig: false, // Use only local config
)

// Hybrid config (combines global + local overrides)
VideoDisplayWidget(
  videoSource: 'https://example.com/video.mp4',
  localCacheConfig: CacheConfig(
    maxVideoCacheSize: 100 * 1024 * 1024, // 100MB
    maxCacheAgeDays: 3, // 3 days
  ),
  useGlobalConfig: true, // Combine with global config
)
```

##### 3. Context-Based Configuration

```dart
// Provide configuration to a widget subtree
CacheConfigScope(
  config: CacheConfig(
    maxImageCacheSize: 20 * 1024 * 1024, // 20MB
    maxVideoCacheSize: 75 * 1024 * 1024, // 75MB
    maxAudioCacheSize: 50 * 1024 * 1024, // 50MB
    enableAutoCleanup: true,
    cleanupThreshold: 0.6, // 60%
    maxCacheAgeDays: 14, // 14 days
  ),
  child: Column(
    children: [
      ImageDisplayWidget(
        imageSource: 'https://example.com/image1.jpg',
        // Uses context config automatically
      ),
      VideoDisplayWidget(
        videoSource: 'https://example.com/video1.mp4',
        // Uses context config automatically
      ),
    ],
  ),
)
```

#### Configuration Priority

The configuration is resolved in the following order:

1. **Local config** (if `useGlobalConfig: false`)
2. **Context config** (from `CacheConfigScope`)
3. **Global config** (from `CacheManager`)

#### Cache Management Examples

```dart
import 'package:smart_media_widgets/smart_media_widgets.dart';

// Configure cache globally
CacheManager.instance.updateConfig(CacheConfig(
  maxImageCacheSize: 50 * 1024 * 1024, // 50MB
  maxVideoCacheSize: 200 * 1024 * 1024, // 200MB
  maxAudioCacheSize: 100 * 1024 * 1024, // 100MB
  enableAutoCleanup: true,
  cleanupThreshold: 0.7, // 70%
  maxCacheAgeDays: 7, // 7 days
));

// Clear image cache
await CacheManager.clearImageCache();

// Clear video cache
await CacheManager.clearVideoCache();

// Clear audio cache
await CacheManager.clearAudioCache();

// Get cache statistics
final stats = await CacheManager.getCacheStats();
print('Image cache: ${stats['imageCacheSizeFormatted']}');
print('Video cache: ${stats['videoCacheSizeFormatted']}');
print('Audio cache: ${stats['audioCacheSizeFormatted']}');

// Reset to original configuration
CacheManager.instance.resetToOriginal();

// Get effective configuration
final effectiveConfig = CacheManager.instance.getEffectiveConfig(localConfig);
```

#### Benefits of the New Configuration System

- **No Interference**: Local configurations don't affect global settings
- **Automatic Cleanup**: Configurations are automatically restored when widgets are disposed
- **Flexible**: Multiple configuration methods for different use cases
- **Backward Compatible**: Existing code continues to work
- **Context-Aware**: Configuration can be inherited through the widget tree

### Progressive Streaming with Cache

The video system now supports **progressive streaming** with automatic caching:

#### How it works?

1. **First playback**: The video plays immediately using `VideoPlayerController.networkUrl` (streaming)
2. **Background download**: While playing, the video is completely downloaded for caching
3. **Subsequent playbacks**: Uses the local cached file (faster)

#### Advantages

- ✅ **Immediate playback**: No waiting to download the complete video
- ✅ **Automatic cache**: Videos are automatically saved for future use
- ✅ **Better experience**: Progressive streaming + local cache
- ✅ **Configurable**: Cache behavior can be controlled

#### Usage

```dart
// Normal usage - automatic streaming with cache
VideoDisplayWidget(
  videoSource: 'https://example.com/video.mp4',
  // Video plays immediately and is saved to cache
)

// Preload with streaming
await CacheManager.preloadVideosWithStreaming([
  'https://example.com/video1.mp4',
  'https://example.com/video2.mp4',
]);

// Streaming information
final info = await CacheManager.getVideoStreamingInfo('https://example.com/video.mp4');
print('Is cached: ${info['isCached']}');
print('Use streaming: ${info['shouldUseStreaming']}');
```

#### Streaming Flow

```dart
// 1. Widget requests video
VideoDisplayWidget(videoSource: 'https://example.com/video.mp4')

// 2. Check cache
final cachedPath = await CacheManager.getCachedVideoPath(videoUrl);

// 3a. If cached: use local file
if (cachedPath != null) {
  VideoPlayerController.file(File(cachedPath));
}

// 3b. If not cached: use streaming + background download
else {
  VideoPlayerController.networkUrl(Uri.parse(videoUrl)); // Immediate streaming
  unawaited(CacheManager.cacheVideo(videoUrl)); // Background download
}
```

### Cache Integration Details

#### How CachedNetworkImage and CacheManager Work Together

The package integrates with `CachedNetworkImage` in the following way:

1. **CachedNetworkImage** handles the actual caching of images in its own directory (`libCachedImageData`)
2. **CacheManager** monitors and manages the cache limits by checking the same directory
3. **No direct integration** - CacheManager "watches" the files that CachedNetworkImage creates

```dart
// CachedNetworkImage stores files in:
// Android: /data/data/com.example.app/cache/libCachedImageData
// iOS: /var/mobile/Containers/Data/Application/.../Library/Caches/libCachedImageData

// CacheManager monitors the same directory:
static Future<Directory> getImageCacheDirectory() async {
  final cacheDir = await getTemporaryDirectory();
  return Directory('${cacheDir.path}/libCachedImageData');
}
```

#### Cache Flow

```dart
// 1. Widget requests image
ImageDisplayWidget(imageSource: 'https://example.com/image.jpg')

// 2. CachedNetworkImage checks its cache
// If found: loads from cache
// If not found: downloads and stores in libCachedImageData

// 3. CacheManager monitors the libCachedImageData directory
// Checks if total size exceeds limits
// Removes old files if necessary

// 4. CachedNetworkImage continues to use its cache normally
// but with files potentially removed by CacheManager
```

#### Debugging Cache Directories

You can check where files are being stored:

```dart
final directories = await CacheManager.debugCacheDirectories();
print('CachedNetworkImage directory: ${directories['cachedNetworkImageDirectory']}');
print('Our image cache directory: ${directories['ourImageCacheDirectory']}');
```

### Media Utilities

The `MediaUtils` class provides utility functions for media operations.

```dart
import 'package:smart_media_widgets/smart_media_widgets.dart';

// Check if source is remote
bool isRemote = MediaUtils.isRemoteSource('https://example.com/image.jpg');

// Check if source is local
bool isLocal = MediaUtils.isLocalSource('/path/to/file.jpg');

// Validate image URL
bool isValidImage = MediaUtils.isValidImageUrl('https://example.com/image.jpg');

// Validate video URL
bool isValidVideo = MediaUtils.isValidVideoUrl('https://example.com/video.mp4');

// Validate audio URL
bool isValidAudio = MediaUtils.isValidAudioUrl('https://example.com/audio.mp3');

// Get file extension
String? extension = MediaUtils.getFileExtension('https://example.com/file.jpg');

// Check platform support
bool supportsVideo = MediaUtils.supportsVideoPlayback();
bool supportsAudio = MediaUtils.supportsAudioPlayback();
```

### Recommended Cache Configurations

This section provides recommended cache configurations for different types of applications.

#### Chat Applications (WhatsApp/Telegram Style)

For chat applications with intensive media usage and storage constraints, here are optimized configurations:

##### Base Global Configuration

```dart
CacheManager.instance.updateConfig(CacheConfig(
  maxImageCacheSize: 150 * 1024 * 1024, // 150MB
  maxVideoCacheSize: 750 * 1024 * 1024, // 750MB
  maxAudioCacheSize: 200 * 1024 * 1024, // 200MB
  enableAutoCleanup: true,
  cleanupThreshold: 0.6, // 60%
  maxCacheAgeDays: 7, // 7 days
));
```

##### Content-Specific Configurations

**Profile Images (small, high frequency)**
```dart
ImageDisplayWidget(
  imageSource: userProfileImage,
  localCacheConfig: CacheConfig(
    maxImageCacheSize: 50 * 1024 * 1024, // 50MB
    maxCacheAgeDays: 30, // 30 days
    cleanupThreshold: 0.5, // 50%
  ),
  useGlobalConfig: false,
)
```

**Stickers and GIFs (small, high frequency)**
```dart
ImageDisplayWidget(
  imageSource: stickerUrl,
  localCacheConfig: CacheConfig(
    maxImageCacheSize: 100 * 1024 * 1024, // 100MB
    maxCacheAgeDays: 14, // 14 days
    cleanupThreshold: 0.7, // 70%
  ),
  useGlobalConfig: false,
)
```

**Chat Photos (medium size, medium frequency)**
```dart
ImageDisplayWidget(
  imageSource: chatPhoto,
  localCacheConfig: CacheConfig(
    maxImageCacheSize: 200 * 1024 * 1024, // 200MB
    maxCacheAgeDays: 5, // 5 days
    cleanupThreshold: 0.6, // 60%
  ),
  useGlobalConfig: false,
)
```

**Chat Videos (short, medium frequency)**
```dart
VideoDisplayWidget(
  videoSource: chatVideo,
  localCacheConfig: CacheConfig(
    maxVideoCacheSize: 500 * 1024 * 1024, // 500MB
    maxCacheAgeDays: 3, // 3 days
    cleanupThreshold: 0.5, // 50%
  ),
  useGlobalConfig: false,
)
```

**Chat Audio Messages (short, medium frequency)**
```dart
AudioPlayerWidget(
  audioSource: chatAudioMessage,
  localCacheConfig: CacheConfig(
    maxAudioCacheSize: 100 * 1024 * 1024, // 100MB
    maxCacheAgeDays: 5, // 5 days
    cleanupThreshold: 0.6, // 60%
  ),
  useGlobalConfig: false,
)
```

##### Context-Based Configurations

**Individual Chat (less content)**
```dart
CacheConfigScope(
  config: CacheConfig(
    maxImageCacheSize: 50 * 1024 * 1024, // 50MB
    maxVideoCacheSize: 200 * 1024 * 1024, // 200MB
    maxAudioCacheSize: 50 * 1024 * 1024, // 50MB
    maxCacheAgeDays: 5,
    cleanupThreshold: 0.6,
  ),
  child: ChatScreen(),
)
```

**Large Group (more content)**
```dart
CacheConfigScope(
  config: CacheConfig(
    maxImageCacheSize: 300 * 1024 * 1024, // 300MB
    maxVideoCacheSize: 1 * 1024 * 1024 * 1024, // 1GB
    maxAudioCacheSize: 300 * 1024 * 1024, // 300MB
    maxCacheAgeDays: 7,
    cleanupThreshold: 0.7,
  ),
  child: GroupChatScreen(),
)
```

##### Scheduled Cleanup

```dart
// Daily cleanup
Timer.periodic(Duration(hours: 24), (timer) async {
  await CacheManager.clearImageCache();
  await CacheManager.clearVideoCache();
  await CacheManager.clearAudioCache();
});

// Cleanup on logout
onLogout() async {
  await CacheManager.clearImageCache();
  await CacheManager.clearVideoCache();
  await CacheManager.clearAudioCache();
}
```

##### Storage Monitoring

```dart
// Check storage limits
final stats = await CacheManager.getCacheStats();
final totalSize = stats['totalCacheSize'] as int;
final maxAllowed = 2 * 1024 * 1024 * 1024; // 2GB

if (totalSize > maxAllowed * 0.8) {
  await CacheManager.clearImageCache();
  await CacheManager.clearVideoCache();
  await CacheManager.clearAudioCache();
}
```

##### Configuration Summary

| Content Type | Cache Size | Lifetime | Cleanup Threshold |
|--------------|------------|----------|-------------------|
| Profile Images | 50MB | 30 days | 50% |
| Stickers/GIFs | 100MB | 14 days | 70% |
| Chat Photos | 200MB | 5 days | 60% |
| Chat Videos | 500MB | 3 days | 50% |
| Chat Audio | 100MB | 5 days | 60% |
| Individual Chat | 50MB img + 200MB vid + 50MB aud | 5 days | 60% |
| Large Group | 300MB img + 1GB vid + 300MB aud | 7 days | 70% |

##### Optimization Strategies

- **Smart Preloading**: Only preload content from current chat
- **Image Compression**: Use compressed images for cache
- **Chat-Based Cleanup**: Clean cache from inactive chats
- **Priority System**: High priority for profile images and frequent stickers

##### Final Recommended Configuration

```dart
CacheConfig(
  maxImageCacheSize: 200 * 1024 * 1024, // 200MB
  maxVideoCacheSize: 500 * 1024 * 1024, // 500MB
  maxAudioCacheSize: 150 * 1024 * 1024, // 150MB
  enableAutoCleanup: true,
  cleanupThreshold: 0.6, // 60%
  maxCacheAgeDays: 7, // 7 days
)
```

This configuration balances:
- ✅ **Performance**: Sufficient cache for smooth experience
- ✅ **Storage**: Reasonable limits for mobile devices
- ✅ **Cleanup Frequency**: Keeps cache fresh
- ✅ **Flexibility**: Different configurations per content type

### Disabling Cache for Specific Content

You can disable caching for specific images, videos, or audio using the `disableCache` property:

#### Disable Image Cache

```dart
// For sensitive content that shouldn't be cached
ImageDisplayWidget(
  imageSource: 'https://example.com/sensitive-image.jpg',
  disableCache: true, // No caching
  onImageLoaded: () => print('Image loaded without cache'),
)

// For live/real-time content
ImageDisplayWidget(
  imageSource: 'https://example.com/live-camera-feed.jpg',
  disableCache: true, // Always fetch fresh content
)
```

#### Disable Video Cache

```dart
// For live streams
VideoDisplayWidget(
  videoSource: 'https://example.com/live-stream.mp4',
  disableCache: true, // No caching for live content
  onVideoLoaded: () => print('Live video loaded'),
)

// For sensitive videos
VideoDisplayWidget(
  videoSource: 'https://example.com/private-video.mp4',
  disableCache: true, // No local storage
)
```

#### Disable Audio Cache

```dart
// For live audio streams
AudioPlayerWidget(
  audioSource: 'https://example.com/live-audio.mp3',
  disableCache: true, // No caching for live content
  onAudioLoaded: () => print('Live audio loaded'),
)

// For sensitive audio
AudioPlayerWidget(
  audioSource: 'https://example.com/private-audio.mp3',
  disableCache: true, // No local storage
)
```

#### Use Cases for Disabling Cache

- **Sensitive Content**: Images/videos/audio that shouldn't be stored locally
- **Live Content**: Real-time feeds that change frequently
- **Temporary Content**: One-time viewing content
- **Privacy Concerns**: Content that must not persist on device
- **Dynamic Content**: Content that changes on every request

#### How It Works

When `disableCache: true`:

**For Images:**
- Uses `Image.network` instead of `CachedNetworkImage`
- No local storage of the image
- Always fetches from network
- Still supports all other features (loading, error handling, etc.)

**For Videos:**
- Uses `VideoPlayerController.networkUrl` directly
- No background download for caching
- Streaming only, no local file storage
- Still supports all video player features

**For Audio:**
- Uses `AudioPlayerController.networkUrl` directly
- No background download for caching
- Streaming only, no local file storage
- Still supports all audio player features

### Refreshing Cache for Updated Content

When content changes (like a user updating their profile picture), you can refresh the cache to get the latest version:

#### Refresh Specific Content

```dart
// Refresh a single image (e.g., user profile)
await CacheManager.refreshImage(
  'https://example.com/user-profile.jpg',
  context: context,
  preloadAfterClear: true, // Preload the new version
);

// Refresh a single video
await CacheManager.refreshVideo(
  'https://example.com/updated-video.mp4',
  preloadAfterClear: true,
);

// Refresh a single audio file
await CacheManager.refreshAudio(
  'https://example.com/updated-audio.mp3',
  preloadAfterClear: true,
);
```

#### Refresh Multiple Items

```dart
// Refresh multiple images (e.g., user gallery)
await CacheManager.refreshImages([
  'https://example.com/image1.jpg',
  'https://example.com/image2.jpg',
  'https://example.com/image3.jpg',
], context: context, preloadAfterClear: true);

// Refresh multiple videos
await CacheManager.refreshVideos([
  'https://example.com/video1.mp4',
  'https://example.com/video2.mp4',
], preloadAfterClear: true);

// Refresh multiple audio files
await CacheManager.refreshAudios([
  'https://example.com/audio1.mp3',
  'https://example.com/audio2.mp3',
], preloadAfterClear: true);
```

#### Real-World Example: Content Update

```dart
class ContentService {
  Future<void> updateContent(String newImageUrl) async {
    // 1. Update content in backend
    await api.updateContent(newImageUrl);
    
    // 2. Refresh the image cache
    await CacheManager.refreshImage(
      newImageUrl,
      context: context,
      preloadAfterClear: true,
    );
    
    // 3. Update UI to show new image immediately
    setState(() {
      // UI will now show the fresh image
    });
  }
}
```

#### How Refresh Works

1. **Clear Cache**: Removes the old version from both Flutter's image cache and file system
2. **Optional Preload**: Downloads and caches the new version (if `preloadAfterClear: true`)
3. **Immediate Effect**: Next time the widget loads the image/video/audio, it gets the fresh content

#### Use Cases for Cache Refresh

- **Content Updates**: Images/videos/audio are replaced with new versions
- **Live Content**: Real-time feeds that need fresh data
- **Bug Fixes**: When cached content is corrupted or outdated
- **A/B Testing**: When different content versions need to be tested

## Example

See the `example/` directory for a complete example application demonstrating all features including cache configuration.

To run the example:

```bash
cd example
flutter pub get
flutter run
```

## Dependencies

This package uses the following dependencies:

- `cached_network_image: ^3.4.1` - For remote image caching
- `video_player: ^2.10.0` - For video playback
- `chewie: ^1.11.3` - For video player UI
- `audio_waveforms: ^1.3.0` - For audio waveform visualization
- `path_provider: ^2.1.5` - For file system access
- `http: ^1.4.0` - For HTTP requests
- `flutter_lints: ^5.0.0` - For code quality (dev dependency)

## Platform Support

- ✅ Android
- ✅ iOS
- ⚠️ Web (limited video support)

## Development Status

This package is currently in **internal development phase**. Key milestones:

- ✅ Core widgets implemented (Image, Video, Audio)
- ✅ Cache management system
- ✅ Error handling and preloading
- ✅ Comprehensive documentation
- ✅ Example application
- ✅ Unit tests
- 🔄 Internal testing and optimization
- 📋 Preparation for public release

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
