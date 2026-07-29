import '../entities/advanced_compression_config.dart';
import '../entities/advanced_compression_result.dart';
import '../entities/video_file.dart';

abstract class AdvancedVideoRepository {
  Future<AdvancedCompressionResult> compressVideoAdvanced({
    required VideoFile video,
    required AdvancedCompressionConfig config,
  });

  Future<VideoFile> getExtendedMetadata(String videoPath);

  /// Genera una miniatura JPEG del video en [videoPath].
  /// Devuelve la ruta absoluta del archivo generado en el directorio temporal.
  Future<String> generateThumbnail(String videoPath);
}
