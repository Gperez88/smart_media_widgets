# Smart Media Widgets Example

This is an example application demonstrating the usage of the `smart_media_widgets` Flutter package.

## Features Demonstrated

- **ImageDisplayWidget**: Shows how to display remote and local images with error handling
- **VideoDisplayWidget**: Demonstrates video playback with various configurations
- **Cache Management**: Examples of cache operations and monitoring
- **Media Utilities**: Usage of utility functions for media operations

## Getting Started

### Prerequisites

- Flutter SDK (>=3.16.0)
- Dart SDK (>=3.8.1)
- Android Studio / Xcode for platform-specific development

### Installation

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## Platform Support

### Android
- Requires internet permissions for remote media
- Supports local file access
- Configured for video playback

### iOS
- Configured with App Transport Security settings
- Supports both local and remote media
- Video playback optimized for iOS

## Testing

Run the widget tests:
```bash
flutter test
```

## Structure

The example app is organized into three main sections:

1. **Images Tab**: Demonstrates image loading, error handling, and customization
2. **Videos Tab**: Shows video playback with different configurations
3. **Cache Tab**: Examples of cache management and utility functions

## Troubleshooting

- Ensure you have a stable internet connection for remote media
- For iOS, make sure you have proper code signing certificates
- For Android, verify that all permissions are properly configured

## More Information

For detailed documentation about the `smart_media_widgets` package, see the main [README.md](../README.md) file.
