part of 'profile_photo_bloc.dart';

/// Qué se acaba de guardar, para el aviso.
enum ProfilePhotoOutcome { changed, removed }

@freezed
abstract class ProfilePhotoState with _$ProfilePhotoState {
  const factory ProfilePhotoState({
    /// Foto elegida pendiente de «Usar esta foto».
    PickedPhoto? preview,
    @Default(false) bool saving,
    AppError? error,

    /// Cuenta tras el último cambio guardado: la página la pasa a la sesión.
    Account? account,
    ProfilePhotoOutcome? outcome,
  }) = _ProfilePhotoState;
}
