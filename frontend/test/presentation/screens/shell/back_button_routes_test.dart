import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/academic_routes.dart';
import 'package:synaptixfit/presentation/screens/admin/admin_routes.dart';
import 'package:synaptixfit/presentation/screens/admin/hub/bloc/admin_hub_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/metrics/bloc/admin_metrics_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/user_detail/bloc/admin_user_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenge_detail/bloc/challenge_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenges_routes.dart';
import 'package:synaptixfit/presentation/screens/home/home_routes.dart';
import 'package:synaptixfit/presentation/screens/planner/deadlines/bloc/deadlines_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/planner_routes.dart';
import 'package:synaptixfit/presentation/screens/profile/profile_routes.dart';
import 'package:synaptixfit/presentation/screens/progress/progress_routes.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/study_room_bar_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/social_routes.dart';
import 'package:synaptixfit/presentation/screens/social/together/safety/bloc/together_safety_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/study_room/bloc/study_room_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/session_detail/bloc/session_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/shared_routine/bloc/shared_routine_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/training_routes.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Toda pantalla que no es pestaña tiene salida: la flecha «Volver»
/// ([AppBackButton]) vuelve si hay pila y, abierta en frío (aviso del móvil,
/// enlace, redirección, recarga en web), lleva a la pantalla de la que cuelga.

class _Context extends Mock implements BuildContext {}

class _State extends Mock implements GoRouterState {}

class _MockAccount extends Mock implements Account {}

class _MockSession extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class _MockSessionDetail
    extends MockBloc<SessionDetailEvent, SessionDetailState>
    implements SessionDetailBloc {}

class _MockChallenge
    extends MockBloc<ChallengeDetailEvent, ChallengeDetailState>
    implements ChallengeDetailBloc {}

class _MockRoom extends MockBloc<StudyRoomEvent, StudyRoomState>
    implements StudyRoomBloc {}

class _MockBar extends MockBloc<StudyRoomBarEvent, StudyRoomBarState>
    implements StudyRoomBarBloc {}

class _MockSafety extends MockBloc<TogetherSafetyEvent, TogetherSafetyState>
    implements TogetherSafetyBloc {}

class _MockShared extends MockBloc<SharedRoutineEvent, SharedRoutineState>
    implements SharedRoutineBloc {}

class _MockDeadlines extends MockBloc<DeadlinesEvent, DeadlinesState>
    implements DeadlinesBloc {}

class _MockAdminHub extends MockBloc<AdminHubEvent, AdminHubState>
    implements AdminHubBloc {}

class _MockAdminMetrics extends MockBloc<AdminMetricsEvent, AdminMetricsState>
    implements AdminMetricsBloc {}

class _MockAdminUser
    extends MockBloc<AdminUserDetailEvent, AdminUserDetailState>
    implements AdminUserDetailBloc {}

/// Pantallas sin flecha a propósito y por qué (las pestañas no están en la
/// tabla de pantallas completas).
const _withoutArrow = {
  // Pasos obligatorios: se sigue con su botón, no se vuelve.
  'LegalAcceptancePage': 'aceptar o cerrar sesión',
  'OnboardingPage': 'su flecha va al paso anterior',
  'PermissionsIntroPage': '«Continuar»',
  'SessionCompletedPage': '«Volver a rutinas» y «Cerrar»',
  // Editor con «Cerrar» (X) que pregunta antes de perder lo hecho.
  'RoutineEditorPage': 'cierra con X',
};

