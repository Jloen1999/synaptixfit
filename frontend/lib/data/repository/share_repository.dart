import 'dart:typed_data';

import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/share_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/system_share_data_source.dart';

/// Implementa [ShareRepositoryContract] con [SystemShareDataSource].
class ShareRepository implements ShareRepositoryContract {
  const ShareRepository(this._system);

  final SystemShareDataSource _system;

  @override
  Future<AppResult<bool>> shareImage({
    required Uint8List png,
    required String fileName,
    required String text,
  }) => RepositoryErrorHandler.guard(
    () => _system.sharePng(png: png, fileName: fileName, text: text),
  );

  @override
  Future<AppResult<bool>> shareText({required String text, String? subject}) =>
      RepositoryErrorHandler.guard(
        () => _system.shareText(text: text, subject: subject),
      );
}
