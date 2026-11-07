import 'package:intl/intl.dart';

import '../../../../domain/enums/reminder_kind.dart';
import '../../../../domain/models/reminders/reminder_plan.dart';
import '../../../../domain/models/reminders/reminder_texts.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Pone los textos traducidos a los avisos locales que decide el servidor
/// (los compone `ReminderComposer`). La crea [RemindersHost] con el idioma de
/// la app.
class L10nReminderTexts implements ReminderTexts {
  L10nReminderTexts(this._l10n)
    : _time = DateFormat.Hm(_l10n.localeName),
      _day = DateFormat.MMMEd(_l10n.localeName);

  final AppLocalizations _l10n;
  final DateFormat _time;
  final DateFormat _day;

  @override
  String get channelName => _l10n.remindersChannelName;

  @override
  String dueReviewsTitle(int count) => _l10n.remindersDueReviewsTitle;

  @override
  String dueReviewsBody(int count) => _l10n.remindersDueReviewsBody(count);

  @override
  String blockTitle(ReminderKind kind) => switch (kind) {
    ReminderKind.sportBlock => _l10n.remindersSportTitle,
    _ => _l10n.remindersStudyTitle,
  };

  @override
  String followUpTitle(ReminderKind kind) => switch (kind) {
    ReminderKind.routineDayMissed => _l10n.remindersRoutineMissedTitle,
    ReminderKind.openSession => _l10n.remindersOpenSessionTitle,
    _ => _l10n.remindersChallengeDueTitle,
  };

  @override
  String followUpBody(ReminderKind kind, String? name) => switch (kind) {
    ReminderKind.routineDayMissed => _l10n.remindersRoutineMissedBody(
      name ?? _l10n.remindersYourRoutine,
    ),
    ReminderKind.openSession => _l10n.remindersOpenSessionBody,
    _ => _l10n.remindersChallengeDueBody(name ?? _l10n.remindersYourChallenge),
  };

  @override
  String get weeklySummaryTitle => _l10n.remindersWeeklyTitle;

  @override
  String get weeklySummaryBody => _l10n.remindersWeeklyBody;

  @override
  String deadlineTitle(ReminderKind kind, int daysBefore) =>
      kind == ReminderKind.exam
      ? _l10n.remindersExamTitle(daysBefore)
      : _l10n.remindersDeadlineTitle(daysBefore);

  /// El nombre del aviso o, si falta, uno de reserva según el tipo («Tu
  /// entreno», «Tu evento»…). Único sitio que decide los de reserva.
  String _nameOr(ReminderKind kind, String? name) {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return switch (kind) {
      ReminderKind.sportBlock => _l10n.remindersSportFallbackName,
      ReminderKind.personalEvent => _l10n.remindersPersonalFallbackName,
      ReminderKind.classSoon => _l10n.remindersClassFallbackName,
      ReminderKind.exam => _l10n.remindersExamFallbackName,
      ReminderKind.deadline => _l10n.remindersDeadlineFallbackName,
      ReminderKind.challengeTask ||
      ReminderKind.challengeDue => _l10n.remindersYourChallenge,
      _ => _l10n.remindersStudyFallbackName,
    };
  }

  @override
  String deadlineBody(ReminderKind kind, String? name, DateTime due) =>
      _l10n.remindersDeadlineBody(
        _nameOr(kind, name),
        _day.format(due),
        _time.format(due),
      );

  @override
  String blockBody(ReminderKind kind, String? name, DateTime start) =>
      _l10n.remindersBlockBody(_nameOr(kind, name), _time.format(start));

  @override
  String personalTitle(String? name, DateTime start) =>
      _l10n.remindersPersonalTitle(
        _nameOr(ReminderKind.personalEvent, name),
        _time.format(start),
      );

  @override
  String personalBody(int minutes) => _l10n.remindersPersonalBody(minutes);

  @override
  String get challengeTaskTitle => _l10n.remindersChallengeTaskTitle;

  @override
  String challengeTaskBody(int daysLeft, String? task, String? challenge) {
    final challengeName = _nameOr(ReminderKind.challengeTask, challenge);
    final taskName = task?.trim();
    return taskName == null || taskName.isEmpty
        ? _l10n.remindersChallengeTaskBodyChallenge(daysLeft, challengeName)
        : _l10n.remindersChallengeTaskBody(daysLeft, taskName, challengeName);
  }

