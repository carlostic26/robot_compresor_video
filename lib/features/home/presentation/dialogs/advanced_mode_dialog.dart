import 'package:flutter/material.dart';

/// Diálogo informativo mostrado antes de ejecutar la compresión avanzada.
///
/// Explica las capacidades del modo avanzado (FFmpeg) al usuario.
///
/// ## Preparación para anuncios
/// El callback [onContinue] es el punto de extensión para integrar anuncios.
/// Actualmente ejecuta la acción directamente al pulsar "Continuar".
/// Para integrar anuncios reales, reemplaza el body de [onContinue] en el
/// caller sin modificar este diálogo.
///
/// ## Uso desde navegación (sin await)
/// ```dart
/// AdvancedModeDialog.show(context, onContinue: () { ... });
/// ```
///
/// ## Uso desde botón Comprimir (con await)
/// ```dart
/// await AdvancedModeDialog.showAsync(context, onContinue: () { ... });
/// ```
class AdvancedModeDialog extends StatelessWidget {
  /// Acción ejecutada al pulsar "Continuar".
  /// Debe devolver true para avanzar y false para quedarse en el diálogo.
  final Future<bool> Function() onContinue;

  const AdvancedModeDialog({super.key, required this.onContinue});

  /// Muestra el diálogo sin esperar resultado (uso en navegación).
  static void show(BuildContext context, {required Future<bool> Function() onContinue}) {
    showDialog<bool>(
      context: context,
      builder: (_) => AdvancedModeDialog(onContinue: onContinue),
    );
  }

  /// Muestra el diálogo y espera a que se cierre (uso en flujo de compresión).
  static Future<bool?> showAsync(
    BuildContext context, {
    required Future<bool> Function() onContinue,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AdvancedModeDialog(onContinue: onContinue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome, color: colorScheme.secondary, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Modo avanzado',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Este modo utiliza FFmpeg, una de las herramientas más potentes para procesamiento multimedia. Verás un corto anuncio para continuar.',
              style: textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 22),
            ..._features(colorScheme, textTheme),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Continuar'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
          ),
          onPressed: () async {
            final canContinue = await onContinue();
            if (!context.mounted) return;
            if (canContinue) {
              Navigator.pop(context, true);
            }
          },
        ),
      ],
    );
  }

  List<Widget> _features(ColorScheme cs, TextTheme tt) {
    final items = [
      (Icons.tune, 'Control total del bit rate de salida'),
      (Icons.speed, 'Ajuste de FPS del video'),
      (Icons.high_quality, 'Mayor calidad de compresión configurable'),
      (Icons.terminal, 'Motor FFmpeg de nivel profesional'),
    ];
    return items
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(e.$1, color: cs.secondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.$2,
                    style: tt.bodyMedium?.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
