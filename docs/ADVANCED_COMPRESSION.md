# Compresión Avanzada (FFmpeg)

Documentación del flujo de compresión avanzada implementado con `ffmpeg_kit_flutter_new`.

---

## 1. Arquitectura

La compresión avanzada sigue la misma Clean Architecture que la compresión básica.
No existe una arquitectura paralela: se reutilizan las mismas capas con implementaciones específicas para FFmpeg.

```
PRESENTATION
  AdvancedCompressionScreen
  AdvancedCompressorSection
  AdvancedResultSection
  AdvancedVideoInfoTable
  AdvancedCompressionDialog
  VideoBloc (compartido con compresión básica)
    eventos: CompressVideoAdvancedRequested, LoadExtendedMetadataRequested
    estados: compressingAdvanced, activeResult = ActiveResult.advanced

DOMAIN
  CompressVideoAdvancedUseCase
  GetExtendedMetadataUseCase
  GenerateThumbnailUseCase
  AdvancedVideoRepository (interfaz)
  AdvancedCompressionConfig
  AdvancedCompressionResult

DATA
  AdvancedVideoRepositoryImpl
  FfmpegDatasource (compress, getExtendedMetadata, generateThumbnail)
  FfmpegCommandBuilder
```

---

## 2. Diferencias entre Basic y Advanced

| Aspecto              | Basic (video_compress)         | Advanced (FFmpeg)                    |
|----------------------|-------------------------------|--------------------------------------|
| Librería             | `video_compress`              | `ffmpeg_kit_flutter_new`             |
| Parámetros           | Calidad (low/medium/high)     | Bitrate objetivo (kbps)              |
| Diálogo              | `CompressionDialog`           | `AdvancedCompressionDialog`          |
| Sección Comprimir    | `CompressorSection`           | `AdvancedCompressorSection`          |
| Sección Resultado    | `ResultSection`               | `AdvancedResultSection`              |
| Pantalla             | `HomeScreen`                  | `AdvancedCompressionScreen`          |
| Ruta                 | `/home`                       | `/advanced`                          |
| Metadata             | `video_player` (básica)       | FFprobe (bitrate real, fps)          |
| `activeResult`       | `ActiveResult.basic`          | `ActiveResult.advanced`              |

---

## 3. Flujo completo

```
Drawer → "Compresión avanzada"
  → AdvancedCompressionScreen
  → SubirSection (sin video)
  → PickVideoRequested
  → video seleccionado → LoadExtendedMetadataRequested (auto)
  → FFprobe obtiene bitrate real y fps
  → AdvancedCompressorSection muestra tabla con bitrate editable
  → usuario edita bitrate (kbps)
  → pulsa "Comprimir"
  → AdvancedCompressionDialog (Antes vs Después)
  → confirma → CompressVideoAdvancedRequested(config)
  → VideoBloc emite compressingAdvanced
  → navega automáticamente a AdvancedResultSection
  → FFmpeg ejecuta comando
  → VideoBloc emite success + activeResult = advanced
  → GenerateThumbnailRequested (auto)
  → AdvancedResultSection muestra resultado
  → peso real disponible desde compressedVideo.sizeMB
  → SaveVideoRequested → guardado en galería
```

---

## 4. FFmpeg — uso

`FfmpegDatasource.compress()` ejecuta FFmpeg con los argumentos construidos por `FfmpegCommandBuilder`.

Ejemplo de comando generado:
```
ffmpeg -y -i input.mp4 -b:v 1200k -c:a copy output.mp4
```

- `-y`: sobreescribir sin preguntar.
- `-b:v 1200k`: bitrate de video objetivo en kbps.
- `-c:a copy`: audio copiado sin recodificar.

---

## 5. FFprobe — uso

`FfmpegDatasource.getExtendedMetadata()` usa `FFprobeKit.getMediaInformation()` para extraer:

- `bitrate`: del contenedor (incluye audio + video). Unidad: bps.
- `fps`: del stream de video (`getRealFrameRate()`). Puede ser fraccionario (ej. `30000/1001`).
- `width`, `height`: resolución.
- `duration`: duración en segundos.
- `createdAt`: `File.lastModified()` (fecha de procesamiento).

---

## 6. Bitrate — unidades

| Capa         | Unidad  | Ejemplo        |
|--------------|---------|----------------|
| FFprobe      | bps     | 2 500 000      |
| UI (tabla)   | kbps    | 2 500 kbps     |
| TextField    | kbps    | 2 500          |
| FFmpeg `-b:v`| kbps    | 1200k          |
| `AdvancedCompressionConfig.targetVideoBitrate` | bps | 1 200 000 |

Conversión en `AdvancedCompressorSection`:
```dart
// Usuario introduce kbps → config recibe bps
AdvancedCompressionConfig(targetVideoBitrate: targetBitrateKbps * 1000)
```

Conversión en `FfmpegCommandBuilder`:
```dart
final kbps = (config.targetVideoBitrate! / 1000).round();
args.addAll(['-b:v', '${kbps}k']);
```

---

## 7. Edición del bitrate

El bitrate es editable en `AdvancedVideoInfoTable` mediante un `TextField`.

