import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/challenge_link_type.dart';
import '../../../../domain/models/challenges/challenge_references.dart';
import 'challenge_api_values.dart';

part 'challenge_reference_dto.freezed.dart';
part 'challenge_reference_dto.g.dart';

/// Campos de `SubjectResponse` que usan los retos.
@freezed
abstract class ChallengeSubjectDto with _$ChallengeSubjectDto {
  const factory ChallengeSubjectDto({
    required String id,
    required String name,
    String? code,
    @Default(false) bool archived,
  }) = _ChallengeSubjectDto;

  const ChallengeSubjectDto._();

  factory ChallengeSubjectDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeSubjectDtoFromJson(json);

  ChallengeSubjectOption toDomain() =>
      ChallengeSubjectOption(id: id, name: name, code: code);
}

/// Campos de `NoteResponse` que usan los retos.
@freezed
abstract class ChallengeNoteDto with _$ChallengeNoteDto {
  const factory ChallengeNoteDto({
    required String id,
    String? title,
    String? subjectId,
  }) = _ChallengeNoteDto;

  const ChallengeNoteDto._();

  factory ChallengeNoteDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeNoteDtoFromJson(json);

  ChallengeNoteOption toDomain() =>
      ChallengeNoteOption(id: id, title: title ?? '', subjectId: subjectId);
}

/// `PageResponseNoteResponse` (solo los elementos).
@freezed
abstract class ChallengeNotePageDto with _$ChallengeNotePageDto {
  const factory ChallengeNotePageDto({
    @Default(<ChallengeNoteDto>[]) List<ChallengeNoteDto> items,
  }) = _ChallengeNotePageDto;

  factory ChallengeNotePageDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeNotePageDtoFromJson(json);
}

/// Campos de `SubjectFileResponse` que usan los retos.
@freezed
abstract class ChallengeFileDto with _$ChallengeFileDto {
  const factory ChallengeFileDto({
    required String id,
    required String fileName,
    String? mimeType,
    String? subjectId,
  }) = _ChallengeFileDto;

  const ChallengeFileDto._();

  factory ChallengeFileDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeFileDtoFromJson(json);

  ChallengeFileOption toDomain() => ChallengeFileOption(
    id: id,
    fileName: fileName,
    mimeType: mimeType,
    subjectId: subjectId,
  );
}

/// Campos de `DeadlineResponse` que usan los retos.
@freezed
abstract class ChallengeDeadlineDto with _$ChallengeDeadlineDto {
  const factory ChallengeDeadlineDto({
    required String id,
    required String title,
    String? type,
    required String dueAt,
    String? subjectId,
    @Default(false) bool completed,
  }) = _ChallengeDeadlineDto;

  const ChallengeDeadlineDto._();

  factory ChallengeDeadlineDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeDeadlineDtoFromJson(json);

  /// Un examen se vincula como EXAM; el resto de entregas como DELIVERY.
  ChallengeLinkOption toDomain() => ChallengeLinkOption(
    id: id,
    type: type == 'EXAM' ? ChallengeLinkType.exam : ChallengeLinkType.delivery,
    title: title,
    at: ChallengeApiValues.instant(dueAt),
    subjectId: subjectId,
  );
}

/// `PageResponseDeadlineResponse` (solo los elementos).
@freezed
abstract class ChallengeDeadlinePageDto with _$ChallengeDeadlinePageDto {
  const factory ChallengeDeadlinePageDto({
    @Default(<ChallengeDeadlineDto>[]) List<ChallengeDeadlineDto> items,
  }) = _ChallengeDeadlinePageDto;

  factory ChallengeDeadlinePageDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeDeadlinePageDtoFromJson(json);
}

/// `SignedUrlResponse` de la API.
@freezed
abstract class ChallengeSignedUrlDto with _$ChallengeSignedUrlDto {
  const factory ChallengeSignedUrlDto({required String url}) =
      _ChallengeSignedUrlDto;

  factory ChallengeSignedUrlDto.fromJson(Map<String, dynamic> json) =>
      _$ChallengeSignedUrlDtoFromJson(json);
}
