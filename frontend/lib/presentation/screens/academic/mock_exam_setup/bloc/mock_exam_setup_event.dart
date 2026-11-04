part of 'mock_exam_setup_bloc.dart';

@freezed
sealed class MockExamSetupEvent with _$MockExamSetupEvent {
  const factory MockExamSetupEvent.started(String subjectId) =
      MockExamSetupStarted;

  /// Mete o saca un apunte o archivo del simulacro.
  const factory MockExamSetupEvent.sourceToggled(String materialId) =
      MockExamSetupSourceToggled;

  /// «Elegir todo» o «Quitar todo».
  const factory MockExamSetupEvent.allToggled() = MockExamSetupAllToggled;

  const factory MockExamSetupEvent.countChanged(int count) =
      MockExamSetupCountChanged;
}
