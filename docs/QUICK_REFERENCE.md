# Developer Quick Reference Guide

This guide provides code templates, CLI shortcuts, and formatting conventions frequently used in the Robot Video Compressor project.

---

## 🏃 CLI Commands Cheat Sheet

### Development Lifecycle
```bash
# Get project dependencies
flutter pub get

# Run on the default connected device
flutter run

# Format code files inside directory
flutter format lib/
```

### Build Distribution
```bash
# Android release APK
flutter build apk

# iOS build bundle
flutter build ios

# Windows desktop app
flutter build windows
```

### Cache & Cleanups
```bash
# Clean compilation files
flutter clean

# Flush package cache
flutter pub cache repair
```

---

## 📐 Common Code Snippets

### 1. Declaring a BLoC Event & State

```dart
// my_feature_event.dart
part of 'my_feature_bloc.dart';

abstract class MyFeatureEvent extends Equatable {
  const MyFeatureEvent();
  @override
  List<Object?> get props => [];
}

class TriggerAction extends MyFeatureEvent {
  final String param;
  const TriggerAction(this.param);
  @override
  List<Object?> get props => [param];
}
```

```dart
// my_feature_state.dart
part of 'my_feature_bloc.dart';

class MyFeatureState extends Equatable {
  final bool isLoading;
  final String? result;

  const MyFeatureState({this.isLoading = false, this.result});

  MyFeatureState copyWith({bool? isLoading, String? result}) {
    return MyFeatureState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [isLoading, result];
}
```

```dart
// my_feature_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'my_feature_event.dart';
part 'my_feature_state.dart';

class MyFeatureBloc extends Bloc<MyFeatureEvent, MyFeatureState> {
  MyFeatureBloc() : super(const MyFeatureState()) {
    on<TriggerAction>(_onTriggerAction);
  }

  Future<void> _onTriggerAction(
    TriggerAction event,
    Emitter<MyFeatureState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    // Execute use case logic here...
    emit(state.copyWith(isLoading: false, result: "Completed: ${event.param}"));
  }
}
```

---

### 2. Consuming BLoCs in UI Components

#### Rebuilding UI Layout on State Changes
```dart
BlocBuilder<VideoBloc, VideoState>(
  builder: (context, state) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }
    return Text('Selected File: ${state.video?.name ?? "None"}');
  },
)
```

#### Triggering Navigation or Dialog Side-Effects
```dart
BlocListener<VideoBloc, VideoState>(
  listener: (context, state) {
    if (state.video != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${state.video!.name}')),
      );
    }
  },
  child: const MyLayoutContainer(),
)
```

---

### 3. Dependency Injection Registry (`get_it`)

Register dependencies in [injection_container.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/core/services/injection_container.dart):
```dart
// For long-lived service instances (Singletons)
sl.registerLazySingleton<VideoPickerDatasource>(() => VideoPickerDatasource());

// For screens requiring fresh states each initialization (Factories)
sl.registerFactory(() => VideoBloc(pickVideoUseCase: sl()));
```

Locate and read dependencies from anywhere in the codebase:
```dart
final videoBloc = sl<VideoBloc>();
```

---

## 🎨 Theme Tokens & Common Styles

### Typography Tokens
```dart
// Large headers
Text('Header Title', style: Theme.of(context).textTheme.headlineSmall)

// Common descriptions
Text('Body content text', style: Theme.of(context).textTheme.bodyMedium)

// Micro-copy labels
Text('Small label detail', style: Theme.of(context).textTheme.bodySmall)
```

### Proportional Layout Calculations
Always avoid hardcoding absolute layout dimensions. Use `ScreenSizeService` values to calculate dimensions as screen percentages:
```dart
// Container takes up 90% of screen width
width: ScreenSizeService.widthPercent(context, 90)

// Padding matches 2% of screen height
height: ScreenSizeService.heightPercent(context, 2)
```

Home screen rule:
```dart
// ✅ Use ScreenSizeService for vertical spacing
SizedBox(height: ScreenSizeService.heightPercent(context, 5))

// ❌ Avoid MediaQuery/hardcoded values for this layout
SizedBox(height: MediaQuery.of(context).size.height * 0.05)
SizedBox(height: 50)
```

---

## 🎯 Pre-Commit Checklist

Before submitting code reviews, verify:
- [ ] Code compiles cleanly without diagnostics errors.
- [ ] Code formatting meets standards (`flutter format lib/`).
- [ ] The local test suite passes (`flutter test`).
- [ ] No credential strings or API secrets are committed.
