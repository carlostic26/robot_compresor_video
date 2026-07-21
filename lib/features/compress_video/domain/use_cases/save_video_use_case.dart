import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';

class SaveVideoUseCase {
  final VideoRepository repository;

  SaveVideoUseCase(this.repository);

  Future<void> call(VideoFile video) {
    return repository.saveVideo(video);
  }
}