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

  /// Pestaña Calendario (`go`).
  static const planner = '/planner';

  /// Calendario con la hoja de «Añadir al calendario» abierta en el próximo
  /// hueco (botón de «Tu día» sin nada pendiente). La marca de tiempo hace
  /// que cada toque la abra aunque la pestaña ya estuviera en esa dirección.
  static String addEvent([DateTime? now]) => Uri(
    path: planner,
    queryParameters: {
      'new': '${(now ?? DateTime.now()).millisecondsSinceEpoch}',
    },
  ).toString();
  static const deadlines = '/planner/deadlines';

  /// Entregas con [id] la primera y destacada (aunque esté en otra página).
  static String deadline(String id) =>
      Uri(path: deadlines, queryParameters: {'focus': id}).toString();
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

  /// Calendario abierto en el día de [day] y, con [blockId], en ese evento;
  /// sin él, colocado en ese día.
  static String plannerAt(DateTime day, {String? blockId}) {
    final date =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return Uri(
      path: planner,
      queryParameters: {
        'week': date,
        if (blockId != null) 'block': blockId else 'day': date,
      },
    ).toString();
  }

  static const training = '/training';
  static const newRoutine = '/training/routines/new';
  static String routine(String routineId) => '/training/routines/$routineId';
  static const checkIn = '/training/check-in';

  /// Grabar una carrera con el GPS (pantalla completa, ADR 0037).
  static const recordRun = '/training/run/record';

  /// Sesión en vivo (pantalla completa).
  static String session(String sessionId) => '/training/sessions/$sessionId';
  static const progress = '/progress';

  /// Progreso › Retos (pestaña).
  static const challenges = '/progress?tab=challenges';
  static const newChallenge = '/challenges/new';
  static String challenge(String id) => '/challenges/$id';

  static const analytics = '/progress/analytics';

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

  /// Rutas que pertenecen a otra pestaña de la barra inferior (sin contar la
  /// consulta): se abren con `go`, nunca apiladas.
  static bool isTabRoute(String location) {
    final path = Uri.parse(location).path;
    return path == planner ||
        path == training ||
        path.startsWith('$training/routines') ||
        path == progress ||
        path == '/academic';
  }
}
