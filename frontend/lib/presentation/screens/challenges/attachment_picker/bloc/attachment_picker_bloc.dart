import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/challenges/challenge_references.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_attachments_use_case.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_subjects_use_case.dart';

part 'attachment_picker_bloc.freezed.dart';
part 'attachment_picker_event.dart';
part 'attachment_picker_state.dart';

/// Selector de un apunte o archivo para adjuntar a una tarea.
class AttachmentPickerBloc
    extends Bloc<AttachmentPickerEvent, AttachmentPickerState> {
  AttachmentPickerBloc({
    required this._listSubjects,
    required this._listAttachments,
  }) : super(const AttachmentPickerState()) {
    on<AttachmentPickerStarted>(_onStarted);
    on<AttachmentPickerSubjectChanged>(_onSubjectChanged);
  }

  final ListChallengeSubjectsUseCaseContract _listSubjects;
  final ListChallengeAttachmentsUseCaseContract _listAttachments;
  int _version = 0;

  Future<void> _onStarted(
    AttachmentPickerStarted event,
    Emitter<AttachmentPickerState> emit,
  ) async {
    emit(state.copyWith(status: AttachmentPickerStatus.loading, error: null));
    final subjects = await _listSubjects();
    final list = subjects.valueOrNull ?? const <ChallengeSubjectOption>[];
    final initial = event.subjectId ?? (list.isEmpty ? null : list.first.id);
    emit(state.copyWith(subjects: list, subjectId: initial));
    await _loadOptions(initial, emit);
  }

  Future<void> _onSubjectChanged(
    AttachmentPickerSubjectChanged event,
    Emitter<AttachmentPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        subjectId: event.subjectId,
        status: AttachmentPickerStatus.loading,
      ),
    );
    await _loadOptions(event.subjectId, emit);
  }

  Future<void> _loadOptions(
    String? subjectId,
    Emitter<AttachmentPickerState> emit,
  ) async {
    final version = ++_version;
    final result = await _listAttachments(subjectId);
    if (version != _version) return;
    emit(
      result.fold(
        (options) => state.copyWith(
          status: AttachmentPickerStatus.ready,
          options: options,
          error: null,
        ),
        (error) => state.copyWith(
          status: AttachmentPickerStatus.failure,
          error: error,
        ),
      ),
    );
  }
}
