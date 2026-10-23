import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/profile/notification_category.dart';
import 'package:synaptixfit/domain/enums/profile/notification_mode.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/profile/catalog.dart';
import 'package:synaptixfit/domain/models/profile/notification_preferences.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/change_password_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/add_subjects_from_catalog_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/delete_my_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/export_my_data_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_my_catalog_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_notification_preferences_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/update_notification_preferences_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/change_password/bloc/change_password_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/notification_settings/bloc/notification_settings_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/settings/bloc/settings_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/subject_selector/bloc/subject_selector_bloc.dart';

import 'profile_fixtures.dart';

class _MockExport extends Mock implements ExportMyDataUseCaseContract {}

class _MockDelete extends Mock implements DeleteMyAccountUseCaseContract {}

class _MockChangePassword extends Mock
    implements ChangePasswordUseCaseContract {}

class _MockGetAccount extends Mock implements GetAccountUseCaseContract {}

class _MockGetPrefs extends Mock
    implements GetNotificationPreferencesUseCaseContract {}

class _MockUpdatePrefs extends Mock
    implements UpdateNotificationPreferencesUseCaseContract {}

class _MockSubjects extends Mock
    implements GetMyCatalogSubjectsUseCaseContract {}

class _MockAddSubjects extends Mock
    implements AddSubjectsFromCatalogUseCaseContract {}

