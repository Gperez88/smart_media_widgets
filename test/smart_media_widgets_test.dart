import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

void main() {
  group('Smart Media Widgets Tests', () {
    testWidgets('ImageDisplayWidget creates without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImageDisplayWidget(
              imageSource: 'https://picsum.photos/200/300',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      expect(find.byType(ImageDisplayWidget), findsOneWidget);
    });

    testWidgets('VideoDisplayWidget creates without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoDisplayWidget(
              videoSource:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              width: 400,
              height: 300,
            ),
          ),
        ),
      );

      expect(find.byType(VideoDisplayWidget), findsOneWidget);
    });

    testWidgets('ImageDisplayWidget with local cache config', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImageDisplayWidget(
              imageSource: 'https://picsum.photos/200/300',
              width: 200,
              height: 300,
              localCacheConfig: CacheConfig(
                maxImageCacheSize: 10 * 1024 * 1024,
                maxCacheAgeDays: 1,
              ),
              useGlobalConfig: false,
            ),
          ),
        ),
      );

      expect(find.byType(ImageDisplayWidget), findsOneWidget);
    });

    testWidgets('VideoDisplayWidget with local cache config', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoDisplayWidget(
              videoSource:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              width: 400,
              height: 300,
              localCacheConfig: CacheConfig(
                maxVideoCacheSize: 50 * 1024 * 1024,
                maxCacheAgeDays: 2,
              ),
              useGlobalConfig: false,
            ),
          ),
        ),
      );

      expect(find.byType(VideoDisplayWidget), findsOneWidget);
    });

    testWidgets('CacheConfigScope provides configuration to children', (
      WidgetTester tester,
    ) async {
      const testConfig = CacheConfig(
        maxImageCacheSize: 15 * 1024 * 1024,
        maxVideoCacheSize: 75 * 1024 * 1024,
        enableAutoCleanup: false,
        cleanupThreshold: 0.6,
        maxCacheAgeDays: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CacheConfigScope(
              config: testConfig,
              child: const ImageDisplayWidget(
                imageSource: 'https://picsum.photos/200/300',
                width: 200,
                height: 300,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CacheConfigScope), findsOneWidget);
      expect(find.byType(ImageDisplayWidget), findsOneWidget);
    });

    test('MediaUtils.isRemoteSource works correctly', () {
      expect(MediaUtils.isRemoteSource('https://example.com/image.jpg'), true);
      expect(MediaUtils.isRemoteSource('http://example.com/image.jpg'), true);
      expect(MediaUtils.isRemoteSource('/path/to/local/image.jpg'), false);
    });

    test('MediaUtils.isLocalSource works correctly', () {
      expect(MediaUtils.isLocalSource('/path/to/local/image.jpg'), true);
      expect(MediaUtils.isLocalSource('./relative/path/image.jpg'), true);
      expect(MediaUtils.isLocalSource('https://example.com/image.jpg'), false);
    });

    test('MediaUtils.isValidImageUrl works correctly', () {
      expect(MediaUtils.isValidImageUrl('https://example.com/image.jpg'), true);
      expect(MediaUtils.isValidImageUrl('https://example.com/image.png'), true);
      expect(
        MediaUtils.isValidImageUrl('https://example.com/video.mp4'),
        false,
      );
    });

    test('MediaUtils.isValidVideoUrl works correctly', () {
      expect(MediaUtils.isValidVideoUrl('https://example.com/video.mp4'), true);
      expect(MediaUtils.isValidVideoUrl('https://example.com/video.avi'), true);
      expect(
        MediaUtils.isValidVideoUrl('https://example.com/image.jpg'),
        false,
      );
    });

    test('MediaUtils.getFileExtension works correctly', () {
      expect(
        MediaUtils.getFileExtension('https://example.com/image.jpg'),
        'jpg',
      );
      expect(
        MediaUtils.getFileExtension('https://example.com/video.mp4'),
        'mp4',
      );
      expect(MediaUtils.getFileExtension('https://example.com/file'), null);
    });

    test('CacheManager.formatCacheSize works correctly', () {
      expect(CacheManager.formatCacheSize(1024), '1.0 KB');
      expect(CacheManager.formatCacheSize(1024 * 1024), '1.0 MB');
      expect(CacheManager.formatCacheSize(1024 * 1024 * 1024), '1.0 GB');
    });

    group('CacheConfig Tests', () {
      test('CacheConfig constructor with defaults', () {
        const config = CacheConfig();
        expect(config.maxImageCacheSize, 100 * 1024 * 1024);
        expect(config.maxVideoCacheSize, 500 * 1024 * 1024);
        expect(config.enableAutoCleanup, true);
        expect(config.cleanupThreshold, 0.8);
        expect(config.maxCacheAgeDays, 30);
      });

      test('CacheConfig copyWith works correctly', () {
        const original = CacheConfig();
        final modified = original.copyWith(
          maxImageCacheSize: 50 * 1024 * 1024,
          maxCacheAgeDays: 7,
        );

        expect(modified.maxImageCacheSize, 50 * 1024 * 1024);
        expect(modified.maxVideoCacheSize, original.maxVideoCacheSize);
        expect(modified.maxCacheAgeDays, 7);
        expect(modified.enableAutoCleanup, original.enableAutoCleanup);
        expect(modified.cleanupThreshold, original.cleanupThreshold);
      });

      test('CacheConfig merge works correctly', () {
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
        expect(merged.cleanupThreshold, config2.cleanupThreshold);
        expect(merged.maxCacheAgeDays, config2.maxCacheAgeDays);
      });

      test('CacheConfig equality works correctly', () {
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

      test('CacheConfig toString works correctly', () {
        const config = CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024,
          maxVideoCacheSize: 50 * 1024 * 1024,
          enableAutoCleanup: true,
          cleanupThreshold: 0.7,
          maxCacheAgeDays: 5,
        );

        final str = config.toString();
        expect(str, contains('10.0 MB'));
        expect(str, contains('50.0 MB'));
        expect(str, contains('70%'));
        expect(str, contains('5'));
      });
    });

    group('CacheManager Tests', () {
      test('CacheManager getEffectiveConfig works correctly', () {
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
        expect(effective.enableAutoCleanup, localConfig.enableAutoCleanup);
        expect(effective.cleanupThreshold, localConfig.cleanupThreshold);
      });

      test('CacheManager getEffectiveConfig with null local config', () {
        const globalConfig = CacheConfig(
          maxImageCacheSize: 100 * 1024 * 1024,
          maxVideoCacheSize: 500 * 1024 * 1024,
        );

        CacheManager.instance.updateConfig(globalConfig);
        final effective = CacheManager.instance.getEffectiveConfig(null);

        expect(effective, equals(globalConfig));
      });

      test('CacheManager streaming methods work correctly', () async {
        // Test preloadVideoWithStreaming
        await CacheManager.preloadVideoWithStreaming(
          'https://example.com/test.mp4',
        );

        // Test getVideoStreamingInfo
        final info = await CacheManager.getVideoStreamingInfo(
          'https://example.com/test.mp4',
        );
        expect(info, contains('isCached'));
        expect(info, contains('shouldUseStreaming'));
        expect(info, contains('recommendedApproach'));
      });

      test('CacheManager video cache methods work correctly', () async {
        // Test cacheVideo (mock test)
        final result = await CacheManager.cacheVideo(
          'https://example.com/test.mp4',
        );
        // Result can be null if network fails, but method should not throw
        expect(result, anyOf(isA<String>(), isNull));

        // Test getCachedVideoPath
        final path = await CacheManager.getCachedVideoPath(
          'https://example.com/test.mp4',
        );
        // Path can be null if not cached, but method should not throw
        expect(path, anyOf(isA<String>(), isNull));

        // Test preloadVideosWithStreaming
        await CacheManager.preloadVideosWithStreaming([
          'https://example.com/test1.mp4',
          'https://example.com/test2.mp4',
        ]);
      });

      test('CacheManager refresh methods work correctly', () async {
        // Test refreshImage
        await CacheManager.refreshImage(
          'https://example.com/test.jpg',
          preloadAfterClear: false,
        );

        // Test refreshVideo
        await CacheManager.refreshVideo(
          'https://example.com/test.mp4',
          preloadAfterClear: false,
        );

        // Test refreshImages
        await CacheManager.refreshImages([
          'https://example.com/test1.jpg',
          'https://example.com/test2.jpg',
        ], preloadAfterClear: false);

        // Test refreshVideos
        await CacheManager.refreshVideos([
          'https://example.com/test1.mp4',
          'https://example.com/test2.mp4',
        ], preloadAfterClear: false);
      });
    });

    testWidgets('ImageDisplayWidget with cache disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageDisplayWidget(
              imageSource: 'https://example.com/test.jpg',
              disableCache: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ImageDisplayWidget), findsOneWidget);
    });

    testWidgets('VideoDisplayWidget with cache disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoDisplayWidget(
              videoSource: 'https://example.com/test.mp4',
              disableCache: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(VideoDisplayWidget), findsOneWidget);
    });
  });
}
