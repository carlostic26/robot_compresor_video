import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

class AdvancedCompressionResult {
  final VideoFile compressedVideo;
  final int originalSize;
  final int compressedSize;

  /// Comando FFmpeg que se ejecutó, útil para debugging y logs.
  final String ffmpegCommand;

  const AdvancedCompressionResult({
    required this.compressedVideo,
    required this.originalSize,
    required this.compressedSize,
    required this.ffmpegCommand,
  });

  double get compressionRatio => compressedSize / originalSize;
  double get savedPercentage => 100 - (compressionRatio * 100);
}
