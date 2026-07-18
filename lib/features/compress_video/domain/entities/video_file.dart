class VideoFile {
  final String path;
  final String name;
  final int size;
  final Duration duration;

  //Resolution
  final int width;
  final int height;

  final int bitrate;
  final DateTime? createdAt;
  final String? thumbnailPath;

  const VideoFile({
    required this.path,
    required this.name,
    required this.size,
    required this.duration,
    required this.width,
    required this.height,
    required this.bitrate,
    required this.createdAt,
    required this.thumbnailPath,
  });

  double get sizeMB => size / (1024 * 1024);
  String get resolution => '$width x $height';
  String get extension => name.split('.').last.toUpperCase();

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get shortName {
    if (name.length <= 20) {
      return name;
    }

    final dot = name.lastIndexOf('.');

    if (dot == -1) {
      return '${name.substring(0, 27)}...';
    }

    final extension = name.substring(dot);

    final visible = 26 - extension.length;

    return '${name.substring(0, visible)}...$extension';
  }
}
