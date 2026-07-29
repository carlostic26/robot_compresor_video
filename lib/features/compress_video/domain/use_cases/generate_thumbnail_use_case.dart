import '../repositories/advanced_video_repository.dart';

class GenerateThumbnailUseCase {
  final AdvancedVideoRepository repository;

  GenerateThumbnailUseCase(this.repository);

  /// Genera una miniatura del video en [videoPath].
  /// Devuelve la ruta absoluta del archivo JPEG generado.
  Future<String> call(String videoPath) {
    return repository.generateThumbnail(videoPath);
  }
}
