import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/agenda_section.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/plan_week_bar.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// «Tu semana» con Hecho / Por hacer / Sin hacer y la agenda que marca desde
/// Inicio (ADR 0035).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    Intl.defaultLocale = 'es';
  });

  final monday = DateTime(2026, 10, 19);
  final days = [
    HomePlanDay(date: monday, planned: 4, completed: 2, missed: 1),
    HomePlanDay(date: monday.add(const Duration(days: 1)), planned: 3, completed: 0),
    for (var i = 2; i < 7; i++)
      HomePlanDay(date: monday.add(Duration(days: i)), planned: 0, completed: 0),
  ];
  const week = HomeWeekKpis(
    sessions: 1,
    trainingMinutes: 45,
    trainingCalories: 300,
    studyMinutesCompleted: 90,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 1600 * textScale);
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
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pump();
  }

  group('Tu semana', () {
    testWidgets('el título se entiende solo y nombra los tres estados', (
      tester,
    ) async {
      await pump(
        tester,
        PlanWeekBar(
          days: days,
          week: week,
          onOpenDay: (_) {},
          now: monday,
        ),
      );

      expect(find.text('2 de 7 hechos esta semana'), findsOneWidget);
      expect(find.text('4 por hacer · 1 sin hacer'), findsOneWidget);
      expect(find.text('Hecho'), findsOneWidget);
      expect(find.text('Por hacer'), findsOneWidget);
      expect(find.text('Sin hacer'), findsOneWidget);
      expect(find.text('Planificado'), findsNothing);
    });

    testWidgets('el lector dice lo mismo que se ve y tocar abre el día', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      DateTime? opened;
      await pump(
        tester,
        PlanWeekBar(
          days: days,
          week: week,
          onOpenDay: (d) => opened = d,
          now: monday,
        ),
      );

      final label = find.bySemanticsLabel(
        'Hoy, lunes: 2 de 4 hechos, 1 por hacer, 1 sin hacer',
      );
      expect(find.bySemanticsLabel('martes: 0 de 3 hechos, 3 por hacer'), findsOneWidget);
      expect(find.bySemanticsLabel('miércoles: nada planificado'), findsOneWidget);
      expect(label, findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      await tester.tap(label);
      expect(opened, monday);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('al 200 % y en 320 px no desborda', (tester) async {
      await pump(
        tester,
        PlanWeekBar(days: days, week: week, onOpenDay: (_) {}, now: monday),
        textScale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('agenda: marcar desde Inicio', () {
    HomeTodayEvent event({
      required String id,
      required HomeEventType type,
      HomeEventKind kind = HomeEventKind.block,
      bool completed = false,
      ItemTimeStatus status = ItemTimeStatus.inProgress,
      String? routineDayId,
      List<HomeTaskMention> tasks = const [],
    }) => HomeTodayEvent(
      id: id,
      kind: kind,
      type: type,
      title: 'Evento $id',
      start: DateTime(2026, 10, 19, 10),
      end: kind == HomeEventKind.block ? DateTime(2026, 10, 19, 11) : null,
      completed: completed,
      status: status,
      routineId: routineDayId == null ? null : 'r1',
      routineDayId: routineDayId,
      tasks: tasks,
    );

    Future<List<(String, bool)>> showAgenda(
      WidgetTester tester,
      List<HomeTodayEvent> events, {
      List<String>? started,
      double textScale = 1,
      double width = 390,
    }) async {
      final calls = <(String, bool)>[];
      await pump(
        tester,
        AgendaSection(
          events: events,
          upcoming: const [],
          reviews: const [],
          onOpenPlanner: () {},
          onOpenEvent: (_) {},
          onOpenReview: (_) {},
          onSetCompleted: (e, completed) => calls.add((e.id, completed)),
          onStartTraining: (e) => started?.add(e.id),
          now: DateTime(2026, 10, 19, 10, 30),
        ),
        textScale: textScale,
        width: width,
      );
      return calls;
    }

    testWidgets('estudio, personal y entregas llevan casilla; se desmarca', (
      tester,
    ) async {
      final calls = await showAgenda(tester, [
        event(id: 'a', type: HomeEventType.personal),
        event(id: 'b', type: HomeEventType.study, completed: true),
        event(id: 'c', type: HomeEventType.delivery, kind: HomeEventKind.deadline),
      ]);

      await tester.tap(find.byTooltip('Marcar «Evento a» como hecho'));
      await tester.tap(find.byTooltip('Desmarcar «Evento b»'));
      await tester.tap(find.byTooltip('Marcar «Evento c» como hecho'));

      expect(calls, [('a', true), ('b', false), ('c', true)]);
    });

    testWidgets('lo que aún no ha empezado se explica en vez de marcarse', (
      tester,
    ) async {
      final calls = await showAgenda(tester, [
        event(
          id: 'a',
          type: HomeEventType.review,
          status: ItemTimeStatus.upcoming,
        ),
      ]);

      await tester.tap(find.byTooltip('Marcar «Evento a» como hecho'));
      await tester.pump();

      expect(calls, isEmpty);
      expect(
        find.text('Este evento aún no ha empezado: márcalo cuando lo hagas.'),
        findsOneWidget,
      );
    });

    testWidgets('el entreno de rutina se empieza y el suelto se apunta', (
      tester,
    ) async {
      final started = <String>[];
      final calls = await showAgenda(tester, [
        event(id: 'r', type: HomeEventType.sport, routineDayId: 'd1'),
        event(id: 's', type: HomeEventType.sport, status: ItemTimeStatus.missed),
        event(id: 'k', type: HomeEventType.classSession),
      ], started: started);

      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.text('Empezar'));
      await tester.tap(find.text('Ya lo hice'));

      expect(started, ['r']);
      expect(calls, [('s', true)]);
    });

    testWidgets('dice qué tarea de reto adelanta el evento', (tester) async {
      await showAgenda(tester, [
        event(
          id: 'a',
          type: HomeEventType.study,
          tasks: const [
            HomeTaskMention(
              challengeId: 'c1',
              challengeTitle: 'Aprobar Física',
              title: 'Repasar tema 3',
            ),
          ],
        ),
      ]);

      expect(
        find.text('Cuenta para la tarea «Repasar tema 3» del reto Aprobar Física'),
        findsOneWidget,
      );
    });

    testWidgets('cumple las guías de accesibilidad y no desborda al 200 %', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await showAgenda(tester, [
        event(id: 'a', type: HomeEventType.personal, status: ItemTimeStatus.missed),
        event(id: 'b', type: HomeEventType.study, completed: true),
      ]);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();

      await showAgenda(tester, [
        event(id: 'a', type: HomeEventType.personal, status: ItemTimeStatus.missed),
      ], textScale: 2, width: 320);
      expect(tester.takeException(), isNull);
    });
  });
}
