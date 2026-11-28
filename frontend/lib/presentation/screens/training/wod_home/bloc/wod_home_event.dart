part of 'wod_home_bloc.dart';

@freezed
sealed class WodHomeEvent with _$WodHomeEvent {
  const factory WodHomeEvent.started() = WodHomeStarted;

  /// Volver de otra pantalla o tirar para recargar.
  const factory WodHomeEvent.refreshed() = WodHomeRefreshed;

  /// Ver otra plantilla de ejemplo en la pizarra.
  const factory WodHomeEvent.templateChosen(String code) =
      WodHomeTemplateChosen;

  const factory WodHomeEvent.divisionChanged(WodDivision division) =
      WodHomeDivisionChanged;

  /// «Apuntar marca» sin cronómetro. [wod] lleva ya los textos en el idioma
  /// de la persona si es una plantilla.
  const factory WodHomeEvent.resultSubmitted(Wod wod, WodResultDraft draft) =
      WodHomeResultSubmitted;
}
