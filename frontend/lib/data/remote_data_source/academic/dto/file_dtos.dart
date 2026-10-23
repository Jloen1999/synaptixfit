import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/academic/subject_file.dart';

part 'file_dtos.freezed.dart';
part 'file_dtos.g.dart';

@freezed
abstract class SubjectFileDto with _$SubjectFileDto {
  const factory SubjectFileDto({
    required String id,
    required String subjectId,
    @Default('') String fileName,
    @Default('application/octet-stream') String mimeType,
    @Default(0) int sizeBytes,
    @Default(false) bool aiReadable,
    DateTime? createdAt,
  }) = _SubjectFileDto;

  const SubjectFileDto._();

  factory SubjectFileDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectFileDtoFromJson(json);

  SubjectFile toDomain() => SubjectFile(
    id: id,
    subjectId: subjectId,
    fileName: fileName,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    aiReadable: aiReadable,
    createdAt: createdAt?.toLocal(),
  );
}

/// Ticket de subida: URL prefirmada y cabeceras que hay que enviar.
@freezed
abstract class FileUploadTicketDto with _$FileUploadTicketDto {
  const factory FileUploadTicketDto({
    required String objectKey,
    required String uploadUrl,
    @Default('PUT') String method,
    @Default(<String, String>{}) Map<String, String> headers,
  }) = _FileUploadTicketDto;

  factory FileUploadTicketDto.fromJson(Map<String, dynamic> json) =>
      _$FileUploadTicketDtoFromJson(json);
}

@freezed
abstract class SignedUrlDto with _$SignedUrlDto {
  const factory SignedUrlDto({
    required String url,
    @Default('GET') String method,
    @Default(<String, String>{}) Map<String, String> headers,
    DateTime? expiresAt,
  }) = _SignedUrlDto;

  const SignedUrlDto._();

  factory SignedUrlDto.fromJson(Map<String, dynamic> json) =>
      _$SignedUrlDtoFromJson(json);

  SignedUrl toDomain() =>
      SignedUrl(url: url, headers: headers, expiresAt: expiresAt?.toLocal());
}
