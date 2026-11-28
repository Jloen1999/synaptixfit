part of 'routine_template_detail_bloc.dart';

@freezed
sealed class RoutineTemplateDetailEvent with _$RoutineTemplateDetailEvent {
  /// Carga (o vuelve a cargar con «Reintentar») la plantilla [templateId].
  const factory RoutineTemplateDetailEvent.started(String templateId) =
      RoutineTemplateDetailStarted;

  /// «Usar esta plantilla».
  const factory RoutineTemplateDetailEvent.used() = RoutineTemplateDetailUsed;
}
