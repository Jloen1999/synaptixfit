import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/analytics_enums.dart';
import 'package:synaptixfit/domain/models/progress/physical_load.dart';
import 'package:synaptixfit/domain/models/progress/rpe_trend.dart';
import 'package:synaptixfit/domain/models/progress/study_week.dart';
import 'package:synaptixfit/domain/models/progress/training_volume.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/analytics_summary.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/badge_tile.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/correlation_card.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/level_card.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/physical_load_card.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/rpe_trend_card.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/streak_card.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/study_week_card.dart';
import 'package:synaptixfit/presentation/screens/progress/widgets/volume_chart_card.dart';
import 'package:synaptixfit/presentation/theme/app_palette.dart';

import '../../../progress_fixtures.dart';

/// Comprueba que las tarjetas del módulo se pintan sin errores de layout a
/// ancho de móvil, en claro y oscuro.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<void> pump(WidgetTester tester, Widget child, {bool dark = false}) {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          extensions: [dark ? AppPalette.dark : AppPalette.light],
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  final week = DateTime(2026, 10, 5);
  final cards = Column(
    children: [
      const LevelCard(account: testAccount),
      const StreakCard(streak: testStreak),
      WeeklySummaryCard(weekly: testWeekly, onOpen: () {}),
      PhysicalLoadCard(
        load: PhysicalLoad(
          todayLoad: 300,
          maxDailyLoad: 500,
          todayRatio: 0.6,
          last28Days: [
            for (var i = 0; i < 28; i++)
              DailyLoad(
                date: week.add(Duration(days: i)),
                load: i * 10.0,
              ),
          ],
        ),
      ),
      AnalyticsSummary(weekly: testWeekly),
      VolumeChartCard(
        volume: TrainingVolume(
          points: [
            for (var i = 0; i < 12; i++)
              VolumePoint(
                weekStart: week.add(Duration(days: 7 * i)),
                sessions: i % 3,
                minutes: i * 20,
                calories: i * 100,
              ),
          ],
          averageMinutesPerWeek: 110,
          averageCaloriesPerWeek: 550,
          averageSessionsPerWeek: 1,
        ),
      ),
      RpeTrendCard(
        trend: RpeTrend(
          points: [
            for (var i = 0; i < 4; i++)
              RpePoint(
                weekStart: week.add(Duration(days: 7 * i)),
                averageRpe: 5.0 + i,
              ),
          ],
          slopePerWeek: 1,
          direction: TrendDirection.up,
        ),
      ),
      CorrelationCard(
        correlation: testCorrelation(CorrelationMetric.rpe),
        metric: CorrelationMetric.rpe,
        loading: false,
        onMetricChanged: (_) {},
      ),
      SizedBox(
        height: 224,
        child: Row(
          children: [
            Expanded(
              child: BadgeTile(badge: testBadge(), onTap: () {}),
            ),
            Expanded(
              child: BadgeTile(
                badge: testBadge(id: 'b2', earned: false),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    ],
  );

  testWidgets('las tarjetas se pintan en tema claro', (tester) async {
    await pump(tester, cards);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Racha'), findsWidgets);
    expect(find.text('r = -0,62'), findsOneWidget);
  });

  testWidgets('las tarjetas se pintan en tema oscuro', (tester) async {
    await pump(tester, cards, dark: true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('Tu estudio', () {
    final studyWeek = StudyWeek(
      weekStart: DateTime(2026, 10, 19),
      focusMinutes: 150,
      focusSessions: 3,
      studyBlocksPlanned: 8,
      studyBlocksCompleted: 6,
      planAdherence: 75,
      reviewsCompleted: 12,
      testsCompleted: 2,
      averageTestScore: 80,
      reviewsDue: 4,
      empty: false,
    );

    testWidgets('muestra la semana de estudio con sus cifras', (tester) async {
      await pump(
        tester,
        StudyWeekCard(
          week: studyWeek,
          onFocus: () {},
          onReview: () {},
          onRetry: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('150 min'), findsOneWidget);
      expect(find.text('6 de 8'), findsOneWidget);
      expect(find.text('75 % del plan'), findsOneWidget);
      expect(find.text('80 %'), findsOneWidget);
      expect(find.text('Repasar ahora (4 pendientes)'), findsOneWidget);
    });

    testWidgets('vacía invita a concentrarse', (tester) async {
      var opened = false;
      await pump(
        tester,
        StudyWeekCard(
          week: StudyWeek(weekStart: DateTime(2026, 10, 19)),
          onFocus: () => opened = true,
          onReview: () {},
          onRetry: () {},
        ),
      );
      await tester.tap(find.text('Concentrarme'));
      expect(opened, isTrue);
    });

    testWidgets('si no carga, ofrece reintentar', (tester) async {
      var retried = false;
      await pump(
        tester,
        StudyWeekCard(
          week: null,
          onFocus: () {},
          onReview: () {},
          onRetry: () => retried = true,
        ),
      );
      await tester.tap(find.text('Reintentar'));
      expect(retried, isTrue);
    });

    testWidgets('cabe con el texto al 200 % en un móvil estrecho', (
      tester,
    ) async {
      await pump(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: StudyWeekCard(
            week: studyWeek,
            onFocus: () {},
            onReview: () {},
            onRetry: () {},
          ),
        ),
        dark: true,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
