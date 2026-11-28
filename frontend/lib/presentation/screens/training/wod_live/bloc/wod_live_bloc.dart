import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/wod.dart';
import '../../../../../domain/models/training/wod_timer.dart';
import '../../../../../domain/use_cases/training/save_wod_result_use_case.dart';

part 'wod_live_bloc.freezed.dart';
part 'wod_live_event.dart';
part 'wod_live_state.dart';

/// WOD en marcha (ADR 0069): lleva los segundos activos (las pausas no
/// cuentan) y guarda la marca al terminar. Qué fase toca lo dice [WodTimer]
/// (dominio). La cuenta vive en esta pantalla: salir la pierde, por eso la
/// página avisa antes.
class WodLiveBloc extends Bloc<WodLiveEvent, WodLiveState> {
  WodLiveBloc({
    required this._saveResult,
    this._now = DateTime.now,
    this._tick = const Duration(seconds: 1),
  }) : super(const WodLiveState()) {
    on<WodLiveStarted>(_onStarted);
    on<WodLiveTicked>((_, emit) => _sync(emit));
    on<WodLivePauseToggled>(_onPauseToggled);
    on<WodLiveFinishRequested>(_onFinish);
    on<WodLiveResumed>(_onResumed);
    on<WodLiveResultSubmitted>(_onResult);
  }

  final SaveWodResultUseCaseContract _saveResult;
  final DateTime Function() _now;
  final Duration _tick;

  Timer? _timer;

  /// Segundos activos hasta la última pausa y desde cuándo corre ahora. Se
  /// mide con el reloj, no contando tics: un tic que llega tarde no atrasa.
  Duration _banked = Duration.zero;
  DateTime? _runningSince;

  int get _elapsed {
    final since = _runningSince;
    final total = since == null ? _banked : _banked + _now().difference(since);
    return total.inSeconds;
  }

  void _onStarted(WodLiveStarted e, Emitter<WodLiveState> emit) {
    _banked = Duration.zero;
    _runningSince = _now();
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => add(const WodLiveEvent.ticked()));
    emit(
      WodLiveState(
        wod: e.wod,
        division: e.division,
        status: WodLiveStatus.running,
      ),
    );
  }

  void _sync(Emitter<WodLiveState> emit) {
    final wod = state.wod;
    if (wod == null || state.status != WodLiveStatus.running) return;
    final tick = WodTimer.of(wod).at(_elapsed);
    if (tick.done) {
      // Se acabó el tiempo: el reloj se queda en el total y se pide la marca.
      _stopClock();
      emit(
        state.copyWith(
          elapsedSeconds: tick.elapsedSeconds,
          status: WodLiveStatus.finished,
          timeUp: true,
        ),
      );
      return;
    }
    emit(state.copyWith(elapsedSeconds: tick.elapsedSeconds));
  }

  void _onPauseToggled(WodLivePauseToggled e, Emitter<WodLiveState> emit) {
    switch (state.status) {
      case WodLiveStatus.running:
        _stopClock();
        emit(
          state.copyWith(
            status: WodLiveStatus.paused,
            elapsedSeconds: _banked.inSeconds,
          ),
        );
      case WodLiveStatus.paused:
        _runningSince = _now();
        emit(state.copyWith(status: WodLiveStatus.running));
      case WodLiveStatus.idle || WodLiveStatus.finished:
        break;
    }
  }

  void _onFinish(WodLiveFinishRequested e, Emitter<WodLiveState> emit) {
    if (state.status != WodLiveStatus.running &&
        state.status != WodLiveStatus.paused) {
      return;
    }
    _stopClock();
    emit(
      state.copyWith(
        status: WodLiveStatus.finished,
        elapsedSeconds: _banked.inSeconds,
      ),
    );
  }

  /// «Seguir» tras tocar «Terminar» sin querer: vuelve en pausa, y solo si
  /// el tiempo no se había acabado.
  void _onResumed(WodLiveResumed e, Emitter<WodLiveState> emit) {
    if (state.status != WodLiveStatus.finished || state.timeUp) return;
    emit(state.copyWith(status: WodLiveStatus.paused));
  }

  Future<void> _onResult(
    WodLiveResultSubmitted e,
    Emitter<WodLiveState> emit,
  ) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, error: null));
    final result = await _saveResult(e.wod, e.draft);
    switch (result) {
      case Failure(:final error):
        emit(state.copyWith(saving: false, error: error));
      case Success(:final value):
        emit(state.copyWith(saving: false, saved: value));
    }
  }

  /// Para el reloj guardando lo que llevaba.
  void _stopClock() {
    final since = _runningSince;
    if (since != null) _banked += _now().difference(since);
    _runningSince = null;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
