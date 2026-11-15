import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/models/social/together_live.dart';
import 'package:synaptixfit/presentation/extensions/context_extensions.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/home_routes.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/together_live_bloc.dart';
import 'package:synaptixfit/presentation/screens/shell/widgets/together_live_host.dart';
import 'package:synaptixfit/presentation/screens/social/social_routes.dart';
import 'package:synaptixfit/presentation/screens/training/training_routes.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'together_live_fakes.dart';

/// `TogetherLiveHost` (ADR 0047): el aviso «Ana ha empezado · Ir» fuera de la
/// sesión y de la pantalla de espera, y al abrir la app, directo a la sesión.
void main() {
  late FakeWatchLive watch;
  late FakeGetWorkout getWorkout;
  late FakeOverview overview;

  setUp(() {
    watch = FakeWatchLive();
    getWorkout = FakeGetWorkout(workout());
    overview = FakeOverview(TogetherOverview(workouts: [workout()]));
    getIt.registerFactory<TogetherLiveBloc>(
      () => liveBloc(watch: watch, getWorkout: getWorkout, overview: overview),
    );
  });

  tearDown(() => getIt.reset());

  Future<GoRouter> open(WidgetTester tester, String location) async {
    Widget page(String name) => Scaffold(body: Text(name));
    final router = GoRouter(
      initialLocation: location,
      routes: [
        ShellRoute(
          builder: (_, _, child) => TogetherLiveHost(child: child),
          routes: [
            GoRoute(path: HomePaths.root, builder: (_, _) => page('Inicio')),
            GoRoute(
              path: SocialPaths.togetherWorkoutPattern,
              builder: (_, _) => page('Espera'),
            ),
            GoRoute(
              path: '${TrainingPaths.root}/sessions/:id',
              builder: (_, _) => page('Sesión'),
            ),
            GoRoute(
              path: SocialPaths.togetherStudyRoomPattern,
              builder: (_, _) => page('Sala'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    return router;
  }

  Future<void> friendStarts(WidgetTester tester) async {
    getWorkout.current = workout(
      startedAt: DateTime(2026, 11, 16, 18),
      startedBy: ana,
    );
    watch.signal(TogetherLiveTopic.workout, 'w1');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String at(GoRouter r) => r.state.uri.path;

  testWidgets(
    'en otra parte de la app: «Ana ha empezado a entrenar · Entrar» lleva a la sesión',
    (tester) async {
      final r = await open(tester, HomePaths.root);

      await friendStarts(tester);

      expect(find.text('Ana ha empezado a entrenar'), findsOneWidget);
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(at(r), TrainingPaths.session('s-me'));
    },
  );

  testWidgets('un «Deshacer» abierto no se tapa ni se confirma por el aviso', (
    tester,
  ) async {
    await open(tester, HomePaths.root);
    var committed = false;
    final context = tester.element(find.text('Inicio'));
    context.showUndoSnack(
      'Borrado',
      onUndo: () {},
      onCommit: () => committed = true,
    );
    await tester.pump();

    await friendStarts(tester);

    expect(find.text('Borrado'), findsOneWidget);
    expect(committed, isFalse);
  });

  testWidgets('en la pantalla de espera no hay aviso (entra sola)', (
    tester,
  ) async {
    await open(tester, SocialPaths.togetherWorkout('w1'));

    await friendStarts(tester);

    expect(find.text('Ana ha empezado a entrenar'), findsNothing);
  });

  testWidgets('al abrir la app con un entreno en marcha, va a la sesión', (
    tester,
  ) async {
    overview.value = TogetherOverview(
      workouts: [
        workout(startedAt: DateTime(2026, 11, 16, 18), startedBy: ana),
      ],
    );
    final r = await open(tester, HomePaths.root);
    await tester.pump(const Duration(milliseconds: 400));

    expect(at(r), TrainingPaths.session('s-me'));
  });

  testWidgets('si la app se abrió en otra pantalla (un aviso, un enlace), '
      'esa manda', (tester) async {
    overview.value = TogetherOverview(
      workouts: [
        workout(startedAt: DateTime(2026, 11, 16, 18), startedBy: ana),
      ],
    );
    final r = await open(tester, SocialPaths.togetherStudyRoom('r9'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(at(r), SocialPaths.togetherStudyRoom('r9'));
  });
}
