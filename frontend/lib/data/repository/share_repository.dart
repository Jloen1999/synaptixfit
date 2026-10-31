import 'dart:typed_data';

import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/share_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/image_share_data_source.dart';

/// Implementa [ShareRepositoryContract] con [ImageShareDataSource].
class ShareRepository implements ShareRepositoryContract {
  const ShareRepository(this._images);

  final ImageShareDataSource _images;

  @override
  Future<AppResult<bool>> shareImage({
    required Uint8List png,
    required String fileName,
    required String text,
  }) => RepositoryErrorHandler.guard(
    () => _images.sharePng(png: png, fileName: fileName, text: text),
  );
}
