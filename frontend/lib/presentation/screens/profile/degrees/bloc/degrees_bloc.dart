import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../../domain/use_cases/profile/get_my_degrees_use_case.dart';
import '../../../../../domain/use_cases/profile/link_degree_use_case.dart';
import '../../../../../domain/use_cases/profile/unlink_degree_use_case.dart';

part 'degrees_bloc.freezed.dart';
part 'degrees_event.dart';
part 'degrees_state.dart';

/// Carreras vinculadas: listar, vincular y desvincular.
class DegreesBloc extends Bloc<DegreesEvent, DegreesState> {
  DegreesBloc({
    required this._getDegrees,
    required this._linkDegree,
    required this._unlinkDegree,
  }) : super(const DegreesState()) {
    on<DegreesStarted>(_onStarted);
    on<DegreesLinkRequested>(_onLink);
    on<DegreesUnlinkRequested>(_onUnlink);
  }

  final GetMyDegreesUseCaseContract _getDegrees;
  final LinkDegreeUseCaseContract _linkDegree;
  final UnlinkDegreeUseCaseContract _unlinkDegree;

  Future<void> _onStarted(
    DegreesStarted event,
    Emitter<DegreesState> emit,
  ) async {
    if (state.degrees.isEmpty) {
      emit(state.copyWith(status: DegreesStatus.loading, error: null));
    }
    final result = await _getDegrees();
    emit(
      result.fold(
        (degrees) => state.copyWith(
          status: DegreesStatus.ready,
          degrees: degrees,
          error: null,
        ),
        (error) => state.copyWith(status: DegreesStatus.failure, error: error),
      ),
    );
  }

  Future<void> _onLink(
    DegreesLinkRequested event,
    Emitter<DegreesState> emit,
  ) async {
    if (state.degrees.any((d) => d.degree.id == event.degree.id)) return;
    emit(state.copyWith(busy: true, actionError: null, outcome: null));
    final result = await _linkDegree(event.degree.id);
    emit(
      result.fold(
        (linked) => state.copyWith(
          busy: false,
          degrees: [...state.degrees, linked],
          outcome: DegreesOutcome.linked,
        ),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }

  Future<void> _onUnlink(
    DegreesUnlinkRequested event,
    Emitter<DegreesState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null, outcome: null));
    final result = await _unlinkDegree(event.degreeId);
    emit(
      result.fold(
        (_) => state.copyWith(
          busy: false,
          degrees: state.degrees
              .where((d) => d.degree.id != event.degreeId)
              .toList(),
          outcome: DegreesOutcome.unlinked,
        ),
        (error) => state.copyWith(busy: false, actionError: error),
      ),
    );
  }
}
