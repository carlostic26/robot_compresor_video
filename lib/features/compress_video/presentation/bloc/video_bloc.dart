import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final PickVideoUseCase pickVideoUseCase;
  final CompressVideoUseCase compressVideoUseCase;

VideoBloc({
    required this.pickVideoUseCase,
    required this.compressVideoUseCase,
  }) : super(const VideoState()) {
    on<PickVideoRequested>(_onPickVideoRequested);
    on<CompressVideoRequested>(_onCompressVideoRequested);
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
  ) async {}
}