Validaciones implementadas:
- Campo vacío → error "Introduce un bit rate válido".
- Valor 0 o negativo → error "El bit rate debe ser mayor que 0".
- Valor > 100 000 kbps → error "Valor demasiado alto (máx. 100 000 kbps)".
- Caracteres no numéricos → bloqueados por `FilteringTextInputFormatter.digitsOnly`.

El botón "Comprimir" se deshabilita mientras `_targetBitrateKbps == null` (campo inválido).

---

## 8. FPS

Obtenido via FFprobe (`getRealFrameRate()`). Puede devolver:
- Entero: `30` → se muestra como `30 fps`.
- Fraccionario: `30000/1001` → se convierte a `29.97 fps`.

El FPS es informativo en esta versión. No es editable.
La arquitectura está preparada para hacerlo editable: `AdvancedCompressionConfig.targetFps` ya existe.

---

## 9. Diálogo Antes vs Después

`AdvancedCompressionDialog` muestra una tabla comparativa:

| Campo      | Antes       | Después     |
|------------|-------------|-------------|
| Bit rate   | 2500 kbps   | 1200 kbps   |
| FPS        | 30 fps      | 30 fps      |
| Peso est.  | 8.16 MB     | 3.84 MB     |

- FPS solo se muestra si `video.fps > 0`.
- Peso estimado solo se muestra si `video.bitrate > 0`.

---

## 10. Estimación de peso

```
peso_estimado = tamaño_original_MB × (bitrate_objetivo_bps / bitrate_original_bps)
```

Limitaciones:
- El audio permanece constante (no se recodifica con `-c:a copy`).
- El codec puede producir variaciones.
- Se presenta como "Peso est." — nunca como peso final.

El peso final real se obtiene de `File.length()` tras la compresión.

---

## 11. Loading granular del campo Peso

En `AdvancedResultSection` y `AdvancedVideoInfoTable`:

- Durante `compressingAdvanced`: `isSizeLoading: true` → shimmer solo en la fila "Peso".
- Tras `success`: `finalSizeMB: result.compressedVideo.sizeMB` → peso real.
- El resto de la tabla (Nombre, Duración, Fecha, Bit rate, FPS) permanece visible y estable.

---

## 12. Peso final

Obtenido de `compressedVideo.sizeMB` que proviene de `File(outputPath).length()` en `FfmpegDatasource.compress()`.

No se usa la estimación del diálogo como peso final.

---

## 13. Thumbnail

Reutiliza `GenerateThumbnailUseCase` y `FfmpegDatasource.generateThumbnail()`.

Se dispara automáticamente en `VideoBloc._onCompressVideoAdvancedRequested()` tras el éxito:
```dart
add(GenerateThumbnailRequested(result.compressedVideo.path));
```

El thumbnail corresponde al video comprimido por FFmpeg, no al original.

---

## 14. Guardado en galería

Reutiliza `SaveVideoUseCase` y `VideoStorageDatasource` (gal).

`VideoBloc._onSaveVideoRequested()` usa `state.activeCompressedVideo`:
- Si `activeResult == ActiveResult.advanced` → usa `advancedCompressionResult.compressedVideo`.
- Si `activeResult == ActiveResult.basic` → usa `compressionResult.compressedVideo`.

---

## 15. Cambios en VideoState

Añadidos:
- `ActiveResult activeResult` — indica qué resultado está activo (none/basic/advanced).
- `VideoFile? activeCompressedVideo` — getter que devuelve el video correcto según `activeResult`.

---

## 16. Cambios en VideoBloc

- `_onCompressVideoAdvancedRequested`: ahora emite `activeResult: ActiveResult.advanced` y auto-dispara `GenerateThumbnailRequested`.
- `_onCompressVideoRequested`: ahora emite `activeResult: ActiveResult.basic`.
- `_onSaveVideoRequested`: usa `state.activeCompressedVideo` en lugar de `state.compressionResult`.

---

## 17. Cambios en FfmpegCommandBuilder

Sin cambios estructurales. El bitrate ya era dinámico desde la implementación anterior.
El valor proviene de `AdvancedCompressionConfig.targetVideoBitrate` (bps) y se convierte a kbps internamente.

---

## 18. Navegación

- Ruta: `/advanced` → `AdvancedCompressionScreen`.
- Drawer: "Compresión avanzada / FFmpeg" navega con `context.push(AppRoutes.advanced)`.
- La pantalla avanzada tiene su propio `VideoBloc` independiente del de `HomeScreen`.

---

## 19. Tests

Archivo: `test/unit/bloc/video_bloc_advanced_test.dart`

Grupos cubiertos:
- `LoadExtendedMetadataRequested`: metadata, FPS fraccionario, manejo de error.
- `Bitrate — validación y conversión`: kbps↔bps, límites, AdvancedCompressionConfig.
- `Estimación de peso`: cálculo, null cuando bitrate=0.
- `CompressVideoAdvancedRequested`: éxito, failure FFmpeg, sin video.
- `FfmpegCommandBuilder — bitrate dinámico`: no hardcodeado.
- `AdvancedResultSection — peso granular`: sizeMB, savedPercentage.
- `SaveVideoRequested — con resultado avanzado`: saving→saved.
- `Regresión — activeResult.basic`: compresión básica sigue funcionando.

Total: 53 tests pasando (24 previos + 29 nuevos).
