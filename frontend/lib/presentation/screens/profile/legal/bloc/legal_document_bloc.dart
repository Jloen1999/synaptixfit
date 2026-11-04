import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/legal_document_kind.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/legal_document.dart';
import '../../../../../domain/use_cases/profile/get_legal_document_use_case.dart';

part 'legal_document_bloc.freezed.dart';
part 'legal_document_event.dart';
part 'legal_document_state.dart';

/// Carga un texto legal (privacidad, condiciones o borrado de cuenta) en el
/// idioma de la app. Se puede abrir sin sesión, desde el registro.
class LegalDocumentBloc extends Bloc<LegalDocumentEvent, LegalDocumentState> {
  LegalDocumentBloc({required this._getDocument})
    : super(const LegalDocumentState()) {
    on<LegalDocumentStarted>(_onStarted);
  }

  final GetLegalDocumentUseCaseContract _getDocument;

  Future<void> _onStarted(
    LegalDocumentStarted event,
    Emitter<LegalDocumentState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await _getDocument(event.kind, language: event.language);
    emit(
      result.fold(
        (document) => state.copyWith(loading: false, document: document),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }
}
