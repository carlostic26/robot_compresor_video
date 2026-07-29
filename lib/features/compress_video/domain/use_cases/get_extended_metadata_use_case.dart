import '../entities/video_file.dart';
import '../repositories/advanced_video_repository.dart';

class GetExtendedMetadataUseCase {
  final AdvancedVideoRepository repository;

  GetExtendedMetadataUseCase(this.repository);

  Future<VideoFile> call(String videoPath) {
    return repository.getExtendedMetadata(videoPath);
  }
}
