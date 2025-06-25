import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import 'test_utils.dart';

void main() {
  group('Smart Media Widgets - All Tests', () {
    // Ejecutar pruebas de utilidades
    TestUtils.testMediaUtils();
    TestUtils.testCacheManager();
    TestUtils.runCacheConfigTests();

    group('Integration Tests', () {
      testWidgets('CacheConfigScope provides configuration to children', (
        WidgetTester tester,
      ) async {
        const testConfig = CacheConfig(
          maxImageCacheSize: 15 * 1024 * 1024,
          maxVideoCacheSize: 75 * 1024 * 1024,
          maxAudioCacheSize: 45 * 1024 * 1024,
          enableAutoCleanup: false,
          cleanupThreshold: 0.6,
          maxCacheAgeDays: 5,
        );

        await TestUtils.testWidgetWithCache(
          tester: tester,
          widget: const ImageDisplayWidget(
            imageSource: TestUtils.testImageUrl,
            width: 200,
            height: 300,
          ),
          expectedType: ImageDisplayWidget,
          cacheConfig: testConfig,
        );
      });

      testWidgets('Multiple widgets with different cache configs', (
        WidgetTester tester,
      ) async {
        const imageConfig = CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024,
          maxCacheAgeDays: 1,
        );
        const videoConfig = CacheConfig(
          maxVideoCacheSize: 50 * 1024 * 1024,
          maxCacheAgeDays: 2,
        );
        const audioConfig = CacheConfig(
          maxAudioCacheSize: 30 * 1024 * 1024,
          maxCacheAgeDays: 3,
        );

        await tester.pumpWidget(
          TestUtils.createTestApp(
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  ImageDisplayWidget(
                    imageSource: TestUtils.testImageUrl,
                    width: 200,
                    height: 300,
                    localCacheConfig: imageConfig,
                    useGlobalConfig: false,
                  ),
                  SizedBox(height: 16),
                  VideoPlayerWidget(
                    videoSource: TestUtils.testVideoUrl,
                    width: 400,
                    height: 300,
                    localCacheConfig: videoConfig,
                    useGlobalConfig: false,
                  ),
                  SizedBox(height: 16),
                  AudioPlayerWidget(
                    audioSource: TestUtils.testAudioUrl,
                    width: 300,
                    height: 80,
                    localCacheConfig: audioConfig,
                    useGlobalConfig: false,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(ImageDisplayWidget), findsOneWidget);
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
        expect(find.byType(AudioPlayerWidget), findsOneWidget);
      });

      testWidgets('Widgets with cache disabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  ImageDisplayWidget(
                    imageSource: TestUtils.testImageUrl,
                    width: 200,
                    height: 300,
                    disableCache: true,
                  ),
                  SizedBox(height: 16),
                  VideoPlayerWidget(
                    videoSource: TestUtils.testVideoUrl,
                    width: 400,
                    height: 300,
                    disableCache: true,
                  ),
                  SizedBox(height: 16),
                  AudioPlayerWidget(
                    audioSource: TestUtils.testAudioUrl,
                    width: 300,
                    height: 80,
                  ),
                ],
              ),
            ),
          ),
        );

        // Solo un pump para evitar timeout por animaciones/reproductores
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(ImageDisplayWidget), findsOneWidget);
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
        expect(find.byType(AudioPlayerWidget), findsOneWidget);
      });

      testWidgets('Widgets with global cache config', (
        WidgetTester tester,
      ) async {
        const globalConfig = CacheConfig(
          maxImageCacheSize: 20 * 1024 * 1024,
          maxVideoCacheSize: 100 * 1024 * 1024,
          maxAudioCacheSize: 60 * 1024 * 1024,
          enableAutoCleanup: true,
          cleanupThreshold: 0.7,
          maxCacheAgeDays: 7,
        );

        await tester.pumpWidget(
          TestUtils.createTestAppWithCache(
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  ImageDisplayWidget(
                    imageSource: TestUtils.testImageUrl,
                    width: 200,
                    height: 300,
                  ),
                  SizedBox(height: 16),
                  VideoPlayerWidget(
                    videoSource: TestUtils.testVideoUrl,
                    width: 400,
                    height: 300,
                  ),
                  SizedBox(height: 16),
                  AudioPlayerWidget(
                    audioSource: TestUtils.testAudioUrl,
                    width: 300,
                    height: 80,
                  ),
                ],
              ),
            ),
            cacheConfig: globalConfig,
          ),
        );

        expect(find.byType(ImageDisplayWidget), findsOneWidget);
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
        expect(find.byType(AudioPlayerWidget), findsOneWidget);
        expect(find.byType(CacheConfigScope), findsOneWidget);
      });

      testWidgets('Widgets with mixed local and global configs', (
        WidgetTester tester,
      ) async {
        const globalConfig = CacheConfig(
          maxImageCacheSize: 20 * 1024 * 1024,
          maxVideoCacheSize: 100 * 1024 * 1024,
          maxAudioCacheSize: 60 * 1024 * 1024,
        );
        const localConfig = CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024,
          maxCacheAgeDays: 1,
        );

        await tester.pumpWidget(
          TestUtils.createTestAppWithCache(
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  // Uses local config (overrides global)
                  ImageDisplayWidget(
                    imageSource: TestUtils.testImageUrl,
                    width: 200,
                    height: 300,
                    localCacheConfig: localConfig,
                  ),
                  SizedBox(height: 16),
                  // Uses global config
                  VideoPlayerWidget(
                    videoSource: TestUtils.testVideoUrl,
                    width: 400,
                    height: 300,
                  ),
                  SizedBox(height: 16),
                  // Uses global config
                  AudioPlayerWidget(
                    audioSource: TestUtils.testAudioUrl,
                    width: 300,
                    height: 80,
                  ),
                ],
              ),
            ),
            cacheConfig: globalConfig,
          ),
        );

        expect(find.byType(ImageDisplayWidget), findsOneWidget);
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
        expect(find.byType(AudioPlayerWidget), findsOneWidget);
        expect(find.byType(CacheConfigScope), findsOneWidget);
      });

      testWidgets('Widgets with different media sources', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  // Remote image
                  ImageDisplayWidget(
                    imageSource: TestUtils.testImageUrl,
                    width: 200,
                    height: 300,
                  ),
                  SizedBox(height: 16),
                  // Local image
                  ImageDisplayWidget(
                    imageSource: TestUtils.testLocalImagePath,
                    width: 200,
                    height: 300,
                  ),
                  SizedBox(height: 16),
                  // Remote video
                  VideoPlayerWidget(
                    videoSource: TestUtils.testVideoUrl,
                    width: 400,
                    height: 300,
                  ),
                  SizedBox(height: 16),
                  // Local video
                  VideoPlayerWidget(
                    videoSource: TestUtils.testLocalVideoPath,
                    width: 400,
                    height: 300,
                  ),
                  SizedBox(height: 16),
                  // Remote audio
                  AudioPlayerWidget(
                    audioSource: TestUtils.testAudioUrl,
                    width: 300,
                    height: 80,
                  ),
                  SizedBox(height: 16),
                  // Local audio
                  AudioPlayerWidget(
                    audioSource: TestUtils.testLocalAudioPath,
                    width: 300,
                    height: 80,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(ImageDisplayWidget), findsNWidgets(2));
        expect(find.byType(VideoPlayerWidget), findsNWidgets(2));
        expect(find.byType(AudioPlayerWidget), findsNWidgets(2));
      });

      testWidgets('Widgets with error handling', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  ImageDisplayWidget(
                    imageSource:
                        'https://invalid-url-that-will-fail.com/image.jpg',
                    width: 200,
                    height: 300,
                    errorWidget: Center(child: Text('Image Error')),
                  ),
                  SizedBox(height: 16),
                  VideoPlayerWidget(
                    videoSource:
                        'https://invalid-url-that-will-fail.com/video.mp4',
                    width: 400,
                    height: 300,
                    errorWidget: Center(child: Text('Video Error')),
                  ),
                  SizedBox(height: 16),
                  AudioPlayerWidget(
                    audioSource:
                        'https://invalid-url-that-will-fail.com/audio.mp3',
                    width: 300,
                    height: 80,
                    errorWidget: Center(child: Text('Audio Error')),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(ImageDisplayWidget), findsOneWidget);
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
        expect(find.byType(AudioPlayerWidget), findsOneWidget);
      });

      testWidgets('Widgets with custom placeholders', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          TestUtils.createTestApp(
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  ImageDisplayWidget(
                    imageSource: TestUtils.testImageUrl,
                    width: 200,
                    height: 300,
                    placeholder: Center(child: CircularProgressIndicator()),
                  ),
                  SizedBox(height: 16),
                  VideoPlayerWidget(
                    videoSource: TestUtils.testVideoUrl,
                    width: 400,
                    height: 300,
                    placeholder: Center(child: CircularProgressIndicator()),
                  ),
                  SizedBox(height: 16),
                  AudioPlayerWidget(
                    audioSource: TestUtils.testAudioUrl,
                    width: 300,
                    height: 80,
                    placeholder: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(ImageDisplayWidget), findsOneWidget);
        expect(find.byType(VideoPlayerWidget), findsOneWidget);
        expect(find.byType(AudioPlayerWidget), findsOneWidget);
      });
    });

    group('CacheManager Integration Tests', () {
      test('CacheManager streaming methods work correctly', () async {
        // Test preloadVideoWithStreaming
        await CacheManager.preloadVideoWithStreaming(TestUtils.testVideoUrl);

        // Test getVideoStreamingInfo
        final info = await CacheManager.getVideoStreamingInfo(
          TestUtils.testVideoUrl,
        );
        expect(info, contains('isCached'));
        expect(info, contains('shouldUseStreaming'));
        expect(info, contains('recommendedApproach'));
      });

      test('CacheManager video cache methods work correctly', () async {
        // Test cacheVideo (mock test)
        final result = await CacheManager.cacheVideo(TestUtils.testVideoUrl);
        // Result can be null if network fails, but method should not throw
        expect(result, anyOf(isA<String>(), isNull));

        // Test getCachedVideoPath
        final path = await CacheManager.getCachedVideoPath(
          TestUtils.testVideoUrl,
        );
        // Path can be null if not cached, but method should not throw
        expect(path, anyOf(isA<String>(), isNull));

        // Test preloadVideosWithStreaming
        await CacheManager.preloadVideosWithStreaming([
          TestUtils.testVideoUrl,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        ]);
      });

      test('CacheManager refresh methods work correctly', () async {
        // Test refreshImage
        await CacheManager.refreshImage(
          TestUtils.testImageUrl,
          preloadAfterClear: false,
        );

        // Test refreshVideo
        await CacheManager.refreshVideo(
          TestUtils.testVideoUrl,
          preloadAfterClear: false,
        );

        // Test refreshImages
        await CacheManager.refreshImages([
          TestUtils.testImageUrl,
          'https://picsum.photos/400/500',
        ], preloadAfterClear: false);

        // Test refreshVideos
        await CacheManager.refreshVideos([
          TestUtils.testVideoUrl,
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        ], preloadAfterClear: false);
      });
    });
  });
}
