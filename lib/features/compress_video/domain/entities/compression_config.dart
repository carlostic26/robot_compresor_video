class CompressionConfig {
  final int quality;
  final bool deleteOriginal;

  const CompressionConfig({required this.quality, this.deleteOriginal = false});
}
