# Arquitectura del Proyecto

Robot Video Compressor sigue una **arquitectura limpia** con separación clara de responsabilidades. Esta arquitectura facilita el testing, mantenimiento y escalabilidad del código.

## 📐 Estructura de Capas

```
lib/
├── main.dart                    # Punto de entrada
├── core/                        # Lógica compartida
│   ├── constants/               # Constantes globales
│   ├── errors/                  # Definición de errores personalizados
│   ├── routes/                  # Configuración de rutas
│   ├── services/                # Servicios globales (ScreenSizeService)
│   ├── theme/                   # Temas de la aplicación
│   └── utils/                   # Utilidades globales
├── features/                    # Funcionalidades del app
│   └── home/
│       ├── data/                # [Futuro] Acceso a datos
│       │   ├── datasources/     # [Futuro] APIs, local storage
│       │   └── repositories/    # [Futuro] Implementación de repos
│       ├── domain/              # [Futuro] Entidades y casos de uso
│       │   ├── entities/
│       │   ├── repositories/    # [Futuro] Interfaces de repos
│       │   └── usecases/        # [Futuro] Lógica de negocio
│       └── presentation/        # UI e interacción
│           ├── bloc/            # Gestión de estado
│           │   ├── home_section_bloc.dart
│           │   ├── home_section_event.dart
│           │   └── home_section_state.dart
│           ├── widgets/         # Widgets reutilizables
│           │   ├── animated_section_tabs.dart
│           │   ├── section_pages.dart
│           │   ├── video_preview_widget.dart
│           │   └── video_info_table_widget.dart
│           └── home_screen.dart # Pantalla principal
└── shared/                      # Componentes compartidos
    ├── extensions/
    └── widgets/
```

## 🔄 Flujo de Datos

```
                    ┌─────────────────────────┐
                    │   Presentación (UI)     │
                    │   ├─ home_screen.dart   │
                    │   └─ widgets/           │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Bloc (Estado)          │
                    │  HomeSectionBloc        │
                    │  - Events               │
                    │  - States               │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Domain (Lógica)        │
                    │  [Futuro]               │
                    │  - UseCases             │
                    │  - Entities             │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Data (Acceso a Datos)  │
                    │  [Futuro]               │
                    │  - Repositories         │
                    │  - DataSources          │
                    └─────────────────────────┘
```

## 🎯 Principios Aplicados

### 1. **Clean Architecture**
- Separación clara de responsabilidades
- Independencia de frameworks externos
- Fácil de testear
- Escalable

### 2. **SOLID**
- **S**ingle Responsibility Principle - Cada clase tiene una responsabilidad
- **O**pen/Closed Principle - Abierto para extensión, cerrado para modificación
- **L**iskov Substitution Principle - Las subclases pueden sustituir sus clases base
- **I**nterface Segregation Principle - Interfaces específicas
- **D**ependency Inversion Principle - Depender de abstracciones

### 3. **Feature-Based Organization**
- Cada feature es independiente
- Fácil de agregar nuevas features
- Código modular y reutilizable

## 📦 Capas Explicadas

### **Presentation Layer** (Presentación)
Responsable de:
- Renderizar la UI
- Capturar interacciones del usuario
- Mostrar datos del estado
- Navegar entre pantallas

Componentes:
- `home_screen.dart` - Pantalla principal
- `bloc/` - Gestión de estado
- `widgets/` - Widgets reutilizables

### **Domain Layer** (Dominio) - [Futuro]
Responsable de:
- Lógica de negocio
- Definir casos de uso
- Abstracciones independientes de la plataforma

Componentes:
- `entities/` - Objetos de dominio
- `repositories/` - Interfaces de acceso a datos
- `usecases/` - Lógica de negocio

### **Data Layer** (Datos) - [Futuro]
Responsable de:
- Obtener datos de APIs, base de datos, etc.
- Implementar los repositorios
- Transformar datos

Componentes:
- `datasources/` - Acceso a datos
- `repositories/` - Implementación de interfaces del dominio
- `models/` - Modelos de datos

### **Core** (Núcleo)
Responsable de:
- Servicios globales
- Constantes
- Temas
- Utilidades comunes
- Configuración de rutas

## 🔌 Inyección de Dependencias

El proyecto usa `get_it` para la inyección de dependencias:

```dart
// Registro de dependencias
final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<HomeSectionBloc>(HomeSectionBloc());
}

// Uso en cualquier lado
final bloc = getIt<HomeSectionBloc>();
```

## ✅ Ventajas de esta Arquitectura

✅ **Testabilidad** - Fácil escribir unit tests  
✅ **Escalabilidad** - Crecer sin afectar código existente  
✅ **Mantenibilidad** - Código organizado y predecible  
✅ **Reusabilidad** - Compartir lógica entre features  
✅ **Independencia** - UI independiente de datos  

---

Para más detalles sobre el Bloc system, ver [BLOC_SYSTEM.md](./BLOC_SYSTEM.md)
