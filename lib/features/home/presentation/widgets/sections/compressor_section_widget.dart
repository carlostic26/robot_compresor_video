import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/compression_dialog.dart';

import '../video_info_table_widget.dart';
import '../video_preview_widget.dart';

class CompressorSection extends StatelessWidget {
  const CompressorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        final video = state.video;

        if (video == null) {
          return const Center(child: Text('No hay video seleccionado'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              VideoPreviewWidget(
                thumbnailPath: video.thumbnailPath,
                height: ScreenSizeService.heightPercent(context, 22),
              ),

              const SizedBox(height: 24),

              VideoInfoTableWidget(videoFile: video),

              const SizedBox(height: 16),

              Center(
                child: SizedBox(
                  width: ScreenSizeService.widthPercent(context, 90),
                  child: FilledButton(
                    onPressed: () async {
                      final config = await showDialog<CompressionConfig>(
                        context: context,
                        builder: (_) => const CompressionDialog(),
                      );

                      if (!context.mounted || config == null) {
                        return;
                      }

                      context.read<VideoBloc>().add(
                        CompressVideoRequested(config: config),
                      );
                    },
                    child: const Text('Comprimir'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
