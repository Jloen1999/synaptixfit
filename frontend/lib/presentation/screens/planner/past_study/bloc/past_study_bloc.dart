import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/planner_options.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/get_planner_subjects_use_case.dart';
import '../../../../../domain/use_cases/planner/log_past_study_use_case.dart';

part 'past_study_bloc.freezed.dart';
part 'past_study_event.dart';
part 'past_study_state.dart';

/// «Apuntar estudio hecho»: guarda un rato de estudio ya terminado (de los
/// últimos 7 días) como bloque hecho. Las reglas (plazo, XP, carga cognitiva)
/// las decide el servidor; aquí solo se cargan las asignaturas y se envía.
class PastStudyBloc extends Bloc<PastStudyEvent, PastStudyState> {
  PastStudyBloc({
    required this._logPastStudy,
    required this._getSubjects,
    required this._getAccount,
  }) : super(const PastStudyState()) {
    on<PastStudyStarted>(_onStarted);
    on<PastStudySubmitted>(_onSubmitted);
  }

  final LogPastStudyUseCaseContract _logPastStudy;
  final GetPlannerSubjectsUseCaseContract _getSubjects;
  final GetAccountUseCaseContract _getAccount;

  /// Sin asignaturas (o si fallan) se apunta igual, sin asignatura.
  Future<void> _onStarted(
    PastStudyStarted event,
    Emitter<PastStudyState> emit,
  ) async {
    emit(state.copyWith(loadingSubjects: true, subjectsFailed: false));
    final subjects = (await _getSubjects()).valueOrNull;
    emit(
      state.copyWith(
        loadingSubjects: false,
        subjects: subjects ?? const <SubjectOption>[],
        subjectsFailed: subjects == null,
      ),
    );
  }

  Future<void> _onSubmitted(
    PastStudySubmitted event,
    Emitter<PastStudyState> emit,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, error: null));
    final result = await _logPastStudy(
      start: event.start,
      minutes: event.minutes,
      subjectId: event.subjectId,
      title: event.title,
    );
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(submitting: false, error: error));
        return;
      case null:
        break;
    }
    final xp = result.valueOrNull?.xpDelta ?? 0;
    // Con XP, el nivel de la cuenta cambia: se refresca para la cabecera.
    final account = xp > 0 ? (await _getAccount()).valueOrNull : null;
    emit(
      state.copyWith(submitting: false, savedXp: xp, updatedAccount: account),
    );
  }
}
