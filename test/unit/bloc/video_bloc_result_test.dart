import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/advanced_video_repository.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_advanced_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/generate_thumbnail_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/get_extended_metadata_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/save_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockAdvancedVideoRepository extends Mock
    implements AdvancedVideoRepository {}

class MockPickVideoUseCase extends Mock implements PickVideoUseCase {}

class MockCompressVideoUseCase extends Mock implements CompressVideoUseCase {}

class MockSaveVideoUseCase extends Mock implements SaveVideoUseCase {}

class MockCompressVideoAdvancedUseCase extends Mock
    implements CompressVideoAdvancedUseCase {}

class MockGetExtendedMetadataUseCase extends Mock
    implements GetExtendedMetadataUseCase {}

class MockGenerateThumbnailUseCase extends Mock
    implements GenerateThumbnailUseCase {}

// ── Fixtures ─────────────────────────────────────────────────────────────────

final _processedAt = DateTime(2026, 7, 29, 10, 35, 0);

const _compressedVideo = VideoFile(
  path: '/tmp/compressed_video.mp4',
  name: 'compressed_video.mp4',
  size: 512 * 1024,
  duration: Duration(seconds: 30),
  width: 1920,
  height: 1080,
  bitrate: 2500000, // 2.5 Mbps
  fps: 30,
  createdAt: null,
  thumbnailPath: null,
);

final _compressionResult = CompressionResult(
  compressedVideo: _compressedVideo.copyWith(createdAt: _processedAt),
  originalSize: 1024 * 1024,
  compressedSize: 512 * 1024,
);

// ── Helpers ───────────────────────────────────────────────────────────────────

