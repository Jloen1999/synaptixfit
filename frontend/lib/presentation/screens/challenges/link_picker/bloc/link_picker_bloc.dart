import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/challenges/challenge_references.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_link_targets_use_case.dart';

part 'link_picker_bloc.freezed.dart';
part 'link_picker_event.dart';
part 'link_picker_state.dart';

/// Selector de la entrega o examen al que vincular un reto o tarea.
class LinkPickerBloc extends Bloc<LinkPickerEvent, LinkPickerState> {
  LinkPickerBloc({required this._listTargets})
    : super(const LinkPickerState()) {
    on<LinkPickerStarted>(_onStarted);
  }

  final ListChallengeLinkTargetsUseCaseContract _listTargets;

  Future<void> _onStarted(
    LinkPickerStarted event,
    Emitter<LinkPickerState> emit,
  ) async {
    emit(const LinkPickerState());
    final result = await _listTargets(
      subjectId: event.subjectId,
      from: event.from,
      to: event.to,
    );
    emit(
      result.fold(
        (options) =>
            LinkPickerState(status: LinkPickerStatus.ready, options: options),
        (error) =>
            LinkPickerState(status: LinkPickerStatus.failure, error: error),
      ),
    );
  }
}
