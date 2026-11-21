part of 'community_bloc.dart';

enum CommunityStatus { loading, ready, failure }

/// Tú › Comunidad: solicitudes recibidas, cuántos amigos, lo que está en
/// marcha con amigos y lo último del muro. Las dos últimas partes son
/// opcionales: nulas si no se pudieron leer (la pestaña sale igual).
@freezed
abstract class CommunityState with _$CommunityState {
  const factory CommunityState({
    @Default(CommunityStatus.loading) CommunityStatus status,
    AppError? error,

    /// Las primeras solicitudes recibidas (las que se contestan aquí).
    @Default(<Friendship>[]) List<Friendship> requests,

    /// Todas las recibidas, aunque solo se vean [requests].
    @Default(0) int requestsTotal,
    @Default(0) int friendsTotal,

    /// «Con amigos» (nulo si no se pudo leer).
    TogetherOverview? together,

    /// Lo último del muro (nulo si no se pudo leer).
    List<CommunityPostPreview>? posts,

    /// Solicitudes con una respuesta en camino (botones ocupados).
    @Default(<String>{}) Set<String> busyIds,

    /// Aviso de un solo uso (aceptada, rechazada o el error).
    SocialFeedback? feedback,
  }) = _CommunityState;

  const CommunityState._();

  /// «Con amigos ahora», en orden: primero lo que pide respuesta
  /// (invitaciones) y lo que pasa ya (salas y entrenos de hoy); después los
  /// retos sin terminar y las rachas activas. Solo ordena y filtra lo que
  /// manda el servidor: no calcula nada. Vacía si «Con amigos» no se leyó.
  List<TogetherNowItem> get togetherNow {
    final o = together;
    if (o == null) return const [];
    final invitations =
        o.challenges.where((c) => c.invitation).length +
        o.streaks.where((s) => s.invitation).length +
        o.workouts.where((w) => w.invitation).length +
        o.studyRooms.where((r) => r.invitation).length;
    return [
      if (invitations > 0) TogetherNowInvitations(invitations),
      for (final r in o.studyRooms)
        if (!r.invitation) TogetherNowStudyRoom(r),
      for (final w in o.workouts)
        if (!w.invitation) TogetherNowWorkout(w),
      for (final c in o.challenges)
        if (!c.invitation && !c.over) TogetherNowChallenge(c),
      for (final s in o.streaks)
        if (s.status == FriendStreakStatus.active) TogetherNowStreak(s),
    ];
  }
}

/// Una fila de «Con amigos ahora». Solo dice qué es; los textos, iconos y
/// destinos los pone la página.
sealed class TogetherNowItem {
  const TogetherNowItem();
}

/// Invitaciones de amigos sin contestar (retos, rachas, entrenos y salas).
final class TogetherNowInvitations extends TogetherNowItem {
  const TogetherNowInvitations(this.count);

  final int count;
}

final class TogetherNowStudyRoom extends TogetherNowItem {
  const TogetherNowStudyRoom(this.room);

  final StudyRoom room;
}

final class TogetherNowWorkout extends TogetherNowItem {
  const TogetherNowWorkout(this.workout);

  final WorkoutTogether workout;
}

final class TogetherNowChallenge extends TogetherNowItem {
  const TogetherNowChallenge(this.challenge);

  final FriendChallenge challenge;
}

final class TogetherNowStreak extends TogetherNowItem {
  const TogetherNowStreak(this.streak);

  final FriendStreak streak;
}
