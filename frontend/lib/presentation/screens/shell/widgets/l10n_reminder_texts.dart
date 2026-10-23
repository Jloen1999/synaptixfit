import 'package:intl/intl.dart';

import '../../../../domain/enums/reminder_kind.dart';
import '../../../../domain/models/reminders/reminder_texts.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Pone los textos traducidos a los avisos locales que decide el servidor
/// (los compone `ReminderComposer`). La crea [RemindersHost] con el idioma de
/// la app.
class L10nReminderTexts implements ReminderTexts {
  L10nReminderTexts(this._l10n) : _time = DateFormat.Hm(_l10n.localeName);

  final AppLocalizations _l10n;
  final DateFormat _time;

  @override
  String get channelName => _l10n.remindersChannelName;

  @override
  String dueReviewsTitle(int count) => _l10n.remindersDueReviewsTitle;

  @override
  String dueReviewsBody(int count) => _l10n.remindersDueReviewsBody(count);

  @override
  String blockTitle(ReminderKind kind) => switch (kind) {
    ReminderKind.sportBlock => _l10n.remindersSportTitle,
    ReminderKind.studyBlock ||
    ReminderKind.dueReviews => _l10n.remindersStudyTitle,
  };

  @override
  String blockBody(ReminderKind kind, String? name, DateTime start) {
    final label = (name == null || name.trim().isEmpty)
        ? (kind == ReminderKind.sportBlock
              ? _l10n.remindersSportFallbackName
              : _l10n.remindersStudyFallbackName)
        : name.trim();
    return _l10n.remindersBlockBody(label, _time.format(start));
  }
}
