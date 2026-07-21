import 'package:get_it/get_it.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_compressor_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/data/datasources/video_metadata_datasource.dart';
import 'package:robot_compresor_video/features/compress_video/domain/repositories/video_repository.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/compress_video_use_case.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';
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

  getIt.registerLazySingleton<VideoCompressorDatasource>(
    () => VideoCompressorDatasource(getIt( )),
  );

  /// Repository
  getIt.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(getIt(), getIt(), getIt()),
  );

  /// UseCases
  getIt.registerLazySingleton(() => PickVideoUseCase(getIt()));

  getIt.registerLazySingleton(() => CompressVideoUseCase(getIt()));

  /// Bloc
  getIt.registerFactory(
    () => VideoBloc(pickVideoUseCase: getIt(), compressVideoUseCase: getIt()),
  );
}
