import 'package:gal/gal.dart';

class VideoStorageDatasource {
  Future<void> saveVideo(String videoPath) async {
    final hasAccess = await Gal.hasAccess();

    if (!hasAccess) {
      final granted = await Gal.requestAccess();

      if (!granted) {
        throw Exception('Permiso denegado para guardar el video.');
      }
    }

    await Gal.putVideo(videoPath);
  }
}
