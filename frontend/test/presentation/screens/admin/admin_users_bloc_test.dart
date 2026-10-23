import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/admin/admin_user_sort.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/admin/admin_queries.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/admin/search_admin_users_use_case.dart';
import 'package:synaptixfit/presentation/screens/admin/users/bloc/admin_users_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/widgets/admin_status.dart';

import 'admin_fixtures.dart';

class _MockSearch extends Mock implements SearchAdminUsersUseCaseContract {}

void main() {
  late _MockSearch search;
  final users = pageOf([summary], totalPages: 3);

  setUpAll(() => registerFallbackValue(const AdminUserQuery()));

  setUp(() {
    search = _MockSearch();
    when(
      () => search(
        query: any(named: 'query'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Success(users));
  });

  AdminUsersBloc build() => AdminUsersBloc(searchUsers: search);

  blocTest<AdminUsersBloc, AdminUsersState>(
    'started carga la primera página',
    build: build,
    act: (bloc) => bloc.add(const AdminUsersEvent.started()),
    expect: () => [
      const AdminUsersState(status: AdminStatus.loading),
      AdminUsersState(status: AdminStatus.ready, users: users),
    ],
    verify: (_) => verify(
      () => search(
        query: const AdminUserQuery(),
        page: 0,
        size: AdminUsersBloc.pageSize,
      ),
    ).called(1),
  );

  blocTest<AdminUsersBloc, AdminUsersState>(
    'emite failure con el error del caso de uso',
    setUp: () => when(
      () => search(
        query: any(named: 'query'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.forbidden())),
    build: build,
    act: (bloc) => bloc.add(const AdminUsersEvent.started()),
    expect: () => const [
      AdminUsersState(status: AdminStatus.loading),
      AdminUsersState(status: AdminStatus.failure, error: AppError.forbidden()),
    ],
  );

  blocTest<AdminUsersBloc, AdminUsersState>(
    'cambiar los filtros vuelve a la página 0 con la nueva consulta',
    build: build,
    seed: () =>
        AdminUsersState(status: AdminStatus.ready, page: 2, users: users),
    act: (bloc) => bloc.add(
      const AdminUsersEvent.queryChanged(
        AdminUserQuery(
          text: 'ana',
          role: UserRole.admin,
          sort: AdminUserSort.level,
        ),
      ),
    ),
    verify: (bloc) {
      expect(bloc.state.page, 0);
      expect(bloc.state.query.role, UserRole.admin);
      verify(
        () => search(
          query: const AdminUserQuery(
            text: 'ana',
            role: UserRole.admin,
            sort: AdminUserSort.level,
          ),
          page: 0,
          size: AdminUsersBloc.pageSize,
        ),
      ).called(1);
    },
  );

  blocTest<AdminUsersBloc, AdminUsersState>(
    'una consulta idéntica no vuelve a buscar',
    build: build,
    seed: () => AdminUsersState(status: AdminStatus.ready, users: users),
    act: (bloc) =>
        bloc.add(const AdminUsersEvent.queryChanged(AdminUserQuery())),
    expect: () => const <AdminUsersState>[],
  );

  blocTest<AdminUsersBloc, AdminUsersState>(
    'pageRequested pide la página indicada y refreshed la repite',
    build: build,
    act: (bloc) => bloc
      ..add(const AdminUsersEvent.pageRequested(1))
      ..add(const AdminUsersEvent.refreshed()),
    verify: (_) => verify(
      () => search(
        query: const AdminUserQuery(),
        page: 1,
        size: AdminUsersBloc.pageSize,
      ),
    ).called(2),
  );
}
