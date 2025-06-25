import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

/// Utilidades reutilizables para las pruebas de Smart Media Widgets
class TestUtils {
  // URLs de prueba
  static const String testImageUrl = 'https://picsum.photos/200/300';
  static const String testVideoUrl =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  static const String testAudioUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  // Rutas locales de prueba
  static const String testLocalImagePath = '/path/to/local/image.jpg';
  static const String testLocalVideoPath = '/path/to/local/video.mp4';
  static const String testLocalAudioPath = '/path/to/local/audio.mp3';

  /// Configuración de caché de prueba
  static const CacheConfig testCacheConfig = CacheConfig(
    maxImageCacheSize: 10 * 1024 * 1024,
    maxVideoCacheSize: 50 * 1024 * 1024,
    maxAudioCacheSize: 30 * 1024 * 1024,
    maxCacheAgeDays: 1,
    enableAutoCleanup: false,
    cleanupThreshold: 0.6,
  );

  /// Widget de prueba base con MaterialApp
  static Widget createTestApp({required Widget child, ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData(),
      home: Scaffold(body: child),
    );
  }

  /// Widget de prueba con CacheConfigScope
  static Widget createTestAppWithCache({
    required Widget child,
    CacheConfig? cacheConfig,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData(),
      home: Scaffold(
        body: cacheConfig != null
            ? CacheConfigScope(config: cacheConfig, child: child)
            : child,
      ),
    );
  }

  /// Prueba básica de creación de widget
  static Future<void> testWidgetCreation({
    required WidgetTester tester,
    required Widget widget,
    required Type expectedType,
  }) async {
    await tester.pumpWidget(createTestApp(child: widget));
    expect(find.byType(expectedType), findsOneWidget);
  }

  /// Prueba de widget con configuración de caché
  static Future<void> testWidgetWithCache({
    required WidgetTester tester,
    required Widget widget,
    required Type expectedType,
    CacheConfig? cacheConfig,
  }) async {
    await tester.pumpWidget(
      createTestAppWithCache(child: widget, cacheConfig: cacheConfig),
    );
    expect(find.byType(expectedType), findsOneWidget);
    if (cacheConfig != null) {
      expect(find.byType(CacheConfigScope), findsOneWidget);
    }
  }

  /// Prueba de widget con caché deshabilitado
  static Future<void> testWidgetWithCacheDisabled({
    required WidgetTester tester,
    required Widget widget,
    required Type expectedType,
  }) async {
    await tester.pumpWidget(createTestApp(child: widget));
    await tester.pumpAndSettle();
    expect(find.byType(expectedType), findsOneWidget);
  }

  /// Prueba de utilidades MediaUtils
  static void testMediaUtils() {
    group('MediaUtils Tests', () {
      test('isRemoteSource works correctly', () {
        expect(
          MediaUtils.isRemoteSource('https://example.com/image.jpg'),
          true,
        );
        expect(MediaUtils.isRemoteSource('http://example.com/image.jpg'), true);
        expect(MediaUtils.isRemoteSource('/path/to/local/image.jpg'), false);
      });

      test('isLocalSource works correctly', () {
        expect(MediaUtils.isLocalSource('/path/to/local/image.jpg'), true);
        expect(MediaUtils.isLocalSource('./relative/path/image.jpg'), true);
        expect(
          MediaUtils.isLocalSource('https://example.com/image.jpg'),
          false,
        );
      });

      test('isValidImageUrl works correctly', () {
        expect(
          MediaUtils.isValidImageUrl('https://example.com/image.jpg'),
          true,
        );
        expect(
          MediaUtils.isValidImageUrl('https://example.com/image.png'),
          true,
        );
        expect(
          MediaUtils.isValidImageUrl('https://example.com/video.mp4'),
          false,
        );
      });

      test('isValidVideoUrl works correctly', () {
        expect(
          MediaUtils.isValidVideoUrl('https://example.com/video.mp4'),
          true,
        );
        expect(
          MediaUtils.isValidVideoUrl('https://example.com/video.avi'),
          true,
        );
        expect(
          MediaUtils.isValidVideoUrl('https://example.com/image.jpg'),
          false,
        );
      });

      test('getFileExtension works correctly', () {
        expect(
          MediaUtils.getFileExtension('https://example.com/image.jpg'),
          'jpg',
        );
        expect(
          MediaUtils.getFileExtension('https://example.com/video.mp4'),
          'mp4',
        );
        expect(
          MediaUtils.getFileExtension('https://example.com/audio.mp3'),
          'mp3',
        );
        expect(MediaUtils.getFileExtension('https://example.com/file'), null);
      });

      test('normalizeLocalPath works correctly', () {
        expect(
          MediaUtils.normalizeLocalPath('file:///path/to/file'),
          '/path/to/file',
        );
        expect(MediaUtils.normalizeLocalPath('/path/to/file'), '/path/to/file');
      });

      test('supportsVideoPlayback works correctly', () {
        expect(MediaUtils.supportsVideoPlayback(), isA<bool>());
      });
    });
  }

