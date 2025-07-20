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

          // Global Player Examples
          const Text(
            'Global Audio Players (WhatsApp Style)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'These players use global mode. When playing, a persistent player will appear at the top.',
              style: TextStyle(fontSize: 12, color: Colors.purple),
            ),
          ),
          const SizedBox(height: 12),

          // Global Player 1 con leftWidget (avatar)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SmartAudioPlayerWidget(
              audioSource: _remoteAudios[0],
              width: double.infinity,
              height: 100,
              color: Colors.blueAccent,
              playIcon: Icons.play_arrow_rounded,
              pauseIcon: Icons.pause_rounded,
              borderRadius: BorderRadius.circular(20),
              showLoadingIndicator: true,
              showDuration: true,
              showPosition: true,
              useBubbleStyle: true,
              enableGlobal: true,
              title: 'Audio name',
              // Example: circular avatar on the left
              leftWidget: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/men/32.jpg',
                ),
              ),
            ),
          ),

          // Global Player 2 con rightWidget (icono de micrófono)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SmartAudioPlayerWidget(
              audioSource: _remoteAudios[1],
              width: double.infinity,
              height: 100,
              color: Colors.green,
              playIcon: Icons.play_arrow_rounded,
              pauseIcon: Icons.pause_rounded,
              borderRadius: BorderRadius.circular(20),
              showLoadingIndicator: true,
              showDuration: true,
              showPosition: true,
              useBubbleStyle: true,
              enableGlobal: true,
              title: 'Same audio, different instance',
              // Example: microphone icon on the right
              rightWidget: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/men/32.jpg',
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Local Player Example
          const Text(
            'Local Audio Player (Traditional Mode)',
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
              'This player works in traditional local mode (without global player).',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 12),

          // Local Player
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SmartAudioPlayerWidget(
              audioSource: _remoteAudios[2],
              width: double.infinity,
              height: 100,
              color: Colors.orange,
              playIcon: Icons.play_arrow_rounded,
              pauseIcon: Icons.pause_rounded,
              borderRadius: BorderRadius.circular(20),
              showLoadingIndicator: true,
              showDuration: true,
              showPosition: true,
              useBubbleStyle: true,
            ),
          ),

          const SizedBox(height: 24),

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
                  '🎯 Test Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Play one of the global audios (blue or green) - the global player will appear at the top\n'
                  '2. Navigate between tabs to see that the global player persists\n'
                  '3. Control the audio from any player (local or global)\n'
                  '4. Test the local player (orange) - works independently',
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
