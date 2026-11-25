part of 'material_share_bloc.dart';

@freezed
sealed class MaterialShareEvent with _$MaterialShareEvent {
  /// «Con un amigo»: el amigo elegido en la hoja de amigos.
  const factory MaterialShareEvent.friendChosen({
    required SubjectMaterial material,
    required String friendId,
  }) = MaterialShareFriendChosen;

  /// «Para todos»: a «Apuntes compartidos».
  const factory MaterialShareEvent.everyoneRequested(
    SubjectMaterial material,
  ) = MaterialShareEveryoneRequested;

  /// «En el muro».
  const factory MaterialShareEvent.wallRequested(SubjectMaterial material) =
      MaterialShareWallRequested;

  /// «Fuera de la app»: menú del sistema con el PDF o el original.
  const factory MaterialShareEvent.outsideRequested(SubjectMaterial material) =
      MaterialShareOutsideRequested;

  /// «Descargar»: el PDF o el original en el teléfono.
  const factory MaterialShareEvent.downloadRequested(
    SubjectMaterial material,
  ) = MaterialShareDownloadRequested;

  /// «Reintentar» tras un error: repite la última acción con el mismo material.
  const factory MaterialShareEvent.retryRequested() =
      MaterialShareRetryRequested;
}
