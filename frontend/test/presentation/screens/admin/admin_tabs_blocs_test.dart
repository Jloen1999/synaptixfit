import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/admin/admin_audit_action.dart';
import 'package:synaptixfit/domain/enums/admin/admin_audit_entity.dart';
import 'package:synaptixfit/domain/enums/admin/admin_report_type.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/admin/admin_exercise.dart';
import 'package:synaptixfit/domain/models/admin/admin_queries.dart';
import 'package:synaptixfit/domain/models/admin/audit_entry.dart';
import 'package:synaptixfit/domain/models/admin/lockdown_status.dart';
import 'package:synaptixfit/domain/models/admin/platform_metrics.dart';
import 'package:synaptixfit/domain/models/admin/reported_content.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/admin/delete_admin_exercise_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/dismiss_report_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_activity_trend_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_lockdown_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_platform_metrics_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_reported_content_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/remove_reported_content_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/search_admin_exercises_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/search_audit_log_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/set_admin_exercise_active_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/set_lockdown_use_case.dart';
import 'package:synaptixfit/presentation/screens/admin/audit/bloc/admin_audit_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/exercises/bloc/admin_exercises_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/hub/bloc/admin_hub_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/metrics/bloc/admin_metrics_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/reports/bloc/admin_reports_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/widgets/admin_status.dart';

import 'admin_fixtures.dart';

class _GetLockdown extends Mock implements GetLockdownUseCaseContract {}

class _SetLockdown extends Mock implements SetLockdownUseCaseContract {}

class _Metrics extends Mock implements GetPlatformMetricsUseCaseContract {}

class _Trend extends Mock implements GetActivityTrendUseCaseContract {}

class _Reports extends Mock implements GetReportedContentUseCaseContract {}

class _Dismiss extends Mock implements DismissReportUseCaseContract {}

class _Remove extends Mock implements RemoveReportedContentUseCaseContract {}

class _SearchExercises extends Mock
    implements SearchAdminExercisesUseCaseContract {}

class _SetActive extends Mock
    implements SetAdminExerciseActiveUseCaseContract {}

class _DeleteExercise extends Mock
    implements DeleteAdminExerciseUseCaseContract {}

