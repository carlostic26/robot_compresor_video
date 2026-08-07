# Project Directory Structure

This document details the file layout, folders, and architecture folders inside the Robot Video Compressor repository.

---

## 📁 Repository Directory Tree

```
robot_compresor_video/
│
├── android/                            # Native Android platform configuration
│   ├── app/                            # Application module container
│   │   ├── build.gradle.kts            # Build scripts
│   │   └── src/                        # Native Java/Kotlin source directories
│   └── gradle/                         # Gradle wrappers
│
├── ios/                                # Native iOS platform configuration
│   ├── Runner.xcodeproj/               # Xcode project workspace files
│   ├── Runner.xcworkspace/
│   └── Runner/                         # App assets and Swift files
│
├── web/                                # Web target assets (index.html, manifest.json)
├── linux/                              # Linux desktop build configs
│
├── lib/                                # ⭐ MAIN FLUTTER SOURCE DIRECTORY
│   ├── main.dart                       # Application entry point & configuration setup
│   │
│   ├── core/                           # Shared utility core module
│   │   ├── constants/                  # Theme constants, values, strings
│   │   ├── errors/                     # App custom exceptions & failures mapping
│   │   ├── routes/                     # Router setup using go_router
│   │   │   ├── app_router.dart         # Declares route lists and endpoints
│   │   │   └── app_routes.dart         # Path string constants
│   │   ├── services/                   # Global singletons
│   │   │   ├── injection_container.dart # Registering dependencies with GetIt
│   │   │   ├── screen_size_service.dart # Sizing calculations for UI
│   │   │   └── service_locator.dart    # Setup helper reference
│   │   ├── theme/                      # Styling setup
│   │   │   └── app_theme.dart          # Dark mode styling values
│   │   └── utils/                      # Common pure functions & helpers
│   │
│   ├── features/                       # Modular business features
│   │   ├── home/                       # Core navigation orchestration
│   │   │   └── presentation/           # Main tab frames and pages
│   │   │       ├── bloc/               # HomeSectionBloc
│   │   │       ├── widgets/            # Section widgets & custom tabs
│   │   │       │   ├── advanced_section_widget.dart  # Advanced options placeholder
│   │   │       │   ├── animated_section_tabs.dart     # Dynamic selection header
│   │   │       │   ├── compressor_section_widget.dart # Loaded file metadata view
│   │   │       │   ├── result_section_widget.dart     # Output options placeholder
│   │   │       │   ├── section_pages.dart             # Painter helpers
│   │   │       │   ├── subir_section_widget.dart      # File picker upload area
│   │   │       │   ├── video_info_table_widget.dart   # Details table widget
│   │   │       │   └── video_preview_widget.dart      # Video preview wrapper
│   │   │       ├── home_screen.dart    # Home screen with mode selection cards
│   │   │       ├── compressor_screen.dart # Basic compression workflow screen
│   │   │       └── loading_screen.dart # Startup linear loader overlay
│   │   │
│   │   └── compress_video/             # Main video parsing feature
│   │       ├── data/                   # Data layer implementation
│   │       │   ├── datasources/        # Low-level external library managers
│   │       │   │   ├── video_compressor_datasource.dart  # Basic engine (video_compress)
│   │       │   │   ├── video_metadata_datasource.dart    # Basic metadata (video_player)
│   │       │   │   ├── video_picker_datasource.dart      # File picker
│   │       │   │   ├── video_storage_datasource.dart     # Save to gallery
│   │       │   │   ├── ffmpeg_datasource.dart            # Advanced engine (FFmpeg + FFprobe)
│   │       │   │   └── ffmpeg_command_builder.dart       # Builds FFmpeg argument lists
│   │       │   └── repositories/       # Implementing domain interfaces
│   │       │       ├── video_repository_impl.dart        # Basic engine repository
│   │       │       └── advanced_video_repository_impl.dart # Advanced engine repository
│   │       ├── domain/                 # Domain logic layer
│   │       │   ├── entities/           # Pure entity models
│   │       │   │   ├── video_file.dart                   # Video metadata (includes fps)
│   │       │   │   ├── compression_config.dart           # Basic engine config
│   │       │   │   ├── compression_result.dart
│   │       │   │   ├── advanced_compression_config.dart  # FFmpeg config (bitrate, fps, extensible)
│   │       │   │   └── advanced_compression_result.dart  # FFmpeg result (includes ffmpegCommand)
│   │       │   ├── repositories/       # Abstract repository interfaces
│   │       │   │   ├── video_repository.dart             # Basic engine contract
│   │       │   │   └── advanced_video_repository.dart    # Advanced engine contract
│   │       │   └── use_cases/          # Business logic coordinators
│   │       │       ├── pick_video_use_case.dart
│   │       │       ├── compress_video_use_case.dart      # Basic compression
│   │       │       ├── compress_video_advanced_use_case.dart # FFmpeg compression
│   │       │       ├── get_extended_metadata_use_case.dart   # FFprobe metadata
│   │       │       └── save_video_use_case.dart
│   │       └── presentation/           # UI elements & BLoC state managers
│   │           └── bloc/               # VideoBloc (basic + advanced compression states)
│   │
│   └── shared/                         # Common UI elements shared across features
│       ├── extensions/                 # Utility extensions (e.g. padding/string extensions)
│       └── widgets/                    # Reusable visual components
│
├── test/                               # Testing suite directory
│   └── widget_test.dart                # Basic Flutter testing
│
├── docs/                               # 📚 PROJECT DOCUMENTATION
│   ├── README.md                       # Documentation index
│   ├── ARCHITECTURE.md                 # High-level clean architecture layers
│   ├── BLOC_SYSTEM.md                  # State managers detailed
│   ├── COMPONENTS.md                   # Custom widgets and UI layers catalog
│   ├── PROJECT_STRUCTURE.md            # This file
│   ├── COLOR_PALETTE.md                # Styling colors specifications
│   ├── STATUS.md                       # Feature implementation status
│   └── GETTING_STARTED.md              # Installation guides & dev tips
│
├── pubspec.yaml                        # Project dependency manager configuration
├── analysis_options.yaml               # Linter conventions and compiler analyzer settings
└── README.md                           # Quick-start documentation at repository root
```

