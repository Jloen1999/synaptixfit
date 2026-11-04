part of 'register_bloc.dart';

@freezed
sealed class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.submitted({
    required String fullName,
    required String email,
    required String password,

    /// Idioma de la app: se lee la política en ese idioma para saber su versión.
    @Default('es') String language,
  }) = RegisterSubmitted;
}
