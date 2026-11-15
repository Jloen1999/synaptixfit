part of 'challenge_templates_bloc.dart';

enum ChallengeTemplatesStatus { loading, ready, failure }

@freezed
abstract class ChallengeTemplatesState with _$ChallengeTemplatesState {
  const factory ChallengeTemplatesState({
    @Default(ChallengeTemplatesStatus.loading) ChallengeTemplatesStatus status,
    @Default(<ChallengeTemplate>[]) List<ChallengeTemplate> templates,
    AppError? error,

    /// Plantilla que se está empezando (botón ocupado).
    String? startingId,

    /// Reto recién empezado (efecto de un solo uso: abrirlo).
    Challenge? started,
    AppError? startError,
  }) = _ChallengeTemplatesState;
}
