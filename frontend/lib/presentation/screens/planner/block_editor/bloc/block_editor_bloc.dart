import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/planner/block_draft.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/deadline.dart';
import '../../../../../domain/models/planner/planner_options.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/planner/create_block_use_case.dart';
import '../../../../../domain/use_cases/planner/distribute_routine_use_case.dart';
import '../../../../../domain/use_cases/planner/get_deadlines_use_case.dart';
import '../../../../../domain/use_cases/planner/get_planner_challenges_use_case.dart';
import '../../../../../domain/use_cases/planner/get_planner_routines_use_case.dart';
import '../../../../../domain/use_cases/planner/get_planner_subjects_use_case.dart';
import '../../../../../domain/use_cases/planner/reschedule_block_use_case.dart';
import '../../../../../domain/use_cases/planner/update_block_use_case.dart';

part 'block_editor_bloc.freezed.dart';
part 'block_editor_event.dart';
part 'block_editor_state.dart';

/// Hoja de creación/edición de un bloque y distribución de rutinas.
class BlockEditorBloc extends Bloc<BlockEditorEvent, BlockEditorState> {
  BlockEditorBloc({
    required this._getSubjects,
    required this._getRoutines,
    required this._getChallenges,
    required this._getDeadlines,
    required this._createBlock,
    required this._updateBlock,
    required this._reschedule,
    required this._distribute,
    CalendarBlock? block,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(BlockEditorState(block: block)) {
    on<BlockEditorStarted>(_onStarted);
    on<BlockEditorSaveRequested>(_onSave);
    on<BlockEditorDistributionRequested>(_onDistribute);
  }

  static const minDurationMinutes = 30;

  final GetPlannerSubjectsUseCaseContract _getSubjects;
  final GetPlannerRoutinesUseCaseContract _getRoutines;
  final GetPlannerChallengesUseCaseContract _getChallenges;
  final GetDeadlinesUseCaseContract _getDeadlines;
  final CreateBlockUseCaseContract _createBlock;
  final UpdateBlockUseCaseContract _updateBlock;
  final RescheduleBlockUseCaseContract _reschedule;
  final DistributeRoutineUseCaseContract _distribute;
  final DateTime Function() _now;

  BlockEditorState _issue(BlockEditorIssue issue) => state.copyWith(
    issue: issue,
    error: null,
    feedbackId: state.feedbackId + 1,
  );

  BlockEditorState _failure(AppError error) => state.copyWith(
    submitting: false,
    error: error,
    issue: null,
    feedbackId: state.feedbackId + 1,
  );

  Future<void> _onStarted(
    BlockEditorStarted event,
    Emitter<BlockEditorState> emit,
  ) async {
    final subjectsF = _getSubjects();
    final routinesF = _getRoutines();
    final challengesF = _getChallenges();
    final deadlinesF = _getDeadlines(upcoming: true);
    final subjects = await subjectsF;
    final routines = await routinesF;
    final challenges = await challengesF;
    final deadlines = await deadlinesF;
    final firstError =
        subjects.errorOrNull ??
        routines.errorOrNull ??
        challenges.errorOrNull ??
        deadlines.errorOrNull;
    emit(
      state.copyWith(
        status: BlockEditorStatus.ready,
        subjects: subjects.valueOrNull ?? const [],
        routines: routines.valueOrNull ?? const [],
        challenges: challenges.valueOrNull ?? const [],
        deadlines: deadlines.valueOrNull?.items ?? const [],
        optionsError: firstError,
      ),
    );
  }

  Future<void> _onSave(
    BlockEditorSaveRequested event,
    Emitter<BlockEditorState> emit,
  ) async {
    if (state.submitting) return;
    final draft = event.draft;
    final original = state.block;
    final timeChanged =
        original == null ||
        original.start != draft.start ||
        original.end != draft.end;

    if (draft.end.difference(draft.start).inMinutes < minDurationMinutes) {
      emit(_issue(BlockEditorIssue.tooShort));
      return;
    }
    if (timeChanged && draft.start.isBefore(_now())) {
      emit(_issue(BlockEditorIssue.inPast));
      return;
    }
    emit(state.copyWith(submitting: true, error: null, issue: null));

    if (original == null) {
      final result = await _createBlock(draft);
      emit(
        result.fold(
          (change) => state.copyWith(
            submitting: false,
            outcome: BlockEditorOutcome.created(
              overlaps: change.conflicts.length,
              weeklyCopies: change.weeklyCopies,
            ),
          ),
          _failure,
        ),
      );
      return;
    }

    final updated = await _updateBlock(original.id, draft);
    if (updated case Failure(:final error)) {
      emit(_failure(error));
      return;
    }
    if (timeChanged && !original.isLocked) {
      final moved = await _reschedule(
        original.id,
        start: draft.start,
        end: draft.end,
      );
      if (moved case Failure(:final error)) {
        emit(_failure(error));
        return;
      }
    }
    emit(
      state.copyWith(
        submitting: false,
        outcome: const BlockEditorOutcome.updated(),
      ),
    );
  }

  Future<void> _onDistribute(
    BlockEditorDistributionRequested event,
    Emitter<BlockEditorState> emit,
  ) async {
    if (state.submitting) return;
    if (event.request.weekdays.isEmpty) {
      emit(_issue(BlockEditorIssue.noWeekdays));
      return;
    }
    emit(state.copyWith(submitting: true, error: null, issue: null));
    final result = await _distribute(event.request);
    emit(
      result.fold(
        (blocks) => state.copyWith(
          submitting: false,
          outcome: BlockEditorOutcome.distributed(blocks.length),
        ),
        _failure,
      ),
    );
  }
}
