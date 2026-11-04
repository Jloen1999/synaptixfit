import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note_scan.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/create_note_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subjects_use_case.dart';
import '../../../../../domain/use_cases/academic/read_note_photos_use_case.dart';

part 'note_scan_bloc.freezed.dart';
part 'note_scan_event.dart';
part 'note_scan_state.dart';

/// Fotografiar apuntes en papel: fotos → el servidor las lee (y la IA las
/// ordena) → la persona revisa el texto → se guarda como apunte privado.
class NoteScanBloc extends Bloc<NoteScanEvent, NoteScanState> {
  NoteScanBloc({
    required this._getSubjects,
    required this._readPhotos,
    required this._createNote,
  }) : super(const NoteScanState()) {
    on<NoteScanStarted>(_onStarted);
    on<NoteScanPhotosAdded>(_onPhotosAdded);
    on<NoteScanPhotoRemoved>(_onPhotoRemoved);
    on<NoteScanPhotoRestored>(_onPhotoRestored);
    on<NoteScanCameraUnavailable>(
      (event, emit) => emit(
        state.copyWith(
          cameraProblem: event.denied
              ? NoteScanCameraProblem.denied
              : NoteScanCameraProblem.missing,
        ),
      ),
    );
    on<NoteScanCameraRetried>(
      (_, emit) => emit(state.copyWith(cameraProblem: null)),
    );
    on<NoteScanReadRequested>(_onRead);
    on<NoteScanBackToPhotos>(
      (_, emit) => emit(state.copyWith(draft: null, readError: null)),
    );
    on<NoteScanSubjectChanged>(
      (event, emit) => emit(state.copyWith(subjectId: event.subjectId)),
    );
    on<NoteScanSaveRequested>(_onSave);
  }

  final GetSubjectsUseCaseContract _getSubjects;
  final ReadNotePhotosUseCaseContract _readPhotos;
  final CreateNoteUseCaseContract _createNote;

  /// Sin asignaturas el apunte se guarda igual (va a «Sin asignatura»): no
  /// cargarlas no impide nada, así que su fallo no se muestra.
  Future<void> _onStarted(
    NoteScanStarted event,
    Emitter<NoteScanState> emit,
  ) async {
    emit(state.copyWith(subjectId: event.subjectId));
    final result = await _getSubjects(archived: false);
    emit(state.copyWith(subjects: result.valueOrNull ?? const []));
  }

  void _onPhotosAdded(NoteScanPhotosAdded event, Emitter<NoteScanState> emit) {
    if (event.photos.isEmpty) return;
    final room = NoteScanState.maxPhotos - state.photos.length;
    if (room <= 0) return;
    emit(
      state.copyWith(
        photos: [...state.photos, ...event.photos.take(room)],
        readError: null,
        cameraProblem: null,
      ),
    );
  }

  void _onPhotoRemoved(
    NoteScanPhotoRemoved event,
    Emitter<NoteScanState> emit,
  ) {
    if (event.index < 0 || event.index >= state.photos.length) return;
    emit(
      state.copyWith(
        photos: [...state.photos]..removeAt(event.index),
        readError: null,
      ),
    );
  }

  void _onPhotoRestored(
    NoteScanPhotoRestored event,
    Emitter<NoteScanState> emit,
  ) {
    if (!state.canAddMore) return;
    final at = event.index.clamp(0, state.photos.length);
    emit(state.copyWith(photos: [...state.photos]..insert(at, event.photo)));
  }

  Future<void> _onRead(
    NoteScanReadRequested event,
    Emitter<NoteScanState> emit,
  ) async {
    if (state.photos.isEmpty || state.reading) return;
    emit(state.copyWith(reading: true, readError: null));
    final result = await _readPhotos(state.photos);
    emit(
      result.fold(
        (draft) => state.copyWith(reading: false, draft: draft),
        (error) => state.copyWith(reading: false, readError: error),
      ),
    );
  }

  /// Apunte privado y no rápido: viene de papel y la persona ya lo revisó.
  Future<void> _onSave(
    NoteScanSaveRequested event,
    Emitter<NoteScanState> emit,
  ) async {
    final title = event.title.trim();
    final text = event.markdown.trim();
    if (title.isEmpty || text.isEmpty || state.saving) return;
    emit(state.copyWith(saving: true, saveError: null));
    final result = await _createNote(
      subjectId: state.subjectId,
      title: title,
      content: text,
      visibility: Visibility.private,
      quickNote: false,
    );
    emit(
      result.fold(
        (note) => state.copyWith(saving: false, savedNoteId: note.id),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }
}
