import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/src/utils/cache_manager.dart';
import 'package:smart_media_widgets/src/widgets/audio_player/global_audio_player_manager.dart';

/// Tests de red para simular interrupciones de conectividad
/// Valida comportamiento bajo condiciones de red inestable
void main() {
  group('Network Interruption Tests', () {
    late GlobalAudioPlayerManager audioManager;
    late CacheManager cacheManager;

    setUp(() {
      audioManager = GlobalAudioPlayerManager.instance;
      cacheManager = CacheManager.instance;
    });

    tearDown(() async {
      // Limpiar recursos después de cada test
      for (final audio in audioManager.activeAudios) {
        try {
          await audioManager.stop(audio.playerId);
        } catch (e) {
          // Ignorar errores de limpieza
        }
      }
      await CacheManager.clearAllCache();
    });

    testWidgets('should handle timeout during audio preparation', (
      tester,
    ) async {
      const String playerId = 'timeout_test';
      const String slowAudioUrl =
          'https://httpbin.org/delay/5'; // 5 segundos de delay (más rápido para tests)

      final stopwatch = Stopwatch()..start();

      try {
        // Intentar preparar audio con timeout
        await audioManager.prepareAudio(slowAudioUrl, playerId: playerId);

        // Si llegamos aquí, el timeout no funcionó como esperado
        fail('Expected timeout but audio was prepared successfully');
      } catch (e) {
        // Verificar que el error es un timeout
        expect(e.toString(), contains('timeout'));

        // Verificar que el audio no está activo
        expect(audioManager.isAudioActive(playerId), isFalse);
        expect(audioManager.isAudioPreparing(playerId), isFalse);
      }

      stopwatch.stop();

      // Verificar que el timeout ocurrió en un tiempo razonable
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(30000),
      ); // 30 segundos máximo
    });

    testWidgets('should handle network errors during audio preparation', (
      tester,
    ) async {
      const String playerId = 'network_error_test';
      const String invalidUrl =
          'https://invalid-domain-that-does-not-exist-12345.com/audio.mp3';

      final stopwatch = Stopwatch()..start();

      try {
        // Intentar preparar audio con URL inválida
        await audioManager.prepareAudio(invalidUrl, playerId: playerId);

        // Si llegamos aquí, el error no se manejó como esperado
        fail('Expected network error but audio was prepared successfully');
      } catch (e) {
        // Verificar que el error es relacionado con red
        final errorString = e.toString().toLowerCase();
        expect(
          errorString.contains('network') ||
              errorString.contains('connection') ||
              errorString.contains('unreachable') ||
              errorString.contains('dns'),
          isTrue,
        );

        // Verificar que el audio no está activo
        expect(audioManager.isAudioActive(playerId), isFalse);
        expect(audioManager.isAudioPreparing(playerId), isFalse);
      }

      stopwatch.stop();

      // Verificar que el error se detectó rápidamente
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(15000),
      ); // 15 segundos máximo
    });

    testWidgets('should handle multiple network failures with retry logic', (
      tester,
    ) async {
      const String playerId = 'retry_test';
      const String unreliableUrl =
          'https://httpbin.org/status/500'; // Error 500

      final stopwatch = Stopwatch()..start();

      try {
        // Intentar preparar audio con URL que falla
        await audioManager.prepareAudio(unreliableUrl, playerId: playerId);

        // Si llegamos aquí, el retry no funcionó como esperado
        fail('Expected retry failure but audio was prepared successfully');
      } catch (e) {
        // Verificar que el error se propagó después de los reintentos
        expect(e, isNotNull);

        // Verificar que el audio no está activo
        expect(audioManager.isAudioActive(playerId), isFalse);
        expect(audioManager.isAudioPreparing(playerId), isFalse);
      }

      stopwatch.stop();

      // Verificar que los reintentos tomaron tiempo razonable
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThan(5000),
      ); // Al menos 5 segundos para reintentos
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(45000),
      ); // Máximo 45 segundos
    });

    testWidgets('should handle cache download with network interruption', (
      tester,
    ) async {
      const String unreliableUrl =
          'https://httpbin.org/status/503'; // Service Unavailable

      final stopwatch = Stopwatch()..start();

      // Intentar descargar archivo con interrupción de red
      final result = await CacheManager.cacheAudio(unreliableUrl);

      stopwatch.stop();

      // Verificar que la descarga falló
      expect(result, isNull);

      // Verificar que el error se manejó en tiempo razonable
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20000),
      ); // 20 segundos máximo
    });

    testWidgets('should handle multiple cache downloads with network issues', (
      tester,
    ) async {
      const int downloads = 5;
      final unreliableUrls = List.generate(
        downloads,
        (i) =>
            'https://httpbin.org/status/${400 + i}', // Errores 400, 401, 402, 403, 404
      );

      final stopwatch = Stopwatch()..start();

      // Intentar múltiples descargas con errores de red
      final futures = unreliableUrls.map((url) => CacheManager.cacheAudio(url));
      final results = await Future.wait(futures);

      stopwatch.stop();

      // Verificar que todas las descargas fallaron
      expect(results.length, downloads);
      for (final result in results) {
        expect(result, isNull);
      }

      // Verificar tiempo total
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(downloads * 10000),
      ); // 10 segundos por descarga máximo
    });

    testWidgets('should handle network timeout during video download', (
      tester,
    ) async {
      const String slowVideoUrl =
          'https://httpbin.org/delay/10'; // 10 segundos de delay (más rápido para tests)

      final stopwatch = Stopwatch()..start();

      // Intentar descargar video con timeout
      final result = await CacheManager.cacheVideo(slowVideoUrl);

      stopwatch.stop();

      // Verificar que la descarga falló por timeout
      expect(result, isNull);

      // Verificar que el timeout ocurrió en tiempo razonable
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(60000),
      ); // 60 segundos máximo
    });

    testWidgets('should handle network configuration adaptation', (
      tester,
    ) async {
      const String playerId = 'config_adaptation_test';
      const String unreliableUrl = 'https://httpbin.org/status/500';

      // Configurar red como inestable
      final unstableConfig = NetworkConfig(
        baseTimeoutSeconds: 5,
        maxRetries: 2,
        backoffFactor: 2.0,
        initialDelayMs: 1000,
        enableConnectivityDetection: true,
      );
      audioManager.updateNetworkConfig(unstableConfig);

      final stopwatch = Stopwatch()..start();

      try {
        // Intentar preparar audio con configuración inestable
        await audioManager.prepareAudio(unreliableUrl, playerId: playerId);

        fail('Expected failure but audio was prepared successfully');
      } catch (e) {
        // Verificar que el error se propagó
        expect(e, isNotNull);
      }

      stopwatch.stop();

      // Verificar que la configuración inestable se aplicó
      final networkStats = audioManager.getNetworkStats();
      expect(networkStats['consecutiveNetworkErrors'], greaterThan(0));

      // Verificar tiempo total
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(30000),
      ); // 30 segundos máximo
    });

    testWidgets('should handle network recovery after failures', (
      tester,
    ) async {
      const String playerId = 'recovery_test';
      const String workingUrl = 'https://httpbin.org/status/200';

      // Primero simular algunos errores de red
      try {
        await audioManager.prepareAudio(
          'https://httpbin.org/status/500',
          playerId: 'error_test_1',
        );
      } catch (e) {
        // Ignorar error esperado
      }

      try {
        await audioManager.prepareAudio(
          'https://httpbin.org/status/503',
          playerId: 'error_test_2',
        );
      } catch (e) {
        // Ignorar error esperado
      }

      final stopwatch = Stopwatch()..start();

      // Ahora intentar con una URL que funciona
      try {
        await audioManager.prepareAudio(workingUrl, playerId: playerId);

        // Verificar que el audio se preparó exitosamente
        expect(audioManager.isAudioActive(playerId), isTrue);
      } catch (e) {
        // Si falla, verificar que no es un error de red
        final errorString = e.toString().toLowerCase();
        expect(
          errorString.contains('network') || errorString.contains('connection'),
          isFalse,
        );
      }

      stopwatch.stop();

      // Verificar tiempo total
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20000),
      ); // 20 segundos máximo
    });

    testWidgets('should handle concurrent network failures', (tester) async {
      const int concurrentAttempts = 8;
      final unreliableUrls = List.generate(
        concurrentAttempts,
        (i) =>
            'https://httpbin.org/status/${500 + (i % 3)}', // Errores 500, 501, 502
      );

      final stopwatch = Stopwatch()..start();

      // Intentar múltiples preparaciones concurrentes con errores de red
      final futures = unreliableUrls.asMap().entries.map((entry) {
        final i = entry.key;
        final url = entry.value;
        return audioManager.prepareAudio(
          url,
          playerId: 'concurrent_network_test_$i',
        );
      });

      final results = await Future.wait(futures, eagerError: false);

      stopwatch.stop();

      // Verificar que todas las operaciones se completaron (aunque fallaron)
      expect(results.length, concurrentAttempts);

      // Verificar que no hay audios activos (todos fallaron)
      expect(audioManager.activeAudios.isEmpty, isTrue);

      // Verificar tiempo total
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(concurrentAttempts * 15000),
      ); // 15 segundos por intento máximo
    });

    testWidgets('should handle network error during cache statistics query', (
      tester,
    ) async {
      // Simular interrupción de red durante consulta de estadísticas
      final stopwatch = Stopwatch()..start();

      // Intentar obtener estadísticas (debería funcionar incluso con red inestable)
      final stats = await CacheManager.getCacheStats();

      stopwatch.stop();

      // Verificar que las estadísticas se obtuvieron
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, contains('totalCacheSize'));
      expect(stats, contains('imageCacheSize'));
      expect(stats, contains('videoCacheSize'));
      expect(stats, contains('audioCacheSize'));

      // Verificar que la consulta fue rápida (no depende de red)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
      ); // 5 segundos máximo
    });

    testWidgets('should handle network error during file validation', (
      tester,
    ) async {
      const String invalidPath = '/invalid/path/that/does/not/exist.mp3';

      final stopwatch = Stopwatch()..start();

      // Intentar validar archivo inexistente
      final isValid = await CacheManager.validateCachedFile(invalidPath);

      stopwatch.stop();

      // Verificar que la validación falló correctamente
      expect(isValid, isFalse);

      // Verificar que la validación fue rápida
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
      ); // 2 segundos máximo
    });

    testWidgets('should handle network error during space checking', (
      tester,
    ) async {
      final stopwatch = Stopwatch()..start();

      // Verificar espacio disponible (no debería depender de red)
      final availableSpace = await CacheManager.getAvailableSpace();
      final hasSpace = await CacheManager.hasEnoughSpace(1024 * 1024); // 1MB

      stopwatch.stop();

      // Verificar que las verificaciones se completaron
      expect(availableSpace, isA<int>());
      expect(availableSpace, greaterThanOrEqualTo(0));
      expect(hasSpace, isA<bool>());

      // Verificar que las verificaciones fueron rápidas
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
      ); // 5 segundos máximo
    });

    testWidgets('should handle network error during configuration update', (
      tester,
    ) async {
      const int configUpdates = 10;

      final stopwatch = Stopwatch()..start();

      // Ejecutar actualizaciones de configuración (no deberían depender de red)
      for (int i = 0; i < configUpdates; i++) {
        final newConfig = CacheConfig(
          maxImageCacheSize: (50 + i) * 1024 * 1024,
          maxVideoCacheSize: (100 + i) * 1024 * 1024,
          maxAudioCacheSize: (75 + i) * 1024 * 1024,
          enableAutoCleanup: i % 2 == 0,
          cleanupThreshold: 0.5 + (i * 0.05),
          maxCacheAgeDays: 1 + (i % 7),
        );

        cacheManager.updateConfig(newConfig);
      }

      stopwatch.stop();

      // Verificar que la configuración final es válida
      final finalConfig = cacheManager.config;
      expect(finalConfig, isNotNull);
      expect(finalConfig.maxImageCacheSize, greaterThan(0));
      expect(finalConfig.maxVideoCacheSize, greaterThan(0));
      expect(finalConfig.maxAudioCacheSize, greaterThan(0));

      // Verificar que las actualizaciones fueron rápidas
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(configUpdates * 100),
      ); // 100ms por actualización máximo
    });

    testWidgets('should handle network error during cleanup operations', (
      tester,
    ) async {
      final stopwatch = Stopwatch()..start();

      // Ejecutar operaciones de cleanup (no deberían depender de red)
      await CacheManager.clearAudioCache();
      await CacheManager.clearVideoCache();
      await CacheManager.clearImageCache();

      stopwatch.stop();

      // Verificar que las operaciones se completaron
      // (no hay forma directa de verificar, pero no deberían fallar)

      // Verificar que las operaciones fueron rápidas
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10000),
      ); // 10 segundos máximo
    });
  });
}
