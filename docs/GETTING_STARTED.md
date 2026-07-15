# Guía de Inicio Rápido

Guía para nuevos desarrolladores que quieren contribuir al proyecto Robot Video Compressor.

## 🚀 Primeros Pasos

### 1. Requisitos Previos

Asegúrate de tener instalado:
- **Flutter SDK** (versión 3.11.4+)
- **Dart SDK** (incluido en Flutter)
- **Git**
- **Android Studio** (para desarrollo Android)
- **Xcode** (para desarrollo iOS)
- **VS Code** o **Android Studio** (editor de código)

### 2. Verificar Instalación

```bash
# Verificar Flutter
flutter --version

# Verificar Dart
dart --version

# Verificar que todo está listo
flutter doctor
```

---

## 📥 Clonar el Proyecto

```bash
# Clonar repositorio
git clone [URL_DEL_REPOSITORIO]
cd robot_compresor_video

# Descargar dependencias
flutter pub get

# (Opcional) Obtener la última versión de dependencias
flutter pub upgrade
```

---

## 🎯 Estructura del Proyecto

Para entender mejor el proyecto, lee estos documentos en orden:

1. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Cómo está organizado el código
2. **[BLOC_SYSTEM.md](./BLOC_SYSTEM.md)** - Cómo funciona la gestión de estado
3. **[COMPONENTS.md](./COMPONENTS.md)** - Widgets disponibles
4. **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - Árbol de directorios

---

## 💻 Ejecutar la Aplicación

### En Emulador Android

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d [device_id]
```

### En Dispositivo iOS

```bash
# Ejecutar en iPhone
flutter run -d iphone
```

### En Web

```bash
flutter run -d chrome
```

### En Linux/Windows

```bash
flutter run -d linux
# o
flutter run -d windows
```

---

## 🔧 Desarrollo

### Modo Debug con Hot Reload

```bash
flutter run
```

Durante el desarrollo:
- Presiona `r` para hot reload (recarga rápida)
- Presiona `R` para hot restart (recarga completa)
- Presiona `q` para quit (salir)

### Build para Producción

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web

# Linux
flutter build linux

# Windows
flutter build windows
```

---

## 📁 Archivos Importantes

### `pubspec.yaml`
Archivo principal de configuración:
- Versión del proyecto
- Dependencias (librerías)
- Assets (imágenes, fuentes)

```yaml
name: robot_compresor_video
version: 1.0.0+1

dependencies:
  flutter: sdk: flutter
  flutter_bloc: ^9.1.1
  go_router: ^15.1.2
  # ... más dependencias
```

### `lib/main.dart`
Punto de entrada de la aplicación:

```dart
void main() {
  setupServiceLocator();  // Configurar inyección de dependencias
  runApp(const MyApp());  // Iniciar la app
}
```

### `lib/features/home/presentation/home_screen.dart`
Pantalla principal con:
- Tabs de navegación
- PageView para deslizar entre secciones
- Bloc para gestionar estado

---

## 🎨 Estructura de Features

Cada feature sigue la arquitectura limpia:

```
feature_name/
├── data/                 # Obtener datos (APIs, BD)
│   ├── datasources/
│   └── repositories/
├── domain/               # Lógica de negocio
│   ├── entities/
│   ├── repositories/     # Interfaces
│   └── usecases/
└── presentation/         # UI
    ├── bloc/            # Estado
    ├── widgets/         # Componentes
    └── screens/         # Pantallas
```

---

## 📝 Agregar Nueva Funcionalidad

### Ejemplo: Agregar nueva sección

**1. Crear el widget en `section_pages.dart`:**

```dart
class MiSeccionSection extends StatelessWidget {
  const MiSeccionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Tu contenido aquí
        ],
      ),
    );
  }
}
```

**2. Agregar a la lista de secciones en `home_screen.dart`:**

```dart
static const List<String> _sections = [
  'Subir',
  'Compresor',
  'Avanzado',
  'Resultado',
  'Mi Sección',  // ← Nueva
];
```

**3. Agregar al PageView:**

```dart
children: const [
  SubirSection(),
  CompressorSection(),
  AvanzadoSection(),
  ResultadoSection(),
  MiSeccionSection(),  // ← Nueva
],
```

