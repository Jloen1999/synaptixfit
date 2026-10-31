import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/planner/calendar_feed.dart';
import '../../../../../domain/models/planner/planner_ai.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/planner/create_calendar_feed_use_case.dart';
import '../../../../../domain/use_cases/planner/get_calendar_feed_use_case.dart';
import '../../../../../domain/use_cases/planner/import_general_calendar_use_case.dart';
import '../../../../../domain/use_cases/planner/revoke_calendar_feed_use_case.dart';

part 'calendar_sync_bloc.freezed.dart';
part 'calendar_sync_event.dart';
part 'calendar_sync_state.dart';

/// Sincronizar calendarios: el enlace para ver el planificador en Google,
/// Apple u Outlook y la importación de exámenes y entregas del Campus Virtual.
class CalendarSyncBloc extends Bloc<CalendarSyncEvent, CalendarSyncState> {
  CalendarSyncBloc({
    required this._getFeed,
    required this._createFeed,
    required this._revokeFeed,
    required this._importGeneral,
  }) : super(const CalendarSyncState()) {
    on<CalendarSyncStarted>(_onStarted);
    on<CalendarSyncFeedCreated>(_onCreated);
    on<CalendarSyncFeedRevoked>(_onRevoked);
    on<CalendarSyncImportRequested>(_onImport);
  }

  final GetCalendarFeedUseCaseContract _getFeed;
  final CreateCalendarFeedUseCaseContract _createFeed;
  final RevokeCalendarFeedUseCaseContract _revokeFeed;
  final ImportGeneralCalendarUseCaseContract _importGeneral;

  Future<void> _onStarted(
    CalendarSyncStarted event,
    Emitter<CalendarSyncState> emit,
  ) async {
    emit(state.copyWith(status: CalendarSyncStatus.loading, error: null));
    final result = await _getFeed();
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: CalendarSyncStatus.ready,
        feed: value,
      ),
      Failure(:final error) => state.copyWith(
        status: CalendarSyncStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onCreated(
    CalendarSyncFeedCreated event,
    Emitter<CalendarSyncState> emit,
  ) async {
    if (state.feedBusy) return;
    emit(state.copyWith(feedAction: CalendarFeedAction.creating));
    final result = await _createFeed();
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        feedAction: null,
        link: value,
        feed: CalendarFeedStatus(active: true, activeSince: value.createdAt),
      ),
      Failure(:final error) => _failed(state.copyWith(feedAction: null), error),
    });
  }

  Future<void> _onRevoked(
    CalendarSyncFeedRevoked event,
    Emitter<CalendarSyncState> emit,
  ) async {
    if (state.feedBusy) return;
    emit(state.copyWith(feedAction: CalendarFeedAction.revoking));
    final result = await _revokeFeed();
    emit(switch (result) {
      Success() => state.copyWith(
        feedAction: null,
        link: null,
        feed: const CalendarFeedStatus(),
        revokedCount: state.revokedCount + 1,
      ),
      // Si ya no existía (otro dispositivo lo desactivó), se recarga el estado.
      Failure(error: BusinessError(code: 'PLANNER_CALENDAR_FEED_NOT_FOUND')) =>
        _failed(
          state.copyWith(
            feedAction: null,
            link: null,
            feed: const CalendarFeedStatus(),
          ),
          const AppError.business('PLANNER_CALENDAR_FEED_NOT_FOUND'),
        ),
      Failure(:final error) => _failed(state.copyWith(feedAction: null), error),
    });
  }

  Future<void> _onImport(
    CalendarSyncImportRequested event,
    Emitter<CalendarSyncState> emit,
  ) async {
    final url = event.url.trim();
    if (state.importing) return;
    if (url.isEmpty) {
      emit(state.copyWith(urlMissing: true, importError: null));
      return;
    }
    emit(
      state.copyWith(
        importing: true,
        urlMissing: false,
        importResult: null,
        importError: null,
      ),
    );
    final result = await _importGeneral(url: url);
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        importing: false,
        importResult: value,
      ),
      Failure(:final error) => state.copyWith(
        importing: false,
        importError: error,
      ),
    });
  }

  static CalendarSyncState _failed(CalendarSyncState s, AppError error) =>
      s.copyWith(actionError: error, actionErrorId: s.actionErrorId + 1);
}
