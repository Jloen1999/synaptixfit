import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/question_standing.dart';
import '../../../../../domain/enums/question_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/academic/subject_questions.dart';
import '../../../../../domain/use_cases/academic/answer_question_use_case.dart';
import '../../../../../domain/use_cases/academic/dont_know_question_use_case.dart';
import '../../../../../domain/use_cases/academic/get_due_study_materials_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_questions_use_case.dart';

part 'subject_practice_bloc.freezed.dart';
part 'subject_practice_event.dart';
part 'subject_practice_state.dart';

/// «Practicar» de una asignatura (ADR 0063): todas sus preguntas en el orden
/// en que vuelven (lo da el servidor), los repasos de hoy y la lista filtrada
/// por cómo van, tipo y tema. Contestar una pregunta suelta (o «No lo sé») usa
/// los mismos casos de uso que la práctica libre.
class SubjectPracticeBloc
    extends Bloc<SubjectPracticeEvent, SubjectPracticeState> {
  SubjectPracticeBloc({
    required this._getQuestions,
    required this._getDue,
    required this._answer,
    required this._dontKnow,
  }) : super(const SubjectPracticeState()) {
    on<SubjectPracticeStarted>((event, emit) async {
      emit(state.copyWith(subjectId: event.subjectId));
      await _load(emit, silent: false);
    });
    on<SubjectPracticeRefreshed>((_, emit) => _load(emit, silent: true));
    on<SubjectPracticeQueryChanged>(
      (event, emit) => emit(state.copyWith(query: event.query)),
    );
    on<SubjectPracticeStandingChanged>(
      (event, emit) => emit(state.copyWith(standing: event.filter)),
    );
    on<SubjectPracticeTypeChanged>(
      (event, emit) => emit(state.copyWith(type: event.type)),
    );
    on<SubjectPracticeMaterialChanged>(
      (event, emit) => emit(state.copyWith(materialId: event.materialId)),
    );
    on<SubjectPracticeFiltersCleared>(
      (_, emit) => emit(
        state.copyWith(
          query: '',
          standing: PracticeListFilter.all,
          type: null,
          materialId: null,
        ),
      ),
    );
    on<SubjectPracticeAnswered>(_onAnswered);
    on<SubjectPracticeDontKnow>(_onDontKnow);
  }

  final GetSubjectQuestionsUseCaseContract _getQuestions;
  final GetDueStudyMaterialsUseCaseContract _getDue;
  final AnswerQuestionUseCaseContract _answer;
  final DontKnowQuestionUseCaseContract _dontKnow;

  /// El servidor no da más repasos vencidos de una vez; se filtran por
  /// asignatura aquí (qué vence lo decide él), como en el Resumen.
  static const _dueLimit = 100;

  Future<void> _load(
    Emitter<SubjectPracticeState> emit, {
    required bool silent,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final id = state.subjectId;
    final (questions, due) = await (
      _getQuestions(id),
      _getDue(limit: _dueLimit),
    ).wait;
    // Las preguntas son la pieza principal; los repasos se degradan.
    emit(
      questions.fold(
        (q) => state.copyWith(
          loading: false,
          error: null,
          questions: q,
          // Al volver a leer, lo contestado ya viene en el estado de cada una.
          results: const {},
          answers: const {},
          due: switch (due.valueOrNull) {
            final list? => [
              for (final m in list)
                if (m.subjectId == id) m,
            ],
            null => state.due,
          },
        ),
        (error) => silent
            ? state.copyWith(loading: false, actionError: error)
            : state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onAnswered(
    SubjectPracticeAnswered event,
    Emitter<SubjectPracticeState> emit,
  ) async {
    final answer = event.answer.trim();
    if (answer.isEmpty || state.results.containsKey(event.questionId)) return;
    emit(state.copyWith(checkingId: event.questionId, actionError: null));
    final result = await _answer(event.questionId, answer);
    _emitResult(
      emit,
      event.questionId,
      result.valueOrNull,
      result.errorOrNull,
      answer: answer,
    );
  }

  Future<void> _onDontKnow(
    SubjectPracticeDontKnow event,
    Emitter<SubjectPracticeState> emit,
  ) async {
    if (state.results.containsKey(event.questionId)) return;
    emit(state.copyWith(checkingId: event.questionId, actionError: null));
    final result = await _dontKnow(event.questionId);
    _emitResult(emit, event.questionId, result.valueOrNull, result.errorOrNull);
  }

  /// Guarda la corrección y lo contestado ([answer], nulo con «No lo sé»)
  /// para pintar la pregunta bloqueada.
  void _emitResult(
    Emitter<SubjectPracticeState> emit,
    String questionId,
    AnswerResult? result,
    AppError? error, {
    String? answer,
  }) {
    emit(
      result != null
          ? state.copyWith(
              checkingId: null,
              results: {...state.results, questionId: result},
              answers: {...state.answers, questionId: ?answer},
            )
          : state.copyWith(checkingId: null, actionError: error),
    );
  }
}
