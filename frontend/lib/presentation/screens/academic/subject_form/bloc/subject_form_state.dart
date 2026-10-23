part of 'subject_form_bloc.dart';

@freezed
abstract class SubjectFormState with _$SubjectFormState {
  const factory SubjectFormState({
    @Default(true) bool loading,
    AppError? loadError,
    Subject? subject,
    SubjectSemester? semester,
    @Default(false) bool saving,
    AppError? saveError,

    /// Se rellena al guardar correctamente.
    String? savedSubjectId,
  }) = _SubjectFormState;

  const SubjectFormState._();

  bool get isEditing => subject != null;
}
