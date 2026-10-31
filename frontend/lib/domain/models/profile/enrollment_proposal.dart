import 'package:freezed_annotation/freezed_annotation.dart';

part 'enrollment_proposal.freezed.dart';

/// Lo que el servidor ha reconocido en un documento de matrícula: universidad,
/// carrera y asignaturas (con su equivalente del catálogo, si lo hay). No se
/// guarda nada hasta que el usuario elige qué añadir.
@freezed
abstract class EnrollmentProposal with _$EnrollmentProposal {
  const factory EnrollmentProposal({
    String? universityName,
    String? universityId,
    String? centerName,
    String? degreeName,
    String? degreeId,
    String? academicYear,
    @Default(<EnrollmentSubject>[]) List<EnrollmentSubject> subjects,
  }) = _EnrollmentProposal;
}

/// Asignatura matriculada según el documento.
@freezed
abstract class EnrollmentSubject with _$EnrollmentSubject {
  const EnrollmentSubject._();

  const factory EnrollmentSubject({
    String? code,
    required String name,
    int? course,
    double? credits,
    String? period,
    int? timesEnrolled,
    String? catalogSubjectId,
    @Default(false) bool alreadyAdded,
  }) = _EnrollmentSubject;

  bool get inCatalog => catalogSubjectId != null;
}

/// Resultado de añadir lo elegido.
@freezed
abstract class EnrollmentApplyResult with _$EnrollmentApplyResult {
  const factory EnrollmentApplyResult({
    required int subjectsAdded,
    required bool degreeLinked,
  }) = _EnrollmentApplyResult;
}
