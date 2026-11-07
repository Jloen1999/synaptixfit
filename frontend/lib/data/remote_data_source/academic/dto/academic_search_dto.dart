import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/academic/academic_search.dart';

part 'academic_search_dto.freezed.dart';
part 'academic_search_dto.g.dart';

@freezed
abstract class AcademicSearchDto with _$AcademicSearchDto {
  const factory AcademicSearchDto({
    @Default('') String query,
    @Default(<AcademicSearchGroupDto>[]) List<AcademicSearchGroupDto> groups,
  }) = _AcademicSearchDto;

  const AcademicSearchDto._();

  factory AcademicSearchDto.fromJson(Map<String, dynamic> json) =>
      _$AcademicSearchDtoFromJson(json);

  /// Los tipos que esta versión no conoce se descartan.
  AcademicSearchResult toDomain() => AcademicSearchResult(
    query: query,
    groups: [
      for (final g in groups)
        if (AcademicSearchKind.fromApi(g.kind) case final kind?)
          AcademicSearchGroup(
            kind: kind,
            more: g.more,
            hits: [for (final h in g.hits) h.toDomain()],
          ),
    ],
  );
}

@freezed
abstract class AcademicSearchGroupDto with _$AcademicSearchGroupDto {
  const factory AcademicSearchGroupDto({
    required String kind,
    @Default(<AcademicSearchHitDto>[]) List<AcademicSearchHitDto> hits,
    @Default(false) bool more,
  }) = _AcademicSearchGroupDto;

  factory AcademicSearchGroupDto.fromJson(Map<String, dynamic> json) =>
      _$AcademicSearchGroupDtoFromJson(json);
}

@freezed
abstract class AcademicSearchHitDto with _$AcademicSearchHitDto {
  const factory AcademicSearchHitDto({
    required String id,
    @Default('') String title,
    String? context,
    String? subjectId,
    DateTime? at,
    @Default(false) bool exam,
  }) = _AcademicSearchHitDto;

  const AcademicSearchHitDto._();

  factory AcademicSearchHitDto.fromJson(Map<String, dynamic> json) =>
      _$AcademicSearchHitDtoFromJson(json);

  AcademicSearchHit toDomain() => AcademicSearchHit(
    id: id,
    title: title,
    context: context,
    subjectId: subjectId,
    at: at?.toLocal(),
    exam: exam,
  );
}
