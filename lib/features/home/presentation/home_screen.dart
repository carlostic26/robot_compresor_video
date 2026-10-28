import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/core/routes/app_routes.dart';
import 'package:robot_compresor_video/core/services/ad_service.dart';
import 'package:robot_compresor_video/core/theme/app_colors.dart';
import 'package:robot_compresor_video/core/widgets/banner_ad_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/advanced_mode_dialog.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/app_drawer.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/app_info_dialog.dart';

/// Formatos de video admitidos por la app.
const List<String> _supportedFormats = ['MP4', 'MOV', 'AVI', 'MKV'];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Home'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => AppInfoDialog.show(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ~40% — Compresión básica
              Expanded(
                flex: 40,
                child: _CompressionModeCard(
                  icon: Icons.bolt_rounded,
                  title: 'Compresión básica',
                  badge: 'Sin anuncios',
                  badgeIcon: Icons.check_circle_rounded,
                  badgeColor: AppColors.success,
                  description:
                      'Rápida y sencilla. Elige un preset de calidad y reduce '
                      'el tamaño de tus videos en pocos toques.',
                  features: const [
                    'Presets de calidad predefinidos',
                    'Proceso rápido y automático',
                    'Ideal para compartir en redes y chats',
                  ],
                  color: colorScheme.primary,
                  onTap: () => context.push(AppRoutes.basic),
                ),
              ),

              const SizedBox(height: 12),

              // ~40% — Compresión avanzada
              Expanded(
                flex: 40,
                child: _CompressionModeCard(
                  icon: Icons.auto_awesome,
                  title: 'Compresión avanzada',
                  badge: 'Contiene anuncio',
                  badgeIcon: Icons.campaign_rounded,
                  badgeColor: AppColors.primary,
                  description:
                      'Control total con FFmpeg. Ajusta cada parámetro y '
                      'compara el resultado antes de guardar.',
                  features: const [
                    'Bitrate personalizado (kbps)',
                    'Ajuste de FPS y resolución',
                    'Vista previa antes / después',
                  ],
                  color: colorScheme.primary,
                  onTap: () {
                    AdvancedModeDialog.show(
                      context,
                      onContinue: () async {
                        await AdService.showInterstitialAd();
                        if (!context.mounted) return false;
                        context.push(AppRoutes.advanced);
                        return true;
                      },
                    );
                  },
                ),
              ),

              // ~20% — márgenes + botón de tutorial
              Expanded(
                flex: 20,
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.tutorial),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.school_rounded),
                      label: const Text('Ver Tutorial'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

class _CompressionModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final IconData badgeIcon;
  final Color badgeColor;
  final String description;
  final List<String> features;
  final Color color;
  final VoidCallback onTap;

  const _CompressionModeCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeIcon,
    required this.badgeColor,
    required this.description,
    required this.features,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: .15),
        highlightColor: color.withValues(alpha: .08),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: .25)),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          // Scroll de respaldo para pantallas muy pequeñas; en pantallas
          // normales el contenido cabe sin desplazarse.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Encabezado
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(badgeIcon, size: 14, color: badgeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      badge,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: badgeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: color.withValues(alpha: .6),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Descripción
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurface.withValues(alpha: .85),
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Características
                      ...features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Formatos admitidos
                      Row(
                        children: [
                          Text(
                            'Formatos:',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _supportedFormats
                                  .map(
                                    (format) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: .10),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: color.withValues(alpha: .30),
                                        ),
                                      ),
                                      child: Text(
                                        format,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
