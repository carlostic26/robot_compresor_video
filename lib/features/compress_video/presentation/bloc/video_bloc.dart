import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final PickVideoUseCase pickVideoUseCase;

  VideoBloc({required this.pickVideoUseCase}) : super(const VideoState()) {
    on<PickVideoRequested>(_onPickVideoRequested);
  }

  Future<void> _onPickVideoRequested(
    PickVideoRequested event,
    Emitter<VideoState> emit,
  ) async {
    final video = await pickVideoUseCase();

    if (video == null) {
      return;
    }

    emit(state.copyWith(video: video));

    debugPrint("VIDEO SELECCIONADO");
    debugPrint(video.name);
    debugPrint(video.path);
    debugPrint(video.size.toString());
  }
}
