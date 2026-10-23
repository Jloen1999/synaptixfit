import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/challenge_dto.dart';
import 'dto/challenge_request_dto.dart';

/// Endpoints de retos (`/api/v1/challenges`). El usuario sale del token.
class ChallengesRemoteDataSource {
  ChallengesRemoteDataSource(ApiClient client) : _dio = client.dio;

  static const _base = '/api/v1/challenges';

  final Dio _dio;

  Future<ChallengePageDto> listMine({
    String? status,
    String? type,
    String? tasks,
    String? q,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'status': ?status,
        'type': ?type,
        'tasks': ?tasks,
        'q': ?q,
        'page': page,
        'size': size,
      },
    );
    return ChallengePageDto.fromJson(response.data!);
  }

  Future<ChallengeSummaryDto> summary() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/summary');
    return ChallengeSummaryDto.fromJson(response.data!);
  }

  Future<ChallengePageDto> community({
    String? type,
    String? q,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/community',
      queryParameters: {'type': ?type, 'q': ?q, 'page': page, 'size': size},
    );
    return ChallengePageDto.fromJson(response.data!);
  }

  Future<List<PendingMilestoneDto>> pendingMilestones() async {
    final response = await _dio.get<List<dynamic>>('$_base/milestones/pending');
    return response.data!
        .map((e) => PendingMilestoneDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeDto> get(String challengeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/$challengeId',
    );
    return ChallengeDto.fromJson(response.data!);
  }

  Future<ChallengeDto> create(CreateChallengeRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _base,
      data: request.toJson(),
    );
    return ChallengeDto.fromJson(response.data!);
  }

  Future<ChallengeDto> update(
    String challengeId,
    UpdateChallengeRequestDto request,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$challengeId',
      data: request.toJson(),
    );
    return ChallengeDto.fromJson(response.data!);
  }

  Future<void> delete(String challengeId) =>
      _dio.delete<void>('$_base/$challengeId');

  Future<ChallengeDto> clone(String challengeId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$challengeId/clone',
    );
    return ChallengeDto.fromJson(response.data!);
  }

  Future<ChallengeOutcomeDto> setCompleted(
    String challengeId, {
    required bool completed,
  }) =>
      _outcome('$_base/$challengeId/${completed ? 'complete' : 'uncomplete'}');

  Future<ChallengeOutcomeDto> setMilestoneCompleted(
    String challengeId,
    String milestoneId, {
    required bool completed,
  }) => _outcome(
    '$_base/$challengeId/milestones/$milestoneId/'
    '${completed ? 'complete' : 'uncomplete'}',
  );

  Future<ChallengeOutcomeDto> recordProgress(
    String challengeId, {
    String? milestoneId,
    required double amount,
  }) => _outcome(
    '$_base/$challengeId/progress',
    data: {'milestoneId': ?milestoneId, 'amount': amount},
  );

  Future<List<ProgressEntryDto>> progressHistory(String challengeId) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/$challengeId/progress',
    );
    return response.data!
        .map((e) => ProgressEntryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeOutcomeDto> replaceMilestones(
    String challengeId,
    List<MilestoneRequestDto> milestones,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/$challengeId/milestones',
      data: {'milestones': milestones.map((m) => m.toJson()).toList()},
    );
    return ChallengeOutcomeDto.fromJson(response.data!);
  }

  Future<ChallengeDto> reorderMilestones(
    String challengeId,
    List<String> milestoneIds,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/$challengeId/milestones/order',
      data: {'milestoneIds': milestoneIds},
    );
    return ChallengeDto.fromJson(response.data!);
  }

  Future<ChallengeOutcomeDto> _outcome(String path, {Object? data}) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: data);
    return ChallengeOutcomeDto.fromJson(response.data!);
  }
}
