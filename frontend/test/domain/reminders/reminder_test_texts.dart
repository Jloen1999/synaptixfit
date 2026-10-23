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
}
