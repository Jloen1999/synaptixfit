part of 'friend_picker_bloc.dart';

enum FriendPickerStatus { loading, ready, failure }

@freezed
abstract class FriendPickerState with _$FriendPickerState {
  const factory FriendPickerState({
    @Default(FriendPickerStatus.loading) FriendPickerStatus status,
    @Default(<SocialUser>[]) List<SocialUser> friends,
    @Default(<String>[]) List<String> selected,
    @Default(TogetherInviteKind.streak) TogetherInviteKind kind,

    /// Topes del servidor (nulos al elegir para una racha).
    TogetherLimits? limits,
    @Default(1) int max,
    AppError? error,
  }) = _FriendPickerState;

  const FriendPickerState._();

  bool get full => selected.length >= max;
}
