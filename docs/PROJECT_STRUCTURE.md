# Estructura del Proyecto

Descripción detallada de la estructura de directorios y archivos del proyecto.

## 📁 Árbol Completo

```
robot_compresor_video/
├── android/                          # Código nativo de Android
│   ├── app/                          # App module
│   │   ├── build.gradle.kts
│   │   └── src/
│   │       ├── debug/
│   │       ├── main/
│   │       └── profile/
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── local.properties             # [No versionado] Configuración local
│   ├── settings.gradle.kts
│   └── gradle/                      # Configuración de Gradle
│       └── wrapper/
│
├── ios/                              # Código nativo de iOS
│   ├── Runner.xcodeproj/            # Proyecto Xcode
│   ├── Runner.xcworkspace/
│   ├── Runner/                      # App principal
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   ├── Info.plist
│   │   ├── Assets.xcassets/
│   │   └── Base.lproj/
│   ├── RunnerTests/
│   └── Flutter/                     # Configuración Flutter para iOS
│       ├── Debug.xcconfig
│       ├── Release.xcconfig
│       └── ephemeral/               # [Autogenerado] Ignorar
│
├── web/                              # Código para web
│   ├── index.html
│   ├── manifest.json
│   └── icons/
│
├── linux/                            # Código para Linux (desktop)
│   ├── CMakeLists.txt
│   ├── flutter/
│   └── runner/
│
├── lib/                              # ⭐ CÓDIGO PRINCIPAL DE FLUTTER
│   ├── main.dart                    # Punto de entrada
│   ├── core/                        # Núcleo compartido
│   │   ├── constants/               # Constantes globales
│   │   ├── errors/                  # Definición de errores personalizados
│   │   ├── routes/                  # Configuración de rutas (go_router)
│   │   ├── services/                # Servicios globales
│   │   │   └── screen_size_service.dart
│   │   ├── theme/                   # Temas de la aplicación
│   │   └── utils/                   # Utilidades compartidas
│   │
│   ├── features/                    # Funcionalidades principales
│   │   └── home/                    # Feature: Home
│   │       ├── data/                # [Futuro] Capa de datos
│   │       │   ├── datasources/     # [Futuro] APIs, local storage
│   │       │   └── repositories/    # [Futuro] Implementación
│   │       ├── domain/              # [Futuro] Capa de dominio
│   │       │   ├── entities/        # [Futuro] Entidades
│   │       │   ├── repositories/    # [Futuro] Interfaces
│   │       │   └── usecases/        # [Futuro] Casos de uso
│   │       └── presentation/        # ⭐ Capa de presentación
│   │           ├── bloc/            # Gestión de estado
│   │           │   ├── home_section_bloc.dart
│   │           │   ├── home_section_event.dart
│   │           │   └── home_section_state.dart
│   │           ├── widgets/         # Widgets específicos del feature
│   │           │   ├── animated_section_tabs.dart
│   │           │   ├── section_pages.dart
│   │           │   ├── video_preview_widget.dart
│   │           │   └── video_info_table_widget.dart
│   │           └── home_screen.dart # Pantalla principal
│   │
│   └── shared/                      # Código compartido entre features
│       ├── extensions/              # Extensiones de Dart
│       └── widgets/                 # Widgets globales reutilizables
│
├── test/                             # Tests unitarios
│   └── widget_test.dart
│
├── build/                            # [Autogenerado] Ignorar
│   ├── app/                         # Outputs del build
│   ├── flutter_assets/
│   ├── jni/
│   └── native_assets/
│
├── docs/                             # 📚 DOCUMENTACIÓN
│   ├── README.md                    # Índice de documentación
│   ├── ARCHITECTURE.md              # Arquitectura del proyecto
│   ├── BLOC_SYSTEM.md               # Sistema de BLoC
│   ├── COMPONENTS.md                # Widgets y componentes
│   ├── PROJECT_STRUCTURE.md         # Este archivo
│   └── GETTING_STARTED.md           # Guía de inicio
│
├── analysis_options.yaml             # Configuración de análisis (linter)
├── pubspec.yaml                      # ⭐ DEPENDENCIAS DEL PROYECTO
├── pubspec.lock                      # [Autogenerado] Lock de dependencias
├── README.md                         # Documentación principal del proyecto
├── robot_compresor_video.iml         # Archivo IntelliJ IDEA
└── .gitignore                        # Archivos ignorados por Git
```

## 📋 Descripción por Carpeta

### `lib/` - Código Principal

#### `main.dart`
Punto de entrada de la aplicación. Configura:
- Tema de la aplicación
- Navegación (go_router)
- Setup inicial

```dart
void main() {
  // Setup de dependencias
  setupServiceLocator();
  
  runApp(const MyApp());
}
```

#### `core/` - Funcionalidad Compartida

**`core/constants/`**
- Constantes globales (colores, strings, números)
- Configuración compartida en toda la app

**`core/errors/`**
- Definición de excepciones personalizadas
- Errores de dominio específicos

**`core/routes/`**
- Configuración de go_router
- Definición de rutas de la app

**`core/services/`**
- ScreenSizeService: Cálculo de tamaños responsive
- Otros servicios globales (autenticación, etc.)

