import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/teaching_guide_import_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/teaching_guide_import.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/teaching_guide_import_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/academic/await_teaching_guide_import_use_case.dart';

class _Repository extends Mock
    implements TeachingGuideImportRepositoryContract {}

TeachingGuideImport _import(TeachingGuideImportStatus status) =>
    TeachingGuideImport(id: 'i1', status: status, fileName: 'plan.pdf');

void main() {
  late _Repository repository;

  setUp(() => repository = _Repository());

  test('consulta hasta que el análisis termina y emite cada estado', () async {
    final answers = [
      Success<TeachingGuideImport, AppError>(
        _import(TeachingGuideImportStatus.pending),
      ),
      Success<TeachingGuideImport, AppError>(
        _import(TeachingGuideImportStatus.processing),
      ),
      Success<TeachingGuideImport, AppError>(
        _import(TeachingGuideImportStatus.ready),
      ),
    ];
    when(
      () => repository.get('i1'),
    ).thenAnswer((_) async => answers.removeAt(0));

    final emitted = await AwaitTeachingGuideImportUseCase(repository)(
      'i1',
      interval: Duration.zero,
    ).toList();

    expect(
      emitted.map(
        (r) => (r as Success<TeachingGuideImport, AppError>).value.status,
      ),
      [
        TeachingGuideImportStatus.pending,
        TeachingGuideImportStatus.processing,
        TeachingGuideImportStatus.ready,
      ],
    );
  });

  test('tras varios cortes de red seguidos deja de esperar', () async {
    when(
      () => repository.get('i1'),
    ).thenAnswer((_) async => const Failure(AppError.network()));

    final emitted = await AwaitTeachingGuideImportUseCase(repository)(
      'i1',
      interval: Duration.zero,
    ).toList();

    expect(emitted, hasLength(1));
    verify(
      () => repository.get('i1'),
    ).called(AwaitTeachingGuideImportUseCase.maxNetworkErrors);
  });
}
