import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/today_intensity.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/home_day_state.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/domain/models/home/today_next.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/agenda_section.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/today_hero_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'home_fixtures.dart';

HomeTodayEvent _block(
  String id,
  HomeEventType type,
  ItemTimeStatus status, {
  bool completed = false,
  int hour = 10,
  String? routineDayId,
}) => HomeTodayEvent(
  id: id,
  kind: HomeEventKind.block,
  type: type,
  title: 'Bloque $id',
  start: DateTime(2026, 10, 31, hour),
  end: DateTime(2026, 10, 31, hour + 1),
  completed: completed,
  status: status,
  routineId: routineDayId == null ? null : 'r1',
  routineDayId: routineDayId,
);

/// Un solo evento pendiente, el «1».
const _pendingOne = HomeTodaySummary(
  total: 1,
  nextEventId: '1',
  state: HomeDayState.pending,
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<List<TodayAction>> pump(
    WidgetTester tester,
    List<HomeTodayEvent> events, {
    HomeTodaySummary summary = const HomeTodaySummary(),
    double textScale = 1,
    TodayIntensity? intensity,
    ValueChanged<HomeTodayEvent>? onMarkDone,
    VoidCallback? onOpenAgenda,
  }) async {
    final actions = <TodayAction>[];
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
                todayIntensity: intensity,
              ),
              focus: UsageFocus.both,
              onAction: actions.add,
              onMarkDone: onMarkDone,
              onOpenAgenda: onOpenAgenda,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return actions;
  }

  group('lo que toca lo dice el servidor (ADR 0050)', () {
    HomeDashboard day(List<HomeTodayEvent> events, HomeTodaySummary summary) =>
        homeDashboardFixture.copyWith(
          todayEvents: events,
          todaySummary: summary,
        );

    test('el evento destacado es el que manda el resumen', () {
      final dashboard = day(
        [
          _block('1', HomeEventType.study, ItemTimeStatus.missed),
          _block('2', HomeEventType.study, ItemTimeStatus.inProgress),
        ],
        const HomeTodaySummary(
          total: 2,
          missed: 1,
          nextEventId: '2',
          state: HomeDayState.pending,
        ),
      );

      expect(dashboard.nextUp?.id, '2');
      expect(dashboard.todayAction, TodayAction.focus);
    });

    test('lo que quedó sin hacer se marca; un día de rutina se empieza', () {
      const missedLeft = HomeTodaySummary(
        total: 1,
        missed: 1,
        nextEventId: '1',
        state: HomeDayState.missedLeft,
      );
      final study = _block('1', HomeEventType.study, ItemTimeStatus.missed);
      final routine = _block(
        '1',
        HomeEventType.sport,
        ItemTimeStatus.missed,
        routineDayId: 'd1',
      );

      expect(TodayAction.of(missedLeft, study), TodayAction.markDone);
      expect(TodayAction.of(missedLeft, routine), TodayAction.train);
    });

    test('una entrega de hoy se marca; ya marcada no hay botón', () {
      const pending = HomeTodaySummary(
        total: 1,
        nextEventId: 'd',
        state: HomeDayState.pending,
      );
      final delivery = HomeTodayEvent(
        id: 'd',
        kind: HomeEventKind.deadline,
        type: HomeEventType.delivery,
        title: 'Práctica',
        start: DateTime(2026, 10, 31, 23, 59),
        completed: false,
      );

      expect(TodayAction.of(pending, delivery), TodayAction.markDone);
      expect(
        TodayAction.of(pending, delivery.copyWith(completed: true)),
        isNull,
      );
      expect(
        TodayAction.of(
          const HomeTodaySummary(
            done: 1,
            total: 1,
            state: HomeDayState.allDone,
          ),
          null,
        ),
        TodayAction.addEvent,
      );
    });
  });

  testWidgets('«Hoy toca» sale solo si el servidor lo manda (ADR 0042)', (
    tester,
  ) async {
    await pump(tester, const []);
    expect(find.textContaining('Hoy toca'), findsNothing);

    await pump(tester, const [], intensity: TodayIntensity.easy);
    expect(find.text('Hoy toca: entreno suave'), findsOneWidget);
    // El porqué, solo al tocar el «?».
    expect(find.textContaining('menos series'), findsNothing);
    await tester.tap(find.byTooltip('Qué es «Hoy toca»'));
    await tester.pumpAndSettle();
    expect(find.textContaining('menos series'), findsOneWidget);
  });

  testWidgets('un bloque de estudio en curso ofrece concentrarse', (
    tester,
  ) async {
    final actions = await pump(
      tester,
      [
        _block('1', HomeEventType.study, ItemTimeStatus.done, completed: true),
        _block('2', HomeEventType.study, ItemTimeStatus.inProgress, hour: 12),
      ],
      summary: const HomeTodaySummary(
        done: 1,
        total: 2,
        nextEventId: '2',
        state: HomeDayState.pending,
      ),
    );

    expect(find.text('Ahora'), findsOneWidget);
    expect(find.text('Bloque 2'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Has hecho 1 de 2 eventos de hoy'),
      findsOneWidget,
    );
    await tester.tap(find.text('Concentrarme'));
    expect(actions, [TodayAction.focus]);
  });

  testWidgets('sin nada planificado, «Añadir al calendario» en un toque', (
    tester,
  ) async {
    final actions = await pump(tester, const []);

    expect(
      find.text('Aún no tienes nada planificado para hoy.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Añadir al calendario'));
    expect(actions, [TodayAction.addEvent]);
  });

  testWidgets('un solo botón: el entreno de hoy empieza con «Empezar»', (
    tester,
  ) async {
    final actions = await pump(tester, [
      _block(
        '1',
        HomeEventType.sport,
        ItemTimeStatus.upcoming,
        hour: 18,
        routineDayId: 'd1',
      ),
    ], summary: _pendingOne);

    expect(find.byWidgetPredicate((w) => w is FilledButton), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    expect(actions, [TodayAction.train]);
  });

  testWidgets('un partido suelto no arranca otra rutina: sin botón', (
    tester,
  ) async {
    await pump(tester, [
      _block('1', HomeEventType.sport, ItemTimeStatus.upcoming, hour: 18),
    ], summary: _pendingOne);

    expect(find.byWidgetPredicate((w) => w is FilledButton), findsNothing);
  });

  testWidgets('con solo clases se nombran y se ofrece añadir algo', (
    tester,
  ) async {
    final actions = await pump(tester, [
      _block('1', HomeEventType.classSession, ItemTimeStatus.upcoming),
    ]);

    expect(find.text('Hoy solo tienes 1 clase'), findsOneWidget);
    expect(find.textContaining('Has terminado'), findsNothing);
    await tester.tap(find.text('Añadir al calendario'));
    expect(actions, [TodayAction.addEvent]);
  });

  testWidgets('con todo hecho lo celebra', (tester) async {
    await pump(
      tester,
      [_block('1', HomeEventType.study, ItemTimeStatus.done, completed: true)],
      summary: const HomeTodaySummary(
        done: 1,
        total: 1,
        state: HomeDayState.allDone,
      ),
    );

    expect(find.textContaining('Has terminado lo de hoy'), findsOneWidget);
  });

  testWidgets('uno hecho y uno sin hacer no dice «Has terminado»', (
    tester,
  ) async {
    final marked = <HomeTodayEvent>[];
    final missed = _block('2', HomeEventType.study, ItemTimeStatus.missed);
    await pump(
      tester,
      [
        _block('1', HomeEventType.study, ItemTimeStatus.done, completed: true),
        missed,
      ],
      summary: const HomeTodaySummary(
        done: 1,
        total: 2,
        missed: 1,
        nextEventId: '2',
        state: HomeDayState.missedLeft,
      ),
      onMarkDone: marked.add,
    );

    expect(find.textContaining('Has terminado'), findsNothing);
    // Nombra lo que queda, con su hora y que no se hizo.
    expect(find.text('Te queda:'), findsOneWidget);
    expect(find.text('Bloque 2'), findsOneWidget);
    expect(find.textContaining(', sin hacer'), findsOneWidget);
    // Solo queda eso: sin «y N más».
    expect(find.textContaining(' más'), findsNothing);
    expect(
      find.bySemanticsLabel('Has hecho 1 de 2 eventos de hoy'),
      findsOneWidget,
    );
    // Se marca ahí mismo, con el mismo caso de uso que la agenda.
    await tester.tap(find.text('Marcar como hecho'));
    expect(marked, [missed]);
  });

  testWidgets('si queda más de una, «y 2 más» lleva a la agenda', (
    tester,
  ) async {
    var opened = 0;
    await pump(
      tester,
      [
        _block('1', HomeEventType.study, ItemTimeStatus.missed, hour: 8),
        _block('2', HomeEventType.review, ItemTimeStatus.missed, hour: 9),
        _block('3', HomeEventType.personal, ItemTimeStatus.missed, hour: 11),
      ],
      summary: const HomeTodaySummary(
        total: 3,
        missed: 3,
        nextEventId: '3',
        state: HomeDayState.missedLeft,
      ),
      onOpenAgenda: () => opened++,
    );

    expect(find.text('Bloque 3'), findsOneWidget);
    expect(find.text('Marcar como hecho'), findsOneWidget);
    await tester.tap(find.text('y 2 más'));
    expect(opened, 1);
  });

  testWidgets('con el texto al 200 % el anillo y el botón caben, sin XP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      [
        for (var i = 0; i < 12; i++)
          _block(
            '$i',
            HomeEventType.study,
            i < 10 ? ItemTimeStatus.done : ItemTimeStatus.upcoming,
            completed: i < 10,
            hour: 8 + i,
          ),
      ],
      summary: const HomeTodaySummary(
        done: 10,
        total: 12,
        nextEventId: '10',
        state: HomeDayState.pending,
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('10/12'), findsOneWidget);
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
