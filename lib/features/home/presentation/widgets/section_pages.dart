import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';

import 'video_info_table_widget.dart';
import 'video_preview_widget.dart';

/// Pintor personalizado para crear un borde punteado
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 8,
    this.dashSpace = 6,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDist = distance + dashWidth;
        final t1 = metric.getTangentForOffset(distance);
        final t2 = metric.getTangentForOffset(nextDist);
        if (t1 != null && t2 != null) {
          canvas.drawLine(t1.position, t2.position, paint);
        }
        distance = nextDist + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => false;
}
