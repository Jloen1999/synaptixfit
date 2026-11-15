import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../challenges/dto/challenge_dto.dart';
import 'dto/together_dto.dart';

/// Endpoints de «Con amigos» (`/api/v1/together`, ADR 0044 y 0045) y la
/// denuncia de una persona (`/api/v1/social/users/{id}/report`).
class TogetherRemoteDataSource {
  TogetherRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/together';

  Future<TogetherOverviewDto> overview() async {
    final r = await _dio.get<Map<String, dynamic>>(_base);
    return TogetherOverviewDto.fromJson(r.data!);
  }

  Future<List<ChallengeTemplateDto>> challengeTemplates() async {
    final r = await _dio.get<List<dynamic>>('$_base/challenges/templates');
    return [
      for (final json in r.data!)
        ChallengeTemplateDto.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<FriendChallengeDto> createChallenge({
    required String templateId,
    required int days,
    required String mode,
    required List<String> friendIds,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/challenges',
      data: {
        'templateId': templateId,
        'days': days,
        'mode': mode,
        'friendIds': friendIds,
      },
    );
    return FriendChallengeDto.fromJson(r.data!);
  }

  Future<FriendChallengeDto> challenge(String id) async {
    final r = await _dio.get<Map<String, dynamic>>('$_base/challenges/$id');
    return FriendChallengeDto.fromJson(r.data!);
  }

  Future<FriendChallengeDto> joinChallenge(String id) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/challenges/$id/join',
    );
    return FriendChallengeDto.fromJson(r.data!);
  }

  Future<void> declineChallenge(String id) =>
      _dio.post<void>('$_base/challenges/$id/decline');

  Future<void> leaveChallenge(String id) =>
      _dio.post<void>('$_base/challenges/$id/leave');

  Future<void> react(
    String challengeId, {
    required String recipientId,
    required String day,
    required String reaction,
  }) => _dio.put<void>(
    '$_base/challenges/$challengeId/reactions',
    data: {'recipientId': recipientId, 'day': day, 'reaction': reaction},
  );

  Future<void> removeReaction(
    String challengeId, {
    required String recipientId,
    required String day,
  }) => _dio.delete<void>(
    '$_base/challenges/$challengeId/reactions',
    queryParameters: {'recipientId': recipientId, 'day': day},
  );

  Future<FriendStreakDto> proposeStreak(String friendId) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/streaks',
      data: {'friendId': friendId},
    );
    return FriendStreakDto.fromJson(r.data!);
  }

  Future<FriendStreakDto> acceptStreak(String id) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/streaks/$id/accept',
    );
    return FriendStreakDto.fromJson(r.data!);
  }

  Future<void> declineStreak(String id) =>
      _dio.post<void>('$_base/streaks/$id/decline');

  Future<void> endStreak(String id) => _dio.delete<void>('$_base/streaks/$id');

  Future<FriendStreakDto> nudgeStreak(String id) async {
    final r = await _dio.post<Map<String, dynamic>>('$_base/streaks/$id/nudge');
    return FriendStreakDto.fromJson(r.data!);
  }

  Future<WorkoutTogetherDto> createWorkout({
    required String routineId,
    String? dayId,
    required List<String> friendIds,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/workouts',
      data: {'routineId': routineId, 'dayId': ?dayId, 'friendIds': friendIds},
    );
    return WorkoutTogetherDto.fromJson(r.data!);
  }

  Future<WorkoutTogetherDto> workout(String id) async {
    final r = await _dio.get<Map<String, dynamic>>('$_base/workouts/$id');
    return WorkoutTogetherDto.fromJson(r.data!);
  }

  /// `null` (204 sin cuerpo) si la sesión no es de entrenar juntos.
  Future<WorkoutTogetherDto?> workoutBySession(String sessionId) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_base/workouts/by-session/$sessionId',
    );
    final data = r.data;
    return r.statusCode == 204 || data == null
        ? null
        : WorkoutTogetherDto.fromJson(data);
  }

  Future<WorkoutTogetherDto> joinWorkout(String id) async {
    final r = await _dio.post<Map<String, dynamic>>('$_base/workouts/$id/join');
    return WorkoutTogetherDto.fromJson(r.data!);
  }

  Future<void> declineWorkout(String id) =>
      _dio.post<void>('$_base/workouts/$id/decline');

  Future<void> leaveWorkout(String id) =>
      _dio.post<void>('$_base/workouts/$id/leave');

  Future<String> startWorkout(String id) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/workouts/$id/start',
    );
    return r.data!['sessionId'] as String;
  }

  Future<TogetherLimitsDto> limits() async {
    final r = await _dio.get<Map<String, dynamic>>('$_base/limits');
    return TogetherLimitsDto.fromJson(r.data!);
  }

  Future<StudyRoomDto> createStudyRoom({
    required String length,
    required int rounds,
    required List<String> friendIds,
    String? subjectId,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/study-rooms',
      data: {
        'length': length,
        'rounds': rounds,
        'friendIds': friendIds,
        'subjectId': ?subjectId,
      },
    );
    return StudyRoomDto.fromJson(r.data!);
  }

  Future<StudyRoomDto> studyRoom(String id) async {
    final r = await _dio.get<Map<String, dynamic>>('$_base/study-rooms/$id');
    return StudyRoomDto.fromJson(r.data!);
  }

  Future<StudyRoomDto> joinStudyRoom(String id) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/study-rooms/$id/join',
    );
    return StudyRoomDto.fromJson(r.data!);
  }

  Future<void> declineStudyRoom(String id) =>
      _dio.post<void>('$_base/study-rooms/$id/decline');

  Future<void> leaveStudyRoom(String id) =>
      _dio.post<void>('$_base/study-rooms/$id/leave');

  Future<StudyRoomDto> startStudyRoom(String id) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_base/study-rooms/$id/start',
    );
    return StudyRoomDto.fromJson(r.data!);
  }

  Future<StudyRoomDto> chooseStudyRoomSubject(
    String id, {
    String? subjectId,
  }) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '$_base/study-rooms/$id/subject',
      data: {'subjectId': subjectId},
    );
    return StudyRoomDto.fromJson(r.data!);
  }

  Future<StudyRoomDto> reactInStudyRoom(
    String id, {
    required String reaction,
  }) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '$_base/study-rooms/$id/reaction',
      data: {'reaction': reaction},
    );
    return StudyRoomDto.fromJson(r.data!);
  }

  Future<void> reportUser(String userId, {required String context}) =>
      _dio.post<void>(
        '/api/v1/social/users/$userId/report',
        data: {'context': context},
      );
}
