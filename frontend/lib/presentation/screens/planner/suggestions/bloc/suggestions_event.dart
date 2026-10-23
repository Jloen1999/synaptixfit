part of 'suggestions_bloc.dart';

@freezed
sealed class SuggestionsEvent with _$SuggestionsEvent {
  const factory SuggestionsEvent.studyHoursChanged(double hours) =
      SuggestionsStudyHoursChanged;

  const factory SuggestionsEvent.sportSessionsChanged(int sessions) =
      SuggestionsSportSessionsChanged;

  /// `0` = esta semana, `1` = la siguiente.
  const factory SuggestionsEvent.weekOffsetChanged(int offset) =
      SuggestionsWeekOffsetChanged;

  const factory SuggestionsEvent.generateRequested() =
      SuggestionsGenerateRequested;

  /// Selecciona o descarta el bloque propuesto [index].
  const factory SuggestionsEvent.blockToggled(int index) =
      SuggestionsBlockToggled;

  const factory SuggestionsEvent.allToggled(bool selected) =
      SuggestionsAllToggled;

  /// Crea en el calendario los bloques seleccionados.
  const factory SuggestionsEvent.acceptRequested() = SuggestionsAcceptRequested;
}
