import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/profile/onboarding_step.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/profile/onboarding_status.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/change_password_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/update_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/complete_onboarding_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_onboarding_status_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/onboarding/bloc/onboarding_bloc.dart';

import 'profile_fixtures.dart';

class _MockStatus extends Mock implements GetOnboardingStatusUseCaseContract {}

class _MockComplete extends Mock implements CompleteOnboardingUseCaseContract {}

class _MockChangePassword extends Mock
    implements ChangePasswordUseCaseContract {}

class _MockUpdateAccount extends Mock implements UpdateAccountUseCaseContract {}

class _MockGetAccount extends Mock implements GetAccountUseCaseContract {}

void main() {
  late _MockStatus getStatus;
  late _MockComplete complete;
  late _MockChangePassword changePassword;
  late _MockUpdateAccount updateAccount;
  late _MockGetAccount getAccount;

  const done = OnboardingStatus(completed: true);

  OnboardingBloc build() => OnboardingBloc(
    getStatus: getStatus,
    complete: complete,
    changePassword: changePassword,
    updateAccount: updateAccount,
    getAccount: getAccount,
  );

  setUp(() {
    getStatus = _MockStatus();
    complete = _MockComplete();
    changePassword = _MockChangePassword();
    updateAccount = _MockUpdateAccount();
    getAccount = _MockGetAccount();
  });

  group('started', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'muestra los pasos pendientes en el orden del servidor',
      setUp: () => when(() => getStatus()).thenAnswer(
        (_) async => const Success(
          OnboardingStatus(
            completed: false,
            pendingSteps: [
              OnboardingStep.account,
              OnboardingStep.focus,
              OnboardingStep.wellnessProfile,
              OnboardingStep.academicProfile,
              OnboardingStep.subjects,
            ],
          ),
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(const OnboardingEvent.started()),
      expect: () => const [
        OnboardingState(),
        OnboardingState(
          status: OnboardingStatusView.ready,
          steps: [
            OnboardingStep.account,
            OnboardingStep.focus,
            OnboardingStep.wellnessProfile,
            OnboardingStep.academicProfile,
            OnboardingStep.subjects,
          ],
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'al elegir solo estudios guarda el enfoque y pide al servidor los pasos que quedan',
      setUp: () {
        when(
          () => updateAccount(usageFocus: UsageFocus.academic),
        ).thenAnswer((_) async => const Success(testAccount));
        when(() => getStatus()).thenAnswer(
          (_) async => const Success(
            OnboardingStatus(
              completed: false,
              pendingSteps: [
                OnboardingStep.academicProfile,
                OnboardingStep.subjects,
              ],
            ),
          ),
        );
      },
      seed: () => const OnboardingState(
        status: OnboardingStatusView.ready,
        steps: [
          OnboardingStep.focus,
          OnboardingStep.wellnessProfile,
          OnboardingStep.academicProfile,
          OnboardingStep.subjects,
        ],
      ),
      build: build,
      act: (bloc) =>
          bloc.add(const OnboardingEvent.focusSubmitted(UsageFocus.academic)),
      verify: (bloc) {
        expect(bloc.state.steps, const [
          OnboardingStep.focus,
          OnboardingStep.academicProfile,
          OnboardingStep.subjects,
        ]);
        expect(bloc.state.currentStep, OnboardingStep.academicProfile);
        expect(bloc.state.account, testAccount);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'si ya está completado termina sin mostrar pasos',
      setUp: () =>
          when(() => getStatus()).thenAnswer((_) async => const Success(done)),
      build: build,
      act: (bloc) => bloc.add(const OnboardingEvent.started()),
      expect: () => const [
        OnboardingState(),
        OnboardingState(status: OnboardingStatusView.finished),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emite failure si no puede cargar el estado',
      setUp: () => when(
        () => getStatus(),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc.add(const OnboardingEvent.started()),
      expect: () => const [
        OnboardingState(),
        OnboardingState(
          status: OnboardingStatusView.failure,
          error: AppError.network(),
        ),
      ],
    );
  });

  group('avance', () {
    const twoSteps = OnboardingState(
      status: OnboardingStatusView.ready,
      steps: [OnboardingStep.academicProfile, OnboardingStep.wellnessProfile],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'saltar un paso pasa al siguiente',
      build: build,
      seed: () => twoSteps,
      act: (bloc) => bloc.add(const OnboardingEvent.stepSkipped()),
      expect: () => [twoSteps.copyWith(index: 1)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'completar el último paso cierra el onboarding',
      setUp: () =>
          when(() => complete()).thenAnswer((_) async => const Success(done)),
      build: build,
      seed: () => twoSteps.copyWith(index: 1),
      act: (bloc) => bloc.add(const OnboardingEvent.stepCompleted()),
      expect: () => [
        twoSteps.copyWith(index: 1, busy: true),
        twoSteps.copyWith(index: 1, status: OnboardingStatusView.finished),
      ],
      verify: (_) => verify(() => complete()).called(1),
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'si el backend exige el perfil físico, muestra el error y no termina',
      setUp: () => when(() => complete()).thenAnswer(
        (_) async => const Failure(
          AppError.business('PROFILE_ONBOARDING_WELLNESS_REQUIRED'),
        ),
      ),
      build: build,
      seed: () => twoSteps.copyWith(index: 1),
      act: (bloc) => bloc.add(const OnboardingEvent.stepCompleted()),
      expect: () => [
        twoSteps.copyWith(index: 1, busy: true),
        twoSteps.copyWith(
          index: 1,
          actionError: const AppError.business(
            'PROFILE_ONBOARDING_WELLNESS_REQUIRED',
          ),
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'volver atrás reduce el índice',
      build: build,
      seed: () => twoSteps.copyWith(index: 1),
      act: (bloc) => bloc.add(const OnboardingEvent.previousRequested()),
      expect: () => [twoSteps],
    );

    test('el perfil físico no se puede saltar', () {
      expect(twoSteps.canSkip, isTrue);
      expect(twoSteps.copyWith(index: 1).canSkip, isFalse);
    });
  });

  group('paso de cuenta', () {
    const accountStep = OnboardingState(
      status: OnboardingStatusView.ready,
      steps: [OnboardingStep.account, OnboardingStep.wellnessProfile],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'crea la contraseña, actualiza el nombre y avanza',
      setUp: () {
        when(
          () => changePassword(newPassword: 'clave1234'),
        ).thenAnswer((_) async => const Success(unit));
        when(
          () => updateAccount(fullName: 'Ana López'),
        ).thenAnswer((_) async => const Success(testAccount));
      },
      build: build,
      seed: () => accountStep,
      act: (bloc) => bloc.add(
        const OnboardingEvent.accountSubmitted(
          fullName: ' Ana López ',
          password: 'clave1234',
        ),
      ),
      expect: () => [
        accountStep.copyWith(busy: true),
        accountStep.copyWith(account: testAccount),
        accountStep.copyWith(account: testAccount, index: 1),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'si falla la contraseña se queda en el paso con el error',
      setUp: () =>
          when(
            () => changePassword(newPassword: any(named: 'newPassword')),
          ).thenAnswer(
            (_) async => const Failure(AppError.business('AUTH_WEAK_PASSWORD')),
          ),
      build: build,
      seed: () => accountStep,
      act: (bloc) =>
          bloc.add(const OnboardingEvent.accountSubmitted(password: 'debil')),
      expect: () => [
        accountStep.copyWith(busy: true),
        accountStep.copyWith(
          actionError: const AppError.business('AUTH_WEAK_PASSWORD'),
        ),
      ],
      verify: (_) =>
          verifyNever(() => updateAccount(fullName: any(named: 'fullName'))),
    );
  });
}
