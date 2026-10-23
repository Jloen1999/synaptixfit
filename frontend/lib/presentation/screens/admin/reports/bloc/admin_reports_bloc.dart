import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/admin/admin_report_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/admin_page.dart';
import '../../../../../domain/models/admin/reported_content.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/admin/dismiss_report_use_case.dart';
import '../../../../../domain/use_cases/admin/get_reported_content_use_case.dart';
import '../../../../../domain/use_cases/admin/remove_reported_content_use_case.dart';
import '../../widgets/admin_status.dart';

part 'admin_reports_bloc.freezed.dart';
part 'admin_reports_event.dart';
part 'admin_reports_state.dart';

/// Pestaña Contenido: cola de publicaciones y comentarios reportados.
class AdminReportsBloc extends Bloc<AdminReportsEvent, AdminReportsState> {
  AdminReportsBloc({
    required this._getReports,
    required this._dismiss,
    required this._remove,
  }) : super(const AdminReportsState()) {
    on<AdminReportsStarted>((_, emit) => _load(emit, page: 0));
    on<AdminReportsRefreshed>((_, emit) => _load(emit, page: state.page));
    on<AdminReportsTypeChanged>(_onTypeChanged);
    on<AdminReportsPageRequested>((e, emit) => _load(emit, page: e.page));
    on<AdminReportsDismissRequested>(
      (e, emit) => _moderate(
        emit,
        e.item,
        dismissed: true,
        request: () => _dismiss(e.item.type, e.item.id),
      ),
    );
    on<AdminReportsRemoveRequested>(
      (e, emit) => _moderate(
        emit,
        e.item,
        dismissed: false,
        request: () => _remove(e.item.type, e.item.id),
      ),
    );
  }

  static const pageSize = 20;

  final GetReportedContentUseCaseContract _getReports;
  final DismissReportUseCaseContract _dismiss;
  final RemoveReportedContentUseCaseContract _remove;

  Future<void> _onTypeChanged(
    AdminReportsTypeChanged event,
    Emitter<AdminReportsState> emit,
  ) async {
    emit(state.copyWith(type: event.type));
    await _load(emit, page: 0);
  }

  Future<void> _load(
    Emitter<AdminReportsState> emit, {
    required int page,
  }) async {
    emit(state.copyWith(status: AdminStatus.loading, page: page, error: null));
    final result = await _getReports(
      type: state.type,
      page: page,
      size: pageSize,
    );
    emit(
      result.fold(
        (reports) =>
            state.copyWith(status: AdminStatus.ready, reports: reports),
        (error) => state.copyWith(status: AdminStatus.failure, error: error),
      ),
    );
  }

  Future<void> _moderate(
    Emitter<AdminReportsState> emit,
    ReportedContent item, {
    required bool dismissed,
    required Future<AppResult<Unit>> Function() request,
  }) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: item.id, effect: null));
    final result = await request();
    final error = result.errorOrNull;
    if (error != null) {
      emit(
        state.copyWith(busyId: null, effect: AdminReportsEffect.failure(error)),
      );
      return;
    }
    // Si se vacía la última página, se retrocede una.
    final reports = state.reports;
    final page = reports != null && reports.items.length == 1 && state.page > 0
        ? state.page - 1
        : state.page;
    emit(state.copyWith(busyId: null));
    await _load(emit, page: page);
    emit(
      state.copyWith(
        effect: dismissed
            ? const AdminReportsEffect.dismissed()
            : const AdminReportsEffect.removed(),
      ),
    );
  }
}
