import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/challenge_link_type.dart';
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

/// Fallo 10: «Ver en el planificador» de una tarea (o un reto) ligada a una
/// entrega abría «Entregas y exámenes» sin decir cuál; con muchas entregas,
/// o una vencida hace más de 30 días, la de la tarea no se veía. Ahora se
/// abre con `?focus=<id>`: la entrega va la primera y destacada.
void main() {
  late _MockDetailBloc detail;
  late _MockSessionBloc session;
  late Uri? opened;

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    opened = null;
    detail = _MockDetailBloc();
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(null);
    getIt.registerFactory<ChallengeDetailBloc>(() => detail);
  });

  tearDown(() => getIt.unregister<ChallengeDetailBloc>());

  Future<void> pump(WidgetTester tester, Challenge challenge) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => detail.state).thenReturn(
      ChallengeDetailState(
        status: ChallengeDetailStatus.ready,
        challenge: challenge,
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ChallengeDetailPage(challengeId: 'c1'),
        ),
        GoRoute(
          path: '/planner/deadlines',
          builder: (_, state) {
            opened = state.uri;
            return const SizedBox();
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('la tarea ligada a una entrega abre esa entrega', (
    tester,
  ) async {
    final task = ChallengesFixtures.milestone('m1').copyWith(
      link: const ChallengeLink(
        type: ChallengeLinkType.delivery,
        entityId: 'd42',
      ),
      completedByLink: true,
    );
    await pump(
      tester,
      ChallengesFixtures.challenge(milestones: [task]),
    );

    await tester.tap(find.text('Ver en el planificador').first);
    await tester.pumpAndSettle();

    expect(opened?.queryParameters['focus'], 'd42');
  });

  testWidgets('el reto sin tareas ligado a un examen abre ese examen', (
    tester,
  ) async {
    await pump(
      tester,
      ChallengesFixtures.challenge().copyWith(
        link: const ChallengeLink(
          type: ChallengeLinkType.exam,
          entityId: 'e7',
        ),
        completedByLink: true,
      ),
    );

    await tester.tap(find.text('Ver en el planificador').first);
    await tester.pumpAndSettle();

    expect(opened?.queryParameters['focus'], 'e7');
  });
}
