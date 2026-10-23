import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/wellness_history.dart';
import '../../../../../domain/use_cases/profile/get_goal_history_use_case.dart';
import '../../../../../domain/use_cases/profile/get_weight_history_use_case.dart';

part 'wellness_history_bloc.freezed.dart';
part 'wellness_history_event.dart';
part 'wellness_history_state.dart';

/// Historial de peso y de objetivos.
class WellnessHistoryBloc
    extends Bloc<WellnessHistoryEvent, WellnessHistoryState> {
  WellnessHistoryBloc({
    required this._getWeightHistory,
    required this._getGoalHistory,
  }) : super(const WellnessHistoryState()) {
    on<WellnessHistoryStarted>(_onStarted);
  }

  final GetWeightHistoryUseCaseContract _getWeightHistory;
  final GetGoalHistoryUseCaseContract _getGoalHistory;

  Future<void> _onStarted(
    WellnessHistoryStarted event,
    Emitter<WellnessHistoryState> emit,
  ) async {
    emit(state.copyWith(status: WellnessHistoryStatus.loading, error: null));
    final (weights, goals) = await (
      _getWeightHistory(),
      _getGoalHistory(),
    ).wait;
    final error = weights.errorOrNull ?? goals.errorOrNull;
    if (error != null) {
      emit(state.copyWith(status: WellnessHistoryStatus.failure, error: error));
      return;
    }
    emit(
      state.copyWith(
        status: WellnessHistoryStatus.ready,
        weights: weights.valueOrNull ?? const [],
        goals: goals.valueOrNull ?? const [],
      ),
    );
  }
}
