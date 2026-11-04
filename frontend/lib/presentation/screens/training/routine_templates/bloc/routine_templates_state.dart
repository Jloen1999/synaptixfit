part of 'routine_templates_bloc.dart';

enum TemplatesStatus { loading, ready, failure }

/// Qué plantillas se ven: todas, por días por semana, las de casa o las de
/// semanas de exámenes. Es solo un filtro de lo que ya llegó del servidor.
@freezed
abstract class TemplateFilter with _$TemplateFilter {
  const factory TemplateFilter({
    int? days,
    @Default(false) bool atHome,
    @Default(false) bool forExams,
  }) = _TemplateFilter;

  const TemplateFilter._();

  bool get isEmpty => days == null && !atHome && !forExams;

  bool matches(RoutineTemplate t) =>
      (days == null || t.daysPerWeek == days) &&
      (!atHome || t.atHome) &&
      (!forExams || t.forExams);
}

@freezed
abstract class RoutineTemplatesState with _$RoutineTemplatesState {
  const factory RoutineTemplatesState({
    @Default(TemplatesStatus.loading) TemplatesStatus status,
    @Default(<RoutineTemplate>[]) List<RoutineTemplate> templates,
    @Default(TemplateFilter()) TemplateFilter filter,
    AppError? error,

    /// Plantilla que se está convirtiendo en rutina (botón ocupado).
    String? usingId,

    /// Rutina recién creada (efecto de un solo uso: abrirla).
    Routine? created,
    AppError? useError,
  }) = _RoutineTemplatesState;

  const RoutineTemplatesState._();

  List<RoutineTemplate> get visible => templates.where(filter.matches).toList();

  /// Días por semana disponibles, para los filtros.
  List<int> get dayOptions =>
      (templates.map((t) => t.daysPerWeek).toSet().toList()..sort());
}
