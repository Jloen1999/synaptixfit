import '../screens/profile/enrollment_import/bloc/enrollment_import_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/enums/app_language.dart';
import '../../domain/enums/appearance_mode.dart';
import '../screens/profile/appearance/bloc/appearance_bloc.dart';
import '../screens/profile/language/bloc/language_bloc.dart';
import '../screens/profile/catalog_picker/bloc/catalog_picker_bloc.dart';
import '../screens/profile/change_password/bloc/change_password_bloc.dart';
import '../screens/profile/degrees/bloc/degrees_bloc.dart';
import '../screens/profile/edit_academic/bloc/academic_form_bloc.dart';
import '../screens/profile/edit_account/bloc/edit_account_bloc.dart';
import '../screens/profile/edit_wellness/bloc/wellness_form_bloc.dart';
import '../screens/profile/notification_settings/bloc/device_reminders_bloc.dart';
import '../screens/profile/notification_settings/bloc/weekly_email_bloc.dart';
import '../screens/profile/notification_settings/bloc/notification_settings_bloc.dart';
import '../screens/profile/onboarding/bloc/onboarding_bloc.dart';
import '../screens/profile/profile/bloc/profile_bloc.dart';
import '../screens/profile/settings/bloc/settings_bloc.dart';
import '../screens/profile/subject_selector/bloc/subject_selector_bloc.dart';
import '../screens/profile/wellness_history/bloc/wellness_history_bloc.dart';

/// Blocs del módulo profile.
void registerProfilePresentation(GetIt getIt) {
  getIt
    ..registerFactory(() => EnrollmentImportBloc(read: getIt(), apply: getIt()))
    ..registerFactoryParam<LanguageBloc, AppLanguage?, void>(
      (initial, _) => LanguageBloc(
        get: getIt(),
        set: getIt(),
        initial: initial ?? AppLanguage.system,
      ),
    )
    ..registerFactoryParam<AppearanceBloc, AppearanceMode?, void>(
      (initial, _) => AppearanceBloc(
        get: getIt(),
        set: getIt(),
        initial: initial ?? AppearanceMode.dark,
      ),
    )
    ..registerFactory(
      () => OnboardingBloc(
        getStatus: getIt(),
        complete: getIt(),
        changePassword: getIt(),
        updateAccount: getIt(),
        getAccount: getIt(),
      ),
    )
    ..registerFactory(
      () => ProfileBloc(getAccount: getIt(), getSummary: getIt()),
    )
    ..registerFactory(() => EditAccountBloc(updateAccount: getIt()))
    ..registerFactory(
      () => WellnessFormBloc(
        getSummary: getIt(),
        saveProfile: getIt(),
        updateProfile: getIt(),
        suggestGoals: getIt(),
      ),
    )
    ..registerFactory(
      () => AcademicFormBloc(getSummary: getIt(), saveProfile: getIt()),
    )
    ..registerFactory(
      () => CatalogPickerBloc(
        searchUniversities: getIt(),
        searchDegrees: getIt(),
      ),
    )
    ..registerFactory(
      () => SubjectSelectorBloc(getSubjects: getIt(), addSubjects: getIt()),
    )
    ..registerFactory(
      () => DegreesBloc(
        getDegrees: getIt(),
        linkDegree: getIt(),
        unlinkDegree: getIt(),
      ),
    )
    ..registerFactory(
      () => WellnessHistoryBloc(
        getWeightHistory: getIt(),
        getGoalHistory: getIt(),
      ),
    )
    ..registerFactory(
      () => SettingsBloc(exportMyData: getIt(), deleteMyAccount: getIt()),
    )
    ..registerFactory(
      () => ChangePasswordBloc(changePassword: getIt(), getAccount: getIt()),
    )
    ..registerFactory(
      () => NotificationSettingsBloc(
        getPreferences: getIt(),
        updatePreferences: getIt(),
      ),
    )
    ..registerFactory(
      () => DeviceRemindersBloc(getStatus: getIt(), setEnabled: getIt()),
    )
    ..registerFactory(
      () => WeeklyEmailBloc(
        getStatus: getIt(),
        enable: getIt(),
        disable: getIt(),
      ),
    );
}
