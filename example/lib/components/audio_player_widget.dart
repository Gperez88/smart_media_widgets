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
              'Estos reproductores usan el modo global. Al reproducir aparecerá un reproductor persistente arriba.',
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
              title: 'Nombre del audio',
              // Ejemplo: avatar circular a la izquierda
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
              title: 'Mismo audio, diferente instancia',
              // Ejemplo: icono de micrófono a la derecha
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
              'Este reproductor funciona en modo local tradicional (sin reproductor global).',
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
                  '🎯 Instrucciones de Prueba',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Reproduce uno de los audios globales (azul o verde) - aparecerá el reproductor global arriba\n'
                  '2. Navega entre tabs para ver que el reproductor global persiste\n'
                  '3. Controla el audio desde cualquier reproductor (local o global)\n'
                  '4. Prueba el reproductor local (naranja) - funciona independientemente',
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
