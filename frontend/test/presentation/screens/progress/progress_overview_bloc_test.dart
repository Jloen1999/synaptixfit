import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_dashboard_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_progress_overview_use_case.dart';
import 'package:synaptixfit/presentation/screens/progress/overview/bloc/progress_overview_bloc.dart';

import '../../../progress_fixtures.dart';
import '../data_changes_fake.dart';
import '../home/home_fixtures.dart';

class _MockGetOverview extends Mock
    implements GetProgressOverviewUseCaseContract {}

class _MockGetToday extends Mock implements GetHomeDashboardUseCaseContract {}

void main() {
  late _MockGetOverview getOverview;
  late FakeDataChanges changes;
  late _MockGetToday getToday;

  setUp(() {
    getOverview = _MockGetOverview();
    changes = FakeDataChanges();
    getToday = _MockGetToday();
    // Sin resumen de hoy, «Tu equilibrio» dice el error y deja reintentar.
    when(
      () => getToday(),
    ).thenAnswer((_) async => const Failure(AppError.network()));
  });

  tearDown(() => changes.close());

  ProgressOverviewBloc build() => ProgressOverviewBloc(
    getOverview: getOverview,
    getToday: getToday,
    watchChanges: changes.useCase,
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    '«Tu equilibrio» (carga y energía de hoy) se carga en Progreso',
    setUp: () {
      when(() => getOverview()).thenAnswer((_) async => Success(testOverview));
      when(
        () => getToday(),
      ).thenAnswer((_) async => Success(homeDashboardFixture));
    },
    build: build,
    act: (bloc) => bloc.add(const ProgressOverviewEvent.started()),
    expect: () => [
      const ProgressOverviewState.loading(),
      ProgressOverviewState.loaded(testOverview, today: homeDashboardFixture),
    ],
  );

  blocTest<ProgressOverviewBloc, ProgressOverviewState>(
    'carga los datos de la pestaña; si «Tu equilibrio» falla, guarda el error',
    setUp: () => when(
      () => getOverview(),
    ).thenAnswer((_) async => Success(testOverview)),
    build: build,
    act: (bloc) => bloc.add(const ProgressOverviewEvent.started()),
    expect: () => [
      const ProgressOverviewState.loading(),
      ProgressOverviewState.loaded(
        testOverview,
        todayError: const AppError.network(),
      ),
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
      ProgressOverviewState.loaded(
        testOverview,
        todayError: const AppError.network(),
      ),
      ProgressOverviewState.loaded(
        testOverview,
        todayError: const AppError.network(),
        refreshing: true,
      ),
      ProgressOverviewState.loaded(
        testOverview,
        todayError: const AppError.network(),
      ),
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
