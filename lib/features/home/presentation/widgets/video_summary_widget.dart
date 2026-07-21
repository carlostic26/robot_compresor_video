import 'package:flutter/material.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

import 'video_info_table_widget.dart';
import 'video_preview_widget.dart';

class VideoSummaryWidget extends StatelessWidget {
  final VideoFile video;

  const VideoSummaryWidget({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VideoPreviewWidget(
          thumbnailPath: video.thumbnailPath,
          height: ScreenSizeService.heightPercent(context, 22),
        ),

        const SizedBox(height: 24),

        VideoInfoTableWidget(videoFile: video),
      ],
    );
  }
}
