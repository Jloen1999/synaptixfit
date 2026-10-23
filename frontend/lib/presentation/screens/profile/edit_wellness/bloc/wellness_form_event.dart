part of 'wellness_form_bloc.dart';

@freezed
sealed class WellnessFormEvent with _$WellnessFormEvent {
  /// Con [loadExisting] a `false` (onboarding) no se consulta el perfil actual.
  const factory WellnessFormEvent.started({@Default(true) bool loadExisting}) =
      WellnessFormStarted;

  const factory WellnessFormEvent.submitted(WellnessProfileDraft draft) =
      WellnessFormSubmitted;

  /// «Recomiéndame»: pide sugerencias de objetivo con los datos ya rellenados.
  const factory WellnessFormEvent.suggestionsRequested({
    int? age,
    Sex? sex,
    ActivityLevel? activityLevel,
  }) = WellnessFormSuggestionsRequested;
}
