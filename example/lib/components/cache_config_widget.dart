import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

/// Widget para gestionar la configuración de caché de video, audio e imagen
class CacheConfigWidget extends StatefulWidget {
  const CacheConfigWidget({super.key});

  @override
  State<CacheConfigWidget> createState() => _CacheConfigWidgetState();
}

class _CacheConfigWidgetState extends State<CacheConfigWidget> {
  late CacheConfig _currentConfig;

  // Cache controls
  double _audioCacheSize = 100.0; // MB
  double _videoCacheSize = 200.0; // MB
  double _imageCacheSize = 50.0; // MB
  bool _enableAutoCleanup = true;
  double _cleanupThreshold = 0.8; // 80%
  double _maxCacheAge = 7.0; // days
  int _maxConcurrentDownloads = 3;

  // Android Buffer controls
  bool _enableAndroidBuffer = true;
  int _bufferSize = 8192; // bytes
  double _bufferTimeout = 5.0; // seconds
  bool _enableAdaptiveBuffer = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    _currentConfig = CacheManager.instance.config;

    // Load current values
    _audioCacheSize = _currentConfig.maxAudioCacheSize / (1024 * 1024);
    _videoCacheSize = _currentConfig.maxVideoCacheSize / (1024 * 1024);
    _imageCacheSize = _currentConfig.maxImageCacheSize / (1024 * 1024);
    _enableAutoCleanup = _currentConfig.enableAutoCleanup;
    _cleanupThreshold = _currentConfig.cleanupThreshold;
    _maxCacheAge = _currentConfig.maxCacheAgeDays.toDouble();
    _maxConcurrentDownloads = 3; // Default value

