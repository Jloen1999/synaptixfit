import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/user_role.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/admin_user.dart';
import '../../../../../domain/models/admin/admin_user_stats.dart';
import '../../../../../domain/models/admin/erasure_report.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/use_cases/admin/anonymize_admin_user_use_case.dart';
import '../../../../../domain/use_cases/admin/change_admin_user_role_use_case.dart';
import '../../../../../domain/use_cases/admin/delete_admin_user_use_case.dart';
import '../../../../../domain/use_cases/admin/export_admin_user_data_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_user_activity_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_user_detail_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_user_stats_use_case.dart';
import '../../../../../domain/use_cases/admin/get_admin_user_timeline_use_case.dart';
import '../../../../../domain/use_cases/admin/set_admin_user_progress_use_case.dart';
import '../../../../../domain/use_cases/admin/set_admin_user_shadowban_use_case.dart';
import '../../../../../domain/use_cases/admin/update_admin_user_identity_use_case.dart';
import '../../../../../domain/use_cases/admin/wipe_admin_user_use_case.dart';
import '../../widgets/admin_status.dart';

part 'admin_user_detail_bloc.freezed.dart';
part 'admin_user_detail_event.dart';
part 'admin_user_detail_state.dart';

/// Casos de uso que necesita el detalle de usuario.
class AdminUserDetailUseCases {
  const AdminUserDetailUseCases({
    required this.getDetail,
    required this.getStats,
    required this.getActivity,
    required this.getTimeline,
    required this.updateIdentity,
    required this.setProgress,
    required this.changeRole,
    required this.setShadowban,
    required this.wipe,
    required this.anonymize,
    required this.delete,
    required this.export,
  });

  final GetAdminUserDetailUseCaseContract getDetail;
  final GetAdminUserStatsUseCaseContract getStats;
  final GetAdminUserActivityUseCaseContract getActivity;
  final GetAdminUserTimelineUseCaseContract getTimeline;
  final UpdateAdminUserIdentityUseCaseContract updateIdentity;
  final SetAdminUserProgressUseCaseContract setProgress;
  final ChangeAdminUserRoleUseCaseContract changeRole;
  final SetAdminUserShadowbanUseCaseContract setShadowban;
  final WipeAdminUserUseCaseContract wipe;
  final AnonymizeAdminUserUseCaseContract anonymize;
  final DeleteAdminUserUseCaseContract delete;
  final ExportAdminUserDataUseCaseContract export;
}

