part of 'cycle_bloc.dart';

@freezed
sealed class CycleEvent with _$CycleEvent {
  const factory CycleEvent.started() = CycleStarted;

  /// Mes del calendario que se quiere ver (cualquier día de ese mes).
  const factory CycleEvent.monthChanged(DateTime month) = CycleMonthChanged;

  /// Activar tras aceptar para qué se usan los datos.
  const factory CycleEvent.enabled() = CycleEnabled;

  const factory CycleEvent.disabled({required bool deleteHistory}) =
      CycleDisabled;

  const factory CycleEvent.dayLogged(CycleDay day) = CycleDayLogged;

  const factory CycleEvent.dayDeleted(DateTime date) = CycleDayDeleted;

  const factory CycleEvent.historyDeleted() = CycleHistoryDeleted;
}
