import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/use_cases/academic/get_shared_notes_use_case.dart';

part 'shared_notes_bloc.freezed.dart';
part 'shared_notes_event.dart';
part 'shared_notes_state.dart';

/// Apuntes que comparten los amigos (paginado).
class SharedNotesBloc extends Bloc<SharedNotesEvent, SharedNotesState> {
  SharedNotesBloc({required this._getShared})
    : super(const SharedNotesState()) {
    on<SharedNotesStarted>(_onStarted);
    on<SharedNotesMoreRequested>(_onMore);
  }

  final GetSharedNotesUseCaseContract _getShared;

  Future<void> _onStarted(
    SharedNotesStarted event,
    Emitter<SharedNotesState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await _getShared(page: 0);
    emit(
      result.fold(
        (page) => state.copyWith(
          loading: false,
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
    emit(state.copyWith(loadingMore: true));
    final next = state.page + 1;
    final result = await _getShared(page: next);
    emit(
      result.fold(
        (page) => state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items],
          page: next,
          hasMore: page.hasMore,
        ),
        (_) => state.copyWith(loadingMore: false, hasMore: false),
      ),
    );
  }
}
