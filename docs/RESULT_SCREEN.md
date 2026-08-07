# Result Screen — Thumbnails, Metadata y Flujo Completo

Este documento describe la implementación de la pantalla de resultado ampliada: thumbnail real, metadata completa (fecha y bitrate), botón "Subir otro video" y cambio de etiqueta de tab.

---

## 🖼️ Thumbnail del video comprimido

### Cómo se genera

FFmpeg extrae el frame del segundo 1 del video comprimido como imagen JPEG:

```
ffmpeg -y -i video.mp4 -ss 00:00:01 -vframes 1 -q:v 2 thumb.jpg
```

Si el video es más corto que 1 segundo, se usa un fallback sin `-ss` para capturar el primer frame disponible.

### Por qué FFmpeg y no una librería de thumbnails

- `ffmpeg_kit_flutter_new` ya estaba instalado en el proyecto.
- No requiere dependencia adicional.
- Produce thumbnails de alta calidad con control total de parámetros.
- Consistente con el motor de compresión avanzada ya implementado.

### Flujo arquitectónico

```
VideoBloc (GenerateThumbnailRequested)
    ↓
GenerateThumbnailUseCase
    ↓
AdvancedVideoRepository.generateThumbnail()
    ↓
AdvancedVideoRepositoryImpl
    ↓
FfmpegDatasource.generateThumbnail()
    ↓
FFmpegKit.executeWithArguments([...])
    ↓
Archivo JPEG en directorio temporal
    ↓
state.thumbnailPath (VideoState)
    ↓
VideoPreviewWidget (FileImage)
```

### Cuándo se genera

El thumbnail se genera **automáticamente** al finalizar la compresión básica (`video_compress`). El BLoC despacha `GenerateThumbnailRequested` internamente tras emitir el resultado de compresión:

```dart
// En _onCompressVideoRequested, tras emitir success:
add(GenerateThumbnailRequested(result.compressedVideo.path));
```

### Manejo de errores

El thumbnail es **no crítico**. Si FFmpeg falla:
- El BLoC emite `VideoStatus.success` con `thumbnailPath = null`.
- La compresión **no se considera fallida**.
- `VideoPreviewWidget` muestra el placeholder con ícono de video.

### Estados de UI

| `VideoStatus` | Comportamiento del preview |
|---|---|
| `generatingThumbnail` | Overlay semitransparente con spinner sobre el preview |
| `success` + `thumbnailPath != null` | Imagen real del video |
| `success` + `thumbnailPath == null` | Placeholder con ícono |

### Archivos involucrados

| Archivo | Cambio |
|---|---|
| `FfmpegDatasource` | Nuevo método `generateThumbnail()` |
| `AdvancedVideoRepository` | Nuevo método abstracto `generateThumbnail()` |
| `AdvancedVideoRepositoryImpl` | Implementación delegando a `FfmpegDatasource` |
| `GenerateThumbnailUseCase` | Nuevo use case en dominio |
| `video_event.dart` | Nuevo evento `GenerateThumbnailRequested` |
| `video_state.dart` | Nuevo campo `thumbnailPath`, nuevo status `generatingThumbnail` |
| `video_bloc.dart` | Handler `_onGenerateThumbnailRequested` |
| `injection_container.dart` | Registro de `GenerateThumbnailUseCase` |

---

## 📊 Metadata real: Fecha y Bit rate

### Fecha

**¿Qué representa?** La fecha de modificación del archivo comprimido, que equivale a la fecha en que fue procesado/comprimido. Es la fuente más confiable porque:
- El archivo comprimido siempre tiene una fecha de modificación real.
- No depende de metadata embebida en el contenedor de video (que puede estar ausente).
- Es consistente entre Android e iOS.

**Cómo se obtiene:** `File(videoPath).lastModified()` en `FfmpegDatasource.getExtendedMetadata()`.

**Formato de visualización:** `dd/MM/yyyy` (ej. `29/07/2026`) usando `intl`.

**Fallback:** Si `createdAt == null`, la tabla muestra `--`.

### Bit rate

**¿Qué tipo de bitrate se muestra?** El bitrate total del contenedor (audio + video), obtenido de `info.getBitrate()` via FFprobe. Es el más representativo para el usuario porque refleja el tamaño real del archivo.

**Cómo se obtiene:** `FFprobeKit.getMediaInformation()` → `info.getBitrate()` en `FfmpegDatasource.getExtendedMetadata()`.

**Conversión de unidades:**

| Valor en bps | Formato mostrado |
|---|---|
| `0` | `--` |
| `< 1,000,000` | `X kbps` (ej. `800 kbps`) |
| `>= 1,000,000` | `X.X Mbps` (ej. `2.5 Mbps`) |

**Fallback:** Si FFprobe no devuelve bitrate (`bitrate == 0`), la tabla muestra `--`.

### Cuándo se obtiene la metadata extendida

`VideoCompressorDatasource` ahora llama a `FfmpegDatasource.getExtendedMetadata()` en lugar de `VideoMetadataDatasource.getVideoMetadata()` tras la compresión. Esto garantiza que el `CompressionResult` ya contiene bitrate real y fecha desde el primer momento.

