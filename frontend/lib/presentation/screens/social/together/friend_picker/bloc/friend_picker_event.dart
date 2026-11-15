part of 'friend_picker_bloc.dart';

@freezed
sealed class FriendPickerEvent with _$FriendPickerEvent {
  /// Empieza a elegir amigos para [kind] (decide el tope).
  const factory FriendPickerEvent.started({required TogetherInviteKind kind}) =
      FriendPickerStarted;

  const factory FriendPickerEvent.toggled(String userId) = FriendPickerToggled;
}
