import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/profile/catalog.dart';

part 'catalog_dto.freezed.dart';
part 'catalog_dto.g.dart';

@freezed
abstract class UniversityDto with _$UniversityDto {
  const factory UniversityDto({
    required String id,
    required String name,
    String? type,
    String? region,
  }) = _UniversityDto;

  const UniversityDto._();

  factory UniversityDto.fromJson(Map<String, dynamic> json) =>
      _$UniversityDtoFromJson(json);

  University toDomain() =>
      University(id: id, name: name, type: type, region: region);
}

@freezed
abstract class DegreeDto with _$DegreeDto {
  const factory DegreeDto({
    required String id,
    required String name,
    int? totalCredits,
    String? centerName,
    String? universityId,
    String? universityName,
  }) = _DegreeDto;

  const DegreeDto._();

  factory DegreeDto.fromJson(Map<String, dynamic> json) =>
      _$DegreeDtoFromJson(json);

  Degree toDomain() => Degree(
    id: id,
    name: name,
    totalCredits: totalCredits,
    centerName: centerName,
    universityId: universityId,
    universityName: universityName,
  );
}

@freezed
abstract class UserDegreeDto with _$UserDegreeDto {
  const factory UserDegreeDto({required DegreeDto degree, String? linkedAt}) =
      _UserDegreeDto;

  const UserDegreeDto._();

  factory UserDegreeDto.fromJson(Map<String, dynamic> json) =>
      _$UserDegreeDtoFromJson(json);

  UserDegree toDomain() => UserDegree(
    degree: degree.toDomain(),
    linkedAt: linkedAt == null ? null : DateTime.tryParse(linkedAt!)?.toLocal(),
  );
}

@freezed
abstract class CatalogSubjectDto with _$CatalogSubjectDto {
  const factory CatalogSubjectDto({
    required String id,
    required String name,
    int? course,
    int? semester,
    String? character,
    double? credits,
  }) = _CatalogSubjectDto;

  const CatalogSubjectDto._();

  factory CatalogSubjectDto.fromJson(Map<String, dynamic> json) =>
      _$CatalogSubjectDtoFromJson(json);

  CatalogSubject toDomain() => CatalogSubject(
    id: id,
    name: name,
    course: course,
    semester: semester,
    character: character,
    credits: credits,
  );
}

@freezed
abstract class UserCatalogSubjectDto with _$UserCatalogSubjectDto {
  const factory UserCatalogSubjectDto({
    required CatalogSubjectDto subject,
    String? userSubjectId,
    bool? active,
  }) = _UserCatalogSubjectDto;

  const UserCatalogSubjectDto._();

  factory UserCatalogSubjectDto.fromJson(Map<String, dynamic> json) =>
      _$UserCatalogSubjectDtoFromJson(json);

  /// Solo cuenta como ya añadida si la asignatura del usuario existe y está activa
  /// (una archivada se puede volver a crear).
  CatalogSubject toDomain() => subject.toDomain().copyWith(
    alreadyAdded: userSubjectId != null && (active ?? true),
  );
}

@freezed
abstract class UserCatalogSubjectPageDto with _$UserCatalogSubjectPageDto {
  const factory UserCatalogSubjectPageDto({
    @Default(<UserCatalogSubjectDto>[]) List<UserCatalogSubjectDto> items,
    @Default(0) int page,
    @Default(0) int totalPages,
    @Default(0) int totalItems,
  }) = _UserCatalogSubjectPageDto;

  const UserCatalogSubjectPageDto._();

  factory UserCatalogSubjectPageDto.fromJson(Map<String, dynamic> json) =>
      _$UserCatalogSubjectPageDtoFromJson(json);

  CatalogSubjectPage toDomain() => CatalogSubjectPage(
    items: items.map((i) => i.toDomain()).toList(),
    page: page,
    totalPages: totalPages,
    totalItems: totalItems,
  );
}
