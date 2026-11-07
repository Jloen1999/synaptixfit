import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/deadline.dart';
import '../../../../../domain/models/planner/planner_options.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/create_deadline_use_case.dart';
import '../../../../../domain/use_cases/planner/delete_deadline_use_case.dart';
import '../../../../../domain/use_cases/planner/get_deadline_use_case.dart';
import '../../../../../domain/use_cases/planner/get_deadlines_use_case.dart';
import '../../../../../domain/use_cases/planner/get_planner_subjects_use_case.dart';
import '../../../../../domain/use_cases/planner/set_deadline_completion_use_case.dart';
import '../../../../../domain/use_cases/planner/update_deadline_use_case.dart';

part 'deadlines_bloc.freezed.dart';
part 'deadlines_event.dart';
part 'deadlines_state.dart';

/// Lista de entregas y exámenes con filtros, alta/edición, borrado y completado.
class DeadlinesBloc extends Bloc<DeadlinesEvent, DeadlinesState> {
  DeadlinesBloc({
    required this._getDeadlines,
    required this._getDeadline,
    required this._getSubjects,
    required this._createDeadline,
    required this._updateDeadline,
    required this._deleteDeadline,
    required this._setCompletion,
    required this._getAccount,
  }) : super(const DeadlinesState()) {
    on<DeadlinesStarted>(_onStarted);
    on<DeadlinesRefreshed>((_, emit) => _reload(emit, silent: true));
    on<DeadlinesPendingFilterChanged>(_onPendingFilter);
    on<DeadlinesSubjectFilterChanged>(_onSubjectFilter);
    on<DeadlinesMoreRequested>(_onMore);
    on<DeadlinesSaved>(_onSaved);
    on<DeadlinesDeleted>(_onDeleted);
    on<DeadlinesDeleteUndone>(_onDeleteUndone);
    on<DeadlinesDeleteCommitted>(_onDeleteCommitted);
    on<DeadlinesCompletionToggled>(_onCompletion);
  }

  final GetDeadlinesUseCaseContract _getDeadlines;
  final GetDeadlineUseCaseContract _getDeadline;
  final GetPlannerSubjectsUseCaseContract _getSubjects;
  final CreateDeadlineUseCaseContract _createDeadline;
  final UpdateDeadlineUseCaseContract _updateDeadline;
  final DeleteDeadlineUseCaseContract _deleteDeadline;
  final SetDeadlineCompletionUseCaseContract _setCompletion;
  final GetAccountUseCaseContract _getAccount;

  /// Borrados que aún se pueden deshacer, en orden (el último es el de Ctrl+Z).
  final Set<String> _pendingDeletes = {};

  DeadlinesState _notice(DeadlinesState next, DeadlinesNotice notice) =>
      next.copyWith(notice: notice, noticeId: state.noticeId + 1);

  Future<void> _onStarted(
    DeadlinesStarted event,
    Emitter<DeadlinesState> emit,
  ) async {
    final subjects = await _getSubjects();
    emit(
      state.copyWith(
        subjects: subjects.valueOrNull ?? const [],
        focusId: event.focusId,
      ),
    );
    await _reload(emit, silent: false);
  }

  Future<void> _reload(
    Emitter<DeadlinesState> emit, {
    required bool silent,
  }) async {
    if (!silent) {
      emit(state.copyWith(status: DeadlinesStatus.loading, error: null));
    }
    final pendingOnly = state.pendingOnly;
    final subjectId = state.subjectId;
    // «Pendientes» también enseña lo vencido sin entregar (primero).
    final result = await _getDeadlines(
      upcoming: pendingOnly,
      includeOverdue: pendingOnly,
      subjectId: subjectId,
    );
    // Filtros cambiados mientras se cargaba: manda la última petición.
    if (pendingOnly != state.pendingOnly || subjectId != state.subjectId) {
      return;
    }
    switch (result) {
      case Failure(:final error):
        emit(
          silent && state.status == DeadlinesStatus.ready
              ? _notice(state, DeadlinesNotice.failure(error))
              : state.copyWith(status: DeadlinesStatus.failure, error: error),
        );
      case Success(:final value):
        // Primero se resuelve la entrega del aviso: el estado se lee después
        // (mientras tanto pudo cambiar un filtro).
        final items = await _withFocusFirst(value.items);
        if (pendingOnly != state.pendingOnly || subjectId != state.subjectId) {
          return;
        }
        final focusId = state.focusId;
        emit(
          state.copyWith(
            status: DeadlinesStatus.ready,
            focusMissing: focusId != null && !items.any((d) => d.id == focusId),
            items: items,
            page: value.page,
            hasMore: value.hasMore,
            error: null,
          ),
        );
    }
  }

  /// La entrega del aviso va la primera; si no está entre las cargadas (otra
  /// página o ya entregada), se pide. Si ya no existe, la lista queda igual.
  Future<List<Deadline>> _withFocusFirst(List<Deadline> items) async {
    final id = state.focusId;
    if (id == null) return items;
    final focused =
        items.where((d) => d.id == id).firstOrNull ??
        (await _getDeadline(id)).valueOrNull;
    if (focused == null) return items;
    return [focused, ...items.where((d) => d.id != id)];
  }

