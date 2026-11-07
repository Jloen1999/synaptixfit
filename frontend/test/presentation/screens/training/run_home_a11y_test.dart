import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/training/run.dart';
import 'package:synaptixfit/domain/models/training/sport_activity.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/run_home/bloc/run_home_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/run_home/page/run_home_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _MockRunHomeBloc extends MockBloc<RunHomeEvent, RunHomeState>
    implements RunHomeBloc {}

/// Pantalla «Correr» (ADR 0037) con datos y en vacío: objetivos táctiles,
/// etiquetas, contraste, texto al 200 % y botones que dicen de qué entreno
/// son (no «Borrar entreno» repetido).
void main() {
  late _MockRunHomeBloc bloc;

  const workout = RunWorkout(
    id: 'w1',
    name: 'Series 6 × 800 m',
    groups: [
      RunStepGroup(
        repeat: 6,
        steps: [
          RunStep(
            type: RunStepType.run,
            measure: RunMeasure.distance,
            value: 800,
          ),
          RunStep(
            type: RunStepType.recover,
            measure: RunMeasure.time,
            value: 120,
          ),
        ],
      ),
    ],
    estimatedSeconds: 2400,
  );

  final full = RunHomeState(
    status: RunHomeStatus.ready,
    week: RunWeek(
      weekStart: DateTime(2026, 11, 2),
      distanceMeters: 12400,
      movingSeconds: 4200,
      elevationGainMeters: 85,
      outings: 3,
      dailyDistanceMeters: const [5000, 0, 3200, 0, 4200, 0, 0],
    ),
    activities: [
      SportActivity(
        blockId: 'b1',
        start: DateTime(2026, 11, 6, 18),
        minutes: 30,
        kind: ActivityKind.run,
        distanceMeters: 5000,
        paceSecondsPerKm: 360,
        effort: 6,
        source: ActivitySource.gps,
      ),
    ],
    totalActivities: 1,
    workouts: [workout],
    planned: [
      PlannedRun(
        blockId: 'e1',
        workoutId: 'w1',
        workoutName: 'Series 6 × 800 m',
        start: DateTime(2026, 11, 9, 18),
        end: DateTime(2026, 11, 9, 18, 45),
      ),
    ],
  );

  const empty = RunHomeState(status: RunHomeStatus.ready);

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    bloc = _MockRunHomeBloc();
    getIt.registerFactory<RunHomeBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<RunHomeBloc>());

  Future<void> pump(
    WidgetTester tester,
    RunHomeState state, {
    ThemeData? theme,
    double scale = 1,
  }) async {
    when(() => bloc.state).thenReturn(state);
    tester.view.physicalSize = Size(360, 2400 * scale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
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
        home: const RunHomePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('los botones de cada entreno dicen de cuál son', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, full);
    expect(find.byTooltip('Borrar «Series 6 × 800 m»'), findsOneWidget);
    expect(find.byTooltip('Cambiar «Series 6 × 800 m»'), findsOneWidget);
    // «Empezar» del evento del calendario y del entreno: con su nombre.
    expect(
      find.bySemanticsLabel(RegExp('Empezar: Series 6 × 800 m')),
      findsNWidgets(2),
    );
    handle.dispose();
  });

  for (final (name, state) in [('con datos', full), ('en vacío', empty)]) {
    for (final (mode, theme) in [
      ('claro', AppTheme.light),
      ('oscuro', AppTheme.dark),
    ]) {
      testWidgets('cumple las guías de accesibilidad $name, tema $mode', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, state, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // Como en el resto de pantallas: la guía de contraste de Flutter da
        // falsos fallos en el tema claro (mide píxeles con la fuente de
        // test); el contraste real de los tokens lo prueba contrast_test.
        if (theme == AppTheme.dark) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        handle.dispose();
      });
    }

    testWidgets('$name, con el texto al 200 % no se desborda', (tester) async {
      await pump(tester, state, scale: 2);
      expect(tester.takeException(), isNull);
    });
  }
}
