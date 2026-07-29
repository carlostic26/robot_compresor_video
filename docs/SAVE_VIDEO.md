# Save Video to Gallery — Implementación y Diagnóstico

Este documento describe el análisis, los problemas encontrados y la solución implementada para la funcionalidad "Guardar video" de la pantalla de resultado.

---

## 🔍 Estado inicial (antes de la corrección)

### ¿El botón funcionaba de extremo a extremo?

**No completamente.** La arquitectura estaba parcialmente implementada pero tenía tres defectos críticos:

| Capa | Estado previo |
|---|---|
| Widget (`result_section_widget.dart`) | ✅ Botón existía y disparaba `SaveVideoRequested` |
| BLoC (`video_bloc.dart`) | ❌ Handler no emitía `saving` ni `saved` — los estados existían en el enum pero nunca se usaban |
| Use Case (`SaveVideoUseCase`) | ✅ Existía y funcionaba correctamente |
| Repository (`VideoRepository` / `VideoRepositoryImpl`) | ✅ Existía y delegaba al datasource |
| DataSource (`VideoStorageDatasource`) | ✅ Existía, usaba `gal` correctamente |
| Librería (`gal`) | ✅ Ya estaba instalada en `pubspec.yaml` |
| Permisos Android | ❌ Faltaba `WRITE_EXTERNAL_STORAGE` para Android ≤ 28 |
| Permisos iOS | ❌ Faltaba `NSPhotoLibraryAddUsageDescription` en `Info.plist` |
| Feedback visual | ❌ El SnackBar de éxito estaba dentro del `builder` del BlocBuilder (incorrecto) |
| Protección contra doble pulsación | ❌ El botón no se deshabilitaba durante el guardado |

### ¿Qué hacía realmente el botón?

Al pulsarlo:
1. Disparaba `SaveVideoRequested` al BLoC ✅
2. El BLoC llamaba a `saveVideoUseCase` ✅
3. `gal` intentaba guardar el video ✅ (si los permisos estaban concedidos)
4. **Nunca emitía `VideoStatus.saving` ni `VideoStatus.saved`** ❌
5. El botón no cambiaba de estado visual ❌
6. El SnackBar de éxito nunca se mostraba ❌ (estaba en el `builder`, no en el `listener`)
7. En Android < 29 o iOS, fallaba silenciosamente por falta de permisos ❌

---

## ✅ Cambios realizados

### 1. `video_bloc.dart` — Handler `_onSaveVideoRequested`

**Problema:** No emitía `saving` ni `saved`. No protegía contra pulsaciones múltiples.

**Solución:**
```dart
Future<void> _onSaveVideoRequested(...) async {
  // Guard: evita guardados duplicados
  if (state.status == VideoStatus.saving || state.status == VideoStatus.saved) {
    return;
  }

  emit(state.copyWith(status: VideoStatus.saving));   // ← NUEVO
  try {
    await saveVideoUseCase(result.compressedVideo);
    emit(state.copyWith(status: VideoStatus.saved));  // ← NUEVO
  } catch (e) {
    emit(state.copyWith(status: VideoStatus.failure, error: e.toString()));
  }
}
```

### 2. `result_section_widget.dart` — UI del botón

**Problema:** Usaba `BlocBuilder` para mostrar el SnackBar (incorrecto — el builder se llama en cada rebuild). El botón no reflejaba el estado de guardado.

**Solución:** Migrado a `BlocConsumer`:
- `listener`: muestra SnackBar de éxito o error **una sola vez** cuando el estado cambia
- `builder`: deshabilita el botón durante `saving` y `saved`, muestra spinner o ícono de check

```dart
// Estados del botón:
// - Normal:    icono save_alt  + texto "Guardar video"   + onPressed activo
// - Guardando: spinner         + texto "Guardando..."    + onPressed null
// - Guardado:  icono check     + texto "Guardado"        + onPressed null
```

### 3. `AndroidManifest.xml` — Permiso Android

```xml
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />
```

- Solo aplica a Android 9 (API 28) e inferior
- Android 10+ (API 29+) usa MediaStore y no requiere este permiso
- `gal` gestiona la solicitud en runtime automáticamente

### 4. `ios/Runner/Info.plist` — Permiso iOS

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Robot Compresor de Video necesita acceso a tu galería para guardar los videos comprimidos.</string>
```

- Requerido por iOS para guardar contenido en la app Fotos
- Sin esta clave, la app crashea en iOS al intentar guardar

---

## 🏗️ Arquitectura del flujo completo

```
ResultSection (Widget)
    │
    │  onPressed → context.read<VideoBloc>().add(SaveVideoRequested())
    ▼
VideoBloc._onSaveVideoRequested()
    │  emit(saving)
    │  await saveVideoUseCase(video)
    │  emit(saved) ─── o ─── emit(failure)
    ▼
SaveVideoUseCase.call(VideoFile video)
    │  repository.saveVideo(video)
    ▼
