part of 'together_live_bloc.dart';

/// Un amigo acaba de empezar un entreno juntos en el que estoy: aviso
/// «Ana ha empezado a entrenar · Entrar» (efecto de un solo uso).
@freezed
abstract class TogetherLiveStart with _$TogetherLiveStart {
  const factory TogetherLiveStart({
    required String workoutId,
    required String sessionId,

    /// Nombre de quien empezó (vacío si borró su cuenta).
    @Default('') String name,
  }) = _TogetherLiveStart;
}

/// Qué abrir al entrar en la app: mi sesión del entreno juntos en marcha o la
/// sala de estudio en marcha.
@freezed
sealed class TogetherLiveOpen with _$TogetherLiveOpen {
  const factory TogetherLiveOpen.session(String sessionId) =
      TogetherLiveOpenSession;

  const factory TogetherLiveOpen.studyRoom(String roomId) =
      TogetherLiveOpenStudyRoom;
}

@freezed
abstract class TogetherLiveState with _$TogetherLiveState {
  const factory TogetherLiveState({
    /// El canal está abierto: las pantallas consultan más despacio.
    @Default(false) bool connected,

    /// Efecto de un solo uso.
    TogetherLiveStart? startedByFriend,

    /// Efecto de un solo uso, una vez por apertura de la app.
    TogetherLiveOpen? openOnLaunch,
  }) = _TogetherLiveState;
}
