import 'package:flutter/material.dart';
import 'dart:io';

/// Widget que muestra la miniatura del video con un botón de play superpuesto
class VideoPreviewWidget extends StatelessWidget {
  final String? thumbnailPath;
  final double? width;
  final double? height;

  const VideoPreviewWidget({
    super.key,
    required this.thumbnailPath,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumbnail =
        thumbnailPath != null && File(thumbnailPath!).existsSync();
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
              image: hasThumbnail
                  ? DecorationImage(
                      image: FileImage(File(thumbnailPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: thumbnailPath == null
                ? const Center(
                    child: Icon(
                      Icons.video_library_rounded,
                      size: 72,
                      color: Colors.white54,
                    ),
                  )
                : null,
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
