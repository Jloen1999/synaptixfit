import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/wod.dart';
import 'package:synaptixfit/domain/use_cases/training/create_wod_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_wod_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_wod_board_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_wod_marks_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_wod_templates_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_wod_result_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/update_wod_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/wod_editor/bloc/wod_editor_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/wod_home/bloc/wod_home_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/wod_live/bloc/wod_live_bloc.dart';

class _Board extends Mock implements GetWodBoardUseCaseContract {}

class _Templates extends Mock implements ListWodTemplatesUseCaseContract {}

class _Marks extends Mock implements ListWodMarksUseCaseContract {}

class _Save extends Mock implements SaveWodResultUseCaseContract {}

class _Create extends Mock implements CreateWodUseCaseContract {}

class _Update extends Mock implements UpdateWodUseCaseContract {}

class _Delete extends Mock implements DeleteWodUseCaseContract {}

const _template = Wod(
  templateCode: 'TWELVE_NONSTOP',
  format: WodFormat.amrap,
  timeCapSeconds: 720,
  movements: [WodMovement(code: 'BURPEE', quantity: 5)],
);

const _mine = Wod(
  id: 'w1',
  title: 'Lunes',
  format: WodFormat.forTime,
  timeCapSeconds: 600,
  rounds: 3,
  movements: [WodMovement(name: 'Sentadillas', quantity: 20)],
);

const _draft = WodResultDraft(division: WodDivision.rx, value: 540);

WodMark _mark({bool best = true}) => WodMark(
  result: WodResult(
    id: 'r1',
    wodId: 'w1',
    division: WodDivision.rx,
    scoreType: WodScoreType.time,
    value: 540,
    performedAt: DateTime(2026, 11, 28, 18),
  ),
  title: 'Lunes',
  format: WodFormat.forTime,
  best: best,
);

