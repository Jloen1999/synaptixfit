import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/social/social_page.dart';

part 'page_dto.freezed.dart';
part 'page_dto.g.dart';

/// Página genérica de la API (`PageResponse<T>`).
@Freezed(genericArgumentFactories: true)
abstract class PageDto<T> with _$PageDto<T> {
  const factory PageDto({
    @Default([]) List<T> items,
    @Default(0) int page,
    @Default(20) int size,
    @Default(0) int totalItems,
    @Default(0) int totalPages,
  }) = _PageDto<T>;

  const PageDto._();

  factory PageDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PageDtoFromJson(json, fromJsonT);

  SocialPage<R> toDomain<R>(R Function(T item) map) => SocialPage<R>(
    items: items.map(map).toList(),
    page: page,
    totalPages: totalPages,
    totalItems: totalItems,
  );
}
