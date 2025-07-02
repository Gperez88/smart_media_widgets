import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

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
  CacheConfig _currentCacheConfig = const CacheConfig();

  @override
  void initState() {
    super.initState();
    // Initialize with custom cache config
    _currentCacheConfig = const CacheConfig(
      maxImageCacheSize: 150 * 1024 * 1024, // 150MB
      maxVideoCacheSize: 750 * 1024 * 1024, // 750MB
      enableAutoCleanup: true,
      cleanupThreshold: 0.6, // 60%
      maxCacheAgeDays: 7, // 7 days
    );
    CacheManager.instance.updateConfig(_currentCacheConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Smart Media Widgets Example'),
      ),
      body: Column(
        children: [
          // Global Audio Player Overlay - appears when global audio is playing
          const GlobalAudioPlayerOverlay(
            backgroundColor: Color(0xFF4A4A4A), // Dark gray like WhatsApp
            showCloseButton: true,
            closeIcon: Icons.close,
            showSpeedButton: true,
          ),

          // Main content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const ImageDisplayWidgetExample(),
                const VideoDisplayWidgetExample(),
                const AudioPlayerWidgetExample(),
                const CacheConfigWidget(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Images'),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.audiotrack), label: 'Audio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cache Config',
          ),
        ],
      ),
    );
  }
}
