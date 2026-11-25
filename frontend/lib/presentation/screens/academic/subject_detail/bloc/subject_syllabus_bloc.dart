import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/study_document.dart';
import '../../../../../domain/models/academic/subject_file.dart';
import '../../../../../domain/models/academic/subject_material.dart';
import '../../../../../domain/use_cases/academic/delete_note_use_case.dart';
import '../../../../../domain/use_cases/academic/delete_subject_file_use_case.dart';
import '../../../../../domain/use_cases/academic/get_notes_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_document_availability_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_files_use_case.dart';
import '../../../../../domain/use_cases/academic/register_study_material_use_case.dart';
import '../../../../../domain/use_cases/academic/upload_subject_file_use_case.dart';

part 'subject_syllabus_bloc.freezed.dart';
part 'subject_syllabus_event.dart';
part 'subject_syllabus_state.dart';

/// Pestaña Apuntes: la lista «Material» (apuntes y archivos juntos, ADR 0064)
/// con sus documentos de IA guardados, subida de archivos y acceso al repaso o
/// la práctica. Apuntes, archivos y documentos llegan en tres peticiones a la
/// vez (antes, una más por elemento). Se refresca sola cuando otra pantalla
/// crea o cambia un apunte (ADR 0010).
class SubjectSyllabusBloc
    extends Bloc<SubjectSyllabusEvent, SubjectSyllabusState>
    with DataChangeRefreshMixin<SubjectSyllabusEvent, SubjectSyllabusState> {
  SubjectSyllabusBloc({
    required this._watchChanges,
    required this._getNotes,
    required this._getFiles,
    required this._getSubjectAvailability,
    required this._uploadFile,
    required this._deleteFile,
    required this._deleteNote,
    required this._registerMaterial,
  }) : super(const SubjectSyllabusState()) {
    on<SubjectSyllabusStarted>((event, emit) async {
      watchDataChanges(
        _watchChanges,
        topics: const {DataTopic.academic},
        onChanged: const SubjectSyllabusEvent.refreshed(),
      );
      emit(state.copyWith(subjectId: event.subjectId));
      await _load(emit, silent: false);
    });
    on<SubjectSyllabusRefreshed>((_, emit) => _load(emit, silent: true));
    on<SubjectSyllabusUploadRequested>(_onUpload);
    on<SubjectSyllabusFileDeleted>(_onFileDeleted);
    on<SubjectSyllabusNoteDeleted>(_onNoteDeleted);
    on<SubjectSyllabusMaterialRequested>(_onMaterialRequested);
  }

  final WatchDataChangesUseCaseContract _watchChanges;
  final GetNotesUseCaseContract _getNotes;
  final GetSubjectFilesUseCaseContract _getFiles;
  final GetSubjectDocumentAvailabilityUseCaseContract _getSubjectAvailability;
  final UploadSubjectFileUseCaseContract _uploadFile;
  final DeleteSubjectFileUseCaseContract _deleteFile;
  final DeleteNoteUseCaseContract _deleteNote;
  final RegisterStudyMaterialUseCaseContract _registerMaterial;

  Future<void> _load(
    Emitter<SubjectSyllabusState> emit, {
    required bool silent,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final (notes, files, availability) = await (
      _getNotes(subjectId: state.subjectId),
      _getFiles(state.subjectId),
      _getSubjectAvailability(state.subjectId),
    ).wait;
    final error = notes.errorOrNull ?? files.errorOrNull;
    if (error != null) {
      emit(state.copyWith(loading: false, error: error));
      return;
    }
    // Los documentos solo pintan iconos: si fallan, la lista sale igual.
    emit(
      state.copyWith(
        loading: false,
        error: null,
        notes: notes.valueOrNull!,
        files: files.valueOrNull!,
        availability: {
          for (final MapEntry(:key, :value)
              in (availability.valueOrNull ?? const {}).entries)
            if (value.any) key: value,
        },
      ),
    );
  }

  Future<void> _onUpload(
    SubjectSyllabusUploadRequested event,
    Emitter<SubjectSyllabusState> emit,
  ) async {
    emit(state.copyWith(uploadProgress: 0, actionError: null, message: null));
    final result = await _uploadFile(
      state.subjectId,
      event.payload,
      onProgress: (p) {
        if (!emit.isDone) emit(state.copyWith(uploadProgress: p));
      },
    );
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(uploadProgress: null, actionError: error));
      case null:
        emit(
          state.copyWith(
            uploadProgress: null,
            files: [result.valueOrNull!, ...state.files],
            message: SyllabusMessage.fileUploaded,
          ),
        );
    }
  }

  Future<void> _onFileDeleted(
    SubjectSyllabusFileDeleted event,
    Emitter<SubjectSyllabusState> emit,
  ) async {
    emit(state.copyWith(actionError: null, message: null));
    final result = await _deleteFile(event.fileId);
    emit(
      result.fold(
        (_) => state.copyWith(
          files: state.files.where((f) => f.id != event.fileId).toList(),
          message: SyllabusMessage.fileDeleted,
        ),
        (error) => state.copyWith(actionError: error),
      ),
    );
  }

  Future<void> _onNoteDeleted(
    SubjectSyllabusNoteDeleted event,
    Emitter<SubjectSyllabusState> emit,
  ) async {
    emit(state.copyWith(actionError: null, message: null));
    final result = await _deleteNote(event.noteId);
    emit(
      result.fold(
        (_) => state.copyWith(
          notes: state.notes.where((n) => n.id != event.noteId).toList(),
          message: SyllabusMessage.noteDeleted,
        ),
        (error) => state.copyWith(actionError: error),
      ),
    );
  }

  Future<void> _onMaterialRequested(
    SubjectSyllabusMaterialRequested event,
    Emitter<SubjectSyllabusState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null, navigation: null));
    final result = await _registerMaterial(event.sourceType, event.sourceId);
    emit(
      result.fold(
        (m) => state.copyWith(
          busy: false,
          navigation: (materialId: m.id, practice: event.practice),
        ),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }
}
