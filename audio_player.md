**Título:**  
Refactorizar `AudioPlayerWidget` para soporte de reproducción global estilo WhatsApp/Telegram

**Plataforma:**  
Android/iOS

**Módulo Afectado:**  
Chat / Reproductor de Audio

**Descripción Detallada:**  
Se requiere refactorizar el componente `AudioPlayerWidget` para permitir un comportamiento similar al de aplicaciones como WhatsApp o Telegram. La funcionalidad debe permitir que, al reproducir un audio desde una conversación, aparezca un reproductor global fijo en la parte superior de la interfaz (debajo del AppBar), visible desde cualquier pantalla de la app.  
El componente también debe poder reproducirse de forma embebida (local) en la burbuja del mensaje si no se activa el modo de reproducción global. Esta configuración debe ser controlada por un flag (`enableGlobalPlayer`) que determine el comportamiento deseado.

**Criterios de Aceptación:**  
- Si `enableGlobalPlayer = true`, al reproducir un audio en el chat:
  - Se oculta el reproductor local del mensaje.  
  - Aparece un reproductor global anclado debajo del AppBar, con controles de reproducción y progreso.  
  - El reproductor se mantiene visible al navegar por otras pantallas.  
  - El audio puede pausarse o cerrarse desde el reproductor global.  
- Si `enableGlobalPlayer = false`, el audio se reproduce directamente en la burbuja de chat como hasta ahora.  
- Al cerrar el reproductor global, se detiene la reproducción y se libera el recurso.  
- Soporte para reproducción secuencial o en cola puede definirse en futuras iteraciones.  
- El diseño visual debe estar alineado al estilo actual de la app y ser responsivo.  
- El comportamiento debe funcionar correctamente tanto en Android como en iOS.

**Pasos para Validación:**  
1. Ingresar a una conversación que tenga mensajes de audio.  
2. Activar `enableGlobalPlayer` y reproducir un mensaje.  
3. Verificar que aparece el reproductor global y se oculta el reproductor del mensaje.  
4. Navegar a otra pantalla y confirmar que el reproductor sigue visible y funcional.  
5. Detener la reproducción desde el reproductor global.  
6. Desactivar `enableGlobalPlayer` y reproducir otro audio: debe reproducirse directamente en la burbuja.  

**Resultado Esperado:**  
El componente `AudioPlayerWidget` puede funcionar de forma local o global según la configuración del flag. La experiencia de reproducción es consistente y fluida, replicando el patrón de UX adoptado por apps líderes de mensajería.

**Notas Adicionales / Recomendaciones:**  
- Evaluar el uso de un `Provider` o `Singleton` para mantener el estado del reproductor global.  
- Considerar el impacto en recursos y conflictos si se reproducen múltiples audios simultáneamente.  
- Documentar claramente la lógica que gobierna el cambio entre modo local y global.  
- Revisar la accesibilidad y controles para usuarios con navegación asistida.
