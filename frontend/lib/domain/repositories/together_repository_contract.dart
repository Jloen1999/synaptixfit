import '../enums/together_enums.dart';
import '../models/challenges/challenge_template.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/social/together.dart';

/// «Con amigos» asíncrono (ADR 0044): retos con amigos, rachas con un amigo,
/// «Entrenamos juntos» y denunciar a una persona.
abstract interface class TogetherRepositoryContract {
  Future<AppResult<TogetherOverview>> overview();

  Future<AppResult<List<ChallengeTemplate>>> challengeTemplates();

  Future<AppResult<FriendChallenge>> createChallenge({
    required String templateId,
    required int days,
    required FriendChallengeMode mode,
    required List<String> friendIds,
  });

  Future<AppResult<FriendChallenge>> challenge(String id);

  Future<AppResult<FriendChallenge>> joinChallenge(String id);

  Future<AppResult<Unit>> declineChallenge(String id);

  Future<AppResult<Unit>> leaveChallenge(String id);

  Future<AppResult<Unit>> react(
    String challengeId, {
    required String recipientId,
    required DateTime day,
    required TogetherReaction reaction,
  });

  Future<AppResult<Unit>> removeReaction(
    String challengeId, {
    required String recipientId,
    required DateTime day,
  });

  Future<AppResult<FriendStreak>> proposeStreak(String friendId);

  Future<AppResult<FriendStreak>> acceptStreak(String id);

  Future<AppResult<Unit>> declineStreak(String id);

  Future<AppResult<Unit>> endStreak(String id);

  Future<AppResult<FriendStreak>> nudgeStreak(String id);

  Future<AppResult<WorkoutTogether>> createWorkout({
    required String routineId,
    String? dayId,
    required List<String> friendIds,
  });

  Future<AppResult<WorkoutTogether>> workout(String id);

  /// El de una sesión propia, o `null` si la sesión no es de entrenar juntos.
  Future<AppResult<WorkoutTogether?>> workoutBySession(String sessionId);

  Future<AppResult<WorkoutTogether>> joinWorkout(String id);

  Future<AppResult<Unit>> declineWorkout(String id);

  Future<AppResult<Unit>> leaveWorkout(String id);

  /// Empieza (o retoma) mi sesión y devuelve su id.
  Future<AppResult<String>> startWorkout(String id);

  Future<AppResult<Unit>> reportUser(
    String userId, {
    required UserReportContext context,
  });
}
