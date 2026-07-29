# Project Implementation Status

This document tracks the actual implementation progress of the Robot Video Compressor application.

---

## 📊 Summary of Feature Status

| Feature / Component | Status | Description / Notes |
|---|---|---|
| **Video Picking** | ✅ Implemented | Uses `file_picker` to select a single video file. |
| **Metadata Extraction (basic)** | 🟡 Partial | Extracts resolution and duration via `video_player`. Bitrate and fps return `0` until extended metadata is loaded. |
| **Metadata Extraction (extended)** | ✅ Implemented | `GetExtendedMetadataUseCase` uses FFprobe to extract real bitrate, fps, resolution and duration. Triggered via `LoadExtendedMetadataRequested` event. |
| **Video Compression (basic)** | ✅ Implemented | `VideoCompressorDatasource` uses `video_compress`. Supports low/medium/high quality presets. |
| **Video Compression (advanced)** | ✅ Implemented (logic only) | `FfmpegDatasource` + `FfmpegCommandBuilder` fully wired. UI pending (next iteration). |
| **Home Navigation** | ✅ Implemented | Sliding `PageView` with synchronized dynamic section tabs. |
| **Dynamic Tab Logic** | ✅ Implemented | Switches tabs from `['Subir', 'Avanzado', 'Resultado']` to `['Compresor', 'Avanzado', 'Resultado']` when a video is loaded. |
| **Save to Gallery** | ✅ Implemented | `VideoStorageDatasource` usa `gal`. BLoC emite `saving → saved`. Botón con feedback visual completo. |
| **Advanced Section UI** | ❌ Pending | Placeholder only. Will connect to `CompressVideoAdvancedRequested` in next iteration. |
| **Result Section UI** | ❌ Pending | Placeholder only. |

---

## 🔍 Detailed Breakdown

### 1. File Upload / Video Picking
- **Location**: [video_picker_datasource.dart](file:///c:/projects/robot_compresor_video/lib/features/compress_video/data/datasources/video_picker_datasource.dart)
- **Status**: Fully Functional
- Uses `file_picker` to retrieve absolute path, file name, and file size.

### 2. Video Metadata Extraction

#### Basic (video_player)
- **Location**: [video_metadata_datasource.dart](file:///c:/projects/robot_compresor_video/lib/features/compress_video/data/datasources/video_metadata_datasource.dart)
- **Status**: Partially Functional
- Extracts resolution (`width`, `height`) and `duration`. `bitrate` and `fps` return `0`.

#### Extended (FFprobe)
- **Location**: [ffmpeg_datasource.dart](file:///c:/projects/robot_compresor_video/lib/features/compress_video/data/datasources/ffmpeg_datasource.dart) → `getExtendedMetadata()`
- **Status**: Fully Implemented
- Uses `FFprobeKit.getMediaInformation()` to extract real `bitrate`, `fps`, `width`, `height`, and `duration`.
- Triggered by dispatching `LoadExtendedMetadataRequested` to `VideoBloc`.
- Falls back gracefully to basic metadata if FFprobe fails.

### 3. Video Compression — Basic Engine (video_compress)
- **Location**: [video_compressor_datasource.dart](file:///c:/projects/robot_compresor_video/lib/features/compress_video/data/datasources/video_compressor_datasource.dart)
- **Status**: Fully Implemented
- Uses `VideoCompress.compressVideo()` with quality mapping: `low → LowQuality`, `medium → MediumQuality`, `high → HighestQuality`.
- Output file is renamed with `compressed_<timestamp>_<originalName>` pattern.
- BLoC event: `CompressVideoRequested(config: CompressionConfig(...))`.

### 4. Video Compression — Advanced Engine (FFmpeg)
- **Location**: [ffmpeg_datasource.dart](file:///c:/projects/robot_compresor_video/lib/features/compress_video/data/datasources/ffmpeg_datasource.dart)
- **Command builder**: [ffmpeg_command_builder.dart](file:///c:/projects/robot_compresor_video/lib/features/compress_video/data/datasources/ffmpeg_command_builder.dart)
- **Status**: Logic fully implemented. UI pending.
- Accepts `AdvancedCompressionConfig` with `targetVideoBitrate` and `targetFps`.
- `FfmpegCommandBuilder` constructs the argument list dynamically — extensible for CRF, codec, resolution, preset, audio without architectural changes.
- Output file is named `ffmpeg_<timestamp>_<originalName>`.
- BLoC event: `CompressVideoAdvancedRequested(config: AdvancedCompressionConfig(...))`.
- Result includes `ffmpegCommand` string for debugging.

### 5. Dynamic Tab System & Screens
- **Location**: [home_screen.dart](file:///c:/projects/robot_compresor_video/lib/features/home/presentation/home_screen.dart)
- **Status**: UI works; Advanced and Result sections are placeholders.
- When a video is selected, the first tab switches from **"Subir"** to **"Compresor"**.
- Advanced section will connect to `CompressVideoAdvancedRequested` in the next UI iteration.

---

## 🔮 Next Iteration (UI for Advanced Section)

To connect the future Advanced Section UI to the existing logic:

```dart
// The widget only needs to dispatch this event:
context.read<VideoBloc>().add(
  CompressVideoAdvancedRequested(
    config: AdvancedCompressionConfig(
      targetVideoBitrate: 4000000, // 4 Mbps
      targetFps: 30,
    ),
  ),
);

// And listen to these states:
// VideoStatus.compressingAdvanced → show progress indicator
// VideoStatus.success + state.advancedCompressionResult != null → show result
// VideoStatus.failure + state.error → show error message
```
