import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/challenge_rule_kind.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/study_room_bar_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/challenge_detail/bloc/friend_challenge_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/challenge_detail/page/friend_challenge_detail_page.dart';
import 'package:synaptixfit/presentation/screens/social/together/hub/bloc/together_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/hub/page/together_page.dart';
import 'package:synaptixfit/presentation/screens/social/together/safety/bloc/together_safety_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/study_room/bloc/study_room_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/study_room/page/study_room_page.dart';
import 'package:synaptixfit/presentation/screens/social/together/workout_detail/bloc/workout_together_bloc.dart';
import 'package:synaptixfit/presentation/screens/social/together/workout_detail/page/workout_together_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// Pantallas de «Con amigos» (ADR 0044 y 0045) con blocs simulados: lo que se
/// ve en cada estado, la acción principal y lo que mandan los botones.

class _MockSafety extends MockBloc<TogetherSafetyEvent, TogetherSafetyState>
    implements TogetherSafetyBloc {}

class _MockBar extends MockBloc<StudyRoomBarEvent, StudyRoomBarState>
    implements StudyRoomBarBloc {}

class _MockRoom extends MockBloc<StudyRoomEvent, StudyRoomState>
    implements StudyRoomBloc {}

class _MockChallenge
    extends MockBloc<FriendChallengeDetailEvent, FriendChallengeDetailState>
    implements FriendChallengeDetailBloc {}

class _MockWorkout extends MockBloc<WorkoutTogetherEvent, WorkoutTogetherState>
    implements WorkoutTogetherBloc {}

class _MockHub extends MockBloc<TogetherEvent, TogetherState>
    implements TogetherBloc {}

const _me = TogetherPerson(id: 'yo', name: 'Yo');
const _ana = TogetherPerson(id: 'ana', name: 'Ana');
const _luis = TogetherPerson(id: 'luis', name: 'Luis');

StudyRoom _room({
  StudyRoomPhase phase = StudyRoomPhase.focus,
  TogetherMemberStatus myStatus = TogetherMemberStatus.joined,
  Duration left = const Duration(minutes: 10),
}) {
  final now = DateTime.now();
  return StudyRoom(
    id: 'r1',
    creator: _ana,
    rounds: 2,
    phase: phase,
    round: phase == StudyRoomPhase.waiting ? 0 : 1,
    phaseEndsAt: phase.over ? null : now.add(left),
    serverTime: now,
    myStatus: myStatus,
    members: [
      StudyRoomMember(person: _me, status: myStatus, me: true),
      const StudyRoomMember(
        person: _ana,
        status: TogetherMemberStatus.joined,
        reaction: StudyRoomReaction.coffee,
      ),
      const StudyRoomMember(person: _luis, status: TogetherMemberStatus.left),
    ],
  );
}

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
  groupTotal: 3,
  groupTarget: 12,
  members: const [
    FriendChallengeMember(
      person: _me,
      status: TogetherMemberStatus.joined,
      contributed: true,
      me: true,
    ),
    FriendChallengeMember(person: _ana, status: TogetherMemberStatus.joined),
  ],
);

WorkoutTogether _workout(TogetherMemberStatus myStatus) => WorkoutTogether(
  id: 'w1',
  host: _ana,
  routineName: 'Fuerza en casa',
  dayName: 'Pierna',
  date: DateTime(2026, 11, 16),
  today: true,
  myStatus: myStatus,
  members: [
    WorkoutTogetherMember(
      person: _me,
      status: myStatus,
      state: WorkoutMemberState.notStarted,
      me: true,
    ),
    const WorkoutTogetherMember(
      person: _ana,
      status: TogetherMemberStatus.joined,
      state: WorkoutMemberState.training,
    ),
  ],
);

