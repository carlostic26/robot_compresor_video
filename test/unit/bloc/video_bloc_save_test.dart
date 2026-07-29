import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_advanced_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/generate_thumbnail_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/get_extended_metadata_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/save_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';

class MockPickVideoUseCase extends Mock implements PickVideoUseCase {}
class MockCompressVideoUseCase extends Mock implements CompressVideoUseCase {}
class MockSaveVideoUseCase extends Mock implements SaveVideoUseCase {}
class MockCompressVideoAdvancedUseCase extends Mock implements CompressVideoAdvancedUseCase {}
class MockGetExtendedMetadataUseCase extends Mock implements GetExtendedMetadataUseCase {}
class MockGenerateThumbnailUseCase extends Mock implements GenerateThumbnailUseCase {}

const _compressedVideo = VideoFile(
  path: '/tmp/compressed_video.mp4',
  name: 'compressed_video.mp4',
  size: 512 * 1024,
  duration: Duration(seconds: 10),
  width: 1920,
  height: 1080,
  bitrate: 4000000,
  createdAt: null,
  thumbnailPath: null,
);

const _compressionResult = CompressionResult(
  compressedVideo: _compressedVideo,
  originalSize: 1024 * 1024,
  compressedSize: 512 * 1024,
);

VideoBloc _buildBloc({
  MockSaveVideoUseCase? saveUseCase,
}) {
  return VideoBloc(
    pickVideoUseCase: MockPickVideoUseCase(),
    compressVideoUseCase: MockCompressVideoUseCase(),
    saveVideoUseCase: saveUseCase ?? MockSaveVideoUseCase(),
    compressVideoAdvancedUseCase: MockCompressVideoAdvancedUseCase(),
    getExtendedMetadataUseCase: MockGetExtendedMetadataUseCase(),
    generateThumbnailUseCase: MockGenerateThumbnailUseCase(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const VideoFile(
        path: '',
        name: '',
        size: 0,
        duration: Duration.zero,
        width: 0,
        height: 0,
        bitrate: 0,
        createdAt: null,
        thumbnailPath: null,
      ),
    );
    registerFallbackValue(
      const CompressionConfig(quality: CompressionQuality.medium),
    );
    registerFallbackValue(const AdvancedCompressionConfig());
  });

  group('VideoBloc — SaveVideoRequested', () {
    test('estado inicial no tiene compressionResult', () {
      final bloc = _buildBloc();
      expect(bloc.state.compressionResult, isNull);
      bloc.close();
    });

    blocTest<VideoBloc, VideoState>(
      'emite failure cuando no hay compressionResult',
      build: _buildBloc,
      act: (bloc) => bloc.add(const SaveVideoRequested()),
      expect: () => [
        isA<VideoState>()
            .having((s) => s.status, 'status', VideoStatus.failure)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<VideoBloc, VideoState>(
      'emite saving → saved cuando el guardado es exitoso',
      build: () {
        final saveUseCase = MockSaveVideoUseCase();
        when(() => saveUseCase(any())).thenAnswer((_) async {});
        return _buildBloc(saveUseCase: saveUseCase);
      },
      seed: () => const VideoState(
        compressionResult: _compressionResult,
        activeResult: ActiveResult.basic,
        status: VideoStatus.success,
      ),
      act: (bloc) => bloc.add(const SaveVideoRequested()),
      expect: () => [
        isA<VideoState>().having((s) => s.status, 'status', VideoStatus.saving),
        isA<VideoState>().having((s) => s.status, 'status', VideoStatus.saved),
      ],
    );

    blocTest<VideoBloc, VideoState>(
      'emite saving → failure cuando el datasource lanza excepción',
      build: () {
        final saveUseCase = MockSaveVideoUseCase();
        when(() => saveUseCase(any()))
            .thenThrow(Exception('Permiso denegado'));
        return _buildBloc(saveUseCase: saveUseCase);
      },
      seed: () => const VideoState(
        compressionResult: _compressionResult,
        activeResult: ActiveResult.basic,
        status: VideoStatus.success,
      ),
      act: (bloc) => bloc.add(const SaveVideoRequested()),
      expect: () => [
        isA<VideoState>().having((s) => s.status, 'status', VideoStatus.saving),
        isA<VideoState>()
            .having((s) => s.status, 'status', VideoStatus.failure)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<VideoBloc, VideoState>(
      'ignora el evento si ya está en estado saving (evita duplicados)',
      build: () {
        final saveUseCase = MockSaveVideoUseCase();
        when(() => saveUseCase(any())).thenAnswer((_) async {});
        return _buildBloc(saveUseCase: saveUseCase);
      },
      seed: () => const VideoState(
        compressionResult: _compressionResult,
        activeResult: ActiveResult.basic,
        status: VideoStatus.saving,
      ),
      act: (bloc) => bloc.add(const SaveVideoRequested()),
      expect: () => [],
    );

    blocTest<VideoBloc, VideoState>(
      'ignora el evento si ya está en estado saved (evita duplicados)',
      build: () {
        final saveUseCase = MockSaveVideoUseCase();
        when(() => saveUseCase(any())).thenAnswer((_) async {});
        return _buildBloc(saveUseCase: saveUseCase);
      },
      seed: () => const VideoState(
        compressionResult: _compressionResult,
        activeResult: ActiveResult.basic,
        status: VideoStatus.saved,
      ),
      act: (bloc) => bloc.add(const SaveVideoRequested()),
      expect: () => [],
    );
  });
}
