part of 'video_bloc.dart';

class VideoState extends Equatable {
  final VideoFile? video;

  const VideoState({
    this.video,
  });

  VideoState copyWith({
    VideoFile? video,
  }) {
    return VideoState(
      video: video ?? this.video,
    );
  }

  @override
  List<Object?> get props => [
        video,
      ];
}