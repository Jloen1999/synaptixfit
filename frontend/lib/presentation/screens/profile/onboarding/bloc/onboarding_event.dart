part of 'onboarding_bloc.dart';

@freezed
sealed class OnboardingEvent with _$OnboardingEvent {
  const factory OnboardingEvent.started() = OnboardingStarted;

  /// Crear contraseña (y opcionalmente corregir el nombre) en el paso de cuenta.
  const factory OnboardingEvent.accountSubmitted({
    String? fullName,
    required String password,
  }) = OnboardingAccountSubmitted;

  /// Enfoque de uso elegido (estudios, deporte o ambos) y, si la dio, la fecha de nacimiento (opcional, ADR 0036).
  const factory OnboardingEvent.focusSubmitted(
    UsageFocus focus, {
    DateTime? birthDate,
  }) = OnboardingFocusSubmitted;

  /// El formulario del paso actual se ha guardado.
  const factory OnboardingEvent.stepCompleted() = OnboardingStepCompleted;

  /// Saltar el paso actual (cuenta, perfil académico o asignaturas).
  const factory OnboardingEvent.stepSkipped() = OnboardingStepSkipped;

  const factory OnboardingEvent.previousRequested() =
      OnboardingPreviousRequested;

  /// Reintentar el cierre del onboarding tras un error.
  const factory OnboardingEvent.finishRequested() = OnboardingFinishRequested;
}
