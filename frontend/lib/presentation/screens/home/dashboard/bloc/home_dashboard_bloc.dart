import '../../../../../domain/models/home/home_setup.dart';
import '../../../../../domain/use_cases/home/get_home_setup_use_case.dart';
import '../../../../../domain/use_cases/home/snooze_home_setup_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/enums/home_event_kind.dart';
import '../../../../../domain/enums/home_event_type.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/home/home_dashboard.dart';
import '../../../../../domain/models/home/home_due_review.dart';
import '../../../../../domain/models/planner/weekly_planning.dart';
import '../../../../../domain/use_cases/home/get_home_dashboard_use_case.dart';
import '../../../../../domain/use_cases/home/get_home_due_reviews_use_case.dart';
import '../../../../../domain/use_cases/home/get_home_onboarding_status_use_case.dart';
import '../../../../../domain/use_cases/home/get_home_unread_count_use_case.dart';
import '../../../../../domain/use_cases/planner/get_timeline_use_case.dart';
import '../../../../../domain/use_cases/planner/reschedule_block_to_next_free_slot_use_case.dart';
import '../../../../../domain/use_cases/planner/set_block_completion_use_case.dart';
import '../../../../../domain/use_cases/training/start_session_use_case.dart';
import '../../home_onboarding_gate.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'home_dashboard_bloc.freezed.dart';
part 'home_dashboard_event.dart';
part 'home_dashboard_state.dart';

