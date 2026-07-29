import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_advanced_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/get_extended_metadata_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/save_video_use_case.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final PickVideoUseCase pickVideoUseCase;
  final CompressVideoUseCase compressVideoUseCase;
  final SaveVideoUseCase saveVideoUseCase;
  final CompressVideoAdvancedUseCase compressVideoAdvancedUseCase;
  final GetExtendedMetadataUseCase getExtendedMetadataUseCase;

  VideoBloc({
    required this.pickVideoUseCase,
    required this.compressVideoUseCase,
    required this.saveVideoUseCase,
    required this.compressVideoAdvancedUseCase,
    required this.getExtendedMetadataUseCase,
  }) : super(const VideoState()) {
    on<PickVideoRequested>(_onPickVideoRequested);
    on<CompressVideoRequested>(_onCompressVideoRequested);
    on<SaveVideoRequested>(_onSaveVideoRequested);
    on<CompressVideoAdvancedRequested>(_onCompressVideoAdvancedRequested);
    on<LoadExtendedMetadataRequested>(_onLoadExtendedMetadataRequested);
  }
  Future<void> _onPickVideoRequested(
    PickVideoRequested event,
    Emitter<VideoState> emit,
  ) async {
    emit(state.copyWith(status: VideoStatus.picking, error: null));

    try {
      final video = await pickVideoUseCase();

      if (video == null) {
        emit(state.copyWith(status: VideoStatus.initial));
        return;
      }

      emit(
        state.copyWith(
          video: video,
          compressionResult: null,
          status: VideoStatus.success,
          error: null,
        ),
      );

      debugPrint('VIDEO SELECCIONADO');
      debugPrint(video.name);
      debugPrint(video.path);
      debugPrint(video.size.toString());
    } catch (e) {
      emit(state.copyWith(status: VideoStatus.failure, error: e.toString()));

      debugPrint(e.toString());
    }
  }

  Future<void> _onCompressVideoRequested(
    CompressVideoRequested event,
    Emitter<VideoState> emit,
  ) async {
    debugPrint("STATUS 1. Entró al evento");
    final video = state.video;

    if (video == null) {
      debugPrint("STATUS 2. Video nulo");
      emit(
        state.copyWith(
          status: VideoStatus.failure,
          error: 'No hay un video seleccionado.',
        ),
      );
      return;
    }

    debugPrint("STATUS 3. Antes del emit compressing");

    emit(state.copyWith(status: VideoStatus.compressing, error: null));

    debugPrint("STATUS 4. Después del emit compressing");

    try {
      debugPrint("STATUS 5. Antes del usecase");

      final result = await compressVideoUseCase(
        video: video,
        config: event.config,
      );

      debugPrint("STATUS 6. Terminó el usecase");

      emit(
        state.copyWith(
          compressionResult: result,
          status: VideoStatus.success,
          error: null,
        ),
      );

      debugPrint("STATUS 7. Emit success");

      debugPrint('COMPRESIÓN FINALIZADA');
    } catch (e) {
      debugPrint("STATUS 8. ERROR $e");

      emit(state.copyWith(status: VideoStatus.failure, error: e.toString()));

      debugPrint(e.toString());
    }
  }

Future<void> _onSaveVideoRequested(
    SaveVideoRequested event,
    Emitter<VideoState> emit,
  ) async {
    // Evitar guardados duplicados
    if (state.status == VideoStatus.saving ||
        state.status == VideoStatus.saved) {
      return;
    }

    final result = state.compressionResult;

    if (result == null) {
      emit(state.copyWith(
        status: VideoStatus.failure,
        error: 'No existe un video comprimido para guardar.',
      ));
      return;
    }

    emit(state.copyWith(status: VideoStatus.saving, error: null));

    try {
      await saveVideoUseCase(result.compressedVideo);
      emit(state.copyWith(status: VideoStatus.saved, error: null));
    } catch (e) {
      debugPrint('ERROR AL GUARDAR: $e');
      emit(state.copyWith(status: VideoStatus.failure, error: e.toString()));
    }
  }

  /// Comprime el video usando FFmpeg con los parámetros avanzados.
  Future<void> _onCompressVideoAdvancedRequested(
    CompressVideoAdvancedRequested event,
    Emitter<VideoState> emit,
  ) async {
    final video = state.video;

    if (video == null) {
      emit(state.copyWith(
        status: VideoStatus.failure,
        error: 'No hay un video seleccionado.',
      ));
      return;
    }

    emit(state.copyWith(
      status: VideoStatus.compressingAdvanced,
      error: null,
    ));

    try {
      final result = await compressVideoAdvancedUseCase(
        video: video,
        config: event.config,
      );

      debugPrint('COMPRESIÓN AVANZADA FINALIZADA: ${result.ffmpegCommand}');

      emit(state.copyWith(
        advancedCompressionResult: result,
        status: VideoStatus.success,
        error: null,
      ));
    } catch (e) {
      debugPrint('ERROR COMPRESIÓN AVANZADA: $e');
      emit(state.copyWith(status: VideoStatus.failure, error: e.toString()));
    }
  }

  /// Carga la metadata extendida del video actual usando FFprobe.
  Future<void> _onLoadExtendedMetadataRequested(
    LoadExtendedMetadataRequested event,
    Emitter<VideoState> emit,
  ) async {
    final video = state.video;

    if (video == null) return;

    emit(state.copyWith(status: VideoStatus.loadingExtendedMetadata));

    try {
      final enrichedVideo = await getExtendedMetadataUseCase(video.path);

      emit(state.copyWith(
        video: enrichedVideo,
        status: VideoStatus.success,
        error: null,
      ));
    } catch (e) {
      // No es un error crítico: la UI puede funcionar con los datos básicos
      debugPrint('No se pudo cargar metadata extendida: $e');
      emit(state.copyWith(status: VideoStatus.success));
    }
  }
}
