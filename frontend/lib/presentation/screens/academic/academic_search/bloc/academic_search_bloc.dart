import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/academic_search.dart';
import '../../../../../domain/use_cases/academic/search_academic_use_case.dart';

part 'academic_search_bloc.freezed.dart';
part 'academic_search_event.dart';
part 'academic_search_state.dart';

/// Buscador único de Académico (ADR 0036) con [SearchAcademicUseCaseContract].
/// La página ya espera a que se deje de teclear; aquí se descartan las
/// respuestas que llegan tarde (de un texto anterior) para no pintar
/// resultados que no corresponden a lo escrito.
class AcademicSearchBloc
    extends Bloc<AcademicSearchEvent, AcademicSearchState> {
  AcademicSearchBloc({required this._search})
    : super(const AcademicSearchState()) {
    on<AcademicSearchQueryChanged>(_onQuery);
    on<AcademicSearchRetried>((_, emit) => _run(state.query, emit));
  }

  final SearchAcademicUseCaseContract _search;

  /// Cada búsqueda lleva su número: solo vale la respuesta de la última.
  int _request = 0;

  Future<void> _onQuery(
    AcademicSearchQueryChanged event,
    Emitter<AcademicSearchState> emit,
  ) => _run(event.query.trim(), emit);

  Future<void> _run(String query, Emitter<AcademicSearchState> emit) async {
    if (query.length < SearchAcademicUseCaseContract.minLength) {
      _request++;
      emit(AcademicSearchState(query: query));
      return;
    }
    final request = ++_request;
    emit(
      state.copyWith(
        query: query,
        status: AcademicSearchStatus.loading,
        error: null,
      ),
    );
    final result = await _search(query);
    // Mientras tanto se buscó otra vez: esta respuesta ya no vale.
    if (request != _request) return;
    emit(
      result.fold(
        (found) =>
            state.copyWith(status: AcademicSearchStatus.ready, result: found),
        (error) =>
            state.copyWith(status: AcademicSearchStatus.failure, error: error),
      ),
    );
  }
}
