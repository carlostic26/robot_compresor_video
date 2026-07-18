part of 'video_bloc.dart';

class VideoState extends Equatable {
  final VideoFile? video;
  final bool isLoading;

  const VideoState({this.video, this.isLoading = false});

  VideoState copyWith({VideoFile? video, bool? isLoading}) {
    return VideoState(
      video: video ?? this.video,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [video, isLoading];
}
