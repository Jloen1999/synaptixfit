part of 'wellness_form_bloc.dart';

enum WellnessFormStatus { loading, ready, failure }

@freezed
abstract class WellnessFormState with _$WellnessFormState {
  const factory WellnessFormState({
    @Default(WellnessFormStatus.loading) WellnessFormStatus status,

    /// Perfil actual; `null` si aún no existe.
    WellnessProfile? initial,
    @Default(false) bool saving,
    @Default(false) bool suggesting,
    GoalSuggestions? suggestions,

    /// Perfil recién guardado (señal para cerrar la pantalla o avanzar).
    WellnessProfile? saved,
    AppError? loadError,
    AppError? actionError,
  }) = _WellnessFormState;
}
