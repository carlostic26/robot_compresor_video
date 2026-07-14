import 'package:flutter/material.dart';
import 'core/routes/app_router.dart';
import 'core/services/injection_container.dart';
import 'core/theme/app_theme.dart';

void main() {
  setupDependencies();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Robot Compresor Video',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
