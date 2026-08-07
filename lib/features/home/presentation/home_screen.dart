import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/core/routes/app_routes.dart';
import 'package:robot_compresor_video/core/services/ad_service.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/core/theme/app_colors.dart';
import 'package:robot_compresor_video/core/widgets/banner_ad_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/advanced_mode_dialog.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/app_drawer.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/app_info_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                SizedBox(height: ScreenSizeService.heightPercent(context, 2)),
             
              Text(
                'Selecciona el método que mejor se adapte a tus necesidades.',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: ScreenSizeService.heightPercent(context, 5)),
           
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _CompressionCard(
                      icon: Icons.bolt_rounded,
                      title: 'Compresión básica',
                      subtitle: 'No contiene anuncio',
                      description:
                          'Rápida y sencilla. Elige entre presets de calidad para reducir el tamaño de tus videos.',
                      color: colorScheme.primary,
                      onTap: () => context.push(AppRoutes.basic),
                    ),
                    SizedBox(height: ScreenSizeService.heightPercent(context, 6)),
                    _CompressionCard(
                      icon: Icons.auto_awesome,
                      title: 'Compresión avanzada',
                      subtitle: 'Contiene anuncio',
                      description:
                        'Mayor control utilizando FFmpeg. Permite modificar y ajustar bitrate, FPS y dimensión del video.',
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
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.tutorial),
                        icon: const Icon(Icons.school_rounded),
                        label: const Text('Ver Tutorial'),
                      ),
                    ),
                  ],
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

class _CompressionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _CompressionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: .15),
        highlightColor: color.withValues(alpha: .08),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: .25)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: .6)),
            ],
          ),
        ),
      ),
    );
  }
}
