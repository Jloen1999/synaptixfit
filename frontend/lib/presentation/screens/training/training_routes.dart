import 'package:go_router/go_router.dart';

import '../../../domain/models/training/session.dart';
import '../../../domain/models/training/session_history.dart';
import 'check_in/page/check_in_page.dart';
import 'community/page/community_page.dart';
import 'exercise_detail/page/exercise_detail_page.dart';
import 'exercise_explorer/page/exercise_explorer_page.dart';
import 'cycle/page/cycle_page.dart';
import 'past_activity/page/past_activity_page.dart';
import 'live_session/page/live_session_page.dart';
import 'routine_detail/page/routine_detail_page.dart';
import 'routine_editor/page/routine_editor_page.dart';
import 'session_completed/page/session_completed_page.dart';
import 'session_detail/page/session_detail_page.dart';
import 'session_history/page/session_history_page.dart';
import 'training_home/page/training_home_page.dart';
import 'weekly_plan/page/weekly_plan_page.dart';
import 'routine_templates/page/routine_templates_page.dart';
import 'run_detail/page/run_detail_page.dart';
import 'run_home/page/run_home_page.dart';
import 'run_recorder/page/run_recorder_page.dart';
import 'run_workout_editor/page/run_workout_editor_page.dart';
import 'widgets/training_section_bar.dart';
import '../../../domain/models/training/run.dart';

/// Rutas del módulo training.
abstract final class TrainingPaths {
  static const root = '/training';

  static const modeAi = 'ai';
  static const modeManual = 'manual';

  /// Nueva rutina: `mode` = [modeAi] (asistente con IA) o [modeManual].
  static String newRoutine({String mode = modeAi}) =>
      '$root/routines/new?mode=$mode';

  static String routine(String routineId) => '$root/routines/$routineId';

  static const exercises = '$root/exercises';

  /// Explorador en modo selección: devuelve el `Exercise` elegido con `pop`.
  static const exercisePicker = '$exercises?select=true';

  static String exercise(String exerciseId) => '$exercises/$exerciseId';

  /// Sesión en vivo (pantalla completa).
  static String session(String sessionId) => '$root/sessions/$sessionId';

  /// Resumen de sesión completada (`extra`: `FinishSessionResult` opcional).
  static String sessionCompleted(String sessionId) =>
      '${session(sessionId)}/completed';

  /// Detalle de solo lectura de una sesión terminada (`extra`:
  /// `SessionHistoryEntry` opcional). Devuelve una `SessionDetailAction`.
  static String sessionDetail(String sessionId) =>
      '${session(sessionId)}/detail';

  static const history = '$root/history';
  static const checkIn = '$root/check-in';
  static const weeklyPlan = '$root/weekly-plan';
  static const community = '$root/community';

  /// Plantillas de rutina listas para usar (dentro de la pestaña).
  static const templates = '$root/templates';
  static const pastActivity = '$root/past-activity';

  /// «Mi ciclo» (opcional, ADR 0033).
  static const cycle = '$root/cycle';

  /// Apartado de la pestaña Entreno («Gimnasio», «Correr»).
  static String section(TrainingSection s) =>
      s == TrainingSection.gym ? root : '$root?section=${s.query}';

  /// Historial abierto en «Actividades y partidos».
  static const activities = '$history?tab=activities';

  /// Detalle de una carrera (dentro de la pestaña).
  static String run(String blockId) => '$root/runs/$blockId';

  /// Muro de la Comunidad (fuera del módulo): «Ver» tras publicar.
  static const communityWall = '/social';

  /// Grabar una carrera (pantalla completa), con un entreno de carrera o
  /// desde su evento del calendario si se indican.
  static String recordRun({String? workoutId, String? eventId}) => _withQuery(
    '$root/run/record',
    {'workout': ?workoutId, 'event': ?eventId},
  );

  /// Crear un entreno de carrera (desde una plantilla si se indica).
  static String newRunWorkout({String? template}) =>
      _withQuery('$root/run-workouts/new', {'template': ?template});

  static String _withQuery(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query.isEmpty ? null : query).toString();

  /// Cambiar un entreno de carrera (`extra`: el `RunWorkout`).
  static String runWorkout(String id) => '$root/run-workouts/$id';
}

