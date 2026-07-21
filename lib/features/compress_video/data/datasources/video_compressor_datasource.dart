import 'dart:io';

import 'package:robot_compresor_video/features/compress_video/data/datasources/video_metadata_datasource.dart';
import 'package:video_compress/video_compress.dart';

import '../../domain/entities/compression_config.dart';
import '../../domain/entities/compression_result.dart';
import '../../domain/entities/video_file.dart';

class VideoCompressorDatasource {
  final VideoMetadataDatasource metadataDatasource;

  VideoCompressorDatasource(this.metadataDatasource);

  Future<CompressionResult> compress({
    required VideoFile video,
    required CompressionConfig config,
  }) async {
    final mediaInfo = await VideoCompress.compressVideo(
      video.path,
      quality: _mapQuality(config.quality),
      deleteOrigin: config.deleteOriginal,
    );

    if (mediaInfo == null || mediaInfo.path == null) {
      throw Exception('No fue posible comprimir el video.');
    }

    final compressedFile = File(mediaInfo.path!);

final compressedVideo = await metadataDatasource.getVideoMetadata(
      mediaInfo.path!,
    );

    return CompressionResult(
      compressedVideo: compressedVideo,
      originalSize: video.size,
      compressedSize: await compressedFile.length(),
    );
  }

  VideoQuality _mapQuality(CompressionQuality quality) {
    switch (quality) {
      case CompressionQuality.low:
        return VideoQuality.LowQuality;

      case CompressionQuality.medium:
        return VideoQuality.MediumQuality;

      case CompressionQuality.high:
        return VideoQuality.HighestQuality;
    }
  }
}
