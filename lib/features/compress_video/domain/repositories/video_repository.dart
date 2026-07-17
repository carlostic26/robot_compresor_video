import '../entities/video_file.dart';

abstract class VideoRepository {
  Future<VideoFile?> pickVideo();
}
