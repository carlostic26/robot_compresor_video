import 'package:flutter/material.dart';

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

class SubirSection extends StatelessWidget {
  const SubirSection({super.key});

  void _onUploadPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Boton de subida tocado'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Container(
          color: Colors.blueGrey[900],
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: screenHeight * 0.3,
            child: GestureDetector(
              onTap: () => _onUploadPressed(context),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: Colors.blue.withValues(alpha: 0.5),
                  strokeWidth: 2,
                  dashWidth: 10,
                  dashSpace: 8,
                  borderRadius: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono de nube con flecha hacia arriba
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 80,
                        color: Colors.blue,
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Título principal
                      Text(
                        'Sube tu video',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.005),

                      // Subtítulo
                      Text(
                        'Toca para seleccionar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Formatos soportados
                      Text(
                        'MP4, MOV, AVI, MKV',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tamaño máximo
                      Text(
                        'Tamaño máximo: 2 GB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sección para comprimir videos
class CompressorSection extends StatelessWidget {
  const CompressorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Preview del video
          VideoPreviewWidget(
            thumbnailUrl:
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop',
            height: 250,
          ),
          const SizedBox(height: 24),

          /// Información del video
          VideoInfoTableWidget(videoInfo: VideoInfo.mock()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Sección para opciones avanzadas
class AvanzadoSection extends StatelessWidget {
  const AvanzadoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Sección Avanzado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            'Aquí irá el contenido de opciones avanzadas',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Sección para ver resultados
class ResultadoSection extends StatelessWidget {
  const ResultadoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Sección de Resultado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            'Aquí irá el contenido del resultado',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
