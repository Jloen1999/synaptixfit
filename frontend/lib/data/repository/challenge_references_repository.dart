import '../../domain/models/challenges/challenge_references.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
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
  }) async {
    // Dos listas independientes, pedidas a la vez: si una falla (p. ej. la de
    // entreno), la otra se sigue ofreciendo; solo si fallan las dos se avisa.
    final (deadlines, days) = await (
      // Las que vencen en el periodo del reto: el servidor filtra por fechas y
      // valida al guardar (CHALLENGE_LINK_OUTSIDE_PERIOD).
      RepositoryErrorHandler.guard(() async {
        final found = await _remote.deadlinesBetween(
          subjectId,
          from: from,
          to: to,
        );
        return [
          for (final d in found)
            if (!d.completed) d.toDomain(),
        ];
      }),
      // Los días de la rutina en curso no dependen del periodo: se completan
      // al entrenarlos (ADR 0032).
      RepositoryErrorHandler.guard(_remote.routineDayTargets),
    ).wait;
    if (deadlines case Failure(:final error) when days is Failure) {
      return Failure(error);
    }
    return Success([...?deadlines.valueOrNull, ...?days.valueOrNull]);
  }

  @override
  Future<AppResult<String>> fileUrl(String fileId) =>
      RepositoryErrorHandler.guard(() => _remote.fileUrl(fileId));
}