    // Load Android Buffer configuration (simulated for now)
    _enableAndroidBuffer = true;
    _bufferSize = 8192;
    _bufferTimeout = 5.0;
    _enableAdaptiveBuffer = true;
  }

  void _applyConfig() {
    final newConfig = CacheConfig(
      maxAudioCacheSize: (_audioCacheSize * 1024 * 1024).round(),
      maxVideoCacheSize: (_videoCacheSize * 1024 * 1024).round(),
      maxImageCacheSize: (_imageCacheSize * 1024 * 1024).round(),
      enableAutoCleanup: _enableAutoCleanup,
      cleanupThreshold: _cleanupThreshold,
      maxCacheAgeDays: _maxCacheAge.round(),
    );

    CacheManager.instance.updateConfig(newConfig);

    // Note: Android Buffer configuration will be implemented in the future
    if (Platform.isAndroid) {
      // TODO: Implement Android Buffer configuration
      debugPrint(
        'Android Buffer config: enabled=$_enableAndroidBuffer, size=$_bufferSize',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration applied successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _audioCacheSize = 100.0;
      _videoCacheSize = 200.0;
      _imageCacheSize = 50.0;
      _enableAutoCleanup = true;
      _cleanupThreshold = 0.8;
      _maxCacheAge = 7.0;
      _maxConcurrentDownloads = 3;

      _enableAndroidBuffer = true;
      _bufferSize = 8192;
      _bufferTimeout = 5.0;
      _enableAdaptiveBuffer = true;
    });
  }

  void _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Caché'),
        content: const Text(
          '¿Estás seguro de que quieres limpiar toda la caché? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CacheManager.clearAllCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cache Configuration',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Cache Configuration
          _buildCacheSection(),
          const SizedBox(height: 24),

          // Android Buffer Configuration (Android only)
          if (Platform.isAndroid) ...[
            _buildAndroidBufferSection(),
            const SizedBox(height: 24),
          ],

          // Cache Statistics
          _buildCacheStatsSection(),
          const SizedBox(height: 24),

          // Actions
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildCacheSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📁 Cache Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Cache sizes
            _buildSliderTile(
              'Audio Cache Size',
              _audioCacheSize,
              (value) => setState(() => _audioCacheSize = value),
              min: 10,
              max: 500,
              divisions: 49,
              unit: 'MB',
            ),

            _buildSliderTile(
              'Video Cache Size',
              _videoCacheSize,
              (value) => setState(() => _videoCacheSize = value),
              min: 50,
              max: 1000,
              divisions: 95,
              unit: 'MB',
            ),

            _buildSliderTile(
              'Image Cache Size',
              _imageCacheSize,
              (value) => setState(() => _imageCacheSize = value),
              min: 10,
              max: 200,
              divisions: 19,
              unit: 'MB',
            ),

            const SizedBox(height: 16),

            // Boolean configurations
            SwitchListTile(
              title: const Text('Auto Cleanup'),
              subtitle: const Text('Automatically delete old files'),
              value: _enableAutoCleanup,
              onChanged: (value) => setState(() => _enableAutoCleanup = value),
            ),

            if (_enableAutoCleanup) ...[
              _buildSliderTile(
                'Cleanup Threshold',
                _cleanupThreshold,
                (value) => setState(() => _cleanupThreshold = value),
                min: 0.5,
                max: 0.95,
                divisions: 9,
                unit: '%',
                valueTransformer: (value) => (value * 100).round().toString(),
              ),

              _buildSliderTile(
                'Max Cache Age',
                _maxCacheAge,
                (value) => setState(() => _maxCacheAge = value),
                min: 1,
                max: 30,
                divisions: 29,
                unit: 'days',
              ),
            ],

            const SizedBox(height: 16),

            _buildSliderTile(
              'Concurrent Downloads',
              _maxConcurrentDownloads.toDouble(),
              (value) =>
                  setState(() => _maxConcurrentDownloads = value.round()),
              min: 1,
              max: 10,
              divisions: 9,
              unit: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidBufferSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🤖 Android Buffer Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Android-specific optimizations',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Enable Android Buffer'),
              subtitle: const Text('Use optimized buffer for Android'),
              value: _enableAndroidBuffer,
              onChanged: (value) =>
                  setState(() => _enableAndroidBuffer = value),
            ),

            if (_enableAndroidBuffer) ...[
              _buildSliderTile(
                'Buffer Size',
                _bufferSize.toDouble(),
                (value) => setState(() => _bufferSize = value.round()),
                min: 1024,
                max: 32768,
                divisions: 31,
                unit: 'bytes',
                valueTransformer: (value) => value.round().toString(),
              ),

              _buildSliderTile(
                'Buffer Timeout',
                _bufferTimeout,
                (value) => setState(() => _bufferTimeout = value),
                min: 1,
                max: 30,
                divisions: 29,
                unit: 'sec',
              ),

              SwitchListTile(
                title: const Text('Adaptive Buffer'),
                subtitle: const Text(
                  'Adjust buffer based on network conditions',
                ),
                value: _enableAdaptiveBuffer,
                onChanged: (value) =>
                    setState(() => _enableAdaptiveBuffer = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Cache Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            FutureBuilder<Map<String, dynamic>>(
              future: _getCacheStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Column(
                    children: [
                      _buildStatRow(
                        'Audio in Cache',
                        '${stats['audioFiles']} files',
                      ),
                      _buildStatRow(
                        'Video in Cache',
                        '${stats['videoFiles']} files',
                      ),
                      _buildStatRow(
                        'Images in Cache',
                        '${stats['imageFiles']} files',
                      ),
                      _buildStatRow('Total Space', '${stats['totalSize']} MB'),
                      _buildStatRow(
                        'Active Downloads',
                        '${stats['activeDownloads']}',
                      ),
                      _buildStatRow('In Queue', '${stats['pendingDownloads']}'),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Apply Configuration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearAllCache,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    ValueChanged<double> onChanged, {
    required double min,
    required double max,
    required int divisions,
    required String unit,
    String Function(double)? valueTransformer,
  }) {
    final displayValue =
        valueTransformer?.call(value) ?? value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(title), Text('$displayValue $unit')],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getCacheStats() async {
    try {
      // Simulate statistics for now
      final stats = {'audioDownloads': 0, 'pendingDownloads': 0};
      final audioDir = await CacheManager.getAudioCacheDirectory();
      final videoDir = await CacheManager.getVideoCacheDirectory();
      final imageDir = await CacheManager.getImageCacheDirectory();

      int audioFiles = 0;
      int videoFiles = 0;
      int imageFiles = 0;
      int totalSize = 0;

      // Count audio files
      if (await audioDir.exists()) {
        await for (final file in audioDir.list()) {
          if (file is File) {
            audioFiles++;
            totalSize += await file.length();
          }
        }
      }

      // Count video files
      if (await videoDir.exists()) {
        await for (final file in videoDir.list()) {
          if (file is File) {
            videoFiles++;
            totalSize += await file.length();
          }
        }
      }

      // Count image files
      if (await imageDir.exists()) {
        await for (final file in imageDir.list()) {
          if (file is File) {
            imageFiles++;
            totalSize += await file.length();
          }
        }
      }

      return {
        'audioFiles': audioFiles,
        'videoFiles': videoFiles,
        'imageFiles': imageFiles,
        'totalSize': (totalSize / (1024 * 1024)).round(),
        'activeDownloads': stats['audioDownloads'] ?? 0,
        'pendingDownloads': stats['pendingDownloads'] ?? 0,
      };
    } catch (e) {
      return {
        'audioFiles': 0,
        'videoFiles': 0,
        'imageFiles': 0,
        'totalSize': 0,
        'activeDownloads': 0,
        'pendingDownloads': 0,
      };
    }
  }
}
