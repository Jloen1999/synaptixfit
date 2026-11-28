import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/planner/planner_week.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/block_editor/bloc/block_editor_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/block_editor/page/block_editor_sheet.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar/bloc/calendar_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar/page/block_details_sheet.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar/page/calendar_page.dart';
import 'package:synaptixfit/presentation/screens/planner/planner_routes.dart';
import 'package:synaptixfit/presentation/screens/planner/weekly_load/bloc/weekly_load_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/weekly_load/page/weekly_load_sheet.dart';
import 'package:synaptixfit/presentation/screens/planner/widgets/planner_visuals.dart';
import 'package:synaptixfit/presentation/screens/planner/widgets/time_block_tile.dart';
import 'package:synaptixfit/presentation/screens/planner/widgets/week_canvas.dart';
import 'package:synaptixfit/presentation/theme/app_icons.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'planner_fixtures.dart';

class _MockCalendarBloc extends MockBloc<CalendarEvent, CalendarState>
    implements CalendarBloc {}

class _MockEditorBloc extends MockBloc<BlockEditorEvent, BlockEditorState>
    implements BlockEditorBloc {}

class _MockLoadBloc extends MockBloc<WeeklyLoadEvent, WeeklyLoadState>
    implements WeeklyLoadBloc {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

/// Pestaña Calendario (ADR 0060): cabecera compacta, cifras de la semana que
/// abren su detalle, «+» y pulsación larga para añadir, y la ficha de lectura
/// de un evento con «Editar» y eliminar con «Deshacer».
void main() {
  late _MockCalendarBloc calendar;
  late _MockEditorBloc editor;
  late _MockLoadBloc load;
  late _MockSessionBloc session;

  // La página usa el reloj real: la semana y el evento salen de «ahora».
  final now = DateTime.now();
  final monday = PlannerWeek.mondayOf(now);
  // A esta hora (como mucho las 20:00) el lienzo la enseña al abrir.
  final hour = now.hour.clamp(1, 20);
  final study = CalendarBlock(
    id: 'b1',
    type: BlockType.study,
    start: DateTime(now.year, now.month, now.day, hour),
    end: DateTime(now.year, now.month, now.day, hour + 1),
    subjectId: 's1',
  );
  final other = study.copyWith(id: 'b2');

  CalendarState ready({DateTime? week}) => CalendarState(
    weekStart: week ?? monday,
    status: CalendarStatus.ready,
    blocks: [study],
    blockTitles: const {'b1': 'Bases de datos'},
    blockSubjects: const {'b1': 'Bases de datos'},
    conflicts: [BlockConflict(first: study, second: other)],
    balance: testBalance,
  );

  setUpAll(() async {
    registerPlannerFallbacks();
    registerFallbackValue(const CalendarEvent.refreshed());
    registerFallbackValue(const BlockEditorEvent.started());
    registerFallbackValue(WeeklyLoadEvent.started(DateTime(2000)));
    await initializeDateFormatting('es');
  });

  setUp(() {
    calendar = _MockCalendarBloc();
    when(() => calendar.state).thenReturn(ready());
    when(() => calendar.isClosed).thenReturn(false);
    editor = _MockEditorBloc();
    when(
      () => editor.state,
    ).thenReturn(const BlockEditorState(status: BlockEditorStatus.ready));
    load = _MockLoadBloc();
    when(() => load.state).thenReturn(const WeeklyLoadState());
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(null);
    getIt
      ..registerFactory<CalendarBloc>(() => calendar)
      ..registerFactory<WeeklyLoadBloc>(() => load)
      ..registerFactoryParam<BlockEditorBloc, CalendarBlock?, void>(
        (_, _) => editor,
      );
  });

  tearDown(() {
    getIt
      ..unregister<CalendarBloc>()
      ..unregister<WeeklyLoadBloc>()
      ..unregister<BlockEditorBloc>();
  });

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: PlannerPaths.root,
            routes: [
              GoRoute(
                path: PlannerPaths.root,
                builder: (_, _) => const CalendarPage(),
              ),
              GoRoute(
                path: PlannerPaths.deadlines,
                builder: (_, _) => const Scaffold(body: Text('entregas')),
              ),
              GoRoute(
                path: PlannerPaths.pomodoro,
                builder: (_, _) => const Scaffold(body: Text('pomodoro')),
              ),
            ],
          ),
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
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Alto de todo lo que va encima de la rejilla (hasta la línea bajo la
  /// cabecera de días).
  double headerHeight(WidgetTester tester) => tester
      .getRect(
        find.descendant(
          of: find.byType(WeekCanvas),
          matching: find.byType(Divider),
        ),
      )
      .bottom;

  Finder todayButton() => find.widgetWithText(TextButton, 'Hoy');

  group('cabecera compacta', () {
    testWidgets('en 390×844 la rejilla empieza antes de 190 px, sin barra '
        'de título y con la semana como encabezado', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(headerHeight(tester), lessThanOrEqualTo(190));
      expect(
        find.bySemanticsLabel(RegExp(r'^Calendario, semana del ')),
        findsOneWidget,
      );
      // Entregas y Concentrarme son iconos con nombre (y tooltip).
      expect(find.byTooltip('Entregas y exámenes'), findsOneWidget);
      expect(find.byTooltip('Concentrarme'), findsOneWidget);
      expect(find.byTooltip('Más opciones'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('en la semana actual no sale «Hoy» (la tira ya lleva a hoy)', (
      tester,
    ) async {
      await pump(tester);
      expect(todayButton(), findsNothing);
    });

    testWidgets('en otra semana sale «Hoy» y vuelve a la actual', (
      tester,
    ) async {
      when(
        () => calendar.state,
      ).thenReturn(ready(week: monday.add(const Duration(days: 7))));
      await pump(tester);
      expect(todayButton(), findsOneWidget);
      await tester.tap(todayButton());
      verify(
        () => calendar.add(const CalendarEvent.todayRequested()),
      ).called(1);
    });

    // Semana que cambia de mes (el rango más largo, «27 oct – 2 nov») y no es
    // la actual (sale «Hoy»): el rango se ve entero, sin cortarse.
    for (final (size, scale) in [
      (const Size(320, 844), 1.0),
      (const Size(360, 800), 1.25),
    ]) {
      testWidgets('a ${size.width.toInt()} px y texto al '
          '${(scale * 100).toInt()} % el rango de otra semana se ve entero', (
        tester,
      ) async {
        when(
          () => calendar.state,
        ).thenReturn(ready(week: DateTime(2025, 10, 27)));
        await pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        final range = find.text('27 oct – 2 nov');
        expect(range, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(range);
        expect(paragraph.didExceedMaxLines, isFalse);
        final rect = tester.getRect(range);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        // Ni «Hoy» ni los iconos le quitan sitio: si no cabe con ellos en
        // una fila, bajan a la segunda.
        for (final other in [
          todayButton(),
          find.byTooltip('Entregas y exámenes'),
          find.byTooltip('Más opciones'),
        ]) {
          expect(tester.getRect(other).overlaps(rect), isFalse);
        }
        expect(todayButton(), findsOneWidget);
      });
    }

    testWidgets('en escritorio ‹ semana › van juntas, no en los extremos', (
      tester,
    ) async {
      await pump(tester, size: const Size(1280, 800));
      final prev = tester.getRect(find.byTooltip('Semana anterior'));
      final next = tester.getRect(find.byTooltip('Semana siguiente'));
      expect(next.right - prev.left, lessThanOrEqualTo(360));
    });

    testWidgets('los iconos abren sus pantallas', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('Entregas y exámenes'));
      await tester.pumpAndSettle();
      expect(find.text('entregas'), findsOneWidget);
    });
  });

  group('cifras de la semana', () {
    testWidgets('sin chip de entregas (las abre su icono) y con flecha', (
      tester,
    ) async {
      await pump(tester);
      expect(find.textContaining('entrega'), findsNothing);
      // Los chips que quedan llevan flecha: se leen como botones.
      for (final text in [
        '1 choque de horario',
        '10 h estudio · 3 h deporte',
      ]) {
        expect(
          find.descendant(
            of: find.widgetWithText(ActionChip, text),
            matching: find.byIcon(AppIcons.next),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('las horas abren la carga semanal y dicen qué son', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        find.bySemanticsLabel(
          RegExp(r'^10 h estudio · 3 h deporte: lo planificado esta semana'),
        ),
        findsOneWidget,
      );
      // Los chips van en una línea que se desliza: con la fuente de los tests
      // (más ancha que la real) este queda a la derecha.
      await tester.ensureVisible(find.text('10 h estudio · 3 h deporte'));
      await tester.pump();
      await tester.tap(find.text('10 h estudio · 3 h deporte'));
      // La carga semanal aún carga (esqueleto animado): no se espera a que
      // se quede quieta.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(WeeklyLoadSheet), findsOneWidget);
      handle.dispose();
    });

    testWidgets('el choque de horario es un chip más que abre la lista', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('1 choque de horario'));
      await tester.pumpAndSettle();
      expect(find.text('Choques de horario'), findsOneWidget);
    });
  });

  group('añadir', () {
    testWidgets('«+ Añadir» con texto y nombre abre el formulario', (
      tester,
    ) async {
      await pump(tester);
      final add = find.byTooltip('Añadir al calendario');
      expect(add, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.text('Añadir'),
        ),
        findsOneWidget,
      );
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.byType(BlockEditorSheet), findsOneWidget);
    });

    testWidgets('se encoge a «+» al bajar la rejilla y vuelve al parar', (
      tester,
    ) async {
      await pump(tester);
      final label = find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.text('Añadir'),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Bases de datos')) + const Offset(0, 200),
      );
      await gesture.moveBy(const Offset(0, -60));
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(label, findsNothing);
      // Sin texto, el nombre sigue en el tooltip.
      expect(find.byTooltip('Añadir al calendario'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(label, findsOneWidget);
    });

    testWidgets('mantener pulsado un hueco vacío pide añadir ahí', (
      tester,
    ) async {
      await pump(tester);
      final tile = tester.getCenter(find.text('Bases de datos'));
      // Dos horas más abajo en la misma columna: hueco libre.
      await tester.longPressAt(tile + const Offset(0, 120));
      await tester.pumpAndSettle();
      final slot =
          verify(
                () => calendar.add(captureAny(that: isA<CalendarSlotTapped>())),
              ).captured.single
              as CalendarSlotTapped;
      expect(slot.start.day, now.day);
      expect(slot.start.hour, hour + 2);
    });
  });

  group('eventos de la rejilla', () {
    testWidgets('llevan el icono de su tipo y «Hecho» con ✓ y en texto', (
      tester,
    ) async {
      when(
        () => calendar.state,
      ).thenReturn(ready().copyWith(blocks: [study.copyWith(completed: true)]));
      final handle = tester.ensureSemantics();
      await pump(tester);
      final tile = find.byType(TimeBlockTile);
      expect(
        find.descendant(of: tile, matching: find.byIcon(BlockType.study.icon)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.byIcon(AppIcons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.textContaining('· Hecho')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Bases de datos, Hecho')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('en un evento estrecho y corto queda solo el ✓', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 36,
                height: 20,
                child: TimeBlockTile(
                  block: study.copyWith(completed: true),
                  title: 'Bases de datos',
                  start: study.start,
                  end: study.end,
                  busy: false,
                  dragging: false,
                  onTap: () {},
                  onDragStart: () {},
                  onDragUpdate: (_) {},
                  onDragEnd: () {},
                  onResizeUpdate: (_) {},
                  onResizeEnd: () {},
                  onLockedTouched: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(find.byIcon(BlockType.study.icon), findsNothing);
      expect(find.text('Bases de datos'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('ficha de un evento', () {
    Future<void> openDetails(WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Bases de datos'));
      await tester.pumpAndSettle();
      expect(find.byType(BlockDetailsSheet), findsOneWidget);
    }

    testWidgets('tocar un evento abre su ficha de lectura (no el formulario)', (
      tester,
    ) async {
      await openDetails(tester);
      expect(find.byType(BlockEditorSheet), findsNothing);
      expect(find.text('Abrir asignatura'), findsOneWidget);
    });

    testWidgets('«Editar» (con texto) abre el formulario de siempre', (
      tester,
    ) async {
      await openDetails(tester);
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.byType(BlockDetailsSheet), findsNothing);
      expect(find.byType(BlockEditorSheet), findsOneWidget);
    });

    testWidgets('«Eliminar» lo quita con «Deshacer»', (tester) async {
      final notices = StreamController<CalendarState>();
      addTearDown(notices.close);
      whenListen(calendar, notices.stream, initialState: ready());
      await openDetails(tester);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      verify(
        () => calendar.add(CalendarEvent.blockDeleteRequested(study)),
      ).called(1);

      // El bloc lo aparta y avisa: el aviso lleva «Deshacer».
      final deleted = ready().copyWith(
        pendingDeletionIds: {'b1'},
        notice: const CalendarNotice.blockDeleted('b1'),
        noticeId: 1,
      );
      when(() => calendar.state).thenReturn(deleted);
      notices.add(deleted);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      verify(
        () => calendar.add(const CalendarEvent.blockDeleteUndone('b1')),
      ).called(1);
    });
  });

  group('accesibilidad', () {
    testWidgets('cumple tamaño táctil, etiquetas y contraste (claro y oscuro)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // Como en Correr: en el tema claro la guía mide los píxeles de la
        // línea de cada hora, que pasa por detrás de su etiqueta, y da un
        // falso fallo; el contraste real de los tokens lo prueba contrast_test.
        if (theme == AppTheme.dark) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
      }
      handle.dispose();
    });

    testWidgets('con el texto al 200 % la cabecera no se corta ni desborda', (
      tester,
    ) async {
      await pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      // Los iconos bajan a una segunda fila y siguen a la vista.
      expect(find.byTooltip('Entregas y exámenes'), findsOneWidget);
      expect(find.text('1 choque de horario'), findsOneWidget);
    });
  });
}
