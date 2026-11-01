part of 'home_dashboard_bloc.dart';

enum HomeDashboardStatus { loading, loaded, failure }

@freezed
abstract class HomeDashboardState with _$HomeDashboardState {
  const factory HomeDashboardState({
    @Default(HomeDashboardStatus.loading) HomeDashboardStatus status,
    HomeDashboard? dashboard,

    /// Error de la última carga. Con datos ya pintados se avisa con un SnackBar.
    AppError? error,

    /// Recarga en curso manteniendo los datos visibles.
    @Default(false) bool refreshing,
    @Default(<HomeDueReview>[]) List<HomeDueReview> dueReviews,

    /// Bloques y entregas de los próximos días (sin hoy), en orden.
    @Default(<HomeTodayEvent>[]) List<HomeTodayEvent> upcoming,
    @Default(0) int unreadNotifications,

    /// Configuración pendiente (aviso discreto); nulo si no se pudo leer.
    HomeSetup? setup,

    /// La página debe abrir `/onboarding` (efecto de un solo uso).
    @Default(false) bool onboardingRequired,

    /// Creando o recuperando la sesión de entrenamiento.
    @Default(false) bool startingTraining,

    /// Sesión que la página debe abrir (efecto de un solo uso).
    String? openSessionId,

    /// No se pudo empezar el entreno (efecto de un solo uso).
    AppError? trainingError,

    /// Acción del aviso en curso («Hecho» o «Al próximo hueco»); nula si
    /// no hay ninguna.
    HomeBannerAction? bannerBusy,

    /// Resultado de la acción del aviso (efecto de un solo uso).
    HomeBannerNotice? bannerNotice,
  }) = _HomeDashboardState;
}

/// Acciones del aviso de bloques sin hacer.
enum HomeBannerAction { complete, reschedule }

/// Qué pasó al actuar desde el aviso; la página lo dice con un SnackBar.
@freezed
sealed class HomeBannerNotice with _$HomeBannerNotice {
  /// Bloque marcado como hecho; [xpDelta] es la XP que dio (puede ser 0).
  const factory HomeBannerNotice.completed(int xpDelta) =
      HomeBannerNoticeCompleted;

  /// Bloque llevado al hueco que empieza en [start].
  const factory HomeBannerNotice.rescheduled(DateTime start) =
      HomeBannerNoticeRescheduled;

  const factory HomeBannerNotice.failed(AppError error) =
      HomeBannerNoticeFailed;
}
