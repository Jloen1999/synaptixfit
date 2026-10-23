import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/admin/admin_exercise.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/admin/create_admin_exercise_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_admin_exercise_options_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/get_admin_exercise_use_case.dart';
import 'package:synaptixfit/domain/use_cases/admin/update_admin_exercise_use_case.dart';
import 'package:synaptixfit/presentation/screens/admin/exercise_form/bloc/admin_exercise_form_bloc.dart';
import 'package:synaptixfit/presentation/screens/admin/widgets/admin_status.dart';

import 'admin_fixtures.dart';

class _MockOptions extends Mock
    implements GetAdminExerciseOptionsUseCaseContract {}

class _MockGet extends Mock implements GetAdminExerciseUseCaseContract {}

class _MockCreate extends Mock implements CreateAdminExerciseUseCaseContract {}

class _MockUpdate extends Mock implements UpdateAdminExerciseUseCaseContract {}

void main() {
  late _MockOptions getOptions;
  late _MockGet getExercise;
  late _MockCreate create;
  late _MockUpdate update;

  setUpAll(() => registerFallbackValue(const AdminExerciseDraft()));

  setUp(() {
    getOptions = _MockOptions();
    getExercise = _MockGet();
    create = _MockCreate();
    update = _MockUpdate();
    when(() => getOptions()).thenAnswer((_) async => const Success(options));
    when(
      () => getExercise('e1'),
    ).thenAnswer((_) async => const Success(exercise));
  });

  AdminExerciseFormBloc build() => AdminExerciseFormBloc(
    getOptions: getOptions,
    getExercise: getExercise,
    create: create,
    update: update,
  );

  const validDraft = AdminExerciseDraft(name: 'Plancha', met: 3.5);

  blocTest<AdminExerciseFormBloc, AdminExerciseFormState>(
    'alta: carga las opciones con un borrador vacío',
    build: build,
    act: (bloc) => bloc.add(const AdminExerciseFormEvent.started()),
    expect: () => const [
      AdminExerciseFormState(status: AdminStatus.loading),
      AdminExerciseFormState(status: AdminStatus.ready, options: options),
    ],
    verify: (_) => verifyNever(() => getExercise(any())),
  );

  blocTest<AdminExerciseFormBloc, AdminExerciseFormState>(
    'edición: rellena el borrador con el ejercicio',
    build: build,
    act: (bloc) =>
        bloc.add(const AdminExerciseFormEvent.started(exerciseId: 'e1')),
    verify: (bloc) {
      final state = bloc.state;
      expect(state.status, AdminStatus.ready);
      expect(state.isEditing, isTrue);
      expect(state.draft, AdminExerciseDraft.fromExercise(exercise));
      expect(state.draft.bodyPartIds, {1});
      expect(state.draft.targetMuscleIds, {2});
      expect(state.draft.instructions, ['Baja', 'Sube']);
    },
  );

  blocTest<AdminExerciseFormBloc, AdminExerciseFormState>(
    'falla la carga si no llegan las opciones',
    setUp: () => when(
      () => getOptions(),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const AdminExerciseFormEvent.started()),
    expect: () => const [
      AdminExerciseFormState(status: AdminStatus.loading),
      AdminExerciseFormState(
        status: AdminStatus.failure,
        error: AppError.network(),
      ),
    ],
  );

  blocTest<AdminExerciseFormBloc, AdminExerciseFormState>(
    'enviar un borrador no válido muestra errores sin llamar a la API',
    build: build,
    seed: () => const AdminExerciseFormState(
      status: AdminStatus.ready,
      draft: AdminExerciseDraft(name: 'x', met: 40),
    ),
    act: (bloc) => bloc.add(const AdminExerciseFormEvent.submitted()),
    expect: () => const [
      AdminExerciseFormState(
        status: AdminStatus.ready,
        draft: AdminExerciseDraft(name: 'x', met: 40),
        showErrors: true,
      ),
    ],
    verify: (_) => verifyNever(() => create(any())),
  );

  blocTest<AdminExerciseFormBloc, AdminExerciseFormState>(
    'alta: draftChanged + submitted crea el ejercicio',
    setUp: () => when(
      () => create(any()),
    ).thenAnswer((_) async => const Success(exercise)),
    build: build,
    seed: () => const AdminExerciseFormState(status: AdminStatus.ready),
    act: (bloc) => bloc
      ..add(const AdminExerciseFormEvent.draftChanged(validDraft))
      ..add(const AdminExerciseFormEvent.submitted()),
    expect: () => const [
      AdminExerciseFormState(status: AdminStatus.ready, draft: validDraft),
      AdminExerciseFormState(
        status: AdminStatus.ready,
        draft: validDraft,
        submitting: true,
        showErrors: true,
      ),
      AdminExerciseFormState(
        status: AdminStatus.ready,
        draft: validDraft,
        showErrors: true,
        effect: AdminExerciseFormEffect.saved(exercise),
      ),
    ],
    verify: (_) => verify(() => create(validDraft)).called(1),
  );

  blocTest<AdminExerciseFormBloc, AdminExerciseFormState>(
    'edición: submitted actualiza y propaga el error de negocio',
    setUp: () => when(() => update('e1', any())).thenAnswer(
      (_) async => const Failure(
        AppError.business('EXERCISE_CATALOG_REFERENCE_INVALID'),
      ),
    ),
    build: build,
    seed: () => const AdminExerciseFormState(
      status: AdminStatus.ready,
      exerciseId: 'e1',
      draft: validDraft,
    ),
    act: (bloc) => bloc.add(const AdminExerciseFormEvent.submitted()),
    verify: (bloc) {
      expect(
        bloc.state.effect,
        const AdminExerciseFormEffect.failure(
          AppError.business('EXERCISE_CATALOG_REFERENCE_INVALID'),
        ),
      );
      expect(bloc.state.submitting, isFalse);
      verify(() => update('e1', validDraft)).called(1);
      verifyNever(() => create(any()));
    },
  );
}
