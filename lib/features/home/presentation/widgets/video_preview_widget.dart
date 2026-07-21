import 'dart:io';

import 'package:flutter/material.dart';

enum PreviewMode { play, processing }

/// Widget que muestra la miniatura del video.
class VideoPreviewWidget extends StatelessWidget {
  final String? thumbnailPath;
  final double? width;
  final double? height;
  final PreviewMode mode;

  const VideoPreviewWidget({
    super.key,
    required this.thumbnailPath,
    this.width,
    this.height,
    this.mode = PreviewMode.play,
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
          /// Miniatura
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
            child: !hasThumbnail
                ? const Center(
                    child: Icon(
                      Icons.video_library_rounded,
                      size: 72,
                      color: Colors.white54,
                    ),
                  )
                : null,
          ),

          /// Oscurece ligeramente el preview
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.30),
            ),
          ),

          /// Contenido central
          if (mode == PreviewMode.play)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
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
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),

                const SizedBox(height: 14),

                Text(
                  'Procesando...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