void main() {
  group('la tabla de rutas entera', () {
    /// Rutas de pantalla completa y las que viven dentro de una pestaña
    /// (rutina, ejercicio, historial…), sin las raíces de las pestañas.
    List<({String path, GoRouterWidgetBuilder builder})> fullScreen() {
      final all = <({String path, GoRouterWidgetBuilder builder})>[];
      void walk(Iterable<RouteBase> routes, String parent) {
        for (final r in routes.whereType<GoRoute>()) {
          final path = r.path.startsWith('/')
              ? r.path
              : '${parent == '/' ? '' : parent}/${r.path}';
          if (r.builder case final b?) all.add((path: path, builder: b));
          walk(r.routes, path);
        }
      }

      walk([
        ...homeRoutes(),
        ...academicRoutes(),
        ...trainingRoutes(),
        ...challengesRoutes(),
        ...progressRoutes(),
        ...profileRoutes(),
        ...plannerRoutes(),
        ...socialRoutes(),
        ...adminRoutes(),
      ], '/');
      // Dentro de las pestañas: solo las hijas, la raíz es la pestaña.
      for (final tab in [
        ...plannerBranchRoutes(),
        ...academicBranchRoutes(),
        ...trainingBranchRoutes(),
        ...progressBranchRoutes(),
        ...homeBranchRoutes(),
      ].whereType<GoRoute>()) {
        walk(tab.routes, tab.path);
      }
      return all;
    }

    test('cada pantalla que construye la tabla lleva AppBackButton', () {
      final sources = {
        for (final f
            in Directory('lib/presentation/screens')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart')))
          f.path: f.readAsStringSync(),
      };
      final missing = <String>[];
      final seen = <String>{};
      final routes = fullScreen();
      expect(routes.length, greaterThan(60));
      for (final route in routes) {
        final page = route.builder(_Context(), _stateFor(route.path));
        final name = page.runtimeType.toString();
        seen.add(name);
        if (_withoutArrow.containsKey(name)) continue;
        final file = sources.entries
            .where((e) => e.value.contains(RegExp('class $name\\b')))
            .map((e) => e.value)
            .single;
        // Cada barra de la página (carga, error, contenido) lleva la suya.
        final bars = RegExp(
          r'AppPageBar(\.reading|\.wide)?\(',
        ).allMatches(file);
        final arrows = 'AppBackButton('.allMatches(file);
        if (arrows.isEmpty || arrows.length < bars.length) {
          missing.add('${route.path} → $name');
        }
      }
      expect(missing, isEmpty, reason: 'Pantallas sin flecha «Volver»');
      // La lista de excepciones no guarda pantallas que ya no existen.
      expect(seen, containsAll(_withoutArrow.keys));
    });
  });

  group('abiertas en frío, «Volver» lleva al padre', () {
    late _MockSession session;

    setUp(() {
      session = _MockSession();
      final admin = _MockAccount();
      when(() => admin.isAdmin).thenReturn(true);
      when(() => session.state).thenReturn(const SessionState.unknown());
      when(() => session.account).thenReturn(admin);

      T mock<T extends BlocBase<S>, S>(T bloc, S state) {
        when(() => bloc.state).thenReturn(state);
        return bloc;
      }

      getIt
        ..registerSingleton<SessionBloc>(session)
        ..registerFactory<SessionDetailBloc>(
          () => mock(_MockSessionDetail(), const SessionDetailState()),
        )
        ..registerFactory<ChallengeDetailBloc>(
          () => mock(_MockChallenge(), const ChallengeDetailState()),
        )
        ..registerFactory<StudyRoomBloc>(
          () => mock(_MockRoom(), const StudyRoomState()),
        )
        ..registerFactory<StudyRoomBarBloc>(
          () => mock(_MockBar(), const StudyRoomBarState()),
        )
        ..registerFactory<TogetherSafetyBloc>(
          () => mock(_MockSafety(), const TogetherSafetyState()),
        )
        ..registerFactory<SharedRoutineBloc>(
          () => mock(_MockShared(), const SharedRoutineState()),
        )
        ..registerFactory<DeadlinesBloc>(
          () => mock(_MockDeadlines(), const DeadlinesState()),
        )
        ..registerFactory<AdminHubBloc>(
          () => mock(_MockAdminHub(), const AdminHubState()),
        )
        ..registerFactory<AdminMetricsBloc>(
          () => mock(_MockAdminMetrics(), const AdminMetricsState()),
        )
        ..registerFactory<AdminUserDetailBloc>(
          () => mock(_MockAdminUser(), const AdminUserDetailState()),
        );
    });

    tearDown(() => getIt.reset());

    /// Router con las rutas reales de [routes] y pantallas de mentira para los
    /// padres: así se ve a dónde lleva la flecha sin montar las pestañas.
    Future<GoRouter> open(
      WidgetTester tester,
      List<RouteBase> routes,
      String location,
      List<String> parents,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: location,
        routes: [
          ...routes,
          for (final p in parents)
            GoRoute(path: p, builder: (_, _) => Text('Padre $p')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider<SessionBloc>.value(
          value: session,
          child: MaterialApp.router(
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
            // Sin animaciones infinitas (esqueletos): se puede esperar fijo.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await _settle(tester);
      return router;
    }

    Future<void> back(WidgetTester tester) async {
      expect(find.byTooltip('Volver'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await _settle(tester);
    }

    String at(GoRouter r) =>
        r.routerDelegate.currentConfiguration.uri.toString();

    final cases = <(String, List<RouteBase> Function(), String, String)>[
      (
        'detalle de sesión → historial',
        trainingRoutes,
        TrainingPaths.sessionDetail('s1'),
        TrainingPaths.history,
      ),
      (
        'reto → Progreso › Retos',
        challengesRoutes,
        ChallengesPaths.detail('c1'),
        ChallengesPaths.list,
      ),
      (
        'sala de estudio → «Con amigos»',
        socialRoutes,
        SocialPaths.togetherStudyRoom('r1'),
        SocialPaths.together,
      ),
      (
        'rutina compartida → Entreno',
        trainingRoutes,
        TrainingPaths.sharedRoutine('abc'),
        TrainingPaths.root,
      ),
      (
        'entregas → Calendario',
        plannerRoutes,
        PlannerPaths.deadline('d1'),
        PlannerPaths.root,
      ),
    ];

    for (final (name, routes, location, parent) in cases) {
      testWidgets(name, (tester) async {
        final parentPath = Uri.parse(parent).path;
        final r = await open(
          tester,
          routes().where((x) => x is! GoRoute || x.path != parentPath).toList(),
          location,
          [parentPath],
        );
        expect(at(r), location);

        await back(tester);

        expect(at(r), parent);
        expect(find.text('Padre $parentPath'), findsOneWidget);
      });
    }

    // El «atrás» del sistema (Android) sin pila iba a cerrar la app: ahora va
    // al padre, como la flecha (ADR 0046, cierre en el ADR 0047).
    for (final (name, routes, location, parent) in cases.take(3)) {
      testWidgets('atrás del sistema: $name', (tester) async {
        final parentPath = Uri.parse(parent).path;
        final r = await open(
          tester,
          routes().where((x) => x is! GoRoute || x.path != parentPath).toList(),
          location,
          [parentPath],
        );

        final handled = await tester.binding.handlePopRoute();
        await _settle(tester);

        expect(handled, isTrue);
        expect(at(r), parent);
        expect(find.text('Padre $parentPath'), findsOneWidget);
      });
    }

    testWidgets('atrás del sistema con un diálogo encima: cierra el diálogo', (
      tester,
    ) async {
      final (_, routes, location, parent) = cases.first;
      final parentPath = Uri.parse(parent).path;
      final r = await open(
        tester,
        routes().where((x) => x is! GoRoute || x.path != parentPath).toList(),
        location,
        [parentPath],
      );
      final context = tester.element(find.byTooltip('Volver'));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('Diálogo')),
        ),
      );
      await _settle(tester);
      expect(find.text('Diálogo'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.text('Diálogo'), findsNothing);
      expect(at(r), location);
    });

    testWidgets('atrás del sistema con pila: vuelve a la de debajo', (
      tester,
    ) async {
      final (_, routes, location, parent) = cases.first;
      final parentPath = Uri.parse(parent).path;
      final r = await open(
        tester,
        routes().where((x) => x is! GoRoute || x.path != parentPath).toList(),
        parentPath,
        [parentPath],
      );
      unawaited(r.push<void>(location));
      await _settle(tester);
      expect(r.state.uri.toString(), location);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(at(r), parentPath);
      expect(find.text('Padre $parentPath'), findsOneWidget);
    });

    testWidgets('admin: un usuario vuelve al panel y el panel, al perfil', (
      tester,
    ) async {
      // `/admin/users/:id` cuelga de `/admin`: en frío go_router monta el
      // panel debajo, así que aquí la flecha hace pop.
      final r = await open(tester, adminRoutes(), AdminPaths.userDetail('u1'), [
        AdminPaths.profile,
        HomePaths.root,
      ]);

      await back(tester);
      expect(at(r), AdminPaths.root);

      await back(tester);
      expect(at(r), AdminPaths.profile);
      expect(find.text('Padre ${AdminPaths.profile}'), findsOneWidget);
    });
  });

  test('el padre de lo académico es su asignatura o Académico', () {
    expect(AcademicPaths.subjectOrHome(null), AcademicPaths.root);
    expect(AcademicPaths.subjectOrHome(''), AcademicPaths.root);
    expect(AcademicPaths.subjectOrHome('s1'), AcademicPaths.subject('s1'));
    expect(
      AcademicPaths.subjectOrHome('s1', notes: true),
      AcademicPaths.subjectNotes('s1'),
    );
  });

  test('los padres fuera de una pestaña acaban en una pestaña', () {
    // «Con amigos» y el panel de admin son pantallas completas: su propia
    // flecha lleva a una pestaña (Progreso) o al perfil, que lleva a Inicio.
    expect(SocialExternalPaths.progressChallenges, ProgressPaths.challenges);
    expect(SocialExternalPaths.isTabRoot(SocialExternalPaths.home), isTrue);
    expect(ProfilePaths.home, HomePaths.root);
  });
}

/// Unos pocos fotogramas: la transición de página y la primera carga.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Estado de go_router para construir la página de [path] con parámetros de
/// relleno, sin `extra`.
GoRouterState _stateFor(String path) {
  final params = {
    for (final m in RegExp(r':(\w+)').allMatches(path)) m.group(1)!: 'x1',
  };
  final location = path.replaceAllMapped(RegExp(r':(\w+)'), (_) => 'x1');
  final state = _State();
  when(() => state.pathParameters).thenReturn(params);
  when(() => state.uri).thenReturn(Uri.parse(location));
  when(() => state.extra).thenReturn(null);
  when(() => state.matchedLocation).thenReturn(location);
  return state;
}
