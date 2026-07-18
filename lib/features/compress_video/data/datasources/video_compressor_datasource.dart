import '../../domain/entities/compression_config.dart';
import '../../domain/entities/compression_result.dart';
import '../../domain/entities/video_file.dart';

class VideoCompressorDatasource {
  Future<CompressionResult> compress({
    required VideoFile video,
    required CompressionConfig config,
  }) async {
    throw UnimplementedError();
  }
}
