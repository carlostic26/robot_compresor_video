/// Configuración para la compresión avanzada mediante FFmpeg.
///
/// Cada campo es opcional: si es null, FFmpeg conserva el valor original
/// del video fuente. Esto permite comprimir sólo los parámetros que el
/// usuario desea modificar sin afectar el resto.
///
/// Extensible: para agregar CRF, codec, resolución, preset o audio
/// basta con añadir el campo aquí y actualizar [FfmpegCommandBuilder].
class AdvancedCompressionConfig {
  /// Bitrate de video objetivo en bits por segundo (ej. 4000000 = 4 Mbps).
  final int? targetVideoBitrate;

  /// FPS objetivo (ej. 30). Debe ser <= FPS original.
  final int? targetFps;

  // ── Campos preparados para iteraciones futuras ──────────────────────────
  // final String? videoCodec;   // ej. 'libx264', 'libx265'
  // final int? crf;             // Constant Rate Factor (0-51)
  // final String? preset;       // ej. 'fast', 'medium', 'slow'
  // final int? width;           // Resolución ancho (mantiene aspect ratio si height es null)
  // final int? height;          // Resolución alto
  // final int? targetAudioBitrate; // Bitrate de audio en bps

  const AdvancedCompressionConfig({
    this.targetVideoBitrate,
    this.targetFps,
  });
}
