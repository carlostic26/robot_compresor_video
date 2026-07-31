import 'package:flutter/material.dart';
import 'package:robot_compresor_video/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Diálogo de información de la aplicación.
///
/// Muestra descripción, modos de compresión y desarrollador.
/// Incluye botón "Calificar aplicación" que abre [_RateDialog].
///
/// Uso:
/// ```dart
/// AppInfoDialog.show(context);
/// ```
class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const AppInfoDialog());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Robot Compresor Video',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              'Desarrollada por TICnoticos Apps',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Robot Compresor Video es una aplicación móvil que te permite reducir el tamaño de tus videos de forma rápida e inteligente, sin perder calidad innecesaria.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Modos de compresión',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _ModeChip(
              icon: Icons.bolt_rounded,
              label: 'Compresión básica',
              sublabel: 'video_compress',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _ModeChip(
              icon: Icons.auto_awesome,
              label: 'Compresión avanzada',
              sublabel: 'FFmpeg',
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.star_rounded, size: 18),
          label: const Text('Calificar'),
          onPressed: () {
            Navigator.pop(context);
            _RateDialog.show(context);
          },
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(sublabel, style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diálogo motivacional para calificar la aplicación.
class _RateDialog extends StatelessWidget {
  const _RateDialog();

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const _RateDialog());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star_rounded, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('¿Te gusta la app?'),
        ],
      ),
      content: Text(
        '¡Tu valoración nos ayuda a seguir mejorando Robot Compresor Video! '
        'Solo toma un momento y significa mucho para nosotros. 🙌',
        style: textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ahora no'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Calificar ahora'),
          onPressed: () async {
            Navigator.pop(context);
            await _openPlayStore(context);
          },
        ),
      ],
    );
  }

  Future<void> _openPlayStore(BuildContext context) async {
    final url = AppConstants.playStoreUrl;
    if (url.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La app aún no está disponible en Play Store.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
