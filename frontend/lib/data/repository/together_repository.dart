import '../../domain/enums/together_enums.dart';
import '../../domain/models/challenges/challenge_template.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/social/together.dart';
import '../../domain/repositories/together_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/social/together_remote_data_source.dart';

/// Implementa [TogetherRepositoryContract] con [TogetherRemoteDataSource].
class TogetherRepository implements TogetherRepositoryContract {
  TogetherRepository(this._remote);

  final TogetherRemoteDataSource _remote;

  /// Los días del tablón viajan como fecha sin hora («2026-11-16»).
  static String _dayOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<AppResult<TogetherOverview>> overview() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.overview()).toDomain(),
      );

  @override
  Future<AppResult<List<ChallengeTemplate>>> challengeTemplates() =>
      RepositoryErrorHandler.guard(
        () async => [
          for (final t in await _remote.challengeTemplates()) t.toDomain(),
        ],
      );

  @override
  Future<AppResult<FriendChallenge>> createChallenge({
    required String templateId,
    required int days,
    required FriendChallengeMode mode,
    required List<String> friendIds,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.createChallenge(
      templateId: templateId,
      days: days,
      mode: mode.apiValue,
      friendIds: friendIds,
    )).toDomain(),
  );

  @override
  Future<AppResult<FriendChallenge>> challenge(String id) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.challenge(id)).toDomain(),
      );

  @override
  Future<AppResult<FriendChallenge>> joinChallenge(String id) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.joinChallenge(id)).toDomain(),
      );

  @override
  Future<AppResult<Unit>> declineChallenge(String id) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.declineChallenge(id);
        return unit;
      });

  @override
  Future<AppResult<Unit>> leaveChallenge(String id) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.leaveChallenge(id);
        return unit;
      });

  @override
  Future<AppResult<Unit>> react(
    String challengeId, {
    required String recipientId,
    required DateTime day,
    required TogetherReaction reaction,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.react(
      challengeId,
      recipientId: recipientId,
      day: _dayOf(day),
      reaction: reaction.apiValue,
    );
    return unit;
  });

  @override
  Future<AppResult<Unit>> removeReaction(
    String challengeId, {
    required String recipientId,
    required DateTime day,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.removeReaction(
      challengeId,
      recipientId: recipientId,
      day: _dayOf(day),
    );
    return unit;
  });

  @override
  Future<AppResult<FriendStreak>> proposeStreak(String friendId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.proposeStreak(friendId)).toDomain(),
      );

  @override
  Future<AppResult<FriendStreak>> acceptStreak(String id) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.acceptStreak(id)).toDomain(),
      );

  @override
  Future<AppResult<Unit>> declineStreak(String id) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.declineStreak(id);
        return unit;
      });

  @override
  Future<AppResult<Unit>> endStreak(String id) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.endStreak(id);
        return unit;
      });

  @override
  Future<AppResult<FriendStreak>> nudgeStreak(String id) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.nudgeStreak(id)).toDomain(),
      );

  @override
  Future<AppResult<WorkoutTogether>> createWorkout({
    required String routineId,
    String? dayId,
    required List<String> friendIds,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.createWorkout(
      routineId: routineId,
      dayId: dayId,
      friendIds: friendIds,
    )).toDomain(),
  );

  @override
  Future<AppResult<WorkoutTogether>> workout(String id) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.workout(id)).toDomain(),
      );

  @override
  Future<AppResult<WorkoutTogether?>> workoutBySession(String sessionId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.workoutBySession(sessionId))?.toDomain(),
      );

  @override
  Future<AppResult<WorkoutTogether>> joinWorkout(String id) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.joinWorkout(id)).toDomain(),
      );

  @override
  Future<AppResult<Unit>> declineWorkout(String id) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.declineWorkout(id);
        return unit;
      });

  @override
  Future<AppResult<Unit>> leaveWorkout(String id) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.leaveWorkout(id);
        return unit;
      });

  @override
  Future<AppResult<String>> startWorkout(String id) =>
      RepositoryErrorHandler.guard(() => _remote.startWorkout(id));

  @override
  Future<AppResult<Unit>> reportUser(
    String userId, {
    required UserReportContext context,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.reportUser(userId, context: context.apiValue);
    return unit;
  });
}
