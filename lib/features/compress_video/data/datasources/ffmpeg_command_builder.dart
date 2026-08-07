import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';

/// Construye el array de argumentos para FFmpeg de forma declarativa.
///
/// Diseño extensible: para agregar un nuevo parámetro (CRF, codec, resolución,
/// preset, audio, etc.) basta con añadir un bloque `if (config.campo != null)`
/// en [build] sin modificar ninguna otra clase.
///
/// Ejemplo de comando generado:
///   -y -i input.mp4 -b:v 4000k -r 30 -c:a copy output.mp4
class FfmpegCommandBuilder {
  /// Construye la lista de argumentos FFmpeg a partir de [config].
  ///
  /// [inputPath]  ruta absoluta del video original.
  /// [outputPath] ruta absoluta del archivo de salida.
  List<String> build({
    required String inputPath,
    required String outputPath,
    required AdvancedCompressionConfig config,
  }) {
    final args = <String>[
      '-y',           // Sobreescribir sin preguntar
      '-i', inputPath,
      '-map', '0:v:0',
    ];

    if (config.targetVideoBitrate != null) {
      // Convertir bps → k (FFmpeg usa kilobits)
      final kbps = (config.targetVideoBitrate! / 1000).round();
      args.addAll(['-b:v', '${kbps}k']);

      // Control de bitrate más estricto (near-CBR).
      // Nota: el bitrate final de archivo puede variar por audio/mux overhead.
      final bufKbps = (kbps * 2).clamp(500, 2000000);
      args.addAll([
        '-minrate', '${kbps}k',
        '-maxrate', '${kbps}k',
        '-bufsize', '${bufKbps}k',
        '-x264-params', 'nal-hrd=cbr:force-cfr=1',
      ]);
    }

    if (config.targetFps != null) {
      args.addAll(['-r', config.targetFps.toString()]);
    }

    // Forzar un encode de video estable para asegurar stream de salida válido.
    args.addAll(['-c:v', 'libx264', '-pix_fmt', 'yuv420p']);

    // ── Bloques preparados para iteraciones futuras ──────────────────────
    // if (config.videoCodec != null) args.addAll(['-c:v', config.videoCodec!]);
    // if (config.crf != null)        args.addAll(['-crf', config.crf.toString()]);
    // if (config.preset != null)     args.addAll(['-preset', config.preset!]);
    // if (config.width != null || config.height != null) {
    //   final w = config.width ?? -2;   // -2 mantiene aspect ratio
    //   final h = config.height ?? -2;
    //   args.addAll(['-vf', 'scale=$w:$h']);
    // }
    // if (config.targetAudioBitrate != null) {
    //   final abr = (config.targetAudioBitrate! / 1000).round();
    //   args.addAll(['-b:a', '${abr}k']);
    // }

    // Incluir audio solo si existe y copiarlo sin recodificar.
    args.addAll(['-map', '0:a?']);

    // Copiar audio sin recodificar si no se especificó bitrate de audio
    args.addAll(['-c:a', 'copy']);

    args.add(outputPath);

    return args;
  }

  /// Devuelve el comando como string legible para logs y debugging.
  String buildAsString({
    required String inputPath,
    required String outputPath,
    required AdvancedCompressionConfig config,
  }) {
    final args = build(
      inputPath: inputPath,
      outputPath: outputPath,
      config: config,
    );
    return 'ffmpeg ${args.join(' ')}';
  }
}
