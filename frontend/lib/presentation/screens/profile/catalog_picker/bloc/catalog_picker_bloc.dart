import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../../domain/use_cases/profile/search_degrees_use_case.dart';
import '../../../../../domain/use_cases/profile/search_universities_use_case.dart';

part 'catalog_picker_bloc.freezed.dart';
part 'catalog_picker_event.dart';
part 'catalog_picker_state.dart';

/// Selector de carrera del catálogo en dos pasos: universidad → carrera.
class CatalogPickerBloc extends Bloc<CatalogPickerEvent, CatalogPickerState> {
  CatalogPickerBloc({
    required this._searchUniversities,
    required this._searchDegrees,
  }) : super(const CatalogPickerState()) {
    on<CatalogPickerStarted>((_, emit) => _search(emit, ''));
    on<CatalogPickerQueryChanged>((e, emit) => _search(emit, e.query));
    on<CatalogPickerUniversitySelected>((e, emit) async {
      emit(state.copyWith(university: e.university));
      await _search(emit, '');
    });
    on<CatalogPickerUniversityCleared>((_, emit) async {
      emit(state.copyWith(university: null, degrees: const []));
      await _search(emit, '');
    });
  }

  final SearchUniversitiesUseCaseContract _searchUniversities;
  final SearchDegreesUseCaseContract _searchDegrees;

  Future<void> _search(Emitter<CatalogPickerState> emit, String query) async {
    emit(
      state.copyWith(
        query: query,
        status: CatalogPickerStatus.loading,
        error: null,
      ),
    );
    final university = state.university;
    final q = query.trim().isEmpty ? null : query.trim();
    if (university == null) {
      final result = await _searchUniversities(q);
      // Respuesta de una búsqueda ya superada: se descarta.
      if (state.query != query || state.university != null) return;
      emit(
        result.fold(
          (items) => state.copyWith(
            status: CatalogPickerStatus.ready,
            universities: items,
          ),
          (error) =>
              state.copyWith(status: CatalogPickerStatus.failure, error: error),
        ),
      );
    } else {
      final result = await _searchDegrees(university.id, q);
      if (state.query != query || state.university != university) return;
      emit(
        result.fold(
          (items) =>
              state.copyWith(status: CatalogPickerStatus.ready, degrees: items),
          (error) =>
              state.copyWith(status: CatalogPickerStatus.failure, error: error),
        ),
      );
    }
  }
}
