import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/challenge_status.dart';
import 'package:synaptixfit/domain/models/challenges/challenge.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenge_detail/bloc/challenge_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenge_detail/page/challenge_detail_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'challenges_fixtures.dart';

class _MockDetailBloc
    extends MockBloc<ChallengeDetailEvent, ChallengeDetailState>
    implements ChallengeDetailBloc {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

void main() {
  late _MockDetailBloc detail;
  late _MockSessionBloc session;

  final done = ChallengesFixtures.milestone('m1', completed: true);
  final next = ChallengesFixtures.milestone('m2');
  final withTasks = ChallengesFixtures.challenge(milestones: [done, next]);

  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('fr');
  });

  setUp(() {
    detail = _MockDetailBloc();
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(null);
    getIt.registerFactory<ChallengeDetailBloc>(() => detail);
  });

  tearDown(() => getIt.unregister<ChallengeDetailBloc>());

  void show(Challenge challenge) => when(() => detail.state).thenReturn(
    ChallengeDetailState(
      status: ChallengeDetailStatus.ready,
      challenge: challenge,
    ),
  );

  Future<void> pump(
    WidgetTester tester, {
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
          home: const ChallengeDetailPage(challengeId: 'c1'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('con tareas, el siguiente paso arriba y su botón principal', (
    tester,
  ) async {
    show(withTasks);
    await pump(tester);

    expect(find.text('Siguiente paso'), findsOneWidget);
    // La tarea siguiente se marca en la lista con «Siguiente».
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('1/2 tareas'), findsOneWidget);

    await tester.tap(find.text('Completar siguiente tarea'));
    verify(
      () => detail.add(const ChallengeDetailEvent.milestoneToggled('m2')),
    ).called(1);
  });

  testWidgets('sin tareas, estado vacío útil y completar como principal', (
    tester,
  ) async {
    show(ChallengesFixtures.challenge());
    await pump(tester);

    expect(find.text('Sin tareas todavía'), findsOneWidget);
    expect(find.text('Añadir tareas'), findsOneWidget);
    expect(find.text('Completar reto'), findsOneWidget);
    expect(find.text('Registrar progreso'), findsOneWidget);
  });

  testWidgets('vencido: solo se ofrece ampliar la fecha', (tester) async {
    show(withTasks.copyWith(status: ChallengeStatus.expired));
    await pump(tester);

    expect(find.text('Ampliar fecha'), findsOneWidget);
    const hint = 'Se acabó el plazo. Amplía la fecha para seguir.';
    expect(find.text(hint), findsOneWidget);
    expect(find.text('Registrar progreso'), findsNothing);
    expect(find.text('Completar siguiente tarea'), findsNothing);

    // La tarea pendiente no se puede completar (el servidor lo rechazaría) y
    // su casilla explica por qué.
    expect(find.byTooltip('Completar «Tarea m2»'), findsNothing);
    await tester.tap(find.byTooltip(hint));
    verifyNever(
      () => detail.add(const ChallengeDetailEvent.milestoneToggled('m2')),
    );
  });

  testWidgets('reto ajeno: la acción es añadirlo a mis retos', (tester) async {
    show(ChallengesFixtures.challenge(owned: false));
    await pump(tester);

    await tester.tap(find.text('Añadir a mis retos'));
    verify(
      () => detail.add(const ChallengeDetailEvent.cloneRequested()),
    ).called(1);
    expect(find.text('Siguiente paso'), findsNothing);
  });

  group('accesibilidad', () {
    testWidgets('cumple las guías de tamaño táctil, etiquetas y contraste', (
      tester,
    ) async {
      show(withTasks);
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
      show(withTasks);
      await pump(tester, textScale: 2);

      expect(find.text('Completar siguiente tarea'), findsOneWidget);
      expect(find.text('Registrar progreso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en 320 px, en francés y al 200 % tampoco desborda', (
      tester,
    ) async {
      show(withTasks);
      await pump(tester, textScale: 2, width: 320, locale: const Locale('fr'));
      expect(tester.takeException(), isNull);
    });
  });
}
