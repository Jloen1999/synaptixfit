import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_page.freezed.dart';

/// Página de resultados de un listado paginado del módulo de entrenamiento.
@freezed
abstract class TrainingPage<T> with _$TrainingPage<T> {
  const factory TrainingPage({
    required List<T> items,
    required int page,
    required int totalPages,
    required int totalItems,
  }) = _TrainingPage<T>;

  const TrainingPage._();

  /// Si quedan más páginas por cargar.
  bool get hasMore => page + 1 < totalPages;
}
