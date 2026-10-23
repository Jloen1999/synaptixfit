import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/admin_page.dart';
import '../../../../../domain/models/admin/admin_queries.dart';
import '../../../../../domain/models/admin/audit_entry.dart';
import '../../../../../domain/use_cases/admin/search_audit_log_use_case.dart';
import '../../widgets/admin_status.dart';

part 'admin_audit_bloc.freezed.dart';
part 'admin_audit_event.dart';
part 'admin_audit_state.dart';

/// Pestaña Auditoría: registro paginado con filtros.
class AdminAuditBloc extends Bloc<AdminAuditEvent, AdminAuditState> {
  AdminAuditBloc({required this._search}) : super(const AdminAuditState()) {
    on<AdminAuditStarted>((_, emit) => _load(emit, page: 0));
    on<AdminAuditRefreshed>((_, emit) => _load(emit, page: state.page));
    on<AdminAuditQueryChanged>(_onQueryChanged);
    on<AdminAuditPageRequested>((e, emit) => _load(emit, page: e.page));
  }

  static const pageSize = 25;

  final SearchAuditLogUseCaseContract _search;

  Future<void> _onQueryChanged(
    AdminAuditQueryChanged event,
    Emitter<AdminAuditState> emit,
  ) async {
    emit(state.copyWith(query: event.query));
    await _load(emit, page: 0);
  }

  Future<void> _load(Emitter<AdminAuditState> emit, {required int page}) async {
    emit(state.copyWith(status: AdminStatus.loading, page: page, error: null));
    final result = await _search(
      query: state.query,
      page: page,
      size: pageSize,
    );
    emit(
      result.fold(
        (entries) =>
            state.copyWith(status: AdminStatus.ready, entries: entries),
        (error) => state.copyWith(status: AdminStatus.failure, error: error),
      ),
    );
  }
}
