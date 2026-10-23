import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/data_topic.dart';
import '../../../../domain/models/account/account.dart';
import '../../../../domain/models/progress/badge.dart';
import '../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../domain/use_cases/progress/get_unnotified_badges_use_case.dart';
import '../../../../domain/use_cases/progress/mark_badges_notified_use_case.dart';
import '../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';

part 'achievements_bloc.freezed.dart';
part 'achievements_event.dart';
part 'achievements_state.dart';

/// Logros de toda la app: tras cualquier acción que pueda dar XP (entrenar,
/// estudiar, completar un reto…) recarga la cuenta, detecta si se ha subido
/// de nivel y recoge las insignias nuevas para celebrarlas una sola vez,
/// estés en la pestaña que estés. Las insignias las otorga el servidor; aquí
/// solo se leen las no celebradas.
class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  AchievementsBloc({
    required this._getAccount,
    required this._checkNewBadges,
    required this._markBadgesNotified,
    required this._watchChanges,
  }) : super(const AchievementsState()) {
    on<AchievementsStarted>(_onStarted);
    on<AchievementsDataChanged>(_onDataChanged);
    on<AchievementsCelebrated>(_onCelebrated);
  }

  final GetAccountUseCaseContract _getAccount;
  final GetUnnotifiedBadgesUseCaseContract _checkNewBadges;
  final MarkBadgesNotifiedUseCaseContract _markBadgesNotified;
  final WatchDataChangesUseCaseContract _watchChanges;
  StreamSubscription<Set<DataTopic>>? _subscription;

  Future<void> _onStarted(
    AchievementsStarted event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(state.copyWith(knownLevel: event.account?.level));
    await _subscription?.cancel();
    _subscription = _watchChanges(
      topics: const {DataTopic.gamification},
    ).listen((_) => add(const AchievementsEvent.dataChanged()));
    await _collectBadges(emit);
  }

  Future<void> _onDataChanged(
    AchievementsDataChanged event,
    Emitter<AchievementsState> emit,
  ) async {
    final account = (await _getAccount()).valueOrNull;
    if (account != null) {
      final known = state.knownLevel;
      final leveledUp = known != null && account.level > known;
      emit(
        state.copyWith(
          account: account,
          knownLevel: account.level,
          levelReached: leveledUp ? account.level : state.levelReached,
        ),
      );
    }
    await _collectBadges(emit);
  }

  /// Junta las insignias nuevas con las que ya esperaban, sin duplicados.
  Future<void> _collectBadges(Emitter<AchievementsState> emit) async {
    final badges = (await _checkNewBadges()).valueOrNull ?? const [];
    if (badges.isEmpty) return;
    final known = {for (final b in state.badges) b.id};
    final fresh = badges.where((b) => !known.contains(b.id));
    if (fresh.isEmpty) return;
    emit(state.copyWith(badges: [...state.badges, ...fresh]));
  }

  /// El usuario ya ha visto la celebración. Solo se quita lo mostrado: lo que
  /// llegó con el diálogo abierto se celebra a continuación. Si marcar falla,
  /// las insignias se volverán a celebrar (mejor repetir que perderlas).
  Future<void> _onCelebrated(
    AchievementsCelebrated event,
    Emitter<AchievementsState> emit,
  ) async {
    final shown = event.badgeIds.toSet();
    emit(
      state.copyWith(
        badges: [
          for (final badge in state.badges)
            if (!shown.contains(badge.id)) badge,
        ],
        levelReached: state.levelReached == event.level
            ? null
            : state.levelReached,
      ),
    );
    await _markBadgesNotified(event.badgeIds);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
