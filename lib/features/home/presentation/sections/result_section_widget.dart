import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_info_table_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_preview_widget.dart';

class ResultSection extends StatelessWidget {
  const ResultSection({super.key});

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
        final result = state.activeCompressedVideo;

        // ── Compresión en proceso ──────────────────────────────────────────
        final isProcessing = state.status == VideoStatus.compressing ||
            state.status == VideoStatus.compressingAdvanced;
        if (isProcessing && state.video != null) {
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
                VideoInfoTableWidget(videoFile: state.video!, isLoading: true),
                const SizedBox(height: 24),
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Comprimiendo video...',
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
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey.shade500,
                ),
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

        // El video comprimido con el thumbnailPath actualizado desde el estado
        final videoWithThumb = result;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview con thumbnail real (o placeholder si aún se genera)
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

              VideoInfoTableWidget(
                videoFile: videoWithThumb,
                thumbnailPath: state.thumbnailPath,
              ),

              const SizedBox(height: 24),

              // Botón Guardar video
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

              // Botón "Subir otro video" — solo visible tras guardado exitoso
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
