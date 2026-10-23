import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../../domain/use_cases/profile/add_subjects_from_catalog_use_case.dart';
import '../../../../../domain/use_cases/profile/get_my_catalog_subjects_use_case.dart';

part 'subject_selector_bloc.freezed.dart';
part 'subject_selector_event.dart';
part 'subject_selector_state.dart';

/// Selector de asignaturas del plan de estudios de las carreras vinculadas.
class SubjectSelectorBloc
    extends Bloc<SubjectSelectorEvent, SubjectSelectorState> {
  SubjectSelectorBloc({required this._getSubjects, required this._addSubjects})
    : super(const SubjectSelectorState()) {
    on<SubjectSelectorStarted>((_, emit) => _reload(emit));
    on<SubjectSelectorCourseChanged>((e, emit) async {
      emit(state.copyWith(course: e.course));
      await _reload(emit);
    });
    on<SubjectSelectorSemesterChanged>((e, emit) async {
      emit(state.copyWith(semester: e.semester));
      await _reload(emit);
    });
    on<SubjectSelectorQueryChanged>((e, emit) async {
      emit(state.copyWith(query: e.query));
      await _reload(emit);
    });
    on<SubjectSelectorMoreRequested>(_onMore);
    on<SubjectSelectorToggled>(_onToggled);
    on<SubjectSelectorSubmitted>(_onSubmitted);
  }

  final GetMyCatalogSubjectsUseCaseContract _getSubjects;
  final AddSubjectsFromCatalogUseCaseContract _addSubjects;

  /// Máximo de asignaturas por alta (límite del backend).
  static const maxSelection = 50;

  Future<void> _reload(Emitter<SubjectSelectorState> emit) async {
    final filters = (state.course, state.semester, state.query);
    emit(state.copyWith(status: SubjectSelectorStatus.loading, error: null));
    final result = await _getSubjects(
      course: state.course,
      semester: state.semester,
      query: state.query.trim().isEmpty ? null : state.query.trim(),
    );
    // Los filtros han cambiado mientras se cargaba: se descarta.
    if (filters != (state.course, state.semester, state.query)) return;
    emit(
      result.fold(
        (page) => state.copyWith(
          status: SubjectSelectorStatus.ready,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
        ),
        (error) =>
            state.copyWith(status: SubjectSelectorStatus.failure, error: error),
      ),
    );
  }

  Future<void> _onMore(
    SubjectSelectorMoreRequested event,
    Emitter<SubjectSelectorState> emit,
  ) async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != SubjectSelectorStatus.ready) {
      return;
    }
    emit(state.copyWith(loadingMore: true, actionError: null));
    final result = await _getSubjects(
      course: state.course,
      semester: state.semester,
      query: state.query.trim().isEmpty ? null : state.query.trim(),
      page: state.page + 1,
    );
    emit(
      result.fold(
        (page) => state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ),
        (error) => state.copyWith(loadingMore: false, actionError: error),
      ),
    );
  }

  void _onToggled(
    SubjectSelectorToggled event,
    Emitter<SubjectSelectorState> emit,
  ) {
    final selected = {...state.selected};
    if (!selected.remove(event.subjectId)) {
      if (selected.length >= maxSelection) return;
      selected.add(event.subjectId);
    }
    emit(state.copyWith(selected: selected));
  }

  Future<void> _onSubmitted(
    SubjectSelectorSubmitted event,
    Emitter<SubjectSelectorState> emit,
  ) async {
    if (state.selected.isEmpty) return;
    emit(state.copyWith(submitting: true, actionError: null, addedCount: null));
    final result = await _addSubjects(state.selected.toList());
    emit(
      result.fold(
        (count) => state.copyWith(
          submitting: false,
          addedCount: count,
          selected: const {},
          items: [
            for (final item in state.items)
              state.selected.contains(item.id)
                  ? item.copyWith(alreadyAdded: true)
                  : item,
          ],
        ),
        (error) => state.copyWith(submitting: false, actionError: error),
      ),
    );
  }
}
