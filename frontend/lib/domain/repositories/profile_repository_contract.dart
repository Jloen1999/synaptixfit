import '../enums/profile/activity_level.dart';
import '../enums/profile/sex.dart';
import '../models/profile/academic_profile.dart';
import '../models/profile/catalog.dart';
import '../models/profile/onboarding_status.dart';
import '../models/profile/profile_summary.dart';
import '../models/profile/wellness_history.dart';
import '../models/profile/wellness_profile.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Perfil del usuario: resumen, onboarding, perfil físico y académico y carreras.
abstract interface class ProfileRepositoryContract {
  Future<AppResult<ProfileSummary>> getSummary();

  Future<AppResult<OnboardingStatus>> getOnboardingStatus();

  Future<AppResult<OnboardingStatus>> completeOnboarding();

  /// Crea o reemplaza el perfil físico completo (PUT).
  Future<AppResult<WellnessProfile>> saveWellnessProfile(
    WellnessProfileDraft draft,
  );

  /// Edición parcial del perfil físico (PATCH): conserva lo que el formulario no toca.
  Future<AppResult<WellnessProfile>> updateWellnessProfile(
    WellnessProfileDraft draft,
  );

  Future<AppResult<GoalSuggestions>> suggestGoals({
    int? age,
    Sex? sex,
    ActivityLevel? activityLevel,
  });

  Future<AppResult<List<WeightRecord>>> getWeightHistory();

  Future<AppResult<List<GoalHistoryEntry>>> getGoalHistory();

  /// Crea o reemplaza el perfil académico (PUT).
  Future<AppResult<AcademicProfile>> saveAcademicProfile(
    AcademicProfileDraft draft,
  );

  Future<AppResult<List<UserDegree>>> getMyDegrees();

  Future<AppResult<UserDegree>> linkDegree(String degreeId);

  Future<AppResult<Unit>> unlinkDegree(String degreeId);

  /// Asignaturas del plan de estudios de las carreras vinculadas.
  Future<AppResult<CatalogSubjectPage>> getMyCatalogSubjects({
    int? course,
    int? semester,
    String? query,
    int page = 0,
    int size = 30,
  });
}
