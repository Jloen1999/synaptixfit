import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/profile/activity_level.dart';
import 'package:synaptixfit/domain/enums/profile/fitness_goal.dart';
import 'package:synaptixfit/domain/enums/profile/goal_suggestion_source.dart';
import 'package:synaptixfit/domain/enums/profile/sex.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/profile/academic_profile.dart';
import 'package:synaptixfit/domain/models/profile/wellness_history.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/update_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_profile_summary_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/save_academic_profile_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/save_wellness_profile_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/suggest_goals_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/update_wellness_profile_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/edit_academic/bloc/academic_form_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/edit_account/bloc/edit_account_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/edit_wellness/bloc/wellness_form_bloc.dart';

import 'profile_fixtures.dart';

class _MockSummary extends Mock implements GetProfileSummaryUseCaseContract {}

class _MockSaveWellness extends Mock
    implements SaveWellnessProfileUseCaseContract {}

class _MockUpdateWellness extends Mock
    implements UpdateWellnessProfileUseCaseContract {}

class _MockSuggest extends Mock implements SuggestGoalsUseCaseContract {}

class _MockSaveAcademic extends Mock
    implements SaveAcademicProfileUseCaseContract {}

class _MockUpdateAccount extends Mock implements UpdateAccountUseCaseContract {}

