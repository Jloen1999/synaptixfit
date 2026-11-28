import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/models/training/routine_template.dart'
    hide TemplateDay;
import 'package:synaptixfit/domain/models/training/session.dart';
import 'package:synaptixfit/domain/models/training/session_history.dart';
import 'package:synaptixfit/domain/models/training/training_page.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_template_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_session_history_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_routine_templates_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/start_free_session_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/free_session_start/bloc/free_session_start_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_effect.dart';

import 'training_fixtures.dart';

/// «Sesión libre: cómo empezar» (ADR 0067): elegir varios ejercicios y
/// empezar con ellos, repetir un entreno o un día de plantilla.
class _Start implements StartFreeSessionUseCaseContract {
  final sources = <FreeSessionSource>[];
  AppError? fail;

  @override
  Future<AppResult<TrainingSession>> call(FreeSessionSource source) async {
    sources.add(source);
    final error = fail;
    return error == null ? Success(TrainingFixtures.session()) : Failure(error);
  }
}

class _History implements GetSessionHistoryUseCaseContract {
  @override
  Future<AppResult<TrainingPage<SessionHistoryEntry>>> call({
    int page = 0,
    int size = 20,
  }) async => Success(
    TrainingPage(
      items: [SessionHistoryEntry(session: TrainingFixtures.session())],
      page: 0,
      totalPages: 1,
      totalItems: 1,
    ),
  );
}

class _Templates implements ListRoutineTemplatesUseCaseContract {
  @override
  Future<AppResult<List<RoutineTemplate>>> call() async => const Success([]);
}

class _Template implements GetRoutineTemplateUseCaseContract {
  @override
  Future<AppResult<RoutineTemplateDetail>> call(String templateId) async =>
      const Failure(AppError.network());
}

Exercise _exercise(String id) => Exercise(
  id: id,
  name: 'Ejercicio $id',
  difficulty: ExerciseDifficulty.beginner,
  modality: Modality.strength,
  met: 5,
);

void main() {
  late _Start start;

  FreeSessionStartBloc build() => FreeSessionStartBloc(
    start: start,
    getHistory: _History(),
    listTemplates: _Templates(),
    getTemplate: _Template(),
  );

  setUp(() => start = _Start());

  blocTest<FreeSessionStartBloc, FreeSessionStartState>(
    'lee los últimos entrenos para «Repetir un entreno»',
    build: build,
    act: (b) => b.add(const FreeSessionStartEvent.started()),
    verify: (b) {
      expect(b.state.recentLoaded, isTrue);
      expect(b.state.recent, hasLength(1));
    },
  );

  blocTest<FreeSessionStartBloc, FreeSessionStartState>(
    'elige varios a la vez, en orden, y empieza con ellos',
    build: build,
    act: (b) => b
      ..add(FreeSessionStartEvent.exerciseToggled(_exercise('a')))
      ..add(FreeSessionStartEvent.exerciseToggled(_exercise('b')))
      ..add(FreeSessionStartEvent.exerciseToggled(_exercise('c')))
      ..add(FreeSessionStartEvent.exerciseToggled(_exercise('b')))
      ..add(const FreeSessionStartEvent.startRequested()),
    expect: () => [
      isA<FreeSessionStartState>(),
      isA<FreeSessionStartState>(),
      isA<FreeSessionStartState>(),
      isA<FreeSessionStartState>().having(
        (s) => s.chosen.map((e) => e.id),
        'elegidos',
        ['a', 'c'],
      ),
      isA<FreeSessionStartState>().having((s) => s.starting, 'empieza', true),
      isA<FreeSessionStartState>().having((s) => s.starting, 'empieza', false),
      isA<FreeSessionStartState>().having(
        (s) => s.effect,
        'abre la sesión',
        const TrainingEffect.openSession('s1'),
      ),
      isA<FreeSessionStartState>().having((s) => s.effect, 'efecto', null),
    ],
    verify: (_) {
      final source = start.sources.single as ChosenExercises;
      expect(source.exerciseIds, ['a', 'c']);
    },
  );

  blocTest<FreeSessionStartBloc, FreeSessionStartState>(
    'repetir un entreno y un día de plantilla van tal cual al servidor',
    build: build,
    act: (b) async {
      b.add(const FreeSessionStartEvent.startRequested(RepeatSession('old')));
      await Future<void>.delayed(Duration.zero);
      b.add(const FreeSessionStartEvent.startRequested(TemplateDay('t1', 3)));
    },
    verify: (_) {
      expect((start.sources.first as RepeatSession).sessionId, 'old');
      final day = start.sources.last as TemplateDay;
      expect((day.templateId, day.dayNumber), ('t1', 3));
    },
  );

  blocTest<FreeSessionStartBloc, FreeSessionStartState>(
    'si falla, lo dice y deja volver a intentarlo',
    build: build,
    setUp: () => start.fail = const AppError.network(),
    act: (b) => b.add(const FreeSessionStartEvent.startRequested()),
    verify: (b) {
      expect(b.state.starting, isFalse);
      expect(b.state.effect, isNull);
    },
  );

  blocTest<FreeSessionStartBloc, FreeSessionStartState>(
    'abrir una plantilla que no llega deja el error para reintentar',
    build: build,
    act: (b) => b.add(const FreeSessionStartEvent.templateOpened('t1')),
    verify: (b) {
      expect(b.state.openTemplateId, 't1');
      expect(b.state.templatesError, const AppError.network());
    },
  );
}