**`core/theme/`**
- AppTheme: Tema oscuro/claro
- Estilos de texto
- Colores de la app

**`core/utils/`**
- Funciones auxiliares globales
- Extensiones de tipos comunes

#### `features/` - Funcionalidades Principales

Cada feature es independiente y contiene:

```
feature/
├── data/          # Acceso a datos (BD, APIs)
├── domain/        # Lógica de negocio
└── presentation/  # UI e interacción
```

**`features/home/`** - Feature actual

```
home/
├── data/                           # [Futuro]
│   ├── datasources/               # APIs, SQLite, SharedPreferences
│   └── repositories/              # Implementación de repos
│
├── domain/                        # [Futuro]
│   ├── entities/                  # Objetos de dominio
│   ├── repositories/              # Interfaces de repos
│   └── usecases/                  # Lógica de negocio
│
└── presentation/                  # ✅ Implementado
    ├── bloc/                      # Gestión de estado
    │   ├── home_section_bloc.dart         # Bloc principal
    │   ├── home_section_event.dart        # Eventos
    │   └── home_section_state.dart        # Estado
    ├── widgets/                   # Widgets del feature
    │   ├── animated_section_tabs.dart     # Tabs de navegación
    │   ├── section_pages.dart             # Secciones principales
    │   ├── video_preview_widget.dart      # Preview del video
    │   └── video_info_table_widget.dart   # Tabla de info
    └── home_screen.dart           # Pantalla principal
```

#### `shared/` - Código Reutilizable

**`shared/extensions/`**
- Extensiones de tipos (String, int, etc.)
- Métodos helper globales

**`shared/widgets/`**
- Widgets globales (diálogos, botones comunes, etc.)
- Componentes reutilizables en toda la app

### `test/` - Testing

```
test/
└── widget_test.dart               # Tests de widgets
```

Estructura recomendada para agregar más tests:
```
test/
├── unit/                          # Tests unitarios
│   ├── bloc/
│   └── services/
├── widget/                        # Tests de widgets
│   └── home/
└── integration/                   # Tests de integración
```

### `docs/` - Documentación

```
docs/
├── README.md                      # Índice de docs
├── ARCHITECTURE.md                # Arquitectura limpia
├── BLOC_SYSTEM.md                 # Sistema de BLoC
├── COMPONENTS.md                  # Widgets del proyecto
├── PROJECT_STRUCTURE.md           # Este archivo
└── GETTING_STARTED.md             # Cómo comenzar
```

### `android/` y `ios/` - Código Nativo

- **`android/`**: Código Java/Kotlin específico de Android
- **`ios/`**: Código Swift/Objective-C específico de iOS

### Carpetas Autogeneradas

- **`build/`**: Outputs del build (ignorar)
- **`ephemeral/`**: Archivos temporales (ignorar)
- **`pubspec.lock`**: Lock de dependencias (no editar)

---

## 📊 Estadísticas de Archivos

| Carpeta | Archivos | Descripción |
|---------|----------|-------------|
| `lib/features/home` | 8 | Código de la feature home |
| `lib/core` | 5+ | Código compartido |
| `docs/` | 5 | Documentación |
| `android/` | ~15 | Configuración Android |
| `ios/` | ~20 | Configuración iOS |

---

## 🔄 Dependencias Internas

```
home_screen.dart
    ├─→ bloc/home_section_bloc.dart
    ├─→ widgets/animated_section_tabs.dart
    ├─→ widgets/section_pages.dart
    └─→ core/services/screen_size_service.dart

section_pages.dart
    ├─→ widgets/video_preview_widget.dart
    └─→ widgets/video_info_table_widget.dart

animated_section_tabs.dart
    └─→ Standalone (sin dependencias internas)
```

---

## 📦 Configuración de Archivos

### `pubspec.yaml`
Define:
- Nombre y versión del proyecto
- Dependencias (flutter_bloc, go_router, etc.)
- Assets (imágenes, fuentes)
- Configuración de compilación

### `analysis_options.yaml`
Configura:
- Reglas de linting
- Nivel de severidad de errores
- Exclusiones de análisis

### `.gitignore`
Archivos ignorados por Git:
- `build/`
- `pubspec.lock`
- `android/local.properties`
- Otros archivos temporales

---

## 🎯 Estructura Recomendada para Agregar Nuevos Features

Para agregar un nuevo feature (ejemplo: `video_editor`):

```
features/
└── video_editor/
    ├── data/
    │   ├── datasources/
    │   └── repositories/
    ├── domain/
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    └── presentation/
        ├── bloc/
        │   ├── video_editor_bloc.dart
        │   ├── video_editor_event.dart
        │   └── video_editor_state.dart
        ├── widgets/
        │   └── [widgets específicos]
        └── video_editor_screen.dart
```

---

## 🔗 Relaciones de Importaciones

```
main.dart
    ↓
core/routes/ (go_router config)
    ↓
features/home/presentation/home_screen.dart
    ↓
    ├─ features/home/presentation/bloc/
    ├─ features/home/presentation/widgets/
    └─ core/services/
```

---

Para más detalles sobre la arquitectura, ver [ARCHITECTURE.md](./ARCHITECTURE.md)
