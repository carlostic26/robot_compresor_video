# Sistema BLoC - Gestión de Estado

Documentación completa del sistema BLoC implementado en Robot Video Compressor.

## 📘 Introducción a BLoC

**BLoC** (Business Logic Component) es un patrón de arquitectura que separa la lógica de negocio de la UI. En este proyecto, usamos `flutter_bloc` para gestionar el estado de las secciones.

## 🏗️ Componentes del BLoC

### 1. **HomeSectionBloc**
El bloc principal que gestiona qué sección está actualmente activa.

**Ubicación:** `lib/features/home/presentation/bloc/home_section_bloc.dart`

```dart
class HomeSectionBloc extends Bloc<HomeSectionEvent, HomeSectionState> {
  HomeSectionBloc() : super(const HomeSectionState()) {
    on<PageChanged>(_onPageChanged);
    on<InitPage>(_onInitPage);
  }
  
  Future<void> _onPageChanged(PageChanged event, Emitter<HomeSectionState> emit) async {
    emit(state.copyWith(currentPageIndex: event.pageIndex));
  }
}
```

### 2. **HomeSectionEvent** (Eventos)
Define las acciones que pueden ocurrir.

**Ubicación:** `lib/features/home/presentation/bloc/home_section_event.dart`

```dart
// Evento disparado cuando el usuario cambia de página
class PageChanged extends HomeSectionEvent {
  final int pageIndex;
  const PageChanged(this.pageIndex);
}

// Evento para inicializar el bloc
class InitPage extends HomeSectionEvent {
  const InitPage();
}
```

### 3. **HomeSectionState** (Estado)
Representa el estado actual de la aplicación.

**Ubicación:** `lib/features/home/presentation/bloc/home_section_state.dart`

```dart
class HomeSectionState extends Equatable {
  final int currentPageIndex;  // Índice de la sección activa (0-3)
  
  const HomeSectionState({this.currentPageIndex = 0});
  
  HomeSectionState copyWith({int? currentPageIndex}) {
    return HomeSectionState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }
}
```

## 🔄 Flujo de Datos - Paso a Paso

### Escenario: Usuario desliza de la sección "Subir" a "Compresor"

```
1. USUARIO INTERACTÚA
   └─> Desliza en el PageView de derecha a izquierda

2. PAGEVIEW DETECTA EL CAMBIO
   └─> onPageChanged(index: 1) se ejecuta

3. EVENTO SE DISPARA
   └─> _onPageChanged(index) llama a:
       home_section_bloc.add(PageChanged(1))

4. BLOC PROCESA EL EVENTO
   └─> _onPageChanged() en el bloc se ejecuta
       └─> emit(state.copyWith(currentPageIndex: 1))

5. ESTADO SE EMITE
   └─> HomeSectionState(currentPageIndex: 1) se emite

6. UI ESCUCHA EL CAMBIO
   └─> BlocBuilder recibe el nuevo estado
       └─> Reconstruye AnimatedSectionTabs
           └─> El indicador azul se anima a la posición 1
```

## 🎯 Casos de Uso

### Caso 1: Usuario Toca un Tab

```dart
// En home_screen.dart
void _onTabPressed(int index) {
  // 1. Animar el PageView a la página
  _pageController.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
  // 2. PageView dispara onPageChanged(index)
  // 3. Bloc se encarga del resto automáticamente
}
```

### Caso 2: Inicializar la Aplicación

```dart
@override
void initState() {
  super.initState();
  _homeSectionBloc = HomeSectionBloc();
}

@override
Widget build(BuildContext context) {
  return BlocProvider<HomeSectionBloc>(
    create: (context) => _homeSectionBloc..add(const InitPage()),
    child: Scaffold(...)
  );
}
```

### Caso 3: Escuchar Cambios en la UI

```dart
BlocBuilder<HomeSectionBloc, HomeSectionState>(
  builder: (context, state) {
    return AnimatedSectionTabs(
      currentIndex: state.currentPageIndex,  // Lee el estado actual
      onTabPressed: _onTabPressed,
    );
  },
)
```

## 📊 Diagrama de Flujo Completo

