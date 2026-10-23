import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog.freezed.dart';

/// Universidad del catálogo académico. [type] (Pública/Privada) y [region]
/// (comunidad autónoma) vienen del registro oficial y pueden faltar.
@freezed
abstract class University with _$University {
  const factory University({
    required String id,
    required String name,
    String? type,
    String? region,
  }) = _University;
}

/// Carrera (titulación) del catálogo.
@freezed
abstract class Degree with _$Degree {
  const factory Degree({
    required String id,
    required String name,
    int? totalCredits,
    String? centerName,
    String? universityId,
    String? universityName,
  }) = _Degree;
}

/// Carrera vinculada al usuario.
@freezed
abstract class UserDegree with _$UserDegree {
  const factory UserDegree({required Degree degree, DateTime? linkedAt}) =
      _UserDegree;
}

/// Asignatura del plan de estudios de una carrera.
@freezed
abstract class CatalogSubject with _$CatalogSubject {
  const factory CatalogSubject({
    required String id,
    required String name,
    int? course,
    int? semester,
    String? character,
    double? credits,

    /// El usuario ya tiene esta asignatura creada.
    @Default(false) bool alreadyAdded,
  }) = _CatalogSubject;
}

/// Página de asignaturas del catálogo.
@freezed
abstract class CatalogSubjectPage with _$CatalogSubjectPage {
  const factory CatalogSubjectPage({
    required List<CatalogSubject> items,
    required int page,
    required int totalPages,
    required int totalItems,
  }) = _CatalogSubjectPage;

  const CatalogSubjectPage._();

  bool get hasMore => page + 1 < totalPages;
}
