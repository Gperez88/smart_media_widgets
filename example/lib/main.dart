import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';
import 'android_buffer_example.dart';

import 'components/audio_player_widget.dart';
import 'components/cache_config_widget.dart';
import 'components/image_display_widget.dart';
import 'components/video_display_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Media Widgets Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ImageDisplayExample(),
    const VideoPlayerExample(),
    const AudioPlayerExample(),
    const AndroidBufferExample(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Smart Media Widgets Example'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Images'),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.audiotrack), label: 'Audio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Android Config',
          ),
        ],
      ),
    );
  }
}

class ImageDisplayExample extends StatelessWidget {
  const ImageDisplayExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image Display Examples',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const SmartImageDisplayWidget(
            imageSource: 'https://picsum.photos/400/300?random=1',
            height: 200,
          ),
          const SizedBox(height: 16),
          const SmartImageDisplayWidget(
            imageSource: 'https://picsum.photos/400/300?random=2',
            height: 200,
          ),
        ],
      ),
    );
  }
}

class VideoPlayerExample extends StatelessWidget {
  const VideoPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Player Examples',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SmartVideoPlayerWidget(
              videoSource:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            ),
          ),
        ],
      ),
    );
  }
}

class AudioPlayerExample extends StatelessWidget {
  const AudioPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio Player Examples',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Audio Global (enableGlobal=true)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global Audio Player (enableGlobal=true)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SmartAudioPlayerWidget(
                    audioSource:
                        'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                    enableGlobal: true,
                    title: 'Bell Sound (Global)',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Audio Local (enableGlobal=false)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Audio Player (enableGlobal=false)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SmartAudioPlayerWidget(
                    audioSource:
                        'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                    enableGlobal: false,
                    title: 'Bell Sound (Local)',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Multiple Global Audios (only one can play at a time)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multiple Global Audios (Exclusive Playback)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only one global audio can play at a time. When you play one, the others will pause automatically.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const SmartAudioPlayerWidget(
                    audioSource:
                        'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                    enableGlobal: true,
                    title: 'Global Audio 1',
                  ),
                  const SizedBox(height: 8),
                  const SmartAudioPlayerWidget(
                    audioSource:
                        'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                    enableGlobal: true,
                    title: 'Global Audio 2',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Multiple Local Audios (can play simultaneously)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multiple Local Audios (Simultaneous Playback)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Local audios can play simultaneously without affecting each other.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const SmartAudioPlayerWidget(
                    audioSource:
                        'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                    enableGlobal: false,
                    title: 'Local Audio 1',
                  ),
                  const SizedBox(height: 8),
                  const SmartAudioPlayerWidget(
                    audioSource:
                        'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                    enableGlobal: false,
                    title: 'Local Audio 2',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
