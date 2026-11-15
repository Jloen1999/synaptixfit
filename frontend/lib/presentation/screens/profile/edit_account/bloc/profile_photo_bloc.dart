import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/account/remove_avatar_use_case.dart';
import '../../../../../domain/use_cases/account/upload_avatar_use_case.dart';
import '../../../../../domain/models/account/picked_photo.dart';

part 'profile_photo_bloc.freezed.dart';
part 'profile_photo_event.dart';
part 'profile_photo_state.dart';

/// Foto de perfil en «Editar cuenta» (ADR 0052): la foto elegida se enseña
/// antes de subirla y solo se sube con «Usar esta foto»; «Quitar foto» la
/// borra. Cada cambio se guarda al momento (no espera a «Guardar») y la
/// página pasa la cuenta nueva a `SessionBloc`.
class ProfilePhotoBloc extends Bloc<ProfilePhotoEvent, ProfilePhotoState> {
  ProfilePhotoBloc({required this._upload, required this._remove})
    : super(const ProfilePhotoState()) {
    on<ProfilePhotoPicked>(
      (event, emit) => emit(state.copyWith(preview: event.photo, error: null)),
    );
    on<ProfilePhotoDiscarded>(
      (_, emit) => emit(state.copyWith(preview: null, error: null)),
    );
    on<ProfilePhotoUploadRequested>(_onUpload);
    on<ProfilePhotoRemoveRequested>(_onRemove);
  }

  final UploadAvatarUseCaseContract _upload;
  final RemoveAvatarUseCaseContract _remove;

  Future<void> _onUpload(
    ProfilePhotoUploadRequested event,
    Emitter<ProfilePhotoState> emit,
  ) async {
    final photo = state.preview;
    if (photo == null || state.saving) return;
    emit(state.copyWith(saving: true, error: null));
    final result = await _upload(
      bytes: photo.bytes,
      fileName: photo.fileName,
      mimeType: photo.mimeType,
    );
    emit(
      result.fold(
        (account) => state.copyWith(
          saving: false,
          preview: null,
          account: account,
          outcome: ProfilePhotoOutcome.changed,
        ),
        // La vista previa se queda: se puede reintentar o elegir otra.
        (error) => state.copyWith(saving: false, error: error),
      ),
    );
  }

  Future<void> _onRemove(
    ProfilePhotoRemoveRequested event,
    Emitter<ProfilePhotoState> emit,
  ) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, error: null, preview: null));
    final result = await _remove();
    emit(
      result.fold(
        (account) => state.copyWith(
          saving: false,
          account: account,
          outcome: ProfilePhotoOutcome.removed,
        ),
        (error) => state.copyWith(saving: false, error: error),
      ),
    );
  }
}
