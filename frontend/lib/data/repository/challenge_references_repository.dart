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
    // Las que vencen en el periodo del reto: el servidor filtra por fechas y
    // valida al guardar (CHALLENGE_LINK_OUTSIDE_PERIOD).
    final deadlines = await _remote.deadlinesBetween(
      subjectId,
      from: from,
      to: to,
    );
    // Los días de la rutina en curso no dependen del periodo: se completan al
    // entrenarlos (ADR 0032).
    final days = await _remote.routineDayTargets();
    return [
      for (final d in deadlines)
        if (!d.completed) d.toDomain(),
      ...days,
    ];
  });

  @override
  Future<AppResult<String>> fileUrl(String fileId) =>
      RepositoryErrorHandler.guard(() => _remote.fileUrl(fileId));
}
