import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_progress_overview_use_case.dart';
import 'package:synaptixfit/presentation/screens/progress/overview/bloc/progress_overview_bloc.dart';

import '../../../progress_fixtures.dart';
import '../data_changes_fake.dart';

class _MockGetOverview extends Mock
    implements GetProgressOverviewUseCaseContract {}

void main() {
  late _MockGetOverview getOverview;
  late FakeDataChanges changes;

  setUp(() {
    getOverview = _MockGetOverview();
    changes = FakeDataChanges();
  });

  tearDown(() => changes.close());

  ProgressOverviewBloc build() => ProgressOverviewBloc(
    getOverview: getOverview,
    watchChanges: changes.useCase,
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'carga los datos de la pestaña',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => Success(testOverview)),
    build: build,
    act: (bloc) => bloc.add(const ProgressOverviewEvent.started()),
    expect: () => [
      const ProgressOverviewState.loading(),
      ProgressOverviewState.loaded(testOverview),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'emite failure si la carga falla',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const ProgressOverviewEvent.started()),
    expect: () => const [
      ProgressOverviewState.loading(),
      ProgressOverviewState.failure(AppError.network()),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'una recarga fallida conserva los datos y expone el error',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    seed: () => ProgressOverviewState.loaded(testOverview),
    act: (bloc) => bloc.add(const ProgressOverviewEvent.refreshed()),
    expect: () => [
      ProgressOverviewState.loaded(testOverview, refreshing: true),
      ProgressOverviewState.loaded(
        testOverview,
        refreshError: const AppError.server(),
      ),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'un cambio social lo refresca en silencio',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => Success(testOverview)),
    build: build,
    act: (bloc) async {
      bloc.add(const ProgressOverviewEvent.started());
      await pump();
      changes.emit({DataTopic.social});
      await pump();
    },
    expect: () => [
      const ProgressOverviewState.loading(),
      ProgressOverviewState.loaded(testOverview),
      ProgressOverviewState.loaded(testOverview, refreshing: true),
      ProgressOverviewState.loaded(testOverview),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'un cambio académico lo refresca («Tu estudio»); uno de retos no',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => Success(testOverview)),
    build: build,
    act: (bloc) async {
      bloc.add(const ProgressOverviewEvent.started());
      await pump();
      changes.emit({DataTopic.academic});
      await pump();
      changes.emit({DataTopic.challenges});
      await pump();
    },
    verify: (_) => verify(() => getOverview()).called(2),
  );
}
