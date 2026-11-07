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

  /// «Hecho» en el aviso de bloques sin hacer: marca ese bloque.
  const factory HomeDashboardEvent.bannerBlockCompleted(String blockId) =
      HomeDashboardBannerBlockCompleted;

  /// «Al próximo hueco» en el aviso de bloques sin hacer: lo lleva al primer
  /// hueco libre (lo elige el servidor).
  const factory HomeDashboardEvent.bannerBlockRescheduled(String blockId) =
      HomeDashboardBannerBlockRescheduled;

  /// «Marcar como hecho» o «Desmarcar» de un evento o una entrega de la agenda
  /// (y «Deshacer» del aviso, que pide lo contrario). Desmarcar devuelve la XP
  /// que dio; lo decide el servidor (ADR 0035).
  const factory HomeDashboardEvent.completionSet({
    required String id,
    required HomeEventKind kind,
    required bool completed,
  }) = HomeDashboardCompletionSet;

  /// La página ya ha avisado del resultado de marcar o desmarcar.
  const factory HomeDashboardEvent.completionNoticeHandled() =
      HomeDashboardCompletionNoticeHandled;

  /// La página ya ha avisado del resultado de la acción del aviso.
  const factory HomeDashboardEvent.bannerNoticeHandled() =
      HomeDashboardBannerNoticeHandled;

  /// La página ya ha navegado al onboarding.
  const factory HomeDashboardEvent.onboardingHandled() =
      HomeDashboardOnboardingHandled;

  /// La página ya ha abierto el paso «Permisos».
  const factory HomeDashboardEvent.permissionsIntroHandled() =
      HomeDashboardPermissionsIntroHandled;

  /// La política ya está aceptada: toca ver si falta el onboarding o el paso
  /// «Permisos» (antes no, para no tapar la aceptación; ADR 0034).
  const factory HomeDashboardEvent.onboardingCheckRequested({
    required String userId,
  }) = HomeDashboardOnboardingCheckRequested;
}
