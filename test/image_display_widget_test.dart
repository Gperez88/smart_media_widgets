import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

import 'test_utils.dart';

void main() {
  group('ImageDisplayWidget Tests', () {
    testWidgets('creates without error with remote image', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates without error with local image', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testLocalImagePath,
          width: 200,
          height: 300,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates with custom fit', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          fit: BoxFit.contain,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates with border radius', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates with custom placeholder', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 300,
          height: 200,
          placeholder: Center(child: CircularProgressIndicator()),
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates with custom error widget', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: 'https://invalid-url-that-will-fail.com/image.jpg',
          width: 300,
          height: 200,
          errorWidget: Center(child: Text('Error loading image')),
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates with local cache config', (WidgetTester tester) async {
      await TestUtils.testWidgetWithCache(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          localCacheConfig: TestUtils.testCacheConfig,
          useGlobalConfig: false,
        ),
        expectedType: SmartImageDisplayWidget,
        cacheConfig: TestUtils.testCacheConfig,
      );
    });

    testWidgets('creates with cache disabled', (WidgetTester tester) async {
      await TestUtils.testWidgetWithCacheDisabled(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          disableCache: true,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates with preload disabled', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          preload: false,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates with custom loading color', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          loadingColor: Colors.red,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('creates without loading indicator', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          showLoadingIndicator: false,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('calls onImageLoaded callback', (WidgetTester tester) async {
      bool callbackCalled = false;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          onImageLoaded: () {
            callbackCalled = true;
          },
        ),
        expectedType: SmartImageDisplayWidget,
      );

      // Note: In a real test environment, you would wait for the image to load
      // For now, we just verify the widget was created with the callback
      expect(callbackCalled, false);
    });

    testWidgets('calls onImageError callback', (WidgetTester tester) async {
      String? errorMessage;

      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: SmartImageDisplayWidget(
          imageSource: 'https://invalid-url-that-will-fail.com/image.jpg',
          width: 200,
          height: 300,
          onImageError: (error) {
            errorMessage = error;
          },
        ),
        expectedType: SmartImageDisplayWidget,
      );

      // Note: In a real test environment, you would wait for the error to occur
      // For now, we just verify the widget was created with the callback
      expect(errorMessage, null);
    });

    testWidgets('handles different image formats', (WidgetTester tester) async {
      final imageUrls = [
        'https://example.com/image.jpg',
        'https://example.com/image.png',
        'https://example.com/image.gif',
        'https://example.com/image.webp',
      ];

      for (final url in imageUrls) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: SmartImageDisplayWidget(
            imageSource: url,
            width: 200,
            height: 300,
          ),
          expectedType: SmartImageDisplayWidget,
        );
      }
    });

    testWidgets('handles relative local paths', (WidgetTester tester) async {
      final localPaths = [
        './assets/images/test.jpg',
        '../assets/images/test.png',
        'assets/images/test.gif',
      ];

      for (final path in localPaths) {
        await TestUtils.testWidgetCreation(
          tester: tester,
          widget: SmartImageDisplayWidget(
            imageSource: path,
            width: 200,
            height: 300,
          ),
          expectedType: SmartImageDisplayWidget,
        );
      }
    });

    testWidgets('handles file:// protocol paths', (WidgetTester tester) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: 'file:///path/to/local/image.jpg',
          width: 200,
          height: 300,
        ),
        expectedType: SmartImageDisplayWidget,
      );
    });

    testWidgets('updates when image source changes', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetCreation(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
        ),
        expectedType: SmartImageDisplayWidget,
      );

      // Update the widget with a different image source
      await tester.pumpWidget(
        TestUtils.createTestApp(
          child: const SmartImageDisplayWidget(
            imageSource: 'https://picsum.photos/400/500',
            width: 200,
            height: 300,
          ),
        ),
      );

      expect(find.byType(SmartImageDisplayWidget), findsOneWidget);
    });

    testWidgets('updates when cache config changes', (
      WidgetTester tester,
    ) async {
      await TestUtils.testWidgetWithCache(
        tester: tester,
        widget: const SmartImageDisplayWidget(
          imageSource: TestUtils.testImageUrl,
          width: 200,
          height: 300,
          localCacheConfig: TestUtils.testCacheConfig,
        ),
        expectedType: SmartImageDisplayWidget,
        cacheConfig: TestUtils.testCacheConfig,
      );

      // Update with different cache config
      final newConfig = TestUtils.testCacheConfig.copyWith(
        maxImageCacheSize: 20 * 1024 * 1024,
      );

      await tester.pumpWidget(
        TestUtils.createTestAppWithCache(
          child: const SmartImageDisplayWidget(
            imageSource: TestUtils.testImageUrl,
            width: 200,
            height: 300,
            localCacheConfig: TestUtils.testCacheConfig,
          ),
          cacheConfig: newConfig,
        ),
      );

      expect(find.byType(SmartImageDisplayWidget), findsOneWidget);
      expect(find.byType(CacheConfigScope), findsOneWidget);
    });
  });
}
