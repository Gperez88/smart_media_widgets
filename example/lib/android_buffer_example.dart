import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

/// Example demonstrating how to use Android Buffer Configuration
/// to fix the buffer overflow issues seen in the logs
class AndroidBufferExample extends StatefulWidget {
  const AndroidBufferExample({super.key});

  @override
  State<AndroidBufferExample> createState() => _AndroidBufferExampleState();
}

class _AndroidBufferExampleState extends State<AndroidBufferExample> {
  AndroidBufferConfig _currentConfig = const AndroidBufferConfig();
  String _configType = 'Default';

  @override
  void initState() {
    super.initState();
    _initializeAndroidConfig();
  }

  void _initializeAndroidConfig() {
    if (Platform.isAndroid) {
      // Use conservative configuration to prevent buffer issues
      AndroidBufferManager().useConservativeConfig();
      _currentConfig = AndroidBufferManager().config;
      _configType = 'Conservative';
    }
  }

  void _setConservativeConfig() {
    if (Platform.isAndroid) {
      AndroidBufferManager().useConservativeConfig();
      setState(() {
        _currentConfig = AndroidBufferManager().config;
        _configType = 'Conservative';
      });
    }
  }

  void _setOptimizedConfig() {
    if (Platform.isAndroid) {
      AndroidBufferManager().useOptimizedConfig();
      setState(() {
        _currentConfig = AndroidBufferManager().config;
        _configType = 'Optimized';
      });
    }
  }

  void _setCustomConfig() {
    if (Platform.isAndroid) {
      final customConfig = AndroidBufferConfig(
        maxVideoBuffers: 2,
        maxAudioBuffers: 3,
        videoBufferSize: 2 * 1024 * 1024, // 2MB
        audioBufferSize: 1024 * 1024, // 1MB
        maxConcurrentVideoPlayers: 1,
        maxConcurrentAudioPlayers: 2,
      );
      AndroidBufferManager().updateConfig(customConfig);
      setState(() {
        _currentConfig = AndroidBufferManager().config;
        _configType = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android Buffer Configuration Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Section
            _buildConfigurationSection(),
            const SizedBox(height: 24),

            // Video Player Section
            _buildVideoPlayerSection(),
            const SizedBox(height: 24),

            // Audio Player Section
            _buildAudioPlayerSection(),
            const SizedBox(height: 24),

            // Information Section
            _buildInformationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Android Buffer Configuration',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // Current Configuration Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Config: $_configType',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Video Buffers: ${_currentConfig.maxVideoBuffers}'),
                  Text('Audio Buffers: ${_currentConfig.maxAudioBuffers}'),
                  Text(
                    'Video Buffer Size: ${_currentConfig.videoBufferSize ~/ 1024}KB',
                  ),
                  Text(
                    'Audio Buffer Size: ${_currentConfig.audioBufferSize ~/ 1024}KB',
                  ),
                  Text(
                    'Max Concurrent Video: ${_currentConfig.maxConcurrentVideoPlayers}',
                  ),
                  Text(
                    'Max Concurrent Audio: ${_currentConfig.maxConcurrentAudioPlayers}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Configuration Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setConservativeConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Conservative'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setOptimizedConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Optimized'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setCustomConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Custom'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayerSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Player with Android Config',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SmartVideoPlayerWidget(
                videoSource:
                    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                onVideoError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video Error: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                onVideoLoaded: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video loaded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Player with Android Config',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            SmartAudioPlayerWidget(
              audioSource:
                  'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
              onAudioError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Audio Error: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              onAudioLoaded: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Audio loaded successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Android Buffer Issues',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'This example demonstrates how to fix the Android buffer issues:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const Text('• ImageReader buffer overflow'),
            const Text('• CCodec buffer management problems'),
            const Text('• BufferPool saturation'),
            const SizedBox(height: 16),

            const Text(
              'The conservative configuration is recommended for devices experiencing these issues.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
