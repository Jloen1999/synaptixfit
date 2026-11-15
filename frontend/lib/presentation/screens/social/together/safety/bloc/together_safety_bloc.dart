import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/use_cases/social/block_user_use_case.dart';
import '../../../../../../domain/use_cases/social/together/report_user_use_case.dart';

part 'together_safety_bloc.freezed.dart';
part 'together_safety_event.dart';
part 'together_safety_state.dart';

/// Bloquear y denunciar en un toque desde cada pantalla de «Con amigos»
/// (ADR 0044). Bloquear usa el caso de uso de siempre; el servidor saca a las
/// dos personas de lo que compartían.
class TogetherSafetyBloc
    extends Bloc<TogetherSafetyEvent, TogetherSafetyState> {
  TogetherSafetyBloc({required this._block, required this._report})
    : super(const TogetherSafetyState()) {
    on<TogetherSafetyBlockRequested>(_onBlock);
    on<TogetherSafetyReportRequested>(_onReport);
  }

  final BlockUserUseCaseContract _block;
  final ReportUserUseCaseContract _report;

  Future<void> _onBlock(
    TogetherSafetyBlockRequested event,
    Emitter<TogetherSafetyState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _block(userId: event.userId);
    emit(switch (result) {
      Success() => state.copyWith(
        busy: false,
        done: TogetherSafetyDone.blocked,
        blockedId: event.userId,
      ),
      Failure(:final error) => state.copyWith(busy: false, error: error),
    });
    emit(state.copyWith(done: null, error: null));
  }

  Future<void> _onReport(
    TogetherSafetyReportRequested event,
    Emitter<TogetherSafetyState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _report(event.userId, context: event.context);
    emit(switch (result) {
      Success() => state.copyWith(
        busy: false,
        done: TogetherSafetyDone.reported,
      ),
      Failure(:final error) => state.copyWith(busy: false, error: error),
    });
    emit(state.copyWith(done: null, error: null));
  }
}
