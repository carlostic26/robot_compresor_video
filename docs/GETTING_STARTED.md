# Getting Started Guide

This guide helps new developers set up, run, and start contributing to the Robot Video Compressor project.

---

## 🚀 Initial Environment Setup

### 1. Prerequisites
Ensure you have the following installed on your developer machine:
- **Flutter SDK** (`3.11.4` or newer)
- **Dart SDK** (comes bundled inside Flutter)
- **Git**
- **Android Studio** & **SDK Command-line Tools** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **VS Code** or **Android Studio** (IDE editor of choice)

### 2. Verify Your Configuration
Run the following tool command to ensure all developer dependencies are correctly configured:
```bash
# Check installed tool versions
flutter --version
dart --version

# Run validation checks on your machine
flutter doctor
```

---

## 📥 Cloning and Initializing the Project

```bash
# 1. Clone the repository
git clone [URL_OF_REPOSITORY]
cd robot_compresor_video

# 2. Fetch and configure pubspec packages
flutter pub get

# 3. (Optional) Update dependencies to compatible patch releases
flutter pub upgrade
```

---

## 💻 Running the Application

### Under a Simulator / Emulator
Ensure an emulator is active. If not, launch one via Android Studio, Xcode, or the CLI:
```bash
# List available simulators and devices
flutter devices

# Run the project on a default device
flutter run

# Run on a specific device using its id
flutter run -d [device_id]
```

### Building Release Packages
```bash
# Android (generates release APK)
flutter build apk

# iOS (generates archive files)
flutter build ios

# Desktop platforms
flutter build windows
flutter build linux
```

---

## 🛠️ Developer Onboarding Sequence

To get comfortable with the codebase, review the documentation in this order:
1. **[STATUS.md](./STATUS.md)**: Current completion status of features (stubs vs. functional implementations).
2. **[ARCHITECTURE.md](./ARCHITECTURE.md)**: Architectural layers, dependency injection rules, and clean boundaries.
3. **[BLOC_SYSTEM.md](./BLOC_SYSTEM.md)**: How events and states control UI tabs and file processing.
4. **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)**: File placement maps.

---

## 🧪 Testing Suite

Automated tests are located in the [test/](file:///c:/projects/play_console_2/robot_compresor_video/test/) directory.

```bash
# Execute all tests inside the suite
flutter test

# Run a specific unit test file
flutter test test/widget_test.dart

# Run with test coverage calculations
flutter test --coverage
```

To expand testing coverage:
- Put domain model parser tests under `test/unit/`.
- Put bloc behavior tests under `test/unit/presentation/`.
- Put visual layout checks under `test/widget/`.

---

## 🔍 Troubleshooting & Cleaning Cache

### Cache Cleanups
If you encounter compiler discrepancies, cached conflicts, or package sync errors, run the following sequence:
```bash
# Erase all build directories and compiled temporary objects
flutter clean

# Fetch clean package files
flutter pub get
```

### Android Gradle Sync Issues
```bash
# Navigate to native folder and clear wrapper caches
cd android
./gradlew clean
cd ..
```

### iOS CocoaPods Sync Issues
```bash
cd ios
pod repo update
pod install
cd ..
```

---

## 📖 Helpful Links & Official Resources

- **Official Flutter Documentation**: [https://flutter.dev/docs](https://flutter.dev/docs)
- **Dart Programming Guides**: [https://dart.dev/guides](https://dart.dev/guides)
- **BLoC Library Handbook**: [https://bloclibrary.dev/](https://bloclibrary.dev/)
- **GetIt Locator Guidelines**: [https://pub.dev/packages/get_it](https://pub.dev/packages/get_it)
