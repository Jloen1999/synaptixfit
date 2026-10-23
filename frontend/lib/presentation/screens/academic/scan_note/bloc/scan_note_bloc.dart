import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/create_note_from_scan_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subjects_use_case.dart';

part 'scan_note_bloc.freezed.dart';
part 'scan_note_event.dart';
part 'scan_note_state.dart';

/// Guarda texto escaneado o pegado como apunte.
class ScanNoteBloc extends Bloc<ScanNoteEvent, ScanNoteState> {
  ScanNoteBloc({required this._getSubjects, required this._createFromScan})
    : super(const ScanNoteState()) {
    on<ScanNoteStarted>(_onStarted);
    on<ScanNoteSubmitted>(_onSubmitted);
  }

  final GetSubjectsUseCaseContract _getSubjects;
  final CreateNoteFromScanUseCaseContract _createFromScan;

  Future<void> _onStarted(
    ScanNoteStarted event,
    Emitter<ScanNoteState> emit,
  ) async {
    emit(state.copyWith(initialSubjectId: event.subjectId));
    final result = await _getSubjects(archived: false);
    emit(
      state.copyWith(loading: false, subjects: result.valueOrNull ?? const []),
    );
  }

  Future<void> _onSubmitted(
    ScanNoteSubmitted event,
    Emitter<ScanNoteState> emit,
  ) async {
    emit(state.copyWith(saving: true, saveError: null));
    final result = await _createFromScan(
      title: event.title,
      text: event.text,
      subjectId: event.subjectId,
    );
    emit(
      result.fold(
        (n) => state.copyWith(saving: false, savedNoteId: n.id),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }
}
