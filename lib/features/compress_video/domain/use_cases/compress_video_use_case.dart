import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';

class CompressVideoUseCase {
  final VideoRepository repository;

  CompressVideoUseCase(this.repository);

  Future<CompressionResult> call({
    required VideoFile video,
    required CompressionConfig config,
  }) {
    return repository.compressVideo(video: video, config: config);
  }
}
