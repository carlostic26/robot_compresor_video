import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/core/routes/app_routes.dart';
import 'package:robot_compresor_video/core/services/ad_service.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _onLoadingComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onLoadingComplete() async {
    try {
      await AdService.showAppOpenAd();
    } catch (_) {
      // Ignorar fallos de anuncio y seguir con la navegación.
    }

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = ScreenSizeService.shortestSidePercent(context, 48);
    final progressWidth = ScreenSizeService.widthPercent(context, 60);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF020912),
              gradient: RadialGradient(
                center: Alignment(0, -0.05),
                radius: 0.85,
                colors: [
                  Color(0xFF06283A),
                  Color(0xFF031522),
                  Color(0xFF020912),
                ],
                stops: [
                  0.0,
                  0.45,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo de luz detrás del logo
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.22,
                  child: Container(
                    width: logoSize * 1.25,
                    height: logoSize * 1.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF00D9FF).withValues(alpha: .30),
                          blurRadius: 100,
                          spreadRadius: 35,
                        ),
                        BoxShadow(
                          color: const Color(0xFF00B8D9).withValues(alpha: .20),
                          blurRadius: 180,
                          spreadRadius: 60,
                        ),
                      ],
                    ),
                  ),
                ),

                // Contenido principal
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9FF).withValues(alpha: .30),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(
                      height: ScreenSizeService.heightPercent(context, 2),
                    ),

                    // Nombre de la aplicación
                    const Column(
                      children: [
                        Text(
                          'Robot',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Compresor de Video',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: ScreenSizeService.heightPercent(context, 8),
                    ),

                    // Barra de progreso
                    SizedBox(
                      width: progressWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight:6,
                          backgroundColor: const Color(0xFF163044),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: ScreenSizeService.heightPercent(context, 1),
                    ),

                    // Estado de carga
                    const Text(
                      'Cargando recursos...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                        color: Color(0xFFA9C0D2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}