import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/block_draft.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/block_editor/bloc/block_editor_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/block_editor/page/block_editor_sheet.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'planner_fixtures.dart';

class _MockEditorBloc extends MockBloc<BlockEditorEvent, BlockEditorState>
    implements BlockEditorBloc {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

/// Hoja de crear/editar evento: pasos, nombre de lo personal, atajos de
/// duración, «Más opciones» según el tipo y accesibilidad.
void main() {
  late _MockEditorBloc editor;
  late _MockSessionBloc session;

  const nameMissing = 'Escribe un nombre, por ejemplo «Dentista».';
  final slot = DateTime(2025, 10, 16, 9);

  setUpAll(() async {
    registerPlannerFallbacks();
    registerFallbackValue(const BlockEditorEvent.started());
    await initializeDateFormatting('es');
    await initializeDateFormatting('fr');
  });

  setUp(() {
    editor = _MockEditorBloc();
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(null);
    getIt.registerFactoryParam<BlockEditorBloc, CalendarBlock?, void>(
      (_, _) => editor,
    );
  });

  tearDown(() => getIt.unregister<BlockEditorBloc>());

  void show({CalendarBlock? editing, BlockEditorState? state}) =>
      when(() => editor.state).thenReturn(
        state ??
            BlockEditorState(block: editing, status: BlockEditorStatus.ready),
      );

  Future<void> pump(
    WidgetTester tester, {
    CalendarBlock? editing,
    ThemeData? theme,
    double textScale = 1,
    double width = 390,
    Locale locale = const Locale('es'),
  }) async {
    tester.view.physicalSize = Size(width, 1800 * textScale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: locale,
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
            // Con otra clave por evento: cambiar de evento crea la hoja de cero.
            body: BlockEditorSheet(
              key: ValueKey(editing),
              block: editing,
              start: slot,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Último borrador enviado al bloc al pulsar el botón principal.
  BlockDraft savedDraft() {
    final events = verify(() => editor.add(captureAny())).captured;
    return events.whereType<BlockEditorSaveRequested>().last.draft;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('al crear se ven los tres pasos y los tipos más usados', (
    tester,
  ) async {
    show();
    await pump(tester);

    expect(find.text('Nuevo evento'), findsOneWidget);
    expect(find.text('¿Qué es?'), findsOneWidget);
    expect(find.text('¿Cuándo?'), findsOneWidget);
    expect(find.text('Repetir y aviso'), findsOneWidget);
    for (final label in ['Estudio', 'Repaso', 'Entreno', 'Clase', 'Personal']) {
      expect(find.text(label), findsOneWidget);
    }
    // Los menos usados esperan en «Más tipos».
    expect(find.text('Examen'), findsNothing);
    await tapVisible(tester, find.text('Más tipos'));
    expect(find.text('Examen'), findsOneWidget);
    expect(find.text('Sueño'), findsOneWidget);
    expect(find.text('Menos tipos'), findsOneWidget);
  });

  testWidgets('Personal pide un nombre y lo envía en los temas', (
    tester,
  ) async {
    show();
    await pump(tester);

    expect(find.text('Nombre'), findsNothing);
    await tapVisible(tester, find.text('Personal'));
    expect(find.text('Nombre'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      '  Dentista ',
    );
    await tapVisible(tester, find.text('Añadir al calendario'));

    final draft = savedDraft();
    expect(draft.type, BlockType.personal);
    expect(draft.topics, 'Dentista');
    expect(draft.subjectId, isNull);
    expect(draft.priority, isNull);
  });

  testWidgets('sin nombre, el error sale junto al campo y abajo', (
    tester,
  ) async {
    final personal = block(type: BlockType.personal);
    show(
      state: BlockEditorState(
        block: personal,
        status: BlockEditorStatus.ready,
        issue: BlockEditorIssue.nameMissing,
        feedbackId: 1,
      ),
    );
    await pump(tester, editing: personal);

    expect(find.text('Editar evento personal'), findsOneWidget);
    expect(find.text(nameMissing), findsNWidgets(2));
  });

  testWidgets('el error de campo del servidor también se ve en «Nombre»', (
    tester,
  ) async {
    final personal = block(type: BlockType.personal);
    show(
      state: BlockEditorState(
        block: personal,
        status: BlockEditorStatus.ready,
        error: const AppError.validation(
          fields: [FieldError(field: 'topics', code: 'REQUIRED')],
        ),
        feedbackId: 1,
      ),
    );
    await pump(tester, editing: personal);

    expect(find.text(nameMissing), findsNWidgets(2));
  });

  testWidgets('los atajos de duración cambian la hora de fin', (tester) async {
    show();
    await pump(tester);

    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('1 h'), findsOneWidget);
    await tapVisible(tester, find.text('2 h'));
    expect(find.text('11:00'), findsOneWidget);

    await tapVisible(tester, find.text('Añadir al calendario'));
    final draft = savedDraft();
    expect(draft.end.difference(draft.start).inMinutes, 120);
    expect(draft.start, slot);
  });

  testWidgets('una entrega pide solo su hora límite', (tester) async {
    show();
    await pump(tester);

    await tapVisible(tester, find.text('Más tipos'));
    await tapVisible(tester, find.text('Entrega'));
    expect(find.text('Hora de entrega'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
    // Las entregas no se repiten: el paso 3 es solo el aviso.
    expect(find.text('Repetir cada semana'), findsNothing);
    expect(find.text('Aviso'), findsOneWidget);
  });

  testWidgets('«Más opciones» solo trae lo que aplica a cada tipo', (
    tester,
  ) async {
    show();
    await pump(tester);

    // Plegado al crear.
    expect(find.widgetWithText(TextFormField, 'Temas'), findsNothing);
    await tapVisible(tester, find.text('Más opciones'));
    expect(find.text('Prioridad'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Temas'), findsOneWidget);

    await tapVisible(tester, find.text('Personal'));
    expect(find.text('Prioridad'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Temas'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Ubicación'), findsOneWidget);
    expect(find.text('Evento privado'), findsOneWidget);
  });

  testWidgets('al editar con datos avanzados, «Más opciones» sale abierto', (
    tester,
  ) async {
    final withPlace = block(
      type: BlockType.personal,
    ).copyWith(topics: 'Dentista', location: 'Centro de salud');
    show(editing: withPlace);
    await pump(tester, editing: withPlace);

    expect(find.text('Dentista'), findsOneWidget);
    await tester.ensureVisible(find.text('Centro de salud'));
    expect(find.text('Centro de salud'), findsOneWidget);
  });

  testWidgets('un evento fijo no deja cambiar día ni hora', (tester) async {
    final fixed = block(fixed: true);
    show(editing: fixed);
    await pump(tester, editing: fixed);

    expect(
      find.text('Este evento es fijo: no puedes cambiar el día ni la hora.'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('2 h'));
    expect(find.text('11:00'), findsNothing);
  });

  group('accesibilidad', () {
    testWidgets('cumple las guías de tamaño táctil, etiquetas y contraste', (
      tester,
    ) async {
      // Al crear (estudio) y al editar un personal que se quedó sin hacer
      // (con «Nombre», «Más opciones» abierto y sus acciones arriba).
      final personal = block(type: BlockType.personal).copyWith(
        topics: 'Dentista',
        location: 'Centro de salud',
        timeStatus: ItemTimeStatus.missed,
      );
      final semantics = tester.ensureSemantics();
      for (final editing in [null, personal]) {
        show(editing: editing);
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await pump(tester, editing: editing, theme: theme);

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
      }
      semantics.dispose();
    });

    testWidgets('los pasos se anuncian como encabezados numerados', (
      tester,
    ) async {
      show();
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(
        find.bySemanticsLabel('Paso 1 de 3: ¿Qué es?'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Paso 2 de 3: ¿Cuándo?'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      show();
      await pump(tester, textScale: 2);
      await tapVisible(tester, find.text('Personal'));
      await tapVisible(tester, find.text('Más opciones'));

      expect(find.text('Nombre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en 320 px, en francés y al 200 % tampoco desborda', (
      tester,
    ) async {
      show();
      await pump(tester, textScale: 2, width: 320, locale: const Locale('fr'));
      await tapVisible(tester, find.text('Plus de types'));
      await tapVisible(tester, find.text('Plus d’options'));
      expect(tester.takeException(), isNull);
    });
  });
}
