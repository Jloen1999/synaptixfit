/// Enums de «Con amigos» (ADR 0044 y 0045). Los valores los decide el servidor; el
/// cliente solo elige el texto y el icono de cada uno.
library;

/// Situación de una persona en algo compartido: invitada, dentro, ha dicho que
/// no o ha salido.
enum TogetherMemberStatus {
  invited('INVITED'),
  joined('JOINED'),
  declined('DECLINED'),
  left('LEFT');

  const TogetherMemberStatus(this.apiValue);

  final String apiValue;

  static TogetherMemberStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => left);
}

/// Juntos (meta común, por defecto) o competición (con tope diario).
enum FriendChallengeMode {
  cooperative('COOPERATIVE'),
  competition('COMPETITION');

  const FriendChallengeMode(this.apiValue);

  final String apiValue;

  static FriendChallengeMode fromApi(String? value) =>
      values.firstWhere((m) => m.apiValue == value, orElse: () => cooperative);
}

/// Reacciones fijas del tablón de un reto con amigos (sin texto libre).
enum TogetherReaction {
  clap('CLAP'),
  fire('FIRE'),
  muscle('MUSCLE'),
  heart('HEART');

  const TogetherReaction(this.apiValue);

  final String apiValue;

  static TogetherReaction? fromApi(String? value) {
    for (final r in values) {
      if (r.apiValue == value) return r;
    }
    return null;
  }
}

/// Racha con un amigo propuesta o activa.
enum FriendStreakStatus {
  pending('PENDING'),
  active('ACTIVE');

  const FriendStreakStatus(this.apiValue);

  final String apiValue;

  static FriendStreakStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => pending);
}

/// Cómo va cada persona en «Entrenamos juntos».
enum WorkoutMemberState {
  notStarted('NOT_STARTED'),
  training('TRAINING'),
  finished('FINISHED');

  const WorkoutMemberState(this.apiValue);

  final String apiValue;

  static WorkoutMemberState fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => notStarted);
}

/// Dónde se denuncia a una persona.
enum UserReportContext {
  friendChallenge('FRIEND_CHALLENGE'),
  friendStreak('FRIEND_STREAK'),
  workoutTogether('WORKOUT_TOGETHER'),
  studyRoom('STUDY_ROOM'),
  profile('PROFILE');

  const UserReportContext(this.apiValue);

  final String apiValue;
}

/// En qué punto está una sala de «Estudiamos juntos» (ADR 0045). Lo calcula el
/// servidor desde la hora de inicio.
enum StudyRoomPhase {
  waiting('WAITING'),
  focus('FOCUS'),
  rest('BREAK'),
  finished('FINISHED'),
  expired('EXPIRED');

  const StudyRoomPhase(this.apiValue);

  final String apiValue;

  static StudyRoomPhase fromApi(String? value) =>
      values.firstWhere((p) => p.apiValue == value, orElse: () => expired);

  /// Terminada o caducada sin empezar: ya no se puede entrar ni reaccionar.
  bool get over => this == finished || this == expired;
}

/// Reacciones fijas de una sala (sin chat).
enum StudyRoomReaction {
  clap('CLAP'),
  fire('FIRE'),
  muscle('MUSCLE'),
  coffee('COFFEE');

  const StudyRoomReaction(this.apiValue);

  final String apiValue;

  static StudyRoomReaction? fromApi(String? value) {
    for (final r in values) {
      if (r.apiValue == value) return r;
    }
    return null;
  }
}

/// A qué se invita a amigos: decide el tope del selector, que manda el
/// servidor (`/together/limits`). [streak] elige a un solo amigo.
enum TogetherInviteKind { challenge, workout, studyRoom, streak }
