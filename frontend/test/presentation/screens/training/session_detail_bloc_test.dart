import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/models/training/session_history.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/correct_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_highlights_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_history_entry_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/unmark_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/session_detail/bloc/session_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';

import 'training_fixtures.dart';

class _GetSession extends Mock
    implements GetSessionHistoryEntryUseCaseContract {}

class _GetRoutine extends Mock implements GetRoutineUseCaseContract {}

class _GetHighlights extends Mock
    implements GetSessionHighlightsUseCaseContract {}

class _Correct extends Mock implements CorrectSessionUseCaseContract {}

class _Unmark extends Mock implements UnmarkSessionUseCaseContract {}

class _Delete extends Mock implements DeleteSessionUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

/// Detalle de una sesión terminada: lo destacado y, también sin pila,
/// corregir, reabrir y eliminar (ADR 0046).
void main() {
  late _GetSession getSession;
  late _GetRoutine getRoutine;
  late _GetHighlights getHighlights;
  late _Correct correct;
  late _Unmark unmark;
  late _Delete delete;
  late _GetAccount getAccount;
  final session = TrainingFixtures.session(status: SessionStatus.completed);
  final entry = SessionHistoryEntry(session: session, routineName: 'Fuerza');
  const highlights = SessionHighlights(volumeKg: 1200, completedSets: 6);

  SessionDetailBloc build() => SessionDetailBloc(
    getEntry: getSession,
    getRoutine: getRoutine,
    getHighlights: getHighlights,
    correct: correct,
    unmark: unmark,
    delete: delete,
    getAccount: getAccount,
  );

  setUp(() {
    getSession = _GetSession();
    getRoutine = _GetRoutine();
    getHighlights = _GetHighlights();
    correct = _Correct();
    unmark = _Unmark();
    delete = _Delete();
    getAccount = _GetAccount();
    when(
      () => getAccount(),
    ).thenAnswer((_) async => const Success(TrainingFixtures.account));
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
      when(
        () => getSession('s1'),
      ).thenAnswer((_) async => Success(SessionHistoryEntry(session: session)));
    },
    build: build,
    act: (bloc) => bloc.add(const SessionDetailEvent.started('s1')),
    verify: (bloc) {
      expect(bloc.state.status, SessionDetailStatus.ready);
      expect(bloc.state.exercises, isEmpty);
    },
  );

  SessionDetailState ready() => SessionDetailState(
    status: SessionDetailStatus.ready,
    entry: entry.copyWith(unmarkable: true),
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'corregir lo hace el propio detalle y se queda con la sesión corregida',
    setUp: () => when(
      () => correct('s1', rpe: 8, durationMinutes: 50),
    ).thenAnswer((_) async => Success(session.copyWith(durationMinutes: 50))),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(
      const SessionDetailEvent.correctRequested(minutes: 50, rpe: 8),
    ),
    verify: (bloc) {
      expect(bloc.state.entry!.session.durationMinutes, 50);
      expect(bloc.state.busy, isFalse);
      verify(() => correct('s1', rpe: 8, durationMinutes: 50)).called(1);
    },
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'reabrir la desmarca, entra en la sesión y pone la cuenta al día',
    setUp: () => when(() => unmark('s1')).thenAnswer(
      (_) async => Success(
        UnmarkSessionResult(
          session: session,
          experience: const ExperienceChange(
            level: 1,
            levelXp: 0,
            xpDelta: -10,
          ),
        ),
      ),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const SessionDetailEvent.reopenRequested()),
    expect: () => [
      isA<SessionDetailState>().having((s) => s.busy, 'busy', true),
      isA<SessionDetailState>().having((s) => s.reopened, 'reopened', 's1'),
      isA<SessionDetailState>().having((s) => s.reopened, 'reopened', null),
      isA<SessionDetailState>().having(
        (s) => s.effect,
        'effect',
        isA<TrainingEffectAccountChanged>(),
      ),
      isA<SessionDetailState>().having((s) => s.effect, 'effect', null),
    ],
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'eliminar la borra y cierra el detalle; un fallo se dice y se queda',
    setUp: () =>
        when(() => delete('s1')).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const SessionDetailEvent.deleteRequested()),
    verify: (bloc) => expect(bloc.state.deleted, isTrue),
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'si eliminar falla, se avisa y no se cierra',
    setUp: () => when(
      () => delete('s1'),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const SessionDetailEvent.deleteRequested()),
    expect: () => [
      isA<SessionDetailState>().having((s) => s.busy, 'busy', true),
      isA<SessionDetailState>().having((s) => s.busy, 'busy', false),
      isA<SessionDetailState>().having(
        (s) => s.effect,
        'effect',
        const TrainingEffect.error(AppError.network()),
      ),
      isA<SessionDetailState>().having((s) => s.effect, 'effect', null),
    ],
    verify: (bloc) => expect(bloc.state.deleted, isFalse),
  );
}
