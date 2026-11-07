import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/reminder_kind.dart';

part 'reminder_plan.freezed.dart';

/// Aviso ya decidido por el servidor (`GET /notifications/reminder-plan`):
/// qué, cuándo y con qué datos. [ReminderComposer] le pone textos e id.
@freezed
abstract class PlannedReminder with _$PlannedReminder {
  const factory PlannedReminder({
    required ReminderKind kind,

    /// Instante en que debe sonar.
    required DateTime at,

    /// Referencia estable: id del evento o día del aviso de repasos y del
    /// resumen de la mañana.
    required String refId,

    /// Repasos vencidos ([ReminderKind.dueReviews]) o días que faltan
    /// (entregas, exámenes y tareas de reto; 0 = hoy).
    int? count,

    /// Título o asignatura del evento, o título de la entrega o de la tarea;
    /// puede faltar.
    String? title,

    /// Inicio del evento, fecha de la entrega o de la tarea.
    DateTime? startsAt,

    /// Qué abrir al tocarlo cuando no es [refId] (entrega o reto).
    String? targetId,

    /// Aula de la clase (solo [ReminderKind.classSoon]).
    String? place,

    /// Tareas de reto que menciona el aviso (van con su entrega o su evento
    /// para no duplicar avisos, ADR 0035).
    @Default(<ReminderTask>[]) List<ReminderTask> tasks,

    /// Lo que trae el día (solo [ReminderKind.morningSummary]).
    ReminderDaySummary? summary,
  }) = _PlannedReminder;
}

/// Tarea de reto mencionada en un aviso. [title] nulo: el propio reto.
@freezed
abstract class ReminderTask with _$ReminderTask {
  const factory ReminderTask({
    required String challengeId,
    String? challengeTitle,
    String? milestoneId,
    String? title,
  }) = _ReminderTask;
}

/// Contenido del resumen de la mañana: cuántos estudios (estudio y repaso),
/// entrenos, clases y eventos personales hay, qué entregas y exámenes, cuántas
/// tareas de reto sueltas y si recuerda también el registro diario.
@freezed
abstract class ReminderDaySummary with _$ReminderDaySummary {
  const factory ReminderDaySummary({
    @Default(0) int studies,
    @Default(0) int trainings,
    @Default(0) int classes,
    @Default(0) int personal,
    @Default(<ReminderSummaryDeadline>[])
    List<ReminderSummaryDeadline> deadlines,
    @Default(0) int tasks,

    /// Ese día no llega aviso aparte del registro diario: va aquí.
    @Default(false) bool checkIn,
  }) = _ReminderDaySummary;
}

/// Entrega o examen del resumen de la mañana.
@freezed
abstract class ReminderSummaryDeadline with _$ReminderSummaryDeadline {
  const factory ReminderSummaryDeadline({
    String? title,
    @Default(false) bool exam,
  }) = _ReminderSummaryDeadline;
}
