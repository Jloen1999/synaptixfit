import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/get_unnotified_badges_use_case.dart';
import 'package:synaptixfit/domain/use_cases/progress/mark_badges_notified_use_case.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/achievements_bloc.dart';

import '../../../progress_fixtures.dart';

class _MockAccount extends Mock implements GetAccountUseCaseContract {}

class _MockCheck extends Mock implements GetUnnotifiedBadgesUseCaseContract {}

class _MockMark extends Mock implements MarkBadgesNotifiedUseCaseContract {}

class _MockWatch extends Mock implements WatchDataChangesUseCaseContract {}

Account _account(int level) => Account(
  id: 'u1',
  email: 'a@b.c',
  fullName: 'Ana',
  level: level,
  levelXp: 10,
  levelThreshold: 100,
  streak: 0,
  privacy: Visibility.public,
  role: UserRole.user,
  hasPassword: true,
  googleLinked: false,
);

final _b1 = testBadge(id: 'b1');
final _b2 = testBadge(id: 'b2');

void main() {
  late _MockAccount getAccount;
  late _MockCheck check;
  late _MockMark mark;
  late _MockWatch watch;
  late StreamController<Set<DataTopic>> changes;

  setUp(() {
    getAccount = _MockAccount();
    check = _MockCheck();
    mark = _MockMark();
    watch = _MockWatch();
    changes = StreamController<Set<DataTopic>>.broadcast();
    when(
      () => watch(topics: any(named: 'topics')),
    ).thenAnswer((_) => changes.stream);
    when(() => check()).thenAnswer((_) async => const Success([]));
    when(() => mark(any())).thenAnswer((_) async => const Success(unit));
  });

  tearDown(() => changes.close());

  AchievementsBloc build() => AchievementsBloc(
    getAccount: getAccount,
    checkNewBadges: check,
    markBadgesNotified: mark,
    watchChanges: watch,
  );

  blocTest<AchievementsBloc, AchievementsState>(
    'al entrar recoge las insignias pendientes',
    setUp: () => when(() => check()).thenAnswer((_) async => Success([_b1])),
    build: build,
    act: (bloc) => bloc.add(AchievementsEvent.started(account: _account(2))),
    expect: () => [
      const AchievementsState(knownLevel: 2),
      AchievementsState(knownLevel: 2, badges: [_b1]),
    ],
  );

  blocTest<AchievementsBloc, AchievementsState>(
    'un cambio de XP de otra pantalla detecta la subida de nivel',
    setUp: () =>
        when(() => getAccount()).thenAnswer((_) async => Success(_account(3))),
    build: build,
    act: (bloc) async {
      bloc.add(AchievementsEvent.started(account: _account(2)));
      await Future<void>.delayed(Duration.zero);
      changes.add({DataTopic.gamification});
    },
    expect: () => [
      const AchievementsState(knownLevel: 2),
      AchievementsState(knownLevel: 3, account: _account(3), levelReached: 3),
    ],
  );

  blocTest<AchievementsBloc, AchievementsState>(
    'sin subida de nivel solo actualiza la cuenta',
    setUp: () =>
        when(() => getAccount()).thenAnswer((_) async => Success(_account(2))),
    build: build,
    seed: () => const AchievementsState(knownLevel: 2),
    act: (bloc) => bloc.add(const AchievementsEvent.dataChanged()),
    expect: () => [AchievementsState(knownLevel: 2, account: _account(2))],
  );

  blocTest<AchievementsBloc, AchievementsState>(
    'al cerrar solo quita lo mostrado y lo marca como visto',
    build: build,
    seed: () => AchievementsState(levelReached: 3, badges: [_b1, _b2]),
    act: (bloc) => bloc.add(
      const AchievementsEvent.celebrated(level: 3, badgeIds: ['b1']),
    ),
    expect: () => [
      AchievementsState(badges: [_b2]),
    ],
    verify: (_) => verify(() => mark(['b1'])).called(1),
  );
}
