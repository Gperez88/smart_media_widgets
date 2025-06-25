import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

class AudioPlayerWidgetExample extends StatelessWidget {
  const AudioPlayerWidgetExample({super.key});

  static const List<String> _remoteAudios = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Player Examples',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Basic remote audio examples
          const Text(
            'Remote Audio Players',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._remoteAudios.map(
            (url) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AudioPlayerWidget(
                audioSource: url,
                width: double.infinity,
                height: 100,
                color: Colors.blueAccent,
                playIcon: Icons.play_arrow_rounded,
                pauseIcon: Icons.pause_rounded,
                borderRadius: BorderRadius.circular(20),
                onAudioLoaded: () => debugPrint('Remote audio loaded!'),
                onAudioError: (err) => debugPrint('Remote audio error: $err'),
                localCacheConfig: const CacheConfig(
                  maxAudioCacheSize: 30 * 1024 * 1024,
                ),
                showLoadingIndicator: true,
                showSeekLine: true,
                showDuration: true,
                showPosition: true,
                useBubbleStyle: true,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Custom styled audio player
          const Text(
            'Custom Styled Audio Player',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          AudioPlayerWidget(
            audioSource: _remoteAudios.first,
            width: double.infinity,
            height: 120,
            color: Colors.deepPurple,
            backgroundColor: Colors.deepPurple.withValues(alpha: 0.9),
            playIcon: Icons.play_circle_fill,
            pauseIcon: Icons.pause_circle_filled,
            borderRadius: BorderRadius.circular(25),
            onAudioLoaded: () => debugPrint('Custom styled audio loaded!'),
            onAudioError: (err) =>
                debugPrint('Custom styled audio error: $err'),
            showLoadingIndicator: true,
            showSeekLine: false,
            showDuration: true,
            showPosition: true,
            timeTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            useBubbleStyle: true,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),

          const SizedBox(height: 24),

          // Minimal audio player
          const Text(
            'Minimal Audio Player',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          AudioPlayerWidget(
            audioSource: _remoteAudios[1],
            width: double.infinity,
            height: 80,
            color: Colors.green,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            onAudioLoaded: () => debugPrint('Minimal audio loaded!'),
            onAudioError: (err) => debugPrint('Minimal audio error: $err'),
            showLoadingIndicator: false,
            showSeekLine: false,
            showDuration: false,
            showPosition: false,
            useBubbleStyle: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),

          const SizedBox(height: 24),

          // Note about local audio
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 Note: Local Audio Testing',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'To test with local audio files, place an audio file in your assets folder and update the path in the code. The AudioPlayerWidget supports both local and remote audio sources with full caching capabilities.',
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
