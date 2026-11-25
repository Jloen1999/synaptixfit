import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/home/dashboard/bloc/home_dashboard_bloc.dart';
import 'package:synaptixfit/presentation/screens/home/dashboard/page/home_dashboard_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

import 'home_fixtures.dart';

class _MockHomeBloc extends MockBloc<HomeDashboardEvent, HomeDashboardState>
    implements HomeDashboardBloc {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

void main() {
  late _MockHomeBloc home;
  late _MockSessionBloc session;

  setUpAll(() {
    registerFallbackValue(const HomeDashboardEvent.refreshed());
    return initializeDateFormatting('es');
  });

  setUp(() {
    home = _MockHomeBloc();
    when(() => home.isClosed).thenReturn(false);
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(null);
  });

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
    double width = 390,
    String language = 'es',
  }) async {
    tester.view.physicalSize = Size(width, 2400 * textScale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: Locale(language),
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
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: session),
            BlocProvider<HomeDashboardBloc>.value(value: home),
          ],
          child: const HomeDashboardView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final missedStudy = HomeTodayEvent(
    id: 'm1',
    kind: HomeEventKind.block,
    type: HomeEventType.study,
    title: 'Repasar Cálculo',
    start: DateTime(yesterday.year, yesterday.month, yesterday.day, 19),
    end: DateTime(yesterday.year, yesterday.month, yesterday.day, 20),
    completed: false,
    status: ItemTimeStatus.missed,
  );
  final halfDone = homeDashboardFixture.copyWith(
    unfinishedSession: HomeUnfinishedSession(
      sessionId: 's9',
      routineName: 'Fuerza 3 días',
      dayName: 'Pierna y empuje',
      dayNumber: 2,
      startedAt: DateTime(2026, 11, 18, 18, 10),
      exercisesDone: 4,
      exercisesTotal: 6,
    ),
    missedEvents: [missedStudy],
    pendingFriendRequests: 2,
  );

  HomeDashboardState loadedWith(HomeDashboard dashboard) => HomeDashboardState(
    status: HomeDashboardStatus.loaded,
    dashboard: dashboard,
    dueReviews: homeReviewsFixture,
  );

  testWidgets('pinta todas las secciones del inicio', (tester) async {
    when(() => home.state).thenReturn(
      HomeDashboardState(
        status: HomeDashboardStatus.loaded,
        dashboard: homeDashboardFixture,
        dueReviews: homeReviewsFixture,
        unreadNotifications: 3,
      ),
    );

    await pump(tester);

    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.text('Tienes 2 entregas próximas'), findsOneWidget);
    // En el móvil el aviso entero lleva a la acción: se anuncia como pista.
    expect(
      find.bySemanticsLabel(RegExp('Tienes 2 entregas próximas')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    // Carga, energía y XP viven en Progreso (ADR 0038).
    expect(find.text('Carga de estudio'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    // En la agenda y en «Tu día» (es el bloque que toca a continuación).
    expect(find.text('Cálculo'), findsNWidgets(2));
    expect(find.text('Tu día'), findsOneWidget);
    expect(find.text('Tema 3: Límites'), findsOneWidget);
    expect(find.text('Fuerza base'), findsOneWidget);
    expect(find.text('¿Qué tal estás hoy?'), findsOneWidget);
    expect(find.text('Estudiar 10 horas'), findsOneWidget);
    // «Tu día» manda con un solo botón destacado: concentrarse en lo que toca.
    expect(find.text('Concentrarme'), findsOneWidget);
    expect(find.byType(AppPrimaryButton), findsOneWidget);
    // «Empezar» del próximo entreno pesa igual pero sin competir: tonal.
    expect(
      find.ancestor(
        of: find.text('Empezar'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Empezar'), findsNothing);
    // Un solo camino al calendario: su pestaña (sin enlaces ni «Planificar»).
    expect(find.text('Calendario'), findsNothing);
    expect(find.text('Planificar la semana'), findsNothing);
    expect(find.text('Empezar a correr'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('lo que quedó a medias (ADR 0059)', () {
    testWidgets('la sesión sin terminar dice cuál, cuándo y cuánto, y cada '
        'botón explica qué hace', (tester) async {
      when(() => home.state).thenReturn(loadedWith(halfDone));
      await pump(tester);

      expect(find.text('Sin terminar: Pierna y empuje'), findsOneWidget);
      expect(find.textContaining('a las 18:10 · 4 de 6 ejercicios'), findsOne);
      expect(find.text('Cuentan los 4 ejercicios que hiciste'), findsOneWidget);
      expect(
        find.text('Se borra, como si no la hubieras empezado'),
        findsOneWidget,
      );
      // «Guardar lo hecho» es el único destacado: «Tu día» no compite con él
      // (su «Concentrarme» pasa a tonal).
      expect(
        find.widgetWithText(AppPrimaryButton, 'Guardar lo hecho'),
        findsOneWidget,
      );
      expect(find.byType(AppPrimaryButton), findsOneWidget);
    });

    testWidgets('«Guardar lo hecho» pide minutos y esfuerzo y la guarda', (
      tester,
    ) async {
      when(() => home.state).thenReturn(loadedWith(halfDone));
      await pump(tester);

      await tester.tap(find.text('Guardar lo hecho'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar').last);
      await tester.pumpAndSettle();

      verify(
        () => home.add(
          any(
            that: isA<HomeDashboardUnfinishedSaved>().having(
              (e) => e.sessionId,
              'sessionId',
              's9',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('«Descartar» confirma antes y después ofrece «Deshacer»', (
      tester,
    ) async {
      when(() => home.state).thenReturn(loadedWith(halfDone));
      await pump(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar «Pierna y empuje»?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
      await tester.pumpAndSettle();
      verify(
        () => home.add(const HomeDashboardEvent.unfinishedDiscarded('s9')),
      ).called(1);
    });

    testWidgets('el aviso de descartar lleva «Deshacer» que la recupera', (
      tester,
    ) async {
      final hidden = loadedWith(
        halfDone,
      ).copyWith(deferredKeys: {'session:s9'});
      whenListen(
        home,
        Stream.fromIterable([
          hidden.copyWith(
            actionNotice: const HomeActionNotice.sessionDiscarded('session:s9'),
          ),
        ]),
        initialState: loadedWith(halfDone),
      );
      await pump(tester);
      await tester.pump();

      expect(find.text('Sesión descartada'), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pump();
      verify(
        () => home.add(const HomeDashboardEvent.deferredUndone('session:s9')),
      ).called(1);
    });

    testWidgets('lo de ayer sin marcar se nombra con sus tres botones', (
      tester,
    ) async {
      when(() => home.state).thenReturn(loadedWith(halfDone));
      await pump(tester);

      expect(find.text('Ayer quedó sin marcar'), findsOneWidget);
      expect(find.text('Repasar Cálculo'), findsOneWidget);
      // El evento y la sesión se abren al tocarlos (llevan su flecha).
      expect(find.bySemanticsLabel(RegExp('Repasar Cálculo')), findsWidgets);
      expect(find.textContaining('19:00 – 20:00'), findsOneWidget);

      await tester.tap(find.text('Lo hice'));
      await tester.pump();
      verify(
        () => home.add(
          const HomeDashboardEvent.completionSet(
            id: 'm1',
            kind: HomeEventKind.block,
            completed: true,
          ),
        ),
      ).called(1);

      await tester.tap(find.text('Quitar'));
      verify(
        () => home.add(const HomeDashboardEvent.missedRemoved('m1')),
      ).called(1);

      await tester.tap(find.text('Pasar a otro día'));
      await tester.pumpAndSettle();
      expect(find.text('¿A qué día lo pasas?'), findsOneWidget);
      expect(find.text('A la misma hora: 19:00'), findsOneWidget);
      await tester.tap(find.textContaining('Mañana, '));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      verify(
        () => home.add(
          HomeDashboardEvent.missedMoved(
            eventId: 'm1',
            start: DateTime(now.year, now.month, now.day + 1, 19),
            end: DateTime(now.year, now.month, now.day + 1, 20),
          ),
        ),
      ).called(1);
    });

    testWidgets('con varios, se ve uno y «Ver los 2»', (tester) async {
      when(() => home.state).thenReturn(
        loadedWith(
          halfDone.copyWith(
            missedEvents: [
              missedStudy,
              missedStudy.copyWith(id: 'm2', title: 'Correr'),
            ],
          ),
        ),
      );
      await pump(tester);

      expect(find.text('Ayer quedaron 2 cosas sin marcar'), findsOneWidget);
      expect(find.text('Correr'), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Ver los 2'));
      await tester.pump();
      expect(find.text('Correr'), findsOneWidget);
    });

    testWidgets('si «Empezar» no pudo, lleva a la tarjeta y lo explica', (
      tester,
    ) async {
      whenListen(
        home,
        Stream.fromIterable([
          loadedWith(halfDone).copyWith(showUnfinished: true),
        ]),
        initialState: loadedWith(halfDone),
      );
      await pump(tester);
      await tester.pump();

      expect(
        find.text(
          'Antes de empezar otra, guarda o descarta la sesión sin terminar.',
        ),
        findsOneWidget,
      );
      verify(
        () => home.add(const HomeDashboardEvent.trainingHandled()),
      ).called(1);
    });
  });

  group('cabecera y «Tu día» al grano (ADR 0059)', () {
    testWidgets('el icono de Comunidad dice cuántas solicitudes hay', (
      tester,
    ) async {
      when(() => home.state).thenReturn(loadedWith(halfDone));
      await pump(tester);

      expect(
        find.byTooltip('Comunidad, 2 solicitudes de amistad'),
        findsOneWidget,
      );
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('con entreno y clase hoy, la Agenda empieza hacia la mitad y '
        '«Próximo entreno» no se repite', (tester) async {
      final now = DateTime.now();
      final dashboard = homeDashboardFixture.copyWith(
        nextTrainingDay: const HomeNextTrainingDay(
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
        ),
        todayEvents: [
          HomeTodayEvent(
            id: 'c1',
            kind: HomeEventKind.block,
            type: HomeEventType.classSession,
            title: 'Bases de datos',
            start: DateTime(now.year, now.month, now.day, 10),
            end: DateTime(now.year, now.month, now.day, 12),
            completed: false,
            status: ItemTimeStatus.inProgress,
            place: 'Aula 2.4',
            teacher: 'Ana Ruiz',
          ),
        ],
        todaySummary: const HomeTodaySummary(spotlightEventId: 'c1'),
        nextDeadline: HomeNextDeadline(
          id: 'x1',
          title: 'Parcial 1',
          type: DeadlineType.exam,
          dueAt: now.add(const Duration(days: 4)),
          subjectName: 'Cálculo',
        ),
      );
      when(() => home.state).thenReturn(loadedWith(dashboard));
      tester.view.physicalSize = const Size(390, 844);
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
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>.value(value: session),
              BlocProvider<HomeDashboardBloc>.value(value: home),
            ],
            child: const HomeDashboardView(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Pierna y empuje'), findsOneWidget);
      expect(find.text('Clase de Bases de datos'), findsOneWidget);
      expect(find.text('Aula 2.4 · Ana Ruiz'), findsOneWidget);
      expect(find.text('Parcial 1'), findsOneWidget);
      // El entreno de hoy está en «Tu día»: no sale «Próximo entreno».
      expect(find.text('Próximo entreno'), findsNothing);
      // «Tu día» ocupa mucho menos: la Agenda empieza hacia la mitad.
      final agenda = tester.getTopLeft(find.text('Agenda').first).dy;
      expect(agenda, lessThan(844 * 0.62));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('se ve sin errores en tema oscuro', (tester) async {
    when(() => home.state).thenReturn(
      HomeDashboardState(
        status: HomeDashboardStatus.loaded,
        dashboard: homeDashboardFixture,
      ),
    );

    await pump(tester, theme: AppTheme.dark);

    expect(find.text('Tu día'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el error con reintento', (tester) async {
    when(() => home.state).thenReturn(
      const HomeDashboardState(
        status: HomeDashboardStatus.failure,
        error: AppError.network(),
      ),
    );

    await pump(tester);
    await tester.tap(find.text('Reintentar'));

    verify(() => home.add(const HomeDashboardEvent.refreshed())).called(1);
  });

  group('accesibilidad', () {
    setUp(
      () => when(() => home.state).thenReturn(
        HomeDashboardState(
          status: HomeDashboardStatus.loaded,
          dashboard: homeDashboardFixture,
          dueReviews: homeReviewsFixture,
        ),
      ),
    );

    testWidgets('cumple las guías de tamaño táctil, etiquetas y contraste', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets(
      'un bloque sin hacer a 360 dp y texto al 200 % lleva el aviso bajo el subtítulo',
      (tester) async {
        when(() => home.state).thenReturn(
          HomeDashboardState(
            status: HomeDashboardStatus.loaded,
            dashboard: homeDashboardFixture.copyWith(
              todayEvents: [
                HomeTodayEvent(
                  id: 'e3',
                  kind: HomeEventKind.block,
                  type: HomeEventType.study,
                  title: 'Repaso de integrales por partes y sustitución',
                  start: DateTime(2026, 10, 18, 8),
                  end: DateTime(2026, 10, 18, 9),
                  completed: false,
                  status: ItemTimeStatus.missed,
                ),
              ],
            ),
          ),
        );

        await pump(tester, textScale: 2, width: 360);

        // La pastilla de la agenda (la leyenda de «Tu semana» también dice
        // «Sin hacer»).
        final pill = find
            .descendant(
              of: find.byType(ListTile),
              matching: find.text('Sin hacer'),
            )
            .first;
        expect(pill, findsOneWidget);
        // Debajo del título, no a su derecha.
        expect(
          tester.getTopLeft(pill).dy,
          greaterThan(
            tester
                .getBottomLeft(find.textContaining('Repaso de integrales'))
                .dy,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('las tarjetas de arriba cumplen las guías y caben al 200 %', (
      tester,
    ) async {
      when(() => home.state).thenReturn(loadedWith(halfDone));
      final semantics = tester.ensureSemantics();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();

      await pump(tester, textScale: 2, width: 360);
      expect(find.text('Guardar lo hecho'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final language in ['en', 'fr', 'pt']) {
      testWidgets('en $language con texto al 200 % no se rompe', (
        tester,
      ) async {
        Intl.defaultLocale = language;
        addTearDown(() => Intl.defaultLocale = 'es');
        await pump(tester, textScale: 2, width: 360, language: language);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);

      expect(find.text('Tu semana'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
