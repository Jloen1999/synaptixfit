part of 'mock_exam_setup_bloc.dart';

@freezed
abstract class MockExamSetupState with _$MockExamSetupState {
  const factory MockExamSetupState({
    @Default('') String subjectId,
    @Default(true) bool loading,
    AppError? error,
    MockExamOptions? options,
    @Default(<String>{}) Set<String> selected,
    @Default(0) int count,
  }) = _MockExamSetupState;

  const MockExamSetupState._();

  /// Tamaños que se ofrecen, en saltos de 10 como un examen corto, medio o
  /// largo; si hay pocas preguntas, se ofrecen todas las que hay.
  static const step = 10;

  List<MockExamSource> get sources => options?.sources ?? const [];

  int get available => options?.questionsIn(selected) ?? 0;

  bool get allSelected {
    final o = options;
    if (o == null || o.sources.isEmpty) return false;
    return selected.length >= o.sources.length.clamp(0, o.maxMaterials);
  }

  /// Ya hay el máximo de materiales: los demás no se pueden marcar.
  bool get atMaterialLimit =>
      options != null && selected.length >= options!.maxMaterials;

  List<int> get countChoices {
    final o = options;
    if (o == null || available == 0) return const [];
    final top = available < o.maxQuestions ? available : o.maxQuestions;
    final choices = [for (var c = step; c <= top; c += step) c];
    if (choices.isEmpty || choices.last < top && top < o.maxQuestions) {
      choices.add(top);
    }
    return choices;
  }

  bool get canStart => selected.isNotEmpty && count > 0;

  /// Orden en que se mandan: el primero identifica la sesión (para reanudarla).
  List<String> get orderedSelection => [
    for (final s in sources)
      if (selected.contains(s.materialId)) s.materialId,
  ];
}
