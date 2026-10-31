part of 'enrollment_import_bloc.dart';

enum EnrollmentStep { intro, reading, review, applying, done }

@freezed
abstract class EnrollmentImportState with _$EnrollmentImportState {
  const factory EnrollmentImportState({
    @Default(EnrollmentStep.intro) EnrollmentStep step,
    @Default(false) bool consent,
    EnrollmentProposal? proposal,

    /// Posiciones de las asignaturas elegidas en [proposal].
    @Default(<int>{}) Set<int> selected,
    EnrollmentApplyResult? result,
    AppError? error,
  }) = _EnrollmentImportState;
}