void main() {
  group('SettingsBloc', () {
    late _MockExport export;
    late _MockDelete delete;

    setUp(() {
      export = _MockExport();
      delete = _MockDelete();
    });

    blocTest<SettingsBloc, SettingsState>(
      'exporta los datos',
      setUp: () =>
          when(() => export()).thenAnswer((_) async => const Success(true)),
      build: () => SettingsBloc(exportMyData: export, deleteMyAccount: delete),
      act: (bloc) => bloc.add(const SettingsEvent.exportRequested()),
      expect: () => const [
        SettingsState(exporting: true),
        SettingsState(outcome: SettingsOutcome.exported),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'cancelar el guardado no es un error',
      setUp: () =>
          when(() => export()).thenAnswer((_) async => const Success(false)),
      build: () => SettingsBloc(exportMyData: export, deleteMyAccount: delete),
      act: (bloc) => bloc.add(const SettingsEvent.exportRequested()),
      expect: () => const [
        SettingsState(exporting: true),
        SettingsState(outcome: SettingsOutcome.exportCancelled),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'elimina la cuenta con contraseña',
      setUp: () => when(
        () => delete(password: 'secreta1', confirm: true),
      ).thenAnswer((_) async => const Success(unit)),
      build: () => SettingsBloc(exportMyData: export, deleteMyAccount: delete),
      act: (bloc) => bloc.add(
        const SettingsEvent.deleteRequested(
          password: 'secreta1',
          confirm: true,
        ),
      ),
      expect: () => const [
        SettingsState(deleting: true),
        SettingsState(outcome: SettingsOutcome.deleted),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'cuenta solo de Google: confirmación explícita sin contraseña',
      setUp: () => when(
        () => delete(password: null, confirm: true),
      ).thenAnswer((_) async => const Success(unit)),
      build: () => SettingsBloc(exportMyData: export, deleteMyAccount: delete),
      act: (bloc) => bloc.add(
        const SettingsEvent.deleteRequested(password: '  ', confirm: true),
      ),
      verify: (_) =>
          verify(() => delete(password: null, confirm: true)).called(1),
    );

    blocTest<SettingsBloc, SettingsState>(
      'contraseña incorrecta: error sin cerrar sesión',
      setUp: () =>
          when(
            () => delete(
              password: any(named: 'password'),
              confirm: any(named: 'confirm'),
            ),
          ).thenAnswer(
            (_) async =>
                const Failure(AppError.business('GDPR_PASSWORD_MISMATCH')),
          ),
      build: () => SettingsBloc(exportMyData: export, deleteMyAccount: delete),
      act: (bloc) => bloc.add(
        const SettingsEvent.deleteRequested(password: 'mala', confirm: true),
      ),
      expect: () => const [
        SettingsState(deleting: true),
        SettingsState(error: AppError.business('GDPR_PASSWORD_MISMATCH')),
      ],
    );
  });

  group('ChangePasswordBloc', () {
    late _MockChangePassword change;
    late _MockGetAccount account;

    setUp(() {
      change = _MockChangePassword();
      account = _MockGetAccount();
    });

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'cambia la contraseña y refresca la cuenta',
      setUp: () {
        when(
          () => change(currentPassword: 'vieja123', newPassword: 'nueva123'),
        ).thenAnswer((_) async => const Success(unit));
        when(
          () => account(),
        ).thenAnswer((_) async => const Success(testAccount));
      },
      build: () =>
          ChangePasswordBloc(changePassword: change, getAccount: account),
      act: (bloc) => bloc.add(
        const ChangePasswordEvent.submitted(
          currentPassword: 'vieja123',
          newPassword: 'nueva123',
        ),
      ),
      expect: () => const [
        ChangePasswordState.submitting(),
        ChangePasswordState.success(testAccount),
      ],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'cuenta de Google: crea la contraseña sin la actual',
      setUp: () {
        when(
          () => change(currentPassword: null, newPassword: 'nueva123'),
        ).thenAnswer((_) async => const Success(unit));
        when(
          () => account(),
        ).thenAnswer((_) async => const Success(testAccount));
      },
      build: () =>
          ChangePasswordBloc(changePassword: change, getAccount: account),
      act: (bloc) => bloc.add(
        const ChangePasswordEvent.submitted(
          currentPassword: '',
          newPassword: 'nueva123',
        ),
      ),
      verify: (_) => verify(
        () => change(currentPassword: null, newPassword: 'nueva123'),
      ).called(1),
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'propaga el error',
      setUp: () =>
          when(
            () => change(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
            ),
          ).thenAnswer(
            (_) async =>
                const Failure(AppError.business('AUTH_INVALID_CREDENTIALS')),
          ),
      build: () =>
          ChangePasswordBloc(changePassword: change, getAccount: account),
      act: (bloc) => bloc.add(
        const ChangePasswordEvent.submitted(
          currentPassword: 'mala',
          newPassword: 'nueva123',
        ),
      ),
      expect: () => const [
        ChangePasswordState.submitting(),
        ChangePasswordState.failure(
          AppError.business('AUTH_INVALID_CREDENTIALS'),
        ),
      ],
    );
  });

  group('NotificationSettingsBloc', () {
    late _MockGetPrefs getPrefs;
    late _MockUpdatePrefs updatePrefs;
    const prefs = NotificationPreferences(
      activeCategories: {NotificationCategory.social},
      dailyLimit: 10,
      mode: NotificationMode.normal,
    );
    const ready = NotificationSettingsState(
      status: NotificationSettingsStatus.ready,
      preferences: prefs,
    );

    setUpAll(() => registerFallbackValue(prefs));

    setUp(() {
      getPrefs = _MockGetPrefs();
      updatePrefs = _MockUpdatePrefs();
    });

    NotificationSettingsBloc build() => NotificationSettingsBloc(
      getPreferences: getPrefs,
      updatePreferences: updatePrefs,
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'carga las preferencias',
      setUp: () =>
          when(() => getPrefs()).thenAnswer((_) async => const Success(prefs)),
      build: build,
      act: (bloc) => bloc.add(const NotificationSettingsEvent.started()),
      expect: () => const [NotificationSettingsState(), ready],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'error de carga',
      setUp: () => when(
        () => getPrefs(),
      ).thenAnswer((_) async => const Failure(AppError.server())),
      build: build,
      act: (bloc) => bloc.add(const NotificationSettingsEvent.started()),
      expect: () => const [
        NotificationSettingsState(),
        NotificationSettingsState(
          status: NotificationSettingsStatus.failure,
          error: AppError.server(),
        ),
      ],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'edita en memoria y guarda todo junto',
      setUp: () => when(() => updatePrefs(any())).thenAnswer(
        (inv) async =>
            Success(inv.positionalArguments.first as NotificationPreferences),
      ),
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(
          const NotificationSettingsEvent.categoryToggled(
            NotificationCategory.academic,
          ),
        )
        ..add(
          const NotificationSettingsEvent.modeChanged(NotificationMode.exams),
        )
        ..add(
          const NotificationSettingsEvent.quietHoursChanged(
            start: ClockTime(hour: 23, minute: 0),
            end: ClockTime(hour: 7, minute: 30),
          ),
        )
        ..add(const NotificationSettingsEvent.dailyLimitChanged(99))
        ..add(const NotificationSettingsEvent.saveRequested()),
      skip: 4,
      verify: (bloc) {
        const expected = NotificationPreferences(
          activeCategories: {
            NotificationCategory.social,
            NotificationCategory.academic,
          },
          quietHoursStart: ClockTime(hour: 23, minute: 0),
          quietHoursEnd: ClockTime(hour: 7, minute: 30),
          dailyLimit: 50,
          mode: NotificationMode.exams,
        );
        verify(() => updatePrefs(expected)).called(1);
        expect(bloc.state.saved, isTrue);
        expect(bloc.state.dirty, isFalse);
      },
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'quitar las horas de silencio',
      build: build,
      seed: () => ready.copyWith(
        preferences: prefs.copyWith(
          quietHoursStart: const ClockTime(hour: 22, minute: 0),
          quietHoursEnd: const ClockTime(hour: 7, minute: 0),
        ),
      ),
      act: (bloc) =>
          bloc.add(const NotificationSettingsEvent.quietHoursCleared()),
      expect: () => [ready.copyWith(dirty: true)],
    );
  });

  group('SubjectSelectorBloc', () {
    late _MockSubjects subjects;
    late _MockAddSubjects add;
    const s1 = CatalogSubject(id: 's1', name: 'Cálculo', course: 1);
    const s2 = CatalogSubject(id: 's2', name: 'Álgebra', course: 1);
    const s3 = CatalogSubject(id: 's3', name: 'Física', course: 1);

    setUpAll(() => registerFallbackValue(<String>[]));

    setUp(() {
      subjects = _MockSubjects();
      add = _MockAddSubjects();
    });

    SubjectSelectorBloc build() =>
        SubjectSelectorBloc(getSubjects: subjects, addSubjects: add);

    blocTest<SubjectSelectorBloc, SubjectSelectorState>(
      'carga la primera página',
      setUp: () =>
          when(
            () => subjects(
              course: any(named: 'course'),
              semester: any(named: 'semester'),
              query: any(named: 'query'),
              page: any(named: 'page'),
            ),
          ).thenAnswer(
            (_) async => const Success(
              CatalogSubjectPage(
                items: [s1, s2],
                page: 0,
                totalPages: 2,
                totalItems: 3,
              ),
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(const SubjectSelectorEvent.started()),
      expect: () => const [
        SubjectSelectorState(),
        SubjectSelectorState(
          status: SubjectSelectorStatus.ready,
          items: [s1, s2],
          hasMore: true,
        ),
      ],
    );

    blocTest<SubjectSelectorBloc, SubjectSelectorState>(
      'error de carga',
      setUp: () => when(
        () => subjects(
          course: any(named: 'course'),
          semester: any(named: 'semester'),
          query: any(named: 'query'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc.add(const SubjectSelectorEvent.started()),
      expect: () => const [
        SubjectSelectorState(),
        SubjectSelectorState(
          status: SubjectSelectorStatus.failure,
          error: AppError.network(),
        ),
      ],
    );

    blocTest<SubjectSelectorBloc, SubjectSelectorState>(
      'filtra por curso',
      setUp: () =>
          when(
            () => subjects(course: 2, semester: null, query: null, page: 0),
          ).thenAnswer(
            (_) async => const Success(
              CatalogSubjectPage(
                items: [],
                page: 0,
                totalPages: 0,
                totalItems: 0,
              ),
            ),
          ),
      build: build,
      seed: () => const SubjectSelectorState(
        status: SubjectSelectorStatus.ready,
        items: [s1],
      ),
      act: (bloc) => bloc.add(const SubjectSelectorEvent.courseChanged(2)),
      expect: () => const [
        SubjectSelectorState(
          status: SubjectSelectorStatus.ready,
          items: [s1],
          course: 2,
        ),
        SubjectSelectorState(items: [s1], course: 2),
        SubjectSelectorState(status: SubjectSelectorStatus.ready, course: 2),
      ],
    );

    blocTest<SubjectSelectorBloc, SubjectSelectorState>(
      'carga la página siguiente',
      setUp: () =>
          when(
            () => subjects(course: null, semester: null, query: null, page: 1),
          ).thenAnswer(
            (_) async => const Success(
              CatalogSubjectPage(
                items: [s3],
                page: 1,
                totalPages: 2,
                totalItems: 3,
              ),
            ),
          ),
      build: build,
      seed: () => const SubjectSelectorState(
        status: SubjectSelectorStatus.ready,
        items: [s1, s2],
        hasMore: true,
      ),
      act: (bloc) => bloc.add(const SubjectSelectorEvent.moreRequested()),
      expect: () => const [
        SubjectSelectorState(
          status: SubjectSelectorStatus.ready,
          items: [s1, s2],
          hasMore: true,
          loadingMore: true,
        ),
        SubjectSelectorState(
          status: SubjectSelectorStatus.ready,
          items: [s1, s2, s3],
          page: 1,
        ),
      ],
    );

    blocTest<SubjectSelectorBloc, SubjectSelectorState>(
      'selecciona y crea las asignaturas elegidas',
      setUp: () =>
          when(() => add(['s1'])).thenAnswer((_) async => const Success(1)),
      build: build,
      seed: () => const SubjectSelectorState(
        status: SubjectSelectorStatus.ready,
        items: [s1, s2],
      ),
      act: (bloc) => bloc
        ..add(const SubjectSelectorEvent.toggled('s1'))
        ..add(const SubjectSelectorEvent.toggled('s2'))
        ..add(const SubjectSelectorEvent.toggled('s2'))
        ..add(const SubjectSelectorEvent.submitted()),
      skip: 4,
      expect: () => [
        SubjectSelectorState(
          status: SubjectSelectorStatus.ready,
          items: [s1.copyWith(alreadyAdded: true), s2],
          addedCount: 1,
        ),
      ],
    );

    blocTest<SubjectSelectorBloc, SubjectSelectorState>(
      'sin selección no llama al backend',
      build: build,
      seed: () =>
          const SubjectSelectorState(status: SubjectSelectorStatus.ready),
      act: (bloc) => bloc.add(const SubjectSelectorEvent.submitted()),
      expect: () => const <SubjectSelectorState>[],
      verify: (_) => verifyNever(() => add(any())),
    );
  });
}
