import 'package:get_it/get_it.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/ffmpeg_command_builder.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/ffmpeg_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_compressor_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_metadata_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_storage_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/repositories/advanced_video_repository_impl.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/advanced_video_repository.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_advanced_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/generate_thumbnail_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/get_extended_metadata_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/save_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';

import '../../features/compress_video/data/datasources/video_picker_datasource.dart';
import '../../features/compress_video/data/repositories/video_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  /// Datasources
  getIt.registerLazySingleton<VideoPickerDatasource>(
    () => VideoPickerDatasource(),
  );

  getIt.registerLazySingleton<VideoMetadataDatasource>(
    () => VideoMetadataDatasource(),
  );

  getIt.registerLazySingleton<FfmpegCommandBuilder>(
    () => FfmpegCommandBuilder(),
  );

  getIt.registerLazySingleton<FfmpegDatasource>(
    () => FfmpegDatasource(
      commandBuilder: getIt(),
      metadataDatasource: getIt(),
    ),
  );

  // VideoCompressorDatasource ahora recibe FfmpegDatasource para metadata extendida
  getIt.registerLazySingleton<VideoCompressorDatasource>(
    () => VideoCompressorDatasource(getIt(), getIt()),
  );

  getIt.registerLazySingleton<VideoStorageDatasource>(
    () => VideoStorageDatasource(),
  );

  /// Repositories
  getIt.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );

  getIt.registerLazySingleton<AdvancedVideoRepository>(
    () => AdvancedVideoRepositoryImpl(getIt()),
  );

  /// UseCases
  getIt.registerLazySingleton(() => PickVideoUseCase(getIt()));
  getIt.registerLazySingleton(() => CompressVideoUseCase(getIt()));
  getIt.registerLazySingleton(() => SaveVideoUseCase(getIt()));
  getIt.registerLazySingleton(() => CompressVideoAdvancedUseCase(getIt()));
  getIt.registerLazySingleton(() => GetExtendedMetadataUseCase(getIt()));
  getIt.registerLazySingleton(() => GenerateThumbnailUseCase(getIt()));

  /// Bloc
  getIt.registerFactory(
    () => VideoBloc(
      pickVideoUseCase: getIt(),
      compressVideoUseCase: getIt(),
      saveVideoUseCase: getIt(),
      compressVideoAdvancedUseCase: getIt(),
      getExtendedMetadataUseCase: getIt(),
      generateThumbnailUseCase: getIt(),
    ),
  );
}
