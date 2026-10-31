part of 'badges_bloc.dart';

@freezed
sealed class BadgesEvent with _$BadgesEvent {
  /// Carga (o recarga) el catálogo.
  const factory BadgesEvent.started() = BadgesStarted;

  /// Filtra por categoría; `null` muestra todas.
  const factory BadgesEvent.categorySelected(BadgeCategory? category) =
      BadgesCategorySelected;

  const factory BadgesEvent.visibilityToggled({
    required Badge badge,
    required bool visible,
  }) = BadgesVisibilityToggled;

  const factory BadgesEvent.shareRequested({
    required Badge badge,
    String? message,
  }) = BadgesShareRequested;

  /// Comparte fuera de la app la imagen de la insignia ya dibujada.
  const factory BadgesEvent.imageShareRequested({
    required Uint8List png,
    required String fileName,
    required String text,
  }) = BadgesImageShareRequested;
}
