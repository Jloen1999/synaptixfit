part of 'together_safety_bloc.dart';

/// Lo que acaba de hacerse (efecto de un solo uso: el aviso).
enum TogetherSafetyDone { blocked, reported }

@freezed
abstract class TogetherSafetyState with _$TogetherSafetyState {
  const factory TogetherSafetyState({
    @Default(false) bool busy,
    TogetherSafetyDone? done,

    /// Persona bloqueada (con [done] == blocked).
    String? blockedId,
    AppError? error,
  }) = _TogetherSafetyState;
}
