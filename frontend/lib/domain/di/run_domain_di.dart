import 'package:get_it/get_it.dart';

import '../use_cases/training/create_run_workout_use_case.dart';
import '../use_cases/training/delete_run_use_case.dart';
import '../use_cases/training/delete_run_workout_use_case.dart';
import '../use_cases/training/discard_run_recording_use_case.dart';
import '../use_cases/training/finish_run_use_case.dart';
import '../use_cases/training/get_current_position_use_case.dart';
import '../use_cases/training/get_run_use_case.dart';
import '../use_cases/training/get_run_week_use_case.dart';
import '../use_cases/training/is_location_service_enabled_use_case.dart';
import '../use_cases/training/list_pending_runs_use_case.dart';
import '../use_cases/training/list_planned_runs_use_case.dart';
import '../use_cases/training/list_run_workout_templates_use_case.dart';
import '../use_cases/training/list_run_workouts_use_case.dart';
import '../use_cases/training/load_run_recording_use_case.dart';
import '../use_cases/training/save_run_recording_use_case.dart';
import '../use_cases/training/schedule_run_workout_use_case.dart';
import '../use_cases/training/track_run_use_case.dart';
import '../use_cases/training/update_run_workout_use_case.dart';
import '../use_cases/training/upload_pending_runs_use_case.dart';

/// Casos de uso de las carreras con GPS y los entrenos de carrera (ADR 0037).
void registerRunDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<GetRunUseCaseContract>(() => GetRunUseCase(getIt()))
    ..registerLazySingleton<DeleteRunUseCaseContract>(
      () => DeleteRunUseCase(getIt()),
    )
    ..registerLazySingleton<GetRunWeekUseCaseContract>(
      () => GetRunWeekUseCase(getIt()),
    )
    ..registerLazySingleton<ListRunWorkoutsUseCaseContract>(
      () => ListRunWorkoutsUseCase(getIt()),
    )
    ..registerLazySingleton<ListRunWorkoutTemplatesUseCaseContract>(
      () => ListRunWorkoutTemplatesUseCase(getIt()),
    )
    ..registerLazySingleton<CreateRunWorkoutUseCaseContract>(
      () => CreateRunWorkoutUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateRunWorkoutUseCaseContract>(
      () => UpdateRunWorkoutUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteRunWorkoutUseCaseContract>(
      () => DeleteRunWorkoutUseCase(getIt()),
    )
    ..registerLazySingleton<ScheduleRunWorkoutUseCaseContract>(
      () => ScheduleRunWorkoutUseCase(getIt()),
    )
    ..registerLazySingleton<ListPlannedRunsUseCaseContract>(
      () => ListPlannedRunsUseCase(getIt()),
    )
    ..registerLazySingleton<LoadRunRecordingUseCaseContract>(
      () => LoadRunRecordingUseCase(getIt()),
    )
    ..registerLazySingleton<SaveRunRecordingUseCaseContract>(
      () => SaveRunRecordingUseCase(getIt()),
    )
    ..registerLazySingleton<DiscardRunRecordingUseCaseContract>(
      () => DiscardRunRecordingUseCase(getIt()),
    )
    ..registerLazySingleton<ListPendingRunsUseCaseContract>(
      () => ListPendingRunsUseCase(getIt()),
    )
    ..registerLazySingleton<GetCurrentPositionUseCaseContract>(
      () => GetCurrentPositionUseCase(getIt()),
    )
    ..registerLazySingleton<IsLocationServiceEnabledUseCaseContract>(
      () => IsLocationServiceEnabledUseCase(getIt()),
    )
    ..registerLazySingleton<TrackRunUseCaseContract>(
      () => TrackRunUseCase(getIt()),
    )
    ..registerLazySingleton<FinishRunUseCaseContract>(
      () => FinishRunUseCase(getIt(), getIt()),
    )
    ..registerLazySingleton<UploadPendingRunsUseCaseContract>(
      () => UploadPendingRunsUseCase(getIt(), getIt()),
    );
}
