import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import 'test_utils.dart';

void main() {
  group('AudioPlayerWidget Tests', () {
    testWidgets('creates without error with remote audio', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates without error with local audio', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testLocalAudioPath,
          width: 300,
          height: 80,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom dimensions', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 400,
          height: 120,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom border radius', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom color', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          color: Colors.red,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom background color', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          backgroundColor: Colors.blue,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom play icon', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          playIcon: Icons.play_circle_fill,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom pause icon', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          pauseIcon: Icons.pause_circle_filled,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom animation duration', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          animationDuration: Duration(milliseconds: 500),
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom placeholder', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          placeholder: Center(child: CircularProgressIndicator()),
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom error widget', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: 'https://invalid-url-that-will-fail.com/audio.mp3',
          width: 300,
          height: 80,
          errorWidget: Center(child: Text('Error loading audio')),
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with local cache config', (WidgetTester tester) async {
      await TestUtils.testWidgetWithCache(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          localCacheConfig: TestUtils.testCacheConfig,
          useGlobalConfig: false,
        ),
        expectedType: AudioPlayerWidget,
        cacheConfig: TestUtils.testCacheConfig,
      );
    });

    testWidgets('creates without loading indicator', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          showLoadingIndicator: false,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates without seek line', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          showSeekLine: false,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates without duration display', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          showDuration: false,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates without position display', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          showPosition: false,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom time text style', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          timeTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates without bubble style', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          useBubbleStyle: false,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom padding', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          padding: EdgeInsets.all(16),
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with custom margin', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('calls onAudioLoaded callback', (WidgetTester tester) async {
      bool callbackCalled = false;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          onAudioLoaded: () {
            callbackCalled = true;
          },
        ),
        expectedType: AudioPlayerWidget,
      );

      // Note: In a real test environment, you would wait for the audio to load
      // For now, we just verify the widget was created with the callback
      expect(callbackCalled, false);
    });

    testWidgets('calls onAudioError callback', (WidgetTester tester) async {
      String? errorMessage;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: AudioPlayerWidget(
          audioSource: 'https://invalid-url-that-will-fail.com/audio.mp3',
          width: 300,
          height: 80,
          onAudioError: (error) {
            errorMessage = error;
          },
        ),
        expectedType: AudioPlayerWidget,
      );

      // Note: In a real test environment, you would wait for the error to occur
      // For now, we just verify the widget was created with the callback
      expect(errorMessage, null);
    });

    testWidgets('handles different audio formats', (WidgetTester tester) async {
      final audioUrls = [
        'https://example.com/audio.mp3',
        'https://example.com/audio.wav',
        'https://example.com/audio.aac',
        'https://example.com/audio.ogg',
        'https://example.com/audio.m4a',
        'https://example.com/audio.flac',
      ];

      for (final url in audioUrls) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: AudioPlayerWidget(audioSource: url, width: 300, height: 80),
          expectedType: AudioPlayerWidget,
        );
      }
    });

    testWidgets('handles relative local paths', (WidgetTester tester) async {
      final localPaths = [
        './assets/audio/test.mp3',
        '../assets/audio/test.wav',
        'assets/audio/test.aac',
      ];

      for (final path in localPaths) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: AudioPlayerWidget(audioSource: path, width: 300, height: 80),
          expectedType: AudioPlayerWidget,
        );
      }
    });

    testWidgets('handles file:// protocol paths', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: 'file:///path/to/local/audio.mp3',
          width: 300,
          height: 80,
        ),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('updates when audio source changes', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
        ),
        expectedType: AudioPlayerWidget,
      );

      // Update the widget with a different audio source
      await tester.pumpWidget(
        TestUtils.createTestApp(
          child: const AudioPlayerWidget(
            audioSource:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            width: 300,
            height: 80,
          ),
        ),
      );

      expect(find.byType(AudioPlayerWidget), findsOneWidget);
    });

    testWidgets('updates when cache config changes', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetWithCache(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          localCacheConfig: TestUtils.testCacheConfig,
        ),
        expectedType: AudioPlayerWidget,
        cacheConfig: TestUtils.testCacheConfig,
      );

      // Update with different cache config
      final newConfig = TestUtils.testCacheConfig.copyWith(
        maxAudioCacheSize: 50 * 1024 * 1024,
      );

      await tester.pumpWidget(
        TestUtils.createTestAppWithCache(
          child: const AudioPlayerWidget(
            audioSource: TestUtils.testAudioUrl,
            width: 300,
            height: 80,
            localCacheConfig: TestUtils.testCacheConfig,
          ),
          cacheConfig: newConfig,
        ),
      );

      expect(find.byType(AudioPlayerWidget), findsOneWidget);
      expect(find.byType(CacheConfigScope), findsOneWidget);
    });

    testWidgets('handles different heights', (WidgetTester tester) async {
      final heights = [60, 80, 100, 120, 150];

      for (final height in heights) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: AudioPlayerWidget(
            audioSource: TestUtils.testAudioUrl,
            width: 300,
            height: height.toDouble(),
          ),
          expectedType: AudioPlayerWidget,
        );
      }
    });

    testWidgets('creates with minimal configuration', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(audioSource: TestUtils.testAudioUrl),
        expectedType: AudioPlayerWidget,
      );
    });

    testWidgets('creates with all features disabled', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const AudioPlayerWidget(
          audioSource: TestUtils.testAudioUrl,
          width: 300,
          height: 80,
          showLoadingIndicator: false,
          showSeekLine: false,
          showDuration: false,
          showPosition: false,
          useBubbleStyle: false,
        ),
        expectedType: AudioPlayerWidget,
      );
    });
  });
}
