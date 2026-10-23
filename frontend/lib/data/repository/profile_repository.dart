import '../../domain/enums/profile/activity_level.dart';
import '../../domain/enums/profile/sex.dart';
import '../../domain/models/profile/academic_profile.dart';
import '../../domain/models/profile/catalog.dart';
import '../../domain/models/profile/onboarding_status.dart';
import '../../domain/models/profile/profile_summary.dart';
import '../../domain/models/profile/wellness_history.dart';
import '../../domain/models/profile/wellness_profile.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/profile_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/profile/dto/academic_profile_dto.dart';
import '../remote_data_source/profile/dto/wellness_profile_dto.dart';
import '../remote_data_source/profile/profile_remote_data_source.dart';

class ProfileRepository implements ProfileRepositoryContract {
  ProfileRepository(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<AppResult<ProfileSummary>> getSummary() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.summary()).toDomain(),
      );

  @override
  Future<AppResult<OnboardingStatus>> getOnboardingStatus() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.onboarding()).toDomain(),
      );

  @override
  Future<AppResult<OnboardingStatus>> completeOnboarding() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.completeOnboarding()).toDomain(),
      );

  @override
  Future<AppResult<WellnessProfile>> saveWellnessProfile(
    WellnessProfileDraft draft,
  ) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.saveWellness(wellnessDraftToJson(draft))).toDomain(),
  );

  @override
  Future<AppResult<WellnessProfile>> updateWellnessProfile(
    WellnessProfileDraft draft,
  ) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.patchWellness(wellnessDraftToJson(draft))).toDomain(),
  );

  @override
  Future<AppResult<GoalSuggestions>> suggestGoals({
    int? age,
    Sex? sex,
    ActivityLevel? activityLevel,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.goalSuggestions({
      'age': ?age,
      'sex': ?sex?.apiValue,
      'activityLevel': ?activityLevel?.apiValue,
    })).toDomain(),
  );

  @override
  Future<AppResult<List<WeightRecord>>> getWeightHistory() =>
      RepositoryErrorHandler.guard(() async {
        final records = (await _remote.weightHistory())
            .map((r) => r.toDomain())
            .toList();
        records.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
        return records;
      });

  @override
  Future<AppResult<List<GoalHistoryEntry>>> getGoalHistory() =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.goalHistory()).map((g) => g.toDomain()).toList(),
      );

  @override
  Future<AppResult<AcademicProfile>> saveAcademicProfile(
    AcademicProfileDraft draft,
  ) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.saveAcademic(academicDraftToJson(draft))).toDomain(),
  );

  @override
  Future<AppResult<List<UserDegree>>> getMyDegrees() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.degrees()).map((d) => d.toDomain()).toList(),
      );

  @override
  Future<AppResult<UserDegree>> linkDegree(String degreeId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.linkDegree(degreeId)).toDomain(),
      );

  @override
  Future<AppResult<Unit>> unlinkDegree(String degreeId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.unlinkDegree(degreeId);
        return unit;
      });

  @override
  Future<AppResult<CatalogSubjectPage>> getMyCatalogSubjects({
    int? course,
    int? semester,
    String? query,
    int page = 0,
    int size = 30,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.degreeSubjects(
      course: course,
      semester: semester,
      query: query,
      page: page,
      size: size,
    )).toDomain(),
  );
}
