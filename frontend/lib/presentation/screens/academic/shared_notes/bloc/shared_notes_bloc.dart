import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/shared_notes_scope.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/use_cases/academic/get_shared_notes_use_case.dart';

part 'shared_notes_bloc.freezed.dart';
part 'shared_notes_event.dart';
part 'shared_notes_state.dart';

/// Lista paginada de apuntes compartidos de un ámbito (amigos o comunidad) o
/// de un autor. Usa [GetSharedNotesUseCaseContract]; cada pestaña tiene el suyo.
class SharedNotesBloc extends Bloc<SharedNotesEvent, SharedNotesState> {
  SharedNotesBloc({required this._getShared})
    : super(const SharedNotesState()) {
    on<SharedNotesStarted>(_onStarted);
    on<SharedNotesRefreshed>(_onRefreshed);
    on<SharedNotesMoreRequested>(_onMore);
  }

  final GetSharedNotesUseCaseContract _getShared;

  Future<void> _onStarted(
    SharedNotesStarted event,
    Emitter<SharedNotesState> emit,
  ) async {
    emit(SharedNotesState(scope: event.scope, authorId: event.authorId));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    SharedNotesRefreshed event,
    Emitter<SharedNotesState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: state.items.isEmpty,
        refreshing: true,
        error: null,
      ),
    );
    await _load(emit);
    emit(state.copyWith(refreshing: false));
  }

  Future<void> _load(Emitter<SharedNotesState> emit) async {
    final result = await _getShared(
      page: 0,
      scope: state.scope,
      authorId: state.authorId,
    );
    emit(
      result.fold(
        (page) => state.copyWith(
          loading: false,
          error: null,
          items: page.items,
          page: 0,
          hasMore: page.hasMore,
        ),
        (error) => state.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onMore(
    SharedNotesMoreRequested event,
    Emitter<SharedNotesState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true, loadMoreError: null));
    final next = state.page + 1;
    final result = await _getShared(
      page: next,
      scope: state.scope,
      authorId: state.authorId,
    );
    emit(
      result.fold(
        (page) => state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items],
          page: next,
          hasMore: page.hasMore,
        ),
        // Se conserva hasMore: la lista muestra el error con «Reintentar».
        (error) => state.copyWith(loadingMore: false, loadMoreError: error),
      ),
    );
  }
}
