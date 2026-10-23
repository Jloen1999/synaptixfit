import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/use_cases/academic/get_due_study_materials_use_case.dart';
import '../../../../../domain/use_cases/academic/get_subjects_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'academic_home_bloc.freezed.dart';
part 'academic_home_event.dart';
part 'academic_home_state.dart';

/// Pestaña Académico: asignaturas (activas o archivadas) y repasos pendientes.
/// Se refresca sola cuando cambian datos académicos o del planificador.
class AcademicHomeBloc extends Bloc<AcademicHomeEvent, AcademicHomeState>
    with DataChangeRefreshMixin<AcademicHomeEvent, AcademicHomeState> {
  AcademicHomeBloc({
    required this._getSubjects,
    required this._getDue,
    required this._watchChanges,
  }) : super(const AcademicHomeState()) {
    on<AcademicHomeStarted>((_, emit) {
      watchDataChanges(
        _watchChanges,
        topics: const {DataTopic.academic, DataTopic.planner},
        onChanged: const AcademicHomeEvent.refreshed(),
      );
      return _load(emit);
    });
    on<AcademicHomeRefreshed>((_, emit) => _load(emit, silent: true));
    on<AcademicHomeArchivedToggled>((event, emit) async {
      emit(state.copyWith(showArchived: event.archived));
      await _load(emit);
    });
  }

  final GetSubjectsUseCaseContract _getSubjects;
  final GetDueStudyMaterialsUseCaseContract _getDue;
  final WatchDataChangesUseCaseContract _watchChanges;

  Future<void> _load(
    Emitter<AcademicHomeState> emit, {
    bool silent = false,
  }) async {
    if (!silent) emit(state.copyWith(loading: true, error: null));
    final (subjects, due) = await (
      _getSubjects(archived: state.showArchived),
      _getDue(),
    ).wait;
    emit(
      subjects.fold(
        (list) => state.copyWith(
          loading: false,
          error: null,
          subjects: list,
          // Los repasos pendientes son secundarios: si fallan no bloquean.
          due: due.valueOrNull ?? state.due,
        ),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }
}
