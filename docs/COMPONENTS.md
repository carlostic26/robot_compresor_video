# UI Components & Widgets

This document describes all custom UI components and widgets implemented in the Robot Video Compressor application. These files are located under [lib/features/home/presentation/widgets/](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/).

---

## 🎨 Presentation Widgets Breakdown

### 1. AnimatedSectionTabs
- **File**: [animated_section_tabs.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/animated_section_tabs.dart)
- **Description**: Displays a row of horizontal tabs indicating page sections. It features a sliding blue accent underline that animates dynamically when selection changes.
- **Parameters**:
  - `sections` (`List<String>`): The names of the sections to render.
  - `currentIndex` (`int`): The active section index.
  - `onTabPressed` (`Function(int)`): Callback triggered when a tab is pressed.
- **Example**:
  ```dart
  AnimatedSectionTabs(
    sections: const ['Subir', 'Avanzado', 'Resultado'],
    currentIndex: state.currentPageIndex,
    onTabPressed: (index) => _onTabPressed(index),
  )
  ```

---

### 2. VideoPreviewWidget
- **File**: [video_preview_widget.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/video_preview_widget.dart)
- **Description**: Shows a preview container for the selected video. It currently renders a placeholder network image with a dark overlay and an illustrative play button icon centered on top.
- **Parameters**:
  - `thumbnailUrl` (`String`): The URL of the image to display (currently mocked).
  - `width` (`double?`): The widget width (defaults to full width).
  - `height` (`double?`): The widget height (defaults to `250`).
- **Implementation Status**: **Mocked**. It does not stream or play the selected local video, nor does it generate a real local thumbnail yet.

---

### 3. VideoInfoTableWidget
- **File**: [video_info_table_widget.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/video_info_table_widget.dart)
- **Description**: Renders technical details of the selected video inside a dark slate card container.
- **Parameters**:
  - `videoFile` (`VideoFile`): The loaded domain entity containing video metadata.
- **Displayed Fields**:
  - **Name**: Displayed via the `shortName` getter (truncates long file names and keeps the extension visible).
  - **Duration**: Formatted dynamically (e.g., `MM:SS` or `HH:MM:SS`).
  - **Date**: Shows `--` (mocked, pending extraction).
  - **Size**: Formatted from raw bytes to `MB` with two decimal places.
  - **Bit rate**: Shows `--` if `0`, or formatted string in `kbps`.
- **Styling**:
  - Background styled with Slate Surface color.
  - Row details divided by horizontal lines.
  - Primary blue icons highlight each detail row.

---

### 4. SubirSection
- **File**: [subir_section_widget.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/subir_section_widget.dart)
- **Description**: The default starting view. It displays a drag-and-drop styled dotted border container enclosing a upload cloud icon, prompting users to upload files.
- **Behaviors**:
  - Tapping anywhere in the blue-dotted box triggers `PickVideoRequested` event inside `VideoBloc`.
  - Shows supported file types (`MP4, MOV, AVI, MKV`) and maximum file size guidelines (`2 GB`).
- **Layout**: Uses 95% of screen width and 30% of screen height to fit device displays cleanly.

---

### 5. CompressorSection
- **File**: [compressor_section_widget.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/compressor_section_widget.dart)
- **Description**: Displayed in place of `SubirSection` once a video file has been successfully loaded into the state.
- **Contents**:
  - Contains `VideoPreviewWidget`.
  - Renders `VideoInfoTableWidget`.
  - Shows a main action button labeled **"Comprimir"** (Compress).
- **Implementation Status**: **Under Development**. The action button has an empty callback.

---

### 6. AvanzadoSection (Advanced Settings)
- **File**: [advanced_section_widget.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/advanced_section_widget.dart)
- **Description**: Intended to customize compression settings (e.g., quality factor slider, deleting the original video, resolution scale overrides).
- **Implementation Status**: **Static Placeholder**. Renders an icon and a text label indicating the section content will go here.

---

### 7. ResultSection (Results View)
- **File**: [result_section_widget.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/result_section_widget.dart)
- **Description**: Intended to show compression analytics (original size vs. compressed size, compression ratio percentage, saved space bar, sharing or saving options).
- **Implementation Status**: **Static Placeholder**. Renders a check icon and a placeholder label.

---

### 8. DashedBorderPainter (CustomPainter)
- **File**: [section_pages.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/features/home/presentation/widgets/section_pages.dart)
- **Description**: A utility custom painter helper class that draws dotted outlines on a canvas path.
- **Parameters**:
  - `color` (`Color`): Color of the dashed line.
  - `strokeWidth` (`double`): Line thickness (defaults to `2`).
  - `dashWidth` (`double`): Length of each individual dash segment (defaults to `8`).
  - `dashSpace` (`double`): Space size between dash segments (defaults to `6`).
  - `borderRadius` (`double`): Corner radius of the container (defaults to `12`).
- **Example**:
  ```dart
  CustomPaint(
    painter: DashedBorderPainter(
      color: Colors.blue.withValues(alpha: 0.5),
      strokeWidth: 2,
      dashWidth: 10,
      dashSpace: 8,
      borderRadius: 12,
    ),
    child: Container(...),
  )
  ```

---

## 📱 Responsive & Layout Calculations

All components utilize proportional sizing to ensure rendering on standard phone screens:
- Screen sizes are parsed dynamically using media queries or [screen_size_service.dart](file:///c:/projects/play_console_2/robot_compresor_video/lib/core/services/screen_size_service.dart).
- Sizing references standard percentages:
  - `ScreenSizeService.heightPercent(context, 22)` for video preview cards.
  - `ScreenSizeService.widthPercent(context, 90)` for full-width action buttons.
