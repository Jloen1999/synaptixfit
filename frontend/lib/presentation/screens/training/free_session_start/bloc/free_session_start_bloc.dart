import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/routine_template.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/use_cases/training/get_routine_template_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_history_use_case.dart';
import '../../../../../domain/use_cases/training/list_routine_templates_use_case.dart';
import '../../../../../domain/use_cases/training/start_free_session_use_case.dart';
import '../../training_effect.dart';

part 'free_session_start_bloc.freezed.dart';
part 'free_session_start_event.dart';
part 'free_session_start_state.dart';

/// «Sesión libre: cómo empezar» (ADR 0067): junta los ejercicios elegidos y
/// empieza con [StartFreeSessionUseCaseContract] desde ellos, desde una sesión
/// anterior o desde un día de plantilla. Las cifras de partida las pone el
/// servidor; aquí solo se elige.
class FreeSessionStartBloc
    extends Bloc<FreeSessionStartEvent, FreeSessionStartState> {
  FreeSessionStartBloc({
    required this._start,
    required this._getHistory,
    required this._listTemplates,
    required this._getTemplate,
  }) : super(const FreeSessionStartState()) {
    on<FreeSessionStartStarted>(_onStarted);
    on<FreeSessionStartExerciseToggled>(_onToggled);
    on<FreeSessionStartStartRequested>(_onStart);
    on<FreeSessionStartTemplatesRequested>(_onTemplates);
    on<FreeSessionStartTemplateOpened>(_onTemplateOpened);
  }

  final StartFreeSessionUseCaseContract _start;
  final GetSessionHistoryUseCaseContract _getHistory;
  final ListRoutineTemplatesUseCaseContract _listTemplates;
  final GetRoutineTemplateUseCaseContract _getTemplate;

  /// Entrenos que se ofrecen para repetir: los últimos.
  static const recentCount = 5;

  Future<void> _onStarted(
    FreeSessionStartStarted event,
    Emitter<FreeSessionStartState> emit,
  ) async {
    final history = await _getHistory(size: recentCount);
    emit(
      state.copyWith(
        recent: history.valueOrNull?.items ?? const <SessionHistoryEntry>[],
        recentLoaded: true,
      ),
    );
  }

  void _onToggled(
    FreeSessionStartExerciseToggled event,
    Emitter<FreeSessionStartState> emit,
  ) {
    final chosen = state.chosen;
    final there = chosen.any((e) => e.id == event.exercise.id);
    emit(
      state.copyWith(
        chosen: there
            ? [
                for (final e in chosen)
                  if (e.id != event.exercise.id) e,
              ]
            : [...chosen, event.exercise],
      ),
    );
  }

  Future<void> _onStart(
    FreeSessionStartStartRequested event,
    Emitter<FreeSessionStartState> emit,
  ) async {
    if (state.starting) return;
    emit(state.copyWith(starting: true));
    final source =
        event.source ?? ChosenExercises([for (final e in state.chosen) e.id]);
    switch (await _start(source)) {
      case Success(value: final session):
        emit(state.copyWith(starting: false));
        _effect(emit, TrainingEffect.openSession(session.id));
      case Failure(:final error):
        emit(state.copyWith(starting: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onTemplates(
    FreeSessionStartTemplatesRequested event,
    Emitter<FreeSessionStartState> emit,
  ) async {
    if (state.templates != null && state.templatesError == null) return;
    emit(state.copyWith(templatesError: null));
    switch (await _listTemplates()) {
      case Success(:final value):
        emit(state.copyWith(templates: value));
      case Failure(:final error):
        emit(state.copyWith(templatesError: error));
    }
  }

  Future<void> _onTemplateOpened(
    FreeSessionStartTemplateOpened event,
    Emitter<FreeSessionStartState> emit,
  ) async {
    emit(
      state.copyWith(
        openTemplateId: event.templateId,
        templateDetail: null,
        templatesError: null,
      ),
    );
    if (event.templateId == null) return;
    switch (await _getTemplate(event.templateId!)) {
      case Success(:final value):
        if (state.openTemplateId == event.templateId) {
          emit(state.copyWith(templateDetail: value));
        }
      case Failure(:final error):
        emit(state.copyWith(templatesError: error));
    }
  }

  void _effect(Emitter<FreeSessionStartState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
