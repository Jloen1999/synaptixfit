import 'package:get_it/get_it.dart';

import '../screens/admin/audit/bloc/admin_audit_bloc.dart';
import '../screens/admin/exercise_form/bloc/admin_exercise_form_bloc.dart';
import '../screens/admin/exercises/bloc/admin_exercises_bloc.dart';
import '../screens/admin/hub/bloc/admin_hub_bloc.dart';
import '../screens/admin/metrics/bloc/admin_metrics_bloc.dart';
import '../screens/admin/reports/bloc/admin_reports_bloc.dart';
import '../screens/admin/user_detail/bloc/admin_user_detail_bloc.dart';
import '../screens/admin/users/bloc/admin_users_bloc.dart';

/// Blocs del módulo admin.
void registerAdminPresentation(GetIt getIt) {
  getIt
    ..registerFactory(
      () => AdminHubBloc(getLockdown: getIt(), setLockdown: getIt()),
    )
    ..registerFactory(
      () => AdminMetricsBloc(getMetrics: getIt(), getTrend: getIt()),
    )
    ..registerFactory(() => AdminUsersBloc(searchUsers: getIt()))
    ..registerFactory(
      () => AdminUserDetailBloc(
        AdminUserDetailUseCases(
          getDetail: getIt(),
          getStats: getIt(),
          getActivity: getIt(),
          getTimeline: getIt(),
          updateIdentity: getIt(),
          setProgress: getIt(),
          changeRole: getIt(),
          setShadowban: getIt(),
          wipe: getIt(),
          anonymize: getIt(),
          delete: getIt(),
          export: getIt(),
        ),
      ),
    )
    ..registerFactory(
      () => AdminReportsBloc(
        getReports: getIt(),
        dismiss: getIt(),
        remove: getIt(),
      ),
    )
    ..registerFactory(
      () => AdminExercisesBloc(
        search: getIt(),
        setActive: getIt(),
        delete: getIt(),
      ),
    )
    ..registerFactory(
      () => AdminExerciseFormBloc(
        getOptions: getIt(),
        getExercise: getIt(),
        getNames: getIt(),
        suggestNames: getIt(),
        create: getIt(),
        update: getIt(),
      ),
    )
    ..registerFactory(() => AdminAuditBloc(search: getIt()));
}