/// Detalle de un usuario: perfil, estadísticas, línea de tiempo y acciones.
class AdminUserDetailBloc
    extends Bloc<AdminUserDetailEvent, AdminUserDetailState> {
  AdminUserDetailBloc(this._useCases) : super(const AdminUserDetailState()) {
    on<AdminUserDetailStarted>(_onStarted);
    on<AdminUserDetailRefreshed>((_, emit) => _loadAll(emit));
    on<AdminUserDetailTimelineMoreRequested>(_onTimelineMore);
    on<AdminUserDetailIdentityUpdated>(
      (e, emit) => _accountAction(
        emit,
        AdminUserAction.identity,
        () => _useCases.updateIdentity(
          state.userId,
          fullName: e.fullName,
          email: e.email,
        ),
      ),
    );
    on<AdminUserDetailProgressSet>(
      (e, emit) => _accountAction(
        emit,
        AdminUserAction.progress,
        () => _useCases.setProgress(
          state.userId,
          level: e.level,
          levelXp: e.levelXp,
        ),
      ),
    );
    on<AdminUserDetailRoleChanged>(
      (e, emit) => _accountAction(
        emit,
        AdminUserAction.role,
        () => _useCases.changeRole(state.userId, e.role),
      ),
    );
    on<AdminUserDetailShadowbanChanged>(
      (e, emit) => _accountAction(
        emit,
        AdminUserAction.shadowban,
        () =>
            _useCases.setShadowban(state.userId, shadowbanned: e.shadowbanned),
      ),
    );
    on<AdminUserDetailWipeRequested>(
      (_, emit) => _erasure(emit, AdminUserAction.wipe, _useCases.wipe.call),
    );
    on<AdminUserDetailAnonymizeRequested>(
      (_, emit) =>
          _erasure(emit, AdminUserAction.anonymize, _useCases.anonymize.call),
    );
    on<AdminUserDetailDeleteRequested>(
      (_, emit) =>
          _erasure(emit, AdminUserAction.delete, _useCases.delete.call),
    );
    on<AdminUserDetailExportRequested>(_onExport);
  }

  /// Tamaño de página de la línea de tiempo y semanas del gráfico.
  static const timelinePageSize = 20;
  static const activityWeeks = 12;

  final AdminUserDetailUseCases _useCases;

  Future<void> _onStarted(
    AdminUserDetailStarted event,
    Emitter<AdminUserDetailState> emit,
  ) async {
    emit(state.copyWith(userId: event.userId));
    await _loadAll(emit);
  }

  Future<void> _loadAll(Emitter<AdminUserDetailState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading, error: null));
    final userId = state.userId;
    final (detail, stats, activity, timeline) = await (
      _useCases.getDetail(userId),
      _useCases.getStats(userId),
      _useCases.getActivity(userId, weeks: activityWeeks),
      _useCases.getTimeline(userId, page: 0, size: timelinePageSize),
    ).wait;

    final detailError = detail.errorOrNull;
    if (detailError != null) {
      emit(state.copyWith(status: AdminStatus.failure, error: detailError));
      return;
    }
    final page = timeline.valueOrNull;
    emit(
      state.copyWith(
        status: AdminStatus.ready,
        detail: detail.valueOrNull,
        stats: stats.valueOrNull,
        activity: activity.valueOrNull ?? const [],
        statsError: stats.errorOrNull ?? activity.errorOrNull,
        timeline: page?.items ?? const [],
        timelinePage: 0,
        timelineHasMore: page?.hasNext ?? false,
        timelineError: timeline.errorOrNull,
      ),
    );
  }

  Future<void> _onTimelineMore(
    AdminUserDetailTimelineMoreRequested event,
    Emitter<AdminUserDetailState> emit,
  ) async {
    if (state.timelineLoading) return;
    final next = state.timeline.isEmpty && state.timelineError != null
        ? 0
        : state.timelinePage + 1;
    emit(state.copyWith(timelineLoading: true, timelineError: null));
    final result = await _useCases.getTimeline(
      state.userId,
      page: next,
      size: timelinePageSize,
    );
    emit(
      result.fold(
        (page) => state.copyWith(
          timelineLoading: false,
          timeline: next == 0 ? page.items : [...state.timeline, ...page.items],
          timelinePage: next,
          timelineHasMore: page.hasNext,
        ),
        (error) => state.copyWith(timelineLoading: false, timelineError: error),
      ),
    );
  }

  Future<void> _accountAction(
    Emitter<AdminUserDetailState> emit,
    AdminUserAction action,
    Future<AppResult<AdminUserAccount>> Function() request,
  ) async {
    final detail = state.detail;
    if (detail == null || state.busyAction != null) return;
    emit(state.copyWith(busyAction: action, effect: null));
    final result = await request();
    emit(
      result.fold(
        (account) => state.copyWith(
          busyAction: null,
          detail: detail.copyWith(account: account),
          effect: AdminUserEffect.saved(action),
        ),
        (error) => state.copyWith(
          busyAction: null,
          effect: AdminUserEffect.failure(error),
        ),
      ),
    );
  }

  Future<void> _erasure(
    Emitter<AdminUserDetailState> emit,
    AdminUserAction action,
    Future<AppResult<ErasureReport>> Function(String userId) request,
  ) async {
    if (state.busyAction != null) return;
    emit(state.copyWith(busyAction: action, effect: null));
    final result = await request(state.userId);
    final report = result.valueOrNull;
    if (report == null) {
      emit(
        state.copyWith(
          busyAction: null,
          effect: AdminUserEffect.failure(result.errorOrNull!),
        ),
      );
      return;
    }
    emit(state.copyWith(busyAction: null));
    // Tras vaciar o anonimizar la cuenta sigue existiendo: se recargan los datos.
    if (action != AdminUserAction.delete) await _loadAll(emit);
    emit(state.copyWith(effect: AdminUserEffect.erased(action, report)));
  }

  Future<void> _onExport(
    AdminUserDetailExportRequested event,
    Emitter<AdminUserDetailState> emit,
  ) async {
    if (state.busyAction != null) return;
    emit(state.copyWith(busyAction: AdminUserAction.export, effect: null));
    final result = await _useCases.export(state.userId);
    emit(
      state.copyWith(
        busyAction: null,
        effect: result.fold(AdminUserEffect.exported, AdminUserEffect.failure),
      ),
    );
  }
}
