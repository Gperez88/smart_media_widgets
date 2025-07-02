import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

class VideoDisplayWidgetExample extends StatelessWidget {
  const VideoDisplayWidgetExample({super.key});

  static const List<Map<String, String>> _remoteVideos = [
    {
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'title': 'Big Buck Bunny',
      'description': 'Video de demostración - Conejo animado',
    },
    {
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'title': 'Elephant\'s Dream',
      'description': 'Video de demostración - Animación 3D',
    },
    {
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'title': 'For Bigger Blazes',
      'description': 'Video de demostración - Acción',
    },
    {
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
      'title': 'Subaru Outback',
      'description': 'Video de demostración - Automóvil',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Player Examples',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Standard Video Players
          const Text(
            'Standard Video Players',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Videos with progressive playback and automatic background caching.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
          const SizedBox(height: 12),

          // Standard Video Player
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _remoteVideos[0]['title']!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  _remoteVideos[0]['description']!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SmartVideoPlayerWidget(
                  videoSource: _remoteVideos[0]['url']!,
                  width: double.infinity,
                  height: 220,
                  autoPlay: false,
                  showLoadingIndicator: true,
                  onVideoLoaded: () =>
                      debugPrint('${_remoteVideos[0]['title']} loaded!'),
                  onVideoError: (err) =>
                      debugPrint('${_remoteVideos[0]['title']} error: $err'),
                ),
              ],
            ),
          ),

          // Auto-play Video
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _remoteVideos[1]['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AUTO-PLAY',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_remoteVideos[1]['description']} - Inicia automáticamente',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SmartVideoPlayerWidget(
                  videoSource: _remoteVideos[1]['url']!,
                  width: double.infinity,
                  height: 220,
                  autoPlay: true,
                  looping: false,
                  onVideoLoaded: () => debugPrint(
                    '${_remoteVideos[1]['title']} auto-play loaded!',
                  ),
                  onVideoError: (err) =>
                      debugPrint('${_remoteVideos[1]['title']} error: $err'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Custom Cache Configuration
          const Text(
            'Advanced Video Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Video con configuración de cache personalizada y controles avanzados.',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _remoteVideos[2]['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CUSTOM CACHE',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_remoteVideos[2]['description']} - Cache personalizado de 100MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SmartVideoPlayerWidget(
                  videoSource: _remoteVideos[2]['url']!,
                  width: double.infinity,
                  height: 220,
                  autoPlay: false,
                  showLoadingIndicator: true,
                  localCacheConfig: const CacheConfig(
                    maxVideoCacheSize: 100 * 1024 * 1024, // 100MB
                    enableAutoCleanup: true,
                    cleanupThreshold: 0.7,
                    maxCacheAgeDays: 30,
                  ),
                  useGlobalConfig: false,
                  onVideoLoaded: () => debugPrint(
                    '${_remoteVideos[2]['title']} with custom cache loaded!',
                  ),
                  onVideoError: (err) =>
                      debugPrint('${_remoteVideos[2]['title']} error: $err'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Compact Video Player
          const Text(
            'Compact Video Player',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Reproductor más pequeño para espacios reducidos.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _remoteVideos[3]['title']!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_remoteVideos[3]['description']} - Formato compacto',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SmartVideoPlayerWidget(
                  videoSource: _remoteVideos[3]['url']!,
                  width: double.infinity,
                  height: 160, // Smaller height
                  autoPlay: false,
                  onVideoLoaded: () => debugPrint(
                    '${_remoteVideos[3]['title']} compact loaded!',
                  ),
                  onVideoError: (err) =>
                      debugPrint('${_remoteVideos[3]['title']} error: $err'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Video con error forzado (URL inválida)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video with forced error (invalid URL)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text('Demonstrates visual error handling.'),
                const SizedBox(height: 8),
                SmartVideoPlayerWidget(
                  videoSource: 'https://url-invalida-404.com/video.mp4',
                  width: double.infinity,
                  height: 160,
                  errorWidget: Container(
                    color: Colors.red.withValues(alpha: 0.1),
                    child: const Center(
                      child: Text(
                        'Failed to load video',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  onVideoError: (err) => debugPrint('Forced video error: $err'),
                ),
              ],
            ),
          ),

          // Video con overlay de ícono
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SmartVideoPlayerWidget(
                  videoSource: _remoteVideos[1]['url']!,
                  width: double.infinity,
                  height: 180,
                  autoPlay: false,
                  onVideoLoaded: () => debugPrint('Video with overlay loaded!'),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          // Video local (comentado si no hay asset)
          /*
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Video local', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('Ejemplo de video desde asset local.'),
                const SizedBox(height: 8),
                SmartVideoPlayerWidget(
                  videoSource: 'assets/videos/ejemplo.mp4',
                  width: double.infinity,
                  height: 160,
                  onVideoLoaded: () => debugPrint('Video local cargado!'),
                  onVideoError: (err) => debugPrint('Error video local: $err'),
                ),
              ],
            ),
          ),
          */

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎥 VideoPlayerWidget Features',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Progressive playback (starts while downloading)\n'
                  '• Automatic background caching\n'
                  '• Full video controls (play, pause, seek, volume)\n'
                  '• Support for auto-play and looping\n'
                  '• Customizable cache configuration\n'
                  '• Flexible aspect ratio and sizing\n'
                  '• Robust network error handling',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
