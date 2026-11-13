import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/presentation/screens/challenges/challenges_routes.dart';
import 'package:synaptixfit/presentation/screens/home/home_external_paths.dart';
import 'package:synaptixfit/presentation/screens/planner/planner_routes.dart';
import 'package:synaptixfit/presentation/screens/progress/progress_routes.dart';

class _Context extends Mock implements BuildContext {}

class _State extends Mock implements GoRouterState {}

/// Navegación de la fase 2 (ADR 0038): Calendario es pestaña, Retos vive en
/// Progreso y las direcciones antiguas siguen llevando al sitio.
void main() {
  GoRoute route(List<RouteBase> routes, String path) =>
      routes.whereType<GoRoute>().firstWhere((r) => r.path == path);

  Future<String?> redirectOf(GoRoute r) async =>
      await r.redirect!(_Context(), _State());

  test('/challenges lleva a Progreso › Retos', () async {
    expect(
      await redirectOf(route(challengesRoutes(), ChallengesPaths.root)),
      '/progress?tab=challenges',
    );
    // Un reto, crear y la comunidad siguen siendo pantallas completas.
    final paths = challengesRoutes().whereType<GoRoute>().map((r) => r.path);
    expect(
      paths,
      containsAll([
        ChallengesPaths.create,
        ChallengesPaths.community,
        '/challenges/:challengeId',
      ]),
    );
  });

  test('/progress/badges lleva a Progreso › Insignias', () async {
    expect(
      await redirectOf(route(progressRoutes(), ProgressPaths.badges)),
      '/progress?tab=badges',
    );
    expect(ProgressTab.fromQuery('challenges'), ProgressTab.challenges);
    expect(ProgressTab.fromQuery('badges'), ProgressTab.badges);
    expect(ProgressTab.fromQuery(null), ProgressTab.summary);
  });

  test('el calendario es una pestaña y sus pantallas cuelgan sueltas', () {
    final branch = plannerBranchRoutes().whereType<GoRoute>().single;
    expect(branch.path, PlannerPaths.root);
    // Si colgaran de la pestaña, apilarlas desde una pantalla completa
    // duplicaría el armazón (pantalla en negro).
    expect(branch.routes, isEmpty);
    expect(
      plannerRoutes().whereType<GoRoute>().map((r) => r.path),
      containsAll([
        PlannerPaths.deadlines,
        PlannerPaths.pomodoro,
        PlannerPaths.suggestions,
        PlannerPaths.pastStudy,
        PlannerPaths.calendarSync,
        PlannerPaths.scheduleScan,
      ]),
    );
  });

  test('Inicio abre las pestañas con go y apila solo pantallas completas', () {
    expect(
      HomeExternalPaths.isTabRoute(
        HomeExternalPaths.plannerAt(DateTime(2026, 11, 13)),
      ),
      isTrue,
    );
    expect(HomeExternalPaths.isTabRoute(HomeExternalPaths.addEvent()), isTrue);
    expect(HomeExternalPaths.isTabRoute(HomeExternalPaths.challenges), isTrue);
    expect(
      HomeExternalPaths.isTabRoute(HomeExternalPaths.deadline('d1')),
      isFalse,
    );
    expect(HomeExternalPaths.isTabRoute(HomeExternalPaths.pomodoro), isFalse);
    expect(
      HomeExternalPaths.isTabRoute(HomeExternalPaths.challenge('c1')),
      isFalse,
    );
  });

  test('cada toque en «Añadir al calendario» es una dirección nueva', () {
    final a = HomeExternalPaths.addEvent(DateTime(2026, 11, 13, 10));
    final b = HomeExternalPaths.addEvent(DateTime(2026, 11, 13, 10, 1));
    expect(Uri.parse(a).path, PlannerPaths.root);
    expect(Uri.parse(a).queryParameters, contains('new'));
    expect(a, isNot(b));
  });
}
