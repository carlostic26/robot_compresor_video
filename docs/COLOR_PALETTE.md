# App Color Palette Guide

This document defines the visual color palette designed for Robot Video Compressor. The design utilizes a dark, tech-oriented, and professional theme, using dark grays and bright blue-cyan accents to communicate a video processing and utility feel.

---

## 🎨 Palette Breakdown

### Base Theme Colors

| Color Role | Hex Value | Preview/Description |
|---|---|---|
| **Primary** | `#4FC3F7` | Light Blue. Used for primary buttons, active icons, and primary interactive elements. |
| **Primary Dark** | `#29B6F6` | Deep Blue. Used for active button hover states or dark mode outlines. |
| **Background** | `#10151C` | Deep Slate Navy. Used as the main backdrop of the screens. Pure black was avoided for a more sophisticated, softer look. |
| **Surface** | `#1A2230` | Slate Gray-Blue. Used for cards, tables, elevated sections, and panel backgrounds. |
| **Text Primary** | `#E6ECF5` | Off-white. High contrast text color for titles, primary details, and buttons. |
| **Text Secondary** | `#7A879C` | Cool gray. Used for labels, descriptions, and disabled or low-priority text. |
| **Accent** | `#5E81AC` | Steel blue. Used for status indicators, borders, and sub-labels. |
| **Success** | `#76C893` | Mint green. Represents successful compression actions, saved space percentages, and progress completions. |
| **Error** | `#FF6B6B` | Coral red. Used for failure alerts, cancellation indicators, and warning messages. |

---

## 💡 Recommended Usage

- **Background**: Set the Scaffold background to the main Background color (`#10151C`).
- **Cards/Containers**: Wrap sections in a Container styled with the Surface color (`#1A2230`) and a subtle `BorderRadius` (typically `8px` or `12px`).
- **Primary Actions**: Highlight primary text buttons, selection checkboxes, and sliding tab underlines using the Primary color (`#4FC3F7`).
- **Error/Success Handling**: Use Success (`#76C893`) for file saving outputs, and Error (`#FF6B6B`) for exceptions like compression failures.
