import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/challenge_status.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/enums/milestone_status.dart';
import 'package:synaptixfit/domain/models/challenges/challenge.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/challenges/widgets/challenge_card.dart';
import 'package:synaptixfit/presentation/screens/challenges/widgets/challenge_labels.dart';
import 'package:synaptixfit/presentation/screens/challenges/widgets/dependency_graph.dart';
import 'package:synaptixfit/presentation/screens/challenges/widgets/milestone_tile.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'challenges_fixtures.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  locale: const Locale('es'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final m1 = ChallengesFixtures.milestone('m1', completed: true);
  final m2 = ChallengesFixtures.milestone(
    'm2',
    status: MilestoneStatus.locked,
    dependencies: ['m1'],
  );
  final m3 = ChallengesFixtures.milestone('m3', dependencies: ['m1', 'm2']);

  testWidgets('la tarjeta muestra título, progreso y tareas', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _wrap(
        ChallengeCard(
          challenge: ChallengesFixtures.challenge(milestones: [m1, m2]),
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Reto c1'), findsOneWidget);
    expect(find.text('1/2 tareas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la tarjeta de un reto con objetivo muestra las sesiones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _wrap(
        ChallengeCard(
          challenge: ChallengesFixtures.challenge().copyWith(
            type: ChallengeType.fitness,
            sessionTarget: 12,
            sessionsCompleted: 4,
            tracksTrainingSessions: true,
          ),
          onTap: () {},
        ),
      ),
    );
    expect(find.text('4 / 12 sesiones'), findsOneWidget);
    // Siguiente paso: lo que falta, en palabras.
    expect(find.text('Te faltan 8 sesiones'), findsOneWidget);
    // El contador lleva su propio icono para no repetir el del tipo.
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('siguiente paso y plazo de la tarjeta', () {
    Future<void> pumpCard(
      WidgetTester tester,
      Challenge challenge, {
      VoidCallback? onClone,
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(
          ChallengeCard(challenge: challenge, onTap: () {}, onClone: onClone),
        ),
      );
    }

    testWidgets('con tareas dice cuál es la siguiente', (tester) async {
      final m4 = ChallengesFixtures.milestone('m4');
      await pumpCard(
        tester,
        ChallengesFixtures.challenge(milestones: [m1, m4]),
      );
      expect(find.text('Siguiente: Tarea m4'), findsOneWidget);
    });

    testWidgets('con el plazo cerca, cuenta los días que quedan', (
      tester,
    ) async {
      final now = DateTime.now();
      await pumpCard(
        tester,
        ChallengesFixtures.challenge().copyWith(
          endAt: DateTime(now.year, now.month, now.day + 2, 23, 59),
        ),
      );
      expect(find.text('Quedan 2 días'), findsOneWidget);
      expect(
        find.text('Márcalo como hecho cuando lo termines'),
        findsOneWidget,
      );
    });

    testWidgets('completado: celebra la XP ganada', (tester) async {
      await pumpCard(
        tester,
        ChallengesFixtures.challenge(completed: true, xpAwarded: 40),
      );
      expect(find.text('Completado'), findsOneWidget);
      expect(find.text('¡Conseguido! Has ganado 40 XP'), findsOneWidget);
    });

    testWidgets('vencido: explica cómo seguir', (tester) async {
      await pumpCard(
        tester,
        ChallengesFixtures.challenge().copyWith(
          status: ChallengeStatus.expired,
        ),
      );
      expect(find.text('Vencido'), findsOneWidget);
      expect(
        find.text('Se acabó el plazo. Amplía la fecha para seguir.'),
        findsOneWidget,
      );
    });

    testWidgets('reto ajeno: sin siguiente paso y con «Añadir a mis retos»', (
      tester,
    ) async {
      var cloned = false;
      await pumpCard(
        tester,
        ChallengesFixtures.challenge(owned: false),
        onClone: () => cloned = true,
      );
      expect(find.textContaining('Márcalo'), findsNothing);
      await tester.tap(find.byTooltip('Añadir a mis retos'));
      expect(cloned, isTrue);
    });
  });

  test('siguiente tarea, sesiones que faltan y pesos manuales', () {
    // El reparto automático de 3 tareas (33,33 / 33,33 / 33,34) no es manual.
    final auto = [
      for (final (i, w) in [33.33, 33.33, 33.34].indexed)
        ChallengesFixtures.milestone('a$i').copyWith(weight: w, order: i),
    ];
    expect(
      ChallengesFixtures.challenge(milestones: auto).showsTaskWeights,
      isFalse,
    );
    final m4 = ChallengesFixtures.milestone('m4');
    expect(
      ChallengesFixtures.challenge(milestones: [m1, m2, m4]).nextMilestone?.id,
      'm4',
    );
    expect(
      ChallengesFixtures.challenge(milestones: [m1]).nextMilestone,
      isNull,
    );
    final sessions = ChallengesFixtures.challenge().copyWith(
      sessionTarget: 12,
      sessionsCompleted: 14,
      tracksTrainingSessions: true,
    );
    expect(sessions.sessionsRemaining, 0);
    expect(
      ChallengesFixtures.challenge(milestones: [m1, m4]).showsTaskWeights,
      isFalse,
    );
    expect(
      ChallengesFixtures.challenge(
        milestones: [m1, m4.copyWith(weight: 30)],
      ).showsTaskWeights,
      isTrue,
    );
  });

  testWidgets('la tarea siguiente se marca y el peso solo si es manual', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MilestoneTile(
          milestone: m3,
          dependencyTitles: const [],
          busy: false,
          isNext: true,
        ),
      ),
    );
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Vale 50 %'), findsNothing);

    await tester.pumpWidget(
      _wrap(
        MilestoneTile(
          milestone: m3,
          dependencyTitles: const [],
          busy: false,
          showWeight: true,
        ),
      ),
    );
    expect(find.text('Siguiente'), findsNothing);
    expect(find.text('Vale 50 %'), findsOneWidget);
  });

  testWidgets('el grafo dibuja un nodo por tarea en tema oscuro', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(DependencyGraph(milestones: [m1, m2, m3]), theme: AppTheme.dark),
    );
    expect(find.text('Tarea m3'), findsOneWidget);
    expect(DependencyGraph.depths([m1, m2, m3]), {'m1': 0, 'm2': 1, 'm3': 2});
    expect(tester.takeException(), isNull);
  });

  testWidgets('una tarea bloqueada no se puede completar', (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      _wrap(
        MilestoneTile(
          milestone: m2,
          dependencyTitles: const ['Tarea m1'],
          busy: false,
          onToggle: () => toggled = true,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.lock_outline_rounded).first);
    expect(toggled, isFalse);
    expect(find.text('Depende de: Tarea m1'), findsOneWidget);
  });
}
