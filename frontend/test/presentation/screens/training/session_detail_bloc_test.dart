import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/session_history.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_highlights_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/session_detail/bloc/session_detail_bloc.dart';

import 'training_fixtures.dart';

class _GetSession extends Mock implements GetSessionUseCaseContract {}

class _GetRoutine extends Mock implements GetRoutineUseCaseContract {}

class _GetHighlights extends Mock
    implements GetSessionHighlightsUseCaseContract {}

/// Detalle de solo lectura de una sesión terminada.
void main() {
  late _GetSession getSession;
  late _GetRoutine getRoutine;
  late _GetHighlights getHighlights;
  final session = TrainingFixtures.session(status: SessionStatus.completed);
  final entry = SessionHistoryEntry(session: session, routineName: 'Fuerza');
  const highlights = SessionHighlights(volumeKg: 1200, completedSets: 6);

  SessionDetailBloc build() => SessionDetailBloc(
    getSession: getSession,
    getRoutine: getRoutine,
    getHighlights: getHighlights,
  );

  setUp(() {
    getSession = _GetSession();
    getRoutine = _GetRoutine();
    getHighlights = _GetHighlights();
    when(
      () => getRoutine('r1'),
    ).thenAnswer((_) async => Success(TrainingFixtures.routine()));
    when(
      () => getHighlights('s1'),
    ).thenAnswer((_) async => const Success(highlights));
  });

  blocTest<SessionDetailBloc, SessionDetailState>(
    'desde el historial: nombres de la rutina y lo destacado',
    build: build,
    act: (bloc) => bloc.add(SessionDetailEvent.started('s1', entry: entry)),
    verify: (bloc) {
      expect(bloc.state.status, SessionDetailStatus.ready);
      expect(bloc.state.exercises.keys, containsAll(['p1', 'p2']));
      expect(bloc.state.highlights, highlights);
      verifyNever(() => getSession(any()));
    },
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'por enlace directo carga la sesión; si falla, muestra el error',
    setUp: () => when(
      () => getSession('s1'),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const SessionDetailEvent.started('s1')),
    expect: () => [
      const SessionDetailState(),
      const SessionDetailState(
        status: SessionDetailStatus.failure,
        error: AppError.network(),
      ),
    ],
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'sin la rutina (borrada) las series se muestran igual',
    setUp: () {
      when(
        () => getRoutine('r1'),
      ).thenAnswer((_) async => const Failure(AppError.network()));
      when(() => getSession('s1')).thenAnswer((_) async => Success(session));
    },
    build: build,
    act: (bloc) => bloc.add(const SessionDetailEvent.started('s1')),
    verify: (bloc) {
      expect(bloc.state.status, SessionDetailStatus.ready);
      expect(bloc.state.exercises, isEmpty);
    },
  );
}
