import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/social/dto/together_dto.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/planner_options.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/choose_study_room_subject_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/decline_study_room_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/get_study_room_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/join_study_room_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/leave_study_room_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/react_in_study_room_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/start_study_room_use_case.dart';
import 'package:synaptixfit/presentation/screens/social/together/study_room/bloc/study_room_bloc.dart';

/// Sala de «Estudiamos juntos» (ADR 0045): el DTO, el reloj corregido por el
/// del servidor y la consulta periódica.

final _deviceNow = DateTime.utc(2026, 11, 18, 16);

StudyRoom _room({
  StudyRoomPhase phase = StudyRoomPhase.focus,
  Duration serverAhead = const Duration(seconds: 30),
}) => StudyRoom(
  id: 'r1',
  creator: const TogetherPerson(id: 'ana', name: 'Ana'),
  length: StudyRoomLength.short,
  phase: phase,
  round: 1,
  rounds: 2,
  // El servidor va 30 s por delante del móvil y la fase acaba en 10 min.
  serverTime: _deviceNow.add(serverAhead),
  phaseEndsAt: phase.over
      ? null
      : _deviceNow.add(serverAhead).add(const Duration(minutes: 10)),
  myStatus: TogetherMemberStatus.joined,
);

class _Get implements GetStudyRoomUseCaseContract {
  _Get(this.room);

  StudyRoom room;
  var calls = 0;
  var fail = false;
  AppError? failWith;

  @override
  Future<AppResult<StudyRoom>> call(String id) async {
    calls++;
    if (failWith case final error?) return Failure(error);
    return fail ? const Failure(AppError.network()) : Success(room);
  }
}

class _Join implements JoinStudyRoomUseCaseContract {
  @override
  Future<AppResult<StudyRoom>> call(String id) async => Success(_room());
}

class _Decline implements DeclineStudyRoomUseCaseContract {
  @override
  Future<AppResult<Unit>> call(String id) async => const Success(unit);
}

class _Leave implements LeaveStudyRoomUseCaseContract {
  var calls = 0;

  @override
  Future<AppResult<Unit>> call(String id) async {
    calls++;
    return const Success(unit);
  }
}

class _Start implements StartStudyRoomUseCaseContract {
  @override
  Future<AppResult<StudyRoom>> call(String id) async => Success(_room());
}

class _Subject implements ChooseStudyRoomSubjectUseCaseContract {
  String? chosen = 'none';

  @override
  Future<AppResult<StudyRoom>> call(String id, {String? subjectId}) async {
    chosen = subjectId;
    return Success(_room());
  }
}

class _React implements ReactInStudyRoomUseCaseContract {
  @override
  Future<AppResult<StudyRoom>> call(
    String id, {
    required StudyRoomReaction reaction,
  }) async => Success(_room());
}

class _Subjects implements GetPlannerSubjectsUseCaseContract {
  @override
  Future<AppResult<List<SubjectOption>>> call() async =>
      const Success([SubjectOption(id: 's1', name: 'Álgebra')]);
}

StudyRoomBloc _bloc(_Get get, {_Subject? subject, _Leave? leave}) =>
    StudyRoomBloc(
      get: get,
      join: _Join(),
      decline: _Decline(),
      leave: leave ?? _Leave(),
      start: _Start(),
      chooseSubject: subject ?? _Subject(),
      react: _React(),
      subjects: _Subjects(),
      pollInterval: const Duration(milliseconds: 5),
      now: () => _deviceNow,
    );