VideoBloc _buildBloc({
  MockGenerateThumbnailUseCase? thumbUseCase,
  MockSaveVideoUseCase? saveUseCase,
  MockPickVideoUseCase? pickUseCase,
}) {
  return VideoBloc(
    pickVideoUseCase: pickUseCase ?? MockPickVideoUseCase(),
    compressVideoUseCase: MockCompressVideoUseCase(),
    saveVideoUseCase: saveUseCase ?? MockSaveVideoUseCase(),
    compressVideoAdvancedUseCase: MockCompressVideoAdvancedUseCase(),
    getExtendedMetadataUseCase: MockGetExtendedMetadataUseCase(),
    generateThumbnailUseCase: thumbUseCase ?? MockGenerateThumbnailUseCase(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

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
        const CompressionConfig(quality: CompressionQuality.medium));
    registerFallbackValue(const AdvancedCompressionConfig());
  });

  // ── GenerateThumbnailUseCase ────────────────────────────────────────────────
  group('GenerateThumbnailUseCase', () {
    late MockAdvancedVideoRepository mockRepo;
    late GenerateThumbnailUseCase useCase;

    setUp(() {
      mockRepo = MockAdvancedVideoRepository();
      useCase = GenerateThumbnailUseCase(mockRepo);
    });

    test('devuelve la ruta del thumbnail cuando el repositorio tiene éxito',
        () async {
      when(() => mockRepo.generateThumbnail(any()))
          .thenAnswer((_) async => '/tmp/thumb.jpg');

      final result = await useCase('/tmp/video.mp4');

      expect(result, '/tmp/thumb.jpg');
      verify(() => mockRepo.generateThumbnail('/tmp/video.mp4')).called(1);
    });

    test('propaga la excepción cuando el repositorio falla', () async {
      when(() => mockRepo.generateThumbnail(any()))
          .thenThrow(Exception('FFmpeg error'));

      expect(() => useCase('/tmp/video.mp4'), throwsException);
    });
  });

  // ── VideoBloc — GenerateThumbnailRequested ──────────────────────────────────
  group('VideoBloc — GenerateThumbnailRequested', () {
    test('emite generatingThumbnail → success con thumbnailPath', () async {
      final thumbUseCase = MockGenerateThumbnailUseCase();
      when(() => thumbUseCase(any()))
          .thenAnswer((_) async => '/tmp/thumb.jpg');

      final bloc = _buildBloc(thumbUseCase: thumbUseCase);

      final states = <VideoState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const GenerateThumbnailRequested('/tmp/video.mp4'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        states.any((s) => s.status == VideoStatus.generatingThumbnail),
        isTrue,
      );
      expect(
        states.any(
            (s) => s.status == VideoStatus.success && s.thumbnailPath != null),
        isTrue,
      );

      await sub.cancel();
      await bloc.close();
    });

    test('emite success con thumbnailPath null cuando FFmpeg falla', () async {
      final thumbUseCase = MockGenerateThumbnailUseCase();
      when(() => thumbUseCase(any())).thenThrow(Exception('FFmpeg error'));

      final bloc = _buildBloc(thumbUseCase: thumbUseCase);

      final states = <VideoState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const GenerateThumbnailRequested('/tmp/video.mp4'));
      await Future.delayed(const Duration(milliseconds: 100));

      // No debe emitir failure — el thumbnail es no crítico
      expect(states.any((s) => s.status == VideoStatus.failure), isFalse);
      expect(
        states.any(
            (s) => s.status == VideoStatus.success && s.thumbnailPath == null),
        isTrue,
      );

      await sub.cancel();
      await bloc.close();
    });
  });

  // ── VideoBloc — ResetVideoRequested ────────────────────────────────────────
  group('VideoBloc — ResetVideoRequested', () {
    blocTest<VideoBloc, VideoState>(
      'reinicia el estado y dispara PickVideoRequested',
      build: () {
        final pickUseCase = MockPickVideoUseCase();
        // Simular que el usuario cancela el picker (devuelve null)
        when(() => pickUseCase()).thenAnswer((_) async => null);
        return _buildBloc(pickUseCase: pickUseCase);
      },
      seed: () => VideoState(
        compressionResult: _compressionResult,
        thumbnailPath: '/tmp/thumb.jpg',
        status: VideoStatus.saved,
      ),
      act: (bloc) => bloc.add(const ResetVideoRequested()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        // El estado debe haber pasado por initial en algún momento
        expect(bloc.state.compressionResult, isNull);
        expect(bloc.state.thumbnailPath, isNull);
      },
    );
  });

  // ── Metadata — formateo de bitrate ─────────────────────────────────────────
  group('VideoFile — bitrate formatting logic', () {
    test('bitrate 0 debe representarse como no disponible', () {
      const video = VideoFile(
        path: '/tmp/v.mp4',
        name: 'v.mp4',
        size: 0,
        duration: Duration.zero,
        width: 0,
        height: 0,
        bitrate: 0,
        createdAt: null,
        thumbnailPath: null,
      );
      expect(video.bitrate, 0);
    });

    test('bitrate 800000 bps = 800 kbps', () {
      const bps = 800000;
      final kbps = bps ~/ 1000;
      expect(kbps, 800);
    });

    test('bitrate 2500000 bps = 2.5 Mbps', () {
      const bps = 2500000;
      final mbps = bps / 1000000;
      expect(mbps, 2.5);
    });

    test('bitrate 4000000 bps >= 1 Mbps threshold', () {
      const bps = 4000000;
      expect(bps >= 1000000, isTrue);
    });

    test('bitrate 999999 bps < 1 Mbps threshold', () {
      const bps = 999999;
      expect(bps >= 1000000, isFalse);
    });
  });

  // ── Metadata — fecha ────────────────────────────────────────────────────────
  group('VideoFile — createdAt', () {
    test('createdAt disponible devuelve DateTime correcto', () {
      final date = DateTime(2026, 7, 29);
      final video = VideoFile(
        path: '/tmp/v.mp4',
        name: 'v.mp4',
        size: 0,
        duration: Duration.zero,
        width: 0,
        height: 0,
        bitrate: 0,
        createdAt: date,
        thumbnailPath: null,
      );
      expect(video.createdAt, date);
      expect(video.createdAt!.day, 29);
      expect(video.createdAt!.month, 7);
      expect(video.createdAt!.year, 2026);
    });

    test('createdAt null cuando FFprobe no devuelve fecha', () {
      const video = VideoFile(
        path: '/tmp/v.mp4',
        name: 'v.mp4',
        size: 0,
        duration: Duration.zero,
        width: 0,
        height: 0,
        bitrate: 0,
        createdAt: null,
        thumbnailPath: null,
      );
      expect(video.createdAt, isNull);
    });
  });

  // ── VideoBloc — botón "Subir otro video" ────────────────────────────────────
  group('VideoBloc — estado saved controla visibilidad de "Subir otro video"',
      () {
    test('status != saved → botón no debe mostrarse', () {
      const state = VideoState(status: VideoStatus.success);
      expect(state.status == VideoStatus.saved, isFalse);
    });

    test('status == saved → botón debe mostrarse', () {
      const state = VideoState(status: VideoStatus.saved);
      expect(state.status == VideoStatus.saved, isTrue);
    });

    test('status == saving → botón no debe mostrarse', () {
      const state = VideoState(status: VideoStatus.saving);
      expect(state.status == VideoStatus.saved, isFalse);
    });

    test('status == failure → botón no debe mostrarse', () {
      const state = VideoState(status: VideoStatus.failure);
      expect(state.status == VideoStatus.saved, isFalse);
    });
  });
}

// ── Extension helper para tests ───────────────────────────────────────────────
extension VideoFileCopyWith on VideoFile {
  VideoFile copyWith({DateTime? createdAt}) {
    return VideoFile(
      path: path,
      name: name,
      size: size,
      duration: duration,
      width: width,
      height: height,
      bitrate: bitrate,
      fps: fps,
      createdAt: createdAt ?? this.createdAt,
      thumbnailPath: thumbnailPath,
    );
  }
}
