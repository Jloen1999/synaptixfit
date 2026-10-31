part of 'appearance_bloc.dart';

@freezed
abstract class AppearanceState with _$AppearanceState {
  const factory AppearanceState({
    @Default(AppearanceMode.dark) AppearanceMode mode,
  }) = _AppearanceState;
}
