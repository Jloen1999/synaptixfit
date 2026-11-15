part of 'friend_picker_bloc.dart';

@freezed
sealed class FriendPickerEvent with _$FriendPickerEvent {
  const factory FriendPickerEvent.started({required int max}) =
      FriendPickerStarted;

  const factory FriendPickerEvent.toggled(String userId) = FriendPickerToggled;
}
