import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/analytics_enums.dart';
import 'package:synaptixfit/domain/enums/analytics_period.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_analytics_report_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_load_correlation_use_case.dart';
import 'package:synaptixfit/presentation/screens/progress/analytics/bloc/analytics_bloc.dart';

import '../../../progress_fixtures.dart';

class _MockReport extends Mock implements GetAnalyticsReportUseCaseContract {}

class _MockCorrelation extends Mock
    implements GetLoadCorrelationUseCaseContract {}

void main() {
  late _MockReport getReport;
  late _MockCorrelation getCorrelation;

  setUpAll(() {
    registerFallbackValue(AnalyticsPeriod.monthly);
    registerFallbackValue(CorrelationMetric.rpe);
  });

  setUp(() {
    getReport = _MockReport();
    getCorrelation = _MockCorrelation();
  });

  AnalyticsBloc build() =>
      AnalyticsBloc(getReport: getReport, getCorrelation: getCorrelation);

  final report = testReport();
  final loaded = AnalyticsState(status: AnalyticsStatus.loaded, report: report);

  blocTest<AnalyticsBloc, AnalyticsState>(
    'carga el periodo mensual por defecto',
    setUp: () => when(
      () => getReport(
        period: AnalyticsPeriod.monthly,
        metric: CorrelationMetric.rpe,
      ),
    ).thenAnswer((_) async => Success(report)),
    build: build,
    act: (bloc) => bloc.add(const AnalyticsEvent.started()),
    expect: () => [const AnalyticsState(), loaded],
  );

  blocTest<AnalyticsBloc, AnalyticsState>(
    'emite failure si el informe falla',
    setUp: () =>
        when(
          () => getReport(
            period: any(named: 'period'),
            metric: any(named: 'metric'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure(AppError.business('ANALYTICS_INVALID_PERIOD')),
        ),
    build: build,
    act: (bloc) => bloc.add(const AnalyticsEvent.started()),
    expect: () => const [
      AnalyticsState(),
      AnalyticsState(
        status: AnalyticsStatus.failure,
        error: AppError.business('ANALYTICS_INVALID_PERIOD'),
      ),
    ],
  );

  blocTest<AnalyticsBloc, AnalyticsState>(
    'cambiar de periodo recarga conservando el informe anterior',
    setUp: () => when(
      () => getReport(
        period: AnalyticsPeriod.quarterly,
        metric: CorrelationMetric.rpe,
      ),
    ).thenAnswer((_) async => Success(report)),
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(const AnalyticsEvent.periodChanged(AnalyticsPeriod.quarterly)),
    expect: () => [
      loaded.copyWith(
        period: AnalyticsPeriod.quarterly,
        status: AnalyticsStatus.loading,
      ),
      loaded.copyWith(period: AnalyticsPeriod.quarterly),
    ],
  );

  blocTest<AnalyticsBloc, AnalyticsState>(
    'cambiar la métrica recarga solo la correlación',
    setUp: () =>
        when(() => getCorrelation(CorrelationMetric.minutes)).thenAnswer(
          (_) async => Success(testCorrelation(CorrelationMetric.minutes)),
        ),
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(const AnalyticsEvent.metricChanged(CorrelationMetric.minutes)),
    expect: () => [
      loaded.copyWith(metric: CorrelationMetric.minutes),
      loaded.copyWith(
        metric: CorrelationMetric.minutes,
        correlationLoading: true,
      ),
      loaded.copyWith(
        metric: CorrelationMetric.minutes,
        report: testReport(metric: CorrelationMetric.minutes),
      ),
    ],
    verify: (_) => verifyNever(
      () => getReport(
        period: any(named: 'period'),
        metric: any(named: 'metric'),
      ),
    ),
  );

  blocTest<AnalyticsBloc, AnalyticsState>(
    'si la correlación falla vuelve a la métrica anterior con el error',
    setUp: () => when(
      () => getCorrelation(CorrelationMetric.minutes),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(const AnalyticsEvent.metricChanged(CorrelationMetric.minutes)),
    skip: 2,
    expect: () => [loaded.copyWith(correlationError: const AppError.network())],
  );
}
