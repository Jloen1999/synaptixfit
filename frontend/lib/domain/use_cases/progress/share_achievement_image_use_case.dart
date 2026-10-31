import 'dart:typed_data';

import '../../models/result/app_result.dart';
import '../../repositories/share_repository_contract.dart';

/// Comparte la imagen de un logro (insignia o récord) ya dibujada por la
/// pantalla, con un texto que la acompaña. `false` si se cancela.
abstract interface class ShareAchievementImageUseCaseContract {
  Future<AppResult<bool>> call({
    required Uint8List png,
    required String fileName,
    required String text,
  });
}

class ShareAchievementImageUseCase
    implements ShareAchievementImageUseCaseContract {
  const ShareAchievementImageUseCase(this._repository);

  final ShareRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call({
    required Uint8List png,
    required String fileName,
    required String text,
  }) => _repository.shareImage(png: png, fileName: fileName, text: text);
}
