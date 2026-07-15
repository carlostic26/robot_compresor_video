# Componentes y Widgets

Documentación detallada de todos los widgets y componentes del proyecto.

## 📁 Ubicación

Todos los widgets se encuentran en: `lib/features/home/presentation/widgets/`

## 🎨 Widgets del Proyecto

### 1. **AnimatedSectionTabs**

**Archivo:** `animated_section_tabs.dart`

**Descripción:** Widget que muestra las pestañas de navegación entre secciones con un indicador animado.

**Props:**
- `sections: List<String>` - Lista de nombres de las secciones
- `currentIndex: int` - Índice de la sección actualmente seleccionada
- `onTabPressed: Function(int)` - Callback cuando se presiona una pestaña

**Ejemplo de uso:**
```dart
AnimatedSectionTabs(
  sections: ['Subir', 'Compresor', 'Avanzado', 'Resultado'],
  currentIndex: 0,
  onTabPressed: (index) {
    // Manejar toque en pestaña
  },
)
```

**Características:**
- Texto coloreado (azul cuando está activo, gris cuando no)
- Indicador de subrayado animado
- Transiciones suaves de 300ms
- Totalmente responsive

---

### 2. **VideoPreviewWidget**

**Archivo:** `video_preview_widget.dart`

**Descripción:** Widget que muestra la miniatura del video con un botón de reproducción superpuesto (sin funcionalidad).

**Props:**
- `thumbnailUrl: String` - URL de la imagen de previsualización (requerido)
- `width: double?` - Ancho del widget (opcional, por defecto 100%)
- `height: double?` - Alto del widget (opcional, por defecto 250)

**Ejemplo de uso:**
```dart
VideoPreviewWidget(
  thumbnailUrl: 'https://example.com/thumbnail.jpg',
  width: 400,
  height: 250,
)
```

**Características:**
- Muestra imagen de previsualización
- Overlay oscuro semi-transparente (30% opacidad)
- Botón de play circular centrado (ilustrativo, sin acción)
- Bordes redondeados
- Sombra bajo el botón de play

**Estados:**
- Default: Muestra la imagen con overlay

---

### 3. **VideoInfoTableWidget**

**Archivo:** `video_info_table_widget.dart`

**Descripción:** Widget que muestra información detallada del video en formato de tabla.

**Props:**
- `videoInfo: VideoInfo` - Objeto con información del video

**Ejemplo de uso:**
```dart
VideoInfoTableWidget(
  videoInfo: VideoInfo(
    name: 'video.mp4',
    duration: '00:02:45',
    date: '14 jul. 2025 10:30 a. m.',
    size: '52.4 MB',
    bitRate: '2540 kbps',
  ),
)
```

**Modelo VideoInfo:**
```dart
class VideoInfo {
  final String name;          // Nombre del archivo
  final String duration;      // Duración (formato HH:MM:SS)
  final String date;          // Fecha de creación
  final String size;          // Tamaño del archivo
  final String bitRate;       // Velocidad de bits

  const VideoInfo({
    required this.name,
    required this.duration,
    required this.date,
    required this.size,
    required this.bitRate,
  });

  // Factory para crear datos mock
  factory VideoInfo.mock() { ... }
}
```

**Características:**
- Tabla estilizada con fondo oscuro
- Iconos coloreados (azul) para cada campo
- Divisores entre filas
- Información alineada (etiqueta a la izquierda, valor a la derecha)
- Responsive y escalable

**Información mostrada:**
- 📄 Nombre del archivo
- ⏱️ Duración del video
- 📅 Fecha de creación
- 💾 Tamaño del archivo
- 🚀 Velocidad de bits (Bit rate)

---

### 4. **SubirSection**

**Archivo:** `section_pages.dart`

**Descripción:** Sección para subir videos con área de arrastrar y soltar.

**Características:**
- Área con borde punteado (líneas discontinuas)
- Icono de nube con flecha hacia arriba (azul)
- Título "Sube tu video"
- Subtítulo "Toca para seleccionar"
- Formatos soportados: MP4, MOV, AVI, MKV
- Tamaño máximo: 2 GB
- Ocupa 95% del ancho y 40% del alto
- Toque muestra un SnackBar

**Responsive:**
```dart
// Calcula automáticamente el alto basado en la pantalla
final screenHeight = MediaQuery.of(context).size.height;
height = screenHeight * 0.4;  // 40% de la altura
```

---

### 5. **CompressorSection**

**Archivo:** `section_pages.dart`

**Descripción:** Sección que muestra la previsualización del video y su información.

**Contenido:**
- VideoPreviewWidget con imagen mockada
- VideoInfoTableWidget con información del video
- Scroll vertical para contenido que excede la pantalla

