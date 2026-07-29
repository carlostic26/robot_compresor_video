import '../entities/advanced_compression_config.dart';
import '../entities/advanced_compression_result.dart';
import '../entities/video_file.dart';
import '../repositories/advanced_video_repository.dart';

class CompressVideoAdvancedUseCase {
  final AdvancedVideoRepository repository;

  CompressVideoAdvancedUseCase(this.repository);

  Future<AdvancedCompressionResult> call({
    required VideoFile video,
    required AdvancedCompressionConfig config,
  }) {
    return repository.compressVideoAdvanced(video: video, config: config);
  }
}
