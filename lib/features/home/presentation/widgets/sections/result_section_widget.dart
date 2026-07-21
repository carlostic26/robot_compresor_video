import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_info_table_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_preview_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/video_summary_widget.dart';

class ResultSection extends StatelessWidget {
  const ResultSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        final result = state.compressionResult;

        /// ==========================
        /// COMPRESIÓN EN PROCESO
        /// ==========================
        if (state.status == VideoStatus.compressing && state.video != null) {
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

        /// ==========================
        /// AÚN NO EXISTE RESULTADO
        /// ==========================
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        /// ==========================
        /// RESULTADO FINAL
        /// ==========================
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: VideoSummaryWidget(video: result.compressedVideo),
        );
      },
    );
  }
}