### Archivos involucrados

| Archivo | Cambio |
|---|---|
| `FfmpegDatasource.getExtendedMetadata()` | Agrega `createdAt` via `File.lastModified()` |
| `VideoCompressorDatasource` | Inyecta `FfmpegDatasource`, usa `getExtendedMetadata()` post-compresión |
| `VideoInfoTableWidget` | Muestra fecha formateada y bitrate en Mbps/kbps |
| `injection_container.dart` | `VideoCompressorDatasource` recibe `FfmpegDatasource` |

---

## ➕ Botón "Subir otro video"

### Condición de visibilidad

El botón aparece **únicamente** cuando `state.status == VideoStatus.saved`. La fuente de verdad es el estado del BLoC — no hay variable local en el widget.

```dart
if (isSaved) ...[
  OutlinedButton.icon(
    onPressed: () => context.read<VideoBloc>().add(const ResetVideoRequested()),
    icon: const Icon(Icons.add_circle_outline),
    label: const Text('Subir otro video'),
  ),
]
```

| Estado | Botón visible |
|---|---|
| `success` (sin guardar) | ❌ |
| `saving` | ❌ |
| `saved` | ✅ |
| `failure` | ❌ |

### Qué hace al pulsarlo

1. Despacha `ResetVideoRequested` al BLoC.
2. El BLoC emite `const VideoState()` — estado completamente limpio (sin video, sin resultado, sin thumbnail, sin error).
3. Inmediatamente despacha `PickVideoRequested` para abrir el selector de archivos.
4. La UI vuelve al estado inicial: tabs `['Subir', 'Resultado']`, sección de upload visible.

```dart
Future<void> _onResetVideoRequested(...) async {
  emit(const VideoState());       // Limpia todo
  add(const PickVideoRequested()); // Abre el picker
}
```

### Archivos involucrados

| Archivo | Cambio |
|---|---|
| `video_event.dart` | Nuevo evento `ResetVideoRequested` |
| `video_bloc.dart` | Handler `_onResetVideoRequested` |
| `result_section_widget.dart` | Botón condicional `if (isSaved)` |

---

## 🏷️ Cambio de etiqueta: "Compresor" → "Comprimir"

Cambio puramente de presentación en `compressor_screen.dart`:

```dart
// Antes:
const ['Compresor', 'Resultado']

// Después:
const ['Comprimir', 'Resultado']
```

No se modificaron nombres de clases, carpetas ni arquitectura interna.

---

## 🧪 Tests

### Archivos de test

- `test/unit/bloc/video_bloc_result_test.dart` — nuevo
- `test/unit/bloc/video_bloc_save_test.dart` — actualizado (agregado `generateThumbnailUseCase`)

### Casos cubiertos (24 tests totales)

| Grupo | Tests |
|---|---|
| `GenerateThumbnailUseCase` | Caso exitoso, propagación de excepción |
| `VideoBloc — GenerateThumbnailRequested` | `generatingThumbnail → success` con path, `success` con null cuando FFmpeg falla (no crítico) |
| `VideoBloc — ResetVideoRequested` | Estado limpio tras reset |
| `VideoFile — bitrate` | 0 bps, 800 kbps, 2.5 Mbps, threshold 1 Mbps |
| `VideoFile — createdAt` | Fecha disponible, fecha null |
| `VideoBloc — "Subir otro video"` | Visibilidad en `success`, `saved`, `saving`, `failure` |
| `SaveVideoUseCase` | Caso exitoso, propagación de excepción |
| `VideoBloc — SaveVideoRequested` | `failure` sin resultado, `saving→saved`, `saving→failure`, duplicados en `saving` y `saved` |

---

## 📱 Cómo probar manualmente

### Flujo completo

1. Abrir la app → pantalla "Subir"
2. Pulsar el área de upload → seleccionar un video
3. La app navega automáticamente a "Comprimir"
4. Pulsar "Comprimir" → seleccionar calidad → confirmar
5. La app navega a "Resultado" y muestra el spinner de compresión
6. Al terminar: aparece la miniatura real del video, fecha y bitrate en la tabla
7. Mientras se genera el thumbnail: overlay semitransparente con spinner sobre el preview
8. Pulsar "Guardar video" → el botón cambia a "Guardando..." y luego a "✓ Guardado"
9. Aparece el botón "Subir otro video"
10. Pulsar "Subir otro video" → se abre el selector de archivos para un nuevo video
11. Verificar que no queda información del video anterior

### Verificar thumbnail

- Video normal (> 1 seg): debe mostrar el frame del segundo 1
- Video muy corto (< 1 seg): debe mostrar el primer frame disponible
- Si FFmpeg falla: debe mostrar el placeholder con ícono, sin crashear

### Verificar metadata

- Fecha: debe mostrar la fecha actual en formato `dd/MM/yyyy`
- Bitrate: debe mostrar un valor real en Mbps o kbps (no `--` ni `0`)
- Si FFprobe no puede leer el archivo: debe mostrar `--` sin crashear
