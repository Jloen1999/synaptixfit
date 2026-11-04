import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_texts.dart';

/// Textos de prueba que dejan ver qué datos recibió cada aviso.
class TestReminderTexts implements ReminderTexts {
  const TestReminderTexts();

  @override
  String get channelName => 'channel';

  @override
  String dueReviewsTitle(int count) => 'reviews';

  @override
  String dueReviewsBody(int count) => 'reviews:$count';

  @override
  String blockTitle(ReminderKind kind) => kind.name;

  @override
  String blockBody(ReminderKind kind, String? name, DateTime start) {
    final time =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
    return '${kind.name}:${name ?? '-'}@$time';
  }

  @override
  String get weeklySummaryTitle => 'weekly';

  @override
  String get weeklySummaryBody => 'weekly-body';

  @override
  String deadlineTitle(ReminderKind kind, int daysBefore) =>
      '${kind.name}:$daysBefore';

  @override
  String deadlineBody(ReminderKind kind, String? name, DateTime due) =>
      '${kind.name}:${name ?? '-'}';

  @override
  String followUpTitle(ReminderKind kind) => kind.name;

  @override
  String followUpBody(ReminderKind kind, String? name) =>
      '${kind.name}:${name ?? '-'}';

  @override
  String startAction(ReminderKind kind) => 'start:${kind.name}';

  @override
  String snoozeAction(int minutes) => 'snooze:$minutes';

  @override
  String wellbeingTitle(ReminderKind kind, {String? name}) =>
      'wellbeing:${kind.name}';

  @override
  String wellbeingBody(
    ReminderKind kind, {
    int? count,
    String? name,
    String? place,
    DateTime? start,
  }) => '${kind.name}:${count ?? '-'}:${name ?? '-'}:${place ?? '-'}';
}
