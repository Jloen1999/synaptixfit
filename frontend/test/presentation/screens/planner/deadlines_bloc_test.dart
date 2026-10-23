import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/deadline.dart';
import 'package:synaptixfit/domain/models/planner/planner_options.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/create_deadline_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/delete_deadline_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_deadlines_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/set_deadline_completion_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/update_deadline_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/deadlines/bloc/deadlines_bloc.dart';

import 'planner_fixtures.dart';

class _Get extends Mock implements GetDeadlinesUseCaseContract {}

class _Subjects extends Mock implements GetPlannerSubjectsUseCaseContract {}

class _Create extends Mock implements CreateDeadlineUseCaseContract {}

class _Update extends Mock implements UpdateDeadlineUseCaseContract {}

class _Delete extends Mock implements DeleteDeadlineUseCaseContract {}

class _Completion extends Mock
    implements SetDeadlineCompletionUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Get getDeadlines;
  late _Subjects getSubjects;
  late _Create create;
  late _Update update;
  late _Delete delete;
  late _Completion setCompletion;
  late _Account getAccount;

  const subject = SubjectOption(id: 's1', name: 'Física');
  final d1 = deadline();
  final d2 = deadline(id: 'd2');

  DeadlinesBloc build() => DeadlinesBloc(
    getDeadlines: getDeadlines,
    getSubjects: getSubjects,
    createDeadline: create,
    updateDeadline: update,
    deleteDeadline: delete,
    setCompletion: setCompletion,
    getAccount: getAccount,
  );

  DeadlinesState ready() => DeadlinesState(
    status: DeadlinesStatus.ready,
    items: [d1, d2],
    subjects: const [subject],
  );

  setUp(() {
    getDeadlines = _Get();
    getSubjects = _Subjects();
    create = _Create();
    update = _Update();
    delete = _Delete();
    setCompletion = _Completion();
    getAccount = _Account();
    when(() => getSubjects()).thenAnswer((_) async => const Success([subject]));
    when(
      () => getDeadlines(
        upcoming: any(named: 'upcoming'),
        subjectId: any(named: 'subjectId'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async =>
          Success(DeadlinePage(items: [d1, d2], page: 0, totalPages: 2)),
    );
    when(
      () => getAccount(),
    ).thenAnswer((_) async => const Success(testAccount));
  });

  blocTest<DeadlinesBloc, DeadlinesState>(
    'carga asignaturas y entregas pendientes',
    build: build,
    act: (bloc) => bloc.add(const DeadlinesEvent.started()),
    expect: () => [
      // El estado inicial ya es «cargando»: solo cambian las asignaturas.
      isA<DeadlinesState>()
          .having((s) => s.subjects, 'subjects', [subject])
          .having((s) => s.status, 'status', DeadlinesStatus.loading),
      isA<DeadlinesState>()
          .having((s) => s.status, 'status', DeadlinesStatus.ready)
          .having((s) => s.items, 'items', [d1, d2])
          .having((s) => s.hasMore, 'hasMore', isTrue),
    ],
    verify: (_) =>
        verify(() => getDeadlines(upcoming: true, subjectId: null)).called(1),
  );

  blocTest<DeadlinesBloc, DeadlinesState>(
    'error al cargar',
    setUp: () => when(
      () => getDeadlines(
        upcoming: any(named: 'upcoming'),
        subjectId: any(named: 'subjectId'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    act: (bloc) => bloc.add(const DeadlinesEvent.started()),
    verify: (bloc) {
      expect(bloc.state.status, DeadlinesStatus.failure);
      expect(bloc.state.error, const AppError.server());
    },
  );

  blocTest<DeadlinesBloc, DeadlinesState>(
    'cambiar el filtro a «todas» y por asignatura recarga',
    build: build,
    seed: ready,
    act: (bloc) => bloc
      ..add(const DeadlinesEvent.pendingFilterChanged(false))
      ..add(const DeadlinesEvent.subjectFilterChanged('s1')),
    verify: (bloc) {
      expect(bloc.state.pendingOnly, isFalse);
      expect(bloc.state.subjectId, 's1');
      verify(() => getDeadlines(upcoming: false, subjectId: 's1')).called(1);
    },
  );

  blocTest<DeadlinesBloc, DeadlinesState>(
    'completar con el filtro de pendientes la saca de la lista y da XP',
    setUp: () => when(() => setCompletion('d1', completed: true)).thenAnswer(
      (_) async => Success(
        DeadlineCompletion(deadline: d1.copyWith(completed: true), xpDelta: 30),
      ),
    ),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(const DeadlinesEvent.completionToggled('d1')),
    skip: 1,
    expect: () => [
      isA<DeadlinesState>()
          .having((s) => s.items, 'items', [d2])
          .having(
            (s) => s.notice,
            'notice',
            const DeadlinesNotice.completion(
              completed: true,
              xpDelta: 30,
              account: testAccount,
            ),
          ),
    ],
  );

  blocTest<DeadlinesBloc, DeadlinesState>(
    'borrar la quita ya y la borra cuando el aviso se cierra sin deshacer',
    setUp: () =>
        when(() => delete('d2')).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: ready,
    act: (bloc) async {
      bloc.add(const DeadlinesEvent.deleted('d2'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.visibleItems, [d1]);
      expect(bloc.state.notice, const DeadlinesNotice.deleted('d2'));
      bloc.add(const DeadlinesEvent.deleteCommitted('d2'));
    },
    verify: (bloc) {
      verify(() => delete('d2')).called(1);
      expect(bloc.state.items, [d1]);
    },
  );

  blocTest<DeadlinesBloc, DeadlinesState>(
    '«Deshacer» la devuelve y no se borra',
    build: build,
    seed: ready,
    act: (bloc) => bloc
      ..add(const DeadlinesEvent.deleted('d2'))
      ..add(const DeadlinesEvent.deleteUndone('d2'))
      ..add(const DeadlinesEvent.deleteCommitted('d2')),
    verify: (bloc) {
      verifyNever(() => delete(any()));
      expect(bloc.state.visibleItems, hasLength(2));
    },
  );

  blocTest<DeadlinesBloc, DeadlinesState>(
    'crear una entrega avisa y recarga',
    setUp: () => when(() => create(any())).thenAnswer((_) async => Success(d1)),
    build: build,
    seed: ready,
    act: (bloc) => bloc.add(
      DeadlinesEvent.saved(
        draft: DeadlineDraft(
          title: 'Nueva',
          type: d1.type,
          dueAt: d1.dueAt,
          difficulty: d1.difficulty,
        ),
      ),
    ),
    expect: () => [
      isA<DeadlinesState>().having((s) => s.saving, 'saving', isTrue),
      isA<DeadlinesState>().having(
        (s) => s.notice,
        'notice',
        const DeadlinesNotice.saved(created: true),
      ),
      isA<DeadlinesState>().having((s) => s.hasMore, 'hasMore', isTrue),
    ],
  );
}
