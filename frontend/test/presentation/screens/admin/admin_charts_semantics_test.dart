import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/models/admin/admin_user_stats.dart';
import 'package:synaptixfit/domain/models/admin/platform_metrics.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/admin/metrics/bloc/admin_metrics_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/metrics/page/admin_metrics_page.dart';
import 'package:synaptixfit/presentation/screens/admin/user_detail/bloc/admin_user_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/user_detail/page/admin_user_stats_tab.dart';
import 'package:synaptixfit/presentation/screens/admin/widgets/admin_status.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'admin_fixtures.dart';

class _MockMetricsBloc extends MockBloc<AdminMetricsEvent, AdminMetricsState>
    implements AdminMetricsBloc {}

/// Las gráficas del panel se anuncian con un resumen textual (WCAG 1.1.1).
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('la tendencia de KPIs resume periodo y cifras por serie', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final bloc = _MockMetricsBloc();
    when(() => bloc.state).thenReturn(
      AdminMetricsState(
        status: AdminStatus.ready,
        metrics: const PlatformMetrics(
          totalUsers: 10,
          activeUsersToday: 4,
          trainingSessionsToday: 2,
          activeRoutines: 3,
          activeChallenges: 1,
          pendingReportedContent: 0,
          newUsersToday: 1,
          shadowbannedUsers: 0,
        ),
        trendDays: 7,
        trend: [
          DailyActivity(
            date: DateTime(2026, 10, 1),
            signups: 2,
            activeUsers: 5,
            trainingSessions: 1,
          ),
          DailyActivity(
            date: DateTime(2026, 10, 2),
            signups: 0,
            activeUsers: 9,
            trainingSessions: 3,
          ),
        ],
      ),
    );

    await pump(
      tester,
      BlocProvider<AdminMetricsBloc>.value(
        value: bloc,
        child: const AdminMetricsView(),
      ),
    );

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Gráfica de líneas de los últimos 7 días, del 1 oct al 2 oct\. '
          r'Altas: último día 0, máximo 2, media diaria 1; '
          r'Activos: último día 9, máximo 9, media diaria 7; '
          r'Sesiones: último día 3, máximo 3, media diaria 2\.$',
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('la actividad semanal del usuario resume ambas series', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      AdminUserStatsTab(
        state: AdminUserDetailState(
          userId: 'u1',
          stats: stats,
          activity: [
            AdminWeeklyActivity(
              weekStart: DateTime(2026, 9, 21),
              trainingSessions: 2,
              trainingMinutes: 90,
              calories: 500,
              studyMinutes: 120,
              focusMinutes: 30,
            ),
            AdminWeeklyActivity(
              weekStart: DateTime(2026, 9, 28),
              trainingSessions: 1,
              trainingMinutes: 30,
              calories: 200,
              studyMinutes: 60,
              focusMinutes: 0,
            ),
          ],
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Actividad semanal (minutos)'),
      200,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Gráfica de barras de minutos por semana, 2 semanas desde el '
          r'21 sept hasta el 28 sept\. '
          r'Entrenamiento: última semana 30 minutos, mejor semana 90, '
          r'media semanal 60; '
          r'Estudio y foco: última semana 60 minutos, mejor semana 150, '
          r'media semanal 105\.$',
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
