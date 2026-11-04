import '../use_cases/profile/apply_enrollment_use_case.dart';
import '../use_cases/profile/read_enrollment_use_case.dart';
import 'package:get_it/get_it.dart';

import '../use_cases/profile/get_device_permission_status_use_case.dart';
import '../use_cases/profile/request_device_permission_use_case.dart';
import '../use_cases/profile/open_permission_settings_use_case.dart';
import '../use_cases/profile/is_permissions_intro_pending_use_case.dart';
import '../use_cases/profile/mark_permissions_intro_seen_use_case.dart';
import '../use_cases/profile/get_legal_document_use_case.dart';
import '../use_cases/profile/get_legal_acceptance_use_case.dart';
import '../use_cases/profile/accept_legal_terms_use_case.dart';

import '../use_cases/profile/get_language_use_case.dart';
import '../use_cases/profile/set_language_use_case.dart';
import '../use_cases/profile/get_appearance_use_case.dart';
import '../use_cases/profile/set_appearance_use_case.dart';
import '../use_cases/profile/get_profile_summary_use_case.dart';
import '../use_cases/profile/get_onboarding_status_use_case.dart';
import '../use_cases/profile/complete_onboarding_use_case.dart';
import '../use_cases/profile/save_wellness_profile_use_case.dart';
import '../use_cases/profile/update_wellness_profile_use_case.dart';
import '../use_cases/profile/suggest_goals_use_case.dart';
import '../use_cases/profile/get_weight_history_use_case.dart';
import '../use_cases/profile/get_goal_history_use_case.dart';
import '../use_cases/profile/save_academic_profile_use_case.dart';
import '../use_cases/profile/get_my_degrees_use_case.dart';
import '../use_cases/profile/link_degree_use_case.dart';
import '../use_cases/profile/unlink_degree_use_case.dart';
import '../use_cases/profile/get_my_catalog_subjects_use_case.dart';
import '../use_cases/profile/search_universities_use_case.dart';
import '../use_cases/profile/search_degrees_use_case.dart';
import '../use_cases/profile/add_subjects_from_catalog_use_case.dart';
import '../use_cases/profile/export_my_data_use_case.dart';
import '../use_cases/profile/delete_my_account_use_case.dart';
import '../use_cases/profile/get_notification_preferences_use_case.dart';
import '../use_cases/profile/update_notification_preferences_use_case.dart';
import '../use_cases/profile/get_weekly_email_status_use_case.dart';
import '../use_cases/profile/enable_weekly_email_use_case.dart';
import '../use_cases/profile/disable_weekly_email_use_case.dart';

