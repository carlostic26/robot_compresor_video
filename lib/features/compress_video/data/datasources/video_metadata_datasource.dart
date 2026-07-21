import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:video_player/video_player.dart';

class VideoMetadataDatasource {
  Future<VideoFile> getVideoMetadata(String videoPath) async {
    final file = File(videoPath);

    final controller = VideoPlayerController.file(file);

    await controller.initialize();

    final value = controller.value;

    final video = VideoFile(
      path: videoPath,
      name: path.basename(videoPath),
      size: await file.length(),
      duration: value.duration,
      width: value.size.width.toInt(),
      height: value.size.height.toInt(),

      // Los completaremos más adelante
      bitrate: 0,
      createdAt: null,
      thumbnailPath: null,
    );

    await controller.dispose();

    return video;
  }
}
