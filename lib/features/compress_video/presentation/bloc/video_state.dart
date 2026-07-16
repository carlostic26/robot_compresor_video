part of 'video_bloc.dart';

class VideoState extends Equatable {
  final String? selectedVideoName;

  const VideoState({this.selectedVideoName});

  VideoState copyWith({String? selectedVideoName}) {
    return VideoState(
      selectedVideoName: selectedVideoName ?? this.selectedVideoName,
    );
  }

  @override
  List<Object?> get props => [selectedVideoName];
}
