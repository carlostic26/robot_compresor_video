import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/routes/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/injection_container.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    debugPrint('Could not load .env file: $error');
    debugPrint('$stackTrace');
  }

  await setupDependencies();

  try {
    await AdService.initialize();
  } catch (error, stackTrace) {
    debugPrint('AdService initialization failed: $error');
    debugPrint('$stackTrace');
  }

  FlutterError.onError = (details) {
    debugPrint('Flutter framework error: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
    FlutterError.presentError(details);
  };

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