void main() {
  group('Estudiamos juntos (ADR 0045)', () {
    test('el DTO lee la sala: mi asignatura, reacciones conocidas y la fase '
        'de descanso', () {
      final room = StudyRoomDto.fromJson({
        'id': 'r1',
        'creator': {'id': 'ana', 'fullName': 'Ana'},
        'length': 'LONG',
        'focusMinutes': 50,
        'breakMinutes': 10,
        'rounds': 3,
        'phase': 'BREAK',
        'round': 1,
        'phaseEndsAt': '2026-11-18T17:00:00Z',
        'startedAt': '2026-11-18T16:00:00Z',
        'endsAt': '2026-11-18T18:50:00Z',
        'serverTime': '2026-11-18T16:55:00Z',
        'myStatus': 'JOINED',
        'mySubjectId': 's1',
        'members': [
          {
            'person': {'id': 'ana', 'fullName': 'Ana'},
            'status': 'JOINED',
            'reaction': 'COFFEE',
          },
          {
            'person': {'id': 'luis'},
            'status': 'LEFT',
            'reaction': 'WAVE',
          },
        ],
      }).toDomain();
      expect(room.phase, StudyRoomPhase.rest);
      expect(room.length, StudyRoomLength.long);
      expect(room.mySubjectId, 's1');
      expect(room.members.first.reaction, StudyRoomReaction.coffee);
      expect(room.members.last.reaction, isNull);
      expect(room.inside.single.person.id, 'ana');
      expect(
        room.phaseEndsAt!.difference(room.serverTime),
        const Duration(minutes: 5),
      );
    });

    test('los topes y las duraciones de ronda llegan del servidor', () {
      final limits = TogetherLimitsDto.fromJson({
        'challengeFriends': 24,
        'workoutFriends': 4,
        'studyRoomFriends': 4,
        'friendStreaks': 5,
        'studyRoomRounds': 4,
        'studyRoomLengths': [
          {'length': 'SHORT', 'focusMinutes': 25, 'breakMinutes': 5},
          {'length': 'LONG', 'focusMinutes': 50, 'breakMinutes': 10},
        ],
      }).toDomain();
      expect(limits.friendsFor(TogetherInviteKind.studyRoom), 4);
      expect(limits.friendsFor(TogetherInviteKind.streak), 1);
      expect(limits.studyRoomLengths.last.length, StudyRoomLength.long);
      expect(limits.studyRoomLengths.last.breakMinutes, 10);
    });

    test('la cuenta atrás usa el reloj del móvil corregido por el del '
        'servidor', () async {
      final bloc = _bloc(_Get(_room()))
        ..add(const StudyRoomEvent.started('r1'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(bloc.state.clockOffset, const Duration(seconds: 30));
      // Para el móvil «ahora» es 16:00:00, para el servidor 16:00:30: quedan
      // los 10 minutos completos, no 10 min 30 s.
      expect(bloc.state.remainingAt(_deviceNow), const Duration(minutes: 10));
      expect(bloc.state.subjects.single.name, 'Álgebra');
      await bloc.close();
    });

    test('si ya no estoy en la sala deja de preguntar y lo dice', () async {
      final get = _Get(_room());
      final bloc = _bloc(get)..add(const StudyRoomEvent.started('r1'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      get.failWith = const AppError.business('STUDY_ROOM_NOT_FOUND');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final calls = get.calls;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(get.calls, calls);
      expect(bloc.state.status, StudyRoomStatus.failure);
      await bloc.close();
    });

    test('consulta cada poco, un fallo no borra lo visto y deja de preguntar '
        'al terminar la sala', () async {
      final get = _Get(_room());
      final bloc = _bloc(get)..add(const StudyRoomEvent.started('r1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(get.calls, greaterThan(2));
      get.fail = true;
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(bloc.state.room?.phase, StudyRoomPhase.focus);
      get
        ..fail = false
        ..room = _room(phase: StudyRoomPhase.finished);
      await Future<void>.delayed(const Duration(milliseconds: 15));
      final calls = get.calls;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(get.calls, calls, reason: 'la sala terminada no se consulta');
      expect(bloc.state.room?.phase, StudyRoomPhase.finished);
      await bloc.close();
    });

    test('salir se aplaza: «Deshacer» no toca el servidor, cerrar el aviso '
        'sale; elegir «Ninguna» manda null', () async {
      final subject = _Subject();
      final leave = _Leave();
      final bloc = _bloc(_Get(_room()), subject: subject, leave: leave)
        ..add(const StudyRoomEvent.started('r1'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final states = <StudyRoomState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(const StudyRoomEvent.left());
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(states.where((s) => s.left), hasLength(1));
      expect(states.last.left, isFalse);
      expect(bloc.state.inside, isFalse);
      bloc.add(const StudyRoomEvent.leaveUndone());
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(leave.calls, 0);
      expect(bloc.state.inside, isTrue);
      bloc
        ..add(const StudyRoomEvent.left())
        ..add(const StudyRoomEvent.leaveCommitted());
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(leave.calls, 1);
      bloc.add(const StudyRoomEvent.subjectChosen(null));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(subject.chosen, isNull);
      await sub.cancel();
      await bloc.close();
    });
  });
}
