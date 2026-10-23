import '../../domain/models/challenges/challenge_references.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/challenge_references_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/challenges/challenge_references_remote_data_source.dart';

class ChallengeReferencesRepository
    implements ChallengeReferencesRepositoryContract {
  ChallengeReferencesRepository(this._remote);

  final ChallengeReferencesRemoteDataSource _remote;

  @override
  Future<AppResult<List<ChallengeSubjectOption>>> subjects() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.subjects())
            .where((s) => !s.archived)
            .map((s) => s.toDomain())
            .toList(),
      );

  @override
  Future<AppResult<ChallengeAttachmentOptions>> attachments(
    String? subjectId,
  ) => RepositoryErrorHandler.guard(() async {
    final notes = (await _remote.notes(
      subjectId,
    )).map((n) => n.toDomain()).toList();
    final files = subjectId == null
        ? const <ChallengeFileOption>[]
        : (await _remote.files(subjectId)).map((f) => f.toDomain()).toList();
    return ChallengeAttachmentOptions(notes: notes, files: files);
  });

  @override
  Future<AppResult<List<ChallengeLinkOption>>> linkTargets({
    String? subjectId,
    required DateTime from,
    required DateTime to,
  }) => RepositoryErrorHandler.guard(() async {
    final deadlines = await _remote.upcomingDeadlines(subjectId);
    final blocks = await _remote.blocks(
      from: from,
      to: to,
      subjectId: subjectId,
    );
    return [
      ...deadlines.where((d) => !d.completed).map((d) => d.toDomain()),
      ...blocks.where((b) => b.isLinkable).map((b) => b.toDomain()),
    ];
  });

  @override
  Future<AppResult<String>> fileUrl(String fileId) =>
      RepositoryErrorHandler.guard(() => _remote.fileUrl(fileId));
}
