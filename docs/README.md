# Robot Video Compressor - Documentation Index

Welcome to the documentation for the Robot Video Compressor project, a Flutter-based mobile application designed for local video compression with a clean, responsive workflow.

---

## 📋 Documentation Index

1. **[STATUS.md](./STATUS.md)** - Implementation checklist (fully functional, mocked, and pending features)
2. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - High-level layers, clean architecture patterns, and data flows
3. **[BLOC_SYSTEM.md](./BLOC_SYSTEM.md)** - Business logic components and state management flows
4. **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - Complete file and folder hierarchy explained
5. **[COMPONENTS.md](./COMPONENTS.md)** - Details on UI screens, custom painters, and presentation widgets
6. **[COLOR_PALETTE.md](./COLOR_PALETTE.md)** - Dark mode guidelines, hex colors, and design tokens
7. **[GETTING_STARTED.md](./GETTING_STARTED.md)** - Local environment setup, prerequisites, and build commands
8. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Code templates, utilities, and common terminal shortcuts
9. **[SAVE_VIDEO.md](./SAVE_VIDEO.md)** - Diagnóstico y solución completa del botón "Guardar video"
10. **[RESULT_SCREEN.md](./RESULT_SCREEN.md)** - Thumbnail, metadata (fecha/bitrate), "Subir otro video" y tab "Comprimir"

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone [repo-url]
cd robot_compresor_video

# 2. Get Dart dependencies
flutter pub get

# 3. Verify installation environment
flutter doctor

# 4. Run the app in development mode
flutter run
```

---

## 📱 Core Features & Current Scope

- **Dynamic Tab Layout**: Adapts layout based on the app state (e.g., switches the initial tab from "Upload" to "Compressor" once a video has been picked).
- **Smooth PageView Navigation**: Swipes horizontally across 3 main sections (Upload/Compressor, Advanced, and Results).
- **Responsive Layouts**: Utilizing `ScreenSizeService` to calculate proportions dynamically for different devices.
- **Dependency Injection**: Scalable and testable component registry managed using the `get_it` service locator.
- **Dark Theme Mode**: Designed from scratch with custom theme settings.

---

## 🛠️ Technology Stack

- **Flutter**: Cross-platform mobile UI framework.
- **Dart**: Underlying programming language.
- **flutter_bloc**: Bloc pattern implementation for clean state boundaries.
- **go_router**: Route-based declarative navigation.
- **get_it**: Service locator for dependency injection.
- **equatable**: Object-level value equality helper.
- **video_player**: Extracting basic video metadata (resolution, duration).
- **video_compress**: Basic compression engine — quality presets (low/medium/high).
- **ffmpeg_kit_flutter_new**: Advanced compression engine — full FFmpeg/FFprobe control (bitrate, fps, and more).

---

## 📞 Support & Contribution

If you experience issues, consult [STATUS.md](./STATUS.md) to check if a feature is fully implemented, or refer to [GETTING_STARTED.md](./GETTING_STARTED.md) for local troubleshooting guides.
