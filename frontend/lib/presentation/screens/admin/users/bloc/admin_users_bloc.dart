import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/admin/admin_page.dart';
import '../../../../../domain/models/admin/admin_queries.dart';
import '../../../../../domain/models/admin/admin_user.dart';
import '../../../../../domain/use_cases/admin/search_admin_users_use_case.dart';
import '../../widgets/admin_status.dart';

part 'admin_users_bloc.freezed.dart';
part 'admin_users_event.dart';
part 'admin_users_state.dart';

/// Pestaña Usuarios: búsqueda con filtros, orden y paginación.
class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  AdminUsersBloc({required this._searchUsers})
    : super(const AdminUsersState()) {
    on<AdminUsersStarted>((_, emit) => _load(emit, page: 0));
    on<AdminUsersRefreshed>((_, emit) => _load(emit, page: state.page));
    on<AdminUsersQueryChanged>(_onQueryChanged);
    on<AdminUsersPageRequested>((e, emit) => _load(emit, page: e.page));
  }

  /// Tamaño de página del listado.
  static const pageSize = 20;

  final SearchAdminUsersUseCaseContract _searchUsers;

  Future<void> _onQueryChanged(
    AdminUsersQueryChanged event,
    Emitter<AdminUsersState> emit,
  ) async {
    if (event.query == state.query && state.status == AdminStatus.ready) {
      return;
    }
    emit(state.copyWith(query: event.query));
    await _load(emit, page: 0);
  }

  Future<void> _load(Emitter<AdminUsersState> emit, {required int page}) async {
    emit(state.copyWith(status: AdminStatus.loading, page: page, error: null));
    final result = await _searchUsers(
      query: state.query,
      page: page,
      size: pageSize,
    );
    emit(
      result.fold(
        (users) => state.copyWith(status: AdminStatus.ready, users: users),
        (error) => state.copyWith(status: AdminStatus.failure, error: error),
      ),
    );
  }
}
