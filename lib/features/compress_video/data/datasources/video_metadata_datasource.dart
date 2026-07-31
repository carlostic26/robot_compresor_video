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

    // Fecha de modificación del archivo como fallback básico.
    // La metadata extendida (FFprobe) sobreescribirá este valor con
    // la fecha real cuando se llame a LoadExtendedMetadataRequested.
    final createdAt = await file.lastModified();

    final video = VideoFile(
      path: videoPath,
      name: path.basename(videoPath),
      size: await file.length(),
      duration: value.duration,
      width: value.size.width.toInt(),
      height: value.size.height.toInt(),
      bitrate: 0,
      createdAt: createdAt,
      thumbnailPath: null,
    );

    await controller.dispose();

    return video;
  }
}
