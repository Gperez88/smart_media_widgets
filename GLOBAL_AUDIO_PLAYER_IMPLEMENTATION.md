# Implementación del Reproductor de Audio Global

## Resumen

Esta implementación añade funcionalidad de reproductor global estilo WhatsApp/Telegram al `AudioPlayerWidget` existente. El sistema permite reproducir audio en un reproductor persistente que se mantiene visible en todas las pantallas de la aplicación.

## Criterios de Aceptación Implementados

- ✅ **Si `enableGlobalPlayer = true`**, al reproducir un audio en el chat:
  - ✅ **El reproductor local se mantiene idéntico visualmente** (sin cambios de estado)
  - ✅ **Aparece un reproductor global anclado debajo del AppBar**, con controles de reproducción y progreso
  - ✅ **Ambos reproductores controlan el mismo audio** (sincronizados)
  - ✅ **El reproductor se mantiene visible al navegar por otras pantallas**
  - ✅ **El audio puede pausarse o cerrarse desde cualquier reproductor**
- ✅ **Si `enableGlobalPlayer = false`**, el audio se reproduce directamente en la burbuja de chat como hasta ahora
- ✅ **Al cerrar el reproductor global**, se detiene la reproducción y se libera el recurso
- ✅ **El diseño visual está alineado al estilo actual** de la app y es responsivo
- ✅ **Funciona correctamente tanto en Android como en iOS**

## Arquitectura

### Componentes Principales

#### 1. GlobalAudioPlayerManager (Singleton)
**Archivo:** `lib/src/widgets/audio_player/global_audio_player_manager.dart`

Gestor centralizado del estado del reproductor global:

```dart
// Iniciar reproducción global
await GlobalAudioPlayerManager.instance.startGlobalPlayback(
  audioSource: 'https://example.com/audio.mp3',
  color: Colors.blue,
  playIcon: Icons.play_arrow,
  pauseIcon: Icons.pause,
);

// Controlar reproducción
await GlobalAudioPlayerManager.instance.togglePlayPause();

// Detener y limpiar
await GlobalAudioPlayerManager.instance.stopGlobalPlayback();

// Escuchar cambios de estado
GlobalAudioPlayerManager.instance.stateStream.listen((state) {
  // Manejar cambios de estado
});
```

**Características:**
- Gestión de estado centralizada
- Streaming de estados para sincronización
- Manejo de recursos y cache
- Soporte para configuraciones personalizadas

#### 2. GlobalAudioPlayerOverlay
**Archivo:** `lib/src/widgets/audio_player/global_audio_player_overlay.dart`

Widget de overlay que se muestra debajo del AppBar:

```dart
GlobalAudioPlayerOverlay(
  height: 80,
  backgroundColor: Colors.white,
  borderRadius: BorderRadius.circular(0),
  showCloseButton: true,
  closeIcon: Icons.close,
  animationDuration: Duration(milliseconds: 300),
)
```

**Características:**
- Animaciones suaves de entrada/salida
- Controles de reproducción integrados
- Waveform interactivo
- Botón de cierre configurable

#### 3. AudioPlayerWidget Refactorizado
**Archivo:** `lib/src/widgets/audio_player/audio_player_widget.dart`

Widget principal con soporte para modo global:

```dart
AudioPlayerWidget(
  audioSource: 'audio.mp3',
  enableGlobalPlayer: true, // Nuevo parámetro
  // ... resto de parámetros existentes
)
```

## Implementación Paso a Paso

### 1. Configuración Básica

#### En el Widget Principal de la App:

```dart
class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mi App')),
      body: Column(
        children: [
          // Overlay global - aparece aquí cuando hay audio activo
          GlobalAudioPlayerOverlay(),
          
          // Contenido principal
          Expanded(
            child: ChatScreen(),
          ),
        ],
      ),
    );
  }
}
```

### 2. Uso en Widgets de Chat

#### Modo Local (comportamiento existente):
```dart
AudioPlayerWidget(
  audioSource: 'https://example.com/message-audio.mp3',
  width: double.infinity,
  height: 60,
  color: Colors.blue,
  enableGlobalPlayer: false, // o simplemente omitir
)
```

