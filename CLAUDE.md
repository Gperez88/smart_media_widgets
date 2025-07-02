# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Media Widgets is a Flutter package providing reusable widgets for displaying images, videos, and audio with advanced features like preloading, error handling, and intelligent caching. The package is currently in internal development and not yet published to pub.dev.

## Development Commands

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/image_display_widget_test.dart
flutter test test/video_player_widget_test.dart
flutter test test/audio_player_widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Run linter analysis
flutter analyze

# Format code
dart format .

# Fix linting issues automatically (where possible)
dart fix --apply
```

### Example App
```bash
# Run the example app
cd example
flutter pub get
flutter run

# Build for release
cd example
flutter build apk
flutter build ios
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated dependencies
flutter pub outdated
```

## Architecture Overview

### Package Structure
- **Core Exports**: `lib/smart_media_widgets.dart` - Main package entry point
- **Utilities**: `lib/src/utils/` - Core utilities and cache management
  - `cache_manager.dart` - Centralized cache management with configurable limits
  - `media_utils.dart` - Media validation and utility functions
- **Widget Categories**: `lib/src/widgets/` - Organized by media type
  - `image_display/` - Image widgets with local/remote support
  - `video_player/` - Video widgets with progressive streaming
  - `audio_player/` - Audio widgets with waveform visualization

### Key Components

#### Cache Management System
- **Hybrid Configuration**: Global, local, and context-based cache settings
- **Automatic Cleanup**: Configurable thresholds and age-based cleanup
- **Progressive Streaming**: Videos stream immediately while caching in background
- **Multi-Media Support**: Separate cache management for images, videos, and audio

#### Widget Architecture Pattern
Each widget category follows a consistent pattern:
- Main widget file (e.g., `audio_player_widget.dart`)
- Specialized components (buttons, displays, error handlers)
- Placeholder and loading states
- Error handling components
- Export file for clean imports

#### Configuration System
- **CacheConfig**: Immutable configuration with `copyWith()` method
- **CacheConfigScope**: InheritedWidget for configuration inheritance
- **Local Overrides**: Per-widget configuration without affecting global settings
- **Priority Resolution**: Local → Context → Global configuration

### Dependencies and Integration
- **cached_network_image**: Image caching (monitored by CacheManager)
- **video_player + chewie**: Video playback with custom UI
- **audio_waveforms**: Audio visualization and playback
- **path_provider**: File system access for caching
- **http**: Network requests for media downloading

### Development Patterns
- **Error Handling**: Consistent error widgets and callbacks across all media types
- **Loading States**: Standardized placeholder and loading indicator patterns
- **Resource Management**: Proper disposal in StatefulWidget lifecycle
- **Testing**: Comprehensive test coverage with `test_utils.dart` helpers

### Security Considerations
- **Cache Disable Option**: `disableCache: true` for sensitive content
- **URL Validation**: Media URL validation in `MediaUtils`
- **Error Sanitization**: No sensitive information exposed in error messages

## Important Notes for Development

### Following Project Conventions
- Check `.cursorrules` for comprehensive coding standards
- All documentation and comments must be in English
- Use snake_case for files, PascalCase for classes, camelCase for methods
- Generate tests for all main widgets and functions
- Implement proper resource cleanup in `dispose()`

### Cache Management Integration
When working with cache features:
- CacheManager monitors but doesn't directly control CachedNetworkImage
- Videos use progressive streaming (immediate play + background cache)
- Audio files are fully downloaded before playback begins
- Always test cache behavior with different size limits and configurations

### Widget Development
- Support both local and remote sources
- Include customizable placeholder and error widgets
- Provide comprehensive callback system (onLoaded, onError, etc.)
- Follow Material Design guidelines for UI consistency
- Implement proper accessibility features (semanticsLabel, etc.)

### Performance Considerations
- Use const constructors where possible
- Implement proper `==` operator and `hashCode` for configurations
- Clean up resources (StreamSubscriptions, controllers) in dispose()
- Optimize for smooth animations and transitions