VideoRepository (abstract interface)
    ▼
VideoRepositoryImpl.saveVideo(VideoFile video)
    │  storageDatasource.saveVideo(video.path)
    ▼
VideoStorageDatasource.saveVideo(String videoPath)
    │  Gal.hasAccess() → Gal.requestAccess() si es necesario
    │  Gal.putVideo(videoPath)
    ▼
gal (plugin Flutter)
    ▼
Galería del dispositivo (Android MediaStore / iOS Photos)
```

---

## 📦 Librería utilizada: `gal`

`gal` ya estaba instalada en el proyecto. No se agregó ninguna dependencia nueva.

**¿Por qué `gal`?**
- API simple: `Gal.putVideo(path)` y `Gal.hasAccess()`
- Maneja permisos en runtime automáticamente
- Compatible con Android (MediaStore en API 29+, legacy en API 28-)
- Compatible con iOS (Photos framework)
- Mantenida activamente en pub.dev
- Ya integrada en la arquitectura existente del proyecto

---

## 🎛️ Estados de UI

| `VideoStatus` | Botón | Texto | Ícono |
|---|---|---|---|
| `success` (con resultado) | Habilitado | "Guardar video" | `save_alt` |
| `saving` | Deshabilitado | "Guardando..." | Spinner |
| `saved` | Deshabilitado | "Guardado" | `check` |
| `failure` | Habilitado | "Guardar video" | `save_alt` |

El estado `failure` reactiva el botón para permitir reintentar.

---

## ⚠️ Errores manejados

| Error | Causa | Comportamiento |
|---|---|---|
| `Permiso denegado` | Usuario rechazó el permiso de galería | SnackBar rojo con mensaje de error, botón se reactiva |
| `No existe un video comprimido` | `compressionResult` es null | SnackBar rojo, status `failure` |
| Archivo no encontrado | Ruta inválida o archivo eliminado | Excepción propagada desde `gal`, capturada en BLoC |
| Error de almacenamiento | Disco lleno u otro error del SO | Excepción propagada desde `gal`, capturada en BLoC |

---

## 🧪 Tests

### Archivos creados

- `test/unit/use_cases/save_video_use_case_test.dart`
- `test/unit/bloc/video_bloc_save_test.dart`

### Dependencias de test agregadas

- `mocktail` — mocking de dependencias
- `bloc_test` — helpers para testear BLoCs

### Casos cubiertos

| Test | Descripción |
|---|---|
| `SaveVideoUseCase` — caso exitoso | Verifica que llama a `repository.saveVideo` con el video correcto |
| `SaveVideoUseCase` — error | Verifica que propaga la excepción del repositorio |
| `VideoBloc` — sin resultado | Emite `failure` si no hay `compressionResult` |
| `VideoBloc` — caso exitoso | Emite `saving → saved` |
| `VideoBloc` — error del datasource | Emite `saving → failure` con mensaje de error |
| `VideoBloc` — duplicado en `saving` | Ignora el evento si ya está guardando |
| `VideoBloc` — duplicado en `saved` | Ignora el evento si ya fue guardado |

Todos los tests pasan: **8/8** ✅

---

## 📱 Cómo probar manualmente

### Android

1. Instalar en dispositivo físico o emulador con Android 9+ (API 28+)
2. Seleccionar un video desde la sección "Subir"
3. Comprimir el video (sección "Compresor" → botón "Comprimir")
4. Navegar a la sección "Resultado"
5. Pulsar "Guardar video"
6. Si es la primera vez, el sistema mostrará un diálogo de permisos — conceder acceso
7. Verificar que el botón cambia a "Guardando..." y luego a "Guardado"
8. Verificar el SnackBar "✅ Video guardado en la galería"
9. Abrir la app de Galería/Fotos del dispositivo y verificar que el video aparece

**Android 10+ (API 29+):** No se solicita permiso de almacenamiento — `gal` usa MediaStore directamente.

**Android 9 (API 28) e inferior:** Se solicita `WRITE_EXTERNAL_STORAGE` en runtime.

### iOS

1. Instalar en dispositivo físico o simulador iOS 14+
2. Seguir los mismos pasos 2–8 de Android
3. En el paso 6, iOS mostrará el diálogo de permisos de Fotos con el texto configurado en `Info.plist`
4. Verificar que el video aparece en la app Fotos del dispositivo

### Verificar protección contra doble pulsación

1. Pulsar "Guardar video" rápidamente varias veces
2. Verificar que el botón se deshabilita inmediatamente tras la primera pulsación
3. Verificar que el video aparece una sola vez en la galería

### Verificar manejo de error

1. Revocar el permiso de galería desde Ajustes del dispositivo
2. Pulsar "Guardar video"
3. Verificar que aparece el SnackBar rojo con el mensaje de error
4. Verificar que el botón vuelve a estar habilitado para reintentar
