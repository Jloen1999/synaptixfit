import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_page.freezed.dart';

/// Página de resultados de la API (paginación por número de página).
@freezed
abstract class SocialPage<T> with _$SocialPage<T> {
  const factory SocialPage({
    required List<T> items,
    required int page,
    required int totalPages,
    required int totalItems,
  }) = _SocialPage<T>;

  const SocialPage._();

  /// Indica si hay más páginas después de esta.
  bool get hasMore => page + 1 < totalPages;
}
