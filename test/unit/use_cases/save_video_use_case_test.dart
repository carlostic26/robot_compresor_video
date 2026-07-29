import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/save_video_use_case.dart';

class MockVideoRepository extends Mock implements VideoRepository {}

const _testVideo = VideoFile(
  path: '/tmp/compressed_video.mp4',
  name: 'compressed_video.mp4',
  size: 1024 * 1024,
  duration: Duration(seconds: 10),
  width: 1920,
  height: 1080,
  bitrate: 4000000,
  createdAt: null,
  thumbnailPath: null,
);

void main() {
  late MockVideoRepository mockRepository;
  late SaveVideoUseCase useCase;

  setUp(() {
    mockRepository = MockVideoRepository();
    useCase = SaveVideoUseCase(mockRepository);
  });

  group('SaveVideoUseCase', () {
    test('llama a repository.saveVideo con el video correcto', () async {
      when(() => mockRepository.saveVideo(_testVideo))
          .thenAnswer((_) async {});

      await useCase(_testVideo);

      verify(() => mockRepository.saveVideo(_testVideo)).called(1);
    });

    test('propaga la excepción cuando el repositorio falla', () async {
      when(() => mockRepository.saveVideo(_testVideo))
          .thenThrow(Exception('Permiso denegado'));

      expect(() => useCase(_testVideo), throwsException);
    });
  });
}
