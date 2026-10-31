import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/models/profile/enrollment_proposal.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/enrollment_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/profile/apply_enrollment_use_case.dart';

class _Repo extends Mock implements EnrollmentRepositoryContract {}

void main() {
  test(
    'las del catálogo van por id y el resto como asignaturas propias',
    () async {
      final repo = _Repo();
      const catalog = EnrollmentSubject(name: 'Redes', catalogSubjectId: 'c1');
      const own = EnrollmentSubject(name: 'Optativa', credits: 6);
      when(
        () => repo.apply(
          degreeId: 'd1',
          catalogSubjectIds: ['c1'],
          customSubjects: [own],
        ),
      ).thenAnswer(
        (_) async => const Success(
          EnrollmentApplyResult(subjectsAdded: 2, degreeLinked: true),
        ),
      );

      final applied = await ApplyEnrollmentUseCase(repo)(
        const EnrollmentProposal(degreeId: 'd1', subjects: [catalog, own]),
        [catalog, own],
      );
      expect(applied.valueOrNull?.subjectsAdded, 2);
    },
  );
}
