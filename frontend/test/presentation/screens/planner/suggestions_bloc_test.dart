import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/block_draft.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/planner/planner_ai.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/planner/create_block_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/suggest_week_plan_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/suggestions/bloc/suggestions_bloc.dart';

import 'planner_fixtures.dart';

class _Suggest extends Mock implements SuggestWeekPlanUseCaseContract {}

class _Create extends Mock implements CreateBlockUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Suggest suggest;
  late _Create create;

  SuggestedBlock proposed(DateTime start, {BlockType type = BlockType.study}) =>
      SuggestedBlock(
        type: type,
        start: start,
        end: start.add(const Duration(hours: 1)),
        subjectId: 's1',
        subjectName: 'Cálculo',
        topic: 'Integrales',
      );

  final past = proposed(DateTime(2025, 10, 15, 8));
  final future1 = proposed(DateTime(2025, 10, 16, 9));
  final future2 = proposed(DateTime(2025, 10, 17, 18), type: BlockType.sport);
  final suggestion = WeekSuggestion(
    source: SuggestionSource.ai,
    studyHours: 2,
    sportSessions: 1,
    blocks: [past, future1, future2],
  );

  SuggestionsBloc build() => SuggestionsBloc(
    suggest: suggest,
    createBlock: create,
    now: () => testNow,
  );

  setUp(() {
    suggest = _Suggest();
    create = _Create();
    when(
      () => suggest(
        weekStart: any(named: 'weekStart'),
        studyHours: any(named: 'studyHours'),
        sportSessions: any(named: 'sportSessions'),
      ),
    ).thenAnswer((_) async => Success(suggestion));
  });

  blocTest<SuggestionsBloc, SuggestionsState>(
    'genera una propuesta, marca los bloques pasados y selecciona el resto',
    build: build,
    act: (bloc) => bloc
      ..add(const SuggestionsEvent.studyHoursChanged(12))
      ..add(const SuggestionsEvent.sportSessionsChanged(2))
      ..add(const SuggestionsEvent.generateRequested()),
    skip: 3,
    expect: () => [
      isA<SuggestionsState>()
          .having((s) => s.status, 'status', SuggestionsStatus.ready)
          .having((s) => s.expired, 'expired', {0})
          .having((s) => s.selected, 'selected', {1, 2}),
    ],
    verify: (_) => verify(
      () => suggest(weekStart: testMonday, studyHours: 12, sportSessions: 2),
    ).called(1),
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'la próxima semana pide el lunes siguiente',
    build: build,
    act: (bloc) => bloc
      ..add(const SuggestionsEvent.weekOffsetChanged(1))
      ..add(const SuggestionsEvent.generateRequested()),
    verify: (_) => verify(
      () => suggest(
        weekStart: DateTime(2025, 10, 20),
        studyHours: 10,
        sportSessions: 3,
      ),
    ).called(1),
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'muestra el error si la primera propuesta falla',
    setUp: () =>
        when(
          () => suggest(
            weekStart: any(named: 'weekStart'),
            studyHours: any(named: 'studyHours'),
            sportSessions: any(named: 'sportSessions'),
          ),
        ).thenAnswer(
          (_) async => const Failure(AppError.business('AI_QUOTA_EXCEEDED')),
        ),
    build: build,
    act: (bloc) => bloc.add(const SuggestionsEvent.generateRequested()),
    skip: 1,
    expect: () => [
      isA<SuggestionsState>()
          .having((s) => s.status, 'status', SuggestionsStatus.idle)
          .having(
            (s) => s.error,
            'error',
            const AppError.business('AI_QUOTA_EXCEEDED'),
          ),
    ],
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'los bloques pasados no se pueden seleccionar',
    build: build,
    seed: () => SuggestionsState(
      currentWeek: testMonday,
      status: SuggestionsStatus.ready,
      suggestion: suggestion,
      expired: const {0},
      selected: const {1, 2},
    ),
    act: (bloc) => bloc
      ..add(const SuggestionsEvent.blockToggled(0))
      ..add(const SuggestionsEvent.blockToggled(1))
      ..add(const SuggestionsEvent.allToggled(true)),
    expect: () => [
      isA<SuggestionsState>().having((s) => s.selected, 'selected', {2}),
      isA<SuggestionsState>().having((s) => s.selected, 'selected', {1, 2}),
    ],
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'aceptar crea los seleccionados y deja los que fallaron',
    setUp: () {
      when(() => create(any())).thenAnswer((invocation) async {
        final draft = invocation.positionalArguments.first as BlockDraft;
        return draft.type == BlockType.sport
            ? const Failure(AppError.business('BLOCK_IN_PAST'))
            : Success(BlockChange(block: block()));
      });
    },
    build: build,
    seed: () => SuggestionsState(
      currentWeek: testMonday,
      status: SuggestionsStatus.ready,
      suggestion: suggestion,
      expired: const {0},
      selected: const {1, 2},
    ),
    act: (bloc) => bloc.add(const SuggestionsEvent.acceptRequested()),
    skip: 1,
    expect: () => [
      isA<SuggestionsState>()
          .having((s) => s.suggestion?.blocks, 'remaining', [past, future2])
          .having((s) => s.selected, 'selected', isEmpty)
          .having(
            (s) => s.notice,
            'notice',
            const SuggestionsNotice.accepted(
              created: 1,
              failed: 1,
              firstError: AppError.business('BLOCK_IN_PAST'),
            ),
          ),
    ],
    verify: (_) => verify(() => create(any())).called(2),
  );
}
