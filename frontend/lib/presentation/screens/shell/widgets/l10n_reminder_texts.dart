import 'package:intl/intl.dart';

import '../../../../domain/enums/reminder_kind.dart';
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

  @override
  String deadlineBody(ReminderKind kind, String? name, DateTime due) {
    final label = (name == null || name.trim().isEmpty)
        ? (kind == ReminderKind.exam
              ? _l10n.remindersExamFallbackName
              : _l10n.remindersDeadlineFallbackName)
        : name.trim();
    return _l10n.remindersDeadlineBody(
      label,
      _day.format(due),
      _time.format(due),
    );
  }

  @override
  String blockBody(ReminderKind kind, String? name, DateTime start) {
    final label = (name == null || name.trim().isEmpty)
        ? (kind == ReminderKind.sportBlock
              ? _l10n.remindersSportFallbackName
              : _l10n.remindersStudyFallbackName)
        : name.trim();
    return _l10n.remindersBlockBody(label, _time.format(start));
  }

  @override
  String startAction(ReminderKind kind) => kind == ReminderKind.sportBlock
      ? _l10n.remindersActionStartTraining
      : _l10n.remindersActionStartStudy;

  @override
  String snoozeAction(int minutes) => _l10n.remindersActionSnooze(minutes);

  @override
  String wellbeingTitle(ReminderKind kind, {String? name}) => switch (kind) {
    ReminderKind.streakAtRisk => _l10n.remindersStreakTitle,
    ReminderKind.checkIn => _l10n.remindersCheckInTitle,
    _ => _l10n.remindersClassTitle(
      name?.trim().isNotEmpty ?? false
          ? name!.trim()
          : _l10n.remindersClassFallbackName,
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
