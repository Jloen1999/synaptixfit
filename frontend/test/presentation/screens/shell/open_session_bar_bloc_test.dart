import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_open_sessions_use_case.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/open_session_bar_bloc.dart';

class _GetOpen extends Mock implements GetOpenSessionsUseCaseContract {}

class _Watch extends Mock implements WatchDataChangesUseCaseContract {}

TrainingSession _session(String id, {DateTime? pausedAt}) => TrainingSession(
  id: id,
  type: SessionType.routine,
  status: SessionStatus.inProgress,
  startedAt: DateTime(2026, 11, 2, 18),
  pausedAt: pausedAt,
);

/// Barra «Sesión en pausa · Volver» del armazón.
void main() {
  late _GetOpen getOpen;
  late _Watch watch;
  late StreamController<Set<DataTopic>> changes;

  setUp(() {
    getOpen = _GetOpen();
    watch = _Watch();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(
      () => watch(topics: any(named: 'topics')),
    ).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  test('muestra la sesión abierta y no la abandonada', () async {
    when(() => getOpen()).thenAnswer(
      (_) async => Success([
        OpenSession(session: _session('vieja'), stale: true),
        OpenSession(
          session: _session('s1', pausedAt: DateTime(2026, 11, 2, 18, 20)),
          stale: false,
        ),
      ]),
    );
    final bloc = OpenSessionBarBloc(
      getOpenSessions: getOpen,
      watchDataChanges: watch,
    )..add(const OpenSessionBarEvent.started());
    await settle();
    expect(bloc.state.session?.id, 's1');
    expect(bloc.state.session?.isPaused, isTrue);
    await bloc.close();
  });

  test(
    'al terminar la sesión (cambio de entreno) la barra desaparece',
    () async {
      var open = [OpenSession(session: _session('s1'), stale: false)];
      when(() => getOpen()).thenAnswer((_) async => Success(open));
      final bloc = OpenSessionBarBloc(
        getOpenSessions: getOpen,
        watchDataChanges: watch,
      )..add(const OpenSessionBarEvent.started());
      await settle();
      expect(bloc.state.session, isNotNull);
      open = [];
      changes.add({DataTopic.training});
      await settle();
      expect(bloc.state.session, isNull);
      await bloc.close();
    },
  );
}
