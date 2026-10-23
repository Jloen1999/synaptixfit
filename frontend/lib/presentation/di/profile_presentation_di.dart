import 'package:get_it/get_it.dart';

import '../screens/profile/catalog_picker/bloc/catalog_picker_bloc.dart';
import '../screens/profile/change_password/bloc/change_password_bloc.dart';
import '../screens/profile/degrees/bloc/degrees_bloc.dart';
import '../screens/profile/edit_academic/bloc/academic_form_bloc.dart';
import '../screens/profile/edit_account/bloc/edit_account_bloc.dart';
import '../screens/profile/edit_wellness/bloc/wellness_form_bloc.dart';
import '../screens/profile/notification_settings/bloc/device_reminders_bloc.dart';
import '../screens/profile/notification_settings/bloc/notification_settings_bloc.dart';
import '../screens/profile/onboarding/bloc/onboarding_bloc.dart';
import '../screens/profile/profile/bloc/profile_bloc.dart';
import '../screens/profile/settings/bloc/settings_bloc.dart';
import '../screens/profile/subject_selector/bloc/subject_selector_bloc.dart';
import '../screens/profile/wellness_history/bloc/wellness_history_bloc.dart';

/// Blocs del módulo profile.
void registerProfilePresentation(GetIt getIt) {
  getIt
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
    );
}