  /// Prueba de CacheManager
  static void testCacheManager() {
    group('CacheManager Tests', () {
      test('formatCacheSize works correctly', () {
        expect(CacheManager.formatCacheSize(1024), '1.0 KB');
        expect(CacheManager.formatCacheSize(1024 * 1024), '1.0 MB');
        expect(CacheManager.formatCacheSize(1024 * 1024 * 1024), '1.0 GB');
      });

      test('getEffectiveConfig works correctly', () {
        const globalConfig = CacheConfig(
          maxImageCacheSize: 100 * 1024 * 1024,
          maxVideoCacheSize: 500 * 1024 * 1024,
        );
        const localConfig = CacheConfig(
          maxImageCacheSize: 50 * 1024 * 1024,
          maxCacheAgeDays: 7,
        );

        CacheManager.instance.updateConfig(globalConfig);
        final effective = CacheManager.instance.getEffectiveConfig(localConfig);

        expect(effective.maxImageCacheSize, localConfig.maxImageCacheSize);
        expect(effective.maxVideoCacheSize, localConfig.maxVideoCacheSize);
        expect(effective.maxCacheAgeDays, localConfig.maxCacheAgeDays);
      });

      test('getEffectiveConfig with null local config', () {
        const globalConfig = CacheConfig(
          maxImageCacheSize: 100 * 1024 * 1024,
          maxVideoCacheSize: 500 * 1024 * 1024,
        );

        CacheManager.instance.updateConfig(globalConfig);
        final effective = CacheManager.instance.getEffectiveConfig(null);

        expect(effective, equals(globalConfig));
      });
    });
  }

  /// Prueba de CacheConfig
  static void runCacheConfigTests() {
    group('CacheConfig Tests', () {
      test('constructor with defaults', () {
        const config = CacheConfig();
        expect(config.maxImageCacheSize, 100 * 1024 * 1024);
        expect(config.maxVideoCacheSize, 500 * 1024 * 1024);
        expect(config.maxAudioCacheSize, 200 * 1024 * 1024);
        expect(config.enableAutoCleanup, true);
        expect(config.cleanupThreshold, 0.8);
        expect(config.maxCacheAgeDays, 30);
      });

      test('copyWith works correctly', () {
        const original = CacheConfig();
        final modified = original.copyWith(
          maxImageCacheSize: 50 * 1024 * 1024,
          maxCacheAgeDays: 7,
        );

        expect(modified.maxImageCacheSize, 50 * 1024 * 1024);
        expect(modified.maxVideoCacheSize, original.maxVideoCacheSize);
        expect(modified.maxCacheAgeDays, 7);
      });

      test('merge works correctly', () {
        const config1 = CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024,
          maxCacheAgeDays: 1,
        );
        const config2 = CacheConfig(
          maxVideoCacheSize: 25 * 1024 * 1024,
          enableAutoCleanup: false,
        );

        final merged = config1.merge(config2);
        expect(merged.maxImageCacheSize, config2.maxImageCacheSize);
        expect(merged.maxVideoCacheSize, config2.maxVideoCacheSize);
        expect(merged.enableAutoCleanup, config2.enableAutoCleanup);
      });

      test('equality works correctly', () {
        const config1 = CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024,
          maxCacheAgeDays: 1,
        );
        const config2 = CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024,
          maxCacheAgeDays: 1,
        );
        const config3 = CacheConfig(
          maxImageCacheSize: 20 * 1024 * 1024,
          maxCacheAgeDays: 1,
        );

        expect(config1, equals(config2));
        expect(config1, isNot(equals(config3)));
      });

      test('toString works correctly', () {
        const config = CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024,
          maxVideoCacheSize: 50 * 1024 * 1024,
          maxAudioCacheSize: 30 * 1024 * 1024,
          enableAutoCleanup: true,
          cleanupThreshold: 0.7,
          maxCacheAgeDays: 5,
        );

        final str = config.toString();
        expect(str, contains('10.0 MB'));
        expect(str, contains('50.0 MB'));
        expect(str, contains('30.0 MB'));
        expect(str, contains('70%'));
        expect(str, contains('5'));
      });
    });
  }
}
