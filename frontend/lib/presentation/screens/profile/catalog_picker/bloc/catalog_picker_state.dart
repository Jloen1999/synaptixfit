part of 'catalog_picker_bloc.dart';

enum CatalogPickerStatus { loading, ready, failure }

@freezed
abstract class CatalogPickerState with _$CatalogPickerState {
  const factory CatalogPickerState({
    @Default(CatalogPickerStatus.loading) CatalogPickerStatus status,

    /// Universidad elegida; `null` mientras se busca universidad.
    University? university,
    @Default('') String query,
    @Default(<University>[]) List<University> universities,
    @Default(<Degree>[]) List<Degree> degrees,
    AppError? error,
  }) = _CatalogPickerState;
}
