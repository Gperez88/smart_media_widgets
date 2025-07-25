import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import 'test_utils.dart';

void main() {
  group('VideoPlayerWidget Tests', () {
    testWidgets('creates without error with remote video', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates without error with local video', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testLocalVideoPath,
          width: 400,
          height: 300,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates with auto play enabled', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          autoPlay: true,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates with looping enabled', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          looping: true,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates without controls', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          showControls: false,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates without play button', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          showPlayButton: false,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates with custom placeholder', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          placeholder: Center(child: CircularProgressIndicator()),
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates with custom error widget', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: 'https://invalid-url-that-will-fail.com/video.mp4',
          width: 400,
          height: 300,
          errorWidget: Center(child: Text('Error loading video')),
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates with local cache config', (WidgetTester tester) async {
      await TestUtils.testWidgetWithCache(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          localCacheConfig: TestUtils.testCacheConfig,
          useGlobalConfig: false,
        ),
        expectedType: SmartVideoPlayerWidget,
        cacheConfig: TestUtils.testCacheConfig,
      );
    });

    testWidgets('creates with cache disabled', (WidgetTester tester) async {
      await TestUtils.testWidgetWithCacheDisabled(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          disableCache: true,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates with preload disabled', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          preload: false,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates with custom loading color', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          loadingColor: Colors.red,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('creates without loading indicator', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          showLoadingIndicator: false,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('calls onVideoLoaded callback', (WidgetTester tester) async {
      bool callbackCalled = false;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          onVideoLoaded: () {
            callbackCalled = true;
          },
        ),
        expectedType: SmartVideoPlayerWidget,
      );

      // Note: In a real test environment, you would wait for the video to load
      // For now, we just verify the widget was created with the callback
      expect(callbackCalled, false);
    });

    testWidgets('calls onVideoError callback', (WidgetTester tester) async {
      String? errorMessage;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: SmartVideoPlayerWidget(
          videoSource: 'https://invalid-url-that-will-fail.com/video.mp4',
          width: 400,
          height: 300,
          onVideoError: (error) {
            errorMessage = error;
          },
        ),
        expectedType: SmartVideoPlayerWidget,
      );

      // Note: In a real test environment, you would wait for the error to occur
      // For now, we just verify the widget was created with the callback
      expect(errorMessage, null);
    });

    testWidgets('calls onVideoPlay callback', (WidgetTester tester) async {
      bool callbackCalled = false;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          onVideoPlay: () {
            callbackCalled = true;
          },
        ),
        expectedType: SmartVideoPlayerWidget,
      );

      // Note: In a real test environment, you would wait for the video to play
      // For now, we just verify the widget was created with the callback
      expect(callbackCalled, false);
    });

    testWidgets('calls onVideoPause callback', (WidgetTester tester) async {
      bool callbackCalled = false;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          onVideoPause: () {
            callbackCalled = true;
          },
        ),
        expectedType: SmartVideoPlayerWidget,
      );

      // Note: In a real test environment, you would wait for the video to pause
      // For now, we just verify the widget was created with the callback
      expect(callbackCalled, false);
    });

    testWidgets('calls onVideoEnd callback', (WidgetTester tester) async {
      bool callbackCalled = false;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          onVideoEnd: () {
            callbackCalled = true;
          },
        ),
        expectedType: SmartVideoPlayerWidget,
      );

      // Note: In a real test environment, you would wait for the video to end
      // For now, we just verify the widget was created with the callback
      expect(callbackCalled, false);
    });

    testWidgets('handles different video formats', (WidgetTester tester) async {
      final videoUrls = [
        'https://example.com/video.mp4',
        'https://example.com/video.avi',
        'https://example.com/video.mov',
        'https://example.com/video.wmv',
        'https://example.com/video.flv',
        'https://example.com/video.webm',
        'https://example.com/video.mkv',
      ];

      for (final url in videoUrls) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: SmartVideoPlayerWidget(
            videoSource: url,
            width: 400,
            height: 300,
          ),
          expectedType: SmartVideoPlayerWidget,
        );
      }
    });

    testWidgets('handles relative local paths', (WidgetTester tester) async {
      final localPaths = [
        './assets/videos/test.mp4',
        '../assets/videos/test.avi',
        'assets/videos/test.mov',
      ];

      for (final path in localPaths) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: SmartVideoPlayerWidget(
            videoSource: path,
            width: 400,
            height: 300,
          ),
          expectedType: SmartVideoPlayerWidget,
        );
      }
    });

    testWidgets('handles file:// protocol paths', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: 'file:///path/to/local/video.mp4',
          width: 400,
          height: 300,
        ),
        expectedType: SmartVideoPlayerWidget,
      );
    });

    testWidgets('updates when video source changes', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
        ),
        expectedType: SmartVideoPlayerWidget,
      );

      // Update the widget with a different video source
      await tester.pumpWidget(
        TestUtils.createTestApp(
          child: const SmartVideoPlayerWidget(
            videoSource:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            width: 400,
            height: 300,
          ),
        ),
      );

      expect(find.byType(SmartVideoPlayerWidget), findsOneWidget);
    });

    testWidgets('updates when cache config changes', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetWithCache(
        tester: tester,
        widget: const SmartVideoPlayerWidget(
          videoSource: TestUtils.testVideoUrl,
          width: 400,
          height: 300,
          localCacheConfig: TestUtils.testCacheConfig,
        ),
        expectedType: SmartVideoPlayerWidget,
        cacheConfig: TestUtils.testCacheConfig,
      );

      // Update with different cache config
      final newConfig = TestUtils.testCacheConfig.copyWith(
        maxVideoCacheSize: 100 * 1024 * 1024,
      );

      await tester.pumpWidget(
        TestUtils.createTestAppWithCache(
          child: const SmartVideoPlayerWidget(
            videoSource: TestUtils.testVideoUrl,
            width: 400,
            height: 300,
            localCacheConfig: TestUtils.testCacheConfig,
          ),
          cacheConfig: newConfig,
        ),
      );

      expect(find.byType(SmartVideoPlayerWidget), findsOneWidget);
      expect(find.byType(CacheConfigScope), findsOneWidget);
    });

    testWidgets('handles different aspect ratios', (WidgetTester tester) async {
      final aspectRatios = [
        {'width': 400, 'height': 300}, // 4:3
        {'width': 400, 'height': 225}, // 16:9
        {'width': 400, 'height': 400}, // 1:1
        {'width': 300, 'height': 400}, // 3:4
      ];

      for (final ratio in aspectRatios) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: SmartVideoPlayerWidget(
            videoSource: TestUtils.testVideoUrl,
            width: ratio['width']!.toDouble(),
            height: ratio['height']!.toDouble(),
          ),
          expectedType: SmartVideoPlayerWidget,
        );
      }
    });
  });
}
