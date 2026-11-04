import '../../domain/enums/legal_document_kind.dart';
import '../../domain/models/profile/legal_document.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/legal_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/profile/legal_remote_data_source.dart';

/// Implementa [LegalRepositoryContract] con [LegalRemoteDataSource].
class LegalRepository implements LegalRepositoryContract {
  const LegalRepository(this._remote);

  final LegalRemoteDataSource _remote;

  @override
  Future<AppResult<LegalDocument>> document(
    LegalDocumentKind kind, {
    required String language,
  }) => RepositoryErrorHandler.guard(
    () async =>
        (await _remote.document(kind, language: language)).toDomain(kind),
  );

  @override
  Future<AppResult<LegalAcceptance>> acceptance() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.acceptance()).toDomain(),
      );

  @override
  Future<AppResult<Unit>> accept(String version) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.accept(version);
        return unit;
      });
}
