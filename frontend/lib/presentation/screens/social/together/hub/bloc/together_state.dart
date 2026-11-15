part of 'together_bloc.dart';

enum TogetherStatus { loading, ready, failure }

/// Aviso tras una acción (efecto de un solo uso).
enum TogetherMessage {
  streakProposed,
  streakAccepted,
  streakEnded,
  streakWithdrawn,
  streakNudged,
  declined,
}

@freezed
abstract class TogetherState with _$TogetherState {
  const factory TogetherState({
    @Default(TogetherStatus.loading) TogetherStatus status,
    @Default(TogetherOverview()) TogetherOverview overview,
    AppError? error,

    /// Lo que se está mandando (botón ocupado).
    String? busyId,
    TogetherMessage? message,
    AppError? actionError,
  }) = _TogetherState;
}
