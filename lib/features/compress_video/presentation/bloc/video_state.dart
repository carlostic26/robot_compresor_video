part of 'video_bloc.dart';

enum VideoStatus { initial, picking, compressing, success, failure }

class VideoState extends Equatable {
  static const _unset = Object();

  final VideoFile? video;
  final CompressionResult? compressionResult;
  final VideoStatus status;
  final String? error;

  const VideoState({
    this.video,
    this.compressionResult,
    this.status = VideoStatus.initial,
    this.error,
  });

VideoState copyWith({
    Object? video = _unset,
    Object? compressionResult = _unset,
    VideoStatus? status,
    Object? error = _unset,
  }) {
    return VideoState(
      video: identical(video, _unset) ? this.video : video as VideoFile?,
      compressionResult: identical(compressionResult, _unset)
          ? this.compressionResult
          : compressionResult as CompressionResult?,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

@override
  List<Object?> get props => [video, compressionResult, status, error];
}
