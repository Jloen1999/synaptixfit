part of 'cycle_bloc.dart';

@freezed
sealed class CycleEvent with _$CycleEvent {
  const factory CycleEvent.started() = CycleStarted;

  /// Mes del calendario que se quiere ver (cualquier día de ese mes).
  const factory CycleEvent.monthChanged(DateTime month) = CycleMonthChanged;

  /// Activar tras aceptar para qué se usan los datos. El consentimiento viaja
  /// tal cual: sin él, el servidor no lo activa (`CYCLE_CONSENT_REQUIRED`).
  const factory CycleEvent.enabled({required bool consent}) = CycleEnabled;

  const factory CycleEvent.disabled({required bool deleteHistory}) =
      CycleDisabled;

  const factory CycleEvent.dayLogged(CycleDay day) = CycleDayLogged;

  const factory CycleEvent.dayDeleted(DateTime date) = CycleDayDeleted;

  const factory CycleEvent.historyDeleted() = CycleHistoryDeleted;
}
