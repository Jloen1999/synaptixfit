import '../../models/academic/material_sharing.dart';
import '../../models/result/app_result.dart';
import '../../repositories/file_export_repository_contract.dart';

/// «Descargar» (ADR 0064): guarda el archivo en el teléfono («Guardar como»;
/// en web, la descarga del navegador). `false` si se cancela.
abstract interface class SaveFileToDeviceUseCaseContract {
  Future<AppResult<bool>> call(MaterialFile file);
}

class SaveFileToDeviceUseCase implements SaveFileToDeviceUseCaseContract {
  const SaveFileToDeviceUseCase(this._repository);

  final FileExportRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call(MaterialFile file) =>
      _repository.saveFile(file);
}
