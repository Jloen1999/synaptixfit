import '../enums/together_enums.dart';
import '../models/challenges/challenge_template.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/social/together.dart';

/// «Con amigos» (ADR 0044 y 0045): retos con amigos, rachas con un amigo,
/// «Entrenamos juntos», «Estudiamos juntos», sus topes y denunciar a una
/// persona.
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

  /// Topes de amigos y rondas que manda el servidor.
  Future<AppResult<TogetherLimits>> limits();

  Future<AppResult<StudyRoom>> createStudyRoom({
    required StudyRoomTimes times,
    required int rounds,
    required List<String> friendIds,
    String? subjectId,
  });

  Future<AppResult<StudyRoom>> studyRoom(String id);

  /// Acepta la invitación o vuelve tras salir («Deshacer»).
  Future<AppResult<StudyRoom>> joinStudyRoom(String id);

  Future<AppResult<Unit>> declineStudyRoom(String id);

  Future<AppResult<Unit>> leaveStudyRoom(String id);

  Future<AppResult<StudyRoom>> startStudyRoom(String id);

  /// Cambia los minutos antes de empezar (cualquiera de dentro, ADR 0053).
  Future<AppResult<StudyRoom>> changeStudyRoomTimes(
    String id,
    StudyRoomTimes times,
  );

  /// Mi asignatura para las rondas (`null`: ninguna).
  Future<AppResult<StudyRoom>> chooseStudyRoomSubject(
    String id, {
    String? subjectId,
  });

  Future<AppResult<StudyRoom>> reactInStudyRoom(
    String id, {
    required StudyRoomReaction reaction,
  });

  Future<AppResult<Unit>> reportUser(
    String userId, {
    required UserReportContext context,
  });
}
