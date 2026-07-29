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

/// Inicia la compresión avanzada con FFmpeg usando [config].
class CompressVideoAdvancedRequested extends VideoEvent {
  final AdvancedCompressionConfig config;

  const CompressVideoAdvancedRequested({required this.config});

  @override
  List<Object?> get props => [config];
}

/// Solicita la metadata extendida (bitrate real, fps) del video actual via FFprobe.
class LoadExtendedMetadataRequested extends VideoEvent {
  const LoadExtendedMetadataRequested();
}

/// Genera la miniatura del video en [videoPath].
class GenerateThumbnailRequested extends VideoEvent {
  final String videoPath;
  const GenerateThumbnailRequested(this.videoPath);

  @override
  List<Object?> get props => [videoPath];
}

/// Reinicia el estado para permitir seleccionar un nuevo video.
class ResetVideoRequested extends VideoEvent {
  const ResetVideoRequested();
}
