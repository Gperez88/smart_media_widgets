# Integration Guide

This guide explains how to integrate the `smart_media_widgets` package into your Flutter project.

## Quick Start

### 1. Add the dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  smart_media_widgets: ^1.0.0
```

### 2. Install dependencies

Run the following command to install the package:

```bash
flutter pub get
```

### 3. Import the package

Import the package in your Dart files:

```dart
import 'package:smart_media_widgets/smart_media_widgets.dart';
```

## Basic Usage Examples

### Displaying Images

```dart
// Remote image
ImageDisplayWidget(
  imageSource: 'https://example.com/image.jpg',
  width: 300,
  height: 200,
  borderRadius: BorderRadius.circular(12),
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
```

### Displaying Videos

```dart
// Remote video
VideoDisplayWidget(
  videoSource: 'https://example.com/video.mp4',
  width: 400,
  height: 300,
  autoPlay: false,
  looping: true,
  showControls: true,
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
```

## Advanced Features

### Custom Error Handling

```dart
ImageDisplayWidget(
  imageSource: 'https://example.com/image.jpg',
  errorWidget: Container(
    width: 300,
    height: 200,
    decoration: BoxDecoration(
      color: Colors.red[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 48, color: Colors.red),
        SizedBox(height: 8),
        Text('Custom Error Message'),
      ],
    ),
  ),
)
```

### Custom Placeholders

```dart
VideoDisplayWidget(
  videoSource: 'https://example.com/video.mp4',
  placeholder: Container(
    width: 400,
    height: 300,
    color: Colors.grey[300],
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading video...'),
        ],
      ),
    ),
  ),
)
```

### Cache Management

```dart
// Clear image cache
await CacheManager.clearImageCache();

// Clear video cache
await CacheManager.clearVideoCache();

// Get cache size
final cacheSize = await CacheManager.getVideoCacheSize();
print('Cache size: ${CacheManager.formatCacheSize(cacheSize)}');

// Preload images
await CacheManager.preloadImages([
  'https://example.com/image1.jpg',
  'https://example.com/image2.jpg',
], context);
```

## Platform-Specific Configuration

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Best Practices

### 1. Error Handling

Always provide error callbacks to handle loading failures gracefully:

```dart
ImageDisplayWidget(
  imageSource: imageUrl,
  onImageError: (error) {
    // Log the error
    print('Image loading failed: $error');
    
    // Show user-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load image')),
    );
  },
)
```

### 2. Preloading

Use preloading for better user experience when you know which images will be displayed:

```dart
// Preload images before displaying them
await CacheManager.preloadImages(imageUrls, context);
```

### 3. Memory Management

Clear cache periodically to prevent memory issues:

```dart
// Clear cache when app goes to background
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    CacheManager.clearImageCache();
  }
}
```

### 4. Responsive Design

Use flexible dimensions for responsive layouts:

```dart
ImageDisplayWidget(
  imageSource: imageUrl,
  width: MediaQuery.of(context).size.width * 0.8,
  height: MediaQuery.of(context).size.height * 0.3,
)
```

## Troubleshooting

### Common Issues

1. **Images not loading**: Check internet permissions and URL validity
2. **Videos not playing**: Ensure video format is supported and URL is accessible
3. **Cache issues**: Clear cache manually if needed
4. **Memory issues**: Monitor cache size and clear periodically

### Debug Mode

Enable debug logging to troubleshoot issues:

```dart
// Add debug prints in callbacks
ImageDisplayWidget(
  imageSource: imageUrl,
  onImageLoaded: () => print('DEBUG: Image loaded: $imageUrl'),
  onImageError: (error) => print('DEBUG: Image error: $error'),
)
```

## Support

For issues and questions:

1. Check the [README.md](README.md) for detailed documentation
2. Review the [example](example/) app for usage examples
3. Open an issue on the GitHub repository
4. Check the [CHANGELOG.md](CHANGELOG.md) for updates and fixes 