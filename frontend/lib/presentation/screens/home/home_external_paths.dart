import '../../../domain/models/home/home_setup.dart';

/// Rutas de otros módulos a las que navega el inicio (mapa de rutas compartido).
///
/// Se escriben como texto para no depender de los ficheros de otros módulos.
/// Las que viven dentro de otra pestaña se abren cambiando de pestaña
/// ([isTabRoute]); el resto se apilan encima del inicio.
abstract final class HomeExternalPaths {
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const permissionsIntro = '/permissions-intro';
  static const notifications = '/notifications';
  static const community = '/social';
  static const admin = '/admin';

  static const planner = '/planner';
  static const deadlines = '/planner/deadlines';
  static const pomodoro = '/planner/pomodoro';

  /// Pomodoro que empieza por una pausa («Descanso guiado»).
  static const pomodoroBreak = '/planner/pomodoro?phase=break';
  static const scheduleScan = '/planner/schedule-scan';

  /// Pomodoro ligado a un bloque del calendario: las fases cuentan para él y
  /// para su asignatura (el servidor la saca del bloque).
  static String pomodoroFor({required String blockId, String? title}) => Uri(
    path: pomodoro,
    queryParameters: {'blockId': blockId, 'title': ?title},
  ).toString();

  /// Calendario abierto en el día de [day] y, con [blockId], en ese bloque.
  static String plannerAt(DateTime day, {String? blockId}) => Uri(
    path: planner,
    queryParameters: {
      'week':
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}',
      'block': ?blockId,
    },
  ).toString();

  static const training = '/training';
  static const newRoutine = '/training/routines/new';
  static String routine(String routineId) => '/training/routines/$routineId';
  static const checkIn = '/training/check-in';

  /// Grabar una carrera con el GPS (pantalla completa, ADR 0037).
  static const recordRun = '/training/run/record';

  /// Sesión en vivo (pantalla completa).
  static String session(String sessionId) => '/training/sessions/$sessionId';
  static const progress = '/progress';

  static const challenges = '/challenges';
  static const newChallenge = '/challenges/new';
  static String challenge(String id) => '/challenges/$id';

  static const analytics = '/progress/analytics';
  static const badges = '/progress/badges';

  /// Repaso de un material; [queue], los que vienen después («Repasar todos»).
  static String materialReview(
    String materialId, {
    List<String> queue = const [],
  }) =>
      '/academic/materials/$materialId/review'
      '${queue.isEmpty ? '' : '?queue=${queue.join(',')}'}';

  static const subjects = '/profile/subjects';
  static const wellnessProfile = '/profile/wellness';
  static const academicProfile = '/profile/academic';

  /// Dónde se resuelve cada tarea de configuración pendiente.
  static String setupTask(HomeSetupTask task) => switch (task) {
    HomeSetupTask.subjects => subjects,
    HomeSetupTask.wellnessProfile => wellnessProfile,
    HomeSetupTask.routine => newRoutine,
    // Con el horario importado la semana ya tiene sus clases: es la forma más
    // rápida de empezar a planificar.
    HomeSetupTask.weekPlan => scheduleScan,
    HomeSetupTask.academicProfile => academicProfile,
  };

  /// Rutas que pertenecen a otra pestaña de la barra inferior.
  static bool isTabRoute(String path) =>
      path == training ||
      path.startsWith('$training/routines') ||
      path == challenges ||
      path == progress ||
      path == '/academic';
}
