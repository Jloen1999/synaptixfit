import '../../../../domain/models/admin/admin_page.dart';

/// Utilidades de conversión comunes a los DTOs del módulo admin.
abstract final class AdminJson {
  /// Instante ISO-8601 (UTC) de la API → hora local.
  static DateTime? instant(String? value) =>
      value == null ? null : DateTime.tryParse(value)?.toLocal();

  /// Fecha `yyyy-MM-dd` de la API → medianoche local de ese día.
  static DateTime? date(String? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// `PageResponse<T>` de la API → [AdminPage].
  static AdminPage<T> page<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) parseItem,
  ) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(parseItem)
        .toList();
    return AdminPage<T>(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? items.length,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
