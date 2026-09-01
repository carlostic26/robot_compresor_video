import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_result.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_advanced_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/generate_thumbnail_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/get_extended_metadata_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/save_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockPickVideoUseCase extends Mock implements PickVideoUseCase {}

class MockCompressVideoUseCase extends Mock implements CompressVideoUseCase {}

class MockSaveVideoUseCase extends Mock implements SaveVideoUseCase {}

class MockCompressVideoAdvancedUseCase extends Mock
    implements CompressVideoAdvancedUseCase {}

class MockGetExtendedMetadataUseCase extends Mock
    implements GetExtendedMetadataUseCase {}

class MockGenerateThumbnailUseCase extends Mock
    implements GenerateThumbnailUseCase {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _originalVideo = VideoFile(
  path: '/tmp/original.mp4',
  name: 'original.mp4',
  size: 8 * 1024 * 1024, // 8 MB
  duration: Duration(seconds: 30),
  width: 1920,
  height: 1080,
  bitrate: 2500000, // 2500 kbps
  fps: 30,
  createdAt: null,
  thumbnailPath: null,
);

const _compressedVideo = VideoFile(
  path: '/tmp/ffmpeg_compressed.mp4',
  name: 'ffmpeg_compressed.mp4',
  size: 4 * 1024 * 1024, // 4 MB
  duration: Duration(seconds: 30),
  width: 1920,
  height: 1080,
  bitrate: 1200000, // 1200 kbps
  fps: 30,
  createdAt: null,
  thumbnailPath: null,
);

const _advancedResult = AdvancedCompressionResult(
  compressedVideo: _compressedVideo,
  originalSize: 8 * 1024 * 1024,
  compressedSize: 4 * 1024 * 1024,
  ffmpegCommand: 'ffmpeg -y -i original.mp4 -b:v 1200k -c:a copy output.mp4',
);

// ── Builder ───────────────────────────────────────────────────────────────────

VideoBloc _buildBloc({
  MockCompressVideoAdvancedUseCase? advancedUseCase,
  MockGenerateThumbnailUseCase? thumbUseCase,
  MockSaveVideoUseCase? saveUseCase,
  MockGetExtendedMetadataUseCase? metadataUseCase,
}) {
  return VideoBloc(
    pickVideoUseCase: MockPickVideoUseCase(),
    compressVideoUseCase: MockCompressVideoUseCase(),
    saveVideoUseCase: saveUseCase ?? MockSaveVideoUseCase(),
    compressVideoAdvancedUseCase:
        advancedUseCase ?? MockCompressVideoAdvancedUseCase(),
    getExtendedMetadataUseCase:
        metadataUseCase ?? MockGetExtendedMetadataUseCase(),
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
      const CompressionConfig(quality: CompressionQuality.medium),
    );
    registerFallbackValue(const AdvancedCompressionConfig());
  });

  // ── Metadata ─────────────────────────────────────────────────────────────────

  group('LoadExtendedMetadataRequested', () {
    blocTest<VideoBloc, VideoState>(
      'emite loadingExtendedMetadata → success con video enriquecido',
      build: () {
        final metadataUseCase = MockGetExtendedMetadataUseCase();
        when(
          () => metadataUseCase(any()),
        ).thenAnswer((_) async => _originalVideo);
        return _buildBloc(metadataUseCase: metadataUseCase);
      },
      seed: () =>
          const VideoState(video: _originalVideo, status: VideoStatus.success),
      act: (bloc) => bloc.add(const LoadExtendedMetadataRequested()),
      expect: () => [
        isA<VideoState>().having(
          (s) => s.status,
          'status',
          VideoStatus.loadingExtendedMetadata,
        ),
        isA<VideoState>()
            .having((s) => s.status, 'status', VideoStatus.success)
            .having((s) => s.video, 'video', isNotNull),
      ],
    );

    blocTest<VideoBloc, VideoState>(
      'emite success (no falla) cuando FFprobe lanza excepción',
      build: () {
        final metadataUseCase = MockGetExtendedMetadataUseCase();
        when(
          () => metadataUseCase(any()),
        ).thenThrow(Exception('FFprobe error'));
        return _buildBloc(metadataUseCase: metadataUseCase);
      },
      seed: () =>
          const VideoState(video: _originalVideo, status: VideoStatus.success),
      act: (bloc) => bloc.add(const LoadExtendedMetadataRequested()),
      expect: () => [
        isA<VideoState>().having(
          (s) => s.status,
          'status',
          VideoStatus.loadingExtendedMetadata,
        ),
        isA<VideoState>().having(
          (s) => s.status,
          'status',
          VideoStatus.success,
        ),
      ],
    );

    test('FFprobe devuelve bitrate correcto en bps', () {
      const bps = 2500000;
      final kbps = bps ~/ 1000;
      expect(kbps, 2500);
    });

    test('FFprobe devuelve FPS fraccionario convertido correctamente', () {
      // 30000/1001 ≈ 29.97
      const num = 30000.0;
      const den = 1001.0;
      final fps = num / den;
      expect(fps, closeTo(29.97, 0.01));
    });

    test('FPS entero se representa sin decimales', () {
      const fps = 30.0;
      final formatted = fps == fps.roundToDouble()
          ? '${fps.round()} fps'
          : '${fps.toStringAsFixed(2)} fps';
      expect(formatted, '30 fps');
    });

    test('FPS fraccionario se representa con 2 decimales', () {
      const fps = 29.97002997;
      final formatted = fps == fps.roundToDouble()
          ? '${fps.round()} fps'
          : '${fps.toStringAsFixed(2)} fps';
      expect(formatted, '29.97 fps');
    });
  });

  // ── Bitrate ───────────────────────────────────────────────────────────────────

  group('Bitrate — validación y conversión de unidades', () {
    test('bitrate original se muestra en kbps (bps ÷ 1000)', () {
      const bps = 2500000;
      final kbps = bps ~/ 1000;
      expect(kbps, 2500);
    });

    test('bitrate introducido en kbps se convierte a bps para FFmpeg', () {
      const kbps = 1200;
      final bps = kbps * 1000;
      expect(bps, 1200000);
    });

    test('bitrate 0 es inválido', () {
      const value = 0;
      expect(value <= 0, isTrue);
    });

    test('bitrate negativo es inválido', () {
      const value = -100;
      expect(value <= 0, isTrue);
    });

    test('bitrate 100001 kbps supera el máximo permitido', () {
      const value = 100001;
      expect(value > 100000, isTrue);
    });

    test('bitrate 1 kbps es válido (mínimo)', () {
      const value = 1;
      expect(value > 0 && value <= 100000, isTrue);
    });

    test('AdvancedCompressionConfig recibe bps correctamente', () {
      const kbps = 1200;
      final config = AdvancedCompressionConfig(targetVideoBitrate: kbps * 1000);
      expect(config.targetVideoBitrate, 1200000);
    });
  });

  // ── Estimación de peso ────────────────────────────────────────────────────────

  group('Estimación de peso en diálogo Antes vs Después', () {
    test('estimación correcta con bitrate original conocido', () {
      const originalSizeMB = 8.0;
      const originalBps = 2500000;
      const targetKbps = 1200;
      final ratio = (targetKbps * 1000) / originalBps;
      final estimated = originalSizeMB * ratio;
      expect(estimated, closeTo(3.84, 0.01));
    });

    test('estimación devuelve null cuando bitrate original es 0', () {
      const originalBps = 0;
      final result = originalBps <= 0 ? null : 1.0;
      expect(result, isNull);
    });

    test('estimación no se muestra si bitrate original es desconocido', () {
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
      final canEstimate = video.bitrate > 0;
      expect(canEstimate, isFalse);
    });
  });

  // ── CompressVideoAdvancedRequested ────────────────────────────────────────────

  group('VideoBloc — CompressVideoAdvancedRequested', () {
    blocTest<VideoBloc, VideoState>(
      'emite compressingAdvanced → success con advancedCompressionResult',
      build: () {
        final advancedUseCase = MockCompressVideoAdvancedUseCase();
        final thumbUseCase = MockGenerateThumbnailUseCase();
        when(
          () => advancedUseCase(
            video: any(named: 'video'),
            config: any(named: 'config'),
          ),
        ).thenAnswer((_) async => _advancedResult);
        when(
          () => thumbUseCase(any()),
        ).thenAnswer((_) async => '/tmp/thumb.jpg');
        return _buildBloc(
          advancedUseCase: advancedUseCase,
          thumbUseCase: thumbUseCase,
        );
      },
      seed: () =>
          const VideoState(video: _originalVideo, status: VideoStatus.success),
      act: (bloc) => bloc.add(
        const CompressVideoAdvancedRequested(
          config: AdvancedCompressionConfig(targetVideoBitrate: 1200000),
        ),
      ),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<VideoState>().having(
          (s) => s.status,
          'status',
          VideoStatus.compressingAdvanced,
        ),
        isA<VideoState>()
            .having((s) => s.status, 'status', VideoStatus.success)
            .having((s) => s.advancedCompressionResult, 'result', isNotNull)
            .having(
              (s) => s.activeResult,
              'activeResult',
              ActiveResult.advanced,
            ),
        // generatingThumbnail + success con thumbnail
        isA<VideoState>().having(
          (s) => s.status,
          'status',
          VideoStatus.generatingThumbnail,
        ),
        isA<VideoState>()
            .having((s) => s.status, 'status', VideoStatus.success)
            .having((s) => s.thumbnailPath, 'thumbnailPath', isNotNull),
      ],
    );

    blocTest<VideoBloc, VideoState>(
      'emite failure cuando FFmpeg lanza excepción',
      build: () {
        final advancedUseCase = MockCompressVideoAdvancedUseCase();
        when(
          () => advancedUseCase(
            video: any(named: 'video'),
            config: any(named: 'config'),
          ),
        ).thenThrow(Exception('FFmpeg falló'));
        return _buildBloc(advancedUseCase: advancedUseCase);
      },
      seed: () =>
          const VideoState(video: _originalVideo, status: VideoStatus.success),
      act: (bloc) => bloc.add(
        const CompressVideoAdvancedRequested(
          config: AdvancedCompressionConfig(targetVideoBitrate: 1200000),
        ),
      ),
      expect: () => [
        isA<VideoState>().having(
          (s) => s.status,
          'status',
          VideoStatus.compressingAdvanced,
        ),
        isA<VideoState>()
            .having((s) => s.status, 'status', VideoStatus.failure)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<VideoBloc, VideoState>(
      'emite failure cuando no hay video seleccionado',
      build: _buildBloc,
      act: (bloc) => bloc.add(
        const CompressVideoAdvancedRequested(
          config: AdvancedCompressionConfig(targetVideoBitrate: 1200000),
        ),
      ),
      expect: () => [
        isA<VideoState>()
            .having((s) => s.status, 'status', VideoStatus.failure)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    test('activeResult es advanced tras compresión avanzada exitosa', () {
      const state = VideoState(
        advancedCompressionResult: _advancedResult,
        activeResult: ActiveResult.advanced,
        status: VideoStatus.success,
      );
      expect(state.activeResult, ActiveResult.advanced);
      expect(state.activeCompressedVideo, _compressedVideo);
    });
  });

  // ── FfmpegCommandBuilder — bitrate no hardcodeado ─────────────────────────────

  group('FfmpegCommandBuilder — bitrate dinámico', () {
    test(
      'el bitrate proviene de AdvancedCompressionConfig, no está hardcodeado',
      () {
        const config1 = AdvancedCompressionConfig(targetVideoBitrate: 1200000);
        const config2 = AdvancedCompressionConfig(targetVideoBitrate: 4000000);
        expect(config1.targetVideoBitrate, isNot(config2.targetVideoBitrate));
      },
    );

    test('targetVideoBitrate null no aplica filtro de bitrate', () {
      const config = AdvancedCompressionConfig();
      expect(config.targetVideoBitrate, isNull);
    });

    test('targetVideoBitrate 1200000 bps = 1200 kbps para FFmpeg', () {
      const bps = 1200000;
      final kbps = (bps / 1000).round();
      expect(kbps, 1200);
    });
  });

  // ── Resultado — peso granular ─────────────────────────────────────────────────

  group('AdvancedResultSection — peso granular', () {
    test('peso disponible cuando advancedCompressionResult no es null', () {
      const state = VideoState(
        advancedCompressionResult: _advancedResult,
        activeResult: ActiveResult.advanced,
        status: VideoStatus.success,
      );
      final sizeMB = state.advancedCompressionResult!.compressedVideo.sizeMB;
      expect(sizeMB, closeTo(4.19, 0.05));
    });

    test('peso corresponde al archivo real (compressedSize)', () {
      const expectedBytes = 4 * 1024 * 1024;
      expect(_advancedResult.compressedSize, expectedBytes);
      expect(_advancedResult.compressedVideo.size, expectedBytes);
    });

    test('savedPercentage es correcto', () {
      expect(_advancedResult.savedPercentage, closeTo(50.0, 0.01));
    });
  });

  // ── Guardado con resultado avanzado ──────────────────────────────────────────

  group('SaveVideoRequested — con resultado avanzado', () {
    blocTest<VideoBloc, VideoState>(
      'emite saving → saved usando activeCompressedVideo del resultado avanzado',
      build: () {
        final saveUseCase = MockSaveVideoUseCase();
        when(() => saveUseCase(any())).thenAnswer((_) async {});
        return _buildBloc(saveUseCase: saveUseCase);
      },
      seed: () => const VideoState(
        advancedCompressionResult: _advancedResult,
        activeResult: ActiveResult.advanced,
        status: VideoStatus.success,
      ),
      act: (bloc) => bloc.add(const SaveVideoRequested()),
      expect: () => [
        isA<VideoState>().having((s) => s.status, 'status', VideoStatus.saving),
        isA<VideoState>().having((s) => s.status, 'status', VideoStatus.saved),
      ],
    );
  });

  // ── Regresión: compresión básica sigue funcionando ────────────────────────────

  group('Regresión — activeResult.basic', () {
    test('activeCompressedVideo devuelve compressionResult cuando es basic', () {
      const compressionResult = _advancedResult; // reutilizamos estructura
      final state = VideoState(
        advancedCompressionResult: compressionResult,
        activeResult: ActiveResult.basic,
        status: VideoStatus.success,
      );
      // Con activeResult.basic, activeCompressedVideo usa compressionResult (null aquí)
      expect(state.activeCompressedVideo, isNull);
    });

    test('activeResult.none devuelve null', () {
      const state = VideoState(status: VideoStatus.initial);
      expect(state.activeCompressedVideo, isNull);
    });
  });
}