#### Modo Global (nuevo):
```dart
AudioPlayerWidget(
  audioSource: 'https://example.com/message-audio.mp3',
  width: double.infinity,
  height: 60,
  color: Colors.blue,
  enableGlobalPlayer: true, // Activa modo global
  onAudioLoaded: () => print('Audio cargado'),
  onAudioError: (error) => print('Error: $error'),
)
```

### 3. Configuración Avanzada

#### Con Configuración de Cache Personalizada:
```dart
AudioPlayerWidget(
  audioSource: 'https://example.com/audio.mp3',
  enableGlobalPlayer: true,
  localCacheConfig: CacheConfig(
    maxAudioCacheSize: 50 * 1024 * 1024, // 50MB
    enableAutoCleanup: true,
    cleanupThreshold: 0.7,
  ),
  color: Colors.deepPurple,
  waveStyle: PlayerWaveStyle(
    fixedWaveColor: Colors.grey,
    liveWaveColor: Colors.deepPurple,
    showSeekLine: true,
  ),
)
```

#### Overlay Personalizado:
```dart
GlobalAudioPlayerOverlay(
  height: 90,
  backgroundColor: Color(0xFFF5F5F5),
  borderRadius: BorderRadius.only(
    bottomLeft: Radius.circular(12),
    bottomRight: Radius.circular(12),
  ),
  showCloseButton: true,
  closeIcon: Icons.keyboard_arrow_down,
  animationDuration: Duration(milliseconds: 250),
)
```

## Estados del Widget

### 1. Modo Local (`enableGlobalPlayer: false`)
- Comportamiento idéntico al widget original
- Reproductor completo con waveform
- Cache y controles locales

### 2. Modo Global (`enableGlobalPlayer: true`)
- **Widget local se mantiene visualmente idéntico**
- Misma apariencia en todos los estados (reproduciendo o no)
- Al presionar play/pause controla el reproductor global
- Waveform sincronizado con reproductor global
- UI indistinguible del modo local

## Flujo de Trabajo

### Inicio de Reproducción Global

1. Usuario presiona play en widget con `enableGlobalPlayer: true`
2. Widget llama a `GlobalAudioPlayerManager.startGlobalPlayback()`
3. Manager prepara audio y actualiza estado
4. Overlay global aparece con animación
5. **Widget local sincroniza su estado** (misma apariencia, estado sincronizado)
6. Audio comienza reproducción global
7. **Ambos reproductores muestran waveform/controles sincronizados**

### Navegación Entre Pantallas

1. Usuario navega a otra pantalla
2. Overlay global permanece visible
3. Estado de reproducción se mantiene
4. Controles siguen funcionales

### Cierre de Reproducción

1. Usuario presiona botón de cierre en overlay (o pausa desde widget local)
2. Manager detiene reproducción y limpia recursos
3. Overlay desaparece con animación
4. **Widgets locales muestran estado pausado** (siempre visibles)

## Compatibilidad

### Retrocompatibilidad Total
- Todo el código existente funciona sin cambios
- Parámetro `enableGlobalPlayer` es opcional (default: `false`)
- APIs existentes no modificadas

### Nuevos Parámetros Opcionales
```dart
AudioPlayerWidget(
  // Parámetros existentes...
  audioSource: 'audio.mp3',
  width: 300,
  height: 80,
  color: Colors.blue,
  
  // Nuevos parámetros opcionales
  disableCache: false,           // Deshabilitar cache
  enableGlobalPlayer: false,     // Activar modo global
)
```

## Configuración de Cache

El sistema global respeta toda la configuración de cache existente:

```dart
// Cache global
CacheManager.instance.updateConfig(CacheConfig(
  maxAudioCacheSize: 100 * 1024 * 1024,
));

// Cache local por widget
AudioPlayerWidget(
  audioSource: 'audio.mp3',
  enableGlobalPlayer: true,
  localCacheConfig: CacheConfig(
    maxAudioCacheSize: 20 * 1024 * 1024,
  ),
)
```

## Manejo de Errores

### En el Widget Local:
```dart
AudioPlayerWidget(
  audioSource: 'audio.mp3',
  enableGlobalPlayer: true,
  onAudioError: (error) {
    // Manejar errores específicos del widget
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error de audio: $error')),
    );
  },
)
```

