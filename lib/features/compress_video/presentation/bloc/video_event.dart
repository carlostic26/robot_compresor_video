part of 'video_bloc.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

class PickVideoRequested extends VideoEvent {
  const PickVideoRequested();
}
