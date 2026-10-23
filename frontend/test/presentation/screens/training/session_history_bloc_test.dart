import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/models/training/session_history.dart';
import 'package:synaptixfit/domain/models/training/training_page.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_personal_records_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_history_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/unmark_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/session_history/bloc/session_history_bloc.dart';

import 'training_fixtures.dart';

class _MockHistory extends Mock implements GetSessionHistoryUseCaseContract {}

class _MockRecords extends Mock implements GetPersonalRecordsUseCaseContract {}

class _MockUnmark extends Mock implements UnmarkSessionUseCaseContract {}

class _MockAccount extends Mock implements GetAccountUseCaseContract {}

void main() {
  late _MockHistory getHistory;
  late _MockRecords getRecords;
  late _MockUnmark unmark;
  late _MockAccount getAccount;

  final session = TrainingFixtures.session(status: SessionStatus.completed);
  final record = PersonalRecord(
    exerciseId: 'e1',
    exerciseName: 'Press de banca',
    kind: PersonalRecordKind.weight,
    weightKg: 62.5,
    reps: 5,
    sessionId: 's1',
    achievedAt: DateTime(2026, 10, 17),
  );
  final entry = SessionHistoryEntry(
    session: session,
    routineName: 'Fuerza',
    dayName: 'Empuje: pecho y hombro',
    records: [record],
  );

  SessionHistoryBloc build() => SessionHistoryBloc(
    getHistory: getHistory,
    getRecords: getRecords,
    unmark: unmark,
    getAccount: getAccount,
  );

  setUp(() {
    getHistory = _MockHistory();
    getRecords = _MockRecords();
    unmark = _MockUnmark();
    getAccount = _MockAccount();
    when(
      () => getHistory(
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => Success(
        TrainingPage(items: [entry], page: 0, totalPages: 1, totalItems: 1),
      ),
    );
    when(() => getRecords()).thenAnswer((_) async => Success([record]));
  });

  blocTest<SessionHistoryBloc, SessionHistoryState>(
    'carga el historial con el nombre del día y tus récords',
    build: build,
    act: (bloc) => bloc.add(const SessionHistoryEvent.started()),
    skip: 1,
    expect: () => [
      SessionHistoryState(
        status: HistoryStatus.ready,
        items: [entry],
        records: [record],
      ),
    ],
  );

  blocTest<SessionHistoryBloc, SessionHistoryState>(
    'si fallan los récords el historial se muestra igual',
    setUp: () => when(
      () => getRecords(),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    act: (bloc) => bloc.add(const SessionHistoryEvent.started()),
    skip: 1,
    expect: () => [
      SessionHistoryState(status: HistoryStatus.ready, items: [entry]),
    ],
  );

  blocTest<SessionHistoryBloc, SessionHistoryState>(
    'desmarcar quita la sesión del historial y recarga los récords',
    setUp: () {
      when(() => unmark('s1')).thenAnswer(
        (_) async => Success(
          UnmarkSessionResult(
            session: session.copyWith(status: SessionStatus.inProgress),
            experience: const ExperienceChange(
              level: 1,
              levelXp: 0,
              xpDelta: -150,
            ),
          ),
        ),
      );
      when(
        () => getAccount(),
      ).thenAnswer((_) async => const Failure(AppError.server()));
    },
    seed: () => SessionHistoryState(
      status: HistoryStatus.ready,
      items: [entry],
      records: [record],
    ),
    build: build,
    act: (bloc) => bloc.add(const SessionHistoryEvent.unmarkRequested('s1')),
    verify: (bloc) {
      expect(bloc.state.items, isEmpty);
      verify(() => getRecords()).called(1);
    },
  );
}
