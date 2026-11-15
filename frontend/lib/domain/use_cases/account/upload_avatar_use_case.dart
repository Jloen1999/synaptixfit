import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/account_repository_contract.dart';

/// Sube una foto de perfil hecha o elegida en el móvil y devuelve la cuenta
/// con su dirección nueva. El servidor la pone derecha, la recorta al
/// cuadrado central y la reduce (ADR 0052).
abstract interface class UploadAvatarUseCaseContract {
  Future<AppResult<Account>> call({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });
}

class UploadAvatarUseCase implements UploadAvatarUseCaseContract {
  const UploadAvatarUseCase(this._repository);

  final AccountRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) => _repository.uploadAvatar(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
