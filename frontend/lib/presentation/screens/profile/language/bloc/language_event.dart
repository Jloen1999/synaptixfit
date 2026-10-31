part of 'language_bloc.dart';

@freezed
sealed class LanguageEvent with _$LanguageEvent {
  /// Lee el idioma guardado en el dispositivo.
  const factory LanguageEvent.started() = LanguageStarted;

  const factory LanguageEvent.changed(AppLanguage language) = LanguageChanged;
}
