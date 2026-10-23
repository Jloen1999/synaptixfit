import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/ai_document_type.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/study_document.dart';
import '../../../../../domain/use_cases/academic/generate_study_document_use_case.dart';
import '../../../../../domain/use_cases/academic/load_or_generate_study_document_use_case.dart';

part 'ai_document_bloc.freezed.dart';
part 'ai_document_event.dart';
part 'ai_document_state.dart';

/// Documento de IA de una fuente: lo carga si está guardado o lo genera.
class AiDocumentBloc extends Bloc<AiDocumentEvent, AiDocumentState> {
  AiDocumentBloc({required this._loadOrGenerate, required this._generate})
    : super(const AiDocumentState()) {
    on<AiDocumentStarted>(_onStarted);
    on<AiDocumentRegenerated>(_onRegenerated);
  }

  final LoadOrGenerateStudyDocumentUseCaseContract _loadOrGenerate;
  final GenerateStudyDocumentUseCaseContract _generate;

  Future<void> _onStarted(
    AiDocumentStarted event,
    Emitter<AiDocumentState> emit,
  ) async {
    emit(
      state.copyWith(
        sourceType: event.sourceType,
        sourceId: event.sourceId,
        type: event.type,
        loading: true,
        error: null,
      ),
    );
    final result = await _loadOrGenerate(
      event.sourceType,
      event.sourceId,
      event.type,
    );
    emit(
      result.fold(
        (doc) => state.copyWith(loading: false, document: doc),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onRegenerated(
    AiDocumentRegenerated event,
    Emitter<AiDocumentState> emit,
  ) async {
    emit(state.copyWith(regenerating: true, actionError: null));
    final result = await _generate(
      state.sourceType,
      state.sourceId,
      state.type,
    );
    emit(
      result.fold(
        (doc) => state.copyWith(regenerating: false, document: doc),
        (error) => state.copyWith(regenerating: false, actionError: error),
      ),
    );
  }
}
