import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_template.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/challenges/list_challenge_templates_use_case.dart';
import '../../../../../domain/use_cases/challenges/start_challenge_template_use_case.dart';

part 'challenge_templates_bloc.freezed.dart';
part 'challenge_templates_event.dart';
part 'challenge_templates_state.dart';

/// Galería de plantillas de retos (ADR 0043): las lista y empieza una con un
/// toque.
class ChallengeTemplatesBloc
    extends Bloc<ChallengeTemplatesEvent, ChallengeTemplatesState> {
  ChallengeTemplatesBloc({required this._list, required this._start})
    : super(const ChallengeTemplatesState()) {
    on<ChallengeTemplatesStarted>(_onStarted);
    on<ChallengeTemplatesStartRequested>(_onStart);
  }

  final ListChallengeTemplatesUseCaseContract _list;
  final StartChallengeTemplateUseCaseContract _start;

  Future<void> _onStarted(
    ChallengeTemplatesStarted event,
    Emitter<ChallengeTemplatesState> emit,
  ) async {
    emit(state.copyWith(status: ChallengeTemplatesStatus.loading, error: null));
    final result = await _list();
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: ChallengeTemplatesStatus.ready,
        templates: value,
      ),
      Failure(:final error) => state.copyWith(
        status: ChallengeTemplatesStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onStart(
    ChallengeTemplatesStartRequested event,
    Emitter<ChallengeTemplatesState> emit,
  ) async {
    if (state.startingId != null) return;
    emit(state.copyWith(startingId: event.templateId, startError: null));
    final result = await _start(event.templateId);
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        startingId: null,
        started: value,
        templates: [
          for (final t in state.templates)
            t.id == event.templateId ? t.copyWith(running: true) : t,
        ],
      ),
      Failure(:final error) => state.copyWith(
        startingId: null,
        startError: error,
      ),
    });
    emit(state.copyWith(started: null, startError: null));
  }
}
