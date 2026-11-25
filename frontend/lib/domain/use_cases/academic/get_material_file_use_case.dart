import '../../models/academic/material_sharing.dart';
import '../../models/academic/subject_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/note_repository_contract.dart';
import '../../repositories/subject_file_repository_contract.dart';

/// El archivo que se guarda o se manda fuera de la app (ADR 0064): de un
/// apunte, su PDF (lo genera el servidor); de un archivo, el original (lo
/// sirve el servidor con una URL firmada: el cliente no habla con R2).
abstract interface class GetMaterialFileUseCaseContract {
  Future<AppResult<MaterialFile>> call(SubjectMaterial material);
}

class GetMaterialFileUseCase implements GetMaterialFileUseCaseContract {
  const GetMaterialFileUseCase(this._notes, this._files);

  final NoteRepositoryContract _notes;
  final SubjectFileRepositoryContract _files;

  @override
  Future<AppResult<MaterialFile>> call(SubjectMaterial material) async {
    switch (material) {
      case NoteMaterial(:final note):
        return _notes.getNotePdf(note.id);
      case FileMaterial(:final file):
        final content = await _files.getFileContent(file.id, withBytes: true);
        return content.map(
          (c) => MaterialFile(
            fileName: file.fileName,
            mimeType: file.mimeType,
            bytes: c.bytes!,
          ),
        );
    }
  }
}
