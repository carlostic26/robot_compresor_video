import 'package:get_it/get_it.dart';
import 'package:robot_compresor_video/features/compress_video/domain/use_cases/pick_video_use_case.dart';

import '../../features/compress_video/data/datasources/video_picker_datasource.dart';
import '../../features/compress_video/data/repositories/video_repository_impl.dart';
import '../../features/compress_video/domain/repositories/video_repository.dart';

import '../../features/compress_video/presentation/bloc/video_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  /// Datasources
  sl.registerLazySingleton<VideoPickerDatasource>(
    () => VideoPickerDatasource(),
  );

  /// Repository
  sl.registerLazySingleton<VideoRepository>(() => VideoRepositoryImpl(sl()));

  /// UseCases
  sl.registerLazySingleton(() => PickVideoUseCase(sl()));

  /// Bloc
  sl.registerFactory(() => VideoBloc(pickVideoUseCase: sl()));
}
