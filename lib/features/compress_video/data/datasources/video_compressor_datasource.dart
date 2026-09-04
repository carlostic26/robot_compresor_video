import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:robot_compresor_video/features/compress_video/data/datasources/ffmpeg_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_metadata_datasource.dart';
import 'package:video_compress/video_compress.dart';

import '../../domain/entities/compression_config.dart';
import '../../domain/entities/compression_result.dart';
import '../../domain/entities/video_file.dart';

class VideoCompressorDatasource {
  final VideoMetadataDatasource metadataDatasource;
  final FfmpegDatasource ffmpegDatasource;

  VideoCompressorDatasource(this.metadataDatasource, this.ffmpegDatasource);

  Future<CompressionResult> compress({
    required VideoFile video,
    required CompressionConfig config,
    void Function(double progress, Duration? estimatedRemaining)? onProgress,
  }) async {
    Subscription? subscription;
    final startTime = DateTime.now();

    if (onProgress != null) {
      subscription = VideoCompress.compressProgress$.subscribe((
        progressPercent,
      ) {
        final progress = (progressPercent / 100.0).clamp(0.0, 1.0);
        Duration? remaining;
        if (progress > 0.03 && progress < 1.0) {
          final elapsed = DateTime.now().difference(startTime);
          final totalMs = elapsed.inMilliseconds / progress;
          final remainingMs = (totalMs - elapsed.inMilliseconds).round();
          if (remainingMs > 0) {
            remaining = Duration(milliseconds: remainingMs);
          }
        }
        onProgress(progress, remaining);
      });
    }

    try {
      final mediaInfo = await VideoCompress.compressVideo(
        video.path,
        quality: _mapQuality(config.quality),
        deleteOrigin: config.deleteOriginal,
      );

      if (mediaInfo == null || mediaInfo.path == null) {
        throw Exception('No fue posible comprimir el video.');
      }

      final tempFile = File(mediaInfo.path!);

      if (!await tempFile.exists()) {
        throw Exception('No se encontró el archivo comprimido.');
      }

      final directory = tempFile.parent.path;

      /// video.mp4
      final originalName = path.basename(video.path);

      /// 20260721_103545
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      /// compressed_20260721_103545_video.mp4
      final newName = 'compressed_${timestamp}_$originalName';

      final newPath = path.join(directory, newName);

      /// Si ya existe lo eliminamos
      final newFile = File(newPath);

      if (await newFile.exists()) {
        await newFile.delete();
      }

      /// Renombrar el archivo
      final renamedFile = await tempFile.rename(newPath);

      /// Leer metadata extendida del nuevo archivo via FFprobe
      /// (obtiene bitrate real, fps y fecha de modificación)
      final compressedVideo = await ffmpegDatasource.getExtendedMetadata(
        renamedFile.path,
      );

      return CompressionResult(
        compressedVideo: compressedVideo,
        originalSize: video.size,
        compressedSize: await renamedFile.length(),
      );
    } finally {
      subscription?.unsubscribe();
    }
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
