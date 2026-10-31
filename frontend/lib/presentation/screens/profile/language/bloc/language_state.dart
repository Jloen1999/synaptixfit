part of 'language_bloc.dart';

@freezed
abstract class LanguageState with _$LanguageState {
  const factory LanguageState({
    @Default(AppLanguage.system) AppLanguage language,
  }) = _LanguageState;
}
