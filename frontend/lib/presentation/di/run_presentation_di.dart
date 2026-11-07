import 'package:get_it/get_it.dart';

import '../screens/training/run_detail/bloc/run_detail_bloc.dart';
import '../screens/training/run_home/bloc/run_home_bloc.dart';
import '../screens/training/run_recorder/bloc/run_recorder_bloc.dart';
import '../screens/training/run_workout_editor/bloc/run_workout_editor_bloc.dart';

/// Blocs del apartado Correr de Entreno (ADR 0037).
void registerRunPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => RunHomeBloc(
        uploadPending: getIt(),
        getWeek: getIt(),
        listActivities: getIt(),
        listWorkouts: getIt(),
        listTemplates: getIt(),
        listPlanned: getIt(),
        listPending: getIt(),
        loadRecording: getIt(),
        deleteWorkout: getIt(),
        scheduleWorkout: getIt(),
        permissionStatus: getIt(),
        openSettings: getIt(),
        position: getIt(),
        track: getIt(),
        share: getIt(),
        watchDataChanges: getIt(),
      ),
    )
    ..registerFactory(
      () => RunRecorderBloc(
        load: getIt(),
        save: getIt(),
        discard: getIt(),
        finish: getIt(),
        listWorkouts: getIt(),
        serviceEnabled: getIt(),
        track: getIt(),
        openSettings: getIt(),
      ),
    )
    ..registerFactory(
      () => RunDetailBloc(get: getIt(), delete: getIt(), share: getIt()),
    )
    ..registerFactory(
      () => RunWorkoutEditorBloc(
        create: getIt(),
        update: getIt(),
        listWorkouts: getIt(),
        listTemplates: getIt(),
      ),
    );
}
