import 'package:go_router/go_router.dart';

import 'calendar/page/calendar_page.dart';
import 'calendar_sync/page/calendar_sync_page.dart';
import 'deadlines/page/deadlines_page.dart';
import 'pomodoro/page/pomodoro_page.dart';
import 'schedule_scan/page/schedule_scan_page.dart';
import 'suggestions/page/suggestions_page.dart';

/// Rutas del módulo planner (todas a pantalla completa, sin barra inferior).
abstract final class PlannerPaths {
  /// Calendario semanal. Acepta `?week=yyyy-MM-dd` (cualquier día de la semana).
  static const root = '/planner';
  static const deadlines = '/planner/deadlines';
  static const pomodoro = '/planner/pomodoro';

  /// Pomodoro que empieza por una pausa corta («Descanso guiado»).
  static const pomodoroBreak = '$pomodoro?phase=break';

  /// Pomodoro vinculado a una asignatura o a un bloque del calendario.
  static String pomodoroFor({
    String? subjectId,
    String? blockId,
    String? title,
  }) => Uri(
    path: pomodoro,
    queryParameters: {
      'subjectId': ?subjectId,
      'blockId': ?blockId,
      'title': ?title,
    },
  ).toString();
  static const suggestions = '/planner/suggestions';

  /// Ver el planificador en otro calendario e importar el del Campus Virtual.
  static const calendarSync = '/planner/calendar-sync';
  static const scheduleScan = '/planner/schedule-scan';

  /// Calendario abierto en la semana de [day].
  static String week(DateTime day) =>
      '$root?week=${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static DateTime? parseWeek(String? value) =>
      value == null ? null : DateTime.tryParse(value);
}

/// Rutas de otros módulos a las que lleva el planificador.
abstract final class PlannerExternalPaths {
  /// Detalle de una rutina (Entrenamiento), para entrenar el día de un bloque.
  static String routine(String routineId) => '/training/routines/$routineId';
}

/// Rutas a pantalla completa (sin barra inferior).
List<RouteBase> plannerRoutes() => [
  GoRoute(
    path: PlannerPaths.root,
    builder: (context, state) => CalendarPage(
      initialWeek: PlannerPaths.parseWeek(state.uri.queryParameters['week']),
    ),
    routes: [
      GoRoute(
        path: 'deadlines',
        builder: (context, state) => const DeadlinesPage(),
      ),
      GoRoute(
        path: 'pomodoro',
        builder: (context, state) => PomodoroPage(
          subjectId: state.uri.queryParameters['subjectId'],
          blockId: state.uri.queryParameters['blockId'],
          title: state.uri.queryParameters['title'],
          startWithBreak: state.uri.queryParameters['phase'] == 'break',
        ),
      ),
      GoRoute(
        path: 'suggestions',
        builder: (context, state) => const SuggestionsPage(),
      ),
      GoRoute(
        path: 'calendar-sync',
        builder: (context, state) => const CalendarSyncPage(),
      ),
      GoRoute(
        path: 'schedule-scan',
        builder: (context, state) => const ScheduleScanPage(),
      ),
    ],
  ),
];
