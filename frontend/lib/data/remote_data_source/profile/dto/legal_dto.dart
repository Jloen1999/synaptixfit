import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/legal_document_kind.dart';
import '../../../../domain/models/profile/legal_document.dart';

part 'legal_dto.freezed.dart';
part 'legal_dto.g.dart';

/// `LegalBlockResponse` de la API.
@freezed
abstract class LegalBlockDto with _$LegalBlockDto {
  const factory LegalBlockDto({required String type, required String text}) =
      _LegalBlockDto;

  const LegalBlockDto._();

  factory LegalBlockDto.fromJson(Map<String, dynamic> json) =>
      _$LegalBlockDtoFromJson(json);

  LegalBlock toDomain() => LegalBlock(
    type: switch (type) {
      'HEADING' => LegalBlockType.heading,
      'BULLET' => LegalBlockType.bullet,
      _ => LegalBlockType.paragraph,
    },
    text: text,
  );
}

/// `LegalDocumentResponse` de la API (`GET /api/v1/legal/{document}`).
@freezed
abstract class LegalDocumentDto with _$LegalDocumentDto {
  const factory LegalDocumentDto({
    required String kind,
    required String language,
    required String version,
    required String title,
    @Default(<LegalBlockDto>[]) List<LegalBlockDto> blocks,
    @Default(true) bool contactConfigured,
  }) = _LegalDocumentDto;

  const LegalDocumentDto._();

  factory LegalDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentDtoFromJson(json);

  LegalDocument toDomain(LegalDocumentKind requested) => LegalDocument(
    kind: LegalDocumentKind.fromSlug(kind) ?? requested,
    language: language,
    version: version,
    title: title,
    blocks: blocks.map((b) => b.toDomain()).toList(),
    contactConfigured: contactConfigured,
  );
}

/// `LegalAcceptanceResponse` de la API (`GET /api/v1/me/legal-acceptance`).
@freezed
abstract class LegalAcceptanceDto with _$LegalAcceptanceDto {
  const factory LegalAcceptanceDto({
    required String currentVersion,
    String? acceptedVersion,
    String? acceptedAt,
    @JsonKey(name: 'required') required bool mustAccept,
  }) = _LegalAcceptanceDto;

  const LegalAcceptanceDto._();

  factory LegalAcceptanceDto.fromJson(Map<String, dynamic> json) =>
      _$LegalAcceptanceDtoFromJson(json);

  LegalAcceptance toDomain() => LegalAcceptance(
    currentVersion: currentVersion,
    acceptedVersion: acceptedVersion,
    acceptedAt: acceptedAt == null ? null : DateTime.tryParse(acceptedAt!),
    mustAccept: mustAccept,
  );
}
