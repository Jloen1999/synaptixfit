import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/models/social/together_live.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/together_live_bloc.dart';

import 'together_live_fakes.dart';

/// Canal en directo de «Con amigos» en el armazón (ADR 0047).
void main() {
  test(
    'abre el canal al entrar y publica cada aviso como cambio de datos',
    () async {
      final watch = FakeWatchLive();
      final publish = FakePublish();
      final bloc = liveBloc(watch: watch, publish: publish)
        ..add(const TogetherLiveEvent.started());
      await settle();
      expect(watch.open, 1);

      watch.signal(TogetherLiveTopic.connected);
      await settle();
      expect(bloc.state.connected, isTrue);

      watch.signal(TogetherLiveTopic.studyRoom, 'r1');
      watch.signal(TogetherLiveTopic.together, 'w9');
      await settle();
      expect(publish.published, [
        {DataTopic.studyRoom},
        {DataTopic.social},
      ]);
      await bloc.close();
      expect(watch.open, 0, reason: 'al cerrar sesión se cierra el canal');
    },
  );

  test('si se corta, vuelve a abrirlo con espera creciente y, al volver, '
      'las pantallas leen otra vez lo que se pudo perder', () async {
    final watch = FakeWatchLive();
    final publish = FakePublish();
    final bloc = liveBloc(watch: watch, publish: publish)
      ..add(const TogetherLiveEvent.started());
    await settle();
    watch.signal(TogetherLiveTopic.connected);
    await settle();

    watch.drop();
    await settle();
    expect(bloc.state.connected, isFalse);
    expect(watch.channels, hasLength(1));
    await settle(30);
    expect(watch.channels, hasLength(2), reason: 'reintenta tras la espera');

    watch.drop();
    await settle(15);
    expect(watch.channels, hasLength(2), reason: 'la segunda espera es mayor');
    await settle(30);
    expect(watch.channels, hasLength(3));

    watch.signal(TogetherLiveTopic.connected);
    await settle();
    expect(publish.published.last, containsAll(DataTopic.live));
    await bloc.close();
  });

  test(
    'en segundo plano se cierra y en primer plano se vuelve a abrir',
    () async {
      final watch = FakeWatchLive();
      final bloc = liveBloc(watch: watch)
        ..add(const TogetherLiveEvent.started());
      await settle();
      bloc.add(const TogetherLiveEvent.backgrounded());
      await settle(30);
      expect(watch.open, 0);
      expect(
        watch.channels,
        hasLength(1),
        reason: 'sin reintentos en segundo plano',
      );

      bloc.add(const TogetherLiveEvent.foregrounded());
      await settle();
      expect(watch.open, 1);
      await bloc.close();
    },
  );

  test('un amigo empieza un entreno juntos en el que estoy: «Ana ha empezado» '
      'y la barra de sesión abierta lee otra vez', () async {
    final watch = FakeWatchLive();
    final publish = FakePublish();
    final getWorkout = FakeGetWorkout(workout());
    final bloc = liveBloc(
      watch: watch,
      publish: publish,
      getWorkout: getWorkout,
      overview: FakeOverview(TogetherOverview(workouts: [workout()])),
    );
    final starts = <TogetherLiveStart>[];
    final sub = bloc.stream.listen((s) {
      if (s.startedByFriend case final start?) starts.add(start);
    });
    bloc.add(const TogetherLiveEvent.started());
    await settle();

    getWorkout.current = workout(
      startedAt: DateTime(2026, 11, 16, 18),
      startedBy: ana,
    );
    watch.signal(TogetherLiveTopic.workout, 'w1');
    await settle();

    expect(starts, [
      const TogetherLiveStart(workoutId: 'w1', sessionId: 's-me', name: 'Ana'),
    ]);
    expect(publish.published, anyElement(equals({DataTopic.training})));

    // Otra serie de Ana: ya había empezado, no se avisa otra vez.
    watch.signal(TogetherLiveTopic.workout, 'w1');
    await settle();
    expect(starts, hasLength(1));
    await sub.cancel();
    await bloc.close();
  });

  test('si empecé yo, no se avisa', () async {
    final watch = FakeWatchLive();
    final getWorkout = FakeGetWorkout(workout());
    final bloc = liveBloc(
      watch: watch,
      getWorkout: getWorkout,
      overview: FakeOverview(TogetherOverview(workouts: [workout()])),
    );
    final starts = <TogetherLiveStart>[];
    final sub = bloc.stream.listen((s) {
      if (s.startedByFriend case final start?) starts.add(start);
    });
    bloc.add(const TogetherLiveEvent.started());
    await settle();
    getWorkout.current = workout(
      startedAt: DateTime(2026, 11, 16, 18),
      startedBy: me,
    );
    watch.signal(TogetherLiveTopic.workout, 'w1');
    await settle();
    expect(starts, isEmpty);
    await sub.cancel();
    await bloc.close();
  });

  group('al abrir la app', () {
    Future<List<TogetherLiveOpen>> opened(TogetherOverview overview) async {
      final bloc = liveBloc(
        watch: FakeWatchLive(),
        overview: FakeOverview(overview),
      );
      final result = <TogetherLiveOpen>[];
      final sub = bloc.stream.listen((s) {
        if (s.openOnLaunch case final open?) result.add(open);
      });
      bloc
        ..add(const TogetherLiveEvent.started())
        ..add(const TogetherLiveEvent.started());
      await settle();
      await sub.cancel();
      await bloc.close();
      return result;
    }

    test('lleva una vez a mi sesión del entreno juntos en marcha', () async {
      final running = workout(
        startedAt: DateTime(2026, 11, 16, 18),
        startedBy: ana,
      );
      expect(await opened(TogetherOverview(workouts: [running])), [
        const TogetherLiveOpen.session('s-me'),
      ]);
    });

    test('sin entreno en marcha, a la sala en marcha', () async {
      final room = StudyRoom(
        id: 'r1',
        creator: ana,
        phase: StudyRoomPhase.focus,
        serverTime: DateTime(2026, 11, 16, 18),
        myStatus: TogetherMemberStatus.joined,
      );
      expect(
        await opened(
          TogetherOverview(workouts: [workout()], studyRooms: [room]),
        ),
        [const TogetherLiveOpen.studyRoom('r1')],
      );
    });

    test('nada si no ha empezado, si ya terminé o si la sala espera', () async {
      final finished = workout(
        startedAt: DateTime(2026, 11, 16, 18),
        startedBy: ana,
        myState: WorkoutMemberState.finished,
      );
      final waiting = StudyRoom(
        id: 'r1',
        creator: ana,
        phase: StudyRoomPhase.waiting,
        serverTime: DateTime(2026, 11, 16, 18),
        myStatus: TogetherMemberStatus.joined,
      );
      expect(
        await opened(
          TogetherOverview(
            workouts: [workout(), finished],
            studyRooms: [waiting],
          ),
        ),
        isEmpty,
      );
    });
  });
}
