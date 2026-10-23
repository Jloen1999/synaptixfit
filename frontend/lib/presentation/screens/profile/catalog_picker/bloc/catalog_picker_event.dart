part of 'catalog_picker_bloc.dart';

@freezed
sealed class CatalogPickerEvent with _$CatalogPickerEvent {
  const factory CatalogPickerEvent.started() = CatalogPickerStarted;

  /// Texto de búsqueda (la página ya aplica el retardo de escritura).
  const factory CatalogPickerEvent.queryChanged(String query) =
      CatalogPickerQueryChanged;

  const factory CatalogPickerEvent.universitySelected(University university) =
      CatalogPickerUniversitySelected;

  /// Volver a la lista de universidades.
  const factory CatalogPickerEvent.universityCleared() =
      CatalogPickerUniversityCleared;
}
