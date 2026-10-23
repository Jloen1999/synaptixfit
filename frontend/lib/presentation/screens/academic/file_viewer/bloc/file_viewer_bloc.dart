import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/study_document.dart';
import '../../../../../domain/models/academic/subject_file.dart';
import '../../../../../domain/use_cases/academic/delete_subject_file_use_case.dart';
import '../../../../../domain/use_cases/academic/get_document_availability_use_case.dart';
import '../../../../../domain/use_cases/academic/get_file_content_use_case.dart';
import '../../../../../domain/use_cases/academic/register_study_material_use_case.dart';

part 'file_viewer_bloc.freezed.dart';
part 'file_viewer_event.dart';
part 'file_viewer_state.dart';

/// Visor de un archivo con la URL firmada de descarga.
class FileViewerBloc extends Bloc<FileViewerEvent, FileViewerState> {
  FileViewerBloc({
    required this._getContent,
    required this._getAvailability,
    required this._deleteFile,
    required this._registerMaterial,
  }) : super(const FileViewerState()) {
    on<FileViewerStarted>(_onStarted);
    on<FileViewerDeleteRequested>(_onDelete);
    on<FileViewerMaterialRequested>(_onMaterial);
  }

  final GetFileContentUseCaseContract _getContent;
  final GetDocumentAvailabilityUseCaseContract _getAvailability;
  final DeleteSubjectFileUseCaseContract _deleteFile;
  final RegisterStudyMaterialUseCaseContract _registerMaterial;

  Future<void> _onStarted(
    FileViewerStarted event,
    Emitter<FileViewerState> emit,
  ) async {
    emit(state.copyWith(fileId: event.fileId, loading: true, error: null));
    final meta = await _getContent(event.fileId, withBytes: false);
    if (meta.errorOrNull case final AppError error) {
      emit(state.copyWith(loading: false, error: error));
      return;
    }
    var content = meta.valueOrNull!;
    // Los PDF se pintan en la app: hace falta el binario.
    if (content.file.isPdf && event.inlinePdf) {
      final full = await _getContent(event.fileId, withBytes: true);
      content = full.valueOrNull ?? content;
    }
    final availability = content.file.aiReadable
        ? (await _getAvailability(
            StudySourceType.file,
            event.fileId,
          )).valueOrNull
        : null;
    emit(
      state.copyWith(
        loading: false,
        content: content,
        availability: availability ?? DocumentAvailability.none,
      ),
    );
  }

  Future<void> _onDelete(
    FileViewerDeleteRequested event,
    Emitter<FileViewerState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null));
    final result = await _deleteFile(state.fileId);
    emit(
      result.fold(
        (_) => state.copyWith(busy: false, deleted: true),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }

  Future<void> _onMaterial(
    FileViewerMaterialRequested event,
    Emitter<FileViewerState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null, navigation: null));
    final result = await _registerMaterial(StudySourceType.file, state.fileId);
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
