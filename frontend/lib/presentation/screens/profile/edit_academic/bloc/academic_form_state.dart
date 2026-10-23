part of 'academic_form_bloc.dart';

enum AcademicFormStatus { loading, ready, failure }

@freezed
abstract class AcademicFormState with _$AcademicFormState {
  const factory AcademicFormState({
    @Default(AcademicFormStatus.loading) AcademicFormStatus status,

    /// Perfil actual; `null` si aún no existe.
    AcademicProfile? initial,

    /// Carrera elegida en el catálogo durante esta edición.
    Degree? selectedDegree,
    @Default(false) bool saving,

    /// Perfil recién guardado (señal para cerrar la pantalla o avanzar).
    AcademicProfile? saved,
    AppError? loadError,
    AppError? actionError,
  }) = _AcademicFormState;
}
