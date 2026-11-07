import 'package:get_it/get_it.dart';

import '../../domain/repositories/run_repository_contract.dart';
import '../local_data_source/run_recording_storage.dart';
import '../local_data_source/run_tracker_data_source.dart';
import '../remote_data_source/training/run_remote_data_source.dart';
import '../repository/run_repository.dart';

/// Carreras con GPS y entrenos de carrera (ADR 0037): servidor, carrera en
/// curso y cola en el teléfono, y GPS (solo Android e iOS).
void registerRunData(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => RunRemoteDataSource(getIt()))
    ..registerLazySingleton(RunRecordingStorage.new)
    ..registerLazySingleton<RunTrackerDataSource>(() {
      final gps = GeolocatorRunTrackerDataSource();
      return gps.supported ? gps : const UnsupportedRunTrackerDataSource();
    })
    ..registerLazySingleton<RunRepositoryContract>(() => RunRepository(getIt()))
    ..registerLazySingleton<RunRecordingRepositoryContract>(
      () => RunRecordingRepository(getIt()),
    )
    ..registerLazySingleton<RunTrackerRepositoryContract>(
      () => RunTrackerRepository(getIt()),
    );
}
