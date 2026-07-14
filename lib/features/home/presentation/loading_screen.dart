import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/core/routes/app_routes.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _animation.value;
    final iconSize = ScreenSizeService.shortestSidePercent(context, 40);
    final progressWidth = ScreenSizeService.widthPercent(context, 60);
    final verticalSpace = ScreenSizeService.heightPercent(context, 3);
    final horizontalPadding = ScreenSizeService.widthPercent(context, 8);
    final widthScreen = ScreenSizeService.widthPercent(context, 50);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: widthScreen,
              child: Placeholder(
                fallbackHeight: iconSize,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: verticalSpace),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  SizedBox(
                    width: progressWidth,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(height: verticalSpace * 0.5),
                  Text('${(progress * 100).round()}%'),
                  SizedBox(height: ScreenSizeService.heightPercent(context, 5)),
                  TextButton(
                    onPressed: () {
                      context.go(AppRoutes.home);
                    },
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
