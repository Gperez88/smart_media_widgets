import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

/// Widget para gestionar la configuración de caché de video, audio e imagen
class CacheConfigWidget extends StatefulWidget {
  const CacheConfigWidget({super.key});

  @override
  State<CacheConfigWidget> createState() => _CacheConfigWidgetState();
}

class _CacheConfigWidgetState extends State<CacheConfigWidget> {
  CacheConfig _currentConfig = const CacheConfig();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    _currentConfig = CacheManager.instance.config;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cache Configuration Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Configuración actual
          _buildCurrentConfigCard(),

          const SizedBox(height: 16),

          // Estadísticas de caché
          _buildCacheStatsCard(),

          const SizedBox(height: 16),

          // Controles de configuración
          _buildConfigurationControls(),

          const SizedBox(height: 16),

          // Acciones de gestión
          _buildManagementActions(),

          const SizedBox(height: 16),

          // Configuraciones predefinidas
          _buildPresetConfigurations(),
        ],
      ),
    );
  }

  Widget _buildCurrentConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildConfigRow(
              'Image Cache',
              CacheManager.formatCacheSize(_currentConfig.maxImageCacheSize),
            ),
            _buildConfigRow(
              'Video Cache',
              CacheManager.formatCacheSize(_currentConfig.maxVideoCacheSize),
            ),
            _buildConfigRow(
              'Audio Cache',
              CacheManager.formatCacheSize(_currentConfig.maxAudioCacheSize),
            ),
            _buildConfigRow(
              'Auto Cleanup',
              _currentConfig.enableAutoCleanup ? 'Enabled' : 'Disabled',
            ),
            _buildConfigRow(
              'Cleanup Threshold',
              '${(_currentConfig.cleanupThreshold * 100).toInt()}%',
            ),
            _buildConfigRow(
              'Max Cache Age',
              '${_currentConfig.maxCacheAgeDays} days',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
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
                const SizedBox(height: 12),
                _buildConfigRow(
                  'Image Cache Used',
                  stats['imageCacheSizeFormatted'] ?? '0 B',
                ),
                _buildConfigRow(
                  'Video Cache Used',
                  stats['videoCacheSizeFormatted'] ?? '0 B',
                ),
                _buildConfigRow(
                  'Audio Cache Used',
                  stats['audioCacheSizeFormatted'] ?? '0 B',
                ),
                _buildConfigRow(
                  'Total Cache Used',
                  stats['totalCacheSizeFormatted'] ?? '0 B',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _clearCache('image'),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Images'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _clearCache('video'),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Videos'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _clearCache('audio'),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Audio'),
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

  Widget _buildConfigurationControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Image Cache Size
            _buildSliderControl(
              'Image Cache Size',
              _currentConfig.maxImageCacheSize / (100 * 1024 * 1024),
              0.1,
              2.0,
              (value) => _updateConfig(
                maxImageCacheSize: (value * 100 * 1024 * 1024).round(),
              ),
              CacheManager.formatCacheSize(_currentConfig.maxImageCacheSize),
            ),

            const SizedBox(height: 16),

            // Video Cache Size
            _buildSliderControl(
              'Video Cache Size',
              _currentConfig.maxVideoCacheSize / (500 * 1024 * 1024),
              0.1,
              2.0,
              (value) => _updateConfig(
                maxVideoCacheSize: (value * 500 * 1024 * 1024).round(),
              ),
              CacheManager.formatCacheSize(_currentConfig.maxVideoCacheSize),
            ),

            const SizedBox(height: 16),

            // Audio Cache Size
            _buildSliderControl(
              'Audio Cache Size',
              _currentConfig.maxAudioCacheSize / (50 * 1024 * 1024),
              0.1,
              2.0,
              (value) => _updateConfig(
                maxAudioCacheSize: (value * 50 * 1024 * 1024).round(),
              ),
              CacheManager.formatCacheSize(_currentConfig.maxAudioCacheSize),
            ),

            const SizedBox(height: 16),

            // Cleanup Threshold
            _buildSliderControl(
              'Cleanup Threshold',
              _currentConfig.cleanupThreshold,
              0.1,
              1.0,
              (value) => _updateConfig(cleanupThreshold: value),
              '${(_currentConfig.cleanupThreshold * 100).toInt()}%',
            ),

            const SizedBox(height: 16),

            // Auto Cleanup Toggle
            Row(
              children: [
                const Text(
                  'Auto Cleanup:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _currentConfig.enableAutoCleanup,
                  onChanged: (value) => _updateConfig(enableAutoCleanup: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderControl(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(displayValue, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 19,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildManagementActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkCacheLimits,
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Check Limits'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearAllCache,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _resetToDefault,
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Reset Default'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showDebugInfo,
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Debug Info'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetConfigurations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preset Configurations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _applyPreset('minimal'),
                    child: const Text('Minimal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _applyPreset('balanced'),
                    child: const Text('Balanced'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _applyPreset('aggressive'),
                    child: const Text('Aggressive'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateConfig({
    int? maxImageCacheSize,
    int? maxVideoCacheSize,
    int? maxAudioCacheSize,
    bool? enableAutoCleanup,
    double? cleanupThreshold,
    int? maxCacheAgeDays,
  }) {
    setState(() {
      _currentConfig = _currentConfig.copyWith(
        maxImageCacheSize: maxImageCacheSize,
        maxVideoCacheSize: maxVideoCacheSize,
        maxAudioCacheSize: maxAudioCacheSize,
        enableAutoCleanup: enableAutoCleanup,
        cleanupThreshold: cleanupThreshold,
        maxCacheAgeDays: maxCacheAgeDays,
      );
      CacheManager.instance.updateConfig(_currentConfig);
    });
  }

  Future<void> _clearCache(String type) async {
    setState(() => _isLoading = true);

    try {
      switch (type) {
        case 'image':
          await CacheManager.clearImageCache();
          break;
        case 'video':
          await CacheManager.clearVideoCache();
          break;
        case 'audio':
          await CacheManager.clearAudioCache();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$type cache cleared')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing $type cache: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllCache() async {
    setState(() => _isLoading = true);

    try {
      await CacheManager.clearImageCache();
      await CacheManager.clearVideoCache();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All cache cleared')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing cache: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkCacheLimits() async {
    setState(() => _isLoading = true);

    try {
      await CacheManager.instance.checkCacheLimits();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache limits checked')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error checking limits: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetToDefault() {
    CacheManager.instance.resetToOriginal();
    _loadCurrentConfig();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to default configuration')),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original Config: ${CacheManager.instance.originalConfig}'),
            const SizedBox(height: 8),
            Text('Current Config: ${CacheManager.instance.config}'),
            const SizedBox(height: 8),
            Text('Config Hash: ${CacheManager.instance.config.hashCode}'),
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

  void _applyPreset(String preset) {
    CacheConfig newConfig;

    switch (preset) {
      case 'minimal':
        newConfig = const CacheConfig(
          maxImageCacheSize: 10 * 1024 * 1024, // 10MB
          maxVideoCacheSize: 50 * 1024 * 1024, // 50MB
          maxAudioCacheSize: 5 * 1024 * 1024, // 5MB
          enableAutoCleanup: true,
          cleanupThreshold: 0.8,
          maxCacheAgeDays: 1,
        );
        break;
      case 'balanced':
        newConfig = const CacheConfig(
          maxImageCacheSize: 100 * 1024 * 1024, // 100MB
          maxVideoCacheSize: 500 * 1024 * 1024, // 500MB
          maxAudioCacheSize: 50 * 1024 * 1024, // 50MB
          enableAutoCleanup: true,
          cleanupThreshold: 0.7,
          maxCacheAgeDays: 7,
        );
        break;
      case 'aggressive':
        newConfig = const CacheConfig(
          maxImageCacheSize: 500 * 1024 * 1024, // 500MB
          maxVideoCacheSize: 2 * 1024 * 1024 * 1024, // 2GB
          maxAudioCacheSize: 200 * 1024 * 1024, // 200MB
          enableAutoCleanup: false,
          cleanupThreshold: 0.9,
          maxCacheAgeDays: 30,
        );
        break;
      default:
        return;
    }

    CacheManager.instance.updateConfig(newConfig);
    _currentConfig = newConfig;
    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Applied $preset configuration')));
  }
}
