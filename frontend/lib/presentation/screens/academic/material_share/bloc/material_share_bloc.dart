import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/material_sharing.dart';
import '../../../../../domain/models/academic/subject_material.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/academic/get_material_file_use_case.dart';
import '../../../../../domain/use_cases/academic/save_file_to_device_use_case.dart';
import '../../../../../domain/use_cases/academic/send_note_to_friend_use_case.dart';
import '../../../../../domain/use_cases/academic/share_file_outside_use_case.dart';
import '../../../../../domain/use_cases/academic/share_note_on_wall_use_case.dart';
import '../../../../../domain/use_cases/academic/share_note_with_everyone_use_case.dart';

part 'material_share_bloc.freezed.dart';
part 'material_share_event.dart';
part 'material_share_state.dart';

/// «Compartir» y «Descargar» un material (ADR 0064): con un amigo, para
/// todos, en el muro y fuera de la app (el PDF del apunte o el archivo
/// original), y guardarlo en el teléfono. Lo comparten la lista «Material» y
/// los visores; la página que lo monta pinta el aviso de [MaterialShareState.result].
/// Lo de dentro de la app solo existe para los apuntes.
class MaterialShareBloc extends Bloc<MaterialShareEvent, MaterialShareState> {
  MaterialShareBloc({
    required this._sendToFriend,
    required this._shareWithEveryone,
    required this._shareOnWall,
    required this._getFile,
    required this._shareOutside,
    required this._saveFile,
  }) : super(const MaterialShareState()) {
    on<MaterialShareFriendChosen>(
      (event, emit) => _forNote(
        emit,
        event,
        event.material,
        MaterialShareAction.friend,
        (noteId) async => (await _sendToFriend(noteId, event.friendId)).map(
          (sent) => MaterialShareResult(
            action: MaterialShareAction.friend,
            materialId: noteId,
            friendName: sent.friendName,
          ),
        ),
      ),
    );
    on<MaterialShareEveryoneRequested>(
      (event, emit) => _forNote(
        emit,
        event,
        event.material,
        MaterialShareAction.everyone,
        (noteId) async => (await _shareWithEveryone(noteId)).map(
          (note) => MaterialShareResult(
            action: MaterialShareAction.everyone,
            materialId: noteId,
            visibility: note.visibility,
          ),
        ),
      ),
    );
    on<MaterialShareWallRequested>(
      (event, emit) => _forNote(
        emit,
        event,
        event.material,
        MaterialShareAction.wall,
        (noteId) async => (await _shareOnWall(noteId)).map(
          (share) => MaterialShareResult(
            action: MaterialShareAction.wall,
            materialId: noteId,
            visibility: share.visibility,
            alreadyShared: share.alreadyShared,
          ),
        ),
      ),
    );
    on<MaterialShareOutsideRequested>(
      (event, emit) => _withFile(
        emit,
        event,
        event.material,
        MaterialShareAction.outside,
        _shareOutside.call,
      ),
    );
    on<MaterialShareDownloadRequested>(
      (event, emit) => _withFile(
        emit,
        event,
        event.material,
        MaterialShareAction.download,
        _saveFile.call,
      ),
    );
    // «Reintentar» del aviso de error: repite lo último con el mismo material.
    on<MaterialShareRetryRequested>((_, _) {
      final retry = state.retry;
      if (retry != null && state.running == null) add(retry);
    });
  }

  final SendNoteToFriendUseCaseContract _sendToFriend;
  final ShareNoteWithEveryoneUseCaseContract _shareWithEveryone;
  final ShareNoteOnWallUseCaseContract _shareOnWall;
  final GetMaterialFileUseCaseContract _getFile;
  final ShareFileOutsideUseCaseContract _shareOutside;
  final SaveFileToDeviceUseCaseContract _saveFile;

  Future<void> _forNote(
    Emitter<MaterialShareState> emit,
    MaterialShareEvent source,
    SubjectMaterial material,
    MaterialShareAction action,
    Future<AppResult<MaterialShareResult>> Function(String noteId) run,
  ) async {
    // Con un amigo, para todos y en el muro solo existen para los apuntes.
    if (material is! NoteMaterial || state.running != null) return;
    emit(state.copyWith(running: action, error: null));
    _finish(emit, source, await run(material.note.id));
  }

  /// Pide el archivo al servidor (PDF del apunte u original) y lo entrega al
  /// menú de compartir o al «Guardar como».
  Future<void> _withFile(
    Emitter<MaterialShareState> emit,
    MaterialShareEvent source,
    SubjectMaterial material,
    MaterialShareAction action,
    Future<AppResult<bool>> Function(MaterialFile file) deliver,
  ) async {
    if (state.running != null) return;
    emit(state.copyWith(running: action, error: null));
    final file = await _getFile(material);
    final AppResult<MaterialShareResult> result = switch (file) {
      Success(:final value) => (await deliver(value)).map(
        (done) => MaterialShareResult(
          action: action,
          materialId: material.id,
          fileName: value.fileName,
          completed: done,
        ),
      ),
      Failure(:final error) => Failure(error),
    };
    _finish(emit, source, result);
  }

  void _finish(
    Emitter<MaterialShareState> emit,
    MaterialShareEvent source,
    AppResult<MaterialShareResult> result,
  ) => emit(
    result.fold(
      (value) => state.copyWith(
        running: null,
        result: value,
        error: null,
        retry: null,
        seq: state.seq + 1,
      ),
      (error) => state.copyWith(
        running: null,
        error: error,
        retry: source,
        seq: state.seq + 1,
      ),
    ),
  );
}
