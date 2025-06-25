import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

class ImageDisplayWidgetExample extends StatelessWidget {
  const ImageDisplayWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image Display Examples',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ImageDisplayWidget(
            imageSource: 'https://picsum.photos/400/300?random=1',
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
            onImageLoaded: () => debugPrint('Remote image loaded'),
          ),
          const SizedBox(height: 16),
          ImageDisplayWidget(
            imageSource: '/path/to/local/image.jpg',
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
            onImageLoaded: () => debugPrint('Local image loaded'),
          ),
          const SizedBox(height: 16),
          ImageDisplayWidget(
            imageSource: 'https://picsum.photos/400/300?random=2',
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
            localCacheConfig: const CacheConfig(
              maxImageCacheSize: 5 * 1024 * 1024,
            ),
            useGlobalConfig: false,
            onImageLoaded: () =>
                debugPrint('Image with local cache config loaded'),
          ),
        ],
      ),
    );
  }
}