/// Rutas dentro de la pestaña (conservan la barra inferior).
List<RouteBase> trainingBranchRoutes() => [
  GoRoute(
    path: TrainingPaths.root,
    // Un solo destino con apartados (`?section=`): la barra inferior se
    // conserva y los enlaces a `/training/...` siguen funcionando.
    builder: (_, state) => switch (TrainingSection.fromQuery(
      state.uri.queryParameters['section'],
    )) {
      TrainingSection.run => const RunHomePage(),
      TrainingSection.gym => const TrainingHomePage(),
    },
    routes: [
      GoRoute(
        path: 'routines/new',
        builder: (_, state) => RoutineEditorPage(
          manual: state.uri.queryParameters['mode'] == TrainingPaths.modeManual,
        ),
      ),
      GoRoute(
        path: 'routines/:routineId',
        builder: (_, state) =>
            RoutineDetailPage(routineId: state.pathParameters['routineId']!),
      ),
      GoRoute(
        path: 'exercises',
        builder: (_, state) => ExerciseExplorerPage(
          selectMode: state.uri.queryParameters['select'] == 'true',
        ),
      ),
      GoRoute(
        path: 'exercises/:exerciseId',
        builder: (_, state) =>
            ExerciseDetailPage(exerciseId: state.pathParameters['exerciseId']!),
      ),
      GoRoute(path: 'community', builder: (_, _) => const CommunityPage()),
      GoRoute(
        path: 'templates',
        builder: (_, _) => const RoutineTemplatesPage(),
      ),
      GoRoute(
        path: 'history',
        builder: (_, state) => SessionHistoryPage(
          activities: state.uri.queryParameters['tab'] == 'activities',
        ),
      ),
      GoRoute(
        path: 'runs/:blockId',
        builder: (_, state) =>
            RunDetailPage(blockId: state.pathParameters['blockId']!),
      ),
      GoRoute(
        path: 'run-workouts/new',
        builder: (_, state) => RunWorkoutEditorPage(
          templateCode: state.uri.queryParameters['template'],
        ),
      ),
      GoRoute(
        path: 'run-workouts/:workoutId',
        builder: (_, state) => RunWorkoutEditorPage(
          workoutId: state.pathParameters['workoutId'],
          workout: state.extra is RunWorkout
              ? state.extra! as RunWorkout
              : null,
        ),
      ),
      GoRoute(path: 'weekly-plan', builder: (_, _) => const WeeklyPlanPage()),
    ],
  ),
];

/// Rutas a pantalla completa (sin barra inferior).
List<RouteBase> trainingRoutes() => [
  // El check-in se abre desde Inicio y desde Entreno: a pantalla completa
  // vuelve siempre a quien lo abrió.
  GoRoute(path: TrainingPaths.checkIn, builder: (_, _) => const CheckInPage()),
  GoRoute(
    path: TrainingPaths.pastActivity,
    builder: (_, _) => const PastActivityPage(),
  ),
  GoRoute(path: TrainingPaths.cycle, builder: (_, _) => const CyclePage()),
  // Grabar una carrera, a pantalla completa como la sesión en vivo.
  GoRoute(
    path: '${TrainingPaths.root}/run/record',
    builder: (_, state) => RunRecorderPage(
      workoutId: state.uri.queryParameters['workout'],
      eventId: state.uri.queryParameters['event'],
    ),
  ),
  // El resumen va como ruta hermana (no hija) para no reconstruir la sesión debajo.
  GoRoute(
    path: '${TrainingPaths.root}/sessions/:sessionId/completed',
    builder: (_, state) => SessionCompletedPage(
      sessionId: state.pathParameters['sessionId']!,
      result: state.extra is FinishSessionResult
          ? state.extra! as FinishSessionResult
          : null,
    ),
  ),
  GoRoute(
    path: '${TrainingPaths.root}/sessions/:sessionId/detail',
    builder: (_, state) => SessionDetailPage(
      sessionId: state.pathParameters['sessionId']!,
      entry: state.extra is SessionHistoryEntry
          ? state.extra! as SessionHistoryEntry
          : null,
    ),
  ),
  GoRoute(
    path: '${TrainingPaths.root}/sessions/:sessionId',
    builder: (_, state) =>
        LiveSessionPage(sessionId: state.pathParameters['sessionId']!),
  ),
];
