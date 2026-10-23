import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/admin/anonymize_admin_user_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/change_admin_user_role_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/delete_admin_user_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/export_admin_user_data_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_admin_user_activity_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_admin_user_detail_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_admin_user_stats_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_admin_user_timeline_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/set_admin_user_progress_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/set_admin_user_shadowban_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/update_admin_user_identity_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/wipe_admin_user_use_case.dart';
import 'package:synaptixfit/presentation/screens/admin/user_detail/bloc/admin_user_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/widgets/admin_status.dart';

import 'admin_fixtures.dart';

class _Detail extends Mock implements GetAdminUserDetailUseCaseContract {}

class _Stats extends Mock implements GetAdminUserStatsUseCaseContract {}

class _Activity extends Mock implements GetAdminUserActivityUseCaseContract {}

class _Timeline extends Mock implements GetAdminUserTimelineUseCaseContract {}

class _Identity extends Mock
    implements UpdateAdminUserIdentityUseCaseContract {}

class _Progress extends Mock implements SetAdminUserProgressUseCaseContract {}

class _Role extends Mock implements ChangeAdminUserRoleUseCaseContract {}

class _Shadowban extends Mock implements SetAdminUserShadowbanUseCaseContract {}

class _Wipe extends Mock implements WipeAdminUserUseCaseContract {}

class _Anonymize extends Mock implements AnonymizeAdminUserUseCaseContract {}

class _Delete extends Mock implements DeleteAdminUserUseCaseContract {}

class _Export extends Mock implements ExportAdminUserDataUseCaseContract {}

void main() {
  late AdminUserDetailUseCases useCases;
  late _Detail getDetail;
  late _Timeline getTimeline;
  late _Role changeRole;
  late _Delete delete;
  late _Export export;

  setUpAll(() => registerFallbackValue(UserRole.user));

  setUp(() {
    getDetail = _Detail();
    final getStats = _Stats();
    final getActivity = _Activity();
    getTimeline = _Timeline();
    changeRole = _Role();
    delete = _Delete();
    export = _Export();
    useCases = AdminUserDetailUseCases(
      getDetail: getDetail,
      getStats: getStats,
      getActivity: getActivity,
      getTimeline: getTimeline,
      updateIdentity: _Identity(),
      setProgress: _Progress(),
      changeRole: changeRole,
      setShadowban: _Shadowban(),
      wipe: _Wipe(),
      anonymize: _Anonymize(),
      delete: delete,
      export: export,
    );
    when(() => getDetail('u1')).thenAnswer((_) async => const Success(detail));
    when(() => getStats('u1')).thenAnswer((_) async => const Success(stats));
    when(
      () => getActivity('u1', weeks: any(named: 'weeks')),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => getTimeline(
        'u1',
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Success(pageOf([timelineEntry], totalPages: 2)));
  });

  final ready = AdminUserDetailState(
    userId: 'u1',
    status: AdminStatus.ready,
    detail: detail,
    stats: stats,
    timeline: [timelineEntry],
    timelineHasMore: true,
  );

  blocTest<AdminUserDetailBloc, AdminUserDetailState>(
    'started carga detalle, estadísticas, actividad y timeline',
    build: () => AdminUserDetailBloc(useCases),
    act: (bloc) => bloc.add(const AdminUserDetailEvent.started('u1')),
    expect: () => [
      const AdminUserDetailState(userId: 'u1'),
      const AdminUserDetailState(userId: 'u1', status: AdminStatus.loading),
      ready,
    ],
  );

  blocTest<AdminUserDetailBloc, AdminUserDetailState>(
    'si falla el detalle la pantalla queda en error',
    setUp: () => when(() => getDetail('u1')).thenAnswer(
      (_) async => const Failure(AppError.business('ADMIN_USER_NOT_FOUND')),
    ),
    build: () => AdminUserDetailBloc(useCases),
    act: (bloc) => bloc.add(const AdminUserDetailEvent.started('u1')),
    verify: (bloc) {
      expect(bloc.state.status, AdminStatus.failure);
      expect(bloc.state.error, const AppError.business('ADMIN_USER_NOT_FOUND'));
    },
  );

  blocTest<AdminUserDetailBloc, AdminUserDetailState>(
    'timelineMoreRequested añade la página siguiente',
    build: () => AdminUserDetailBloc(useCases),
    seed: () => ready,
    act: (bloc) => bloc.add(const AdminUserDetailEvent.timelineMoreRequested()),
    verify: (bloc) {
      expect(bloc.state.timeline, hasLength(2));
      expect(bloc.state.timelinePage, 1);
      verify(
        () => getTimeline(
          'u1',
          page: 1,
          size: AdminUserDetailBloc.timelinePageSize,
        ),
      ).called(1);
    },
  );

  blocTest<AdminUserDetailBloc, AdminUserDetailState>(
    'cambiar el rol actualiza la cuenta y emite saved',
    setUp: () => when(
      () => changeRole('u1', UserRole.admin),
    ).thenAnswer((_) async => Success(account.copyWith(role: UserRole.admin))),
    build: () => AdminUserDetailBloc(useCases),
    seed: () => ready,
    act: (bloc) =>
        bloc.add(const AdminUserDetailEvent.roleChanged(UserRole.admin)),
    expect: () => [
      ready.copyWith(busyAction: AdminUserAction.role),
      ready.copyWith(
        detail: detail.copyWith(
          account: account.copyWith(role: UserRole.admin),
        ),
        effect: const AdminUserEffect.saved(AdminUserAction.role),
      ),
    ],
  );

  blocTest<AdminUserDetailBloc, AdminUserDetailState>(
    'acción sobre uno mismo rechazada: emite el error sin tocar la cuenta',
    setUp: () => when(() => changeRole(any(), any())).thenAnswer(
      (_) async => const Failure(AppError.business('ADMIN_CANNOT_TARGET_SELF')),
    ),
    build: () => AdminUserDetailBloc(useCases),
    seed: () => ready,
    act: (bloc) =>
        bloc.add(const AdminUserDetailEvent.roleChanged(UserRole.admin)),
    expect: () => [
      ready.copyWith(busyAction: AdminUserAction.role),
      ready.copyWith(
        effect: const AdminUserEffect.failure(
          AppError.business('ADMIN_CANNOT_TARGET_SELF'),
        ),
      ),
    ],
  );

  blocTest<AdminUserDetailBloc, AdminUserDetailState>(
    'eliminar emite el informe de borrado sin recargar',
    setUp: () => when(
      () => delete('u1'),
    ).thenAnswer((_) async => const Success(erasure)),
    build: () => AdminUserDetailBloc(useCases),
    seed: () => ready,
    act: (bloc) => bloc.add(const AdminUserDetailEvent.deleteRequested()),
    expect: () => [
      ready.copyWith(busyAction: AdminUserAction.delete),
      ready,
      ready.copyWith(
        effect: const AdminUserEffect.erased(AdminUserAction.delete, erasure),
      ),
    ],
    verify: (_) => verifyNever(() => getDetail(any())),
  );

  blocTest<AdminUserDetailBloc, AdminUserDetailState>(
    'exportar entrega el JSON en un efecto',
    setUp: () =>
        when(() => export('u1')).thenAnswer((_) async => const Success('{}')),
    build: () => AdminUserDetailBloc(useCases),
    seed: () => ready,
    act: (bloc) => bloc.add(const AdminUserDetailEvent.exportRequested()),
    expect: () => [
      ready.copyWith(busyAction: AdminUserAction.export),
      ready.copyWith(effect: const AdminUserEffect.exported('{}')),
    ],
  );
}
