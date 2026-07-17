import 'package:robot_compresor_video/features/compress_video/data/datasources/video_picker_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoPickerDatasource datasource;

  VideoRepositoryImpl(this.datasource);

  @override
  Future<VideoFile?> pickVideo() async {
    final file = await datasource.pickVideo();

    if (file == null) return null;

    return VideoFile(path: file.path!, name: file.name, size: file.size);
  }
}
