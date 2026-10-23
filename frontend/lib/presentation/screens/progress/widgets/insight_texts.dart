import '../../../../domain/enums/analytics_enums.dart';
import '../../../../domain/models/progress/analytics_insight.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import 'progress_labels.dart';

/// Texto ya redactado de una interpretación.
typedef InsightText = ({String title, String message});

/// Redacta en el cliente las interpretaciones de la analítica a partir de
/// `type` + `variant` + `params` (antes las frases venían del generador de la
/// app antigua). Devuelve `null` si el tipo o la variante no se conocen.
abstract final class InsightTexts {
  static InsightText? build(AppLocalizations l10n, AnalyticsInsight insight) {
    final message = switch (insight.type) {
      InsightType.streak => _streak(l10n, insight),
      InsightType.consistency => _consistency(l10n, insight),
      InsightType.volume => _volume(l10n, insight),
      InsightType.correlation => _correlation(l10n, insight),
      InsightType.unknown => null,
    };
    if (message == null) return null;
    final title = switch (insight.type) {
      InsightType.streak => l10n.progressInsightTitleStreak,
      InsightType.consistency => l10n.progressInsightTitleConsistency,
      InsightType.volume => l10n.progressInsightTitleVolume,
      _ => l10n.progressInsightTitleCorrelation,
    };
    return (title: title, message: message);
  }

  static int _int(AnalyticsInsight i, String key) =>
      (i.params[key] ?? 0).round();

  static double _double(AnalyticsInsight i, String key) =>
      (i.params[key] ?? 0).toDouble();

  static String? _streak(AppLocalizations l10n, AnalyticsInsight i) {
    final days = _int(i, 'days');
    return switch (i.variant) {
      'NONE' => l10n.progressInsightStreakNone,
      'FIRST_DAY' => l10n.progressInsightStreakFirstDay,
      'BUILDING' => l10n.progressInsightStreakBuilding(days),
      'WEEKS' => l10n.progressInsightStreakWeeks(
        days,
        i.params.containsKey('weeks') ? _int(i, 'weeks') : days ~/ 7,
      ),
      'HABIT' => l10n.progressInsightStreakHabit(days),
      'UNSTOPPABLE' => l10n.progressInsightStreakUnstoppable(days),
      _ => null,
    };
  }

  static String? _consistency(AppLocalizations l10n, AnalyticsInsight i) {
    final weeks = _int(i, 'weeks');
    return switch (i.variant) {
      'NONE' => l10n.progressInsightConsistencyNone,
      'FIRST_WEEK' => l10n.progressInsightConsistencyFirstWeek,
      'BUILDING' => l10n.progressInsightConsistencyBuilding(weeks),
      'ELITE' => l10n.progressInsightConsistencyElite(weeks),
      _ => null,
    };
  }

  static String? _volume(AppLocalizations l10n, AnalyticsInsight i) =>
      switch (i.variant) {
        'LOW' => l10n.progressInsightVolumeLow,
        'ACCUMULATED' => l10n.progressInsightVolumeAccumulated(
          _int(i, 'weeks') < 1 ? 1 : _int(i, 'weeks'),
          ProgressFormat.oneDecimal(_double(i, 'totalHours')),
          ProgressFormat.oneDecimal(_double(i, 'averageHoursPerWeek')),
        ),
        _ => null,
      };

  /// Variantes `NONE` o `<FUERZA>_<DIRECCIÓN>` (p. ej. `STRONG_NEGATIVE`).
  /// Débil = matiz leve; moderada o mayor = mensaje marcado.
  static String? _correlation(AppLocalizations l10n, AnalyticsInsight i) {
    if (i.variant == 'NONE') return l10n.progressInsightCorrelationNone;
    final percent = i.params.containsKey('percent')
        ? _int(i, 'percent')
        : (_double(i, 'coefficient').abs() * 100).round();
    final negative = i.variant.endsWith('_NEGATIVE');
    if (!negative && !i.variant.endsWith('_POSITIVE')) return null;
    final strength = i.variant.substring(0, i.variant.lastIndexOf('_'));
    final mild = switch (strength) {
      'WEAK' => true,
      'MODERATE' || 'STRONG' || 'VERY_STRONG' => false,
      _ => null,
    };
    if (mild == null) return null;
    return switch ((negative, mild)) {
      (false, false) => l10n.progressInsightCorrelationStrongPositive(percent),
      (false, true) => l10n.progressInsightCorrelationMildPositive(percent),
      (true, false) => l10n.progressInsightCorrelationStrongNegative(percent),
      (true, true) => l10n.progressInsightCorrelationMildNegative(percent),
    };
  }
}
