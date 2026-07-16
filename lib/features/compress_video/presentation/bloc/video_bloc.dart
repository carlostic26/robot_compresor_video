import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc() : super(const VideoState()) {
    on<PickVideoRequested>(_onPickVideoRequested);
  }

  Future<void> _onPickVideoRequested(
    PickVideoRequested event,
    Emitter<VideoState> emit,
  ) async {
    emit(state.copyWith(selectedVideoName: 'Viaje a la playa.mp4'));
  }
}
