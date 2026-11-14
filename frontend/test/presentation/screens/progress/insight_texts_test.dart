import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/analytics_enums.dart';
import 'package:synaptixfit/domain/models/progress/analytics_insight.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations_es.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/insight_texts.dart';

void main() {
  final l10n = AppLocalizationsEs();

  setUpAll(() => initializeDateFormatting('es'));

  String? message(
    InsightType type,
    String variant, [
    Map<String, num> params = const {},
  ]) => InsightTexts.build(
    l10n,
    AnalyticsInsight(
      type: type,
      severity: InsightSeverity.info,
      variant: variant,
      params: params,
    ),
  )?.message;

  group('racha', () {
    test('NONE invita a empezar', () {
      expect(
        message(InsightType.streak, 'NONE'),
        l10n.progressInsightStreakNone,
      );
    });

    test('BUILDING usa los días en plural', () {
      expect(
        message(InsightType.streak, 'BUILDING', {'days': 4, 'weeks': 0}),
        startsWith('Llevas 4 días seguidos'),
      );
    });

    test('WEEKS usa el plural ICU de las semanas', () {
      expect(
        message(InsightType.streak, 'WEEKS', {'days': 8, 'weeks': 1}),
        contains('(una semana)'),
      );
      expect(
        message(InsightType.streak, 'WEEKS', {'days': 21, 'weeks': 3}),
        contains('(3 semanas)'),
      );
    });

    test('el título corresponde al tipo', () {
      final text = InsightTexts.build(
        l10n,
        const AnalyticsInsight(
          type: InsightType.streak,
          severity: InsightSeverity.positive,
          variant: 'HABIT',
          params: {'days': 40},
        ),
      );
      expect(text?.title, l10n.progressInsightTitleStreak);
      expect(text?.message, contains('40 días'));
    });
  });

  group('constancia', () {
    test('BUILDING con 1 semana usa el singular', () {
      expect(
        message(InsightType.consistency, 'BUILDING', {'weeks': 1}),
        startsWith('1 semana seguida'),
      );
    });

    test('ELITE muestra las semanas', () {
      expect(
        message(InsightType.consistency, 'ELITE', {'weeks': 6}),
        startsWith('6 semanas seguidas'),
      );
    });
  });

  group('volumen', () {
    test('ACCUMULATED formatea las horas con coma decimal', () {
      final text = message(InsightType.volume, 'ACCUMULATED', {
        'totalMinutes': 450,
        'totalHours': 7.5,
        'weeks': 4,
        'averageHoursPerWeek': 1.9,
      });
      expect(text, contains('En 4 semanas'));
      expect(text, contains('7,5 h'));
      expect(text, contains('1,9 h por semana'));
    });

    test('ACCUMULATED con una semana usa el singular', () {
      expect(
        message(InsightType.volume, 'ACCUMULATED', {
          'totalHours': 2,
          'weeks': 1,
          'averageHoursPerWeek': 2,
        }),
        startsWith('Esta semana: 2 h'),
      );
    });

    test('LOW anima a sumar', () {
      expect(message(InsightType.volume, 'LOW'), l10n.progressInsightVolumeLow);
    });
  });

  group('correlación', () {
    test('fuerte negativa usa el porcentaje', () {
      expect(
        message(InsightType.correlation, 'STRONG_NEGATIVE', {
          'coefficient': -0.62,
          'percent': 62,
        }),
        l10n.progressInsightCorrelationStrongNegative(62),
      );
    });

    test('moderada positiva se trata como marcada', () {
      expect(
        message(InsightType.correlation, 'MODERATE_POSITIVE', {'percent': 45}),
        l10n.progressInsightCorrelationStrongPositive(45),
      );
    });

    test(
      'débil usa el mensaje leve y deriva el porcentaje del coeficiente',
      () {
        expect(
          message(InsightType.correlation, 'WEAK_NEGATIVE', {
            'coefficient': -0.25,
          }),
          l10n.progressInsightCorrelationMildNegative(25),
        );
      },
    );

    test('muy fuerte positiva', () {
      expect(
        message(InsightType.correlation, 'VERY_STRONG_POSITIVE', {
          'percent': 85,
        }),
        l10n.progressInsightCorrelationStrongPositive(85),
      );
    });

    test('NONE indica que no hay relación clara', () {
      expect(
        message(InsightType.correlation, 'NONE'),
        l10n.progressInsightCorrelationNone,
      );
    });
  });

  test('tipos o variantes desconocidos no generan texto', () {
    expect(message(InsightType.unknown, 'NONE'), isNull);
    expect(message(InsightType.streak, 'NEW_VARIANT'), isNull);
    expect(message(InsightType.correlation, 'HUGE_POSITIVE'), isNull);
  });
}
