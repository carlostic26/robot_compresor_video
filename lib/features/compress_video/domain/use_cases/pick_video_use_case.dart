import '../entities/video_file.dart';
import '../repositories/video_repository.dart';

class PickVideoUseCase {
  final VideoRepository repository;

  PickVideoUseCase(this.repository);

  Future<VideoFile?> call() {
    return repository.pickVideo();
  }
}
