part of 'home_dashboard_bloc.dart';

@freezed
sealed class HomeDashboardEvent with _$HomeDashboardEvent {
  /// Primera carga de la pestaña. [userId] limita la redirección al onboarding
  /// a una vez por usuario y sesión de app.
  const factory HomeDashboardEvent.started({required String userId}) =
      HomeDashboardStarted;

  /// Pull-to-refresh, reintento o vuelta de otra pantalla.
  const factory HomeDashboardEvent.refreshed() = HomeDashboardRefreshed;

  /// «Empezar»/«Continuar» del próximo entreno: el servidor reutiliza la
  /// sesión en curso de ese día si ya existe.
  const factory HomeDashboardEvent.trainingStarted({
    required String routineId,
    required String dayId,
  }) = HomeDashboardTrainingStarted;

  /// La página ya ha abierto la sesión o ha avisado del error.
  const factory HomeDashboardEvent.trainingHandled() =
      HomeDashboardTrainingHandled;

  /// «Ahora no» en el aviso de configuración pendiente.
  const factory HomeDashboardEvent.setupSnoozed() = HomeDashboardSetupSnoozed;

  /// La página ya ha navegado al onboarding.
  const factory HomeDashboardEvent.onboardingHandled() =
      HomeDashboardOnboardingHandled;
}
