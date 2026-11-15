import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/together_dto.dart';
import 'package:synaptixfit/domain/enums/challenge_rule_kind.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/use_cases/social/together/find_workout_together_by_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/get_friend_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/join_friend_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/decline_friend_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/leave_friend_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/react_to_friend_challenge_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/remove_friend_challenge_reaction_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/together/challenge_detail/bloc/friend_challenge_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/live/bloc/workout_together_live_bloc.dart';

const _ana = TogetherPerson(id: 'ana', name: 'Ana');

final _entry = FriendChallengeBoardEntry(
  person: _ana,
  day: DateTime(2026, 11, 16),
  myReaction: TogetherReaction.clap,
);

FriendChallenge _challenge() => FriendChallenge(
  id: 'c1',
  title: 'Repasa cada día',
  metric: ChallengeRuleMetric.reviews,
  unit: ChallengeRuleUnit.day,
  mode: FriendChallengeMode.cooperative,
  startAt: DateTime(2026, 11, 16),
  endAt: DateTime(2026, 11, 22),
  days: 7,
  myStatus: TogetherMemberStatus.joined,
  creator: _ana,
  board: [_entry],
);

WorkoutTogether _workout({bool today = true}) => WorkoutTogether(
  id: 'w1',
  host: _ana,
  date: DateTime(2026, 11, 16),
  today: today,
  myStatus: TogetherMemberStatus.joined,
);

class _Get implements GetFriendChallengeUseCaseContract {
  @override
  Future<AppResult<FriendChallenge>> call(String id) async =>
      Success(_challenge());
}

class _Join implements JoinFriendChallengeUseCaseContract {
  @override
  Future<AppResult<FriendChallenge>> call(String id) async =>
      Success(_challenge());
}

class _Decline implements DeclineFriendChallengeUseCaseContract {
  @override
  Future<AppResult<Unit>> call(String id) async => const Success(unit);
}

class _Leave implements LeaveFriendChallengeUseCaseContract {
  @override
  Future<AppResult<Unit>> call(String id) async => const Success(unit);
}

class _React implements ReactToFriendChallengeUseCaseContract {
  final calls = <TogetherReaction>[];

  @override
  Future<AppResult<Unit>> call(
    String challengeId, {
    required String recipientId,
    required DateTime day,
    required TogetherReaction reaction,
  }) async {
    calls.add(reaction);
    return const Success(unit);
  }
}

class _Remove implements RemoveFriendChallengeReactionUseCaseContract {
  var calls = 0;

  @override
  Future<AppResult<Unit>> call(
    String challengeId, {
    required String recipientId,
    required DateTime day,
  }) async {
    calls++;
    return const Success(unit);
  }
}

class _Find implements FindWorkoutTogetherBySessionUseCaseContract {
  _Find(this.result);

  final WorkoutTogether? result;
  var calls = 0;
  var fail = false;

  @override
  Future<AppResult<WorkoutTogether?>> call(String sessionId) async {
    calls++;
    if (fail) return const Failure(AppError.network());
    return Success(result);
  }
}

FriendChallengeDetailBloc _detail(_React react, _Remove remove) =>
    FriendChallengeDetailBloc(
      get: _Get(),
      join: _Join(),
      decline: _Decline(),
      leave: _Leave(),
      react: react,
      removeReaction: remove,
    );

