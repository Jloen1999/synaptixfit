import 'package:dio/dio.dart';

import '../../../domain/models/training/training_page.dart';
import '../api/api_client.dart';
import 'dto/page_dto.dart';
import 'dto/recommendation_dto.dart';
import 'dto/routine_dto.dart';
import 'dto/session_dto.dart';
import 'dto/wellbeing_dto.dart';

/// Sesiones, día pendiente, check-in, plan semanal y sugerencias (`/api/v1/training`).
class TrainingRemoteDataSource {
  TrainingRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/training';

  /// `null` cuando la API responde 204 (sin día pendiente).
  Future<PendingDayDto?> pendingDay() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/pending-day');
    final data = response.data;
    return data == null || response.statusCode == 204
        ? null
        : PendingDayDto.fromJson(data);
  }

  Future<SessionDto> startSession(String? routineId, String? dayId) => _session(
    _dio.post<Map<String, dynamic>>(
      '$_base/sessions',
      data: {'routineId': ?routineId, 'dayId': ?dayId},
    ),
  );

  Future<SessionDto> getSession(String sessionId) =>
      _session(_dio.get<Map<String, dynamic>>('$_base/sessions/$sessionId'));

  Future<SessionAdaptationDto> getSessionAdaptation(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/sessions/$sessionId/adaptation',
    );
    return SessionAdaptationDto.fromJson(response.data!);
  }

  Future<TrainingPage<SessionDto>> listSessions({
    bool? completed,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/sessions',
      queryParameters: {'completed': ?completed, 'page': page, 'size': size},
    );
    return parseTrainingPage(response.data!, SessionDto.fromJson);
  }

  Future<SessionDto> recordSet(String sessionId, RecordSetRequestDto set) =>
      _session(
        _dio.post<Map<String, dynamic>>(
          '$_base/sessions/$sessionId/sets',
          data: set.toJson(),
        ),
      );

  Future<SessionDto> deleteSet(String sessionId, String setId) => _session(
    _dio.delete<Map<String, dynamic>>('$_base/sessions/$sessionId/sets/$setId'),
  );

  Future<FinishSessionResponseDto> finish(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/sessions/$sessionId/finish',
      data: body,
    );
    return FinishSessionResponseDto.fromJson(response.data!);
  }

  Future<UnmarkSessionResponseDto> unmark(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/sessions/$sessionId/unmark',
    );
    return UnmarkSessionResponseDto.fromJson(response.data!);
  }

  /// Descarta una sesión sin terminar o elimina una terminada.
  Future<void> delete(String sessionId) =>
      _dio.delete<void>('$_base/sessions/$sessionId');

  /// Sesiones sin terminar (en curso y abandonadas).
  Future<List<OpenSessionDto>> openSessions() async {
    final response = await _dio.get<List<dynamic>>('$_base/sessions/open');
    return (response.data ?? const [])
        .map((e) => OpenSessionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Corrige el RPE y la duración de una sesión terminada.
  Future<SessionDto> correct(
    String sessionId, {
    required int rpe,
    required int durationMinutes,
  }) => _session(
    _dio.patch<Map<String, dynamic>>(
      '$_base/sessions/$sessionId',
      data: {'rpe': rpe, 'durationMinutes': durationMinutes},
    ),
  );

  /// Registra un día de rutina hecho sin la app (fecha `yyyy-MM-dd`).
  Future<PastSessionResponseDto> logPast(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/sessions/past',
      data: body,
    );
    return PastSessionResponseDto.fromJson(response.data!);
  }

  /// `null` cuando la API responde 204 (sin check-in hoy).
  Future<CheckInDto?> todayCheckIn() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/check-ins/today',
    );
    final data = response.data;
    return data == null || response.statusCode == 204
        ? null
        : CheckInDto.fromJson(data);
  }

  Future<SubmitCheckInResponseDto> submitCheckIn(
    CheckInRequestDto request,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/check-ins/today',
      data: request.toJson(),
    );
    return SubmitCheckInResponseDto.fromJson(response.data!);
  }

  Future<TrainingPage<CheckInDto>> listCheckIns({
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/check-ins',
      queryParameters: {'page': page, 'size': size},
    );
    return parseTrainingPage(response.data!, CheckInDto.fromJson);
  }

  Future<WeeklyPlanDto> getPlan(String weekStart) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/weekly-plans/$weekStart',
    );
    return WeeklyPlanDto.fromJson(response.data!);
  }

  Future<WeeklyPlanDto> savePlan(
    String weekStart,
    WeeklyPlanRequestDto request,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/weekly-plans/$weekStart',
      data: request.toJson(),
    );
    return WeeklyPlanDto.fromJson(response.data!);
  }

  Future<void> deletePlan(String weekStart) =>
      _dio.delete<void>('$_base/weekly-plans/$weekStart');

  Future<TrainingPage<WeeklyPlanDto>> listPlans({
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/weekly-plans',
      queryParameters: {'page': page, 'size': size},
    );
    return parseTrainingPage(response.data!, WeeklyPlanDto.fromJson);
  }

  Future<TrainingPage<RecommendationDto>> recommendations({
    bool? applied,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/recommendations',
      queryParameters: {'applied': ?applied, 'page': page, 'size': size},
    );
    return parseTrainingPage(response.data!, RecommendationDto.fromJson);
  }

  Future<RecommendationDto> apply(String recommendationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/recommendations/$recommendationId/apply',
    );
    return RecommendationDto.fromJson(response.data!);
  }

  Future<void> discard(String recommendationId) =>
      _dio.delete<void>('$_base/recommendations/$recommendationId');

  /// Peso del perfil de bienestar (solo se usa para estimar calorías).
  Future<BodyWeightDto> bodyWeight() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/profile/wellness',
    );
    return BodyWeightDto.fromJson(response.data ?? const {});
  }

  Future<SessionDto> _session(
    Future<Response<Map<String, dynamic>>> request,
  ) async => SessionDto.fromJson((await request).data!);
}
