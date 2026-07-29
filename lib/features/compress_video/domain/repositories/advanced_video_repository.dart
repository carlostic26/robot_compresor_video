import '../entities/advanced_compression_config.dart';
import '../entities/advanced_compression_result.dart';
import '../entities/video_file.dart';

abstract class AdvancedVideoRepository {
  /// Comprime [video] usando FFmpeg con los parámetros de [config].
  /// Siempre opera sobre el video original, nunca sobre un resultado previo.
  Future<AdvancedCompressionResult> compressVideoAdvanced({
    required VideoFile video,
    required AdvancedCompressionConfig config,
  });

  /// Obtiene metadata extendida del video (bitrate real, fps, etc.) usando FFprobe.
  /// Complementa los datos que [VideoMetadataDatasource] no puede extraer.
  Future<VideoFile> getExtendedMetadata(String videoPath);
}
