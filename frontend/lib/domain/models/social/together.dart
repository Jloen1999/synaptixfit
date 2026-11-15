import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/challenge_rule_kind.dart';
import '../../enums/together_enums.dart';

part 'together.freezed.dart';

/// Otra persona en lo compartido con amigos: solo nombre y foto. [name] vacío
/// si borró su cuenta.
@freezed
abstract class TogetherPerson with _$TogetherPerson {
  const factory TogetherPerson({
    required String id,
    @Default('') String name,
    String? avatarUrl,
  }) = _TogetherPerson;
}

/// Reto privado entre amigos (ADR 0044). En modo juntos se ve el total del
/// grupo y quién ha aportado; los puntos de cada uno solo en competición.
@freezed
abstract class FriendChallenge with _$FriendChallenge {
  const factory FriendChallenge({
    required String id,
    required String title,
    @Default('') String goal,
    required ChallengeRuleMetric metric,
    required ChallengeRuleUnit unit,
    required FriendChallengeMode mode,
    required DateTime startAt,
    required DateTime endAt,
    required int days,
    required TogetherMemberStatus myStatus,
    required TogetherPerson creator,
    @Default(0) int groupTotal,
    @Default(1) int groupTarget,
    @Default(0) int myPoints,
    @Default(1) int myTarget,
    @Default(false) bool over,
    @Default(<FriendChallengeMember>[]) List<FriendChallengeMember> members,
    @Default(<FriendChallengeBoardEntry>[])
    List<FriendChallengeBoardEntry> board,
  }) = _FriendChallenge;

  const FriendChallenge._();

  bool get invitation => myStatus == TogetherMemberStatus.invited;
}

/// Persona de un reto con amigos. [points] solo en competición.
@freezed
abstract class FriendChallengeMember with _$FriendChallengeMember {
  const factory FriendChallengeMember({
    required TogetherPerson person,
    required TogetherMemberStatus status,
    @Default(false) bool contributed,
    int? points,

    /// Soy yo.
    @Default(false) bool me,
  }) = _FriendChallengeMember;
}

/// Entrada del tablón: alguien sumó algo ese día. [counts] solo llega en las
/// entradas propias; de las demás solo se sabe la reacción propia.
@freezed
abstract class FriendChallengeBoardEntry with _$FriendChallengeBoardEntry {
  const factory FriendChallengeBoardEntry({
    required TogetherPerson person,
    required DateTime day,
    @Default(false) bool mine,
    @Default(<TogetherReaction, int>{}) Map<TogetherReaction, int> counts,
    TogetherReaction? myReaction,
  }) = _FriendChallengeBoardEntry;
}

/// Racha con un amigo (ADR 0044).
@freezed
abstract class FriendStreak with _$FriendStreak {
  const factory FriendStreak({
    required String id,
    required FriendStreakStatus status,
    required TogetherPerson friend,
    @Default(false) bool requestedByMe,
    @Default(0) int days,
    @Default(false) bool meDone,
    @Default(false) bool friendDone,
    @Default(false) bool paused,
    @Default(false) bool canNudge,
  }) = _FriendStreak;

  const FriendStreak._();

  /// Propuesta que me han hecho y tengo que contestar.
  bool get invitation => status == FriendStreakStatus.pending && !requestedByMe;
}

/// «Entrenamos juntos» (ADR 0044): ejercicios por su posición y, de cada
/// persona, cómo va y qué posiciones tiene hechas. Sin pesos ni esfuerzo.
@freezed
abstract class WorkoutTogether with _$WorkoutTogether {
  const factory WorkoutTogether({
    required String id,
    required TogetherPerson host,
    String? routineName,
    String? dayName,
    @Default(0) int dayNumber,
    required DateTime date,
    @Default(false) bool today,
    required TogetherMemberStatus myStatus,
    String? mySessionId,
    int? myMinutes,
    @Default(<WorkoutSlot>[]) List<WorkoutSlot> exercises,
    @Default(<WorkoutTogetherMember>[]) List<WorkoutTogetherMember> members,
  }) = _WorkoutTogether;

  const WorkoutTogether._();

  bool get invitation => myStatus == TogetherMemberStatus.invited;
}

/// Un ejercicio del día, por su posición.
@freezed
abstract class WorkoutSlot with _$WorkoutSlot {
  const factory WorkoutSlot({
    required int index,
    required String exerciseId,
    @Default('') String name,
  }) = _WorkoutSlot;
}

/// Persona de un «Entrenamos juntos» con las posiciones que tiene hechas.
@freezed
abstract class WorkoutTogetherMember with _$WorkoutTogetherMember {
  const factory WorkoutTogetherMember({
    required TogetherPerson person,
    required TogetherMemberStatus status,
    required WorkoutMemberState state,
    @Default(<int>[]) List<int> doneSlots,

    /// Soy yo.
    @Default(false) bool me,
  }) = _WorkoutTogetherMember;
}

/// Pantalla «Con amigos»: invitaciones y lo que está en marcha.
@freezed
abstract class TogetherOverview with _$TogetherOverview {
  const factory TogetherOverview({
    @Default(<FriendChallenge>[]) List<FriendChallenge> challenges,
    @Default(<FriendStreak>[]) List<FriendStreak> streaks,
    @Default(<WorkoutTogether>[]) List<WorkoutTogether> workouts,
  }) = _TogetherOverview;

  const TogetherOverview._();

  bool get isEmpty => challenges.isEmpty && streaks.isEmpty && workouts.isEmpty;
}
