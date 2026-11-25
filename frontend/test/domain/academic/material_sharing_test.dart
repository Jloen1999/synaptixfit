import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/material_sharing.dart';
import 'package:synaptixfit/domain/models/academic/note.dart';
import 'package:synaptixfit/domain/models/academic/subject_file.dart';
import 'package:synaptixfit/domain/models/academic/subject_material.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/note_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/subject_file_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_material_file_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/share_note_with_everyone_use_case.dart';

class _Notes extends Mock implements NoteRepositoryContract {}

class _Files extends Mock implements SubjectFileRepositoryContract {}

Note _note(String id, DateTime? updated) => Note(
  id: id,
  title: id,
  content: '',
  visibility: Visibility.private,
  quickNote: false,
  updatedAt: updated,
);

SubjectFile _file(String id, DateTime? created) => SubjectFile(
  id: id,
  subjectId: 's1',
  fileName: '$id.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 10,
  aiReadable: true,
  createdAt: created,
);

/// Lista «Material» y «Compartir» (ADR 0064).
void main() {
  setUpAll(() => registerFallbackValue(Visibility.public));

  test('«Material» junta apuntes y archivos, lo más reciente primero y lo '
      'que no tiene fecha al final', () {
    final list = SubjectMaterial.merge(
      [_note('n-old', DateTime(2026, 11, 1)), _note('n-none', null)],
      [_file('f-new', DateTime(2026, 11, 20)), _file('f-same', DateTime(2026, 11, 1))],
    );
    expect(list.map((m) => m.id), ['f-new', 'n-old', 'f-same', 'n-none']);
    expect(list.first, isA<FileMaterial>());
    expect(list[1].aiReadable, isTrue);
  });

  test('«Para todos» pide la visibilidad pública (el servidor la rebaja)', () async {
    final notes = _Notes();
    final note = _note('n1', null).copyWith(visibility: Visibility.friends);
    when(
      () => notes.setNoteVisibility('n1', Visibility.public),
    ).thenAnswer((_) async => Success(note));

    final result = await ShareNoteWithEveryoneUseCase(notes)('n1');

    expect(result.valueOrNull?.visibility, Visibility.friends);
  });

  group('el archivo para descargar o compartir fuera', () {
    late _Notes notes;
    late _Files files;
    late GetMaterialFileUseCase useCase;

    setUp(() {
      notes = _Notes();
      files = _Files();
      useCase = GetMaterialFileUseCase(notes, files);
    });

    test('de un apunte, su PDF', () async {
      final pdf = MaterialFile(
        fileName: 'n1.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List(3),
      );
      when(() => notes.getNotePdf('n1')).thenAnswer((_) async => Success(pdf));

      expect((await useCase(NoteMaterial(_note('n1', null)))).valueOrNull, pdf);
      verifyNever(() => files.getFileContent(any(), withBytes: any(named: 'withBytes')));
    });

    test('de un archivo, el original con su nombre y su tipo', () async {
      final f = _file('f1', null);
      when(() => files.getFileContent('f1', withBytes: true)).thenAnswer(
        (_) async => Success(
          FileContent(
            file: f,
            url: const SignedUrl(url: 'https://x'),
            bytes: Uint8List.fromList([1, 2]),
          ),
        ),
      );

      final result = (await useCase(FileMaterial(f))).valueOrNull!;

      expect(result.fileName, 'f1.pdf');
      expect(result.mimeType, 'application/pdf');
      expect(result.bytes, [1, 2]);
    });

    test('si falla la descarga, llega el error', () async {
      when(
        () => files.getFileContent('f1', withBytes: true),
      ).thenAnswer((_) async => const Failure(AppError.network()));
      expect(
        (await useCase(FileMaterial(_file('f1', null)))).errorOrNull,
        const AppError.network(),
      );
    });
  });
}
