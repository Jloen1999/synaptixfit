import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_page.freezed.dart';

/// Página de resultados de un listado paginado del panel de administración.
@freezed
abstract class AdminPage<T> with _$AdminPage<T> {
  const factory AdminPage({
    required List<T> items,
    required int page,
    required int size,
    required int totalItems,
    required int totalPages,
  }) = _AdminPage<T>;

  const AdminPage._();

  bool get hasPrevious => page > 0;

  bool get hasNext => page + 1 < totalPages;
}
