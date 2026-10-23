part of 'onboarding_bloc.dart';

enum OnboardingStatusView { loading, ready, failure, finished }

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingStatusView.loading) OnboardingStatusView status,

    /// Pasos pendientes en el orden en que se muestran.
    @Default(<OnboardingStep>[]) List<OnboardingStep> steps,
    @Default(0) int index,
    @Default(false) bool busy,

    /// Cuenta actualizada en el paso de cuenta (para refrescar la sesión).
    Account? account,
    AppError? error,
    AppError? actionError,
  }) = _OnboardingState;

  const OnboardingState._();

  OnboardingStep? get currentStep => index < steps.length ? steps[index] : null;

  bool get isLastStep => index == steps.length - 1;

  /// El enfoque y el perfil físico (con deporte) son obligatorios.
  bool get canSkip =>
      currentStep != OnboardingStep.wellnessProfile &&
      currentStep != OnboardingStep.focus;
}
