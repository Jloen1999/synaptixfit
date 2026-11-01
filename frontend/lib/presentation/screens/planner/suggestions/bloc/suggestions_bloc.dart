import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/planner/block_draft.dart';
import '../../../../../domain/models/planner/planner_ai.dart';
import '../../../../../domain/models/planner/planner_week.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/planner/create_block_use_case.dart';
import '../../../../../domain/use_cases/planner/suggest_week_plan_use_case.dart';

part 'suggestions_bloc.freezed.dart';
part 'suggestions_event.dart';
part 'suggestions_state.dart';

/// Sugerencias de planificación semanal (IA o heurística) y su aceptación.
class SuggestionsBloc extends Bloc<SuggestionsEvent, SuggestionsState> {
  SuggestionsBloc({
    required this._suggest,
    required this._createBlock,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(
         SuggestionsState(
           currentWeek: PlannerWeek.mondayOf((now ?? DateTime.now)()),
         ),
       ) {
    on<SuggestionsStudyHoursChanged>(
      (e, emit) => emit(state.copyWith(studyHours: e.hours.clamp(0, 80))),
    );
    on<SuggestionsSportSessionsChanged>(
      (e, emit) => emit(state.copyWith(sportSessions: e.sessions.clamp(0, 7))),
    );
    on<SuggestionsWeekOffsetChanged>(_onWeekOffset);
    on<SuggestionsGenerateRequested>(_onGenerate);
    on<SuggestionsBlockToggled>(_onToggle);
    on<SuggestionsAllToggled>(_onAllToggled);
    on<SuggestionsAcceptRequested>(_onAccept);
  }

  final SuggestWeekPlanUseCaseContract _suggest;
  final CreateBlockUseCaseContract _createBlock;
  final DateTime Function() _now;

  void _onWeekOffset(
    SuggestionsWeekOffsetChanged event,
    Emitter<SuggestionsState> emit,
  ) {
    if (event.offset == state.weekOffset) return;
    // La propuesta anterior era de otra semana: se descarta.
    emit(
      state.copyWith(
        weekOffset: event.offset,
        suggestion: null,
        selected: const {},
        expired: const {},
        status: SuggestionsStatus.idle,
        error: null,
      ),
    );
  }

  Future<void> _onGenerate(
    SuggestionsGenerateRequested event,
    Emitter<SuggestionsState> emit,
  ) async {
    if (state.status == SuggestionsStatus.generating ||
        state.status == SuggestionsStatus.accepting) {
      return;
    }
    emit(state.copyWith(status: SuggestionsStatus.generating, error: null));
    final result = await _suggest(
      weekStart: state.weekStart,
      studyHours: state.studyHours,
      sportSessions: state.sportSessions,
    );
    switch (result) {
      case Failure(:final error):
        emit(
          state.copyWith(
            status: state.suggestion == null
                ? SuggestionsStatus.idle
                : SuggestionsStatus.ready,
            error: state.suggestion == null ? error : null,
            notice: state.suggestion == null
                ? state.notice
                : SuggestionsNotice.failure(error),
            noticeId: state.suggestion == null
                ? state.noticeId
                : state.noticeId + 1,
          ),
        );
      case Success(:final value):
        final now = _now();
        final expired = {
          for (var i = 0; i < value.blocks.length; i++)
            if (value.blocks[i].start.isBefore(now)) i,
        };
        emit(
          state.copyWith(
            status: SuggestionsStatus.ready,
            suggestion: value,
            expired: expired,
            selected: {
              for (var i = 0; i < value.blocks.length; i++)
                if (!expired.contains(i)) i,
            },
          ),
        );
    }
  }

  void _onToggle(
    SuggestionsBlockToggled event,
    Emitter<SuggestionsState> emit,
  ) {
    if (state.expired.contains(event.index)) return;
    final selected = {...state.selected};
    if (!selected.remove(event.index)) selected.add(event.index);
    emit(state.copyWith(selected: selected));
  }

  void _onAllToggled(
    SuggestionsAllToggled event,
    Emitter<SuggestionsState> emit,
  ) {
    final blocks = state.suggestion?.blocks ?? const [];
    emit(
      state.copyWith(
        selected: event.selected
            ? {
                for (var i = 0; i < blocks.length; i++)
                  if (!state.expired.contains(i)) i,
              }
            : const {},
      ),
    );
  }

  Future<void> _onAccept(
    SuggestionsAcceptRequested event,
    Emitter<SuggestionsState> emit,
  ) async {
    final suggestion = state.suggestion;
    if (suggestion == null ||
        state.selected.isEmpty ||
        state.status == SuggestionsStatus.accepting) {
      return;
    }
    emit(state.copyWith(status: SuggestionsStatus.accepting));
    final indexes = state.selected.toList()..sort();
    final createdIndexes = <int>{};
    AppError? firstError;
    for (final i in indexes) {
      final b = suggestion.blocks[i];
      final result = await _createBlock(
        BlockDraft(
          type: b.type,
          start: b.start,
          end: b.end,
          subjectId: b.subjectId,
          routineId: b.routineId,
          routineWeekId: b.routineWeekId,
          routineDayId: b.routineDayId,
          topics: b.title ?? b.topic,
        ),
      );
      switch (result) {
        case Success():
          createdIndexes.add(i);
        case Failure(:final error):
          firstError ??= error;
      }
    }
    // Los bloques creados salen de la propuesta; quedan los que fallaron.
    final remaining = [
      for (var i = 0; i < suggestion.blocks.length; i++)
        if (!createdIndexes.contains(i)) suggestion.blocks[i],
    ];
    final now = _now();
    final expired = {
      for (var i = 0; i < remaining.length; i++)
        if (remaining[i].start.isBefore(now)) i,
    };
    emit(
      state.copyWith(
        status: SuggestionsStatus.ready,
        suggestion: suggestion.copyWith(blocks: remaining),
        expired: expired,
        selected: const {},
        notice: SuggestionsNotice.accepted(
          created: createdIndexes.length,
          failed: indexes.length - createdIndexes.length,
          firstError: firstError,
        ),
        noticeId: state.noticeId + 1,
      ),
    );
  }
}
