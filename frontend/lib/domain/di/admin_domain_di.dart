import 'package:get_it/get_it.dart';

import '../use_cases/admin/anonymize_admin_user_use_case.dart';
import '../use_cases/admin/change_admin_user_role_use_case.dart';
import '../use_cases/admin/create_admin_exercise_use_case.dart';
import '../use_cases/admin/delete_admin_exercise_use_case.dart';
import '../use_cases/admin/delete_admin_user_use_case.dart';
import '../use_cases/admin/dismiss_report_use_case.dart';
import '../use_cases/admin/export_admin_user_data_use_case.dart';
import '../use_cases/admin/get_activity_trend_use_case.dart';
import '../use_cases/admin/get_admin_exercise_names_use_case.dart';
import '../use_cases/admin/get_admin_exercise_options_use_case.dart';
import '../use_cases/admin/get_admin_exercise_use_case.dart';
import '../use_cases/admin/get_admin_user_activity_use_case.dart';
import '../use_cases/admin/get_admin_user_detail_use_case.dart';
import '../use_cases/admin/get_admin_user_stats_use_case.dart';
import '../use_cases/admin/get_admin_user_timeline_use_case.dart';
import '../use_cases/admin/get_lockdown_use_case.dart';
import '../use_cases/admin/get_platform_metrics_use_case.dart';
import '../use_cases/admin/get_reported_content_use_case.dart';
import '../use_cases/admin/remove_reported_content_use_case.dart';
import '../use_cases/admin/search_admin_exercises_use_case.dart';
import '../use_cases/admin/search_admin_users_use_case.dart';
import '../use_cases/admin/search_audit_log_use_case.dart';
import '../use_cases/admin/set_admin_exercise_active_use_case.dart';
import '../use_cases/admin/set_admin_user_progress_use_case.dart';
import '../use_cases/admin/set_admin_user_shadowban_use_case.dart';
import '../use_cases/admin/set_lockdown_use_case.dart';
import '../use_cases/admin/suggest_admin_exercise_names_use_case.dart';
import '../use_cases/admin/update_admin_exercise_use_case.dart';
import '../use_cases/admin/update_admin_user_identity_use_case.dart';
import '../use_cases/admin/wipe_admin_user_use_case.dart';

/// Casos de uso del módulo admin.
void registerAdminDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<GetPlatformMetricsUseCaseContract>(
      () => GetPlatformMetricsUseCase(getIt()),
    )
    ..registerLazySingleton<GetActivityTrendUseCaseContract>(
      () => GetActivityTrendUseCase(getIt()),
    )
    ..registerLazySingleton<GetLockdownUseCaseContract>(
      () => GetLockdownUseCase(getIt()),
    )
    ..registerLazySingleton<SetLockdownUseCaseContract>(
      () => SetLockdownUseCase(getIt()),
    )
    ..registerLazySingleton<SearchAdminUsersUseCaseContract>(
      () => SearchAdminUsersUseCase(getIt()),
    )
    ..registerLazySingleton<GetAdminUserDetailUseCaseContract>(
      () => GetAdminUserDetailUseCase(getIt()),
    )
    ..registerLazySingleton<GetAdminUserStatsUseCaseContract>(
      () => GetAdminUserStatsUseCase(getIt()),
    )
    ..registerLazySingleton<GetAdminUserActivityUseCaseContract>(
      () => GetAdminUserActivityUseCase(getIt()),
    )
    ..registerLazySingleton<GetAdminUserTimelineUseCaseContract>(
      () => GetAdminUserTimelineUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateAdminUserIdentityUseCaseContract>(
      () => UpdateAdminUserIdentityUseCase(getIt()),
    )
    ..registerLazySingleton<SetAdminUserProgressUseCaseContract>(
      () => SetAdminUserProgressUseCase(getIt()),
    )
    ..registerLazySingleton<ChangeAdminUserRoleUseCaseContract>(
      () => ChangeAdminUserRoleUseCase(getIt()),
    )
    ..registerLazySingleton<SetAdminUserShadowbanUseCaseContract>(
      () => SetAdminUserShadowbanUseCase(getIt()),
    )
    ..registerLazySingleton<WipeAdminUserUseCaseContract>(
      () => WipeAdminUserUseCase(getIt()),
    )
    ..registerLazySingleton<AnonymizeAdminUserUseCaseContract>(
      () => AnonymizeAdminUserUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteAdminUserUseCaseContract>(
      () => DeleteAdminUserUseCase(getIt()),
    )
    ..registerLazySingleton<ExportAdminUserDataUseCaseContract>(
      () => ExportAdminUserDataUseCase(getIt()),
    )
    ..registerLazySingleton<SearchAuditLogUseCaseContract>(
      () => SearchAuditLogUseCase(getIt()),
    )
    ..registerLazySingleton<GetReportedContentUseCaseContract>(
      () => GetReportedContentUseCase(getIt()),
    )
    ..registerLazySingleton<DismissReportUseCaseContract>(
      () => DismissReportUseCase(getIt()),
    )
    ..registerLazySingleton<RemoveReportedContentUseCaseContract>(
      () => RemoveReportedContentUseCase(getIt()),
    )
    ..registerLazySingleton<SearchAdminExercisesUseCaseContract>(
      () => SearchAdminExercisesUseCase(getIt()),
    )
    ..registerLazySingleton<GetAdminExerciseUseCaseContract>(
      () => GetAdminExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<GetAdminExerciseNamesUseCaseContract>(
      () => GetAdminExerciseNamesUseCase(getIt()),
    )
    ..registerLazySingleton<SuggestAdminExerciseNamesUseCaseContract>(
      () => SuggestAdminExerciseNamesUseCase(getIt()),
    )
    ..registerLazySingleton<CreateAdminExerciseUseCaseContract>(
      () => CreateAdminExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateAdminExerciseUseCaseContract>(
      () => UpdateAdminExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<SetAdminExerciseActiveUseCaseContract>(
      () => SetAdminExerciseActiveUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteAdminExerciseUseCaseContract>(
      () => DeleteAdminExerciseUseCase(getIt()),
    )
    ..registerLazySingleton<GetAdminExerciseOptionsUseCaseContract>(
      () => GetAdminExerciseOptionsUseCase(getIt()),
    );
}
