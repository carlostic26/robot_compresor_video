import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // Register dependencies here. Previously registered a HomeCubit
  // but the cubit implementation was moved/removed, which caused
  // build errors due to a missing import. Add registrations as
  // needed, for example:
  // sl.registerFactory(() => HomeCubit());
}