void main() {
  group('Con amigos (ADR 0044)', () {
    test('el DTO lee el tablón: recuentos solo propios y reacciones '
        'desconocidas fuera', () {
      final dto = FriendChallengeDto.fromJson({
        'id': 'c1',
        'title': 'Repasa cada día',
        'metric': 'REVIEWS',
        'unit': 'DAY',
        'mode': 'COMPETITION',
        'startAt': '2026-11-16T08:00:00Z',
        'endAt': '2026-11-22T22:59:59Z',
        'days': 7,
        'myStatus': 'JOINED',
        'creator': {'id': 'ana', 'fullName': 'Ana'},
        'groupTotal': 3,
        'groupTarget': 12,
        'members': [
          {
            'person': {'id': 'yo', 'fullName': 'Yo'},
            'status': 'JOINED',
            'contributed': true,
            'points': 2,
            'me': true,
          },
        ],
        'board': [
          {
            'person': {'id': 'yo', 'fullName': 'Yo'},
            'day': '2026-11-16',
            'mine': true,
            'counts': {'CLAP': 2, 'UNKNOWN': 1},
          },
        ],
      });
      final c = dto.toDomain();
      expect(c.mode, FriendChallengeMode.competition);
      expect(c.members.single.me, isTrue);
      expect(c.members.single.points, 2);
      expect(c.board.single.counts, {TogetherReaction.clap: 2});
      expect(c.board.single.day, DateTime(2026, 11, 16));
    });

    test('una persona que borró su cuenta llega sin nombre', () {
      final dto = TogetherPersonDto.fromJson({'id': 'x'});
      expect(dto.toDomain().name, isEmpty);
    });

    test(
      'la reacción repetida llama a quitar y la nueva a reaccionar',
      () async {
        final react = _React();
        final remove = _Remove();
        final bloc = _detail(react, remove)
          ..add(const FriendChallengeDetailEvent.started('c1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          FriendChallengeDetailEvent.reactionTapped(
            _entry,
            TogetherReaction.clap,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(
          FriendChallengeDetailEvent.reactionTapped(
            _entry,
            TogetherReaction.fire,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(remove.calls, 1);
        expect(react.calls, [TogetherReaction.fire]);
        await bloc.close();
      },
    );

    blocTest<FriendChallengeDetailBloc, FriendChallengeDetailState>(
      'salir avisa una vez (para el «Deshacer») sin preguntar',
      build: () => _detail(_React(), _Remove()),
      seed: () => FriendChallengeDetailState(
        id: 'c1',
        status: FriendChallengeDetailStatus.ready,
        challenge: _challenge(),
      ),
      act: (bloc) => bloc.add(const FriendChallengeDetailEvent.left()),
      expect: () => [
        isA<FriendChallengeDetailState>().having((s) => s.busy, 'busy', true),
        isA<FriendChallengeDetailState>().having(
          (s) => s.effect,
          'efecto',
          FriendChallengeDetailEffect.left,
        ),
        isA<FriendChallengeDetailState>().having(
          (s) => s.effect,
          'consumido',
          isNull,
        ),
      ],
    );

    test('una sesión que no es de entrenar juntos no pinta nada ni vuelve a '
        'preguntar', () async {
      final find = _Find(null);
      final bloc = WorkoutTogetherLiveBloc(
        find: find,
        pollInterval: const Duration(milliseconds: 5),
      )..add(const WorkoutTogetherLiveEvent.started('s1'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.workout, isNull);
      expect(find.calls, 1);
      await bloc.close();
    });

    test(
      'de hoy: consulta cada poco y un fallo de red no borra lo visto',
      () async {
        final find = _Find(_workout());
        final bloc = WorkoutTogetherLiveBloc(
          find: find,
          pollInterval: const Duration(milliseconds: 5),
        )..add(const WorkoutTogetherLiveEvent.started('s1'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(find.calls, greaterThan(2));
        find.fail = true;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.workout?.id, 'w1');
        await bloc.close();
        final calls = find.calls;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          find.calls,
          calls,
          reason: 'al cerrar la pantalla deja de preguntar',
        );
      },
    );

    test('el resumen de una sesión terminada lee una sola vez', () async {
      final find = _Find(_workout(today: false));
      final bloc = WorkoutTogetherLiveBloc(
        find: find,
        pollInterval: const Duration(milliseconds: 5),
      )..add(const WorkoutTogetherLiveEvent.started('s1', poll: false));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(find.calls, 1);
      expect(bloc.state.workout?.id, 'w1');
      await bloc.close();
    });
  });
}
