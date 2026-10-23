/// Origen de las sugerencias de objetivo: la IA o las reglas de respaldo.
enum GoalSuggestionSource {
  ai,
  rules;

  static GoalSuggestionSource fromApi(String? value) =>
      value == 'AI' ? GoalSuggestionSource.ai : GoalSuggestionSource.rules;
}
