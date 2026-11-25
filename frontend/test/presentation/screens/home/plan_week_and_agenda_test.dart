import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:synaptixfit/domain/enums/home_day_mark.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_week_state.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/agenda_section.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/plan_week_bar.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// «Tu semana» con su frase y un círculo por día (ADR 0059) y la agenda que
/// marca desde Inicio (ADR 0035).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    Intl.defaultLocale = 'es';
  });

  final monday = DateTime(2026, 10, 19);
  // Las marcas las manda el servidor (ADR 0059): lunes con algo sin hacer,
  // martes todo hecho, miércoles (hoy) a medias, jueves 3 por hacer y el
  // resto sin nada.
  final days = [
    HomePlanDay(
      date: monday,
      planned: 4,
      completed: 2,
      missed: 1,
      mark: HomeDayMark.missed,
      pending: 1,
    ),
    HomePlanDay(
      date: monday.add(const Duration(days: 1)),
      planned: 2,
      completed: 2,
      mark: HomeDayMark.done,
    ),
    HomePlanDay(
      date: monday.add(const Duration(days: 2)),
      planned: 4,
      completed: 2,
      mark: HomeDayMark.partial,
      pending: 2,
    ),
    HomePlanDay(
      date: monday.add(const Duration(days: 3)),
      planned: 3,
      completed: 0,
      mark: HomeDayMark.pending,
      pending: 3,
    ),
    for (var i = 4; i < 7; i++)
      HomePlanDay(
        date: monday.add(Duration(days: i)),
        planned: 0,
        completed: 0,
      ),
  ];
  const week = HomeWeekKpis(
    sessions: 2,
    plannedSessions: 3,
    trainingMinutes: 90,
    trainingCalories: 600,
    studyMinutesCompleted: 300,
    studyMinutesPlanned: 480,
  );
  const summary = HomeWeekSummary(
    done: 6,
    planned: 13,
    missed: 1,
    state: HomeWeekState.onTrack,
  );
  final wednesday = monday.add(const Duration(days: 2));

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
    Widget bar({ValueChanged<DateTime>? onOpenDay, HomeWeekSummary? state}) =>
        PlanWeekBar(
          days: days,
          week: week,
          summary: state ?? summary,
          onOpenDay: onOpenDay ?? (_) {},
          now: wednesday,
        );

    testWidgets('una frase dice cómo vas y cada cifra lleva su palabra', (
      tester,
    ) async {
      await pump(tester, bar());

      expect(find.text('Vas al día'), findsOneWidget);
      expect(
        find.text('6 de 13 cosas hechas · 1 se quedó sin hacer'),
        findsOneWidget,
      );
      expect(find.text('Entrenos'), findsOneWidget);
      expect(find.text('2 de 3'), findsOneWidget);
      expect(find.text('Estudio'), findsOneWidget);
      expect(find.text('5 h de 8 h'), findsOneWidget);
      // Sin «2/3» sueltos.
      expect(find.text('2/4'), findsNothing);
    });

    testWidgets('el estado lo da el servidor: por detrás y sin plan', (
      tester,
    ) async {
      await pump(
        tester,
        bar(
          state: const HomeWeekSummary(
            done: 1,
            planned: 8,
            missed: 4,
            state: HomeWeekState.behind,
          ),
        ),
      );
      expect(find.text('Vas por detrás'), findsOneWidget);
      expect(find.textContaining('4 se quedaron sin hacer'), findsOneWidget);

      await pump(tester, bar(state: const HomeWeekSummary()));
      expect(find.text('Semana sin plan'), findsOneWidget);
    });

    testWidgets('cada día lleva una marca que no depende del color', (
      tester,
    ) async {
      await pump(tester, bar());

      // ✓ todo hecho (icono), «!» algo sin hacer, el número de lo que queda
      // y «–» sin nada; «Hoy» en vez de la inicial.
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      expect(find.text('!'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('–'), findsWidgets);
      expect(find.text('Hoy'), findsOneWidget);
      // Leyenda corta.
      expect(find.text('Todo hecho'), findsOneWidget);
      expect(find.text('A medias'), findsOneWidget);
      expect(find.text('Algo sin hacer'), findsOneWidget);
      expect(find.text('Por hacer'), findsOneWidget);
    });

    testWidgets('el lector dice lo mismo con palabras y tocar abre el día', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      DateTime? opened;
      await pump(tester, bar(onOpenDay: (d) => opened = d));

      expect(find.bySemanticsLabel('lunes: 1 sin hacer'), findsOneWidget);
      expect(find.bySemanticsLabel('martes: todo hecho'), findsOneWidget);
      final today = find.bySemanticsLabel('Hoy, miércoles: 2 de 4 hechos');
      expect(today, findsOneWidget);
      expect(find.bySemanticsLabel('jueves: 3 por hacer'), findsOneWidget);
      expect(
        find.bySemanticsLabel('viernes: nada planificado'),
        findsOneWidget,
      );
      await tester.tap(today);
      expect(opened, wednesday);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('al 200 % y en 320 px no desborda', (tester) async {
      await pump(tester, bar(), textScale: 2, width: 320);
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
        event(
          id: 'c',
          type: HomeEventType.delivery,
          kind: HomeEventKind.deadline,
        ),
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
        event(
          id: 's',
          type: HomeEventType.sport,
          status: ItemTimeStatus.missed,
        ),
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
        find.text(
          'Cuenta para la tarea «Repasar tema 3» del reto Aprobar Física',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cumple las guías de accesibilidad y no desborda al 200 %', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await showAgenda(tester, [
        event(
          id: 'a',
          type: HomeEventType.personal,
          status: ItemTimeStatus.missed,
        ),
        event(id: 'b', type: HomeEventType.study, completed: true),
      ]);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();

      await showAgenda(
        tester,
        [
          event(
            id: 'a',
            type: HomeEventType.personal,
            status: ItemTimeStatus.missed,
          ),
        ],
        textScale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