---

## 🔍 Directory Breakdown

### 1. `lib/core/`
Houses setup components, constants, and utilities shared throughout the entire app:
- **`routes/`**: Handles the path routing config using `go_router`. Keeps navigation decoupled from screens.
- **`services/`**: Holds long-lived utility managers. `injection_container.dart` runs on app start to initialize dependency injections.
- **`theme/`**: Implements custom UI styling variables. It defines dark backgrounds and blue highlights.

### 2. `lib/features/`
Divided by feature scopes. 
- **`home`**: Handles screen layout frame and navigation page indices. It contains the loading/startup sequence and coordinates slide animations between sections.
- **`compress_video`**: Implements the Clean Architecture pattern for video processing.
  - **`domain`**: Exposes the logic rules and definitions (`use_cases` and `entities`) without relying on packages.
  - **`data`**: Integrates hardware APIs or package calls. Files under `datasources` fetch paths, read metadata, and (ultimately) run ffmpeg or compression scripts.
  - **`presentation`**: Houses state controls (`VideoBloc`) to drive screen rendering.

### 3. `lib/shared/`
Contains common structural widgets (e.g., standard dialogs, loading spinners) and general Dart extension helpers which are feature-agnostic.

### 4. `docs/`
Developer-facing markdown documents describing architecture, state machines, color palettes, and guide procedures.

---

## 📦 Adding a New Feature (Workflow Template)

When creating a new feature (e.g., `video_trimmer`), maintain Clean Architecture boundaries by applying this template:

```
lib/features/video_trimmer/
├── data/
│   ├── datasources/
│   │   └── video_trimmer_datasource.dart
│   └── repositories/
│       └── video_trimmer_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── trim_config.dart
│   ├── repositories/
│   │   └── video_trimmer_repository.dart
│   └── use_cases/
│       └── trim_video_use_case.dart
└── presentation/
    ├── bloc/
    │   ├── video_trimmer_bloc.dart
    │   ├── video_trimmer_event.dart
    │   └── video_trimmer_state.dart
    └── screens/
        └── video_trimmer_screen.dart
```
Once added, register data sources, repositories, and use cases inside [injection_container.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/core/services/injection_container.dart).
