import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/core/routes/app_routes.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/app_info_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: .08),
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black.withValues(alpha: .08),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Robot Compresor Video',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    'Compresión inteligente de videos',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.hub);
              },
            ),

            ListTile(
              leading: const Icon(Icons.bolt_rounded),
              title: const Text('Compresión básica'),
              subtitle: const Text('video_compress'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.home);
              },
            ),

            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Compresión avanzada'),
              subtitle: const Text('FFmpeg'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.advanced);
              },
            ),

            const Divider(height: 28),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Información'),
              onTap: () {
                Navigator.pop(context);
                AppInfoDialog.show(context);
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Versión 1.0.0',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