class _Audit extends Mock implements SearchAuditLogUseCaseContract {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AdminExerciseQuery());
    registerFallbackValue(const AuditQuery());
    registerFallbackValue(AdminReportType.post);
  });

  group('AdminHubBloc', () {
    late _GetLockdown getLockdown;
    late _SetLockdown setLockdown;

    setUp(() {
      getLockdown = _GetLockdown();
      setLockdown = _SetLockdown();
    });

    blocTest<AdminHubBloc, AdminHubState>(
      'carga el estado del bloqueo',
      setUp: () => when(
        () => getLockdown(),
      ).thenAnswer((_) async => const Success(LockdownStatus(active: false))),
      build: () =>
          AdminHubBloc(getLockdown: getLockdown, setLockdown: setLockdown),
      act: (bloc) => bloc.add(const AdminHubEvent.started()),
      expect: () => const [
        AdminHubState(loading: true),
        AdminHubState(lockdown: LockdownStatus(active: false)),
      ],
    );

    blocTest<AdminHubBloc, AdminHubState>(
      'activar el bloqueo; si falla conserva el estado y expone el error',
      setUp: () => when(
        () => setLockdown(active: true),
      ).thenAnswer((_) async => const Failure(AppError.server())),
      build: () =>
          AdminHubBloc(getLockdown: getLockdown, setLockdown: setLockdown),
      seed: () => const AdminHubState(lockdown: LockdownStatus(active: false)),
      act: (bloc) =>
          bloc.add(const AdminHubEvent.lockdownChanged(active: true)),
      expect: () => const [
        AdminHubState(lockdown: LockdownStatus(active: false), updating: true),
        AdminHubState(
          lockdown: LockdownStatus(active: false),
          actionError: AppError.server(),
        ),
      ],
    );
  });

  group('AdminMetricsBloc', () {
    const metrics = PlatformMetrics(
      totalUsers: 10,
      activeUsersToday: 3,
      trainingSessionsToday: 2,
      activeRoutines: 4,
      activeChallenges: 1,
      pendingReportedContent: 0,
      newUsersToday: 1,
      shadowbannedUsers: 0,
    );
    final day = DailyActivity(
      date: DateTime(2026, 10, 1),
      signups: 1,
      activeUsers: 3,
      trainingSessions: 2,
    );
    late _Metrics getMetrics;
    late _Trend getTrend;

    setUp(() {
      getMetrics = _Metrics();
      getTrend = _Trend();
      when(() => getMetrics()).thenAnswer((_) async => const Success(metrics));
      when(
        () => getTrend(days: any(named: 'days')),
      ).thenAnswer((_) async => Success([day]));
    });

    blocTest<AdminMetricsBloc, AdminMetricsState>(
      'carga métricas y tendencia de 30 días',
      build: () => AdminMetricsBloc(getMetrics: getMetrics, getTrend: getTrend),
      act: (bloc) => bloc.add(const AdminMetricsEvent.started()),
      expect: () => [
        const AdminMetricsState(status: AdminStatus.loading),
        AdminMetricsState(
          status: AdminStatus.ready,
          metrics: metrics,
          trend: [day],
        ),
      ],
      verify: (_) => verify(() => getTrend(days: 30)).called(1),
    );

    blocTest<AdminMetricsBloc, AdminMetricsState>(
      'si fallan las métricas queda en error',
      setUp: () => when(
        () => getMetrics(),
      ).thenAnswer((_) async => const Failure(AppError.forbidden())),
      build: () => AdminMetricsBloc(getMetrics: getMetrics, getTrend: getTrend),
      act: (bloc) => bloc.add(const AdminMetricsEvent.started()),
      verify: (bloc) {
        expect(bloc.state.status, AdminStatus.failure);
        expect(bloc.state.error, const AppError.forbidden());
      },
    );

    blocTest<AdminMetricsBloc, AdminMetricsState>(
      'cambiar los días recarga solo la tendencia',
      build: () => AdminMetricsBloc(getMetrics: getMetrics, getTrend: getTrend),
      act: (bloc) => bloc.add(const AdminMetricsEvent.trendDaysChanged(7)),
      verify: (bloc) {
        expect(bloc.state.trendDays, 7);
        expect(bloc.state.trend, [day]);
        verify(() => getTrend(days: 7)).called(1);
        verifyNever(() => getMetrics());
      },
    );
  });

  group('AdminReportsBloc', () {
    const report = ReportedContent(
      type: AdminReportType.comment,
      id: 'c1',
      postId: 'p1',
      content: 'spam',
    );
    late _Reports getReports;
    late _Dismiss dismiss;
    late _Remove remove;

    setUp(() {
      getReports = _Reports();
      dismiss = _Dismiss();
      remove = _Remove();
      when(
        () => getReports(
          type: any(named: 'type'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => Success(pageOf([report])));
    });

    AdminReportsBloc build() => AdminReportsBloc(
      getReports: getReports,
      dismiss: dismiss,
      remove: remove,
    );

    blocTest<AdminReportsBloc, AdminReportsState>(
      'filtrar por tipo recarga con ese tipo',
      build: build,
      act: (bloc) =>
          bloc.add(const AdminReportsEvent.typeChanged(AdminReportType.post)),
      verify: (bloc) {
        expect(bloc.state.type, AdminReportType.post);
        verify(
          () => getReports(
            type: AdminReportType.post,
            page: 0,
            size: AdminReportsBloc.pageSize,
          ),
        ).called(1);
      },
    );

    blocTest<AdminReportsBloc, AdminReportsState>(
      'descartar un reporte recarga la cola y avisa',
      setUp: () => when(
        () => dismiss(AdminReportType.comment, 'c1'),
      ).thenAnswer((_) async => const Success(unit)),
      build: build,
      seed: () => AdminReportsState(
        status: AdminStatus.ready,
        reports: pageOf([report]),
      ),
      act: (bloc) => bloc.add(const AdminReportsEvent.dismissRequested(report)),
      verify: (bloc) {
        expect(bloc.state.effect, const AdminReportsEffect.dismissed());
        expect(bloc.state.busyId, isNull);
        verify(() => dismiss(AdminReportType.comment, 'c1')).called(1);
      },
    );

    blocTest<AdminReportsBloc, AdminReportsState>(
      'si borrar falla emite el error',
      setUp: () => when(() => remove(any(), any())).thenAnswer(
        (_) async => const Failure(AppError.business('COMMENT_NOT_FOUND')),
      ),
      build: build,
      seed: () => AdminReportsState(
        status: AdminStatus.ready,
        reports: pageOf([report]),
      ),
      act: (bloc) => bloc.add(const AdminReportsEvent.removeRequested(report)),
      verify: (bloc) => expect(
        bloc.state.effect,
        const AdminReportsEffect.failure(
          AppError.business('COMMENT_NOT_FOUND'),
        ),
      ),
    );
  });

  group('AdminExercisesBloc', () {
    late _SearchExercises search;
    late _SetActive setActive;
    late _DeleteExercise delete;

    setUp(() {
      search = _SearchExercises();
      setActive = _SetActive();
      delete = _DeleteExercise();
      when(
        () => search(
          query: any(named: 'query'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => Success(pageOf([exercise])));
    });

    AdminExercisesBloc build() => AdminExercisesBloc(
      search: search,
      setActive: setActive,
      delete: delete,
    );

    blocTest<AdminExercisesBloc, AdminExercisesState>(
      'busca incluyendo inactivos por defecto',
      build: build,
      act: (bloc) => bloc.add(const AdminExercisesEvent.started()),
      verify: (bloc) {
        expect(bloc.state.status, AdminStatus.ready);
        verify(
          () => search(
            query: const AdminExerciseQuery(),
            page: 0,
            size: AdminExercisesBloc.pageSize,
          ),
        ).called(1);
        expect(const AdminExerciseQuery().includeInactive, isTrue);
      },
    );

    blocTest<AdminExercisesBloc, AdminExercisesState>(
      'desactivar sustituye el ejercicio en la página',
      setUp: () => when(
        () => setActive('e1', active: false),
      ).thenAnswer((_) async => Success(exercise.copyWith(active: false))),
      build: build,
      seed: () => AdminExercisesState(
        status: AdminStatus.ready,
        exercises: pageOf([exercise]),
      ),
      act: (bloc) =>
          bloc.add(const AdminExercisesEvent.activeToggled(exercise)),
      verify: (bloc) {
        expect(bloc.state.exercises!.items.single.active, isFalse);
        expect(
          bloc.state.effect,
          const AdminExercisesEffect.activeChanged(active: false),
        );
      },
    );

    blocTest<AdminExercisesBloc, AdminExercisesState>(
      'borrar un ejercicio en uso informa de que se ha desactivado',
      setUp: () => when(() => delete('e1')).thenAnswer(
        (_) async => const Success(
          AdminExerciseDeletion(deleted: false, deactivated: true),
        ),
      ),
      build: build,
      seed: () => AdminExercisesState(
        status: AdminStatus.ready,
        exercises: pageOf([exercise]),
      ),
      act: (bloc) =>
          bloc.add(const AdminExercisesEvent.deleteRequested(exercise)),
      verify: (bloc) => expect(
        bloc.state.effect,
        const AdminExercisesEffect.deactivatedInstead(),
      ),
    );
  });

  group('AdminAuditBloc', () {
    late _Audit search;
    final entry = AuditEntry(
      id: 'a1',
      action: AdminAuditAction.changeRole,
      entityType: AdminAuditEntity.user,
      createdAt: DateTime(2026, 10, 1),
    );

    setUp(() {
      search = _Audit();
      when(
        () => search(
          query: any(named: 'query'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => Success(pageOf([entry])));
    });

    blocTest<AdminAuditBloc, AdminAuditState>(
      'aplicar filtros vuelve a la página 0',
      build: () => AdminAuditBloc(search: search),
      seed: () => const AdminAuditState(status: AdminStatus.ready, page: 3),
      act: (bloc) => bloc.add(
        const AdminAuditEvent.queryChanged(
          AuditQuery(action: AdminAuditAction.changeRole),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.page, 0);
        expect(bloc.state.entries!.items, [entry]);
        verify(
          () => search(
            query: const AuditQuery(action: AdminAuditAction.changeRole),
            page: 0,
            size: AdminAuditBloc.pageSize,
          ),
        ).called(1);
      },
    );

    blocTest<AdminAuditBloc, AdminAuditState>(
      'rango de fechas no válido: error de negocio',
      setUp: () =>
          when(
            () => search(
              query: any(named: 'query'),
              page: any(named: 'page'),
              size: any(named: 'size'),
            ),
          ).thenAnswer(
            (_) async =>
                const Failure(AppError.business('ADMIN_INVALID_DATE_RANGE')),
          ),
      build: () => AdminAuditBloc(search: search),
      act: (bloc) => bloc.add(const AdminAuditEvent.started()),
      verify: (bloc) => expect(
        bloc.state.error,
        const AppError.business('ADMIN_INVALID_DATE_RANGE'),
      ),
    );
  });
}