### En el Manager Global:
```dart
GlobalAudioPlayerManager.instance.stateStream.listen((state) {
  if (state?.errorMessage != null) {
    // Manejar errores globales
    print('Error global: ${state!.errorMessage}');
  }
});
```

## Mejores Prácticas

### 1. Limpieza de Recursos
```dart
class ChatScreen extends StatefulWidget {
  @override
  void dispose() {
    // El manager se limpia automáticamente
    // No requiere limpieza manual
    super.dispose();
  }
}
```

### 2. Gestión de Estado
```dart
class AudioChatBubble extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // Escuchar cambios globales si es necesario
    _subscription = GlobalAudioPlayerManager.instance.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          // Actualizar UI según estado global
        });
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### 3. Configuración por Contexto
```dart
// Para chat individual
AudioPlayerWidget(
  enableGlobalPlayer: true,
  color: Colors.blue,
)

// Para chat grupal
AudioPlayerWidget(
  enableGlobalPlayer: true,
  color: Colors.green,
)
```

## Debugging y Monitoreo

### Logs del Sistema:
```dart
// Los logs están integrados automáticamente
// Buscar en consola:
// "GlobalAudioPlayerManager: ..."
// "AudioPlayerWidget: ..."
```

### Estado del Manager:
```dart
// Verificar estado actual
final hasActive = GlobalAudioPlayerManager.instance.hasActivePlayer;
final isPlaying = GlobalAudioPlayerManager.instance.isPlaying;
final currentState = GlobalAudioPlayerManager.instance.currentState;
```

## Consideraciones de Rendimiento

1. **Un Solo PlayerController Global**: Evita múltiples instancias simultáneas
2. **Limpieza Automática**: Recursos se liberan al cerrar reproductor
3. **Cache Compartido**: Configuración de cache se mantiene eficiente
4. **Streams Optimizados**: Broadcasting streams evita memoria innecesaria

## Pruebas de Validación

### Caso 1: Modo Local
```dart
// Verificar comportamiento existente
AudioPlayerWidget(
  audioSource: 'test.mp3',
  enableGlobalPlayer: false,
)
// Debe funcionar exactamente como antes
```

### Caso 2: Activación Global
```dart
// Verificar activación de modo global
AudioPlayerWidget(
  audioSource: 'test.mp3',
  enableGlobalPlayer: true,
)
// Presionar play debe mostrar overlay global
```

### Caso 3: Navegación
```dart
// Reproducir audio globalmente
// Navegar a otra pantalla
// Verificar que overlay permanece visible
```

### Caso 4: Múltiples Widgets
```dart
// Múltiples AudioPlayerWidgets con enableGlobalPlayer: true
// Solo uno debe poder reproducir globalmente a la vez
```

## Migración desde Versión Anterior

### Código Existente (sin cambios requeridos):
```dart
AudioPlayerWidget(
  audioSource: 'audio.mp3',
  width: 300,
  height: 80,
  // Funciona exactamente igual
)
```

### Código Nuevo (opt-in):
```dart
AudioPlayerWidget(
  audioSource: 'audio.mp3',
  width: 300,
  height: 80,
  enableGlobalPlayer: true, // Solo añadir esta línea
)
```

La implementación garantiza compatibilidad total hacia atrás mientras añade las nuevas funcionalidades de manera opcional y elegante.

## Comportamiento Visual Corregido

### ⚠️ Aclaración Importante

**El reproductor local se mantiene visualmente idéntico** independientemente del modo global. La implementación funciona como se muestra en la imagen de referencia:

- **Reproductor Local**: Siempre se ve y funciona igual (misma UI en todos los casos)
- **Reproductor Global**: Aparece como overlay adicional cuando `enableGlobalPlayer: true`
- **Sincronización**: Ambos controlan el mismo audio y muestran el mismo estado
- **Control Dual**: El usuario puede usar cualquiera de los dos para controlar la reproducción

### Estados Visuales del Widget Local

```dart
// Modo local normal
enableGlobalPlayer: false
// → Reproductor normal (comportamiento original)

// Modo global (cualquier estado)
enableGlobalPlayer: true
// → Reproductor se ve EXACTAMENTE IGUAL
// → Solo cambia el comportamiento interno (controla reproductor global)
// → UI indistinguible del modo local
```

**Resultado**: Como en WhatsApp/Telegram, ambos reproductores son funcionales y visualmente coherentes.