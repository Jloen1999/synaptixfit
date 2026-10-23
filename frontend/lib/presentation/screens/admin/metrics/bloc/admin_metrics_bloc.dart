import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/platform_metrics.dart';
import '../../../../../domain/use_cases/admin/get_activity_trend_use_case.dart';
import '../../../../../domain/use_cases/admin/get_platform_metrics_use_case.dart';
import '../../widgets/admin_status.dart';

part 'admin_metrics_bloc.freezed.dart';
part 'admin_metrics_event.dart';
part 'admin_metrics_state.dart';

/// Pestaña KPIs: indicadores globales y tendencia diaria.
class AdminMetricsBloc extends Bloc<AdminMetricsEvent, AdminMetricsState> {
  AdminMetricsBloc({required this._getMetrics, required this._getTrend})
    : super(const AdminMetricsState()) {
    on<AdminMetricsStarted>(_onLoad);
    on<AdminMetricsRefreshed>(_onLoad);
    on<AdminMetricsTrendDaysChanged>(_onTrendDays);
  }

  final GetPlatformMetricsUseCaseContract _getMetrics;
  final GetActivityTrendUseCaseContract _getTrend;

  Future<void> _onLoad(
    AdminMetricsEvent event,
    Emitter<AdminMetricsState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading, error: null));
    final (metrics, trend) = await (
      _getMetrics(),
      _getTrend(days: state.trendDays),
    ).wait;
    final error = metrics.errorOrNull ?? trend.errorOrNull;
    if (error != null) {
      emit(state.copyWith(status: AdminStatus.failure, error: error));
      return;
    }
    emit(
      state.copyWith(
        status: AdminStatus.ready,
        metrics: metrics.valueOrNull,
        trend: trend.valueOrNull ?? const [],
      ),
    );
  }

  Future<void> _onTrendDays(
    AdminMetricsTrendDaysChanged event,
    Emitter<AdminMetricsState> emit,
  ) async {
    emit(
      state.copyWith(
        trendDays: event.days,
        trendLoading: true,
        trendError: null,
      ),
    );
    final result = await _getTrend(days: event.days);
    emit(
      result.fold(
        (trend) => state.copyWith(trendLoading: false, trend: trend),
        (error) => state.copyWith(trendLoading: false, trendError: error),
      ),
    );
  }
}
