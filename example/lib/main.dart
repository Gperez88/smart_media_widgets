import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

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

  final List<String> _remoteImages = [
    'https://picsum.photos/400/300?random=1',
    'https://picsum.photos/400/300?random=2',
    'https://picsum.photos/400/300?random=3',
    'https://picsum.photos/400/300?random=4',
    'https://picsum.photos/400/300?random=5',
    'https://picsum.photos/400/300?random=6',
    'https://picsum.photos/400/300?random=7',
    'https://picsum.photos/400/300?random=8',
    'https://picsum.photos/400/300?random=9',
    'https://picsum.photos/400/300?random=10',
  ];

  final List<String> _remoteVideos = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
  ];

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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildImageExample(),
          _buildVideoExample(),
          _buildCacheExample(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Images'),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.cached), label: 'Cache'),
        ],
      ),
    );
  }

  Widget _buildImageExample() {
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

          // Basic remote images with cache config
          _buildSectionTitle('Basic Remote Images (with Cache Config)'),
          ..._remoteImages.take(3).map((url) => _buildImageExampleItem(url)),

          const SizedBox(height: 24),

          // Cache configuration examples
          _buildSectionTitle('Cache Configuration Examples'),

          // Local config only
          _buildSubsectionTitle('Local Config Only (useGlobalConfig: false)'),
          ImageDisplayWidget(
            imageSource: 'https://picsum.photos/400/300?random=11',
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.circular(8),
            useGlobalConfig: false,
            localCacheConfig: const CacheConfig(
              maxImageCacheSize: 5 * 1024 * 1024, // 5MB
              maxCacheAgeDays: 1, // 1 day
              cleanupThreshold: 0.5, // 50%
            ),
            onImageLoaded: () => log('Local config image loaded'),
          ),

          const SizedBox(height: 16),

          // Context-based configuration
          _buildSubsectionTitle(
            'Context-Based Configuration (CacheConfigScope)',
          ),
          CacheConfigScope(
            config: const CacheConfig(
              maxImageCacheSize: 20 * 1024 * 1024, // 20MB
              maxCacheAgeDays: 14, // 14 days
              enableAutoCleanup: true,
              cleanupThreshold: 0.7, // 70%
            ),
            child: Column(
              children: [
                ImageDisplayWidget(
                  imageSource: 'https://picsum.photos/400/300?random=12',
                  width: double.infinity,
                  height: 150,
                  borderRadius: BorderRadius.circular(8),
                  onImageLoaded: () => log('Context config image 1 loaded'),
                ),
                const SizedBox(height: 8),
                ImageDisplayWidget(
                  imageSource: 'https://picsum.photos/400/300?random=13',
                  width: double.infinity,
                  height: 150,
                  borderRadius: BorderRadius.circular(8),
                  onImageLoaded: () => log('Context config image 2 loaded'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cache disabled example
          _buildSectionTitle('Cache Disabled Example'),
          ImageDisplayWidget(
            imageSource: 'https://picsum.photos/400/300?random=14',
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
            disableCache: true, // Cache disabled for this specific image
            onImageLoaded: () => log('Image loaded without cache'),
            onImageError: (error) => log('Failed to load image: $error'),
          ),

          const SizedBox(height: 24),

          // Error handling example
          _buildSectionTitle('Error Handling Example'),
          ImageDisplayWidget(
            imageSource: 'https://invalid-url-that-will-fail.com/image.jpg',
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
            errorWidget: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red[100],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Custom Error Widget'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageExampleItem(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('URL: $url'),
          const SizedBox(height: 8),
          ImageDisplayWidget(
            imageSource: url,
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
            localCacheConfig: _currentCacheConfig.copyWith(
              maxImageCacheSize: 200 * 1024 * 1024, // 200MB
              maxCacheAgeDays: 5, // 5 days
              cleanupThreshold: 0.6, // 60%
            ),
            onImageLoaded: () => log('Image loaded: $url'),
            onImageError: (error) => log('Image error: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoExample() {
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

          // Basic remote videos with cache config
          _buildSectionTitle('Basic Remote Videos (with Cache Config)'),
          ..._remoteVideos.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            return _buildVideoExampleItem(url, index + 1);
          }),

          const SizedBox(height: 24),

          // Cache configuration examples
          _buildSectionTitle('Cache Configuration Examples'),

          // Local config only for videos
          _buildSubsectionTitle('Video with Local Config Only'),
          VideoDisplayWidget(
            videoSource: _remoteVideos[0],
            width: double.infinity,
            height: 200,
            autoPlay: false,
            useGlobalConfig: false,
            localCacheConfig: const CacheConfig(
              maxVideoCacheSize: 25 * 1024 * 1024, // 25MB
              maxCacheAgeDays: 2, // 2 days
              cleanupThreshold: 0.6, // 60%
            ),
            onVideoLoaded: () => log('Local config video loaded'),
          ),

          const SizedBox(height: 16),

          // Context-based video configuration
          _buildSubsectionTitle('Video with Context-Based Configuration'),
          CacheConfigScope(
            config: const CacheConfig(
              maxVideoCacheSize: 100 * 1024 * 1024, // 100MB
              maxCacheAgeDays: 7, // 7 days
              enableAutoCleanup: true,
              cleanupThreshold: 0.8, // 80%
            ),
            child: VideoDisplayWidget(
              videoSource: _remoteVideos[1],
              width: double.infinity,
              height: 200,
              autoPlay: false,
              onVideoLoaded: () => log('Context config video loaded'),
            ),
          ),

          const SizedBox(height: 24),

          // Progressive streaming examples
          _buildSectionTitle('Progressive Streaming with Cache'),

          // Preload with streaming
          _buildSubsectionTitle('Preload with Progressive Streaming'),
          ElevatedButton(
            onPressed: () async {
              await CacheManager.preloadVideosWithStreaming(_remoteVideos);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Videos preloaded with streaming'),
                  ),
                );
              }
            },
            child: const Text('Preload Videos with Streaming'),
          ),

          const SizedBox(height: 16),

          // Streaming info
          _buildSubsectionTitle('Streaming Information'),
          ElevatedButton(
            onPressed: () async {
              final info = await CacheManager.getVideoStreamingInfo(
                _remoteVideos.first,
              );
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Streaming Information'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Is cached: ${info['isCached']}'),
                        Text('Use streaming: ${info['shouldUseStreaming']}'),
                        Text(
                          'Recommended approach: ${info['recommendedApproach']}',
                        ),
                        if (info['cachedPath'] != null)
                          Text('Path: ${info['cachedPath']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('View Streaming Information'),
          ),

          const SizedBox(height: 24),

          // Cache disabled example
          _buildSectionTitle('Cache Disabled Example'),
          VideoDisplayWidget(
            videoSource: _remoteVideos[2],
            width: double.infinity,
            height: 250,
            autoPlay: false,
            looping: false,
            showControls: true,
            disableCache: true, // Cache disabled for this specific video
            onVideoLoaded: () => log('Video loaded without cache'),
            onVideoPlay: () => log('Video started playing'),
            onVideoPause: () => log('Video paused'),
            onVideoEnd: () => log('Video ended'),
          ),

          const SizedBox(height: 24),

          // Error handling example
          _buildSectionTitle('Error Handling Example'),
          VideoDisplayWidget(
            videoSource: 'https://invalid-url-that-will-fail.com/video.mp4',
            width: double.infinity,
            height: 250,
            errorWidget: Container(
              width: double.infinity,
              height: 250,
              color: Colors.red[100],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Custom Video Error Widget'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoExampleItem(String url, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Video $index: $url'),
          const SizedBox(height: 8),
          VideoDisplayWidget(
            videoSource: url,
            width: double.infinity,
            height: 250,
            autoPlay: false,
            looping: false,
            showControls: true,
            localCacheConfig: _currentCacheConfig.copyWith(
              maxVideoCacheSize: 500 * 1024 * 1024, // 500MB
              maxCacheAgeDays: 3, // 3 days
              cleanupThreshold: 0.5, // 50%
            ),
            onVideoLoaded: () => log('Video loaded: $url'),
            onVideoError: (error) => log('Video error: $error'),
            onVideoPlay: () => log('Video started playing'),
            onVideoPause: () => log('Video paused'),
            onVideoEnd: () => log('Video ended'),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheExample() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cache Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Current cache configuration
          _buildCacheConfigCard(),

          const SizedBox(height: 16),

          // Cache statistics
          _buildCacheStatsCard(),

          const SizedBox(height: 16),

          // Cache configuration controls
          _buildCacheControlsCard(),

          const SizedBox(height: 16),

          // Preload and management examples
          _buildSectionTitle('Preload and Management Examples'),

          ElevatedButton(
            onPressed: () async {
              await CacheManager.preloadImages(_remoteImages, context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Images preloaded')),
                );
              }
            },
            child: const Text('Preload All Images'),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () async {
              await CacheManager.instance.checkCacheLimits();
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache limits checked')),
                );
              }
            },
            child: const Text('Check Cache Limits'),
          ),

          const SizedBox(height: 24),

          // Cache refresh examples
          _buildSectionTitle('Cache Refresh Examples'),

          ElevatedButton(
            onPressed: () async {
              await CacheManager.refreshImage(
                'https://picsum.photos/300/200?random=1',
                context: context,
                preloadAfterClear: true,
              );
              log('Image refreshed');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image refreshed')),
                );
              }
            },
            child: const Text('Refresh Single Image'),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () async {
              await CacheManager.refreshVideo(
                _remoteVideos.first,
                preloadAfterClear: true,
              );
              log('Video refreshed');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video refreshed')),
                );
              }
            },
            child: const Text('Refresh Single Video'),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () async {
              await CacheManager.refreshImages(
                _remoteImages.take(3).toList(),
                context: context,
                preloadAfterClear: true,
              );
              log('Multiple images refreshed');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Multiple images refreshed')),
                );
              }
            },
            child: const Text('Refresh Multiple Images'),
          ),

          const SizedBox(height: 24),

          // Media utilities example
          _buildSectionTitle('Media Utilities Example'),
          _buildMediaUtilsCard(),

          const SizedBox(height: 24),

          // Advanced features
          _buildSectionTitle('Advanced Cache Configuration Features'),
          _buildAdvancedFeaturesCard(),

          const SizedBox(height: 16),

          // Debug and utility buttons
          _buildDebugButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildCacheConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Cache Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Max Image Cache: ${CacheManager.formatCacheSize(_currentCacheConfig.maxImageCacheSize)}',
            ),
            Text(
              'Max Video Cache: ${CacheManager.formatCacheSize(_currentCacheConfig.maxVideoCacheSize)}',
            ),
            Text(
              'Auto Cleanup: ${_currentCacheConfig.enableAutoCleanup ? 'Enabled' : 'Disabled'}',
            ),
            Text(
              'Cleanup Threshold: ${(_currentCacheConfig.cleanupThreshold * 100).toInt()}%',
            ),
            Text('Max Cache Age: ${_currentCacheConfig.maxCacheAgeDays} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: CacheManager.getCacheStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cache Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Image Cache: ${stats['imageCacheSizeFormatted'] ?? '0 B'}',
                ),
                Text(
                  'Video Cache: ${stats['videoCacheSizeFormatted'] ?? '0 B'}',
                ),
                Text(
                  'Total Cache: ${stats['totalCacheSizeFormatted'] ?? '0 B'}',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await CacheManager.clearImageCache();
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image cache cleared'),
                              ),
                            );
                          }
                        },
                        child: const Text('Clear Image Cache'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await CacheManager.clearVideoCache();
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Video cache cleared'),
                              ),
                            );
                          }
                        },
                        child: const Text('Clear Video Cache'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCacheControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Configuration Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Image cache size slider
            Text(
              'Max Image Cache: ${CacheManager.formatCacheSize(_currentCacheConfig.maxImageCacheSize)}',
            ),
            Slider(
              value:
                  _currentCacheConfig.maxImageCacheSize / (100 * 1024 * 1024),
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _currentCacheConfig = _currentCacheConfig.copyWith(
                    maxImageCacheSize: (value * 100 * 1024 * 1024).round(),
                  );
                  CacheManager.instance.updateConfig(_currentCacheConfig);
                });
              },
            ),

            const SizedBox(height: 16),

            // Video cache size slider
            Text(
              'Max Video Cache: ${CacheManager.formatCacheSize(_currentCacheConfig.maxVideoCacheSize)}',
            ),
            Slider(
              value:
                  _currentCacheConfig.maxVideoCacheSize / (500 * 1024 * 1024),
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _currentCacheConfig = _currentCacheConfig.copyWith(
                    maxVideoCacheSize: (value * 500 * 1024 * 1024).round(),
                  );
                  CacheManager.instance.updateConfig(_currentCacheConfig);
                });
              },
            ),

            const SizedBox(height: 16),

            // Cleanup threshold slider
            Text(
              'Cleanup Threshold: ${(_currentCacheConfig.cleanupThreshold * 100).toInt()}%',
            ),
            Slider(
              value: _currentCacheConfig.cleanupThreshold,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _currentCacheConfig = _currentCacheConfig.copyWith(
                    cleanupThreshold: value,
                  );
                  CacheManager.instance.updateConfig(_currentCacheConfig);
                });
              },
            ),

            const SizedBox(height: 16),

            // Auto cleanup toggle
            Row(
              children: [
                const Text('Auto Cleanup:'),
                const SizedBox(width: 8),
                Switch(
                  value: _currentCacheConfig.enableAutoCleanup,
                  onChanged: (value) {
                    setState(() {
                      _currentCacheConfig = _currentCacheConfig.copyWith(
                        enableAutoCleanup: value,
                      );
                      CacheManager.instance.updateConfig(_currentCacheConfig);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaUtilsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Is Remote: ${MediaUtils.isRemoteSource(_remoteImages.first)}',
            ),
            Text('Is Local: ${MediaUtils.isLocalSource("/path/to/file.jpg")}'),
            Text(
              'Valid Image URL: ${MediaUtils.isValidImageUrl(_remoteImages.first)}',
            ),
            Text(
              'Valid Video URL: ${MediaUtils.isValidVideoUrl(_remoteVideos.first)}',
            ),
            Text(
              'File Extension: ${MediaUtils.getFileExtension(_remoteImages.first)}',
            ),
            Text('Supports Video: ${MediaUtils.supportsVideoPlayback()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFeaturesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Methods:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Global: CacheManager.instance.updateConfig()'),
            const Text('• Local: localCacheConfig parameter'),
            const Text('• Context: CacheConfigScope widget'),
            const Text('• Hybrid: useGlobalConfig + localCacheConfig'),
            const SizedBox(height: 16),

            const Text(
              'Configuration Priority:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('1. Local config (if useGlobalConfig: false)'),
            const Text('2. Context config (CacheConfigScope)'),
            const Text('3. Global config (CacheManager)'),
            const SizedBox(height: 16),

            const Text(
              'Benefits:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• No interference between widgets'),
            const Text('• Automatic cleanup on widget dispose'),
            const Text('• Flexible configuration per context'),
            const Text('• Backward compatibility maintained'),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  CacheManager.instance.resetToOriginal();
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset to original config')),
                    );
                  }
                },
                child: const Text('Reset to Original'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final originalConfig = CacheManager.instance.originalConfig;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Original: ${originalConfig.toString()}'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('Show Original Config'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: () async {
            final directories = await CacheManager.debugCacheDirectories();
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cache Directories'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: directories.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
          child: const Text('Debug Cache Directories'),
        ),

        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: () async {
            final stats = await CacheManager.getCacheStats();
            log('Cache stats: $stats');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache stats logged to console')),
              );
            }
          },
          child: const Text('Log Cache Statistics'),
        ),
      ],
    );
  }
}
