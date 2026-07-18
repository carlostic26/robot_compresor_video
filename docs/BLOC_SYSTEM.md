# State Management - BLoC System

This document outlines the state management system used in the Robot Video Compressor application. The application utilizes the **BLoC (Business Logic Component)** pattern via the `flutter_bloc` library to isolate business logic from UI rendering.

---

## 🏗️ Core BLoC Components

The application contains two core BLoCs that handle separate domains:

1. **HomeSectionBloc**: Manages horizontal tab navigation and sliding PageView indexes.
2. **VideoBloc**: Manages video file selection, file metadata extraction, loading states, and (future) compression processing.

---

## 1. HomeSectionBloc (Navigation Control)

Responsible for tracking which segment of the application the user is currently viewing.

- **Files**:
  - [home_section_bloc.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/bloc/home_section_bloc.dart)
  - [home_section_event.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/bloc/home_section_event.dart)
  - [home_section_state.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/bloc/home_section_state.dart)

### Events
- `InitPage`: Dispatched when the homepage is mounted to trigger initial settings.
- `PageChanged(int pageIndex)`: Dispatched when a user swipes the main `PageView` or taps a tab bar button.

### States
- `HomeSectionState`: Holds the single numeric field `currentPageIndex` to let UI widgets know which tab index is selected.

---

## 2. VideoBloc (Video File Processing)

Responsible for coordinating file picking and video parsing metadata.

- **Files**:
  - [video_bloc.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/compress_video/presentation/bloc/video_bloc.dart)
  - [video_event.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/compress_video/presentation/bloc/video_event.dart)
  - [video_state.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/compress_video/presentation/bloc/video_state.dart)

### Events
- `PickVideoRequested`: Dispatched when the user taps the upload area on `SubirSection`. Triggers the picker sequence, retrieves metadata, and loads it into the state.

### States
- `VideoState`: Contains:
  - `video` (`VideoFile?`): The selected video metadata object, or `null` if no file has been successfully picked.
  - `isLoading` (`bool`): Flag to display fullscreen progress overlays during picking or initialization.

---

## 🔄 Collaborative State Flow: Dynamic Section Switching

A key feature in the application is that the tabs change dynamically depending on whether a video file is loaded or not:
- **No Video Loaded**: The tabs are `['Subir', 'Avanzado', 'Resultado']`.
- **Video Loaded**: The tabs are `['Compresor', 'Avanzado', 'Resultado']`.

Here is a step-by-step description of how the two BLoCs interact on the Home Screen:

```
1. USER INTERACTION
   ├─> Tap on "Sube tu video" button in SubirSection
   
2. DISPATCH SELECTION EVENT
   ├─> SubirSection triggers:
   │   context.read<VideoBloc>().add(PickVideoRequested())

3. METADATA LOADING
   ├─> VideoBloc emits: VideoState(isLoading: true)
   ├─> UI displays: CircularProgressIndicator (loading overlay)
   ├─> PickVideoUseCase invokes repository -> file picker opens
   ├─> User selects file "sample.mp4"
   ├─> VideoMetadataDatasource parses duration & resolution
   
4. SUCCESSFUL SELECTION EMISSION
   ├─> VideoBloc emits: VideoState(video: sampleVideo, isLoading: false)
   
5. DYNAMIC TAB INTERPOLATION
   ├─> HomeScreen's build() detects state.video != null
   ├─> Evaluates active tabs: const ['Compresor', 'Avanzado', 'Resultado']
   ├─> Rebuilds:
   │   ├─> AnimatedSectionTabs (with the new tabs list)
   │   └─> PageView (loading CompressorSection inside child index 0)
```

---

## 📊 Complete Architecture Interaction Diagram

```
                 +-------------------------------------------------+
                 |                   HomeScreen                    |
                 +-----------------------+-------------------------+
                                         |
                       Registers & Injects BLoC Instances
                                         |
                                         v
                 +-----------------------+-------------------------+
                 |            MultiBlocProvider/Builder            |
                 +----+---------------------------------------+----+
                      |                                       |
             Listens to VideoState                  Listens to HomeSectionState
                      |                                       |
                      v                                       v
        +-------------+-------------+             +-----------+-------------+
        |  Dynamic Sections List    |             |   AnimatedSectionTabs   |
        |  - Video == null:         |             |   - Moves blue visual   |
        |    [Subir, Avanzado, ...] |             |     underline marker    |
        |  - Video != null:         |             +-------------------------+
        |    [Compresor, Avanzado]  |
        +-------------+-------------+
                      |
           Loads Correct View into
                      |
                      v
        +-------------+-------------+
        |         PageView          |
        |  - Slides pages           |
        |  - Triggers PageChanged() |
        +---------------------------+
```

---

## 🧪 Testing BLoCs

Because the logic is separated into events and states, BLoC behaviors can be tested using the `bloc_test` library.

### Example: Testing VideoBloc Selection

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';

class MockPickVideoUseCase extends Mock implements PickVideoUseCase {}

void main() {
  group('VideoBloc Unit Tests', () {
    late MockPickVideoUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockPickVideoUseCase();
    });

    blocTest<VideoBloc, VideoState>(
      'emits correct loading and loaded states when video is picked',
      build: () => VideoBloc(pickVideoUseCase: mockUseCase),
      setUp: () {
        when(() => mockUseCase()).thenAnswer(
          (_) async => const VideoFile(
            path: '/path/to/video.mp4',
            name: 'video.mp4',
            size: 1048576,
            duration: Duration(seconds: 10),
            width: 1920,
            height: 1080,
            bitrate: 0,
            createdAt: null,
            thumbnailPath: null,
          ),
        );
      },
      act: (bloc) => bloc.add(const PickVideoRequested()),
      expect: () => [
        const VideoState(isLoading: true),
        isA<VideoState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.video?.name, 'video name', 'video.mp4'),
      ],
    );
  });
}
```

---

## 💡 Best Practices

1. **Keep States Immutable**: Always declare BLoC state fields as `final` and extend `Equatable` to allow Dart comparison operators to match equality.
2. **Utilize `copyWith`**: When emitting new states, use `state.copyWith(...)` to modify only specific parameters, preserving existing states (like retaining the loaded video when showing/hiding indicators).
3. **Keep BLoC Agnostic of Packages**: Do not import package dependencies inside a BLoC file (e.g., `file_picker`). All complex processes should be wrapped in domain Use Cases and repositories. The BLoC is strictly an event-driven controller.