void main() {
  late _MockSafety safety;

  setUp(() {
    safety = _MockSafety();
    when(() => safety.state).thenReturn(const TogetherSafetyState());
    getIt.registerFactory<TogetherSafetyBloc>(() => safety);
  });

  tearDown(() => getIt.unregister<TogetherSafetyBloc>());

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );
    await tester.pump();
  }

  /// La cuenta atrás lleva un reloj de un segundo: se quita la pantalla para
  /// que no queden temporizadores vivos al acabar.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  group('Sala de «Estudiamos juntos» (ADR 0045)', () {
    late _MockRoom room;

    setUp(() {
      room = _MockRoom();
      getIt
        ..registerFactory<StudyRoomBloc>(() => room)
        ..registerFactory<StudyRoomBarBloc>(_MockBar.new);
    });

    tearDown(() {
      getIt
        ..unregister<StudyRoomBloc>()
        ..unregister<StudyRoomBarBloc>();
    });

    void show(StudyRoomState state) => when(() => room.state).thenReturn(state);

    StudyRoomState ready(StudyRoom r) =>
        StudyRoomState(id: 'r1', status: StudyRoomStatus.ready, room: r);

    testWidgets('esperando: «Empezar» es la acción principal', (tester) async {
      show(ready(_room(phase: StudyRoomPhase.waiting)));
      await pump(tester, const StudyRoomPage(roomId: 'r1'));

      expect(find.text('Esperando a que alguien la empiece'), findsOneWidget);
      expect(find.byType(AppPrimaryButton), findsOneWidget);
      await tester.tap(find.text('Empezar'));
      verify(() => room.add(const StudyRoomEvent.startRequested())).called(1);
      await unmount(tester);
    });

    testWidgets('en marcha: fase, minutos para el lector, quién está y '
        'quién se ha ido; salir no pregunta', (tester) async {
      final handle = tester.ensureSemantics();
      show(ready(_room()));
      await pump(tester, const StudyRoomPage(roomId: 'r1'));

      expect(find.text('Concentración · ronda 1 de 2'), findsOneWidget);
      // El lector oye los minutos, no cada segundo.
      expect(
        find.bySemanticsLabel(RegExp(r'^Quedan (9|10) minutos$')),
        findsOneWidget,
      );
      expect(find.text('En la sala · \u{2615}'), findsOneWidget);
      expect(find.text('Se ha ido'), findsOneWidget);
      // Sin acción principal mientras se estudia: solo reacciones.
      expect(find.byType(FilledButton), findsNothing);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      // La fase es una región viva y ninguna etiqueta del lector lleva
      // los segundos (mm:ss).
      expect(
        tester.getSemantics(find.text('Concentración · ronda 1 de 2')),
        isSemantics(isLiveRegion: true, isHeader: true),
      );
      expect(find.bySemanticsLabel(RegExp(r'\d{2}:\d{2}')), findsNothing);

      await tester.tap(find.bySemanticsLabel('Reacción: Fuego'));
      verify(
        () => room.add(const StudyRoomEvent.reacted(StudyRoomReaction.fire)),
      ).called(1);

      await tester.ensureVisible(find.text('Salir de la sala'));
      await tester.tap(find.text('Salir de la sala'));
      verify(() => room.add(const StudyRoomEvent.left())).called(1);
      expect(find.byType(AlertDialog), findsNothing);

      handle.dispose();
      await unmount(tester);
    });

    testWidgets('invitación: «Unirme» y «No, gracias»', (tester) async {
      show(
        ready(
          _room(
            phase: StudyRoomPhase.waiting,
            myStatus: TogetherMemberStatus.invited,
          ),
        ),
      );
      await pump(tester, const StudyRoomPage(roomId: 'r1'));

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tap(find.text('Unirme'));
      verify(() => room.add(const StudyRoomEvent.joined())).called(1);
      await tester.tap(find.text('No, gracias'));
      verify(() => room.add(const StudyRoomEvent.declined())).called(1);
      expect(find.text('Salir de la sala'), findsNothing);
      await unmount(tester);
    });

    testWidgets('ya no estoy en la sala: «Volver», sin reintentar', (
      tester,
    ) async {
      show(
        const StudyRoomState(
          id: 'r1',
          status: StudyRoomStatus.failure,
          error: AppError.business('STUDY_ROOM_NOT_FOUND'),
        ),
      );
      await pump(tester, const StudyRoomPage(roomId: 'r1'));

      expect(find.text('Ya no estás en esta sala'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      await unmount(tester);
    });

    testWidgets('terminada: estado vacío con «Volver»', (tester) async {
      show(ready(_room(phase: StudyRoomPhase.finished)));
      await pump(tester, const StudyRoomPage(roomId: 'r1'));

      expect(find.text('Sala terminada'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('error: se puede reintentar', (tester) async {
      show(
        const StudyRoomState(
          id: 'r1',
          status: StudyRoomStatus.failure,
          error: AppError.network(),
        ),
      );
      await pump(tester, const StudyRoomPage(roomId: 'r1'));

      await tester.tap(find.text('Reintentar'));
      verify(() => room.add(const StudyRoomEvent.started('r1'))).called(2);
      await unmount(tester);
    });
  });

  group('Reto con amigos (ADR 0044)', () {
    late _MockChallenge detail;

    setUp(() {
      detail = _MockChallenge();
      getIt.registerFactory<FriendChallengeDetailBloc>(() => detail);
    });

    tearDown(() => getIt.unregister<FriendChallengeDetailBloc>());

    testWidgets('meta común, quién está y deslizar para refrescar', (
      tester,
    ) async {
      when(() => detail.state).thenReturn(
        FriendChallengeDetailState(
          id: 'c1',
          status: FriendChallengeDetailStatus.ready,
          challenge: _challenge(),
        ),
      );
      await pump(tester, const FriendChallengeDetailPage(challengeId: 'c1'));

      expect(find.text('Repasa cada día'), findsWidgets);
      expect(find.text('Entre todos: 3 de 12'), findsWidgets);
      expect(find.text('Ana'), findsWidgets);

      await tester.fling(find.byType(ListView), const Offset(0, 1200), 1000);
      await tester.pumpAndSettle();
      verify(
        () => detail.add(const FriendChallengeDetailEvent.refreshed()),
      ).called(1);
    });

    testWidgets('carga: esqueleto sin botones', (tester) async {
      when(
        () => detail.state,
      ).thenReturn(const FriendChallengeDetailState(id: 'c1'));
      await pump(tester, const FriendChallengeDetailPage(challengeId: 'c1'));
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('Entrenamos juntos (ADR 0044)', () {
    late _MockWorkout workout;

    setUp(() {
      workout = _MockWorkout();
      getIt.registerFactory<WorkoutTogetherBloc>(() => workout);
    });

    tearDown(() => getIt.unregister<WorkoutTogetherBloc>());

    void show(WorkoutTogether w) => when(() => workout.state).thenReturn(
      WorkoutTogetherState(
        id: 'w1',
        status: WorkoutTogetherStatus.ready,
        workout: w,
      ),
    );

    testWidgets('invitación: «Unirme y empezar» abre mi sesión', (
      tester,
    ) async {
      show(_workout(TogetherMemberStatus.invited));
      await pump(tester, const WorkoutTogetherPage(workoutId: 'w1'));

      expect(find.text('Fuerza en casa'), findsOneWidget);
      expect(find.text('Entrenando'), findsOneWidget);
      await tester.tap(find.text('Unirme y empezar'));
      verify(
        () => workout.add(const WorkoutTogetherEvent.startRequested()),
      ).called(1);
      await tester.tap(find.text('No, gracias'));
      verify(
        () => workout.add(const WorkoutTogetherEvent.declined()),
      ).called(1);
    });

    testWidgets('dentro: «Empezar» y salir del entreno', (tester) async {
      show(_workout(TogetherMemberStatus.joined));
      await pump(tester, const WorkoutTogetherPage(workoutId: 'w1'));

      expect(find.text('Empezar'), findsOneWidget);
      await tester.ensureVisible(find.text('Salir del entreno'));
      await tester.tap(find.text('Salir del entreno'));
      verify(() => workout.add(const WorkoutTogetherEvent.left())).called(1);
    });

    // A la vez (ADR 0047): antes de empezar se dice que es para todos.
    testWidgets('esperando: «Empezar» es para todos a la vez', (tester) async {
      show(_workout(TogetherMemberStatus.joined));
      await pump(tester, const WorkoutTogetherPage(workoutId: 'w1'));

      expect(
        find.text('Cuando alguien empiece, empezáis todos a la vez.'),
        findsOneWidget,
      );
      expect(find.byType(AppPrimaryButton), findsOneWidget);
    });

    testWidgets('en marcha: lo dice y ofrece seguir entrenando', (
      tester,
    ) async {
      show(
        _workout(TogetherMemberStatus.joined).copyWith(
          startedAt: DateTime(2026, 11, 16, 18),
          startedBy: _ana,
          mySessionId: 's-me',
        ),
      );
      await pump(tester, const WorkoutTogetherPage(workoutId: 'w1'));

      expect(find.text('Ya está en marcha.'), findsOneWidget);
      expect(find.text('Seguir entrenando'), findsOneWidget);
    });
  });

  group('«Con amigos»: rachas y salas (ADR 0044 y 0045)', () {
    late _MockHub hub;

    setUp(() {
      hub = _MockHub();
      getIt.registerFactory<TogetherBloc>(() => hub);
    });

    tearDown(() => getIt.unregister<TogetherBloc>());

    testWidgets('la racha dice a quién le falta su parte y «Recordárselo»; '
        'la sala en marcha sale en «Estudiar juntos»', (tester) async {
      when(() => hub.state).thenReturn(
        TogetherState(
          status: TogetherStatus.ready,
          overview: TogetherOverview(
            streaks: const [
              FriendStreak(
                id: 's1',
                status: FriendStreakStatus.active,
                friend: _ana,
                days: 4,
                meDone: true,
                canNudge: true,
              ),
            ],
            studyRooms: [_room()],
          ),
        ),
      );
      await pump(tester, const TogetherPage());

      expect(find.text('Racha con Ana: 4 días'), findsOneWidget);
      expect(find.text('A Ana le falta su parte de hoy'), findsOneWidget);
      await tester.tap(find.text('Recordárselo'));
      verify(() => hub.add(const TogetherEvent.streakNudged('s1'))).called(1);
      expect(find.text('Estudiar juntos'), findsOneWidget);
      expect(find.text('Concentración · ronda 1 de 2'), findsOneWidget);
    });

    testWidgets('una invitación a una sala se acepta desde la lista', (
      tester,
    ) async {
      when(() => hub.state).thenReturn(
        TogetherState(
          status: TogetherStatus.ready,
          overview: TogetherOverview(
            studyRooms: [
              _room(
                phase: StudyRoomPhase.waiting,
                myStatus: TogetherMemberStatus.invited,
              ),
            ],
          ),
        ),
      );
      await pump(tester, const TogetherPage());

      expect(find.text('Ana te invita a estudiar juntos'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tap(find.text('Unirme'));
      verify(
        () => hub.add(const TogetherEvent.studyRoomJoined('r1')),
      ).called(1);
    });
  });
}
