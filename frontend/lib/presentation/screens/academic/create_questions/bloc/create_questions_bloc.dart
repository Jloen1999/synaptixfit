import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/question_creation_enums.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/question_creation.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/use_cases/academic/generate_question_bank_use_case.dart';
import '../../../../../domain/use_cases/academic/get_notes_use_case.dart';
import '../../../../../domain/use_cases/academic/get_question_bank_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subject_files_use_case.dart';
import '../../../../../domain/use_cases/academic/register_study_material_use_case.dart';
import '../../../../../domain/use_cases/academic/scan_document_questions_use_case.dart';

part 'create_questions_bloc.freezed.dart';
part 'create_questions_event.dart';
part 'create_questions_state.dart';

/// «Crear preguntas» (ADR 0058): elige el apunte (desde la asignatura), mira
/// si el documento ya trae preguntas, recoge tipo, cuántas y qué hacer con
/// las que ya tienes, lleva la revisión de las del documento y guarda. Las
/// tandas, los repetidos y la corrección los decide el servidor.
class CreateQuestionsBloc
    extends Bloc<CreateQuestionsEvent, CreateQuestionsState> {
  CreateQuestionsBloc({
    required this._getNotes,
    required this._getFiles,
    required this._registerMaterial,
    required this._getBank,
    required this._scan,
    required this._generate,
  }) : super(const CreateQuestionsState()) {
    on<CreateQuestionsStarted>(_onStarted);
    on<CreateQuestionsSourcePickRequested>(
      (_, emit) => emit(state.copyWith(choosingSource: true)),
    );
    on<CreateQuestionsSourceChosen>(
      (event, emit) => _choose(event.source, emit),
    );
    on<CreateQuestionsRetried>(_onRetried);
    on<CreateQuestionsScanRetried>((_, emit) => _scanDocument(emit));
    on<CreateQuestionsFormatChosen>(
      (event, emit) => emit(state.copyWith(format: event.format)),
    );
    on<CreateQuestionsCountChanged>(
      (event, emit) => emit(
        state.copyWith(
          count: event.count.clamp(QuestionCount.min, QuestionCount.max),
        ),
      ),
    );
    on<CreateQuestionsDocumentUseChosen>(
      (event, emit) => emit(state.copyWith(documentUse: event.use)),
    );
    on<CreateQuestionsModeChosen>(
      (event, emit) => emit(state.copyWith(mode: event.mode)),
    );
    on<CreateQuestionsSubmitted>(_onSubmitted);
    on<CreateQuestionsReviewToggled>(_onToggled);
    on<CreateQuestionsAnswerChanged>(_onAnswerChanged);
    on<CreateQuestionsSaveRequested>((_, emit) => _save(emit));
  }

  final GetNotesUseCaseContract _getNotes;
  final GetSubjectFilesUseCaseContract _getFiles;
  final RegisterStudyMaterialUseCaseContract _registerMaterial;
  final GetQuestionBankUseCaseContract _getBank;
  final ScanDocumentQuestionsUseCaseContract _scan;
  final GenerateQuestionBankUseCaseContract _generate;

  /// Apunte o archivo elegido (para reintentar si falla al registrarlo).
  QuestionSourceOption? _chosen;

  Future<void> _onStarted(
    CreateQuestionsStarted event,
    Emitter<CreateQuestionsState> emit,
  ) async {
    emit(state.copyWith(subjectId: event.subjectId));
    if (event.materialId != null) {
      emit(state.copyWith(materialId: event.materialId, title: event.title));
      await _prepare(emit);
    } else if (event.subjectId != null) {
      await _loadSources(emit);
    }
  }

  Future<void> _onRetried(
    CreateQuestionsRetried event,
    Emitter<CreateQuestionsState> emit,
  ) async {
    if (state.sourcesError != null) return _loadSources(emit);
    final chosen = _chosen;
    if (state.materialId == null && chosen != null) {
      return _choose(chosen, emit);
    }
    return _prepare(emit);
  }

  Future<void> _loadSources(Emitter<CreateQuestionsState> emit) async {
    final subjectId = state.subjectId!;
    emit(state.copyWith(loadingSources: true, sourcesError: null));
    final (notes, files) = await (
      _getNotes(subjectId: subjectId),
      _getFiles(subjectId),
    ).wait;
    final error = notes.errorOrNull ?? files.errorOrNull;
    if (error != null) {
      emit(state.copyWith(loadingSources: false, sourcesError: error));
      return;
    }
    // Solo los archivos que la IA puede leer (PDF con texto o imagen).
    final sources = [
      for (final n in notes.valueOrNull!)
        QuestionSourceOption(
          type: StudySourceType.note,
          id: n.id,
          title: n.title,
        ),
      for (final f in files.valueOrNull!)
        if (f.aiReadable)
          QuestionSourceOption(
            type: StudySourceType.file,
            id: f.id,
            title: f.fileName,
          ),
    ];
    emit(
      state.copyWith(
        loadingSources: false,
        sources: sources,
        choosingSource: sources.length != 1,
      ),
    );
    if (sources.length == 1) await _choose(sources.single, emit);
  }

  Future<void> _choose(
    QuestionSourceOption source,
    Emitter<CreateQuestionsState> emit,
  ) async {
    _chosen = source;
    emit(
      state.copyWith(
        choosingSource: false,
        materialId: null,
        title: source.title,
        preparing: true,
        prepareError: null,
        scan: null,
        scanError: null,
        existingCount: 0,
      ),
    );
    final result = await _registerMaterial(source.type, source.id);
    if (_chosen != source) return;
    switch (result.errorOrNull) {
      case final error?:
        emit(state.copyWith(preparing: false, prepareError: error));
      case null:
        emit(state.copyWith(materialId: result.valueOrNull!.id));
        await _prepare(emit);
    }
  }

  /// Cuántas preguntas tiene ya y, después, si el documento trae preguntas
  /// (la IA tarda: la hoja ya se puede usar mientras tanto).
  Future<void> _prepare(Emitter<CreateQuestionsState> emit) async {
    final materialId = state.materialId!;
    emit(state.copyWith(preparing: true, prepareError: null));
    final bank = await _getBank(materialId);
    if (state.materialId != materialId) return;
    switch (bank.errorOrNull) {
      case final error?:
        emit(state.copyWith(preparing: false, prepareError: error));
        return;
      case null:
        emit(
          state.copyWith(
            preparing: false,
            existingCount: bank.valueOrNull?.questions.length ?? 0,
          ),
        );
    }
    await _scanDocument(emit);
  }

  Future<void> _scanDocument(Emitter<CreateQuestionsState> emit) async {
    final materialId = state.materialId;
    if (materialId == null) return;
    emit(state.copyWith(scanning: true, scanError: null));
    final result = await _scan(materialId);
    if (state.materialId != materialId) return;
    emit(
      result.fold(
        (scan) => state.copyWith(scanning: false, scan: scan),
        (error) => state.copyWith(scanning: false, scanError: error),
      ),
    );
  }

  Future<void> _onSubmitted(
    CreateQuestionsSubmitted event,
    Emitter<CreateQuestionsState> emit,
  ) async {
    if (!state.ready || state.saving) return;
    if (!state.usesDocument) return _save(emit);
    // Se marcan todas las que se pueden usar; al mezclar, como mucho las que
    // se pidieron (el resto se puede marcar a mano).
    final questions = state.documentQuestions;
    final limit = state.documentUse == DocumentQuestionUse.mix
        ? state.count
        : questions.length;
    final used = <int>{};
    for (var i = 0; i < questions.length && used.length < limit; i++) {
      if (questions[i].usable) used.add(i);
    }
    emit(
      state.copyWith(
        reviewed: questions,
        used: used,
        saveError: null,
        reviewRequest: state.reviewRequest + 1,
      ),
    );
  }

  void _onToggled(
    CreateQuestionsReviewToggled event,
    Emitter<CreateQuestionsState> emit,
  ) {
    final i = event.index;
    if (i < 0 || i >= state.reviewed.length || !state.reviewed[i].usable) {
      return;
    }
    final used = {...state.used};
    if (!used.remove(i)) used.add(i);
    emit(state.copyWith(used: used));
  }

  void _onAnswerChanged(
    CreateQuestionsAnswerChanged event,
    Emitter<CreateQuestionsState> emit,
  ) {
    final i = event.index;
    final answers = [
      for (final a in event.answers)
        if (a.trim().isNotEmpty) a.trim(),
    ];
    if (i < 0 || i >= state.reviewed.length || answers.isEmpty) return;
    final reviewed = [...state.reviewed];
    reviewed[i] = reviewed[i].copyWith(correctAnswers: answers);
    emit(state.copyWith(reviewed: reviewed));
  }

  Future<void> _save(Emitter<CreateQuestionsState> emit) async {
    final materialId = state.materialId;
    if (materialId == null || state.saving || state.totalToSave == 0) return;
    final fromDocument = state.usesDocument
        ? [
            for (var i = 0; i < state.reviewed.length; i++)
              if (state.used.contains(i)) state.reviewed[i],
          ]
        : const <DocumentQuestion>[];
    emit(state.copyWith(saving: true, saveError: null));
    final result = await _generate(
      materialId,
      CreateQuestionsRequest(
        format: state.format,
        newQuestions: state.newCount,
        mode: state.effectiveMode,
        documentQuestions: fromDocument,
      ),
    );
    emit(
      result.fold(
        (bank) => state.copyWith(saving: false, saved: bank),
        (error) => state.copyWith(saving: false, saveError: error),
      ),
    );
  }
}
