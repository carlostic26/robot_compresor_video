# Referencia Rápida

Guía rápida de comandos y patrones comunes.

## 🏃 Comandos Rápidos

### Iniciar Desarrollo
```bash
cd robot_compresor_video
flutter pub get
flutter run
```

### Hot Reload (durante desarrollo)
- Presiona `r` en la terminal

### Build & Deploy
```bash
# APK para Android
flutter build apk

# IPA para iOS
flutter build ios

# Web
flutter build web
```

### Testing
```bash
# Ejecutar todos los tests
flutter test

# Ejecutar un test específico
flutter test test/nombre_test.dart

# Ver cobertura
flutter test --coverage
```

### Limpieza
```bash
flutter clean
flutter pub get
```

---

## 📐 Estructura de Carpetas

```
lib/
├── core/           # Compartido (servicios, constantes, temas)
├── features/       # Features principales
│   └── home/       # Feature home
│       ├── data/   # [Futuro] APIs y BD
│       ├── domain/ # [Futuro] Lógica de negocio
│       └── presentation/
│           ├── bloc/          # Estado
│           ├── widgets/       # Componentes
│           └── home_screen.dart
└── shared/         # Widgets y extensiones globales
```

---

## 🎯 Patrones Comunes

### Crear Nuevo Bloc

```dart
// event.dart
part of 'nuevo_bloc.dart';

abstract class NuevoEvent extends Equatable {
  const NuevoEvent();
  @override
  List<Object> get props => [];
}

// state.dart
part of 'nuevo_bloc.dart';

class NuevoState extends Equatable {
  final int valor;
  const NuevoState({this.valor = 0});
  
  NuevoState copyWith({int? valor}) {
    return NuevoState(valor: valor ?? this.valor);
  }
  
  @override
  List<Object> get props => [valor];
}

// bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'nuevo_event.dart';
part 'nuevo_state.dart';

class NuevoBloc extends Bloc<NuevoEvent, NuevoState> {
  NuevoBloc() : super(const NuevoState()) {
    on<NuevoEvent>(_onNuevoEvent);
  }
  
  Future<void> _onNuevoEvent(
    NuevoEvent event,
    Emitter<NuevoState> emit,
  ) async {
    // Lógica aquí
  }
}
```

### Usar BlocBuilder

```dart
BlocBuilder<NuevoBloc, NuevoState>(
  builder: (context, state) {
    return Text('Valor: ${state.valor}');
  },
)
```

### Usar BlocListener

```dart
BlocListener<NuevoBloc, NuevoState>(
  listener: (context, state) {
    // Acciones sin reconstruir (navegación, dialogs)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Valor: ${state.valor}')),
    );
  },
  child: // Widget aquí
)
```

### Crear Nuevo Widget

```dart
class MiWidget extends StatelessWidget {
  final String titulo;
  final VoidCallback onPressed;

  const MiWidget({
    super.key,
    required this.titulo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(titulo),
    );
  }
}
```

### Usar GetIt (Service Locator)

```dart
// Registrar en main.dart
void setupServiceLocator() {
  getIt.registerSingleton<MyService>(MyService());
}

// Usar en cualquier lado
final service = getIt<MyService>();
```

---

## 🎨 Estilos Comunes

### Texto

```dart
// Heading grande
Text('Título', style: Theme.of(context).textTheme.headlineSmall)

// Body text
Text('Contenido', style: Theme.of(context).textTheme.bodyMedium)

// Small text
Text('Pequeño', style: Theme.of(context).textTheme.bodySmall)
```

### Espaciado

```dart
const SizedBox(height: 8)    // Pequeño
const SizedBox(height: 16)   // Medio
const SizedBox(height: 24)   // Grande
const SizedBox(height: 32)   // Extra grande
```

### Colores

```dart
Colors.blue              // Primario
Colors.grey[400]         // Secundario
Colors.white             // Blanco
Colors.black87           // Negro
Colors.transparent       // Transparente
Colors.blue.withValues(alpha: 0.5)  // Opacidad
```

### Bordes y Esquinas

```dart
// Borde redondeado
BorderRadius.circular(12)

// Sombra
BoxShadow(
  color: Colors.black.withValues(alpha: 0.2),
  blurRadius: 8,
  offset: const Offset(0, 2),
)

// Borde
Border.all(color: Colors.blue, width: 2)
```

---

## 🚀 Agregar Nueva Sección

1. Crear widget en `section_pages.dart`:
```dart
class MiSeccionSection extends StatelessWidget {
  const MiSeccionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: []),
    );
  }
}
```

2. Agregar a `_sections` en `home_screen.dart`:
```dart
static const List<String> _sections = [
  'Subir',
  'Compresor',
  'Avanzado',
  'Resultado',
  'Mi Sección',  // ← Nueva
];
```

3. Agregar al PageView en `home_screen.dart`:
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

## 🔧 Utilidades Útiles

### ScreenSizeService

```dart
// Obtener porcentaje del ancho
final width = ScreenSizeService.widthPercent(context, 95);

// Obtener porcentaje del alto
final height = ScreenSizeService.heightPercent(context, 40);

// Obtener tamaño completo
final size = MediaQuery.of(context).size;
```

### Navegación con go_router

```dart
// Navegar
context.go('/home');

// Navegar con parámetros
context.push('/detail/$id');

// Volver
context.pop();
```

### SnackBar

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Mensaje'),
    duration: const Duration(seconds: 2),
    backgroundColor: Colors.blue,
  ),
);
```

### Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Título'),
    content: const Text('Contenido'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  ),
);
```

---

## 🧪 Testing Pattern

```dart
void main() {
  group('MyWidget', () {
    testWidgets('muestra el texto correcto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MyWidget()),
      );

      expect(find.text('Esperado'), findsOneWidget);
    });

    testWidgets('ejecuta callback al presionar', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MyWidget(onPressed: () => pressed = true),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });
  });
}
```

---

## ⚙️ Configuración Importante

### pubspec.yaml
Ubicación de dependencias:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  go_router: ^15.1.2
```

### analysis_options.yaml
Reglas de linting:
```yaml
linter:
  rules:
    - avoid_empty_else
    - avoid_print
    - prefer_const_constructors
```

---

## 🔍 Debug Tips

### Ver logs
```bash
flutter logs
```

### Hot reload no funciona
```bash
# Hacer hot restart
Presiona R en terminal

# O manual
flutter run --no-fast-start
```

### Device no aparece
```bash
# Listar devices
flutter devices

# Esperar a device
flutter run -d flutter-tester
```

---

## 📱 Responsive Tips

```dart
// Mobile first (adapta para tablet)
final isMobile = MediaQuery.of(context).size.width < 600;

// Usar LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else {
      return TabletLayout();
    }
  },
)
```

---

## 🎯 Checklist Antes de Commit

- [ ] Código compilable (`flutter analyze` sin errores)
- [ ] Tests pasando (`flutter test`)
- [ ] Código formateado (`flutter format lib/`)
- [ ] Sin warnings importantes
- [ ] Commit message descriptivo
- [ ] No tiene secrets o credenciales

---

## 📚 Documentación Relacionada

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Arquitectura completa
- [BLOC_SYSTEM.md](./BLOC_SYSTEM.md) - Detalle del BLoC
- [COMPONENTS.md](./COMPONENTS.md) - Widgets disponibles
- [GETTING_STARTED.md](./GETTING_STARTED.md) - Guía de inicio

---

*Última actualización: Julio 2025*
