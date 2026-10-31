import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/subject_file.dart';
import 'package:synaptixfit/domain/models/profile/enrollment_proposal.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/profile/apply_enrollment_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/read_enrollment_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/enrollment_import/bloc/enrollment_import_bloc.dart';

class _Read extends Mock implements ReadEnrollmentUseCaseContract {}

class _Apply extends Mock implements ApplyEnrollmentUseCaseContract {}

/// Datos inventados: nunca se usan documentos reales en los tests.
void main() {
  late _Read read;
  late _Apply apply;
  final file = FileUploadPayload(
    fileName: 'matricula.pdf',
    mimeType: 'application/pdf',
    bytes: Uint8List.fromList([1, 2, 3]),
  );
  const proposal = EnrollmentProposal(
    degreeName: 'Grado en Informática',
    degreeId: 'd1',
    subjects: [
      EnrollmentSubject(name: 'Redes', catalogSubjectId: 'c1'),
      EnrollmentSubject(name: 'Optativa'),
      EnrollmentSubject(name: 'Ya la tengo', alreadyAdded: true),
    ],
  );

  setUpAll(() {
    registerFallbackValue(file);
    registerFallbackValue(proposal);
  });

  setUp(() {
    read = _Read();
    apply = _Apply();
  });

  EnrollmentImportBloc build() =>
      EnrollmentImportBloc(read: read, apply: apply);

  blocTest<EnrollmentImportBloc, EnrollmentImportState>(
    'sin permiso no se envía el documento',
    build: build,
    act: (bloc) => bloc.add(EnrollmentImportEvent.fileChosen(file)),
    expect: () => const <EnrollmentImportState>[],
    verify: (_) =>
        verifyNever(() => read(any(), consent: any(named: 'consent'))),
  );

  blocTest<EnrollmentImportBloc, EnrollmentImportState>(
    'con permiso lee y propone lo que aún no tiene',
    setUp: () => when(
      () => read(any(), consent: true),
    ).thenAnswer((_) async => const Success(proposal)),
    build: build,
    seed: () => const EnrollmentImportState(consent: true),
    act: (bloc) => bloc.add(EnrollmentImportEvent.fileChosen(file)),
    expect: () => const [
      EnrollmentImportState(consent: true, step: EnrollmentStep.reading),
      EnrollmentImportState(
        consent: true,
        step: EnrollmentStep.review,
        proposal: proposal,
        selected: {0, 1},
      ),
    ],
  );

  blocTest<EnrollmentImportBloc, EnrollmentImportState>(
    'añade solo lo elegido',
    setUp: () => when(() => apply(proposal, any())).thenAnswer(
      (_) async => const Success(
        EnrollmentApplyResult(subjectsAdded: 1, degreeLinked: true),
      ),
    ),
    build: build,
    seed: () => const EnrollmentImportState(
      consent: true,
      step: EnrollmentStep.review,
      proposal: proposal,
      selected: {0},
    ),
    act: (bloc) => bloc.add(const EnrollmentImportEvent.applyRequested()),
    verify: (bloc) {
      expect(bloc.state.step, EnrollmentStep.done);
      verify(() => apply(proposal, [proposal.subjects.first])).called(1);
    },
  );

  blocTest<EnrollmentImportBloc, EnrollmentImportState>(
    'si falla la lectura vuelve al principio con el error',
    setUp: () => when(() => read(any(), consent: true)).thenAnswer(
      (_) async => const Failure(AppError.business('ENROLLMENT_NOTHING_FOUND')),
    ),
    build: build,
    seed: () => const EnrollmentImportState(consent: true),
    act: (bloc) => bloc.add(EnrollmentImportEvent.fileChosen(file)),
    verify: (bloc) {
      expect(bloc.state.step, EnrollmentStep.intro);
      expect(
        bloc.state.error,
        const AppError.business('ENROLLMENT_NOTHING_FOUND'),
      );
    },
  );
}
