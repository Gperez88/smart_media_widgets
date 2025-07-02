import 'package:flutter/material.dart';
import 'package:smart_media_widgets/smart_media_widgets.dart';

class ImageDisplayWidgetExample extends StatelessWidget {
  const ImageDisplayWidgetExample({super.key});

  static const List<String> _remoteImages = [
    'https://picsum.photos/400/300?random=1',
    'https://picsum.photos/400/300?random=2',
    'https://picsum.photos/400/300?random=3',
    'https://picsum.photos/400/300?random=4',
  ];

  @override
  Widget build(BuildContext context) {
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

          // Remote Images Section
          const Text(
            'Remote Images with Cache',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'These images are automatically downloaded and cached.',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 12),

          // Standard Remote Image
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SmartImageDisplayWidget(
              imageSource: _remoteImages[0],
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(12),
              onImageLoaded: () => debugPrint('Standard remote image loaded!'),
              onImageError: (err) => debugPrint('Standard image error: $err'),
            ),
          ),

          // Image with Loading Indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SmartImageDisplayWidget(
              imageSource: _remoteImages[1],
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(12),
              showLoadingIndicator: true,
              placeholder: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading image...'),
                    ],
                  ),
                ),
              ),
              onImageLoaded: () =>
                  debugPrint('Image with custom placeholder loaded!'),
            ),
          ),

          // Imagen con borde y sombra
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SmartImageDisplayWidget(
                  imageSource: _remoteImages[1],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16),
                  onImageLoaded: () =>
                      debugPrint('Image with border and shadow loaded!'),
                ),
              ),
            ),
          ),

          // Imagen con error forzado (URL inválida)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SmartImageDisplayWidget(
              imageSource: 'https://url-invalida-404.com/imagen.png',
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.circular(12),
              errorWidget: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              onImageError: (err) => debugPrint('Forced image error: $err'),
            ),
          ),

          // Imagen local (comentada si no hay asset)
          /*
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SmartImageDisplayWidget(
              imageSource: 'assets/images/ejemplo.jpg',
              width: double.infinity,
              height: 120,
              borderRadius: BorderRadius.circular(12),
              onImageLoaded: () => debugPrint('Imagen local cargada!'),
              onImageError: (err) => debugPrint('Error imagen local: $err'),
            ),
          ),
          */

          // Imagen con overlay de ícono
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SmartImageDisplayWidget(
                  imageSource: _remoteImages[2],
                  width: double.infinity,
                  height: 180,
                  borderRadius: BorderRadius.circular(16),
                  fit: BoxFit.cover,
                  onImageLoaded: () => debugPrint('Image with overlay loaded!'),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Custom Cache Configuration
          const Text(
            'Custom Cache Configuration',
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
              'This image uses a custom cache configuration (10MB limit).',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SmartImageDisplayWidget(
              imageSource: _remoteImages[2],
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(12),
              localCacheConfig: const CacheConfig(
                maxImageCacheSize: 10 * 1024 * 1024, // 10MB
                enableAutoCleanup: true,
                cleanupThreshold: 0.8,
              ),
              useGlobalConfig: false,
              onImageLoaded: () => debugPrint('Custom cache image loaded!'),
              onImageError: (err) =>
                  debugPrint('Custom cache image error: $err'),
            ),
          ),

          const SizedBox(height: 24),

          // Styled Images
          const Text(
            'Styled Image Examples',
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
              'Examples with different styles and visual configurations.',
              style: TextStyle(fontSize: 12, color: Colors.purple),
            ),
          ),
          const SizedBox(height: 12),

          // Circular Image
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SmartImageDisplayWidget(
                imageSource: _remoteImages[3],
                width: 150,
                height: 150,
                borderRadius: BorderRadius.circular(75), // Circular
                fit: BoxFit.cover,
                onImageLoaded: () => debugPrint('Circular image loaded!'),
              ),
            ),
          ),

          // Card Style Image
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SmartImageDisplayWidget(
                  imageSource: _remoteImages[0],
                  width: double.infinity,
                  height: 180,
                  borderRadius: BorderRadius.circular(8),
                  fit: BoxFit.cover,
                  onImageLoaded: () => debugPrint('Card style image loaded!'),
                ),
              ),
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
                  '🖼️ ImageDisplayWidget Features',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Automatic cache for remote images\n'
                  '• Support for local and remote images\n'
                  '• Customizable cache configuration\n'
                  '• Customizable placeholders and loading indicators\n'
                  '• Robust error handling\n'
                  '• Support for all BoxFit modes',
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
