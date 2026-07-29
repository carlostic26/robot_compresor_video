import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
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

  /// Comprime [video] con los parámetros de [config] usando FFmpeg.
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

    final compressedVideo = await metadataDatasource.getVideoMetadata(outputPath);

    return AdvancedCompressionResult(
      compressedVideo: compressedVideo,
      originalSize: video.size,
      compressedSize: await outputFile.length(),
      ffmpegCommand: command,
    );
  }

  /// Extrae metadata extendida (bitrate real, fps) usando FFprobe.
  Future<VideoFile> getExtendedMetadata(String videoPath) async {
    final session = await FFprobeKit.getMediaInformation(videoPath);
    final info = session.getMediaInformation();

    if (info == null) {
      // Si FFprobe falla, devolvemos lo que ya tenemos vía video_player
      return metadataDatasource.getVideoMetadata(videoPath);
    }

    final file = File(videoPath);
    final streams = info.getStreams() ?? [];

    // Buscar el stream de video
    final videoStream = streams.firstWhere(
      (s) => s.getType() == 'video',
      orElse: () => streams.first,
    );

    final bitrate = int.tryParse(info.getBitrate() ?? '0') ?? 0;
    final fps = _parseFps(videoStream.getRealFrameRate());
    final width = int.tryParse(videoStream.getWidth()?.toString() ?? '0') ?? 0;
    final height = int.tryParse(videoStream.getHeight()?.toString() ?? '0') ?? 0;
    final durationSecs = double.tryParse(info.getDuration() ?? '0') ?? 0.0;

    return VideoFile(
      path: videoPath,
      name: path.basename(videoPath),
      size: await file.length(),
      duration: Duration(milliseconds: (durationSecs * 1000).round()),
      width: width,
      height: height,
      bitrate: bitrate,
      createdAt: null,
      thumbnailPath: null,
      fps: fps,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _buildOutputPath(String inputPath) {
    final dir = path.dirname(inputPath);
    final originalName = path.basename(inputPath);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return path.join(dir, 'ffmpeg_${timestamp}_$originalName');
  }

  /// Parsea el framerate en formato "num/den" o decimal que devuelve FFprobe.
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
}
