# Navigation & Home — Documentación

Este documento describe la navegación central, la pantalla Home, los diálogos y los flujos de compresión.

---

## 🏠 HomeScreen — Pantalla principal

**Archivo**: `lib/features/home/presentation/home_screen.dart`
**Ruta**: `/home`

Pantalla de entrada de la aplicación. Presenta dos cards navegables.

| Card | Destino | Flujo |
|---|---|---|
| Compresión básica | `context.push('/basic')` | Navegación directa |
| Compresión avanzada | `context.go('/advanced')` | Navegación directa |

El diálogo informativo de FFmpeg aparece al entrar a la opción avanzada desde Home o Drawer.

---

## 🗂️ Drawer — Navegación

**Archivo**: `lib/features/home/presentation/widgets/app_drawer.dart`

Todas las rutas usan `context.go` para garantizar que cada navegación destruye la pantalla anterior y crea un `VideoBloc` nuevo e independiente.

| Opción | Acción |
|---|---|
| Inicio | `context.go(AppRoutes.home)` |
| Compresión básica | `context.push(AppRoutes.basic)` |
| Compresión avanzada | `context.go(AppRoutes.advanced)` |
| Información | `AppInfoDialog.show(context)` |

---

## ℹ️ AppInfoDialog — Diálogo de información

**Archivo**: `lib/features/home/presentation/widgets/app_info_dialog.dart`

Diálogo único reutilizable. Se abre desde:
- Opción "Información" del Drawer
- Botón `info_outline` del AppBar (HomeScreen y CompressorScreen)

```dart
AppInfoDialog.show(context);
```

---

## ⭐ Flujo de calificación

```
AppInfoDialog → botón "Calificar" → _RateDialog → abrir Play Store
```

URL centralizada en `AppConstants.playStoreUrl`. Si está vacía, muestra SnackBar informativo sin errores.

---

## 🚀 Flujo de compresión avanzada

**Diálogo**: `lib/features/home/presentation/widgets/advanced_mode_dialog.dart`

```
HomeScreen / Drawer
  → Tocar "Compresión avanzada"
    → AdvancedModeDialog (explicativo FFmpeg)
      → Cancelar → no navega
      → Continuar → AdvancedCompressionScreen

AdvancedCompressionScreen
  → Seleccionar video
  → Configurar bit rate y fps
  → Pulsar "Comprimir"
    → AdvancedCompressionDialog (tabla Antes vs Después)
      → Cancelar → no se inicia compresión
      → Comprimir → ejecutar FFmpeg
```

---

## 🔒 Aislamiento de estado entre modos

**Causa del bug**: El Drawer usaba `context.push` para navegar a `/advanced`, dejando la pantalla anterior viva en el stack. Aunque `AdvancedCompressionScreen` crea su propio `BlocProvider<VideoBloc>`, el uso de `push` podía generar ambigüedad en el árbol de contextos en ciertos escenarios de navegación.

**Solución**: La navegación de entrada usa rutas dedicadas para Home, Básica y Avanzada, aislando el estado por pantalla.

- `CompressorScreen` → `BlocProvider<VideoBloc>(create: (_) => getIt<VideoBloc>())` → instancia propia
- `AdvancedCompressionScreen` → `BlocProvider<VideoBloc>(create: (_) => getIt<VideoBloc>())` → instancia propia
- Cada navegación crea su flujo correspondiente sin reutilizar estado de compresión previo

---

## 📊 Metadata: Fecha y Bit Rate en ambos modos

### Flujo de obtención

```
Video seleccionado
  → VideoMetadataDatasource.getVideoMetadata()
    → bitrate: 0, createdAt: file.lastModified() (fecha básica inmediata)
  → Listener detecta bitrate == 0
    → LoadExtendedMetadataRequested
      → FfmpegDatasource.getExtendedMetadata() (FFprobe)
        → bitrate real, fps, createdAt real
        → VideoState.video actualizado
```

### Disponibilidad por modo

| Campo | Básica (CompressorScreen) | Avanzada (AdvancedCompressionScreen) |
|---|---|---|
| Fecha (createdAt) | ✅ Inmediata (lastModified) + FFprobe | ✅ Inmediata (lastModified) + FFprobe |
| Bit Rate | ✅ FFprobe tras selección | ✅ FFprobe tras selección |
| FPS | ✅ FFprobe tras selección | ✅ FFprobe tras selección |

### Metadata en Resultado

- **Básica**: `VideoCompressorDatasource.compress()` llama a `ffmpegDatasource.getExtendedMetadata()` sobre el archivo comprimido → `CompressionResult.compressedVideo` tiene bitrate real, fecha y fps del archivo final.
- **Avanzada**: `FfmpegDatasource.compress()` llama a `getExtendedMetadata()` sobre el output → `AdvancedCompressionResult.compressedVideo` tiene todos los campos del archivo final.

---

## 📢 Preparación para anuncios

El parámetro `onContinue` de `AdvancedModeDialog` es el único punto a modificar cuando se integre el SDK de anuncios.

```dart
// Caller actual (sin anuncios) — en AdvancedCompressorSection:
await AdvancedModeDialog.showAsync(
  context,
  onContinue: () { shouldProceed = true; },
);

// Caller futuro (con anuncios):
await AdvancedModeDialog.showAsync(
  context,
  onContinue: () async {
    await AdService.showInterstitial();
    shouldProceed = true;
  },
);
```

No se requieren cambios en `AdvancedModeDialog`, `AdvancedCompressionScreen` ni en el Drawer.

---

## 📁 Archivos creados / modificados

### Nuevos
| Archivo | Descripción |
|---|---|
| `lib/features/home/presentation/home_screen.dart` | Pantalla Home con las dos cards |
| `lib/features/home/presentation/widgets/app_info_dialog.dart` | Diálogo de información + flujo de calificación |
| `lib/features/home/presentation/widgets/advanced_mode_dialog.dart` | Diálogo explicativo del modo avanzado (punto de extensión para anuncios) |

### Modificados
| Archivo | Cambio |
|---|---|
| `lib/core/constants/app_constants.dart` | Agregado `playStoreUrl` centralizado |
| `lib/core/routes/app_routes.dart` | Ruta principal `/home` y ruta básica `/basic` |
| `lib/core/routes/app_router.dart` | Registra `HomeScreen` en `/home` y `CompressorScreen` en `/basic` |
| `lib/features/home/presentation/widgets/app_drawer.dart` | Navegación hacia Home/Básica/Avanzada y diálogo introductorio en avanzada |
| `lib/features/home/presentation/home_screen.dart` | Tarjetas de navegación (básica/avanzada) y diálogo introductorio en avanzada |
| `lib/features/home/presentation/compressor_screen.dart` | Listener dispara `LoadExtendedMetadataRequested` al seleccionar video |
| `lib/features/home/presentation/sections/advanced_compressor_section.dart` | Botón Comprimir muestra solo `AdvancedCompressionDialog` |
| `lib/features/compress_video/data/datasources/video_metadata_datasource.dart` | `createdAt` se obtiene desde `file.lastModified()` como fallback inmediato |
| `pubspec.yaml` | Agregado `url_launcher: ^6.3.1` |
