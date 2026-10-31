import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/challenge_tasks_filter.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_query.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_summary.dart';
import 'package:synaptixfit/domain/models/challenges/pending_milestone.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenges_list/bloc/challenges_list_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenges_list/page/challenges_page.dart';
import 'package:synaptixfit/presentation/screens/challenges/community_challenges/bloc/community_challenges_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/widgets/pending_milestone_tile.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'challenges_fixtures.dart';

class _MockListBloc extends MockBloc<ChallengesListEvent, ChallengesListState>
    implements ChallengesListBloc {}

class _MockCommunityBloc
    extends MockBloc<CommunityChallengesEvent, CommunityChallengesState>
    implements CommunityChallengesBloc {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

void main() {
  late _MockListBloc list;
  late _MockCommunityBloc community;
  late _MockSessionBloc session;

  const query = ChallengeQuery(tasks: ChallengeTasksFilter.withTasks);

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    list = _MockListBloc();
    community = _MockCommunityBloc();
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(null);
    when(() => community.state).thenReturn(const CommunityChallengesState());
    when(() => list.state).thenReturn(
      ChallengesListState(
        status: ChallengesListStatus.ready,
        query: query,
        challenges: [ChallengesFixtures.challenge()],
        summary: const ChallengeSummary(
          active: 1,
          completed: 0,
          expired: 0,
          total: 1,
        ),
      ),
    );
    getIt
      ..registerFactory<ChallengesListBloc>(() => list)
      ..registerFactory<CommunityChallengesBloc>(() => community);
  });

  tearDown(() {
    getIt
      ..unregister<ChallengesListBloc>()
      ..unregister<CommunityChallengesBloc>();
  });

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(390, 1600 * textScale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp(
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
          home: const ChallengesPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a la vista solo los filtros de estado y «Filtros (n)»', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Activos (1)'), findsOneWidget);
    expect(find.text('Con tareas'), findsNothing);
    expect(find.text('Académico'), findsNothing);
    // Un filtro de la hoja activo (con tareas) y «Quitar filtros» a mano.
    expect(find.text('Filtros (1)'), findsOneWidget);
    expect(find.text('Quitar filtros'), findsOneWidget);
  });

  testWidgets('la hoja de filtros cambia tipo y tareas', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();

    expect(find.text('Académico'), findsOneWidget);
    expect(find.text('Físico'), findsOneWidget);
    expect(find.text('Con tareas'), findsOneWidget);

    await tester.tap(find.text('Sin tareas'));
    verify(
      () => list.add(
        ChallengesListEvent.queryChanged(
          query.copyWith(tasks: ChallengeTasksFilter.withoutTasks),
        ),
      ),
    ).called(1);

    // «Quitar filtros» de la hoja solo limpia tipo y tareas.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Quitar filtros'),
      ),
    );
    verify(
      () => list.add(
        ChallengesListEvent.queryChanged(
          query.copyWith(type: null, tasks: null),
        ),
      ),
    ).called(1);
  });

  testWidgets('los estados sin retos no ocupan sitio', (tester) async {
    await pump(tester);

    expect(find.text('Completados (0)'), findsNothing);
    expect(find.text('Vencidos (0)'), findsNothing);
  });

  testWidgets('la primera vez solo hay bienvenida y cómo empezar', (
    tester,
  ) async {
    when(
      () => list.state,
    ).thenReturn(const ChallengesListState(status: ChallengesListStatus.ready));
    await pump(tester);

    expect(find.text('Tu primer reto empieza aquí'), findsOneWidget);
    expect(find.text('Filtros'), findsNothing);
    expect(find.text('Tus retos'), findsNothing);

    await tester.tap(find.text('Ver retos de la comunidad'));
    // Un fotograma para empezar el cambio de pestaña, otro al terminar y el
    // último para pintar la página nueva.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(
      find.text(
        'Inspírate en los retos que comparten otros estudiantes y añádelos '
        'a los tuyos.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('las tareas pendientes se resumen en tres con «Ver todas»', (
    tester,
  ) async {
    when(() => list.state).thenReturn(
      ChallengesListState(
        status: ChallengesListStatus.ready,
        challenges: [ChallengesFixtures.challenge()],
        summary: const ChallengeSummary(
          active: 1,
          completed: 0,
          expired: 0,
          total: 1,
        ),
        pending: [
          for (var i = 0; i < 5; i++)
            PendingMilestone(
              challengeId: 'c1',
              challengeTitle: 'Reto c1',
              challengeEndAt: DateTime(2026, 10, 30),
              milestone: ChallengesFixtures.milestone('p$i'),
            ),
        ],
      ),
    );
    await pump(tester);

    expect(find.byType(PendingMilestoneTile), findsNWidgets(3));
    await tester.tap(find.text('Ver todas (5)'));
    await tester.pump();
    expect(find.byType(PendingMilestoneTile), findsNWidgets(5));
    expect(find.text('Ver menos'), findsOneWidget);
  });

  group('accesibilidad', () {
    testWidgets('cumple las guías de tamaño táctil, etiquetas y contraste', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      semantics.dispose();
    });

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);
      expect(find.text('Filtros (1)'), findsOneWidget);

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      expect(find.text('Sin tareas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
