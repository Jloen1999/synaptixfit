import '../../enums/reminder_kind.dart';
import 'reminder.dart';
import 'reminder_plan.dart';
import 'reminder_texts.dart';

/// Convierte el plan que decide el servidor ([PlannedReminder]) en avisos
/// locales ([Reminder]): pone los textos traducidos y un id estable. No decide
/// qué se avisa (preferencias, enfoque, silencio y límite viven en el backend,
/// ADR 0013). Lo usa `SyncRemindersUseCase`.
class ReminderComposer {
  const ReminderComposer({this.maxReminders = 60});

  /// Tope de seguridad del dispositivo: iOS solo guarda 64 avisos pendientes
  /// por app (el servidor ya limita el plan a 60).
  final int maxReminders;

  List<Reminder> compose(List<PlannedReminder> plan, ReminderTexts texts) {
    var review = 0;
    return [
      for (final planned in plan.take(maxReminders))
        switch (planned.kind) {
          ReminderKind.dueReviews => Reminder(
            id: _reviewIdBase + review++,
            kind: planned.kind,
            title: texts.dueReviewsTitle(planned.count ?? 0),
            body: texts.dueReviewsBody(planned.count ?? 0),
            at: planned.at,
          ),
          ReminderKind.sportBlock || ReminderKind.studyBlock => Reminder(
            id: _blockId(planned.refId),
            kind: planned.kind,
            title: texts.blockTitle(planned.kind),
            body: texts.blockBody(
              planned.kind,
              planned.title,
              (planned.startsAt ?? planned.at).toLocal(),
            ),
            at: planned.at,
          ),
          ReminderKind.weeklySummary => Reminder(
            id: _weeklyId,
            kind: planned.kind,
            title: texts.weeklySummaryTitle,
            body: texts.weeklySummaryBody,
            at: planned.at,
          ),
          ReminderKind.exam || ReminderKind.deadline => Reminder(
            id: _blockId(planned.refId),
            kind: planned.kind,
            title: texts.deadlineTitle(planned.kind, planned.count ?? 1),
            body: texts.deadlineBody(
              planned.kind,
              planned.title,
              (planned.startsAt ?? planned.at).toLocal(),
            ),
            at: planned.at,
          ),
        },
    ];
  }

  static const _reviewIdBase = 100;

  /// Uno solo a la vez (el próximo domingo), lejos de repasos y bloques.
  static const _weeklyId = 90;

  /// Hash propio porque `String.hashCode` no es estable entre ejecuciones y
  /// el id debe serlo. Se queda por debajo de 2^31 (Android usa int32), lejos
  /// de los ids de repasos y sin pasar de 2^53 en web.
  static int _blockId(String blockId) {
    var hash = 0;
    for (final unit in blockId.codeUnits) {
      hash = (hash * 31 + unit) % 0x3FFFFFFF;
    }
    return hash + 1000;
  }
}
