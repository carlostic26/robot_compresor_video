enum CompressionQuality { low, medium, high }

class CompressionConfig {
  final CompressionQuality quality;
  final bool deleteOriginal;

  const CompressionConfig({required this.quality, this.deleteOriginal = false});
}
