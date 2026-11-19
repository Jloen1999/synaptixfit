import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/home_day_state.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/enums/today_intensity.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/domain/models/home/today_next.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/agenda_section.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/today_hero_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'home_fixtures.dart';

final _now = DateTime(2026, 11, 19, 10, 30);

HomeTodayEvent _block(
  String id,
  HomeEventType type,
  ItemTimeStatus status, {
  bool completed = false,
  int hour = 10,
  String? title,
  String? place,
  String? teacher,
}) => HomeTodayEvent(
  id: id,
  kind: HomeEventKind.block,
  type: type,
  title: title ?? 'Bloque $id',
  start: DateTime(2026, 11, 19, hour),
  end: DateTime(2026, 11, 19, hour + 1),
  completed: completed,
  status: status,
  place: place,
  teacher: teacher,
);

const _training = HomeNextTrainingDay(
  routineId: 'r1',
  routineName: 'Fuerza 3 días',
  dayId: 'd1',
  weekNumber: 1,
  dayNumber: 3,
  dayName: 'Pierna y empuje',
  inProgress: false,
  dueToday: true,
  exerciseCount: 6,
  estimatedMinutes: 45,
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<({List<TodayAction> actions, List<String> taps})> pump(
    WidgetTester tester, {
    List<HomeTodayEvent> events = const [],
    HomeTodaySummary summary = const HomeTodaySummary(),
    HomeNextTrainingDay? training,
    TodayIntensity? intensity,
    HomeNextDeadline? deadline,
    HomeUnfinishedSession? unfinished,
    double textScale = 1,
    ValueChanged<HomeTodayEvent>? onMarkDone,
    bool primaryElsewhere = false,
  }) async {
    final actions = <TodayAction>[];
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('es'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodayHeroCard(
              dashboard: homeDashboardFixture.copyWith(
                todayEvents: events,
                todaySummary: summary,
                nextTrainingDay: training,
                todayIntensity: intensity,
                nextDeadline: deadline,
                unfinishedSession: unfinished,
              ),
              focus: UsageFocus.both,
              now: _now,
              primaryElsewhere: primaryElsewhere,
              blockedBy: unfinished,
              onAction: actions.add,
              onMarkDone: onMarkDone,
              onStartTraining: () => taps.add('start'),
              onOpenTraining: () => taps.add('routine'),
              onOpenEvent: (e) => taps.add('event:${e.id}'),
              onOpenDeadline: () => taps.add('deadline'),
              onOpenAgenda: () => taps.add('agenda'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (actions: actions, taps: taps);
  }

  testWidgets('el entreno de hoy dice cuál es y «Empezar» va en su fila', (
    tester,
  ) async {
    final r = await pump(
      tester,
      training: _training,
      intensity: TodayIntensity.easy,
    );

    expect(find.text('Entreno de hoy · suave'), findsOneWidget);
    expect(find.text('Pierna y empuje'), findsOneWidget);
    expect(
      find.text('≈ 45 min · 6 ejercicios · Fuerza 3 días'),
      findsOneWidget,
    );
    // La intensidad ya no es una línea suelta («Hoy toca: …»).
    expect(find.textContaining('Hoy toca'), findsNothing);
    // Un solo botón destacado en «Tu día».
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.tap(find.text('Pierna y empuje'));
    expect(r.taps, ['start', 'routine']);
  });

  testWidgets('con una sesión a medias, «Empezar» se desactiva y dice qué '
      'hacer antes', (tester) async {
    final r = await pump(
      tester,
      training: _training,
      unfinished: HomeUnfinishedSession(
        sessionId: 's9',
        dayName: 'Pierna y empuje',
        dayNumber: 3,
        startedAt: DateTime(2026, 11, 18, 18, 10),
      ),
      primaryElsewhere: true,
    );

    expect(
      find.text('Primero guarda o descarta la del miércoles.'),
      findsOneWidget,
    );
    final start = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Empezar'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(start.onPressed, isNull);
    await tester.tap(find.text('Empezar'), warnIfMissed: false);
    expect(r.taps, isEmpty);
  });

  testWidgets('la clase de ahora dice hasta cuándo, el aula y el profesor y '
      'se abre al tocarla', (tester) async {
    final r = await pump(
      tester,
      events: [
        _block(
          'c1',
          HomeEventType.classSession,
          ItemTimeStatus.inProgress,
          title: 'Bases de datos',
          place: 'Aula 2.4',
          teacher: 'Ana Ruiz',
        ),
      ],
      summary: const HomeTodaySummary(spotlightEventId: 'c1'),
    );

    expect(find.text('Ahora · hasta las 11:00'), findsOneWidget);
    expect(find.text('Clase de Bases de datos'), findsOneWidget);
    expect(find.text('Aula 2.4 · Ana Ruiz'), findsOneWidget);
    // Una clase no lleva botón: se ve y se abre.
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.text('Clase de Bases de datos'));
    expect(r.taps, ['event:c1']);
  });

  testWidgets('un estudio siguiente ofrece concentrarse', (tester) async {
    final r = await pump(
      tester,
      events: [_block('s1', HomeEventType.study, ItemTimeStatus.upcoming)],
      summary: const HomeTodaySummary(
        total: 1,
        spotlightEventId: 's1',
        state: HomeDayState.pending,
      ),
    );

    expect(find.text('A continuación · a las 10:00'), findsOneWidget);
    await tester.tap(find.text('Concentrarme'));
    expect(r.actions, [TodayAction.focus]);
  });

  testWidgets('lo que pasó sin hacer se marca ahí mismo', (tester) async {
    final marked = <HomeTodayEvent>[];
    final missed = _block('m1', HomeEventType.study, ItemTimeStatus.missed);
    await pump(
      tester,
      events: [missed],
      summary: const HomeTodaySummary(
        total: 1,
        missed: 1,
        spotlightEventId: 'm1',
        state: HomeDayState.missedLeft,
      ),
      onMarkDone: marked.add,
    );

    expect(find.text('Sin hacer · era a las 10:00'), findsOneWidget);
    expect(find.textContaining('Has terminado'), findsNothing);
    await tester.tap(find.text('Marcar como hecho'));
    expect(marked, [missed]);
  });

  testWidgets('la entrega más cercana dice cuál y cuándo y abre esa entrega', (
    tester,
  ) async {
    final r = await pump(
      tester,
      deadline: HomeNextDeadline(
        id: 'x1',
        title: 'Parcial 1',
        type: DeadlineType.exam,
        dueAt: DateTime(2026, 11, 23, 9),
        subjectName: 'Cálculo',
      ),
    );

    expect(find.text('Examen · en 4 días'), findsOneWidget);
    expect(find.text('Parcial 1'), findsOneWidget);
    expect(find.text('Cálculo'), findsOneWidget);
    await tester.tap(find.text('Parcial 1'));
    expect(r.taps, ['deadline']);
  });

  testWidgets('«2 de 5 hechos» con su barra y «y N más» con forma de botón', (
    tester,
  ) async {
    final r = await pump(
      tester,
      events: [
        _block('1', HomeEventType.study, ItemTimeStatus.done, completed: true),
        _block('2', HomeEventType.study, ItemTimeStatus.upcoming, hour: 12),
        _block('3', HomeEventType.review, ItemTimeStatus.upcoming, hour: 14),
        _block('4', HomeEventType.personal, ItemTimeStatus.upcoming, hour: 16),
      ],
      summary: const HomeTodaySummary(
        done: 1,
        total: 4,
        spotlightEventId: '2',
        state: HomeDayState.pending,
      ),
    );

    expect(find.text('1 de 4 hechos'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel('Has hecho 1 de 4 eventos de hoy'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'y 2 más'), findsOneWidget);
    await tester.tap(find.text('y 2 más'));
    expect(r.taps, ['agenda']);
  });

  testWidgets('sin nada planificado, «Añadir al calendario» en un toque', (
    tester,
  ) async {
    final r = await pump(tester);

    expect(
      find.text('Aún no tienes nada planificado para hoy.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Añadir al calendario'));
    expect(r.actions, [TodayAction.addEvent]);
  });

  testWidgets('con todo hecho lo celebra', (tester) async {
    await pump(
      tester,
      events: [
        _block('1', HomeEventType.study, ItemTimeStatus.done, completed: true),
      ],
      summary: const HomeTodaySummary(
        done: 1,
        total: 1,
        state: HomeDayState.allDone,
      ),
    );

    expect(find.textContaining('Has terminado lo de hoy'), findsOneWidget);
  });

  testWidgets('con el texto al 200 % todo cabe y el botón baja de línea', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      training: _training,
      intensity: TodayIntensity.normal,
      events: [
        _block(
          'c1',
          HomeEventType.classSession,
          ItemTimeStatus.inProgress,
          title: 'Bases de datos',
          place: 'Aula 2.4',
          teacher: 'Ana Ruiz',
        ),
      ],
      summary: const HomeTodaySummary(spotlightEventId: 'c1'),
      deadline: HomeNextDeadline(
        id: 'x1',
        title: 'Parcial 1',
        type: DeadlineType.exam,
        dueAt: DateTime(2026, 11, 23, 9),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Empezar'), findsOneWidget);
    // La XP se ve en Progreso, no en Inicio (ADR 0038).
    expect(find.textContaining('XP'), findsNothing);
  });

  test('los títulos en mayúsculas se leen como texto normal', () {
    expect(
      readableEventTitle('AMPLIACIÓN DE MATEMÁTICAS'),
      'Ampliación de matemáticas',
    );
    expect(readableEventTitle('Tema 3: Límites'), 'Tema 3: Límites');
    expect(readableEventTitle('TFG'), 'TFG');
  });
}
