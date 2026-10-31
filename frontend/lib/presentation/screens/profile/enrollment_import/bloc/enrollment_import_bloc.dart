import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/subject_file.dart';
import '../../../../../domain/models/profile/enrollment_proposal.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/profile/apply_enrollment_use_case.dart';
import '../../../../../domain/use_cases/profile/read_enrollment_use_case.dart';

part 'enrollment_import_bloc.freezed.dart';
part 'enrollment_import_event.dart';
part 'enrollment_import_state.dart';

/// Importar la matrícula: permiso → leer el PDF → revisar lo reconocido →
/// añadir lo elegido. Sin el permiso marcado no se envía nada.
class EnrollmentImportBloc
    extends Bloc<EnrollmentImportEvent, EnrollmentImportState> {
  EnrollmentImportBloc({required this._read, required this._apply})
    : super(const EnrollmentImportState()) {
    on<EnrollmentImportConsentChanged>(
      (e, emit) => emit(state.copyWith(consent: e.value)),
    );
    on<EnrollmentImportFileChosen>(_onFile);
    on<EnrollmentImportSubjectToggled>(_onToggled);
    on<EnrollmentImportAllToggled>(_onAllToggled);
    on<EnrollmentImportApplyRequested>(_onApply);
    on<EnrollmentImportRestarted>(
      (_, emit) => emit(EnrollmentImportState(consent: state.consent)),
    );
  }

  final ReadEnrollmentUseCaseContract _read;
  final ApplyEnrollmentUseCaseContract _apply;

  Future<void> _onFile(
    EnrollmentImportFileChosen event,
    Emitter<EnrollmentImportState> emit,
  ) async {
    if (!state.consent || state.step == EnrollmentStep.reading) return;
    emit(state.copyWith(step: EnrollmentStep.reading, error: null));
    final result = await _read(event.file, consent: true);
    switch (result) {
      case Success(value: final proposal):
        emit(
          state.copyWith(
            step: EnrollmentStep.review,
            proposal: proposal,
            // De entrada, todo lo que aún no tiene.
            selected: selectableOf(proposal),
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(step: EnrollmentStep.intro, error: error));
    }
  }

  void _onToggled(
    EnrollmentImportSubjectToggled event,
    Emitter<EnrollmentImportState> emit,
  ) {
    final selected = {...state.selected};
    if (!selected.remove(event.index)) selected.add(event.index);
    emit(state.copyWith(selected: selected));
  }

  void _onAllToggled(
    EnrollmentImportAllToggled event,
    Emitter<EnrollmentImportState> emit,
  ) {
    final proposal = state.proposal;
    if (proposal == null) return;
    final pending = selectableOf(proposal);
    emit(
      state.copyWith(
        selected: state.selected.containsAll(pending) ? {} : pending,
      ),
    );
  }

  /// Posiciones de las asignaturas que se pueden añadir (las que aún no tiene).
  static Set<int> selectableOf(EnrollmentProposal proposal) => {
    for (final (i, s) in proposal.subjects.indexed)
      if (!s.alreadyAdded) i,
  };

  Future<void> _onApply(
    EnrollmentImportApplyRequested event,
    Emitter<EnrollmentImportState> emit,
  ) async {
    final proposal = state.proposal;
    if (proposal == null || state.step == EnrollmentStep.applying) return;
    emit(state.copyWith(step: EnrollmentStep.applying, error: null));
    final chosen = [
      for (final (i, s) in proposal.subjects.indexed)
        if (state.selected.contains(i)) s,
    ];
    final result = await _apply(proposal, chosen);
    switch (result) {
      case Success(value: final applied):
        emit(state.copyWith(step: EnrollmentStep.done, result: applied));
      case Failure(:final error):
        emit(state.copyWith(step: EnrollmentStep.review, error: error));
    }
  }
}
