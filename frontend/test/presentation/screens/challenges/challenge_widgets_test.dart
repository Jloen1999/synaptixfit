import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/challenge_type.dart';
import 'package:synaptixfit/domain/enums/milestone_status.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/challenges/widgets/challenge_card.dart';
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
    // El contador lleva su propio icono para no repetir el del tipo.
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
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
