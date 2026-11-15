import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/use_cases/social/together/decline_workout_together_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/find_workout_together_by_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/get_workout_together_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/join_workout_together_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/leave_workout_together_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/start_workout_together_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together_live/is_together_live_connected_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/together/live/bloc/workout_together_live_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/workout_detail/bloc/workout_together_bloc.dart';

import '../data_changes_fake.dart';
import '../shell/together_live_fakes.dart';

class _Get implements GetWorkoutTogetherUseCaseContract {
  _Get(this.current);

  WorkoutTogether current;
  var calls = 0;

  @override
  Future<AppResult<WorkoutTogether>> call(String id) async {
    calls++;
    return Success(current);
  }
}

class _Join implements JoinWorkoutTogetherUseCaseContract {
  @override
  Future<AppResult<WorkoutTogether>> call(String id) async =>
      Success(workout());
}

class _Decline implements DeclineWorkoutTogetherUseCaseContract {
  @override
  Future<AppResult<Unit>> call(String id) async => const Success(unit);
}

class _Leave implements LeaveWorkoutTogetherUseCaseContract {
  @override
  Future<AppResult<Unit>> call(String id) async => const Success(unit);
}

class _Start implements StartWorkoutTogetherUseCaseContract {
  @override
  Future<AppResult<String>> call(String id) async => const Success('s-me');
}

class _Find implements FindWorkoutTogetherBySessionUseCaseContract {
  _Find(this.result);

  WorkoutTogether? result;
  var calls = 0;

  @override
  Future<AppResult<WorkoutTogether?>> call(String sessionId) async {
    calls++;
    return Success(result);
  }
}

class _Connected implements IsTogetherLiveConnectedUseCaseContract {
  _Connected(this.value);

  bool value;

  @override
  bool call() => value;
}

/// «Entrenamos juntos» a la vez (ADR 0047): la pantalla de espera entra sola
/// cuando empieza otra persona, y el canal en directo hace leer al momento.
void main() {
  late FakeDataChanges changes;

  setUp(() => changes = FakeDataChanges());
  tearDown(() => changes.close());

  WorkoutTogetherBloc waiting(_Get get, {bool connected = false}) =>
      WorkoutTogetherBloc(
        get: get,
        join: _Join(),
        decline: _Decline(),
        leave: _Leave(),
        start: _Start(),
        watchChanges: changes.useCase,
        liveConnected: _Connected(connected),
        pollInterval: const Duration(hours: 1),
      );

  test(
    'pantalla de espera: si empieza otra persona, entra sola una vez',
    () async {
      final get = _Get(workout());
      final bloc = waiting(get, connected: true)
        ..add(const WorkoutTogetherEvent.started('w1'));
      final opened = <(String, bool)>[];
      final sub = bloc.stream.listen((s) {
        if (s.openSession case final id?) opened.add((id, s.startedByOther));
      });
      await pump();

      get.current = workout(
        startedAt: DateTime(2026, 11, 16, 18),
        startedBy: ana,
      );
      changes.emit({DataTopic.workoutTogether});
      await pump();
      await pump();
      expect(opened, [('s-me', true)]);

      changes.emit({DataTopic.workoutTogether});
      await pump();
      await pump();
      expect(opened, hasLength(1), reason: 'no vuelve a entrar sola');
      await sub.cancel();
      await bloc.close();
    },
  );

  test('abierta con el entreno ya en marcha no entra sola', () async {
    final get = _Get(
      workout(startedAt: DateTime(2026, 11, 16, 18), startedBy: ana),
    );
    final bloc = waiting(get)..add(const WorkoutTogetherEvent.started('w1'));
    final opened = <String>[];
    final sub = bloc.stream.listen((s) {
      if (s.openSession case final id?) opened.add(id);
    });
    await pump();
    bloc.add(const WorkoutTogetherEvent.polled(live: true));
    await pump();
    await pump();
    expect(opened, isEmpty);
    await sub.cancel();
    await bloc.close();
  });

  test('con el canal conectado la consulta de respaldo se salta; el aviso '
      'del canal se lee siempre', () async {
    final get = _Get(workout());
    final bloc = waiting(get, connected: true)
      ..add(const WorkoutTogetherEvent.started('w1'));
    await pump();
    expect(get.calls, 1);
    bloc.add(const WorkoutTogetherEvent.polled());
    await pump();
    expect(get.calls, 1, reason: 'leído hace nada: el canal ya avisaría');
    bloc.add(const WorkoutTogetherEvent.polled(live: true));
    await pump();
    expect(get.calls, 2);
    await bloc.close();
  });

  test('sin canal, la consulta de siempre sigue leyendo', () async {
    final get = _Get(workout());
    final bloc = waiting(get)..add(const WorkoutTogetherEvent.started('w1'));
    await pump();
    bloc.add(const WorkoutTogetherEvent.polled());
    await pump();
    expect(get.calls, 2);
    await bloc.close();
  });

  test(
    'sesión en vivo: el panel lee al momento cuando el canal avisa',
    () async {
      final find = _Find(workout(startedAt: DateTime(2026, 11, 16, 18)));
      final bloc = WorkoutTogetherLiveBloc(
        find: find,
        watchChanges: changes.useCase,
        liveConnected: _Connected(true),
        pollInterval: const Duration(hours: 1),
      )..add(const WorkoutTogetherLiveEvent.started('s-me'));
      await pump();
      expect(find.calls, 1);

      find.result = workout(
        startedAt: DateTime(2026, 11, 16, 18),
        pausedAt: DateTime(2026, 11, 16, 18, 10),
      );
      changes.emit({DataTopic.workoutTogether});
      await pump();
      await pump();
      expect(find.calls, 2);
      expect(bloc.state.workout?.paused, isTrue);

      changes.emit({DataTopic.studyRoom});
      await pump();
      expect(find.calls, 2, reason: 'una sala no le afecta');
      await bloc.close();
    },
  );
}
