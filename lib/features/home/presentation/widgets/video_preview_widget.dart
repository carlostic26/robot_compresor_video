import 'dart:io';

import 'package:flutter/material.dart';

import 'video_comparison_preview_widget.dart';

enum PreviewMode { play, processing }

/// Widget que muestra la miniatura del video.
/// Widget que muestra la miniatura del video o la comparativa Antes / Después.
class VideoPreviewWidget extends StatelessWidget {
  final String? thumbnailPath;
  final String? originalVideoPath;
  final String? compressedVideoPath;
  final double? width;
  final double? height;
  final PreviewMode mode;
  final double progress;
  final Duration? estimatedRemaining;

  const VideoPreviewWidget({
    super.key,
    required this.thumbnailPath,
    this.originalVideoPath,
    this.compressedVideoPath,
    this.width,
    this.height,
    this.mode = PreviewMode.play,
    this.progress = 0.0,
    this.estimatedRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final canCompare =
        mode != PreviewMode.processing &&
        originalVideoPath != null &&
        compressedVideoPath != null;

    if (canCompare) {
      return VideoComparisonPreviewWidget(
        originalVideoPath: originalVideoPath!,
        compressedVideoPath: compressedVideoPath!,
        thumbnailPath: thumbnailPath,
        width: width,
        height: height,
      );
    }

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

          if (mode == PreviewMode.processing)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _ProcessingScrim(progress: progress),
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress.clamp(0.0, 1.0) : null,
                        strokeWidth: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  'Procesando...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                if (estimatedRemaining != null &&
                    estimatedRemaining!.inSeconds > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Quedan aprox. ${_formatRemaining(estimatedRemaining!)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ] else if (progress > 0 && progress < 1.0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Calculando tiempo...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}

class _ProcessingScrim extends StatefulWidget {
  final double progress;
  const _ProcessingScrim({this.progress = 0.0});

  @override
  State<_ProcessingScrim> createState() => _ProcessingScrimState();
}

class _ProcessingScrimState extends State<_ProcessingScrim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black.withValues(alpha: 0.32)),

        // Progreso gradual horizontal en el eje X (de 0 a 100%)
        Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            widthFactor: clampedProgress,
            heightFactor: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.20),
                        Colors.blueAccent.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.9),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Destello animado sobre la superficie
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final width = MediaQuery.of(context).size.width;
            return Transform.translate(
              offset: Offset(((_controller.value * 2) - 1) * width, 0),
              child: child,
            );
          },
          child: Container(
            width: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
