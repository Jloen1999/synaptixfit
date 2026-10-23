import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/badge_category.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/progress/change_badge_visibility_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_badge_catalog_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/share_badge_use_case.dart';
import 'package:synaptixfit/presentation/screens/progress/badges/bloc/badges_bloc.dart';

import '../../../progress_fixtures.dart';

class _MockCatalog extends Mock implements GetBadgeCatalogUseCaseContract {}

class _MockVisibility extends Mock
    implements ChangeBadgeVisibilityUseCaseContract {}

class _MockShare extends Mock implements ShareBadgeUseCaseContract {}

void main() {
  late _MockCatalog catalog;
  late _MockVisibility visibility;
  late _MockShare share;

  final earned = testBadge();
  final locked = testBadge(
    id: 'b2',
    earned: false,
    category: BadgeCategory.study,
    order: 2,
  );

  setUpAll(() => registerFallbackValue(earned));

  setUp(() {
    catalog = _MockCatalog();
    visibility = _MockVisibility();
    share = _MockShare();
  });

  BadgesBloc build() => BadgesBloc(
    getCatalog: catalog,
    changeVisibility: visibility,
    shareBadge: share,
  );

  final loaded = BadgesState(
    status: BadgesStatus.loaded,
    badges: [earned, locked],
  );

  blocTest<BadgesBloc, BadgesState>(
    'carga el catálogo',
    setUp: () => when(
      () => catalog(),
    ).thenAnswer((_) async => Success([earned, locked])),
    build: build,
    act: (bloc) => bloc.add(const BadgesEvent.started()),
    expect: () => [const BadgesState(), loaded],
  );

  blocTest<BadgesBloc, BadgesState>(
    'emite failure si el catálogo no carga',
    setUp: () => when(
      () => catalog(),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    act: (bloc) => bloc.add(const BadgesEvent.started()),
    expect: () => const [
      BadgesState(),
      BadgesState(status: BadgesStatus.failure, error: AppError.network()),
    ],
  );

  blocTest<BadgesBloc, BadgesState>(
    'filtra por categoría',
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(const BadgesEvent.categorySelected(BadgeCategory.study)),
    expect: () => [loaded.copyWith(category: BadgeCategory.study)],
    verify: (bloc) => expect(bloc.state.filtered, [locked]),
  );

  blocTest<BadgesBloc, BadgesState>(
    'oculta una insignia obtenida y avisa',
    setUp: () => when(
      () => visibility(badgeId: 'b1', visible: false),
    ).thenAnswer((_) async => Success(earned.copyWith(visible: false))),
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(BadgesEvent.visibilityToggled(badge: earned, visible: false)),
    expect: () {
      final updated = [earned.copyWith(visible: false), locked];
      return [
        loaded.copyWith(busyIds: {'b1'}),
        loaded.copyWith(
          badges: updated,
          feedback: const BadgesFeedback.visibilityChanged(visible: false),
        ),
        loaded.copyWith(badges: updated),
      ];
    },
  );

  blocTest<BadgesBloc, BadgesState>(
    'no cambia la visibilidad de una bloqueada',
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(BadgesEvent.visibilityToggled(badge: locked, visible: true)),
    expect: () => const <BadgesState>[],
  );

  blocTest<BadgesBloc, BadgesState>(
    'compartir con error emite el aviso de fallo',
    setUp: () => when(
      () => share(
        badge: any(named: 'badge'),
        message: any(named: 'message'),
      ),
    ).thenAnswer((_) async => const Failure(AppError.server())),
    build: build,
    seed: () => loaded,
    act: (bloc) =>
        bloc.add(BadgesEvent.shareRequested(badge: earned, message: '¡Sí!')),
    expect: () => [
      loaded.copyWith(busyIds: {'b1'}),
      loaded.copyWith(feedback: const BadgesFeedback.failed(AppError.server())),
      loaded,
    ],
  );

  blocTest<BadgesBloc, BadgesState>(
    'compartir correctamente emite el aviso de publicado',
    setUp: () => when(
      () => share(
        badge: any(named: 'badge'),
        message: any(named: 'message'),
      ),
    ).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(BadgesEvent.shareRequested(badge: earned)),
    expect: () => [
      loaded.copyWith(busyIds: {'b1'}),
      loaded.copyWith(feedback: const BadgesFeedback.shared()),
      loaded,
    ],
  );
}
