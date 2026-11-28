import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/routine_template.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_template_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/use_routine_template_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/routine_template_detail/bloc/routine_template_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/routine_template_detail/page/routine_template_detail_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'training_fixtures.dart';

/// Detalle de una plantilla: se lee con sus días y ejercicios y se usa con el
/// mismo alta que la lista.

const _detail = RoutineTemplateDetail(
  summary: RoutineTemplate(
    id: 't1',
    code: 'piernas',
    name: 'Piernas y glúteos para empezar',
    minutes: 45,
    weeks: 4,
    daysPerWeek: 3,
    runDays: [TemplateRunDay(dayNumber: 3, workoutCode: 'C25K_W1')],
  ),
  days: [
    TemplateDay(
      dayNumber: 1,
      name: 'Piernas',
      exercises: [
        TemplateExercise(
          exerciseId: 'e1',
          name: 'Sentadilla con barra',
          sets: 3,
          reps: 8,
          repMin: 8,
          repMax: 12,
          restSeconds: 90,
        ),
        TemplateExercise(
          exerciseId: 'e2',
          name: 'Plancha',
          sets: 2,
          reps: 0,
          holdSeconds: 30,
          restSeconds: 45,
        ),
      ],
    ),
  ],
  runDays: [
    TemplateRunDay(
      dayNumber: 3,
      workoutCode: 'C25K_W1',
      workoutName: 'Semana 1 · andar y correr',
    ),
  ],
);

final _routine = TrainingFixtures.routine();

class _Get implements GetRoutineTemplateUseCaseContract {
  _Get(this.result);

  AppResult<RoutineTemplateDetail> result;
  int calls = 0;

  @override
  Future<AppResult<RoutineTemplateDetail>> call(String templateId) async {
    calls++;
    return result;
  }
}

class _Use implements UseRoutineTemplateUseCaseContract {
  final used = <String>[];

  @override
  Future<AppResult<Routine>> call(String templateId) async {
    used.add(templateId);
    return Success(_routine);
  }
}

class _MockBloc
    extends MockBloc<RoutineTemplateDetailEvent, RoutineTemplateDetailState>
    implements RoutineTemplateDetailBloc {}

void main() {
  group('RoutineTemplateDetailBloc', () {
    blocTest<RoutineTemplateDetailBloc, RoutineTemplateDetailState>(
      'carga el detalle de la plantilla',
      build: () => RoutineTemplateDetailBloc(
        get: _Get(const Success(_detail)),
        use: _Use(),
      ),
      act: (bloc) => bloc.add(const RoutineTemplateDetailEvent.started('t1')),
      expect: () => const [
        RoutineTemplateDetailState(templateId: 't1'),
        RoutineTemplateDetailState(
          templateId: 't1',
          status: TemplateDetailStatus.ready,
          detail: _detail,
        ),
      ],
    );

    blocTest<RoutineTemplateDetailBloc, RoutineTemplateDetailState>(
      'si falla, guarda el error para «Reintentar»',
      build: () => RoutineTemplateDetailBloc(
        get: _Get(const Failure(AppError.network())),
        use: _Use(),
      ),
      act: (bloc) => bloc.add(const RoutineTemplateDetailEvent.started('t1')),
      skip: 1,
      expect: () => const [
        RoutineTemplateDetailState(
          templateId: 't1',
          status: TemplateDetailStatus.failure,
          error: AppError.network(),
        ),
      ],
    );

    final use = _Use();
    blocTest<RoutineTemplateDetailBloc, RoutineTemplateDetailState>(
      '«Usar esta plantilla» crea la rutina con su id y lo avisa una vez',
      build: () =>
          RoutineTemplateDetailBloc(get: _Get(const Success(_detail)), use: use),
      seed: () => const RoutineTemplateDetailState(
        templateId: 't1',
        status: TemplateDetailStatus.ready,
        detail: _detail,
      ),
      act: (bloc) => bloc.add(const RoutineTemplateDetailEvent.used()),
      expect: () => [
        const RoutineTemplateDetailState(
          templateId: 't1',
          status: TemplateDetailStatus.ready,
          detail: _detail,
          using: true,
        ),
        RoutineTemplateDetailState(
          templateId: 't1',
          status: TemplateDetailStatus.ready,
          detail: _detail,
          created: _routine,
        ),
        const RoutineTemplateDetailState(
          templateId: 't1',
          status: TemplateDetailStatus.ready,
          detail: _detail,
        ),
      ],
      verify: (_) => expect(use.used, ['t1']),
    );
  });

  group('RoutineTemplateDetailView', () {
    Future<void> pump(
      WidgetTester tester,
      RoutineTemplateDetailState state, {
      Size size = const Size(390, 1600),
      double scale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final bloc = _MockBloc();
      whenListen(bloc, const Stream<RoutineTemplateDetailState>.empty(),
          initialState: state);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: BlocProvider<RoutineTemplateDetailBloc>.value(
            value: bloc,
            child: const RoutineTemplateDetailView(),
          ),
        ),
      );
      await tester.pump();
    }

    const ready = RoutineTemplateDetailState(
      templateId: 't1',
      status: TemplateDetailStatus.ready,
      detail: _detail,
    );

    testWidgets('pinta los días con sus ejercicios, las carreras y una sola '
        'acción principal', (tester) async {
      await pump(tester, ready);
      expect(find.text('Sentadilla con barra'), findsOneWidget);
      expect(find.text('3 series · 8–12 reps · Descanso 90 s'), findsOneWidget);
      expect(find.text('2 series · 30 s · Descanso 45 s'), findsOneWidget);
      expect(find.text('Semana 1 · andar y correr'), findsOneWidget);
      expect(find.text('Usar esta plantilla'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('carga, error con «Reintentar» y vacío', (tester) async {
      await pump(tester, const RoutineTemplateDetailState(templateId: 't1'));
      expect(find.text('Usar esta plantilla'), findsNothing);

      await pump(
        tester,
        const RoutineTemplateDetailState(
          templateId: 't1',
          status: TemplateDetailStatus.failure,
          error: AppError.network(),
        ),
      );
      expect(find.text('Reintentar'), findsOneWidget);

      await pump(
        tester,
        RoutineTemplateDetailState(
          templateId: 't1',
          status: TemplateDetailStatus.ready,
          detail: _detail.copyWith(days: const [], runDays: const []),
        ),
      );
      expect(find.text('Esta plantilla aún no tiene ejercicios'), findsOneWidget);
      expect(find.text('Usar esta plantilla'), findsNothing);
    });

    testWidgets('a 320 px con el texto al 200 % no se desborda', (
      tester,
    ) async {
      await pump(tester, ready, size: const Size(320, 2400), scale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Sentadilla con barra'), findsOneWidget);
    });
  });
}
