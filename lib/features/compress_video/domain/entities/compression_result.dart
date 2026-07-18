class CompressionResult {
  final String outputPath;
  final int originalSize;
  final int compressedSize;

  const CompressionResult({
    required this.outputPath,
    required this.originalSize,
    required this.compressedSize,
  });

  double get compressionRatio => compressedSize / originalSize;

  double get savedPercentage => 100 - (compressionRatio * 100);
}
