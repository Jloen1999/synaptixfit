part of 'link_picker_bloc.dart';

enum LinkPickerStatus { loading, ready, failure }

@freezed
abstract class LinkPickerState with _$LinkPickerState {
  const factory LinkPickerState({
    @Default(LinkPickerStatus.loading) LinkPickerStatus status,
    @Default(<ChallengeLinkOption>[]) List<ChallengeLinkOption> options,
    AppError? error,
  }) = _LinkPickerState;
}