---

## 🧪 Testing

### Ejecutar todos los tests

```bash
flutter test
```

### Ejecutar test específico

```bash
flutter test test/widget_test.dart
```

### Ver coverage (cobertura de código)

```bash
flutter test --coverage
```

---

## 🔍 Debugging

### Usar debugger en VS Code

1. Abre `.vscode/launch.json` (o crea uno)
2. Agrega esta configuración:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart"
    }
  ]
}
```

3. Presiona `F5` para iniciar el debugger

### Usar DevTools

```bash
flutter pub global activate devtools
devtools
```

Luego abre http://localhost:9100 en tu navegador.

---

## 📚 Patrones Comunes

### Usar BlocBuilder

```dart
BlocBuilder<HomeSectionBloc, HomeSectionState>(
  builder: (context, state) {
    return Text('Página: ${state.currentPageIndex}');
  },
)
```

### Acceder a Bloc desde cualquier lado

```dart
final bloc = context.read<HomeSectionBloc>();
bloc.add(PageChanged(1));
```

### Usar ScreenSizeService para responsive

```dart
final height = ScreenSizeService.heightPercent(context, 40);
final width = ScreenSizeService.widthPercent(context, 95);
```

---

## 🔌 Agregar Nuevas Dependencias

```bash
# Agregar nueva dependencia
flutter pub add nombre_paquete

# Agregar como dev dependency
flutter pub add --dev nombre_paquete

# Ver todos los paquetes disponibles
flutter pub search nombre_paquete
```

---

## 📋 Checklist para Empezar

- [ ] Clonar el repositorio
- [ ] Ejecutar `flutter pub get`
- [ ] Verificar con `flutter doctor`
- [ ] Ejecutar la app con `flutter run`
- [ ] Leer documentación (ARCHITECTURE.md)
- [ ] Explorar el código
- [ ] Escribir tu primer commit

---

## 🐛 Solucionar Problemas Comunes

### Error: "flutter: command not found"
```bash
# Agregar Flutter al PATH
export PATH="$PATH:[path-to-flutter]/bin"
```

### Error: "No devices found"
```bash
# Asegurar que el emulador está corriendo
flutter emulators
flutter emulators launch [emulator_id]
```

### Limpiar proyecto

```bash
# Limpiar build
flutter clean

# Limpiar caché
flutter pub cache repair

# Reinstalar dependencias
flutter pub get
```

### Problemas con pods (iOS)

```bash
cd ios
pod repo update
pod install
cd ..
```

---

## 📖 Recursos Útiles

### Documentación Oficial
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Bloc Library](https://bloclibrary.dev/)

### Tutoriales
- [Flutter BLoC Pattern](https://www.youtube.com/watch?v=SQJxEV_YFQI)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
- [go_router Guide](https://codewithandrea.com/articles/flutter-navigation-go_router/)

### Comunidades
- [Flutter Community](https://github.com/flutter)
- [Dart Community](https://dart.dev/community)
- [StackOverflow Flutter](https://stackoverflow.com/questions/tagged/flutter)

---

## 💬 Preguntas Frecuentes

### ¿Cómo sé en qué rama estoy?
```bash
git branch
# o
git status
```

### ¿Cómo cambio de rama?
```bash
git checkout nombre_rama
# o (forma moderna)
git switch nombre_rama
```

### ¿Cómo creo una nueva rama?
```bash
git switch -c nombre_nueva_rama
```

### ¿Cómo actualizo desde main?
```bash
git fetch origin
git rebase origin/main
```

---

## 🚀 Próximos Pasos

Después de familiarizarte con el proyecto:

1. **Lee el código existente** para entender los patrones
2. **Escribe tests** para tus cambios
3. **Sigue las convenciones** del proyecto
4. **Comenta tu código** cuando sea necesario
5. **Haz commits pequeños y descriptivos**

---

## 📞 ¿Necesitas Ayuda?

Si tienes dudas:
1. Revisa la documentación relevante en `/docs`
2. Busca en el código existente ejemplos similares
3. Consulta con el equipo

---

¡Felicidades! Ya estás listo para empezar a desarrollar. 🎉

*Para más información, lee [ARCHITECTURE.md](./ARCHITECTURE.md)*
