import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/features/home/presentation/home_screen.dart';
import 'package:robot_compresor_video/features/home/presentation/loading_screen.dart';

import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.loading,
  routes: [
    GoRoute(
      path: AppRoutes.loading,
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
