import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/profile/catalog.dart';
import 'package:synaptixfit/domain/models/profile/wellness_history.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_goal_history_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_my_degrees_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_profile_summary_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_weight_history_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/link_degree_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/search_degrees_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/search_universities_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/unlink_degree_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/catalog_picker/bloc/catalog_picker_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/degrees/bloc/degrees_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/profile/bloc/profile_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/wellness_history/bloc/wellness_history_bloc.dart';

import 'profile_fixtures.dart';

class _MockAccount extends Mock implements GetAccountUseCaseContract {}

class _MockSummary extends Mock implements GetProfileSummaryUseCaseContract {}

class _MockDegrees extends Mock implements GetMyDegreesUseCaseContract {}

class _MockLink extends Mock implements LinkDegreeUseCaseContract {}

class _MockUnlink extends Mock implements UnlinkDegreeUseCaseContract {}

class _MockWeights extends Mock implements GetWeightHistoryUseCaseContract {}

class _MockGoals extends Mock implements GetGoalHistoryUseCaseContract {}

class _MockUniversities extends Mock
    implements SearchUniversitiesUseCaseContract {}

class _MockSearchDegrees extends Mock implements SearchDegreesUseCaseContract {}

void main() {
  group('ProfileBloc', () {
    late _MockAccount account;
    late _MockSummary summary;

    setUp(() {
      account = _MockAccount();
      summary = _MockSummary();
    });

    blocTest<ProfileBloc, ProfileState>(
      'carga cuenta y resumen',
      setUp: () {
        when(
          () => account(),
        ).thenAnswer((_) async => const Success(testAccount));
        when(
          () => summary(),
        ).thenAnswer((_) async => const Success(testSummary));
      },
      build: () => ProfileBloc(getAccount: account, getSummary: summary),
      act: (bloc) => bloc.add(const ProfileEvent.started()),
      expect: () => const [
        ProfileState(),
        ProfileState(
          status: ProfileStatus.ready,
          account: testAccount,
          summary: testSummary,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'sin datos previos, un error deja la pantalla en failure',
      setUp: () {
        when(
          () => account(),
        ).thenAnswer((_) async => const Success(testAccount));
        when(
          () => summary(),
        ).thenAnswer((_) async => const Failure(AppError.network()));
      },
      build: () => ProfileBloc(getAccount: account, getSummary: summary),
      act: (bloc) => bloc.add(const ProfileEvent.started()),
      expect: () => const [
        ProfileState(),
        ProfileState(status: ProfileStatus.failure, error: AppError.network()),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'al refrescar con datos conserva el contenido aunque falle',
      setUp: () {
        when(
          () => account(),
        ).thenAnswer((_) async => const Failure(AppError.network()));
        when(
          () => summary(),
        ).thenAnswer((_) async => const Success(testSummary));
      },
      build: () => ProfileBloc(getAccount: account, getSummary: summary),
      seed: () => const ProfileState(
        status: ProfileStatus.ready,
        account: testAccount,
        summary: testSummary,
      ),
      act: (bloc) => bloc.add(const ProfileEvent.refreshed()),
      expect: () => const [
        ProfileState(
          status: ProfileStatus.ready,
          account: testAccount,
          summary: testSummary,
          refreshing: true,
        ),
        ProfileState(
          status: ProfileStatus.ready,
          account: testAccount,
          summary: testSummary,
          error: AppError.network(),
        ),
      ],
    );
  });

  group('DegreesBloc', () {
    late _MockDegrees degrees;
    late _MockLink link;
    late _MockUnlink unlink;
    const linked = UserDegree(degree: testDegree);

    DegreesBloc build() => DegreesBloc(
      getDegrees: degrees,
      linkDegree: link,
      unlinkDegree: unlink,
    );

    setUp(() {
      degrees = _MockDegrees();
      link = _MockLink();
      unlink = _MockUnlink();
    });

    blocTest<DegreesBloc, DegreesState>(
      'lista las carreras',
      setUp: () => when(
        () => degrees(),
      ).thenAnswer((_) async => const Success([linked])),
      build: build,
      act: (bloc) => bloc.add(const DegreesEvent.started()),
      expect: () => const [
        DegreesState(),
        DegreesState(status: DegreesStatus.ready, degrees: [linked]),
      ],
    );

    blocTest<DegreesBloc, DegreesState>(
      'error de carga',
      setUp: () => when(
        () => degrees(),
      ).thenAnswer((_) async => const Failure(AppError.server())),
      build: build,
      act: (bloc) => bloc.add(const DegreesEvent.started()),
      expect: () => const [
        DegreesState(),
        DegreesState(status: DegreesStatus.failure, error: AppError.server()),
      ],
    );

    blocTest<DegreesBloc, DegreesState>(
      'vincula una carrera',
      setUp: () =>
          when(() => link('d1')).thenAnswer((_) async => const Success(linked)),
      build: build,
      seed: () => const DegreesState(status: DegreesStatus.ready),
      act: (bloc) => bloc.add(const DegreesEvent.linkRequested(testDegree)),
      expect: () => const [
        DegreesState(status: DegreesStatus.ready, busy: true),
        DegreesState(
          status: DegreesStatus.ready,
          degrees: [linked],
          outcome: DegreesOutcome.linked,
        ),
      ],
    );

    blocTest<DegreesBloc, DegreesState>(
      'no vuelve a vincular una carrera ya vinculada',
      build: build,
      seed: () =>
          const DegreesState(status: DegreesStatus.ready, degrees: [linked]),
      act: (bloc) => bloc.add(const DegreesEvent.linkRequested(testDegree)),
      expect: () => const <DegreesState>[],
    );

    blocTest<DegreesBloc, DegreesState>(
      'desvincula una carrera',
      setUp: () =>
          when(() => unlink('d1')).thenAnswer((_) async => const Success(unit)),
      build: build,
      seed: () =>
          const DegreesState(status: DegreesStatus.ready, degrees: [linked]),
      act: (bloc) => bloc.add(const DegreesEvent.unlinkRequested('d1')),
      expect: () => const [
        DegreesState(
          status: DegreesStatus.ready,
          degrees: [linked],
          busy: true,
        ),
        DegreesState(
          status: DegreesStatus.ready,
          outcome: DegreesOutcome.unlinked,
        ),
      ],
    );
  });

  group('WellnessHistoryBloc', () {
    late _MockWeights weights;
    late _MockGoals goals;
    final record = WeightRecord(
      id: 'w1',
      weightKg: 60,
      recordedAt: DateTime(2026, 9, 1),
    );

    setUp(() {
      weights = _MockWeights();
      goals = _MockGoals();
    });

    blocTest<WellnessHistoryBloc, WellnessHistoryState>(
      'carga peso y objetivos',
      setUp: () {
        when(() => weights()).thenAnswer((_) async => Success([record]));
        when(() => goals()).thenAnswer(
          (_) async =>
              const Success([GoalHistoryEntry(id: 'g1', active: true)]),
        );
      },
      build: () =>
          WellnessHistoryBloc(getWeightHistory: weights, getGoalHistory: goals),
      act: (bloc) => bloc.add(const WellnessHistoryEvent.started()),
      expect: () => [
        const WellnessHistoryState(),
        WellnessHistoryState(
          status: WellnessHistoryStatus.ready,
          weights: [record],
          goals: const [GoalHistoryEntry(id: 'g1', active: true)],
        ),
      ],
    );

    blocTest<WellnessHistoryBloc, WellnessHistoryState>(
      'error si falla cualquiera de las dos',
      setUp: () {
        when(() => weights()).thenAnswer((_) async => Success([record]));
        when(
          () => goals(),
        ).thenAnswer((_) async => const Failure(AppError.server()));
      },
      build: () =>
          WellnessHistoryBloc(getWeightHistory: weights, getGoalHistory: goals),
      act: (bloc) => bloc.add(const WellnessHistoryEvent.started()),
      expect: () => const [
        WellnessHistoryState(),
        WellnessHistoryState(
          status: WellnessHistoryStatus.failure,
          error: AppError.server(),
        ),
      ],
    );
  });

  group('CatalogPickerBloc', () {
    late _MockUniversities universities;
    late _MockSearchDegrees searchDegrees;
    const uni = University(id: 'uni1', name: 'Universidad de Granada');

    setUp(() {
      universities = _MockUniversities();
      searchDegrees = _MockSearchDegrees();
    });

    blocTest<CatalogPickerBloc, CatalogPickerState>(
      'lista universidades y, al elegir una, sus carreras',
      setUp: () {
        when(
          () => universities(null),
        ).thenAnswer((_) async => const Success([uni]));
        when(
          () => searchDegrees('uni1', null),
        ).thenAnswer((_) async => const Success([testDegree]));
      },
      build: () => CatalogPickerBloc(
        searchUniversities: universities,
        searchDegrees: searchDegrees,
      ),
      act: (bloc) async {
        bloc.add(const CatalogPickerEvent.started());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CatalogPickerEvent.universitySelected(uni));
      },
      expect: () => const [
        CatalogPickerState(),
        CatalogPickerState(
          status: CatalogPickerStatus.ready,
          universities: [uni],
        ),
        CatalogPickerState(
          status: CatalogPickerStatus.ready,
          universities: [uni],
          university: uni,
        ),
        CatalogPickerState(universities: [uni], university: uni),
        CatalogPickerState(
          status: CatalogPickerStatus.ready,
          universities: [uni],
          university: uni,
          degrees: [testDegree],
        ),
      ],
    );

    blocTest<CatalogPickerBloc, CatalogPickerState>(
      'error de búsqueda',
      setUp: () => when(
        () => universities('gra'),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: () => CatalogPickerBloc(
        searchUniversities: universities,
        searchDegrees: searchDegrees,
      ),
      act: (bloc) => bloc.add(const CatalogPickerEvent.queryChanged('gra')),
      expect: () => const [
        CatalogPickerState(query: 'gra'),
        CatalogPickerState(
          query: 'gra',
          status: CatalogPickerStatus.failure,
          error: AppError.network(),
        ),
      ],
    );
  });
}