  Future<void> _onPendingFilter(
    DeadlinesPendingFilterChanged event,
    Emitter<DeadlinesState> emit,
  ) async {
    if (event.pendingOnly == state.pendingOnly) return;
    emit(state.copyWith(pendingOnly: event.pendingOnly));
    await _reload(emit, silent: false);
  }

  Future<void> _onSubjectFilter(
    DeadlinesSubjectFilterChanged event,
    Emitter<DeadlinesState> emit,
  ) async {
    if (event.subjectId == state.subjectId) return;
    emit(state.copyWith(subjectId: event.subjectId));
    await _reload(emit, silent: false);
  }

  Future<void> _onMore(
    DeadlinesMoreRequested event,
    Emitter<DeadlinesState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    final result = await _getDeadlines(
      upcoming: state.pendingOnly,
      includeOverdue: state.pendingOnly,
      subjectId: state.subjectId,
      page: state.page + 1,
    );
    switch (result) {
      case Failure(:final error):
        emit(
          _notice(
            state.copyWith(loadingMore: false),
            DeadlinesNotice.failure(error),
          ),
        );
      case Success(:final value):
        emit(
          state.copyWith(
            loadingMore: false,
            items: [...state.items, ...value.items],
            page: value.page,
            hasMore: value.hasMore,
          ),
        );
    }
  }

  Future<void> _onSaved(
    DeadlinesSaved event,
    Emitter<DeadlinesState> emit,
  ) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true));
    final id = event.id;
    final result = id == null
        ? await _createDeadline(event.draft)
        : await _updateDeadline(id, event.draft);
    switch (result) {
      case Failure(:final error):
        emit(
          _notice(
            state.copyWith(saving: false),
            DeadlinesNotice.failure(error),
          ),
        );
      case Success():
        emit(
          _notice(
            state.copyWith(saving: false),
            DeadlinesNotice.saved(created: id == null),
          ),
        );
        await _reload(emit, silent: true);
    }
  }

  void _onDeleted(DeadlinesDeleted event, Emitter<DeadlinesState> emit) {
    if (!_pendingDeletes.add(event.id)) return;
    emit(
      _notice(
        state.copyWith(
          pendingDeletionIds: {...state.pendingDeletionIds, event.id},
        ),
        DeadlinesNotice.deleted(event.id),
      ),
    );
  }

  void _onDeleteUndone(
    DeadlinesDeleteUndone event,
    Emitter<DeadlinesState> emit,
  ) {
    if (!_pendingDeletes.remove(event.id)) return;
    emit(
      state.copyWith(
        pendingDeletionIds: {...state.pendingDeletionIds}..remove(event.id),
      ),
    );
  }

  Future<void> _onDeleteCommitted(
    DeadlinesDeleteCommitted event,
    Emitter<DeadlinesState> emit,
  ) async {
    if (!_pendingDeletes.remove(event.id)) return;
    final result = await _deleteDeadline(event.id);
    final pending = {...state.pendingDeletionIds}..remove(event.id);
    switch (result) {
      case Failure(:final error) when error is! NotFoundError:
        // No se pudo borrar: vuelve a verse y se avisa.
        emit(
          _notice(
            state.copyWith(pendingDeletionIds: pending),
            DeadlinesNotice.failure(error),
          ),
        );
      // Ya no existe (borrado desde otro dispositivo): el resultado es el mismo.
      case Success() || Failure():
        emit(
          state.copyWith(
            pendingDeletionIds: pending,
            items: state.items.where((d) => d.id != event.id).toList(),
          ),
        );
    }
  }

  /// Al salir de la pantalla, lo pendiente se borra ya. Si la app se cierra
  /// antes, no se borra nada: es la dirección segura.
  @override
  Future<void> close() async {
    final pending = [..._pendingDeletes];
    _pendingDeletes.clear();
    await Future.wait(pending.map((id) => _deleteDeadline(id)));
    return super.close();
  }

  Future<void> _onCompletion(
    DeadlinesCompletionToggled event,
    Emitter<DeadlinesState> emit,
  ) async {
    final current = state.items.where((d) => d.id == event.id).firstOrNull;
    if (current == null || state.busyIds.contains(event.id)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, event.id}));
    final result = await _setCompletion(
      event.id,
      completed: !current.completed,
    );
    final busy = {...state.busyIds}..remove(event.id);
    switch (result) {
      case Failure(:final error):
        emit(
          _notice(
            state.copyWith(busyIds: busy),
            DeadlinesNotice.failure(error),
          ),
        );
      case Success(:final value):
        final account = value.xpDelta == 0
            ? null
            : (await _getAccount()).valueOrNull;
        final updated = value.deadline;
        // Con el filtro «pendientes», una entrega completada sale de la lista.
        final items = state.pendingOnly && updated.completed
            ? state.items.where((d) => d.id != updated.id).toList()
            : [for (final d in state.items) d.id == updated.id ? updated : d];
        emit(
          _notice(
            state.copyWith(busyIds: busy, items: items),
            DeadlinesNotice.completion(
              completed: updated.completed,
              xpDelta: value.xpDelta,
              account: account,
            ),
          ),
        );
    }
  }
}
