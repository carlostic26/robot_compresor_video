import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:video_player/video_player.dart';

class VideoMetadataDatasource {
  Future<VideoFile> getVideoMetadata(PlatformFile file) async {
    final controller = VideoPlayerController.file(File(file.path!));

    await controller.initialize();

    final value = controller.value;

    final video = VideoFile(
      path: file.path!,
      name: file.name,
      size: file.size,
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
