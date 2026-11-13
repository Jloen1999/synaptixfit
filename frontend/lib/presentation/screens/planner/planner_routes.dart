import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'calendar/page/calendar_page.dart';
import 'calendar_sync/page/calendar_sync_page.dart';
import 'deadlines/page/deadlines_page.dart';
import 'past_study/page/past_study_page.dart';
import 'pomodoro/page/pomodoro_page.dart';
import 'schedule_scan/page/schedule_scan_page.dart';
import 'suggestions/page/suggestions_page.dart';

/// Rutas del módulo planner: la pestaña Calendario y sus pantallas completas.
abstract final class PlannerPaths {
  /// Pestaña Calendario (se abre con `go`). Acepta `?new=<marca>` (abre la
  /// hoja «Añadir al calendario» en el próximo hueco; la marca cambia en cada
  /// toque para que la pestaña la vuelva a abrir), `?week=yyyy-MM-dd` (cualquier día de la semana),
  /// `&block=<id>` para abrir ese evento (desde la agenda o un aviso) y
  /// `&day=yyyy-MM-dd` para colocarse en ese día (desde «Tu semana»).
  static const root = '/planner';
  static const deadlines = '/planner/deadlines';

  /// Entregas con [id] destacada arriba (desde su aviso).
  static String deadline(String id) =>
      Uri(path: deadlines, queryParameters: {'focus': id}).toString();

  /// Entregas con el formulario de una nueva ya abierto (ADR 0039): «+ Entrega»
  /// de Académico y de la asignatura ([subjectId]) y «Entrega»/«Examen» de la
  /// hoja del calendario ([exam] y la hora tocada en [due]).
  static String newDeadline({
    String? subjectId,
    bool exam = false,
    DateTime? due,
  }) => Uri(
    path: deadlines,
    queryParameters: {
      'new': '1',
      'subject': ?subjectId,
      if (exam) 'type': 'exam',
      'due': ?due?.toIso8601String(),
    },
  ).toString();
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

  /// Apuntar estudio ya hecho sin la app (últimos 7 días).
  static const pastStudy = '/planner/past-study';

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

  /// Ajustes › Avisos (Perfil, pantalla completa): la antelación de los avisos
  /// es global, no de cada evento.
  static const notificationSettings = '/profile/settings/notifications';
}

/// Pestaña Calendario (conserva la barra inferior). Se abre con `go`. La
/// clave por consulta recrea la pantalla cuando un enlace pide otra semana,
/// día o evento; volver a la pestaña con la barra conserva lo que había.
List<RouteBase> plannerBranchRoutes() => [
  GoRoute(
    path: PlannerPaths.root,
    builder: (context, state) => CalendarPage(
      key: ValueKey(state.uri.query),
      initialWeek: PlannerPaths.parseWeek(state.uri.queryParameters['week']),
      initialBlockId: state.uri.queryParameters['block'],
      initialDay: PlannerPaths.parseWeek(state.uri.queryParameters['day']),
      initialCreate: state.uri.queryParameters.containsKey('new'),
    ),
  ),
];

/// Rutas a pantalla completa (sin barra inferior), encima de cualquier
/// pestaña con `push`. Van sueltas, no colgando de `/planner`: si colgaran de
/// la pestaña, abrirlas desde otra pantalla completa duplicaría el armazón.
List<RouteBase> plannerRoutes() => [
  GoRoute(
    path: PlannerPaths.deadlines,
    builder: (context, state) {
      final q = state.uri.queryParameters;
      return DeadlinesPage(
        focusId: q['focus'],
        create: q.containsKey('new')
            ? DeadlineCreateRequest(
                subjectId: q['subject'],
                exam: q['type'] == 'exam',
                due: DateTime.tryParse(q['due'] ?? ''),
              )
            : null,
      );
    },
  ),
  GoRoute(
    path: PlannerPaths.pomodoro,
    builder: (context, state) => PomodoroPage(
      subjectId: state.uri.queryParameters['subjectId'],
      blockId: state.uri.queryParameters['blockId'],
      title: state.uri.queryParameters['title'],
      startWithBreak: state.uri.queryParameters['phase'] == 'break',
    ),
  ),
  GoRoute(
    path: PlannerPaths.pastStudy,
    builder: (context, state) => const PastStudyPage(),
  ),
  GoRoute(
    path: PlannerPaths.suggestions,
    builder: (context, state) => const SuggestionsPage(),
  ),
  GoRoute(
    path: PlannerPaths.calendarSync,
    builder: (context, state) => const CalendarSyncPage(),
  ),
  GoRoute(
    path: PlannerPaths.scheduleScan,
    builder: (context, state) => const ScheduleScanPage(),
  ),
];
