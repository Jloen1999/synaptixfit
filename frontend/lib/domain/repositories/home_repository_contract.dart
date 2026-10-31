import '../models/home/home_setup.dart';
import '../models/home/home_dashboard.dart';
import '../models/home/home_due_review.dart';
import '../models/home/home_onboarding_status.dart';
import '../models/result/app_result.dart';

/// Datos de la pestaña Inicio.
abstract interface class HomeRepositoryContract {
  Future<AppResult<HomeDashboard>> getDashboard();

  Future<AppResult<List<HomeDueReview>>> getDueReviews({int limit = 5});

  Future<AppResult<int>> getUnreadNotificationsCount();

  Future<AppResult<HomeOnboardingStatus>> getOnboardingStatus();

  /// Configuración pendiente según el enfoque (sin el «Ahora no» local).
  Future<AppResult<HomeSetup>> getSetup();
}
