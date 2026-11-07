import 'package:freezed_annotation/freezed_annotation.dart';

part 'academic_search.freezed.dart';

/// Tipo de resultado del buscador de Académico, en el orden en que se enseña.
enum AcademicSearchKind {
  subject('SUBJECT'),
  note('NOTE'),
  file('FILE'),
  deadline('DEADLINE');

  const AcademicSearchKind(this.apiValue);

  final String apiValue;

  static AcademicSearchKind? fromApi(String? value) {
    for (final kind in values) {
      if (kind.apiValue == value) return kind;
    }
    return null;
  }
}

/// Un resultado: [context] ayuda a reconocerlo (la asignatura de un apunte, un
/// archivo o una entrega; las siglas de una asignatura); [at] es la fecha de
/// una entrega y [exam] si es un examen.
@freezed
abstract class AcademicSearchHit with _$AcademicSearchHit {
  const factory AcademicSearchHit({
    required String id,
    required String title,
    String? context,
    String? subjectId,
    DateTime? at,
    @Default(false) bool exam,
  }) = _AcademicSearchHit;
}

/// Resultados de un tipo; [more] dice que hay más de los que se enseñan.
@freezed
abstract class AcademicSearchGroup with _$AcademicSearchGroup {
  const factory AcademicSearchGroup({
    required AcademicSearchKind kind,
    required List<AcademicSearchHit> hits,
    @Default(false) bool more,
  }) = _AcademicSearchGroup;
}

/// Lo que devuelve el servidor para un texto (ADR 0036): solo los grupos con
/// algo, ya ordenados.
@freezed
abstract class AcademicSearchResult with _$AcademicSearchResult {
  const factory AcademicSearchResult({
    required String query,
    required List<AcademicSearchGroup> groups,
  }) = _AcademicSearchResult;

  const AcademicSearchResult._();

  bool get isEmpty => groups.every((g) => g.hits.isEmpty);
}
