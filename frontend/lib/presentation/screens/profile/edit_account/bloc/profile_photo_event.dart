part of 'profile_photo_bloc.dart';

@freezed
sealed class ProfilePhotoEvent with _$ProfilePhotoEvent {
  /// Foto hecha o elegida: se enseña en la vista previa, aún sin subir.
  const factory ProfilePhotoEvent.picked(PickedPhoto photo) =
      ProfilePhotoPicked;

  /// «Cancelar» en la vista previa.
  const factory ProfilePhotoEvent.discarded() = ProfilePhotoDiscarded;

  /// «Usar esta foto».
  const factory ProfilePhotoEvent.uploadRequested() =
      ProfilePhotoUploadRequested;

  /// «Quitar foto» (ya confirmado).
  const factory ProfilePhotoEvent.removeRequested() =
      ProfilePhotoRemoveRequested;
}
