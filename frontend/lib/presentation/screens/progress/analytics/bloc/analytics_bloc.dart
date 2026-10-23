import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/analytics_enums.dart';
import '../../../../../domain/enums/analytics_period.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/progress/analytics_report.dart';
import '../../../../../domain/use_cases/progress/get_analytics_report_use_case.dart';
import '../../../../../domain/use_cases/progress/get_load_correlation_use_case.dart';

part 'analytics_bloc.freezed.dart';
part 'analytics_event.dart';
part 'analytics_state.dart';

/// Analítica: periodo, resumen, gráficas e interpretaciones.
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc({required this._getReport, required this._getCorrelation})
    : super(const AnalyticsState()) {
    on<AnalyticsStarted>(_onStarted);
    on<AnalyticsPeriodChanged>(_onPeriodChanged);
    on<AnalyticsMetricChanged>(_onMetricChanged);
  }

  final GetAnalyticsReportUseCaseContract _getReport;
  final GetLoadCorrelationUseCaseContract _getCorrelation;

  Future<void> _onStarted(
    AnalyticsStarted event,
    Emitter<AnalyticsState> emit,
  ) => _load(emit, state.period);

  Future<void> _onPeriodChanged(
    AnalyticsPeriodChanged event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (event.period == state.period &&
        state.status == AnalyticsStatus.loaded) {
      return;
    }
    await _load(emit, event.period);
  }

  Future<void> _load(
    Emitter<AnalyticsState> emit,
    AnalyticsPeriod period,
  ) async {
    emit(
      state.copyWith(
        period: period,
        status: AnalyticsStatus.loading,
        error: null,
      ),
    );
    final result = await _getReport(period: period, metric: state.metric);
    // Si el usuario cambió de periodo mientras tanto, gana la última petición.
    if (state.period != period) return;
    emit(
      result.fold(
        (report) =>
            state.copyWith(status: AnalyticsStatus.loaded, report: report),
        (error) =>
            state.copyWith(status: AnalyticsStatus.failure, error: error),
      ),
    );
  }

  Future<void> _onMetricChanged(
    AnalyticsMetricChanged event,
    Emitter<AnalyticsState> emit,
  ) async {
    final report = state.report;
    if (event.metric == state.metric) return;
    emit(state.copyWith(metric: event.metric));
    if (report == null) return;
    emit(state.copyWith(correlationLoading: true, correlationError: null));
    final result = await _getCorrelation(event.metric);
    if (state.metric != event.metric) return;
    emit(
      result.fold(
        (correlation) => state.copyWith(
          correlationLoading: false,
          report: state.report?.copyWith(correlation: correlation),
        ),
        (error) => state.copyWith(
          correlationLoading: false,
          correlationError: error,
          // Vuelve a la métrica que corresponde a los datos mostrados.
          metric: report.correlation.metric,
        ),
      ),
    );
  }
}
