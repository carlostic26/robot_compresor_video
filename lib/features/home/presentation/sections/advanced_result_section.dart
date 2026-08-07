import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/advanced_video_info_table.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_preview_widget.dart';

/// Sección "Resultado" del modo avanzado (FFmpeg).
///
/// Durante la compresión:
/// - Preview con modo processing.
/// - Tabla con shimmer en Peso, Bit rate y FPS (valores aún desconocidos).
///
/// Al terminar:
/// - Preview con thumbnail del archivo comprimido.
/// - Tabla con valores reales del archivo final (via FFprobe).
/// - Botón Guardar / Subir otro video.
class AdvancedResultSection extends StatelessWidget {
  const AdvancedResultSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoBloc, VideoState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == VideoStatus.saved ||
              current.status == VideoStatus.failure),
      listener: (context, state) {
        if (state.status == VideoStatus.saved) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text('✅ Video guardado en la galería'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
        }
        if (state.status == VideoStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text('❌ Error al guardar: ${state.error}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
        }
      },
      builder: (context, state) {
        final result = state.advancedCompressionResult;

        // ── Compresión en proceso ──────────────────────────────────────────
        // Shimmer en Peso, Bit rate y FPS — valores del archivo final aún desconocidos.
        if (state.status == VideoStatus.compressingAdvanced &&
            state.video != null) {
          final sourceVideo = state.video!;
          final processingVideo = _buildProcessingDisplayVideo(sourceVideo);
          final processingThumb = state.thumbnailPath ?? sourceVideo.thumbnailPath;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AdvancedVideoInfoTable(
                  videoFile: processingVideo,
                  thumbnailPath: processingThumb,
                  previewMode: PreviewMode.processing,
                  onBitrateChanged: (_) {},
                  isResultLoading: true,
                ),
              ],
            ),
          );
        }

        // ── Sin resultado aún ──────────────────────────────────────────────
        if (result == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined,
                    size: 64, color: Colors.grey.shade500),
                const SizedBox(height: 16),
                Text(
                  'Aún no hay un video comprimido',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando finalice la compresión\nel resultado aparecerá aquí.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // ── Resultado final ────────────────────────────────────────────────
        // compressedVideo contiene los valores reales del archivo final
        // obtenidos via FFprobe en FfmpegDatasource.compress().
        final isSaving = state.status == VideoStatus.saving;
        final isSaved = state.status == VideoStatus.saved;
        final compressedVideo = result.compressedVideo;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (isSaved) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .read<VideoBloc>()
                        .add(const ResetVideoRequested()),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Subir otro video'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Tabla con valores reales del archivo comprimido.
              // finalSizeMB fuerza mostrar el peso real (no shimmer).
              AdvancedVideoInfoTable(
                videoFile: compressedVideo,
                thumbnailPath: state.thumbnailPath,
                onBitrateChanged: (_) {},
                finalSizeMB: compressedVideo.sizeMB,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (isSaving || isSaved)
                      ? null
                      : () => context
                          .read<VideoBloc>()
                          .add(const SaveVideoRequested()),
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isSaved ? Icons.check : Icons.save_alt),
                  label: Text(
                    isSaving
                        ? 'Guardando...'
                        : isSaved
                            ? 'Guardado'
                            : 'Guardar video',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  VideoFile _buildProcessingDisplayVideo(VideoFile source) {
    final name = source.name.startsWith('compress_') ||
            source.name.startsWith('compressed_')
        ? source.name
        : 'compress_${source.name}';

    return VideoFile(
      path: source.path,
      name: name,
      size: source.size,
      duration: source.duration,
      width: source.width,
      height: source.height,
      bitrate: source.bitrate,
      fps: source.fps,
      createdAt: source.createdAt,
      thumbnailPath: source.thumbnailPath,
    );
  }
}