**Características:**
- SingleChildScrollView para contenido scrolleable
- Padding de 16 en todos lados
- Espaciado de 24 entre componentes

---

### 6. **AvanzadoSection**

**Archivo:** `section_pages.dart`

**Descripción:** Sección para opciones avanzadas (placeholder actual).

**Estado:** En desarrollo

---

### 7. **ResultadoSection**

**Archivo:** `section_pages.dart`

**Descripción:** Sección para mostrar resultados (placeholder actual).

**Estado:** En desarrollo

---

### 8. **DashedBorderPainter** (CustomPainter)

**Archivo:** `section_pages.dart`

**Descripción:** Pintor personalizado que dibuja bordes punteados.

**Props:**
- `color: Color` - Color del borde
- `strokeWidth: double` - Grosor de la línea (por defecto 2)
- `dashWidth: double` - Largo de cada raya (por defecto 8)
- `dashSpace: double` - Espacio entre rayas (por defecto 6)
- `borderRadius: double` - Radio de las esquinas (por defecto 12)

**Uso:**
```dart
CustomPaint(
  painter: DashedBorderPainter(
    color: Colors.blue.withValues(alpha: 0.5),
    strokeWidth: 2,
    dashWidth: 10,
    dashSpace: 8,
  ),
  child: Container(...)
)
```

---

## 🎯 Estructura de Widgets

```
home_screen.dart
├── AnimatedSectionTabs
│   └── Usa BlocBuilder para reaccionar a cambios de estado
├── PageView
│   ├── SubirSection
│   │   └── DashedBorderPainter (borde punteado)
│   ├── CompressorSection
│   │   ├── VideoPreviewWidget
│   │   └── VideoInfoTableWidget
│   ├── AvanzadoSection
│   └── ResultadoSection
└── BottomNavigationBar (Placeholder)
```

---

## 🔄 Flujo de Datos en Componentes

```
home_screen.dart
     │
     ├─→ BlocBuilder<HomeSectionBloc>
     │        │
     │        └─→ AnimatedSectionTabs (currentIndex del estado)
     │
     └─→ PageView (onPageChanged dispara evento)
              │
              ├─→ SubirSection
              │    └─ GestureDetector (muestra SnackBar)
              │
              ├─→ CompressorSection
              │    ├─ VideoPreviewWidget
              │    └─ VideoInfoTableWidget
              │
              ├─→ AvanzadoSection
              │
              └─→ ResultadoSection
```

---

## 🎨 Tema y Estilos

### Colores Utilizados
- **Primario:** `Colors.blue` - Para iconos activos, bordes, subrayados
- **Secundario:** `Colors.grey[400]` - Para textos secundarios
- **Fondo:** `Colors.grey[800-900]` - Para contenedores
- **Texto:** `Colors.white` - Para texto principal

### Espaciados Comunes
- Padding pequeño: 8px
- Padding medio: 16px
- Padding grande: 24px
- Padding XL: 32px

### Bordes Redondeados
- BorderRadius estándar: 12px
- BorderRadius en botones: 8-12px

---

## 📱 Responsive Design

Los widgets están diseñados para ser responsivos:

```dart
// Ancho dinámico (95% del ancho de pantalla)
width: MediaQuery.of(context).size.width * 0.95

// Alto dinámico (40% del alto de pantalla)
height: MediaQuery.of(context).size.height * 0.4

// Usando ScreenSizeService
final height = ScreenSizeService.heightPercent(context, 8);
```

---

## 🧪 Testing Widgets

### Ejemplo: Test para AnimatedSectionTabs

```dart
void main() {
  group('AnimatedSectionTabs', () {
    testWidgets('muestra el indicador en la posición correcta', 
      (WidgetTester tester) async {
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSectionTabs(
              sections: ['Tab 1', 'Tab 2'],
              currentIndex: 0,
              onTabPressed: (_) {},
            ),
          ),
        ),
      );

      // Verificar que Tab 1 está seleccionado
      expect(find.text('Tab 1'), findsOneWidget);
    });
  });
}
```

---

## 🚀 Próximas Mejoras

- [ ] Agregar animaciones más complejas
- [ ] Mejorar accesibilidad (labels para screen readers)
- [ ] Agregar temas claro/oscuro dinámico
- [ ] Crear componentes para secciones "Avanzado" y "Resultado"
- [ ] Implementar file picker para "Subir" sección
- [ ] Agregar video player funcional en VideoPreviewWidget

---

Para información sobre la arquitectura, ver [ARCHITECTURE.md](./ARCHITECTURE.md)
