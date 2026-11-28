part of 'routine_template_detail_bloc.dart';

enum TemplateDetailStatus { loading, ready, failure }

@freezed
abstract class RoutineTemplateDetailState with _$RoutineTemplateDetailState {
  const factory RoutineTemplateDetailState({
    @Default('') String templateId,
    @Default(TemplateDetailStatus.loading) TemplateDetailStatus status,
    RoutineTemplateDetail? detail,
    AppError? error,

    /// Convirtiéndola en rutina (botón ocupado).
    @Default(false) bool using,

    /// Rutina recién creada (efecto de un solo uso: abrirla).
    Routine? created,
    AppError? useError,
  }) = _RoutineTemplateDetailState;
}
