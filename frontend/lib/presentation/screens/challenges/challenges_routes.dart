import 'package:go_router/go_router.dart';

import '../../../domain/enums/challenge_difficulty.dart';
import '../../../domain/enums/challenge_type.dart';
import 'challenge_detail/page/challenge_detail_page.dart';
import 'challenge_form/page/challenge_form_page.dart';
import 'community_challenges/page/community_challenges_page.dart';

/// Rutas del módulo challenges.
///
/// | Ruta | Pantalla | Parámetros |
/// |---|---|---|
/// | `/challenges` | Dirección antigua: lleva a Progreso › Retos | — |
/// | `/challenges/new` | Nuevo reto completo | `extra` opcional: `Map` con `prefilledTitle`, `subjectId`, `subjectName` (y `type`, `difficulty`, `endAt`, `sessionTarget`) |
/// | `/challenges/community` | Retos de la comunidad | — |
/// | `/challenges/:challengeId` | Detalle del reto | — |
/// | `/challenges/:challengeId/milestones` | Editar tareas del reto | — |
///
/// `/challenges/new` devuelve con `pop` el id del reto creado.
abstract final class ChallengesPaths {
  /// Dirección antigua de la pestaña Retos (avisos de versiones anteriores,
  /// enlaces): redirige a [list].
  static const root = '/challenges';

  /// Tus retos: Progreso › Retos. Es una pestaña: se abre con `go`.
  static const list = '/progress?tab=challenges';
  static const create = '/challenges/new';
  static const community = '/challenges/community';

  static String detail(String challengeId) => '/challenges/$challengeId';

  static String editMilestones(String challengeId) =>
      '/challenges/$challengeId/milestones';
}

/// Rutas de otros módulos a las que navega este módulo.
abstract final class ChallengesExternalPaths {
  static String note(String noteId) => '/academic/notes/$noteId';
  static const deadlines = '/planner/deadlines';

  /// Entregas y exámenes con [id] la primera y destacada (aunque esté en otra
  /// página, vencida o ya hecha).
  static String deadline(String id) =>
      Uri(path: deadlines, queryParameters: {'focus': id}).toString();
  static const planner = '/planner';

  /// Pestaña Rutinas: se navega con `go` (es una pestaña, no una pantalla).
  static const training = '/training';
}

/// Valores iniciales del formulario «Nuevo reto» recibidos por `extra`.
class ChallengeFormArgs {
  const ChallengeFormArgs({
    this.title,
    this.subjectId,
    this.subjectName,
    this.type,
    this.difficulty,
    this.endAt,
    this.sessionTarget,
  });

  /// Acepta un `Map` (desde otros módulos) o un [ChallengeFormArgs].
  factory ChallengeFormArgs.fromExtra(Object? extra) {
    if (extra is ChallengeFormArgs) return extra;
    if (extra is! Map) return const ChallengeFormArgs();
    final type = extra['type'];
    final difficulty = extra['difficulty'];
    final endAt = extra['endAt'];
    final sessionTarget = extra['sessionTarget'];
    return ChallengeFormArgs(
      title: extra['prefilledTitle'] as String?,
      subjectId: extra['subjectId'] as String?,
      subjectName: extra['subjectName'] as String?,
      type: type is ChallengeType
          ? type
          : switch (type) {
              'ACADEMIC' => ChallengeType.academic,
              'FITNESS' => ChallengeType.fitness,
              _ => null,
            },
      difficulty: difficulty is ChallengeDifficulty ? difficulty : null,
      endAt: endAt is DateTime ? endAt : null,
      sessionTarget: sessionTarget is int ? sessionTarget : null,
    );
  }

  final String? title;
  final String? subjectId;
  final String? subjectName;
  final ChallengeType? type;
  final ChallengeDifficulty? difficulty;
  final DateTime? endAt;
  final int? sessionTarget;
}

/// Rutas a pantalla completa (sin barra inferior). La lista de retos vive en
/// Progreso (`ChallengesPage` dentro de `ProgressOverviewPage`, ADR 0038);
/// `/challenges` solo redirige allí.
List<RouteBase> challengesRoutes() => [
  GoRoute(path: ChallengesPaths.root, redirect: (_, _) => ChallengesPaths.list),
  GoRoute(
    path: ChallengesPaths.create,
    builder: (context, state) =>
        ChallengeFormPage(args: ChallengeFormArgs.fromExtra(state.extra)),
  ),
  GoRoute(
    path: ChallengesPaths.community,
    builder: (context, state) => const CommunityChallengesPage(),
  ),
  GoRoute(
    path: '${ChallengesPaths.root}/:challengeId',
    builder: (context, state) =>
        ChallengeDetailPage(challengeId: state.pathParameters['challengeId']!),
    routes: [
      GoRoute(
        path: 'milestones',
        builder: (context, state) => ChallengeFormPage(
          editChallengeId: state.pathParameters['challengeId'],
        ),
      ),
    ],
  ),
];
