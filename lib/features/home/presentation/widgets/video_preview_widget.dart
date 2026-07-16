import 'package:flutter/material.dart';

/// Widget que muestra la miniatura del video con un botón de play superpuesto
class VideoPreviewWidget extends StatelessWidget {
  /// URL de la imagen de previsualización (mock)
  final String thumbnailUrl;

  /// Ancho del widget (opcional)
  final double? width;

  /// Alto del widget (opcional)
  final double? height;

  const VideoPreviewWidget({
    super.key,
    required this.thumbnailUrl,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[800],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// Imagen de previsualización
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(thumbnailUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Overlay oscuro semi-transparente
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          /// Botón de reproducción (sin acción funcional)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 40,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
