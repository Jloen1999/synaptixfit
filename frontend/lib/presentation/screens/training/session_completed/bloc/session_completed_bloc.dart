import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/post_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/recommendation.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/use_cases/social/create_post_use_case.dart';
import '../../../../../domain/use_cases/training/apply_recommendation_use_case.dart';
import '../../../../../domain/use_cases/training/discard_recommendation_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_highlights_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_use_case.dart';
import '../../training_effect.dart';
import '../../../../../domain/enums/challenge_status.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_query.dart';
import '../../../../../domain/models/progress/streak.dart';
import '../../../../../domain/use_cases/challenges/list_my_challenges_use_case.dart';
import '../../../../../domain/use_cases/progress/get_streak_use_case.dart';

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
    required this._getHighlights,
    required this._createPost,
    required this._getStreak,
    required this._listChallenges,
  }) : super(const SessionCompletedState()) {
    on<SessionCompletedStarted>(_onStarted);
    on<SessionCompletedShareRequested>(_onShare);
    on<SessionCompletedRecommendationApplied>(_onApply);
    on<SessionCompletedRecommendationDiscarded>(_onDiscard);
    on<SessionCompletedRecommendationRestored>((e, emit) {
      _pendingDiscards.remove(e.recommendation.id);
      emit(
        state.copyWith(
          recommendations: [...state.recommendations, e.recommendation],
        ),
      );
    });
    on<SessionCompletedRecommendationDiscardConfirmed>(_onDiscardConfirmed);
  }

  /// Sugerencias quitadas con el aviso de «Deshacer» aún abierto; si la
  /// pantalla se cierra antes, se descartan igual.
  final Set<String> _pendingDiscards = {};

  final GetSessionUseCaseContract _getSession;
  final ApplyRecommendationUseCaseContract _apply;
  final DiscardRecommendationUseCaseContract _discard;
  final GetSessionHighlightsUseCaseContract _getHighlights;
  final CreatePostUseCaseContract _createPost;
  final GetStreakUseCaseContract _getStreak;
  final ListMyChallengesUseCaseContract _listChallenges;

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
          xpWithheld: result.xpWithheld,
          recommendations: result.recommendations,
        ),
      );
    } else {
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
    if (state.status != CompletedStatus.ready) return;
    // Lo destacado no bloquea la pantalla: si falla, no se muestra.
    final highlights = await _getHighlights(event.sessionId);
    if (highlights.valueOrNull case final h?) {
      emit(state.copyWith(highlights: h));
    }
    // Lo que ha sumado la sesión: racha y retos que cuentan entrenos (si
    // falla, simplemente no se muestra).
    final streak = await _getStreak();
    final challenges = await _listChallenges(
      query: const ChallengeQuery(status: ChallengeStatus.active),
      size: 10,
    );
    emit(
      state.copyWith(
        streak: streak.valueOrNull,
        trainingChallenges: [
          for (final c in challenges.valueOrNull?.items ?? const <Challenge>[])
            if (c.tracksTrainingSessions) c,
        ],
      ),
    );
  }

  Future<void> _onShare(
    SessionCompletedShareRequested event,
    Emitter<SessionCompletedState> emit,
  ) async {
    if (state.shared || state.sharing) return;
    emit(state.copyWith(sharing: true, effect: null));
    // Con el id de la sesión el servidor evita publicarla dos veces (también
    // al volver a abrir este resumen).
    final result = await _createPost(
      type: PostType.sessionCompleted,
      description: event.description,
      metadata: {'sessionId': state.session!.id},
    );
    emit(switch (result) {
      Success() => state.copyWith(
        sharing: false,
        shared: true,
        effect: const TrainingEffect.message(TrainingMessage.sessionShared),
      ),
      Failure(error: BusinessError(code: 'POST_ALREADY_SHARED')) =>
        state.copyWith(sharing: false, shared: true),
      Failure(:final error) => state.copyWith(
        sharing: false,
        effect: TrainingEffect.error(error),
      ),
    });
  }

  Future<void> _onApply(
    SessionCompletedRecommendationApplied event,
    Emitter<SessionCompletedState> emit,
  ) async {
    final id = event.recommendationId;
    final applied = state.recommendations.where((r) => r.id == id).firstOrNull;
    emit(state.copyWith(busyIds: {...state.busyIds, id}));
    final AppError? error = (await _apply(id)).errorOrNull;
    final busy = {...state.busyIds}..remove(id);
    if (error != null) {
      emit(state.copyWith(busyIds: busy));
      _effect(emit, TrainingEffect.error(error));
      return;
    }
    emit(
      state.copyWith(
        busyIds: busy,
        recommendations: [
          for (final r in state.recommendations)
            r.id == id ? r.copyWith(applied: true) : r,
        ],
      ),
    );
    _effect(
      emit,
      TrainingEffect.recommendationApplied(routineId: applied?.routineId),
    );
  }

  void _onDiscard(
    SessionCompletedRecommendationDiscarded event,
    Emitter<SessionCompletedState> emit,
  ) {
    final id = event.recommendationId;
    final recommendation = state.recommendations
        .where((r) => r.id == id)
        .firstOrNull;
    if (recommendation == null) return;
    _pendingDiscards.add(id);
    emit(
      state.copyWith(
        recommendations: state.recommendations
            .where((r) => r.id != id)
            .toList(),
      ),
    );
    _effect(emit, TrainingEffect.recommendationDiscarded(recommendation));
  }

  Future<void> _onDiscardConfirmed(
    SessionCompletedRecommendationDiscardConfirmed event,
    Emitter<SessionCompletedState> emit,
  ) async {
    if (!_pendingDiscards.remove(event.recommendationId)) return;
    final error = (await _discard(event.recommendationId)).errorOrNull;
    if (error != null) _effect(emit, TrainingEffect.error(error));
  }

  @override
  Future<void> close() {
    for (final id in _pendingDiscards) {
      _discard(id).ignore();
    }
    _pendingDiscards.clear();
    return super.close();
  }

  void _effect(Emitter<SessionCompletedState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
