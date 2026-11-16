import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/guide_id.dart';
import '../../../../domain/use_cases/guides/mark_guide_seen_use_case.dart';
import '../../../../domain/use_cases/guides/should_show_guide_use_case.dart';

part 'guide_tour_bloc.freezed.dart';
part 'guide_tour_event.dart';
part 'guide_tour_state.dart';

/// Guía la primera vez de una pantalla (ADR 0049), una instancia por pantalla
/// (la crea `FirstTimeGuide`): pregunta si toca enseñarla y, al cerrarla
/// (terminada, saltada o con «atrás»), la apunta como vista. Cada pantalla la
/// pide como mucho una vez mientras está abierta.
class GuideTourBloc extends Bloc<GuideTourEvent, GuideTourState> {
  GuideTourBloc({required this._shouldShow, required this._markSeen})
    : super(const GuideTourState()) {
    on<GuideTourRequested>(_onRequested);
    on<GuideTourClosed>(_onClosed);
    on<GuideTourAbandoned>(
      (_, emit) => emit(state.copyWith(status: GuideTourStatus.done)),
    );
  }

  final ShouldShowGuideUseCaseContract _shouldShow;
  final MarkGuideSeenUseCaseContract _markSeen;

  Future<void> _onRequested(
    GuideTourRequested event,
    Emitter<GuideTourState> emit,
  ) async {
    if (state.status != GuideTourStatus.idle) return;
    emit(
      state.copyWith(
        status: GuideTourStatus.checking,
        guide: event.guide,
        accountId: event.accountId,
      ),
    );
    final result = await _shouldShow(
      accountId: event.accountId,
      guide: event.guide,
    );
    // Si no se puede leer, no se enseña: una guía no es imprescindible.
    final show = result.valueOrNull ?? false;
    emit(
      state.copyWith(
        status: show ? GuideTourStatus.showing : GuideTourStatus.done,
      ),
    );
  }

  Future<void> _onClosed(
    GuideTourClosed event,
    Emitter<GuideTourState> emit,
  ) async {
    final guide = state.guide;
    final accountId = state.accountId;
    if (state.status != GuideTourStatus.showing ||
        guide == null ||
        accountId == null) {
      return;
    }
    emit(state.copyWith(status: GuideTourStatus.saving));
    // Si no se puede guardar, saldrá otra vez: mejor que perder el aviso.
    await _markSeen(accountId: accountId, guide: guide);
    emit(state.copyWith(status: GuideTourStatus.done));
  }
}
