import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/create_study_room_use_case.dart';

part 'study_invite_bloc.freezed.dart';
part 'study_invite_event.dart';
part 'study_invite_state.dart';

/// «Estudiar con amigos» (ADR 0045 y 0053): los minutos de cada ronda,
/// cuántas rondas e «Invitar». Los amigos (y los topes, del servidor) los elige
/// `FriendPickerBloc`; la asignatura llega del Pomodoro si había una.
class StudyInviteBloc extends Bloc<StudyInviteEvent, StudyInviteState> {
  StudyInviteBloc({required this._create}) : super(const StudyInviteState()) {
    on<StudyInviteStarted>(_onStarted);
    on<StudyInviteTimesChosen>(
      (e, emit) => emit(state.copyWith(times: e.times)),
    );
    on<StudyInviteRoundsChosen>(
      (e, emit) => emit(state.copyWith(rounds: e.rounds)),
    );
    on<StudyInviteSubmitted>(_onSubmitted);
  }

  final CreateStudyRoomUseCaseContract _create;

  void _onStarted(StudyInviteStarted event, Emitter<StudyInviteState> emit) =>
      emit(
        state.copyWith(
          times: event.times ?? state.times,
          subjectId: event.subjectId,
        ),
      );

  Future<void> _onSubmitted(
    StudyInviteSubmitted event,
    Emitter<StudyInviteState> emit,
  ) async {
    if (state.saving || event.friendIds.isEmpty) return;
    emit(state.copyWith(saving: true, error: null));
    final result = await _create(
      times: state.times,
      rounds: state.rounds,
      friendIds: event.friendIds,
      subjectId: state.subjectId,
    );
    emit(switch (result) {
      Success(:final value) => state.copyWith(saving: false, created: value),
      Failure(:final error) => state.copyWith(saving: false, error: error),
    });
    emit(state.copyWith(error: null));
  }
}
