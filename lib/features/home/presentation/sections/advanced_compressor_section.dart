import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/advanced_compression_dialog.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/advanced_mode_dialog.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/advanced_video_info_table.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_preview_widget.dart';

/// Sección "Comprimir" del modo avanzado (FFmpeg).
///
/// Flujo al pulsar "Comprimir":
/// 1. [AdvancedModeDialog] — explica FFmpeg, punto de extensión para anuncios.
/// 2. [AdvancedCompressionDialog] — tabla Antes vs Después para confirmar config.
/// 3. Dispatch [CompressVideoAdvancedRequested] con bitrate Y fps del usuario.
///
/// Si el usuario cancela en cualquier paso, la compresión no se inicia.
class AdvancedCompressorSection extends StatefulWidget {
  const AdvancedCompressorSection({super.key});

  @override
  State<AdvancedCompressorSection> createState() =>
      _AdvancedCompressorSectionState();
}

class _AdvancedCompressorSectionState extends State<AdvancedCompressorSection> {
  /// Bitrate objetivo en kbps. Null si el campo es inválido.
  int? _targetBitrateKbps;

  /// FPS objetivo. Null si el campo es inválido.
  int? _targetFps;

  /// Indica si los valores iniciales ya fueron cargados desde el video.
  bool _initialized = false;

  void _initFromVideo(VideoState state) {
    if (_initialized) return;
    final video = state.video;
    if (video == null) return;
    // Solo inicializar cuando la metadata extendida ya esté disponible
    if (video.bitrate > 0 || video.fps > 0) {
      _targetBitrateKbps = video.bitrate > 0 ? video.bitrate ~/ 1000 : null;
      _targetFps = video.fps > 0 ? video.fps.round() : null;
      _initialized = true;
    }
  }

  bool get _canCompress => _targetBitrateKbps != null;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        final video = state.video;

        if (video == null) {
          return const Center(child: Text('No hay video seleccionado'));
        }

        final isLoading = state.status == VideoStatus.loadingExtendedMetadata;

        // Inicializar valores desde el video cuando la metadata esté lista
        _initFromVideo(state);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview con overlay de carga mientras se obtiene metadata
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
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Obteniendo información...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Tabla con bitrate y FPS editables
              AdvancedVideoInfoTable(
                videoFile: video,
                onBitrateChanged: (kbps) {
                  setState(() => _targetBitrateKbps = kbps);
                },
                onFpsChanged: (fps) {
                  setState(() => _targetFps = fps);
                },
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: ScreenSizeService.widthPercent(context, 90),
                child: FilledButton(
                  onPressed: _canCompress ? _onCompress : null,
                  child: const Text('Comprimir'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Flujo al pulsar "Comprimir":
  /// 1. Diálogo informativo FFmpeg (punto de extensión para anuncios).
  /// 2. Diálogo de confirmación Antes vs Después.
  /// 3. Dispatch compresión con bitrate Y fps del usuario.
  Future<void> _onCompress() async {
    final video = context.read<VideoBloc>().state.video;
    if (video == null || _targetBitrateKbps == null) return;

    // Paso 1: Diálogo informativo / punto de extensión para anuncios.
    var shouldProceed = false;
    await AdvancedModeDialog.showAsync(
      context,
      onContinue: () => shouldProceed = true,
    );

    if (!mounted || !shouldProceed) return;

    // Paso 2: Diálogo de confirmación Antes vs Después.
    final config = await showDialog<AdvancedCompressionConfig>(
      context: context,
      builder: (_) => AdvancedCompressionDialog(
        video: video,
        targetBitrateKbps: _targetBitrateKbps!,
        targetFps: _targetFps,
      ),
    );

    if (!mounted || config == null) return;

    // Paso 3: Ejecutar compresión con bitrate y fps del usuario.
    context.read<VideoBloc>().add(
          CompressVideoAdvancedRequested(config: config),
        );
  }
}
