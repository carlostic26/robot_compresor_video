import 'dart:io';

import 'package:robot_compresor_video/features/compress_video/data/datasources/video_compressor_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_metadata_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_picker_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_storage_datasource.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoPickerDatasource pickerDatasource;
  final VideoMetadataDatasource metadataDatasource;
  final VideoCompressorDatasource compressorDatasource;
  final VideoStorageDatasource storageDatasource;

  VideoRepositoryImpl(
    this.pickerDatasource,
    this.metadataDatasource,
    this.compressorDatasource,
    this.storageDatasource,
  );

  @override
  Future<VideoFile?> pickVideo() async {
    final file = await pickerDatasource.pickVideo();

    if (file == null) {
      return null;
    }

    return metadataDatasource.getVideoMetadata(file.path!);
  }

  @override
  Future<CompressionResult> compressVideo({
    required VideoFile video,
    required CompressionConfig config,
    void Function(double progress, Duration? estimatedRemaining)? onProgress,
  }) {
    return compressorDatasource.compress(
      video: video,
      config: config,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> saveVideo(VideoFile video) async {
    final originalFile = File(video.path);
    if (!await originalFile.exists()) {
      return storageDatasource.saveVideo(video.path);
    }

    final currentDiskName = originalFile.uri.pathSegments.isNotEmpty
        ? originalFile.uri.pathSegments.last
        : '';
    String targetName = video.name.trim();

    if (targetName.isEmpty || targetName == currentDiskName) {
      return storageDatasource.saveVideo(video.path);
    }

    // Asegurar que conserve la extensión de video
    if (!targetName.contains('.')) {
      final ext = currentDiskName.contains('.')
          ? currentDiskName.split('.').last
          : 'mp4';
      targetName = '$targetName.$ext';
    }

    final targetPath = '${originalFile.parent.path}/$targetName';
    if (targetPath == video.path) {
      return storageDatasource.saveVideo(video.path);
    }

    final renamedFile = await originalFile.copy(targetPath);
    try {
      await storageDatasource.saveVideo(renamedFile.path);
    } finally {
      if (await renamedFile.exists()) {
        try {
          await renamedFile.delete();
        } catch (_) {}
      }
    }
  }
}
