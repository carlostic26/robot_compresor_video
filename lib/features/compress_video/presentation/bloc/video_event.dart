part of 'video_bloc.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

class PickVideoRequested extends VideoEvent {
  const PickVideoRequested();
}

class CompressVideoRequested extends VideoEvent {
  final CompressionConfig config;

  const CompressVideoRequested({required this.config});

  @override
  List<Object?> get props => [config];
}

class SaveVideoRequested extends VideoEvent {
  const SaveVideoRequested();
}
