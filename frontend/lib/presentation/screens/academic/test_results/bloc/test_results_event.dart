part of 'test_results_bloc.dart';

@freezed
sealed class TestResultsEvent with _$TestResultsEvent {
  const factory TestResultsEvent.started(String sessionId) = TestResultsStarted;
}
