import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/calendar_feed_dto.dart';
import 'dto/calendar_block_dto.dart';
import 'dto/deadline_dto.dart';
import 'dto/focus_dto.dart';
import 'dto/planner_ai_dto.dart';
import 'dto/planner_options_dto.dart';
import 'dto/weekly_planning_dto.dart';

/// Endpoints del planificador (`/api/v1/planner/**`) y los catálogos auxiliares
/// que necesita (asignaturas, rutinas, retos y fechas del semestre).
class PlannerRemoteDataSource {
  PlannerRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/planner';

  List<Map<String, dynamic>> _list(Object? data) =>
      (data as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> _pageItems(Map<String, dynamic>? data) =>
      _list(data?['items']);

  // ------------------------------------------------------------------ bloques

  Future<List<CalendarBlockDto>> getBlocks(String from, String to) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/blocks',
      queryParameters: {'from': from, 'to': to},
    );
    return _list(response.data).map(CalendarBlockDto.fromJson).toList();
  }

  Future<BlockChangeDto> createBlock(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/blocks',
      data: body,
    );
    return BlockChangeDto.fromJson(response.data!);
  }

  Future<CalendarBlockDto> updateBlock(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/blocks/$id',
      data: body,
    );
    return CalendarBlockDto.fromJson(response.data!);
  }

  Future<BlockChangeDto> rescheduleToNextFreeSlot(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/blocks/$id/reschedule-next',
    );
    return BlockChangeDto.fromJson(response.data!);
  }

  Future<BlockChangeDto> rescheduleBlock(
    String id,
    String start,
    String end,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/blocks/$id/schedule',
      data: {'start': start, 'end': end},
    );
    return BlockChangeDto.fromJson(response.data!);
  }

  Future<void> deleteBlock(String id) => _dio.delete<void>('$_base/blocks/$id');

  Future<BlockCompletionDto> setBlockCompletion(
    String id, {
    required bool completed,
    int? effort,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/blocks/$id/completion',
      data: {'completed': completed, 'effort': ?effort},
    );
    return BlockCompletionDto.fromJson(response.data!);
  }

  Future<BlockCompletionDto> logPastActivity(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/past-activities',
      data: body,
    );
    return BlockCompletionDto.fromJson(response.data!);
  }

  Future<List<CalendarBlockDto>> distributeRoutine(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<List<dynamic>>(
      '$_base/blocks/routine-distribution',
      data: body,
    );
    return _list(response.data).map(CalendarBlockDto.fromJson).toList();
  }

  Future<List<ConflictDto>> getConflicts(String weekStart) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/blocks/conflicts',
      queryParameters: {'weekStart': weekStart},
    );
    return _list(response.data).map(ConflictDto.fromJson).toList();
  }

  // ------------------------------------------------------------ planificación

  Future<SavePlanResponseDto> savePlan(String weekStart) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/plans/$weekStart',
    );
    return SavePlanResponseDto.fromJson(response.data!);
  }

  /// `GET /plans/{weekStart}`: si la semana ya se cerró.
  Future<bool> isWeekClosed(String weekStart) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/plans/$weekStart',
    );
    return response.data?['closed'] as bool? ?? false;
  }

  Future<List<WeeklyLoadDto>> getWeeklyLoads(String from, String to) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/weekly-loads',
      queryParameters: {'from': from, 'to': to},
    );
    return _list(response.data).map(WeeklyLoadDto.fromJson).toList();
  }

  Future<WeeklyLoadDto> updateWellbeing(
    String weekStart,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/weekly-loads/$weekStart',
      data: body,
    );
    return WeeklyLoadDto.fromJson(response.data!);
  }

  Future<WeeklyLoadSyncDto> syncWeeklyLoad(String weekStart) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/weekly-loads/$weekStart/sync',
    );
    return WeeklyLoadSyncDto.fromJson(response.data!);
  }

  Future<WeekBalanceDto> getBalance(String weekStart) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/balance',
      queryParameters: {'weekStart': weekStart},
    );
    return WeekBalanceDto.fromJson(response.data!);
  }

  Future<List<TimelineItemDto>> getTimeline(String from, String to) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/timeline',
      queryParameters: {'from': from, 'to': to},
    );
    return _list(response.data).map(TimelineItemDto.fromJson).toList();
  }

  // ---------------------------------------------------------------- entregas

  Future<DeadlinePageDto> getDeadlines({
    required bool upcoming,
    bool includeOverdue = false,
    String? subjectId,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/deadlines',
      queryParameters: {
        'upcoming': upcoming,
        if (includeOverdue) 'includeOverdue': true,
        'subjectId': ?subjectId,
        'page': page,
        'size': size,
      },
    );
    return DeadlinePageDto.fromJson(response.data!);
  }

  Future<DeadlineDto> getDeadline(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/deadlines/$id',
    );
    return DeadlineDto.fromJson(response.data!);
  }

  Future<DeadlineDto> createDeadline(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/deadlines',
      data: body,
    );
    return DeadlineDto.fromJson(response.data!);
  }

  Future<DeadlineDto> updateDeadline(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/deadlines/$id',
      data: body,
    );
    return DeadlineDto.fromJson(response.data!);
  }

  Future<void> deleteDeadline(String id) =>
      _dio.delete<void>('$_base/deadlines/$id');

  Future<DeadlineCompletionDto> setDeadlineCompletion(
    String id, {
    required bool completed,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/deadlines/$id/completion',
      data: {'completed': completed},
    );
    return DeadlineCompletionDto.fromJson(response.data!);
  }

  // ------------------------------------------------------------------- IA/ICS

  Future<SuggestionDto> suggest(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/suggestions',
      data: body,
    );
    return SuggestionDto.fromJson(response.data!);
  }

  Future<ScheduleScanDto> scanSchedule({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/schedule-scan',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
    return ScheduleScanDto.fromJson(response.data!);
  }

  Future<void> updateAcademicProfile(Map<String, dynamic> body) =>
      _dio.patch<void>('/api/v1/profile/academic', data: body);

  Future<IcsImportDto> importIcs(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/ics/import',
      data: body,
    );
    return IcsImportDto.fromJson(response.data!);
  }

  Future<CalendarFeedStatusDto> calendarFeed() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/calendar-feed',
    );
    return CalendarFeedStatusDto.fromJson(response.data!);
  }

  Future<CalendarFeedCreatedDto> createCalendarFeed() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/calendar-feed',
    );
    return CalendarFeedCreatedDto.fromJson(response.data!);
  }

  Future<void> revokeCalendarFeed() =>
      _dio.delete<void>('$_base/calendar-feed');

  /// Dirección pública del calendario suscrito (la que se pega en Google,
  /// Apple u Outlook): la de la API más el token.
  String calendarFeedUrl(String token) {
    final base = _dio.options.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    return '$base$_base/calendar-feed/$token.ics';
  }

  Future<String> exportIcs() async {
    final response = await _dio.get<String>(
      '$_base/ics/export',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  // ------------------------------------------------------------------ focus

  Future<FocusSessionResponseDto> recordFocusSession(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/focus-sessions',
      data: body,
    );
    return FocusSessionResponseDto.fromJson(response.data ?? const {});
  }

  Future<FocusPlanDto> getFocusPlan() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/focus-sessions/plan',
    );
    return FocusPlanDto.fromJson(response.data!);
  }

  Future<FocusStatsDto> getFocusStats() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/focus-sessions/stats',
    );
    return FocusStatsDto.fromJson(response.data!);
  }

  // ---------------------------------------------------------------- catálogos

  Future<List<SubjectOptionDto>> getSubjects() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/subjects');
    return _list(response.data).map(SubjectOptionDto.fromJson).toList();
  }

  Future<List<RoutineOptionDto>> getRoutines() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/routines',
      queryParameters: {'page': 0, 'size': 100},
    );
    return _pageItems(response.data).map(RoutineOptionDto.fromJson).toList();
  }

  Future<List<ChallengeOptionDto>> getChallenges() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/challenges',
      queryParameters: {'status': 'ACTIVE', 'page': 0, 'size': 100},
    );
    return _pageItems(response.data).map(ChallengeOptionDto.fromJson).toList();
  }
}
