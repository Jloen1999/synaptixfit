import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/training/recommendation.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/use_cases/training/apply_recommendation_use_case.dart';
import '../../../../../domain/use_cases/training/discard_recommendation_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_use_case.dart';
import '../../training_effect.dart';

part 'session_completed_bloc.freezed.dart';
part 'session_completed_event.dart';
part 'session_completed_state.dart';

/// Resumen de una sesión finalizada: calorías, experiencia y sugerencias.
class SessionCompletedBloc
    extends Bloc<SessionCompletedEvent, SessionCompletedState> {
  SessionCompletedBloc({
    required this._getSession,
    required this._apply,
    required this._discard,
  }) : super(const SessionCompletedState()) {
    on<SessionCompletedStarted>(_onStarted);
    on<SessionCompletedRecommendationApplied>(
      (e, emit) => _act(emit, e.recommendationId, apply: true),
    );
    on<SessionCompletedRecommendationDiscarded>(
      (e, emit) => _act(emit, e.recommendationId, apply: false),
    );
  }

  final GetSessionUseCaseContract _getSession;
  final ApplyRecommendationUseCaseContract _apply;
  final DiscardRecommendationUseCaseContract _discard;

  /// Con [result] (recién finalizada) no hace falta pedir nada; sin él
  /// (enlace directo) se carga la sesión y no se conoce la experiencia.
  Future<void> _onStarted(
    SessionCompletedStarted event,
    Emitter<SessionCompletedState> emit,
  ) async {
    final result = event.result;
    if (result != null) {
      emit(
        SessionCompletedState(
          status: CompletedStatus.ready,
          session: result.session,
          experience: result.experience,
          recommendations: result.recommendations,
        ),
      );
      return;
    }
    emit(const SessionCompletedState());
    final session = await _getSession(event.sessionId);
    emit(
      session.fold(
        (s) => state.copyWith(status: CompletedStatus.ready, session: s),
        (error) =>
            state.copyWith(status: CompletedStatus.failure, error: error),
      ),
    );
  }

  Future<void> _act(
    Emitter<SessionCompletedState> emit,
    String id, {
    required bool apply,
  }) async {
    emit(state.copyWith(busyIds: {...state.busyIds, id}));
    final AppError? error = apply
        ? (await _apply(id)).errorOrNull
        : (await _discard(id)).errorOrNull;
    final busy = {...state.busyIds}..remove(id);
    if (error != null) {
      emit(state.copyWith(busyIds: busy));
      _effect(emit, TrainingEffect.error(error));
      return;
    }
    emit(
      state.copyWith(
        busyIds: busy,
        recommendations: apply
            ? [
                for (final r in state.recommendations)
                  r.id == id ? r.copyWith(applied: true) : r,
              ]
            : state.recommendations.where((r) => r.id != id).toList(),
      ),
    );
    _effect(
      emit,
      TrainingEffect.message(
        apply
            ? TrainingMessage.recommendationApplied
            : TrainingMessage.recommendationDiscarded,
      ),
    );
  }

  void _effect(Emitter<SessionCompletedState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
