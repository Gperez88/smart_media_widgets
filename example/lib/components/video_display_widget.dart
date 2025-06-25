import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

class VideoDisplayWidgetExample extends StatelessWidget {
  const VideoDisplayWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Display Examples',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          VideoPlayerWidget(
            videoSource:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            width: double.infinity,
            height: 220,
            autoPlay: false,
            onVideoLoaded: () => debugPrint('Remote video loaded'),
          ),
          const SizedBox(height: 16),

          VideoPlayerWidget(
            videoSource:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            width: double.infinity,
            height: 220,
            localCacheConfig: const CacheConfig(
              maxVideoCacheSize: 50 * 1024 * 1024,
            ),
            useGlobalConfig: false,
            onVideoLoaded: () =>
                debugPrint('Video with local cache config loaded'),
          ),
        ],
      ),
    );
  }
}
