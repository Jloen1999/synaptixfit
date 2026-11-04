part of 'routine_templates_bloc.dart';

@freezed
sealed class RoutineTemplatesEvent with _$RoutineTemplatesEvent {
  const factory RoutineTemplatesEvent.started() = RoutineTemplatesStarted;

  const factory RoutineTemplatesEvent.filterChanged(TemplateFilter filter) =
      RoutineTemplatesFilterChanged;

  const factory RoutineTemplatesEvent.used(String templateId) =
      RoutineTemplatesUsed;
}
