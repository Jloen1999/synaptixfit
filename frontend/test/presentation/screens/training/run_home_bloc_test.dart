import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/run.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_device_permission_status_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/open_permission_settings_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/share_achievement_image_use_case.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_run_workout_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_current_position_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_run_week_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_pending_runs_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_planned_runs_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_run_workout_templates_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_run_workouts_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_sport_activities_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/load_run_recording_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/schedule_run_workout_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/track_run_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/upload_pending_runs_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/run_home/bloc/run_home_bloc.dart';

class _Delete extends Mock implements DeleteRunWorkoutUseCaseContract {}

class _Upload extends Mock implements UploadPendingRunsUseCaseContract {}

class _Week extends Mock implements GetRunWeekUseCaseContract {}

class _Activities extends Mock implements ListSportActivitiesUseCaseContract {}

class _Workouts extends Mock implements ListRunWorkoutsUseCaseContract {}

class _Templates extends Mock
    implements ListRunWorkoutTemplatesUseCaseContract {}

class _Planned extends Mock implements ListPlannedRunsUseCaseContract {}

class _Pending extends Mock implements ListPendingRunsUseCaseContract {}

class _Recording extends Mock implements LoadRunRecordingUseCaseContract {}

class _Schedule extends Mock implements ScheduleRunWorkoutUseCaseContract {}

class _Permission extends Mock
    implements GetDevicePermissionStatusUseCaseContract {}

class _Settings extends Mock implements OpenPermissionSettingsUseCaseContract {}

class _Position extends Mock implements GetCurrentPositionUseCaseContract {}

class _Track extends Mock implements TrackRunUseCaseContract {}

class _Share extends Mock implements ShareAchievementImageUseCaseContract {}

class _Watch extends Mock implements WatchDataChangesUseCaseContract {}

/// Eliminar un entreno de carrera es reversible un rato (vocabulario §4): se
/// quita de la lista al momento, «Deshacer» lo devuelve a su sitio y solo se
/// elimina en el servidor al cerrarse el aviso o la pantalla.
void main() {
  late _Delete delete;

  const series = RunWorkout(id: 'w1', name: 'Series', groups: []);
  const tempo = RunWorkout(id: 'w2', name: 'Tempo', groups: []);
  const long = RunWorkout(id: 'w3', name: 'Tirada larga', groups: []);
  const ready = RunHomeState(
    status: RunHomeStatus.ready,
    workouts: [series, tempo, long],
  );

  setUp(() {
    delete = _Delete();
    when(() => delete(any())).thenAnswer((_) async => const Success(unit));
  });

  RunHomeBloc build() => RunHomeBloc(
    uploadPending: _Upload(),
    getWeek: _Week(),
    listActivities: _Activities(),
    listWorkouts: _Workouts(),
    listTemplates: _Templates(),
    listPlanned: _Planned(),
    listPending: _Pending(),
    loadRecording: _Recording(),
    deleteWorkout: delete,
    scheduleWorkout: _Schedule(),
    permissionStatus: _Permission(),
    openSettings: _Settings(),
    position: _Position(),
    track: _Track(),
    share: _Share(),
    watchDataChanges: _Watch(),
  );

  blocTest<RunHomeBloc, RunHomeState>(
    'deslizar lo quita al momento y lo elimina al cerrarse el aviso',
    build: build,
    seed: () => ready,
    act: (bloc) async {
      bloc.add(const RunHomeEvent.workoutDeleted('w2'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.workouts, [series, long]);
      verifyNever(() => delete(any()));
      bloc.add(const RunHomeEvent.workoutDeleteCommitted('w2'));
    },
    verify: (_) => verify(() => delete('w2')).called(1),
  );

  blocTest<RunHomeBloc, RunHomeState>(
    '«Deshacer» lo devuelve a su sitio y no se elimina',
    build: build,
    seed: () => ready,
    act: (bloc) async {
      bloc.add(const RunHomeEvent.workoutDeleted('w2'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RunHomeEvent.workoutDeleteUndone('w2'));
      await Future<void>.delayed(Duration.zero);
      // El aviso se cierra después por «Deshacer»: no confirma nada.
      bloc.add(const RunHomeEvent.workoutDeleteCommitted('w2'));
    },
    verify: (bloc) {
      expect(bloc.state.workouts, [series, tempo, long]);
      verifyNever(() => delete(any()));
    },
  );

  blocTest<RunHomeBloc, RunHomeState>(
    'si no se puede eliminar, vuelve a su sitio y se avisa',
    setUp: () => when(
      () => delete('w2'),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: () => ready,
    act: (bloc) async {
      bloc.add(const RunHomeEvent.workoutDeleted('w2'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RunHomeEvent.workoutDeleteCommitted('w2'));
    },
    verify: (bloc) => expect(bloc.state.workouts, [series, tempo, long]),
  );

  // blocTest cierra el bloc después de `act`: `verify` ve lo que hizo close.
  blocTest<RunHomeBloc, RunHomeState>(
    'si la pantalla se cierra con el aviso abierto, se elimina igual',
    build: build,
    seed: () => ready,
    act: (bloc) => bloc.add(const RunHomeEvent.workoutDeleted('w1')),
    verify: (_) => verify(() => delete('w1')).called(1),
  );
}
