import 'package:flutter_test/flutter_test.dart';
import 'package:smart_media_widgets/src/utils/cache_manager.dart';
import 'package:smart_media_widgets/src/widgets/audio_player/global_audio_player_manager.dart';

/// Tests de concurrencia para detectar race conditions
/// Valida comportamiento bajo condiciones de alta concurrencia
void main() {
  group('Race Condition Tests', () {
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

    testWidgets(
      'should handle concurrent prepareAudio calls without race conditions',
      (tester) async {
        const String playerId = 'concurrent_prepare_test';
        const int concurrentCalls = 10;
        const String audioUrl =
            'https://invalid-domain-test.com/test_audio.mp3';

        final stopwatch = Stopwatch()..start();

        // Ejecutar múltiples llamadas concurrentes a prepareAudio
        final futures = List.generate(
          concurrentCalls,
          (i) => audioManager.prepareAudio(audioUrl, playerId: playerId),
        );

        // Esperar todas las llamadas
        final results = await Future.wait(futures);

        stopwatch.stop();

        // Verificar que todas las llamadas se completaron
        expect(results.length, concurrentCalls);

        // Verificar que solo se creó un controlador (no duplicados)
        final audioInfo = audioManager.getAudioInfo(playerId);
        expect(audioInfo, isNotNull);

        // Verificar tiempo total
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(15000),
        ); // 15 segundos máximo
      },
    );

    testWidgets(
      'should handle concurrent play/pause operations without state corruption',
      (tester) async {
        const String playerId = 'concurrent_play_pause_test';
        const String audioUrl =
            'https://invalid-domain-test.com/test_audio.mp3';
        const int operations = 20;

        // Preparar audio primero
        await audioManager.prepareAudio(audioUrl, playerId: playerId);

        final stopwatch = Stopwatch()..start();

        // Ejecutar operaciones play/pause concurrentes
        final futures = <Future<void>>[];

        for (int i = 0; i < operations; i++) {
          if (i % 2 == 0) {
            futures.add(audioManager.play(playerId));
          } else {
            futures.add(audioManager.pause(playerId));
          }
        }

        // Esperar todas las operaciones
        await Future.wait(futures);

        stopwatch.stop();

        // Verificar que el audio sigue siendo válido
        final audioInfo = audioManager.getAudioInfo(playerId);
        expect(audioInfo, isNotNull);
        expect(audioManager.isAudioActive(playerId), isTrue);

        // Verificar tiempo total
        expect(stopwatch.elapsedMilliseconds, lessThan(operations * 500));
      },
    );

    testWidgets(
      'should handle concurrent seek operations without position corruption',
      (tester) async {
        const String playerId = 'concurrent_seek_test';
        const String audioUrl =
            'https://invalid-domain-test.com/test_audio.mp3';
        const int seekOperations = 15;

        // Preparar audio primero
        await audioManager.prepareAudio(audioUrl, playerId: playerId);

        final stopwatch = Stopwatch()..start();

        // Ejecutar operaciones de seek concurrentes
        final futures = <Future<void>>[];

        for (int i = 0; i < seekOperations; i++) {
          final position = Duration(seconds: i * 5);
          futures.add(audioManager.seekTo(playerId, position));
        }

        // Esperar todas las operaciones
        await Future.wait(futures);

        stopwatch.stop();

        // Verificar que el audio sigue siendo válido
        final audioInfo = audioManager.getAudioInfo(playerId);
        expect(audioInfo, isNotNull);

        // Verificar tiempo total
        expect(stopwatch.elapsedMilliseconds, lessThan(seekOperations * 300));
      },
    );

    testWidgets(
      'should handle concurrent callback registrations without conflicts',
      (tester) async {
        const String playerId = 'concurrent_callbacks_test';
        const String audioUrl =
            'https://invalid-domain-test.com/test_audio.mp3';
        const int callbackRegistrations = 25;

        // Preparar audio primero
        await audioManager.prepareAudio(audioUrl, playerId: playerId);

        final stopwatch = Stopwatch()..start();

        // Registrar múltiples callbacks concurrentemente
        final futures = <Future<void>>[];

        for (int i = 0; i < callbackRegistrations; i++) {
          futures.add(
            Future(
              () => audioManager.registerCallbacks(
                playerId: playerId,
                onPlay: () => print('Play callback $i executed'),
              ),
            ),
          );
        }

        // Esperar todas las registraciones
        await Future.wait(futures);

        stopwatch.stop();

        // Verificar que el audio sigue siendo válido
        final audioInfo = audioManager.getAudioInfo(playerId);
        expect(audioInfo, isNotNull);

        // Verificar tiempo total
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(callbackRegistrations * 50),
        );
      },
    );

    testWidgets(
      'should handle concurrent cache operations without corruption',
      (tester) async {
        const int cacheOperations = 30;
        final testUrl =
            'https://invalid-domain-test.com/concurrent_cache_test.mp3';

        final stopwatch = Stopwatch()..start();

        // Ejecutar operaciones de cache concurrentes
        final futures = <Future<String?>>[];

        for (int i = 0; i < cacheOperations; i++) {
          if (i % 3 == 0) {
            futures.add(CacheManager.cacheAudio(testUrl));
          } else if (i % 3 == 1) {
            futures.add(CacheManager.getCachedAudioPath(testUrl));
          } else {
            futures.add(CacheManager.cacheVideo(testUrl));
          }
        }

        // Esperar todas las operaciones
        final results = await Future.wait(futures);

        stopwatch.stop();

        // Verificar que todas las operaciones se completaron
        expect(results.length, cacheOperations);

        // Verificar tiempo total
        expect(stopwatch.elapsedMilliseconds, lessThan(cacheOperations * 1000));
      },
    );

    testWidgets(
      'should handle concurrent configuration updates without conflicts',
      (tester) async {
        const int configUpdates = 20;

        final stopwatch = Stopwatch()..start();

        // Ejecutar actualizaciones de configuración concurrentes
        final futures = <Future<void>>[];

        for (int i = 0; i < configUpdates; i++) {
          final newConfig = CacheConfig(
            maxImageCacheSize: (50 + i) * 1024 * 1024,
            maxVideoCacheSize: (100 + i) * 1024 * 1024,
            maxAudioCacheSize: (75 + i) * 1024 * 1024,
            enableAutoCleanup: i % 2 == 0,
            cleanupThreshold: 0.5 + (i * 0.02),
            maxCacheAgeDays: 1 + (i % 7),
          );

          futures.add(Future(() => cacheManager.updateConfig(newConfig)));
        }

        // Esperar todas las actualizaciones
        await Future.wait(futures);

        stopwatch.stop();

        // Verificar que la configuración final es válida
        final finalConfig = cacheManager.config;
        expect(finalConfig, isNotNull);
        expect(finalConfig.maxImageCacheSize, greaterThan(0));
        expect(finalConfig.maxVideoCacheSize, greaterThan(0));
        expect(finalConfig.maxAudioCacheSize, greaterThan(0));

        // Verificar tiempo total
        expect(stopwatch.elapsedMilliseconds, lessThan(configUpdates * 100));
      },
    );

    testWidgets(
      'should handle concurrent statistics queries without data corruption',
      (tester) async {
        const int statQueries = 40;

        final stopwatch = Stopwatch()..start();

        // Ejecutar consultas de estadísticas concurrentes
        final futures = <Future<Map<String, dynamic>>>[];

        for (int i = 0; i < statQueries; i++) {
          futures.add(CacheManager.getCacheStats());
        }

        // Esperar todas las consultas
        final results = await Future.wait(futures);

        stopwatch.stop();

        // Verificar que todas las consultas se completaron
        expect(results.length, statQueries);

        // Verificar que todos los resultados son válidos
        for (final result in results) {
          expect(result, isA<Map<String, dynamic>>());
          expect(result, contains('totalCacheSize'));
          expect(result, contains('imageCacheSize'));
          expect(result, contains('videoCacheSize'));
          expect(result, contains('audioCacheSize'));
        }

        // Verificar tiempo total
        expect(stopwatch.elapsedMilliseconds, lessThan(statQueries * 200));
      },
    );

    testWidgets('should handle concurrent file validation operations', (
      tester,
    ) async {
      const int validations = 25;
      final testPaths = List.generate(
        validations,
        (i) => '/tmp/concurrent_validation_$i.mp3',
      );

      final stopwatch = Stopwatch()..start();

      // Ejecutar validaciones concurrentes
      final futures = testPaths.map(
        (path) => CacheManager.validateCachedFile(path),
      );
      final results = await Future.wait(futures);

      stopwatch.stop();

      // Verificar que todas las validaciones se completaron
      expect(results.length, validations);

      // Verificar que todos los resultados son booleanos
      for (final result in results) {
        expect(result, isA<bool>());
      }

      // Verificar tiempo total
      expect(stopwatch.elapsedMilliseconds, lessThan(validations * 300));
    });

    testWidgets('should handle concurrent space checking operations', (
      tester,
    ) async {
      const int spaceChecks = 30;

      final stopwatch = Stopwatch()..start();

      // Ejecutar verificaciones de espacio concurrentes
      final availableSpaceFutures = List.generate(
        spaceChecks,
        (i) => CacheManager.getAvailableSpace(),
      );

      final hasSpaceFutures = List.generate(
        spaceChecks,
        (i) => CacheManager.hasEnoughSpace(
          (i + 1) * 1024 * 1024,
        ), // 1MB, 2MB, 3MB...
      );

      // Esperar todas las verificaciones
      final availableSpaceResults = await Future.wait(availableSpaceFutures);
      final hasSpaceResults = await Future.wait(hasSpaceFutures);

      stopwatch.stop();

      // Verificar que todas las verificaciones se completaron
      expect(availableSpaceResults.length, spaceChecks);
      expect(hasSpaceResults.length, spaceChecks);

      // Verificar que los resultados son válidos
      for (final space in availableSpaceResults) {
        expect(space, isA<int>());
        expect(space, greaterThanOrEqualTo(0));
      }

      for (final hasSpace in hasSpaceResults) {
        expect(hasSpace, isA<bool>());
      }

      // Verificar tiempo total
      expect(stopwatch.elapsedMilliseconds, lessThan(spaceChecks * 150));
    });

    testWidgets('should handle concurrent download priority operations', (
      tester,
    ) async {
      const int downloads = 20;
      final urls = List.generate(
        downloads,
        (i) => 'https://invalid-domain-test.com/priority_concurrent_$i.mp3',
      );

      final stopwatch = Stopwatch()..start();

      // Ejecutar descargas con diferentes prioridades concurrentemente
      final futures = <Future<String?>>[];

      for (int i = 0; i < downloads; i++) {
        final priority = switch (i % 4) {
          0 => DownloadPriority.low,
          1 => DownloadPriority.normal,
          2 => DownloadPriority.high,
          3 => DownloadPriority.urgent,
          _ => DownloadPriority.normal,
        };

        futures.add(CacheManager.cacheAudio(urls[i], priority: priority));
      }

      // Esperar todas las descargas
      final results = await Future.wait(futures);

      stopwatch.stop();

      // Verificar que todas las descargas se completaron
      expect(results.length, downloads);

      // Verificar tiempo total
      expect(stopwatch.elapsedMilliseconds, lessThan(downloads * 2000));
    });

    testWidgets(
      'should handle concurrent cleanup operations without conflicts',
      (tester) async {
        const int cleanupOperations = 15;

        final stopwatch = Stopwatch()..start();

        // Ejecutar operaciones de cleanup concurrentes
        final futures = <Future<void>>[];

        for (int i = 0; i < cleanupOperations; i++) {
          switch (i % 3) {
            case 0:
              futures.add(CacheManager.clearAudioCache());
              break;
            case 1:
              futures.add(CacheManager.clearVideoCache());
              break;
            case 2:
              futures.add(CacheManager.clearImageCache());
              break;
          }
        }

        // Esperar todas las operaciones
        await Future.wait(futures);

        stopwatch.stop();

        // Verificar tiempo total
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(cleanupOperations * 1000),
        );
      },
    );
  });
}
