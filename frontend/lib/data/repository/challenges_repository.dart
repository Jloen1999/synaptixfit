import '../../domain/enums/challenge_type.dart';
import '../../domain/models/challenges/challenge.dart';
import '../../domain/models/challenges/challenge_draft.dart';
import '../../domain/models/challenges/challenge_outcome.dart';
import '../../domain/models/challenges/challenge_page.dart';
import '../../domain/models/challenges/challenge_progress_entry.dart';
import '../../domain/models/challenges/challenge_query.dart';
import '../../domain/models/challenges/challenge_summary.dart';
import '../../domain/models/challenges/pending_milestone.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/challenges_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/challenges/challenges_remote_data_source.dart';
import '../remote_data_source/challenges/dto/challenge_api_values.dart';
import '../remote_data_source/challenges/dto/challenge_request_dto.dart';

class ChallengesRepository implements ChallengesRepositoryContract {
  ChallengesRepository(this._remote);

  final ChallengesRemoteDataSource _remote;

  @override
  Future<AppResult<ChallengePage>> listMine({
    required ChallengeQuery query,
    required int page,
    required int size,
  }) => RepositoryErrorHandler.guard(() async {
    final status = query.status;
    final type = query.type;
    final tasks = query.tasks;
    final search = query.search?.trim();
    final dto = await _remote.listMine(
      status: status == null ? null : ChallengeApiValues.statusToApi(status),
      type: type == null ? null : ChallengeApiValues.typeToApi(type),
      tasks: tasks == null ? null : ChallengeApiValues.tasksToApi(tasks),
      q: search == null || search.isEmpty ? null : search,
      page: page,
      size: size,
    );
    return dto.toDomain();
  });

  @override
  Future<AppResult<ChallengeSummary>> summary() => RepositoryErrorHandler.guard(
    () async => (await _remote.summary()).toDomain(),
  );

  @override
  Future<AppResult<ChallengePage>> community({
    ChallengeType? type,
    String? search,
    required int page,
    required int size,
  }) => RepositoryErrorHandler.guard(() async {
    final q = search?.trim();
    final dto = await _remote.community(
      type: type == null ? null : ChallengeApiValues.typeToApi(type),
      q: q == null || q.isEmpty ? null : q,
      page: page,
      size: size,
    );
    return dto.toDomain();
  });

  @override
  Future<AppResult<List<PendingMilestone>>> pendingMilestones() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.pendingMilestones())
            .map((p) => p.toDomain())
            .toList(),
      );

  @override
  Future<AppResult<Challenge>> get(String challengeId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.get(challengeId)).toDomain(),
      );

  @override
  Future<AppResult<Challenge>> create(ChallengeDraft draft) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.create(
          CreateChallengeRequestDto.fromDomain(draft),
        )).toDomain(),
      );

  @override
  Future<AppResult<Challenge>> update(
    String challengeId,
    ChallengeChanges changes,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.update(
      challengeId,
      UpdateChallengeRequestDto.fromDomain(changes),
    )).toDomain(),
  );

  @override
  Future<AppResult<Unit>> delete(String challengeId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.delete(challengeId);
        return unit;
      });

  @override
  Future<AppResult<Challenge>> clone(String challengeId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.clone(challengeId)).toDomain(),
      );

  @override
  Future<AppResult<ChallengeOutcome>> setCompleted(
    String challengeId, {
    required bool completed,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.setCompleted(
      challengeId,
      completed: completed,
    )).toDomain(),
  );

  @override
  Future<AppResult<ChallengeOutcome>> setMilestoneCompleted(
    String challengeId,
    String milestoneId, {
    required bool completed,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.setMilestoneCompleted(
      challengeId,
      milestoneId,
      completed: completed,
    )).toDomain(),
  );

  @override
  Future<AppResult<ChallengeOutcome>> recordProgress(
    String challengeId, {
    String? milestoneId,
    required double value,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.recordProgress(
      challengeId,
      milestoneId: milestoneId,
      value: value,
    )).toDomain(),
  );

  @override
  Future<AppResult<List<ChallengeProgressEntry>>> progressHistory(
    String challengeId,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.progressHistory(
      challengeId,
    )).map((e) => e.toDomain()).toList(),
  );

  @override
  Future<AppResult<ChallengeOutcome>> replaceMilestones(
    String challengeId,
    List<MilestoneDraft> milestones,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.replaceMilestones(
      challengeId,
      milestones.map(MilestoneRequestDto.fromDomain).toList(),
    )).toDomain(),
  );

  @override
  Future<AppResult<Challenge>> reorderMilestones(
    String challengeId,
    List<String> milestoneIds,
  ) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.reorderMilestones(challengeId, milestoneIds)).toDomain(),
  );
}
