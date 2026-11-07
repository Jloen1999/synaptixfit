import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../../domain/use_cases/progress/share_achievement_image_use_case.dart';
import '../../../../../domain/use_cases/training/delete_run_use_case.dart';
import '../../../../../domain/use_cases/training/get_run_use_case.dart';

part 'run_detail_bloc.freezed.dart';
part 'run_detail_event.dart';
part 'run_detail_state.dart';

/// Detalle de una carrera (ADR 0037). Borrar se hace con «Deshacer»: se
/// oculta al momento y solo se borra en el servidor al cerrarse el aviso (o
/// al salir de la pantalla).
class RunDetailBloc extends Bloc<RunDetailEvent, RunDetailState> {
  RunDetailBloc({
    required this._get,
    required this._delete,
    required this._share,
  }) : super(const RunDetailState()) {
    on<RunDetailStarted>((e, emit) async {
      emit(state.copyWith(blockId: e.blockId, loading: true, error: null));
      final result = await _get(e.blockId);
      switch (result) {
        case Success(:final value):
          emit(state.copyWith(loading: false, run: value));
        case Failure(:final error):
          emit(state.copyWith(loading: false, error: error));
      }
    });
    on<RunDetailDeleteRequested>(
      (_, emit) => emit(state.copyWith(pendingDelete: true)),
    );
    on<RunDetailDeleteUndone>(
      (_, emit) => emit(state.copyWith(pendingDelete: false)),
    );
    on<RunDetailDeleteCommitted>((_, emit) async {
      if (!state.pendingDelete) return;
      final result = await _commitDelete();
      switch (result) {
        case Success():
          emit(state.copyWith(deleted: true));
        case Failure(:final error):
          emit(state.copyWith(pendingDelete: false, actionError: error));
          emit(state.copyWith(actionError: null));
      }
    });
    on<RunDetailShared>((e, emit) async {
      final result = await _share(
        png: e.png,
        fileName: 'synaptixfit-carrera.png',
        text: e.text,
      );
      if (result case Failure(:final error)) {
        emit(state.copyWith(actionError: error));
        emit(state.copyWith(actionError: null));
      }
    });
  }

  final GetRunUseCaseContract _get;
  final DeleteRunUseCaseContract _delete;
  final ShareAchievementImageUseCaseContract _share;
  bool _committed = false;

  Future<Result<Object?, AppError>> _commitDelete() async {
    final id = state.blockId;
    if (id == null || _committed) return const Success(null);
    _committed = true;
    final result = await _delete(id);
    if (result is Failure) _committed = false;
    return result;
  }

  @override
  Future<void> close() async {
    // Se sale con el borrado pendiente: se confirma (el aviso ya no se ve).
    if (state.pendingDelete && !state.deleted) await _commitDelete();
    return super.close();
  }
}
