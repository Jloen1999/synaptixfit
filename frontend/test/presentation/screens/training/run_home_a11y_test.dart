import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
import 'package:synaptixfit/presentation/screens/training/run_home/page/sport_grid.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/run_map.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

class _MockRunHomeBloc extends MockBloc<RunHomeEvent, RunHomeState>
    implements RunHomeBloc {}

/// Pantalla «Correr» (ADR 0037) con datos y en vacío: objetivos táctiles,
/// etiquetas, contraste, texto al 200 % y botones que dicen de qué entreno
/// son (no «Eliminar entreno» repetido).
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

  // Un entreno hoy y dos más adelante (ADR 0055).
  final now = DateTime.now();
  // A última hora del día: si fuera a una hora fija ya pasada (p. ej. 23:00 y la prueba corre a las 23:46),
  // «Hoy toca» lo trataría como pasado y la prueba fallaría según la hora.
  final today = DateTime(now.year, now.month, now.day, 23, 59);
  final withToday = full.copyWith(
    planned: [
      PlannedRun(
        blockId: 'hoy',
        workoutId: 'w1',
        workoutName: 'Rodaje suave',
        start: today,
        end: today.add(const Duration(minutes: 30)),
      ),
      for (final (i, d) in [(1, 2), (2, 4)])
        PlannedRun(
          blockId: 'p$i',
          workoutId: 'w1',
          workoutName: 'Series $i',
          start: today.add(Duration(days: d)),
          end: today.add(Duration(days: d, minutes: 45)),
        ),
    ],
  );

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
    // Eliminar no ocupa sitio en la fila: se desliza (con «Deshacer») y el
    // lector tiene la misma acción con el nombre del entreno (§4).
    expect(find.byTooltip('Eliminar «Series 6 × 800 m»'), findsNothing);
    expect(
      tester.getSemantics(find.byType(AppSwipeToDelete).first),
      isSemantics(
        customActions: const [
          CustomSemanticsAction(label: 'Eliminar «Series 6 × 800 m»'),
        ],
      ),
    );
    expect(find.byTooltip('Cambiar «Series 6 × 800 m»'), findsOneWidget);
    // «Empezar» del evento del calendario y del entreno: con su nombre.
    expect(
      find.bySemanticsLabel(RegExp('Empezar: Series 6 × 800 m')),
      findsNWidgets(2),
    );
    handle.dispose();
  });

  testWidgets('hoy toca arriba, la rejilla y «Próximo» en una línea', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, withToday);
    expect(find.text('Rodaje suave'), findsOneWidget);
    expect(find.text('Salir a correr'), findsOneWidget);
    // «Apuntar actividad» ya no es un atajo suelto: cada deporte lleva el suyo.
    expect(find.bySemanticsLabel('Apuntar actividad'), findsNothing);
    expect(find.bySemanticsLabel('Correr libre'), findsNothing);
    expect(find.byType(SportGrid), findsOneWidget);
    expect(find.byType(RunMap), findsNothing);
    // «Próximo» enseña uno y despliega el resto.
    expect(find.text('Series 1'), findsOneWidget);
    expect(find.text('Series 2'), findsNothing);
    await tester.tap(find.text('Ver todos (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Series 2'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('sin nada hoy manda la rejilla: siete deportes y ningún botón '
      'relleno', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, empty);
    expect(find.text('Elige un deporte'), findsOneWidget);
    for (final name in [
      'Correr, andar o bici',
      'Fútbol',
      'Pádel',
      'Natación',
      'Baloncesto',
      'Tenis',
      'Otro deporte',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    // Sin tarjeta de bici aparte y sin «Salir a correr» suelto.
    expect(find.text('Bici'), findsNothing);
    expect(find.text('Salir a correr'), findsNothing);
    // Elegir el deporte es la acción: la rejilla no lleva botón relleno.
    expect(
      find.descendant(
        of: find.byType(SportGrid),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
      findsNothing,
    );
    // Cada tarjeta es un botón con su nombre y su línea corta.
    expect(
      tester.getSemantics(find.byKey(const ValueKey('sport-PADEL'))),
      isSemantics(label: 'Pádel\nPartido o entreno', isButton: true),
    );
    // «Crear entreno guiado» sigue a mano, en la cabecera de su lista.
    expect(find.text('Crear entreno guiado'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a 320 px la rejilla cabe sin desbordarse', (tester) async {
    when(() => bloc.state).thenReturn(empty);
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
        home: const RunHomePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // De dos en dos: fútbol y pádel comparten fila.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('sport-FOOTBALL'))).dy,
      tester.getTopLeft(find.byKey(const ValueKey('sport-PADEL'))).dy,
    );
  });

  for (final (name, state) in [
    ('con datos', full),
    ('en vacío', empty),
    ('con entreno hoy', withToday),
  ]) {
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
