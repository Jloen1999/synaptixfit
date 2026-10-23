import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/artifact_kind.dart';
import '../../../../../domain/enums/question_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/study_artifact.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/models/academic/subject_file.dart';
import '../../../../../domain/use_cases/academic/generate_study_artifact_use_case.dart';
import '../../../../../domain/use_cases/academic/get_notes_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_files_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subjects_use_case.dart';
import '../../../../../domain/use_cases/academic/save_artifact_as_note_use_case.dart';
import '../../../../../domain/use_cases/academic/save_artifact_as_quiz_use_case.dart';

part 'generation_center_bloc.freezed.dart';
part 'generation_center_event.dart';
part 'generation_center_state.dart';

/// Centro de generación: varias fuentes de una asignatura → resumen, mapa
/// mental, flashcards o test (resultado efímero hasta que se guarda).
class GenerationCenterBloc
    extends Bloc<GenerationCenterEvent, GenerationCenterState> {
  GenerationCenterBloc({
    required this._getSubjects,
    required this._getNotes,
    required this._getFiles,
    required this._generate,
    required this._saveAsNote,
    required this._saveAsQuiz,
  }) : super(const GenerationCenterState()) {
    on<GenerationCenterStarted>(_onStarted);
    on<GenerationCenterSubjectSelected>(
      (event, emit) => _loadSources(emit, event.subjectId),
    );
    on<GenerationCenterSourceToggled>(_onSourceToggled);
    on<GenerationCenterKindSelected>(
      (event, emit) => emit(state.copyWith(kind: event.kind)),
    );
    on<GenerationCenterGenerateRequested>(_onGenerate);
    on<GenerationCenterDiscarded>(
      (_, emit) => emit(state.copyWith(artifact: null, generateError: null)),
    );
    on<GenerationCenterSaveRequested>(_onSave);
  }

  final GetSubjectsUseCaseContract _getSubjects;
  final GetNotesUseCaseContract _getNotes;
  final GetSubjectFilesUseCaseContract _getFiles;
  final GenerateStudyArtifactUseCaseContract _generate;
  final SaveArtifactAsNoteUseCaseContract _saveAsNote;
  final SaveArtifactAsQuizUseCaseContract _saveAsQuiz;

  /// Máximo de fuentes que admite la API.
  static const maxSources = 10;

  Future<void> _onStarted(
    GenerationCenterStarted event,
    Emitter<GenerationCenterState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final subjects = await _getSubjects(archived: false);
    switch (subjects.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(loading: false, error: error));
        return;
      case null:
        break;
    }
    final list = subjects.valueOrNull!;
    emit(state.copyWith(loading: false, subjects: list));
    final initial =
        list.where((s) => s.id == event.subjectId).firstOrNull?.id ??
        (list.length == 1 ? list.first.id : null);
    if (initial != null) await _loadSources(emit, initial);
  }

  Future<void> _loadSources(
    Emitter<GenerationCenterState> emit,
    String subjectId,
  ) async {
    emit(
      state.copyWith(
        subjectId: subjectId,
        loadingSources: true,
        sourcesError: null,
        selected: const {},
        notes: const [],
        files: const [],
        artifact: null,
      ),
    );
    final (notes, files) = await (
      _getNotes(subjectId: subjectId),
      _getFiles(subjectId),
    ).wait;
    final error = notes.errorOrNull ?? files.errorOrNull;
    emit(
      error != null
          ? state.copyWith(loadingSources: false, sourcesError: error)
          : state.copyWith(
              loadingSources: false,
              notes: notes.valueOrNull!,
              files: files.valueOrNull!.where((f) => f.aiReadable).toList(),
            ),
    );
  }

  void _onSourceToggled(
    GenerationCenterSourceToggled event,
    Emitter<GenerationCenterState> emit,
  ) {
    final selected = {...state.selected};
    if (!selected.remove(event.source)) {
      if (selected.length >= maxSources) return;
      selected.add(event.source);
    }
    emit(state.copyWith(selected: selected));
  }

  Future<void> _onGenerate(
    GenerationCenterGenerateRequested event,
    Emitter<GenerationCenterState> emit,
  ) async {
    if (state.selected.isEmpty) return;
    emit(state.copyWith(generating: true, generateError: null, artifact: null));
    final result = await _generate(state.kind, state.selected.toList());
    emit(
      result.fold(
        (a) => state.copyWith(generating: false, artifact: a),
        (error) => state.copyWith(generating: false, generateError: error),
      ),
    );
  }

  Future<void> _onSave(
    GenerationCenterSaveRequested event,
    Emitter<GenerationCenterState> emit,
  ) async {
    final artifact = state.artifact;
    final subjectId = state.subjectId;
    if (artifact == null || subjectId == null) return;
    emit(state.copyWith(saving: true, saveError: null));
    final title = event.title?.trim().isNotEmpty ?? false
        ? event.title!.trim()
        : artifact.title;
    if (artifact.kind == ArtifactKind.summary ||
        artifact.kind == ArtifactKind.mindMap) {
      final result = await _saveAsNote(
        subjectId: subjectId,
        title: title,
        markdown: artifact.markdown,
        mindMap: artifact.mindMap,
      );
      emit(
        result.fold(
          (note) => state.copyWith(saving: false, savedNoteId: note.id),
          (error) => state.copyWith(saving: false, saveError: error),
        ),
      );
      return;
    }
    final result = await _saveAsQuiz(
      subjectId: subjectId,
      title: title,
      questions: questionsToSave(artifact),
    );
    emit(
      result.fold(
        (quiz) =>
            state.copyWith(saving: false, savedMaterialId: quiz.materialId),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }

  /// Preguntas que se guardan: las del test o, para flashcards, cada tarjeta
  /// como pregunta de respuesta corta (así se repasan en la práctica).
  static List<QuestionDraft> questionsToSave(StudyArtifact artifact) =>
      artifact.questions.isNotEmpty
      ? artifact.questions
      : [
          for (final card in artifact.flashcards)
            QuestionDraft(
              type: QuestionType.fillInBlank,
              statement: card.question,
              correctAnswer: card.answer,
            ),
        ];
}
