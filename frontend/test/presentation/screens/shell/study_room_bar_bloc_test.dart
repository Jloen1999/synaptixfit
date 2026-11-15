import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/reminders/timer_alert.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/use_cases/reminders/cancel_timer_alert_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/schedule_timer_alert_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/get_study_room_use_case.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/study_room_bar_bloc.dart';

/// Barra y aviso de la sala «Estudiar juntos» (ADR 0045, cierre del plan
/// premium): la cuenta atrás de la fase que dio el servidor, el aviso en su
/// propio hueco y una sola lectura al llegar a cero.

final _deviceNow = DateTime.utc(2026, 11, 18, 16);

StudyRoom _room({
  StudyRoomPhase phase = StudyRoomPhase.focus,
  int round = 1,
  TogetherMemberStatus status = TogetherMemberStatus.joined,
  Duration endsIn = const Duration(minutes: 10),
}) => StudyRoom(
  id: 'r1',
  creator: const TogetherPerson(id: 'ana', name: 'Ana'),
  phase: phase,
  round: round,
  rounds: 2,
  // El servidor va 30 s por delante del móvil.
  serverTime: _deviceNow.add(const Duration(seconds: 30)),
  phaseEndsAt: phase.over
      ? null
      : _deviceNow.add(const Duration(seconds: 30)).add(endsIn),
  myStatus: status,
);

const _texts = StudyRoomAlertTexts(
  title: 'Estudiar juntos',
  focusEndBody: _focusBody,
  breakEndBody: 'vuelve',
  channelName: 'Temporizador',
);

String _focusBody(int round, int rounds) => 'focus $round/$rounds';

class _Get implements GetStudyRoomUseCaseContract {
  StudyRoom? room;
  AppError? error;
  var calls = 0;

  @override
  Future<AppResult<StudyRoom>> call(String id) async {
    calls++;
    final failure = error;
    return failure != null ? Failure(failure) : Success(room!);
  }
}

class _Schedule implements ScheduleTimerAlertUseCaseContract {
  final alerts = <TimerAlert>[];

  @override
  Future<AppResult<Unit>> call(TimerAlert alert) async {
    alerts.add(alert);
    return const Success(unit);
  }
}

class _Cancel implements CancelTimerAlertUseCaseContract {
  final slots = <TimerAlertSlot>[];

  @override
  Future<AppResult<Unit>> call({
    TimerAlertSlot slot = TimerAlertSlot.pomodoro,
  }) async {
    slots.add(slot);
    return const Success(unit);
  }
}

void main() {
  late _Get get;
  late _Schedule schedule;
  late _Cancel cancel;
  late DateTime now;
  late StudyRoomBarBloc bloc;

  setUp(() {
    get = _Get();
    schedule = _Schedule();
    cancel = _Cancel();
    now = _deviceNow;
    bloc = StudyRoomBarBloc(
      get: get,
      scheduleAlert: schedule,
      cancelAlert: cancel,
      now: () => now,
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('dentro de la sala: barra con la cuenta atrás corregida y aviso en el '
      'hueco de la sala', () async {
    bloc.add(
      StudyRoomBarEvent.seen(
        room: _room(),
        clockOffset: const Duration(seconds: 30),
        texts: _texts,
      ),
    );
    await settle();

    expect(bloc.state.roomId, 'r1');
    expect(bloc.state.remainingSeconds, 600);
    final alert = schedule.alerts.single;
    expect(alert.slot, TimerAlertSlot.studyRoom);
    expect(alert.at, _deviceNow.add(const Duration(minutes: 10)));
    expect(alert.body, 'focus 1/2');
  });

  test('en el descanso el aviso no deduce la ronda siguiente', () async {
    bloc.add(
      StudyRoomBarEvent.seen(
        room: _room(phase: StudyRoomPhase.rest),
        clockOffset: const Duration(seconds: 30),
        texts: _texts,
      ),
    );
    await settle();
    expect(schedule.alerts.single.body, 'vuelve');
  });

  test('al salir de la sala la barra y su aviso desaparecen; el del Pomodoro '
      'no se toca', () async {
    bloc.add(
      StudyRoomBarEvent.seen(
        room: _room(),
        clockOffset: const Duration(seconds: 30),
        texts: _texts,
      ),
    );
    await settle();
    bloc.add(const StudyRoomBarEvent.cleared('r1'));
    await settle();

    expect(bloc.state.roomId, isNull);
    expect(cancel.slots, [TimerAlertSlot.studyRoom]);
  });

  test('invitado o con la sala terminada no hay barra', () async {
    bloc.add(
      StudyRoomBarEvent.seen(
        room: _room(status: TogetherMemberStatus.invited),
        clockOffset: Duration.zero,
        texts: _texts,
      ),
    );
    await settle();
    expect(bloc.state.roomId, isNull);
    expect(schedule.alerts, isEmpty);
  });

  test('a cero pide la sala una sola vez y sigue con la fase nueva', () async {
    bloc.add(
      StudyRoomBarEvent.seen(
        room: _room(endsIn: const Duration(seconds: 1)),
        clockOffset: const Duration(seconds: 30),
        texts: _texts,
      ),
    );
    await settle();
    now = now.add(const Duration(seconds: 2));
    get.room = _room(
      phase: StudyRoomPhase.rest,
      endsIn: const Duration(minutes: 5),
    ).copyWith(serverTime: now.add(const Duration(seconds: 30)));
    bloc
      ..add(const StudyRoomBarEvent.ticked())
      ..add(const StudyRoomBarEvent.ticked());
    await settle();
    await settle();

    expect(get.calls, 1);
    expect(bloc.state.phase, StudyRoomPhase.rest);
    expect(schedule.alerts.last.body, 'vuelve');
  });

  test('si ya no estoy en la sala, la barra se quita', () async {
    bloc.add(
      StudyRoomBarEvent.seen(
        room: _room(endsIn: Duration.zero),
        clockOffset: const Duration(seconds: 30),
        texts: _texts,
      ),
    );
    await settle();
    get.error = const AppError.business('STUDY_ROOM_NOT_FOUND');
    bloc.add(const StudyRoomBarEvent.ticked());
    await settle();
    await settle();

    expect(bloc.state.roomId, isNull);
  });

  test('esperando a que alguien la empiece, pregunta cada 12 s y se entera '
      'de que empezó', () async {
    bloc.add(
      StudyRoomBarEvent.seen(
        room: _room(phase: StudyRoomPhase.waiting),
        clockOffset: const Duration(seconds: 30),
        texts: _texts,
      ),
    );
    await settle();
    expect(schedule.alerts, isEmpty);
    bloc.add(const StudyRoomBarEvent.ticked());
    await settle();
    expect(get.calls, 0);

    now = now.add(const Duration(seconds: 13));
    get.room = _room().copyWith(
      serverTime: now.add(const Duration(seconds: 30)),
    );
    bloc.add(const StudyRoomBarEvent.ticked());
    await settle();
    await settle();

    expect(get.calls, 1);
    expect(bloc.state.phase, StudyRoomPhase.focus);
    expect(schedule.alerts.single.body, 'focus 1/2');
  });
}