  @override
  String get morningSummaryTitle => _l10n.remindersMorningSummaryTitle;

  @override
  String morningSummaryBody(ReminderDaySummary summary) {
    final items = [
      if (summary.studies > 0) _l10n.remindersSummaryStudies(summary.studies),
      if (summary.trainings > 0)
        _l10n.remindersSummaryTrainings(summary.trainings),
      if (summary.classes > 0) _l10n.remindersSummaryClasses(summary.classes),
      if (summary.personal > 0)
        _l10n.remindersSummaryPersonal(summary.personal),
      for (final d in summary.deadlines)
        (d.title?.trim().isNotEmpty ?? false)
            ? _l10n.remindersSummaryDeadline(
                d.exam ? 'exam' : 'other',
                d.title!.trim(),
              )
            : _l10n.remindersSummaryDeadlineUnnamed(d.exam ? 'exam' : 'other'),
      if (summary.tasks > 0) _l10n.remindersSummaryTasks(summary.tasks),
    ];
    // El servidor solo lo manda si hay algo; por si acaso, nunca va vacío.
    if (items.isEmpty) {
      return summary.checkIn
          ? _l10n.remindersCheckInBody
          : _l10n.remindersMorningSummaryEmpty;
    }
    final body = _l10n.remindersMorningSummaryBody(_list(items));
    return summary.checkIn ? _l10n.remindersMorningSummaryCheckIn(body) : body;
  }

  /// Hasta tres tareas se nombran; con más, solo cuántas (el aviso se corta).
  static const _maxNamedTasks = 3;

  @override
  String withTasks(String body, List<ReminderTask> tasks) {
    if (tasks.isEmpty) return body;
    final String mention;
    if (tasks.length == 1) {
      final task = tasks.single;
      final challenge = _nameOr(
        ReminderKind.challengeTask,
        task.challengeTitle,
      );
      final title = task.title?.trim();
      mention = title == null || title.isEmpty
          ? _l10n.remindersTaskMentionChallenge(challenge)
          : _l10n.remindersTaskMention(title, challenge);
    } else if (tasks.length <= _maxNamedTasks) {
      mention = _l10n.remindersTaskMentionList(
        _list([
          for (final t in tasks)
            _l10n.remindersQuoted(
              (t.title?.trim().isNotEmpty ?? false)
                  ? t.title!.trim()
                  : _nameOr(ReminderKind.challengeTask, t.challengeTitle),
            ),
        ]),
      );
    } else {
      mention = _l10n.remindersSummaryTasks(tasks.length);
    }
    return _l10n.remindersWithTasks(body, mention);
  }

  /// Lista natural en el idioma de la app: «a, b y c».
  String _list(List<String> items) => items.length == 1
      ? items.single
      : _l10n.remindersListAnd(
          items.sublist(0, items.length - 1).join(', '),
          items.last,
        );

  @override
  String startAction(ReminderKind kind) => switch (kind) {
    ReminderKind.sportBlock => _l10n.remindersActionStartTraining,
    ReminderKind.personalEvent => _l10n.remindersActionStartPersonal,
    _ => _l10n.remindersActionStartStudy,
  };

  @override
  String snoozeAction(int minutes) => _l10n.remindersActionSnooze(minutes);

  @override
  String wellbeingTitle(ReminderKind kind, {String? name, int? minutes}) =>
      switch (kind) {
        ReminderKind.streakAtRisk => _l10n.remindersStreakTitle,
        ReminderKind.checkIn => _l10n.remindersCheckInTitle,
        // Sin inicio no se sabe cuánto falta: solo el nombre.
        _ =>
          minutes == null
              ? _nameOr(ReminderKind.classSoon, name)
              : _l10n.remindersClassTitle(
                  _nameOr(ReminderKind.classSoon, name),
                  minutes,
                ),
      };

  @override
  String wellbeingBody(
    ReminderKind kind, {
    int? count,
    String? name,
    String? place,
    DateTime? start,
  }) => switch (kind) {
    ReminderKind.streakAtRisk => _l10n.remindersStreakBody(count ?? 1),
    ReminderKind.checkIn => _l10n.remindersCheckInBody,
    _ =>
      place?.trim().isNotEmpty ?? false
          ? _l10n.remindersClassBodyPlace(
              start == null ? '' : _time.format(start),
              place!.trim(),
            )
          : _l10n.remindersClassBody(start == null ? '' : _time.format(start)),
  };
}
