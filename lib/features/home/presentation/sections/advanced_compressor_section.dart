import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/advanced_compression_dialog.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/advanced_video_info_table.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_preview_widget.dart';

/// Sección "Comprimir" del modo avanzado (FFmpeg).
///
/// Muestra preview, tabla con bitrate editable y FPS, y botón Comprimir.
/// Al pulsar Comprimir abre el diálogo Antes vs Después antes de ejecutar FFmpeg.
class AdvancedCompressorSection extends StatefulWidget {
  const AdvancedCompressorSection({super.key});

  @override
  State<AdvancedCompressorSection> createState() =>
      _AdvancedCompressorSectionState();
}

class _AdvancedCompressorSectionState
    extends State<AdvancedCompressorSection> {
  /// Bitrate objetivo en kbps. Null si el campo es inválido.
  int? _targetBitrateKbps;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        final video = state.video;

        if (video == null) {
          return const Center(child: Text('No hay video seleccionado'));
        }

        final isLoading =
            state.status == VideoStatus.loadingExtendedMetadata;

        // Inicializar bitrate objetivo con el valor del video si aún no se ha editado
        _targetBitrateKbps ??= video.bitrate > 0 ? video.bitrate ~/ 1000 : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview
              Stack(
                children: [
                  VideoPreviewWidget(
                    thumbnailPath: video.thumbnailPath,
                    height: ScreenSizeService.heightPercent(context, 22),
                  ),
                  if (isLoading)
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

              // Tabla con bitrate editable
              AdvancedVideoInfoTable(
                videoFile: video,
                onBitrateChanged: (kbps) {
                  setState(() => _targetBitrateKbps = kbps);
                },
              ),

              const SizedBox(height: 16),

              // Botón Comprimir
              SizedBox(
                width: ScreenSizeService.widthPercent(context, 90),
                child: FilledButton(
                  onPressed: _targetBitrateKbps == null ? null : _onCompress,
                  child: const Text('Comprimir'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onCompress() async {
    final video = context.read<VideoBloc>().state.video;
    if (video == null || _targetBitrateKbps == null) return;

    final config = await showDialog(
      context: context,
      builder: (_) => AdvancedCompressionDialog(
        video: video,
        targetBitrateKbps: _targetBitrateKbps!,
      ),
    );

    if (!mounted || config == null) return;

    context.read<VideoBloc>().add(
          CompressVideoAdvancedRequested(config: config),
        );
  }
}
