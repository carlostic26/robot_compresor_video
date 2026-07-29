import 'package:robot_compresor_video/features/compress_video/data/datasources/ffmpeg_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/advanced_video_repository.dart';

class AdvancedVideoRepositoryImpl implements AdvancedVideoRepository {
  final FfmpegDatasource ffmpegDatasource;

  AdvancedVideoRepositoryImpl(this.ffmpegDatasource);

  @override
  Future<AdvancedCompressionResult> compressVideoAdvanced({
    required VideoFile video,
    required AdvancedCompressionConfig config,
  }) {
    return ffmpegDatasource.compress(video: video, config: config);
  }

  @override
  Future<VideoFile> getExtendedMetadata(String videoPath) {
    return ffmpegDatasource.getExtendedMetadata(videoPath);
  }

  @override
  Future<String> generateThumbnail(String videoPath) {
    return ffmpegDatasource.generateThumbnail(videoPath);
  }
}
