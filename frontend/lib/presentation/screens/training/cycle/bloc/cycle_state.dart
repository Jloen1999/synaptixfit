part of 'cycle_bloc.dart';

/// Lo que acaba de pasar, para avisar una sola vez.
enum CycleNotice { saved, deleted, historyDeleted, disabled }

@freezed
abstract class CycleState with _$CycleState {
  const factory CycleState({
    @Default(true) bool loading,
    CycleOverview? overview,

    /// Primer día del mes que enseña el calendario.
    required DateTime month,

    /// Días apuntados del mes, por fecha (sin hora).
    @Default(<DateTime, CycleDay>{}) Map<DateTime, CycleDay> days,

    /// El mes se está cargando o no se pudo cargar: el calendario no debe
    /// enseñar días «sin apuntar» que quizá sí lo están.
    @Default(false) bool daysLoading,
    AppError? daysError,
    @Default(false) bool saving,
    AppError? error,

    /// Error al guardar o borrar (la pantalla sigue a la vista).
    AppError? actionError,
    CycleNotice? notice,
  }) = _CycleState;
}
