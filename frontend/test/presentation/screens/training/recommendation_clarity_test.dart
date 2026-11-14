import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/training/recommendation.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/bloc/live_session_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/recommendation_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'training_fixtures.dart';

/// Una sugerencia dice qué cambia (con cifras), por qué, cuándo se nota y qué
/// pasa si no se aplica; y la sesión dice cuánto queda.
void main() {
  const progression = Recommendation(
    id: 'r1',
    type: RecommendationType.progression,
    title: 'Considera aumentar la carga',
    applied: false,
    rpe: 6,
    reasonCode: AdjustmentReason.lowRpeMoreWeight,
    adjustments: [
      ExerciseAdjustment(
        exerciseName: 'Press banca',
        reasonCode: AdjustmentReason.lowRpeMoreWeight,
        before: ExerciseParameters(sets: 3, reps: 12, weightKg: 40),
        parameters: ExerciseParameters(sets: 3, reps: 8, weightKg: 42),
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, Widget child, double scale) async {
    tester.view.physicalSize = const Size(320, 900);
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('qué, por qué, cuándo y si no (320 dp, texto x$scale)', (
      tester,
    ) async {
      await pump(
        tester,
        RecommendationCard(
          recommendation: progression,
          busy: false,
          initiallyExpanded: true,
          onApply: () {},
          onDiscard: () {},
        ),
        scale,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Peso: 40 → 42 kg'), findsOneWidget);
      expect(find.text('Repeticiones: 12 → 8'), findsOneWidget);
      expect(find.textContaining('moderado (6 de 10)'), findsOneWidget);
      expect(find.textContaining('próxima vez que hagas este día'), findsOne);
      expect(find.textContaining('la quita y tu rutina sigue igual'), findsOne);
      expect(find.text('Ahora no'), findsOneWidget);
      expect(find.text('Aplicar'), findsOneWidget);
    });
  }

  test('quedan los minutos de las series sin apuntar', () {
    final bench = TrainingFixtures.planned('p1').copyWith(
      parameters: const ExerciseParameters(sets: 4),
      estimatedSeconds: 480,
    );
    final state = LiveSessionState(
      sessionId: 's1',
      session: TrainingFixtures.session(),
      exercises: [bench],
    );
    expect(state.remainingEstimatedMinutes, 8);
    expect(
      LiveSessionState(
        sessionId: 's1',
        exercises: [bench.copyWith(estimatedSeconds: null)],
      ).remainingEstimatedMinutes,
      isNull,
    );
  });
}
