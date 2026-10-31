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
  }) = _HomeDashboardState;
}
