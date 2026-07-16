import 'package:flutter/material.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';

import 'video_info_table_widget.dart';
import 'video_preview_widget.dart';


class CompressorSection extends StatelessWidget {
  const CompressorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Preview del video
          VideoPreviewWidget(
            thumbnailUrl:
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop',
            height: ScreenSizeService.heightPercent(context, 22),
          ),
          const SizedBox(height: 24),

          /// Información del video
          VideoInfoTableWidget(videoInfo: VideoInfo.mock()),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: ScreenSizeService.widthPercent(context, 90),
              child: FilledButton(
                onPressed: () {},
                child: const Text('Comprimir'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