/// Pestaña Inicio: resumen del día, agenda de los próximos días (planificador),
/// repasos, campana y onboarding. Se refresca sola con cualquier cambio de
/// datos; las insignias y el nivel se celebran en el armazón (`AchievementsBloc`).
class HomeDashboardBloc extends Bloc<HomeDashboardEvent, HomeDashboardState>
    with DataChangeRefreshMixin<HomeDashboardEvent, HomeDashboardState> {
  HomeDashboardBloc({
    required this._getDashboard,
    required this._getDueReviews,
    required this._getUnreadCount,
    required this._getOnboardingStatus,
    required this._getSetup,
    required this._snoozeSetup,
    required this._getTimeline,
    required this._onboardingGate,
    required this._watchChanges,
    required this._startSession,
    required this._setBlockCompletion,
    required this._rescheduleToNextSlot,
    this._clock = DateTime.now,
  }) : super(const HomeDashboardState()) {
    on<HomeDashboardStarted>(_onStarted);
    on<HomeDashboardRefreshed>(_onRefreshed);
    on<HomeDashboardOnboardingHandled>(
      (_, emit) => emit(state.copyWith(onboardingRequired: false)),
    );
    on<HomeDashboardTrainingStarted>(_onTrainingStarted);
    on<HomeDashboardSetupSnoozed>(_onSetupSnoozed);
    on<HomeDashboardBannerBlockCompleted>(_onBannerBlockCompleted);
    on<HomeDashboardBannerBlockRescheduled>(_onBannerBlockRescheduled);
    on<HomeDashboardBannerNoticeHandled>(
      (_, emit) => emit(state.copyWith(bannerNotice: null)),
    );
    on<HomeDashboardTrainingHandled>(
      (_, emit) =>
          emit(state.copyWith(openSessionId: null, trainingError: null)),
    );
  }

  /// Número de repasos urgentes que se muestran.
  static const dueReviewsLimit = 5;

  /// Días que abarca la agenda, hoy incluido.
  static const agendaDays = 7;

  final GetHomeDashboardUseCaseContract _getDashboard;
  final GetHomeDueReviewsUseCaseContract _getDueReviews;
  final GetHomeUnreadCountUseCaseContract _getUnreadCount;
  final GetHomeOnboardingStatusUseCaseContract _getOnboardingStatus;
  final GetHomeSetupUseCaseContract _getSetup;
  final SnoozeHomeSetupUseCaseContract _snoozeSetup;
  final GetTimelineUseCaseContract _getTimeline;
  final DateTime Function() _clock;
  final HomeOnboardingGate _onboardingGate;
  final WatchDataChangesUseCaseContract _watchChanges;
  final StartSessionUseCaseContract _startSession;
  final SetBlockCompletionUseCaseContract _setBlockCompletion;
  final RescheduleBlockToNextFreeSlotUseCaseContract _rescheduleToNextSlot;

  /// La XP y el hueco los decide el servidor; Inicio se refresca solo con el
  /// cambio de datos del planificador.
  Future<void> _onBannerBlockCompleted(
    HomeDashboardBannerBlockCompleted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (state.bannerBusy != null) return;
    emit(state.copyWith(bannerBusy: HomeBannerAction.complete));
    final result = await _setBlockCompletion(event.blockId, completed: true);
    emit(
      state.copyWith(
        bannerBusy: null,
        bannerNotice: result.fold(
          (value) => HomeBannerNotice.completed(value.xpDelta),
          HomeBannerNotice.failed,
        ),
      ),
    );
  }

  Future<void> _onBannerBlockRescheduled(
    HomeDashboardBannerBlockRescheduled event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (state.bannerBusy != null) return;
    emit(state.copyWith(bannerBusy: HomeBannerAction.reschedule));
    final result = await _rescheduleToNextSlot(event.blockId);
    emit(
      state.copyWith(
        bannerBusy: null,
        bannerNotice: result.fold(
          (value) => HomeBannerNotice.rescheduled(value.block.start),
          HomeBannerNotice.failed,
        ),
      ),
    );
  }

  /// Usuario de la sesión (llega en `started`): el «Ahora no» es suyo.
  String _userId = '';

  /// «Ahora no»: se oculta hasta la fecha que devuelve el caso de uso (si no
  /// se pudo guardar, sigue a la vista).
  Future<void> _onSetupSnoozed(
    HomeDashboardSetupSnoozed event,
    Emitter<HomeDashboardState> emit,
  ) async {
    final setup = state.setup;
    if (setup == null) return;
    final now = _clock();
    final until = (await _snoozeSetup(now, userId: _userId)).valueOrNull;
    if (until == null) return;
    emit(state.copyWith(setup: setup.copyWith(snoozedUntil: until)));
  }

  Future<void> _onTrainingStarted(
    HomeDashboardTrainingStarted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (state.startingTraining) return;
    emit(state.copyWith(startingTraining: true));
    final result = await _startSession(
      routineId: event.routineId,
      dayId: event.dayId,
    );
    emit(
      result.fold(
        (session) =>
            state.copyWith(startingTraining: false, openSessionId: session.id),
        (error) =>
            state.copyWith(startingTraining: false, trainingError: error),
      ),
    );
  }

  Future<void> _onStarted(
    HomeDashboardStarted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    _userId = event.userId;
    // Inicio resume todos los módulos: cualquier cambio le afecta.
    watchDataChanges(
      _watchChanges,
      topics: DataTopic.values.toSet(),
      onChanged: const HomeDashboardEvent.refreshed(),
    );
    if (state.status != HomeDashboardStatus.loading) {
      emit(state.copyWith(status: HomeDashboardStatus.loading, error: null));
    }
    final loaded = await _load(emit);
    if (!loaded) return;
    if (event.userId.isNotEmpty && _onboardingGate.shouldCheck(event.userId)) {
      final status = await _getOnboardingStatus();
      if (status.valueOrNull?.completed == false) {
        emit(state.copyWith(onboardingRequired: true));
      }
    }
  }

  Future<void> _onRefreshed(
    HomeDashboardRefreshed event,
    Emitter<HomeDashboardState> emit,
  ) async {
    emit(
      state.dashboard == null
          ? state.copyWith(status: HomeDashboardStatus.loading, error: null)
          : state.copyWith(refreshing: true, error: null),
    );
    await _load(emit);
  }

  /// Carga el resumen, los repasos, la agenda y el contador en paralelo. Solo
  /// el resumen es obligatorio: si fallan los demás se muestran vacíos.
  Future<bool> _load(Emitter<HomeDashboardState> emit) async {
    // Hoy sale del resumen del servidor; la agenda trae los días siguientes.
    final now = _clock();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dashboardFuture = _getDashboard();
    final reviewsFuture = _getDueReviews(limit: dueReviewsLimit);
    final unreadFuture = _getUnreadCount();
    final setupFuture = _getSetup(userId: _userId);
    final upcomingFuture = _getTimeline(
      from: tomorrow,
      to: DateTime(now.year, now.month, now.day + agendaDays),
    );
    final dashboard = await dashboardFuture;
    final reviews = await reviewsFuture;
    final unread = await unreadFuture;
    final upcoming = await upcomingFuture;
    final setup = await setupFuture;

    return dashboard.fold(
      (value) {
        emit(
          state.copyWith(
            status: HomeDashboardStatus.loaded,
            dashboard: value,
            error: null,
            refreshing: false,
            dueReviews: reviews.valueOrNull ?? state.dueReviews,
            unreadNotifications:
                unread.valueOrNull ?? state.unreadNotifications,
            upcoming:
                upcoming.valueOrNull?.map(_toEvent).toList() ?? state.upcoming,
            setup: setup.valueOrNull ?? state.setup,
          ),
        );
        return true;
      },
      (error) {
        emit(
          state.copyWith(
            status: state.dashboard == null
                ? HomeDashboardStatus.failure
                : HomeDashboardStatus.loaded,
            error: error,
            refreshing: false,
          ),
        );
        return false;
      },
    );
  }

  /// La agenda pinta bloques y entregas igual que los eventos de hoy.
  static HomeTodayEvent _toEvent(TimelineEntry entry) {
    final isDeadline = entry.kind == TimelineKind.deadline;
    return HomeTodayEvent(
      id: entry.id,
      kind: isDeadline ? HomeEventKind.deadline : HomeEventKind.block,
      type: isDeadline
          ? switch (entry.deadlineType) {
              DeadlineType.exam => HomeEventType.exam,
              DeadlineType.assignment => HomeEventType.delivery,
              DeadlineType.presentation => HomeEventType.presentation,
              DeadlineType.other || null => HomeEventType.other,
            }
          : switch (entry.blockType) {
              BlockType.study => HomeEventType.study,
              BlockType.sport => HomeEventType.sport,
              BlockType.classSession => HomeEventType.classSession,
              BlockType.rest => HomeEventType.rest,
              BlockType.meal => HomeEventType.meal,
              BlockType.sleep => HomeEventType.sleep,
              BlockType.exam => HomeEventType.exam,
              BlockType.delivery => HomeEventType.delivery,
              BlockType.review => HomeEventType.review,
              null => HomeEventType.other,
            },
      // Sin título, la agenda muestra el tipo («Estudio», «Deporte»...).
      title: entry.title ?? entry.subjectName ?? '',
      start: entry.start,
      end: entry.end,
      completed: entry.completed,
      subjectName: entry.subjectName,
    );
  }
}
