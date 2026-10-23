import '../../../../domain/models/training/training_page.dart';

/// Convierte un `PageResponse` de la API (`items`, `page`, `totalPages`,
/// `totalItems`) en [TrainingPage] mapeando cada elemento con [item].
TrainingPage<T> parseTrainingPage<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic> json) item,
) {
  final items = (json['items'] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>()
      .map(item)
      .toList();
  return TrainingPage<T>(
    items: items,
    page: (json['page'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    totalItems: (json['totalItems'] as num?)?.toInt() ?? items.length,
  );
}
