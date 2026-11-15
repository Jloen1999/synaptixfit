part of 'routine_templates_bloc.dart';

enum TemplatesStatus { loading, ready, failure }

/// Tramos de duración del filtro «Tiempo» (ADR 0043): hasta 20, 30 o 45 min,
/// o más de 45.
enum TemplateTime {
  upTo20(0, 20),
  upTo30(0, 30),
  upTo45(0, 45),
  more(46, 999);

  const TemplateTime(this.min, this.max);

  final int min;
  final int max;

  bool includes(int minutes) => minutes >= min && minutes <= max;
}

/// Qué plantillas se ven: por lugar, días por semana, tiempo, nivel y semanas
/// de exámenes. Es solo un filtro de lo que ya llegó del servidor.
@freezed
abstract class TemplateFilter with _$TemplateFilter {
  const factory TemplateFilter({
    TemplatePlace? place,
    int? days,
    TemplateTime? time,
    TemplateLevel? level,
    @Default(false) bool forExams,
  }) = _TemplateFilter;

  const TemplateFilter._();

  bool get isEmpty =>
      place == null &&
      days == null &&
      time == null &&
      level == null &&
      !forExams;

  bool matches(RoutineTemplate t) =>
      (place == null || t.place == place) &&
      (days == null || t.daysPerWeek == days) &&
      (time == null || time!.includes(t.minutes)) &&
      (level == null || t.level == level) &&
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

    /// La plantilla usada traía carreras: el aviso dice dónde están.
    @Default(false) bool createdWithRuns,
    AppError? useError,
  }) = _RoutineTemplatesState;

  const RoutineTemplatesState._();

  List<RoutineTemplate> get visible => templates.where(filter.matches).toList();

  /// Días por semana disponibles, para los filtros.
  List<int> get dayOptions =>
      (templates.map((t) => t.daysPerWeek).toSet().toList()..sort());

  /// Tramos de tiempo con alguna plantilla, en orden.
  List<TemplateTime> get timeOptions => [
    for (final t in TemplateTime.values)
      if (templates.any((p) => t.includes(p.minutes))) t,
  ];

  /// Lugares con alguna plantilla, en el orden del enum.
  List<TemplatePlace> get placeOptions => [
    for (final p in TemplatePlace.values)
      if (templates.any((t) => t.place == p)) p,
  ];
}
