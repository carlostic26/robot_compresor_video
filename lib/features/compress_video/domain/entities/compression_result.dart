import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

class CompressionResult {
  final VideoFile compressedVideo;

  final int originalSize;
  final int compressedSize;
  
  const CompressionResult({
    required this.compressedVideo,
    required this.originalSize,
    required this.compressedSize,
  });

  double get compressionRatio => compressedSize / originalSize;

  double get savedPercentage => 100 - (compressionRatio * 100);
}