/// Blocs del apartado WOD (ADR 0069): la pizarra, el editor y el cronómetro.
void main() {
  const network = AppError.network();

  setUpAll(() {
    registerFallbackValue(_mine);
    registerFallbackValue(_draft);
  });

  group('WodHomeBloc', () {
    late _Board board;
    late _Templates templates;
    late _Marks marks;
    late _Save save;

    WodHomeBloc build() => WodHomeBloc(
      getBoard: board,
      listTemplates: templates,
      listMarks: marks,
      saveResult: save,
    );

    setUp(() {
      board = _Board();
      templates = _Templates();
      marks = _Marks();
      save = _Save();
      when(() => board(templateCode: any(named: 'templateCode'))).thenAnswer(
        (_) async =>
            const Result.success(WodBoard(wod: _template, example: true)),
      );
      when(
        () => templates(),
      ).thenAnswer((_) async => const Result.success([_template]));
      when(() => marks()).thenAnswer((_) async => const Result.success([]));
    });

    blocTest<WodHomeBloc, WodHomeState>(
      'carga la pizarra de ejemplo, las plantillas y las marcas',
      build: build,
      act: (bloc) => bloc.add(const WodHomeEvent.started()),
      verify: (bloc) {
        expect(bloc.state.status, WodHomeStatus.ready);
        expect(bloc.state.board!.example, isTrue);
        expect(bloc.state.templates, [_template]);
        expect(bloc.state.marks, isEmpty);
        verify(() => board(templateCode: null)).called(1);
      },
    );

    blocTest<WodHomeBloc, WodHomeState>(
      'sin pizarra, enseña el error con reintento',
      setUp: () => when(
        () => board(templateCode: any(named: 'templateCode')),
      ).thenAnswer((_) async => const Result.failure(network)),
      build: build,
      act: (bloc) => bloc.add(const WodHomeEvent.started()),
      verify: (bloc) {
        expect(bloc.state.status, WodHomeStatus.failure);
        expect(bloc.state.error, network);
      },
    );

    blocTest<WodHomeBloc, WodHomeState>(
      'cambiar de plantilla la pide al servidor; Rx o Adaptado no pide nada',
      build: build,
      act: (bloc) => bloc
        ..add(const WodHomeEvent.started())
        ..add(const WodHomeEvent.templateChosen('LONG_LIST'))
        ..add(const WodHomeEvent.divisionChanged(WodDivision.scaled)),
      verify: (bloc) {
        expect(bloc.state.templateCode, 'LONG_LIST');
        expect(bloc.state.division, WodDivision.scaled);
        verify(() => board(templateCode: 'LONG_LIST')).called(1);
        verify(() => board(templateCode: null)).called(1);
      },
    );

    blocTest<WodHomeBloc, WodHomeState>(
      'apuntar una marca la guarda, la anuncia y vuelve a leer mi WOD',
      setUp: () => when(
        () => save(any(), any()),
      ).thenAnswer((_) async => Result.success(_mark())),
      build: build,
      seed: () => const WodHomeState(
        status: WodHomeStatus.ready,
        board: WodBoard(wod: _template, example: true),
        templateCode: 'TWELVE_NONSTOP',
      ),
      act: (bloc) =>
          bloc.add(const WodHomeEvent.resultSubmitted(_template, _draft)),
      verify: (bloc) {
        expect(bloc.state.saving, isFalse);
        expect(bloc.state.saved!.best, isTrue);
        // La plantilla ya es mi WOD de hoy: no se vuelve a pedir de ejemplo.
        expect(bloc.state.templateCode, isNull);
        verify(() => save(_template, _draft)).called(1);
        verify(() => board(templateCode: null)).called(1);
      },
    );

    blocTest<WodHomeBloc, WodHomeState>(
      'si guardar falla, avisa una vez y la pizarra sigue',
      setUp: () => when(
        () => save(any(), any()),
      ).thenAnswer((_) async => const Result.failure(network)),
      build: build,
      seed: () => const WodHomeState(
        status: WodHomeStatus.ready,
        board: WodBoard(wod: _mine),
      ),
      act: (bloc) =>
          bloc.add(const WodHomeEvent.resultSubmitted(_mine, _draft)),
      expect: () => [
        isA<WodHomeState>().having((s) => s.saving, 'saving', isTrue),
        isA<WodHomeState>()
            .having((s) => s.saving, 'saving', isFalse)
            .having((s) => s.actionError, 'actionError', network),
        isA<WodHomeState>().having((s) => s.actionError, 'error', isNull),
      ],
      verify: (bloc) => expect(bloc.state.board!.wod, _mine),
    );
  });

  group('WodEditorBloc', () {
    late _Create create;
    late _Update update;
    late _Delete delete;

    setUp(() {
      create = _Create();
      update = _Update();
      delete = _Delete();
      when(
        () => create(any()),
      ).thenAnswer((_) async => const Result.success(_mine));
      when(
        () => update(any()),
      ).thenAnswer((_) async => const Result.success(_mine));
      when(
        () => delete(any()),
      ).thenAnswer((_) async => const Result.success(unit));
    });

    WodEditorBloc build() =>
        WodEditorBloc(create: create, update: update, delete: delete);

    blocTest<WodEditorBloc, WodEditorState>(
      'sin id crea (también desde una plantilla); con id cambia',
      build: build,
      act: (bloc) => bloc.add(const WodEditorEvent.saveRequested(_template)),
      verify: (bloc) {
        expect(bloc.state.outcome, WodEditorOutcome.saved);
        verify(() => create(_template)).called(1);
        verifyNever(() => update(any()));
      },
    );

    blocTest<WodEditorBloc, WodEditorState>(
      'cambiar mi WOD',
      build: build,
      act: (bloc) => bloc.add(const WodEditorEvent.saveRequested(_mine)),
      verify: (bloc) {
        verify(() => update(_mine)).called(1);
        verifyNever(() => create(any()));
      },
    );

    blocTest<WodEditorBloc, WodEditorState>(
      'eliminar sale con su aviso; si falla, se queda con el error',
      setUp: () => when(
        () => delete('w2'),
      ).thenAnswer((_) async => const Result.failure(network)),
      build: build,
      act: (bloc) => bloc
        ..add(const WodEditorEvent.deleteRequested('w2'))
        ..add(const WodEditorEvent.deleteRequested('w1')),
      verify: (bloc) => expect(bloc.state.outcome, WodEditorOutcome.deleted),
    );
  });

  group('WodLiveBloc', () {
    late _Save save;
    late DateTime now;

    setUp(() {
      save = _Save();
      now = DateTime(2026, 11, 28, 18);
      when(
        () => save(any(), any()),
      ).thenAnswer((_) async => Result.success(_mark()));
    });

    // Tics muy lejanos: el reloj lo mueve la prueba con `now` y `ticked`.
    WodLiveBloc build() => WodLiveBloc(
      saveResult: save,
      now: () => now,
      tick: const Duration(days: 1),
    );

    void advance(int seconds) => now = now.add(Duration(seconds: seconds));

    blocTest<WodLiveBloc, WodLiveState>(
      'las pausas no cuentan y «Terminar» se queda con lo activo',
      build: build,
      act: (bloc) async {
        bloc.add(const WodLiveEvent.started(_mine, WodDivision.scaled));
        await Future<void>.delayed(Duration.zero);
        advance(90);
        bloc.add(const WodLiveEvent.ticked());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.elapsedSeconds, 90);
        expect(bloc.state.tick!.clockSeconds, 90);

        bloc.add(const WodLiveEvent.pauseToggled());
        await Future<void>.delayed(Duration.zero);
        advance(300);
        // En pausa un tic no mueve nada.
        bloc.add(const WodLiveEvent.ticked());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, WodLiveStatus.paused);
        expect(bloc.state.elapsedSeconds, 90);

        bloc.add(const WodLiveEvent.pauseToggled());
        await Future<void>.delayed(Duration.zero);
        advance(30);
        bloc.add(const WodLiveEvent.finishRequested());
      },
      verify: (bloc) {
        expect(bloc.state.status, WodLiveStatus.finished);
        expect(bloc.state.elapsedSeconds, 120);
        expect(bloc.state.timeUp, isFalse);
        expect(bloc.state.division, WodDivision.scaled);
        expect(bloc.state.inProgress, isTrue);
      },
    );

    blocTest<WodLiveBloc, WodLiveState>(
      'al acabarse el tiempo termina solo y no deja seguir',
      build: build,
      act: (bloc) async {
        bloc.add(const WodLiveEvent.started(_template, WodDivision.rx));
        await Future<void>.delayed(Duration.zero);
        advance(1000);
        bloc
          ..add(const WodLiveEvent.ticked())
          ..add(const WodLiveEvent.resumed());
      },
      verify: (bloc) {
        expect(bloc.state.status, WodLiveStatus.finished);
        expect(bloc.state.timeUp, isTrue);
        expect(bloc.state.elapsedSeconds, 720);
        expect(bloc.state.tick!.done, isTrue);
      },
    );

    blocTest<WodLiveBloc, WodLiveState>(
      'cerrar la hoja sin guardar vuelve en pausa; guardar deja la marca',
      build: build,
      act: (bloc) async {
        bloc.add(const WodLiveEvent.started(_mine, WodDivision.rx));
        await Future<void>.delayed(Duration.zero);
        advance(200);
        bloc
          ..add(const WodLiveEvent.finishRequested())
          ..add(const WodLiveEvent.resumed());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, WodLiveStatus.paused);
        expect(bloc.state.elapsedSeconds, 200);
        bloc
          ..add(const WodLiveEvent.finishRequested())
          ..add(const WodLiveEvent.resultSubmitted(_mine, _draft));
      },
      verify: (bloc) {
        expect(bloc.state.saved, isNotNull);
        expect(bloc.state.inProgress, isFalse);
        verify(() => save(_mine, _draft)).called(1);
      },
    );

    blocTest<WodLiveBloc, WodLiveState>(
      'si guardar falla, el WOD sigue terminado para reintentar',
      setUp: () => when(
        () => save(any(), any()),
      ).thenAnswer((_) async => const Result.failure(network)),
      build: build,
      act: (bloc) => bloc
        ..add(const WodLiveEvent.started(_mine, WodDivision.rx))
        ..add(const WodLiveEvent.finishRequested())
        ..add(const WodLiveEvent.resultSubmitted(_mine, _draft)),
      verify: (bloc) {
        expect(bloc.state.error, network);
        expect(bloc.state.saved, isNull);
        expect(bloc.state.status, WodLiveStatus.finished);
      },
    );
  });
}
