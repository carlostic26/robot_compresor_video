import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/advanced_video_info_table.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_preview_widget.dart';

/// Sección "Resultado" del modo avanzado (FFmpeg).
///
/// Muestra el video comprimido con:
/// - Preview con thumbnail real.
/// - Tabla con loading granular SOLO en el campo Peso mientras FFmpeg procesa.
/// - Botón Guardar con estados saving/saved.
/// - Botón "Subir otro video" tras guardado exitoso.
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
        if (state.status == VideoStatus.compressingAdvanced &&
            state.video != null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                VideoPreviewWidget(
                  thumbnailPath: state.video!.thumbnailPath,
                  mode: PreviewMode.processing,
                  height: ScreenSizeService.heightPercent(context, 22),
                ),
                const SizedBox(height: 24),
                // Tabla con shimmer en Peso (tamaño aún desconocido)
                AdvancedVideoInfoTable(
                  videoFile: state.video!,
                  onBitrateChanged: (_) {},
                  isSizeLoading: true,
                ),
                const SizedBox(height: 24),
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Comprimiendo con FFmpeg...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
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
        final isSaving = state.status == VideoStatus.saving;
        final isSaved = state.status == VideoStatus.saved;
        final isGeneratingThumb =
            state.status == VideoStatus.generatingThumbnail;

        // El peso es conocido una vez que FFmpeg terminó y tenemos el resultado.
        // Durante generatingThumbnail el archivo ya existe → peso disponible.
        final compressedVideo = result.compressedVideo;
        final finalSizeMB = compressedVideo.sizeMB;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview con thumbnail real
              Stack(
                children: [
                  VideoPreviewWidget(
                    thumbnailPath: state.thumbnailPath,
                    height: ScreenSizeService.heightPercent(context, 22),
                  ),
                  if (isGeneratingThumb)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Tabla con peso real (no loading)
              AdvancedVideoInfoTable(
                videoFile: compressedVideo,
                onBitrateChanged: (_) {},
                finalSizeMB: finalSizeMB,
              ),

              const SizedBox(height: 24),

              // Botón Guardar
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

              // Botón "Subir otro video" — solo tras guardado exitoso
              if (isSaved) ...[
                const SizedBox(height: 12),
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
              ],
            ],
          ),
        );
      },
    );
  }
}
