import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar/page/block_details_sheet.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'planner_fixtures.dart';

/// Ficha de lectura de un evento (ADR 0060): qué dice de cada tipo, la acción
/// que toca (una sola rellena), marcar, pasar a otro día, eliminar y editar.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  // testNow: miércoles 15/10/2025 10:00.
  final today = DateTime(2025, 10, 15, 19);
  final tomorrow = DateTime(2025, 10, 16, 9);

  late List<BlockDetailsAction> actions;

  /// El texto cabe en una sola línea (no se ha partido): su ancho es el que
  /// pediría sin límite.
  bool oneLine(WidgetTester tester, String text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    return paragraph.size.width + 0.5 >=
        paragraph.getMaxIntrinsicWidth(double.infinity);
  }

  /// Botón relleno (la acción principal) con ese texto.
  Finder filled(String text) => find.ancestor(
    of: find.text(text),
    matching: find.bySubtype<FilledButton>(),
  );

  setUp(() => actions = []);

  Future<void> pump(
    WidgetTester tester,
    BlockDetails details, {
    double textScale = 1,
    double width = 390,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = Size(width, 1400 * textScale);
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
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: BlockDetailsSheet(
            details: details,
            now: testNow,
            onAction: actions.add,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  CalendarBlock event({
    BlockType type = BlockType.study,
    DateTime? start,
    ItemTimeStatus status = ItemTimeStatus.upcoming,
    bool completed = false,
    bool fixed = false,
  }) => block(
    start: start ?? today,
    type: type,
    completed: completed,
    fixed: fixed,
  ).copyWith(timeStatus: status);

  testWidgets('estudio de hoy: dice qué, cuándo, de qué asignatura, qué reto '
      'adelanta, dónde y la nota; la acción grande es «Concentrarme»', (
    tester,
  ) async {
    await pump(
      tester,
      BlockDetails(
        block: event().copyWith(
          subjectId: 's1',
          challengeId: 'c1',
          location: 'Aula 2.4',
          topics: 'Tema 4: GROUP BY',
        ),
        title: 'Bases de datos',
        subjectName: 'Bases de datos',
        challenge: (challenge: 'Estudia y muévete', task: 'Día 2'),
      ),
    );
    expect(find.text('Estudio'), findsOneWidget);
    expect(find.text('Hoy, 19:00 – 20:00'), findsOneWidget);
    // Solo la duración: el calendario no sabe si hay avisos en este móvil.
    expect(find.text('1 h'), findsOneWidget);
    expect(find.textContaining('Más avisos'), findsNothing);
    expect(find.text('Abrir asignatura'), findsOneWidget);
    expect(
      find.text('Adelanta «Día 2» del reto «Estudia y muévete»'),
      findsOneWidget,
    );
    expect(find.text('Aula 2.4'), findsOneWidget);
    expect(find.text('Tema 4: GROUP BY'), findsOneWidget);
    // Una sola acción rellena; lo que aún no empezó no se marca.
    expect(find.bySubtype<FilledButton>(), findsOneWidget);
    expect(filled('Concentrarme'), findsOneWidget);
    expect(
      find.text('Podrás marcarlo como hecho cuando empiece.'),
      findsOneWidget,
    );
    expect(find.text('Marcar como hecho'), findsNothing);

    await tester.tap(find.text('Concentrarme'));
    await tester.tap(find.text('Abrir asignatura'));
    await tester.tap(find.text('Pasar a otro día'));
    await tester.tap(find.text('Eliminar'));
    await tester.tap(find.text('Editar'));
    expect(actions, [
      BlockDetailsAction.focus,
      BlockDetailsAction.openSubject,
      BlockDetailsAction.move,
      BlockDetailsAction.delete,
      BlockDetailsAction.edit,
    ]);
  });

  testWidgets('mañana se dice «Mañana»; sin nombre del reto, se dice igual', (
    tester,
  ) async {
    await pump(
      tester,
      BlockDetails(
        block: event(start: tomorrow).copyWith(challengeId: 'c1'),
        title: 'Cálculo',
      ),
    );
    expect(find.text('Mañana, 9:00 – 10:00'), findsOneWidget);
    expect(find.text('Adelanta una tarea de un reto'), findsOneWidget);
  });

  testWidgets('lo personal que ya empezó: «Marcar como hecho» es la acción', (
    tester,
  ) async {
    await pump(
      tester,
      BlockDetails(
        block: event(
          type: BlockType.personal,
          start: DateTime(2025, 10, 15, 9, 30),
          status: ItemTimeStatus.inProgress,
        ).copyWith(topics: 'Dentista'),
        title: 'Dentista',
      ),
    );
    expect(filled('Marcar como hecho'), findsOneWidget);
    // El nombre de lo personal es el título, no una nota aparte.
    expect(find.text('Dentista'), findsOneWidget);
    await tester.tap(find.text('Marcar como hecho'));
    expect(actions, [BlockDetailsAction.toggleDone]);
  });

  testWidgets(
    'hecho: sin acción rellena, «Desmarcar» y no se pasa a otro día',
    (tester) async {
      await pump(
        tester,
        BlockDetails(
          block: event(
            type: BlockType.sport,
            start: DateTime(2025, 10, 15, 8),
            status: ItemTimeStatus.done,
            completed: true,
          ),
          title: 'Deporte',
        ),
      );
      expect(find.bySubtype<FilledButton>(), findsNothing);
      expect(find.text('Hecho'), findsOneWidget);
      expect(find.text('Desmarcar'), findsOneWidget);
      expect(find.text('Pasar a otro día'), findsNothing);
      // Dice por qué no se puede pasar a otro día.
      expect(
        find.text('Ya está hecho: desmárcalo antes de moverlo.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Desmarcar'));
      expect(actions, [BlockDetailsAction.toggleDone]);
    },
  );

  testWidgets('sin hacer: se marca, se pasa a otro día y se dice con texto', (
    tester,
  ) async {
    await pump(
      tester,
      BlockDetails(
        block: event(
          start: DateTime(2025, 10, 14, 18),
          status: ItemTimeStatus.missed,
        ),
        title: 'Cálculo',
      ),
    );
    expect(find.text('Sin hacer'), findsOneWidget);
    expect(filled('Marcar como hecho'), findsOneWidget);
    expect(find.text('Pasar a otro día'), findsOneWidget);
  });

  testWidgets('clase que ya pasó: «Sí fui»/«No fui» con su explicación', (
    tester,
  ) async {
    await pump(
      tester,
      BlockDetails(
        block: event(
          type: BlockType.classSession,
          start: DateTime(2025, 10, 15, 8),
          status: ItemTimeStatus.done,
          completed: true,
        ),
        title: 'Bases de datos',
      ),
    );
    expect(find.text('Cuenta como asistida.'), findsOneWidget);
    expect(find.text('Sí fui'), findsNothing);
    await tester.tap(find.text('No fui'));
    expect(actions, [BlockDetailsAction.classAbsent]);
  });

  testWidgets('día de rutina: hoy «Empezar el entreno»; otro día, la rutina', (
    tester,
  ) async {
    final routine = event(
      type: BlockType.sport,
    ).copyWith(routineId: 'r1', routineDayId: 'd1');
    await pump(tester, BlockDetails(block: routine, title: 'Tirón y core'));
    expect(filled('Empezar el entreno'), findsOneWidget);
    // Lo marca la sesión: no hay «Marcar como hecho».
    expect(find.text('Marcar como hecho'), findsNothing);
    expect(find.text('Abrir en la rutina'), findsOneWidget);
    await tester.tap(find.text('Empezar el entreno'));
    expect(actions, [BlockDetailsAction.startTraining]);

    await pump(
      tester,
      BlockDetails(
        block: routine.copyWith(
          start: tomorrow,
          end: tomorrow.add(const Duration(hours: 1)),
        ),
        title: 'Tirón y core',
      ),
    );
    expect(filled('Abrir en la rutina'), findsOneWidget);
  });

  testWidgets('un evento fijo no se pasa a otro día y se dice «Fijo»', (
    tester,
  ) async {
    await pump(
      tester,
      BlockDetails(
        block: event(type: BlockType.personal, fixed: true),
        title: 'Trabajo',
      ),
    );
    expect(find.text('Fijo'), findsOneWidget);
    expect(find.text('Pasar a otro día'), findsNothing);
    expect(
      find.text('Este evento es fijo y no se puede mover.'),
      findsOneWidget,
    );
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets(
    'mientras se hace algo, los botones no se pueden pulsar dos veces',
    (tester) async {
      await pump(
        tester,
        BlockDetails(
          block: event(
            type: BlockType.personal,
            start: DateTime(2025, 10, 14, 18),
            status: ItemTimeStatus.missed,
          ),
          title: 'Recados',
          busy: true,
        ),
      );
      await tester.tap(find.text('Pasar a otro día'));
      await tester.tap(find.text('Eliminar'));
      await tester.tap(find.text('Editar'));
      expect(actions, isEmpty);
    },
  );

  testWidgets('sin nombre de la asignatura no sale la línea (no se llama '
      '«Asignatura»)', (tester) async {
    await pump(
      tester,
      BlockDetails(
        block: event().copyWith(subjectId: 's1'),
        title: 'Estudio',
      ),
    );
    expect(find.text('Asignatura'), findsNothing);
    expect(find.text('Abrir asignatura'), findsNothing);
  });

  testWidgets('a 360 px, un estudio en curso: cada botón en una línea y '
      '«Eliminar» en la suya, al final', (tester) async {
    await pump(
      tester,
      BlockDetails(
        block: event(
          start: DateTime(2025, 10, 15, 9, 30),
          status: ItemTimeStatus.inProgress,
        ),
        title: 'Bases de datos',
      ),
      width: 360,
    );
    expect(tester.takeException(), isNull);
    for (final label in [
      'Concentrarme',
      'Marcar como hecho',
      'Pasar a otro día',
      'Eliminar',
      'Editar',
    ]) {
      expect(oneLine(tester, label), isTrue, reason: '«$label» se parte');
    }
    final mark = tester.getRect(find.text('Marcar como hecho'));
    final move = tester.getRect(find.text('Pasar a otro día'));
    final delete = tester.getRect(find.text('Eliminar'));
    // Eliminar va debajo de todo, en su propia línea.
    expect(delete.top, greaterThan(mark.bottom));
    expect(delete.top, greaterThan(move.bottom));
  });

  group('accesibilidad', () {
    final details = BlockDetails(
      block: event().copyWith(subjectId: 's1', location: 'Aula 2.4'),
      title: 'Bases de datos',
      subjectName: 'Bases de datos',
    );

    testWidgets(
      'cumple tamaño táctil, etiquetas y contraste (claro y oscuro)',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await pump(tester, details, theme: theme);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        // El título es el encabezado; el lugar y la asignatura dicen qué son.
        expect(
          find.bySemanticsLabel('Bases de datos').evaluate().isNotEmpty,
          isTrue,
        );
        expect(find.bySemanticsLabel('Ubicación: Aula 2.4'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Abrir asignatura Bases de datos'),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets('con el texto al 200 % y a 320 px no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, details, textScale: 2, width: 320);
      expect(tester.takeException(), isNull);
      // Con el texto grande los botones van uno debajo de otro.
      final move = tester.getTopLeft(find.text('Pasar a otro día'));
      final delete = tester.getTopLeft(find.text('Eliminar'));
      expect(delete.dy, greaterThan(move.dy));
    });
  });

  group('clase (ADR 0065): «Entrar a la clase en línea» o la asignatura', () {
    testWidgets('hoy, con enlace y sin acabar, entrar es la principal', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        BlockDetails(
          block: event(type: BlockType.classSession).copyWith(
            subjectId: 's1',
            location: 'Teams: (https://teams.microsoft.com/l/abc).',
          ),
          title: 'Bases de datos',
          subjectName: 'Bases de datos',
        ),
      );
      expect(filled('Entrar a la clase en línea'), findsOneWidget);
      // El lector oye que sale de la app.
      expect(
        find.bySemanticsLabel(
          'Entrar a la clase en línea. Se abre fuera de la app',
        ),
        findsOneWidget,
      );
      // En «Lugar», solo el dominio del enlace.
      expect(find.text('Teams: (teams.microsoft.com).'), findsOneWidget);
      // La asignatura sigue a mano, con su botón.
      expect(find.text('Abrir asignatura'), findsOneWidget);
      await tester.tap(find.text('Entrar a la clase en línea'));
      expect(actions, [BlockDetailsAction.goToClass]);
      handle.dispose();
    });

    testWidgets(
      'otro día, aunque tenga enlace, la principal es la asignatura',
      (tester) async {
        await pump(
          tester,
          BlockDetails(
            block: event(type: BlockType.classSession, start: tomorrow)
                .copyWith(
                  subjectId: 's1',
                  location: 'https://meet.example.com/abc-defg',
                ),
            title: 'Bases de datos',
            subjectName: 'Bases de datos',
          ),
        );
        expect(find.text('Entrar a la clase en línea'), findsNothing);
        expect(filled('Abrir asignatura'), findsOneWidget);
      },
    );

    testWidgets('a 320 px y texto al 200 %, «Abrir asignatura» baja de línea', (
      tester,
    ) async {
      await pump(
        tester,
        BlockDetails(
          block: event().copyWith(subjectId: 's1'),
          title: 'Bases de datos',
          subjectName: 'Ingeniería del software',
        ),
        width: 320,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final subject = tester.getRect(find.text('Ingeniería del software'));
      final open = tester.getRect(find.text('Abrir asignatura'));
      // Debajo del nombre, no al lado partiéndolo.
      expect(open.top, greaterThanOrEqualTo(subject.bottom - 1));
    });

    testWidgets('en un aula, la principal abre la asignatura (sin repetirla)', (
      tester,
    ) async {
      await pump(
        tester,
        BlockDetails(
          block: event(
            type: BlockType.classSession,
          ).copyWith(subjectId: 's1', location: 'Aula 2.4'),
          title: 'Bases de datos',
          subjectName: 'Bases de datos',
        ),
      );
      expect(find.text('Entrar a la clase en línea'), findsNothing);
      expect(filled('Abrir asignatura'), findsOneWidget);
      expect(find.text('Abrir asignatura'), findsOneWidget);
      expect(find.text('Aula 2.4'), findsOneWidget);
      await tester.tap(find.text('Abrir asignatura'));
      expect(actions, [BlockDetailsAction.openSubject]);
    });

    testWidgets('una clase que ya pasó no lleva al enlace', (tester) async {
      await pump(
        tester,
        BlockDetails(
          block: event(
            type: BlockType.classSession,
            start: DateTime(2025, 10, 15, 8),
            status: ItemTimeStatus.done,
            completed: true,
          ).copyWith(location: 'https://meet.example.com/abc-defg'),
          title: 'Bases de datos',
        ),
      );
      expect(find.text('Entrar a la clase en línea'), findsNothing);
      expect(find.text('Cuenta como asistida.'), findsOneWidget);
    });
  });
}
