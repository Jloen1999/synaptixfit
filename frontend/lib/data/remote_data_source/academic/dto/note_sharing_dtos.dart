import '../../../../domain/enums/study_source_type.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/academic/material_sharing.dart';
import '../../../../domain/models/academic/study_document.dart';

/// Respuesta de `POST /notes/{id}/recipients` (ADR 0064).
class SentNoteDto {
  const SentNoteDto({required this.friendId, required this.friendName});

  factory SentNoteDto.fromJson(Map<String, dynamic> json) => SentNoteDto(
    friendId: json['friendId'] as String? ?? '',
    friendName: json['friendName'] as String? ?? '',
  );

  final String friendId;
  final String friendName;

  SentNote toDomain() => SentNote(friendId: friendId, friendName: friendName);
}

/// Respuesta de `POST /notes/{id}/wall` (ADR 0064).
class WallShareDto {
  const WallShareDto({required this.alreadyShared, required this.visibility});

  factory WallShareDto.fromJson(Map<String, dynamic> json) => WallShareDto(
    alreadyShared: json['alreadyShared'] as bool? ?? false,
    visibility: json['visibility'] as String?,
  );

  final bool alreadyShared;
  final String? visibility;

  NoteWallShare toDomain() => NoteWallShare(
    alreadyShared: alreadyShared,
    visibility: Visibility.fromApi(visibility),
  );
}

/// Un elemento de `GET /study/subjects/{id}/documents` (ADR 0064).
class SourceDocumentsDto {
  const SourceDocumentsDto({
    required this.sourceType,
    required this.sourceId,
    required this.summary,
    required this.mindMap,
    required this.practice,
  });

  factory SourceDocumentsDto.fromJson(Map<String, dynamic> json) =>
      SourceDocumentsDto(
        sourceType: StudySourceType.fromApi(json['sourceType'] as String?),
        sourceId: json['sourceId'] as String? ?? '',
        summary: json['summary'] as bool? ?? false,
        mindMap: json['mindMap'] as bool? ?? false,
        practice: json['practice'] as bool? ?? false,
      );

  final StudySourceType sourceType;
  final String sourceId;
  final bool summary;
  final bool mindMap;
  final bool practice;

  DocumentAvailability toDomain() =>
      DocumentAvailability(summary: summary, mindMap: mindMap, practice: practice);
}

/// Nombre del archivo de `Content-Disposition` (`filename*=UTF-8''…` o
/// `filename="…"`); sin cabecera, [fallback].
String fileNameFromDisposition(String? header, String fallback) {
  if (header == null) return fallback;
  final encoded = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
      .firstMatch(header)
      ?.group(1);
  if (encoded != null) {
    try {
      return Uri.decodeComponent(encoded.trim());
    } on ArgumentError {
      return fallback;
    }
  }
  final plain = RegExp(r'filename="([^"]+)"').firstMatch(header)?.group(1);
  return plain == null || plain.startsWith('=?') ? fallback : plain;
}