void main() {
  setUpAll(() {
    registerFallbackValue(testDraft);
    registerFallbackValue(const AcademicProfileDraft());
  });

  group('WellnessFormBloc', () {
    late _MockSummary summary;
    late _MockSaveWellness save;
    late _MockUpdateWellness update;
    late _MockSuggest suggest;

    WellnessFormBloc build() => WellnessFormBloc(
      getSummary: summary,
      saveProfile: save,
      updateProfile: update,
      suggestGoals: suggest,
    );

    setUp(() {
      summary = _MockSummary();
      save = _MockSaveWellness();
      update = _MockUpdateWellness();
      suggest = _MockSuggest();
    });

    blocTest<WellnessFormBloc, WellnessFormState>(
      'carga el perfil actual',
      setUp: () => when(
        () => summary(),
      ).thenAnswer((_) async => const Success(testSummary)),
      build: build,
      act: (bloc) => bloc.add(const WellnessFormEvent.started()),
      expect: () => const [
        WellnessFormState(),
        WellnessFormState(
          status: WellnessFormStatus.ready,
          initial: testWellness,
        ),
      ],
    );

    blocTest<WellnessFormBloc, WellnessFormState>(
      'emite failure si no puede cargar',
      setUp: () => when(
        () => summary(),
      ).thenAnswer((_) async => const Failure(AppError.server())),
      build: build,
      act: (bloc) => bloc.add(const WellnessFormEvent.started()),
      expect: () => const [
        WellnessFormState(),
        WellnessFormState(
          status: WellnessFormStatus.failure,
          loadError: AppError.server(),
        ),
      ],
    );

    blocTest<WellnessFormBloc, WellnessFormState>(
      'sin perfil previo crea el perfil completo (PUT)',
      setUp: () => when(
        () => save(any()),
      ).thenAnswer((_) async => const Success(testWellness)),
      build: build,
      seed: () => const WellnessFormState(status: WellnessFormStatus.ready),
      act: (bloc) => bloc.add(const WellnessFormEvent.submitted(testDraft)),
      expect: () => const [
        WellnessFormState(status: WellnessFormStatus.ready, saving: true),
        WellnessFormState(
          status: WellnessFormStatus.ready,
          initial: testWellness,
          saved: testWellness,
        ),
      ],
      verify: (_) {
        verify(() => save(testDraft)).called(1);
        verifyNever(() => update(any()));
      },
    );

    blocTest<WellnessFormBloc, WellnessFormState>(
      'con perfil previo edita con PATCH',
      setUp: () => when(
        () => update(any()),
      ).thenAnswer((_) async => const Success(testWellness)),
      build: build,
      seed: () => const WellnessFormState(
        status: WellnessFormStatus.ready,
        initial: testWellness,
      ),
      act: (bloc) => bloc.add(const WellnessFormEvent.submitted(testDraft)),
      verify: (_) {
        verify(() => update(testDraft)).called(1);
        verifyNever(() => save(any()));
      },
    );

    blocTest<WellnessFormBloc, WellnessFormState>(
      'un error al guardar se expone como actionError',
      setUp: () => when(
        () => save(any()),
      ).thenAnswer((_) async => const Failure(AppError.validation())),
      build: build,
      seed: () => const WellnessFormState(status: WellnessFormStatus.ready),
      act: (bloc) => bloc.add(const WellnessFormEvent.submitted(testDraft)),
      expect: () => const [
        WellnessFormState(status: WellnessFormStatus.ready, saving: true),
        WellnessFormState(
          status: WellnessFormStatus.ready,
          actionError: AppError.validation(),
        ),
      ],
    );

    blocTest<WellnessFormBloc, WellnessFormState>(
      '«Recomiéndame» guarda las sugerencias y su origen',
      setUp: () =>
          when(
            () => suggest(
              age: 21,
              sex: Sex.female,
              activityLevel: ActivityLevel.light,
            ),
          ).thenAnswer(
            (_) async => const Success(
              GoalSuggestions(
                source: GoalSuggestionSource.ai,
                suggestions: [GoalSuggestion(goal: FitnessGoal.hypertrophy)],
              ),
            ),
          ),
      build: build,
      seed: () => const WellnessFormState(status: WellnessFormStatus.ready),
      act: (bloc) => bloc.add(
        const WellnessFormEvent.suggestionsRequested(
          age: 21,
          sex: Sex.female,
          activityLevel: ActivityLevel.light,
        ),
      ),
      expect: () => const [
        WellnessFormState(status: WellnessFormStatus.ready, suggesting: true),
        WellnessFormState(
          status: WellnessFormStatus.ready,
          suggestions: GoalSuggestions(
            source: GoalSuggestionSource.ai,
            suggestions: [GoalSuggestion(goal: FitnessGoal.hypertrophy)],
          ),
        ),
      ],
    );
  });

  group('AcademicFormBloc', () {
    late _MockSummary summary;
    late _MockSaveAcademic save;

    setUp(() {
      summary = _MockSummary();
      save = _MockSaveAcademic();
    });

    blocTest<AcademicFormBloc, AcademicFormState>(
      'en el onboarding no consulta el perfil',
      build: () => AcademicFormBloc(getSummary: summary, saveProfile: save),
      act: (bloc) =>
          bloc.add(const AcademicFormEvent.started(loadExisting: false)),
      expect: () => const [AcademicFormState(status: AcademicFormStatus.ready)],
      verify: (_) => verifyNever(() => summary()),
    );

    blocTest<AcademicFormBloc, AcademicFormState>(
      'con carrera del catálogo envía su id y nombres',
      setUp: () => when(
        () => save(any()),
      ).thenAnswer((_) async => const Success(testAcademic)),
      build: () => AcademicFormBloc(getSummary: summary, saveProfile: save),
      seed: () => const AcademicFormState(status: AcademicFormStatus.ready),
      act: (bloc) => bloc
        ..add(const AcademicFormEvent.degreeSelected(testDegree))
        ..add(
          const AcademicFormEvent.submitted(
            AcademicProfileDraft(university: 'Otra', semester: 3),
          ),
        ),
      skip: 2,
      expect: () => const [
        AcademicFormState(
          status: AcademicFormStatus.ready,
          selectedDegree: testDegree,
          initial: testAcademic,
          saved: testAcademic,
        ),
      ],
      verify: (_) => verify(
        () => save(
          const AcademicProfileDraft(
            university: 'Universidad de Granada',
            degree: 'Grado en Informática',
            degreeId: 'd1',
            semester: 3,
          ),
        ),
      ).called(1),
    );

    blocTest<AcademicFormBloc, AcademicFormState>(
      'fechas inválidas: muestra el error del backend',
      setUp: () => when(() => save(any())).thenAnswer(
        (_) async =>
            const Failure(AppError.business('PROFILE_INVALID_CLASS_DATES')),
      ),
      build: () => AcademicFormBloc(getSummary: summary, saveProfile: save),
      seed: () => const AcademicFormState(status: AcademicFormStatus.ready),
      act: (bloc) =>
          bloc.add(const AcademicFormEvent.submitted(AcademicProfileDraft())),
      expect: () => const [
        AcademicFormState(status: AcademicFormStatus.ready, saving: true),
        AcademicFormState(
          status: AcademicFormStatus.ready,
          actionError: AppError.business('PROFILE_INVALID_CLASS_DATES'),
        ),
      ],
    );
  });

  group('EditAccountBloc', () {
    late _MockUpdateAccount update;

    setUp(() => update = _MockUpdateAccount());

    blocTest<EditAccountBloc, EditAccountState>(
      'guarda nombre, avatar y privacidad',
      setUp: () => when(
        () => update(
          fullName: 'Ana',
          avatarUrl: 'https://img.es/a.png',
          privacy: Visibility.public,
        ),
      ).thenAnswer((_) async => const Success(testAccount)),
      build: () => EditAccountBloc(updateAccount: update),
      act: (bloc) => bloc.add(
        const EditAccountEvent.submitted(
          fullName: ' Ana ',
          avatarUrl: ' https://img.es/a.png ',
          privacy: Visibility.public,
        ),
      ),
      expect: () => const [
        EditAccountState.submitting(),
        EditAccountState.success(testAccount),
      ],
    );

    blocTest<EditAccountBloc, EditAccountState>(
      'propaga el error',
      setUp: () => when(
        () => update(
          fullName: any(named: 'fullName'),
          avatarUrl: any(named: 'avatarUrl'),
          privacy: any(named: 'privacy'),
        ),
      ).thenAnswer((_) async => const Failure(AppError.validation())),
      build: () => EditAccountBloc(updateAccount: update),
      act: (bloc) => bloc.add(
        const EditAccountEvent.submitted(
          fullName: 'A',
          avatarUrl: '',
          privacy: Visibility.private,
        ),
      ),
      expect: () => const [
        EditAccountState.submitting(),
        EditAccountState.failure(AppError.validation()),
      ],
    );
  });
}
