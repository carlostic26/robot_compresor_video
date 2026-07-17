import 'package:file_picker/file_picker.dart';

class VideoPickerDatasource {
  Future<PlatformFile?> pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null) return null;

    return result.files.first;
  }
}
