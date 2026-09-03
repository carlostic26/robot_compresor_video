# Robot Video Compressor

A Flutter mobile application that compresses videos with a clean and intuitive workflow, from video selection to optimized output generation.

## 🛠️ Technologies & Libraries

### Core Framework
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language

### State Management
- **flutter_bloc** (^9.1.1) - BLoC pattern implementation for clean and scalable architecture
  - Manages section state, navigation and business logic
  - Facilitates testing and code maintainability

### Navigation
- **go_router** (^15.1.2) - Modern route-based navigation system
  - Declarative routing
  - Deep linking and deep navigation support

### Dependency Injection
- **get_it** (^8.0.3) - Service locator for dependency management

### Utilities
- **equatable** (^2.0.7) - Simplifies object comparisons in Dart
- **path_provider** (^2.1.5) - Access to system file directories

### Architecture
The application follows a clean architecture pattern with:
- **Presentation**: Widgets and UI components
- **Bloc**: State management and business logic
- **Features**: Feature-based modularization (home, etc.)
- **Core**: Common services, themes, constants and routes

& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" uninstall com.blogspot.robotcompresorvideo