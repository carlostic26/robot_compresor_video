import '../entities/compression_config.dart';
import '../entities/compression_result.dart';
import '../entities/video_file.dart';

abstract class VideoRepository {
  Future<VideoFile?> pickVideo();

  Future<CompressionResult> compressVideo({
    required VideoFile video,
    required CompressionConfig config,
  });
}