/// Casos de uso del módulo profile.
void registerProfileDomain(GetIt getIt) {
  getIt
    ..registerLazySingleton<GetDevicePermissionStatusUseCaseContract>(
      () => GetDevicePermissionStatusUseCase(getIt()),
    )
    ..registerLazySingleton<RequestDevicePermissionUseCaseContract>(
      () => RequestDevicePermissionUseCase(getIt()),
    )
    ..registerLazySingleton<OpenPermissionSettingsUseCaseContract>(
      () => OpenPermissionSettingsUseCase(getIt()),
    )
    ..registerLazySingleton<IsPermissionsIntroPendingUseCaseContract>(
      () => IsPermissionsIntroPendingUseCase(getIt()),
    )
    ..registerLazySingleton<MarkPermissionsIntroSeenUseCaseContract>(
      () => MarkPermissionsIntroSeenUseCase(getIt()),
    )
    ..registerLazySingleton<GetLegalDocumentUseCaseContract>(
      () => GetLegalDocumentUseCase(getIt()),
    )
    ..registerLazySingleton<GetLegalAcceptanceUseCaseContract>(
      () => GetLegalAcceptanceUseCase(getIt()),
    )
    ..registerLazySingleton<AcceptLegalTermsUseCaseContract>(
      () => AcceptLegalTermsUseCase(getIt()),
    )
    ..registerLazySingleton<GetAppearanceUseCaseContract>(
      () => GetAppearanceUseCase(getIt()),
    )
    ..registerLazySingleton<SetAppearanceUseCaseContract>(
      () => SetAppearanceUseCase(getIt()),
    )
    ..registerLazySingleton<ReadEnrollmentUseCaseContract>(
      () => ReadEnrollmentUseCase(getIt()),
    )
    ..registerLazySingleton<ApplyEnrollmentUseCaseContract>(
      () => ApplyEnrollmentUseCase(getIt()),
    )
    ..registerLazySingleton<GetLanguageUseCaseContract>(
      () => GetLanguageUseCase(getIt()),
    )
    ..registerLazySingleton<SetLanguageUseCaseContract>(
      () => SetLanguageUseCase(getIt()),
    )
    ..registerLazySingleton<GetProfileSummaryUseCaseContract>(
      () => GetProfileSummaryUseCase(getIt()),
    )
    ..registerLazySingleton<GetOnboardingStatusUseCaseContract>(
      () => GetOnboardingStatusUseCase(getIt()),
    )
    ..registerLazySingleton<CompleteOnboardingUseCaseContract>(
      () => CompleteOnboardingUseCase(getIt()),
    )
    ..registerLazySingleton<SaveWellnessProfileUseCaseContract>(
      () => SaveWellnessProfileUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateWellnessProfileUseCaseContract>(
      () => UpdateWellnessProfileUseCase(getIt()),
    )
    ..registerLazySingleton<SuggestGoalsUseCaseContract>(
      () => SuggestGoalsUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeightHistoryUseCaseContract>(
      () => GetWeightHistoryUseCase(getIt()),
    )
    ..registerLazySingleton<GetGoalHistoryUseCaseContract>(
      () => GetGoalHistoryUseCase(getIt()),
    )
    ..registerLazySingleton<SaveAcademicProfileUseCaseContract>(
      () => SaveAcademicProfileUseCase(getIt()),
    )
    ..registerLazySingleton<GetMyDegreesUseCaseContract>(
      () => GetMyDegreesUseCase(getIt()),
    )
    ..registerLazySingleton<LinkDegreeUseCaseContract>(
      () => LinkDegreeUseCase(getIt()),
    )
    ..registerLazySingleton<UnlinkDegreeUseCaseContract>(
      () => UnlinkDegreeUseCase(getIt()),
    )
    ..registerLazySingleton<GetMyCatalogSubjectsUseCaseContract>(
      () => GetMyCatalogSubjectsUseCase(getIt()),
    )
    ..registerLazySingleton<SearchUniversitiesUseCaseContract>(
      () => SearchUniversitiesUseCase(getIt()),
    )
    ..registerLazySingleton<SearchDegreesUseCaseContract>(
      () => SearchDegreesUseCase(getIt()),
    )
    ..registerLazySingleton<AddSubjectsFromCatalogUseCaseContract>(
      () => AddSubjectsFromCatalogUseCase(getIt()),
    )
    ..registerLazySingleton<ExportMyDataUseCaseContract>(
      () => ExportMyDataUseCase(getIt()),
    )
    ..registerLazySingleton<DeleteMyAccountUseCaseContract>(
      () => DeleteMyAccountUseCase(getIt()),
    )
    ..registerLazySingleton<GetNotificationPreferencesUseCaseContract>(
      () => GetNotificationPreferencesUseCase(getIt()),
    )
    ..registerLazySingleton<UpdateNotificationPreferencesUseCaseContract>(
      () => UpdateNotificationPreferencesUseCase(getIt()),
    )
    ..registerLazySingleton<GetWeeklyEmailStatusUseCaseContract>(
      () => GetWeeklyEmailStatusUseCase(getIt()),
    )
    ..registerLazySingleton<EnableWeeklyEmailUseCaseContract>(
      () => EnableWeeklyEmailUseCase(getIt()),
    )
    ..registerLazySingleton<DisableWeeklyEmailUseCaseContract>(
      () => DisableWeeklyEmailUseCase(getIt()),
    );
}
