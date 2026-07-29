import 'package:flutter/material.dart';

/// Placeholder animado para indicar que un dato aún se está cargando.
class LoadingPlaceholderWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingPlaceholderWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<LoadingPlaceholderWidget> createState() =>
      _LoadingPlaceholderWidgetState();
}

class _LoadingPlaceholderWidgetState extends State<LoadingPlaceholderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(6);

    return ClipRRect(
      borderRadius: borderRadius,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, snapshot) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final width = bounds.width;

              final dx = (-width) + (_controller.value * width * 2);

              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey.shade800,
                  Colors.grey.shade700,
                  Colors.grey.shade500,
                  Colors.grey.shade700,
                  Colors.grey.shade800,
                ],
                stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
                transform: _SlidingGradientTransform(dx),
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey.shade700,
            ),
          );
        },
      ),
    );
  }
}

/// Desplaza el gradiente horizontalmente.
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(slidePercent, 0, 0);
  }
}
