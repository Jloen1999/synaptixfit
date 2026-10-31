part of 'material_review_bloc.dart';

@freezed
abstract class MaterialReviewState with _$MaterialReviewState {
  const factory MaterialReviewState({
    @Default('') String materialId,
    @Default(true) bool loading,
    AppError? error,
    StudyMaterial? material,
    ReviewPreview? preview,
    @Default(<ReviewRecord>[]) List<ReviewRecord> history,
    @Default(false) bool submitting,
    AppError? actionError,

    /// Resultado del repaso recién registrado.
    ReviewOutcome? outcome,

    /// Cuenta refrescada tras el repaso (se propaga a la sesión).
    Account? updatedAccount,

    /// Quitando el material del repaso / ya quitado (la pantalla se cierra).
    @Default(false) bool removing,
    @Default(false) bool removed,
  }) = _MaterialReviewState;
}
