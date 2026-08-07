import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/ffmpeg_command_builder.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

import 'video_metadata_datasource.dart';

class FfmpegDatasource {
  final FfmpegCommandBuilder commandBuilder;
  final VideoMetadataDatasource metadataDatasource;

  FfmpegDatasource({
    required this.commandBuilder,
    required this.metadataDatasource,
  });

  // ── Compresión avanzada ──────────────────────────────────────────────────

  Future<AdvancedCompressionResult> compress({
    required VideoFile video,
    required AdvancedCompressionConfig config,
  }) async {
    final outputPath = _buildOutputPath(video.path);

    final command = commandBuilder.buildAsString(
      inputPath: video.path,
      outputPath: outputPath,
      config: config,
    );

    final args = commandBuilder.build(
      inputPath: video.path,
      outputPath: outputPath,
      config: config,
    );

    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogsAsString();
      throw Exception('FFmpeg falló (código $returnCode).\n$logs');
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      throw Exception('FFmpeg no generó el archivo de salida: $outputPath');
    }

    final compressedVideo = await getExtendedMetadata(outputPath);

    return AdvancedCompressionResult(
      compressedVideo: compressedVideo,
      originalSize: video.size,
      compressedSize: await outputFile.length(),
      ffmpegCommand: command,
    );
  }

  // ── Metadata extendida ───────────────────────────────────────────────────

  /// Extrae metadata completa usando FFprobe: bitrate real, fps, resolución,
  /// duración y fecha de modificación del archivo (= fecha de procesamiento).
  Future<VideoFile> getExtendedMetadata(String videoPath) async {
    final session = await FFprobeKit.getMediaInformation(videoPath);
    final info = session.getMediaInformation();

    final file = File(videoPath);

    // Fecha de modificación del archivo = fecha en que fue procesado/comprimido.
    // Es la fuente más confiable porque el archivo comprimido siempre tiene
    // una fecha de modificación real, independientemente del contenedor de video.
    final createdAt = await file.lastModified();

    if (info == null) {
      return metadataDatasource.getVideoMetadata(videoPath);
    }

    final streams = info.getStreams();
    final videoStream = _selectBestVideoStream(streams);

    if (videoStream == null) {
      // Fallback seguro si FFprobe no expone stream de video usable.
      final basic = await metadataDatasource.getVideoMetadata(videoPath);
      final fallbackBitrate = int.tryParse(info.getBitrate() ?? '0') ?? 0;
      return VideoFile(
        path: basic.path,
        name: basic.name,
        size: basic.size,
        duration: basic.duration,
        width: basic.width,
        height: basic.height,
        bitrate: fallbackBitrate,
        fps: 0,
        createdAt: createdAt,
        thumbnailPath: null,
      );
    }

    // Preferir bitrate del stream de video para que coincida mejor con
    // el valor objetivo ingresado por el usuario en compresión avanzada.
    // Si no está disponible, usar el bitrate total del contenedor.
    final containerBitrate = int.tryParse(info.getBitrate() ?? '0') ?? 0;
    final streamBitrate =
        int.tryParse(_streamProp(videoStream, 'bit_rate') ?? '0') ?? 0;
    final bitrate = streamBitrate > 0 ? streamBitrate : containerBitrate;

    final fps = _parseFps(videoStream.getRealFrameRate()) > 0
        ? _parseFps(videoStream.getRealFrameRate())
        : _parseFps(_streamProp(videoStream, 'avg_frame_rate')) > 0
            ? _parseFps(_streamProp(videoStream, 'avg_frame_rate'))
            : _parseFps(_streamProp(videoStream, 'r_frame_rate'));

    var width = int.tryParse(videoStream.getWidth()?.toString() ?? '0') ?? 0;
    var height = int.tryParse(videoStream.getHeight()?.toString() ?? '0') ?? 0;

    final durationSecs = double.tryParse(info.getDuration() ?? '0') ?? 0.0;
    final duration = Duration(milliseconds: (durationSecs * 1000).round());

    // Fallback cuando FFprobe devuelve 0x0 (caso observado en algunos outputs).
    if (width <= 0 || height <= 0 || duration.inMilliseconds == 0) {
      final basic = await metadataDatasource.getVideoMetadata(videoPath);
      if (width <= 0) width = basic.width;
      if (height <= 0) height = basic.height;

      return VideoFile(
        path: videoPath,
        name: path.basename(videoPath),
        size: await file.length(),
        duration: duration.inMilliseconds > 0 ? duration : basic.duration,
        width: width,
        height: height,
        bitrate: bitrate,
        fps: fps,
        createdAt: createdAt,
        thumbnailPath: null,
      );
    }

    return VideoFile(
      path: videoPath,
      name: path.basename(videoPath),
      size: await file.length(),
      duration: duration,
      width: width,
      height: height,
      bitrate: bitrate,
      fps: fps,
      createdAt: createdAt,
      thumbnailPath: null,
    );
  }

  // ── Thumbnail ────────────────────────────────────────────────────────────

  /// Extrae el frame del segundo 1 del video como imagen JPEG.
  /// Devuelve la ruta absoluta del thumbnail generado.
  /// Lanza [Exception] si FFmpeg no puede generar la imagen.
  Future<String> generateThumbnail(String videoPath) async {
    final cacheDir = await getTemporaryDirectory();
    final videoName = path.basenameWithoutExtension(videoPath);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final thumbnailPath =
        path.join(cacheDir.path, 'thumb_${videoName}_$timestamp.jpg');

    // Extraer el frame del segundo 1 (o el primero disponible si el video
    // es más corto). -vframes 1 asegura que solo se genera una imagen.
    final args = [
      '-y',
      '-i', videoPath,
      '-ss', '00:00:01',
      '-vframes', '1',
      '-q:v', '2', // calidad JPEG alta (1=mejor, 31=peor)
      thumbnailPath,
    ];

    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      // Intentar con el frame 0 si el video es muy corto
      final fallbackArgs = [
        '-y',
        '-i', videoPath,
        '-vframes', '1',
        '-q:v', '2',
        thumbnailPath,
      ];
      final fallbackSession =
          await FFmpegKit.executeWithArguments(fallbackArgs);
      final fallbackCode = await fallbackSession.getReturnCode();

      if (!ReturnCode.isSuccess(fallbackCode)) {
        throw Exception('No se pudo generar el thumbnail para: $videoPath');
      }
    }

    final thumbFile = File(thumbnailPath);
    if (!await thumbFile.exists()) {
      throw Exception('FFmpeg no generó el archivo de thumbnail.');
    }

    return thumbnailPath;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _buildOutputPath(String inputPath) {
    final dir = path.dirname(inputPath);
    final originalName = path.basename(inputPath);
    return path.join(dir, 'compressed_$originalName');
  }

  double _parseFps(String? rawFps) {
    if (rawFps == null || rawFps.isEmpty) return 0;
    if (rawFps.contains('/')) {
      final parts = rawFps.split('/');
      final num = double.tryParse(parts[0]) ?? 0;
      final den = double.tryParse(parts[1]) ?? 1;
      return den != 0 ? num / den : 0;
    }
    return double.tryParse(rawFps) ?? 0;
  }

  dynamic _selectBestVideoStream(List<dynamic> streams) {
    if (streams.isEmpty) return null;

    // 1) Tipo de stream de video explícito (case-insensitive).
    for (final stream in streams) {
      final type = (stream.getType() ?? '').toString().toLowerCase();
      if (type == 'video') return stream;
    }

    // 2) Fallback por dimensiones válidas.
    for (final stream in streams) {
      final w = int.tryParse(stream.getWidth()?.toString() ?? '0') ?? 0;
      final h = int.tryParse(stream.getHeight()?.toString() ?? '0') ?? 0;
      if (w > 0 && h > 0) return stream;
    }

    return streams.first;
  }

  String? _streamProp(dynamic stream, String key) {
    try {
      final props = stream.getAllProperties();
      final value = props[key];
      return value?.toString();
    } catch (_) {
      return null;
    }
  }
}
