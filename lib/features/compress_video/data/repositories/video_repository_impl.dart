import 'package:robot_compresor_video/features/compress_video/data/datasources/video_compressor_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_metadata_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_picker_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoPickerDatasource pickerDatasource;
  final VideoMetadataDatasource metadataDatasource;
  final VideoCompressorDatasource compressorDatasource;

  VideoRepositoryImpl(
    this.pickerDatasource,
    this.metadataDatasource,
    this.compressorDatasource,
  );

  @override
  Future<VideoFile?> pickVideo() async {
    final file = await pickerDatasource.pickVideo();

    if (file == null) {
      return null;
    }

    return metadataDatasource.getVideoMetadata(file);
  }

  @override
  Future<CompressionResult> compressVideo({
    required VideoFile video,
    required CompressionConfig config,
  }) {
    return compressorDatasource.compress(video: video, config: config);
  }
}
