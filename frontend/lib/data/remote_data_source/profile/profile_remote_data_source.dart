import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/academic_profile_dto.dart';
import 'dto/catalog_dto.dart';
import 'dto/profile_summary_dto.dart';
import 'dto/wellness_history_dto.dart';
import 'dto/wellness_profile_dto.dart';

/// Endpoints del perfil (`/api/v1/profile/**`).
class ProfileRemoteDataSource {
  ProfileRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/profile';

  Future<ProfileSummaryDto> summary() async {
    final response = await _dio.get<Map<String, dynamic>>(_base);
    return ProfileSummaryDto.fromJson(response.data!);
  }

  Future<OnboardingStatusDto> onboarding() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/onboarding');
    return OnboardingStatusDto.fromJson(response.data!);
  }

  Future<OnboardingStatusDto> completeOnboarding() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/onboarding/complete',
    );
    return OnboardingStatusDto.fromJson(response.data!);
  }

  Future<WellnessProfileDto> saveWellness(Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/wellness',
      data: body,
    );
    return WellnessProfileDto.fromJson(response.data!);
  }

  Future<WellnessProfileDto> patchWellness(Map<String, dynamic> body) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/wellness',
      data: body,
    );
    return WellnessProfileDto.fromJson(response.data!);
  }

  Future<GoalSuggestionsDto> goalSuggestions(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/wellness/goal-suggestions',
      data: body,
    );
    return GoalSuggestionsDto.fromJson(response.data!);
  }

  Future<List<WeightRecordDto>> weightHistory() async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/wellness/weight-history',
    );
    return response.data!
        .map((e) => WeightRecordDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GoalHistoryDto>> goalHistory() async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/wellness/goal-history',
    );
    return response.data!
        .map((e) => GoalHistoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AcademicProfileDto> saveAcademic(Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/academic',
      data: body,
    );
    return AcademicProfileDto.fromJson(response.data!);
  }

  Future<List<UserDegreeDto>> degrees() async {
    final response = await _dio.get<List<dynamic>>('$_base/degrees');
    return response.data!
        .map((e) => UserDegreeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserDegreeDto> linkDegree(String degreeId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/degrees/$degreeId',
    );
    return UserDegreeDto.fromJson(response.data!);
  }

  Future<void> unlinkDegree(String degreeId) =>
      _dio.delete<void>('$_base/degrees/$degreeId');

  Future<UserCatalogSubjectPageDto> degreeSubjects({
    int? course,
    int? semester,
    String? query,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/degrees/subjects',
      queryParameters: {
        'course': ?course,
        'semester': ?semester,
        if (query != null && query.isNotEmpty) 'q': query,
        'page': page,
        'size': size,
      },
    );
    return UserCatalogSubjectPageDto.fromJson(response.data!);
  }
}