```
┌────────────────────────────────────────────────────────────────┐
│                        HOME SCREEN                             │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  BlocProvider                                            │ │
│  │  └─> Proporciona HomeSectionBloc a toda la app         │ │
│  │                                                          │ │
│  │  ┌────────────────────────────────────────────────────┐ │ │
│  │  │ BlocBuilder                                        │ │ │
│  │  │ └─> Escucha HomeSectionState                      │ │ │
│  │  │     ┌──────────────────────────────────────────┐  │ │ │
│  │  │     │ AnimatedSectionTabs                      │  │ │ │
│  │  │     │ - currentIndex: state.currentPageIndex   │  │ │ │
│  │  │     │ - Muestra tabs con indicador animado     │  │ │ │
│  │  │     │ - onTabPressed: Anima PageView          │  │ │ │
│  │  │     └──────────────────────────────────────────┘  │ │ │
│  │  └────────────────────────────────────────────────────┘ │ │
│  │                                                          │ │
│  │  ┌────────────────────────────────────────────────────┐ │ │
│  │  │ PageView                                           │ │ │
│  │  │ - controller: _pageController                     │ │ │
│  │  │ - onPageChanged: Dispara PageChanged event        │ │ │
│  │  │ ┌──────────────────────────────────────────────┐  │ │ │
│  │  │ │ [SubirSection] [Compresor] [Avanzado] [...]  │  │ │ │
│  │  │ └──────────────────────────────────────────────┘  │ │ │
│  │  └────────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
                            ▲
                            │
         ┌──────────────────┴──────────────────┐
         │                                    │
    [Usuario toca]               [Usuario desliza]
    tab "Compresor"               en PageView
         │                                    │
         └──────────────────┬──────────────────┘
                            │
        ┌───────────────────▼────────────────────┐
        │    HomeSectionBloc                    │
        │                                       │
        │  on<PageChanged>(event)               │
        │  ├─> emit(state.copyWith(             │
        │  │     currentPageIndex: event.index  │
        │  │   ))                               │
        │  │                                    │
        │  on<InitPage>(event)                  │
        │  └─> emit(HomeSectionState())         │
        │                                       │
        │  State: HomeSectionState              │
        │  currentPageIndex: [0-3]              │
        │                                       │
        └───────────────────┬────────────────────┘
                            │
                    [Nuevo estado emitido]
                            │
                    [BlocBuilder reconstruye]
                            │
               [AnimatedSectionTabs se actualiza]
```

## 🧪 Testing

### Ejemplo: Test del Bloc

```dart
void main() {
  group('HomeSectionBloc', () {
    late HomeSectionBloc homeSectionBloc;

    setUp(() {
      homeSectionBloc = HomeSectionBloc();
    });

    tearDown(() {
      homeSectionBloc.close();
    });

    test('emite HomeSectionState cuando PageChanged es agregado', () {
      expect(
        homeSectionBloc.stream,
        emits(HomeSectionState(currentPageIndex: 1)),
      );
      
      homeSectionBloc.add(const PageChanged(1));
    });
  });
}
```

## 💡 Mejores Prácticas

### 1. **Siempre cerrar el Bloc**
```dart
@override
void dispose() {
  _homeSectionBloc.close();
  super.dispose();
}
```

### 2. **Usar BlocBuilder solamente para cambios específicos**
```dart
// Bueno: Solo reconstruye cuando cambia currentPageIndex
BlocBuilder<HomeSectionBloc, HomeSectionState>(
  buildWhen: (previous, current) {
    return previous.currentPageIndex != current.currentPageIndex;
  },
  builder: (context, state) { ... }
)
```

### 3. **Evitar lógica compleja en el Bloc**
La lógica compleja debe estar en `domain/usecases/`. El Bloc solo debe orquestar.

### 4. **Usar copyWith para cambios de estado**
```dart
// Bueno
emit(state.copyWith(currentPageIndex: newIndex));

// Evitar
emit(HomeSectionState(currentPageIndex: newIndex));
```

## 🔗 Referencias

- [Flutter Bloc Documentation](https://bloclibrary.dev/)
- [BLoC Pattern](https://www.didierboelens.com/2018/08/reactive-programming-streams-bloc/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)

---

Para más información sobre la arquitectura general, ver [ARCHITECTURE.md](./ARCHITECTURE.md)
