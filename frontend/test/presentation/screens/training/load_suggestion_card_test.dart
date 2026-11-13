import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/training/load_suggestion.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/page/live_focus_view.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// «Hoy prueba 42,5 kg (+6 %)»: una línea con la propuesta, que ya va en las
/// cifras de las series; el porqué, en un «?» opcional.
void main() {
  const up = LoadSuggestion(
    plannedExerciseId: 'p1',
    metric: LoadMetric.weight,
    previous: 40,
    suggested: 42.5,
    changePercent: 6,
    reason: AdjustmentReason.lowRpeMoreWeight,
    lastRpe: 6,
  );

  Future<void> pump(
    WidgetTester tester,
    LoadSuggestion s, {
    double scale = 1,
  }) async {
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoadSuggestionLine(suggestion: s),
          ),
        ),
      ),
    );
  }

  testWidgets('una línea con la cifra; el porqué solo al tocar «?»', (
    tester,
  ) async {
    await pump(tester, up);

    expect(find.text('Hoy prueba 42,5 kg (+6 %)'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('un 6 por ciento más')),
      findsOneWidget,
    );
    // Nada que aceptar ni explicaciones a la vista.
    expect(find.textContaining('la última vez hiciste 40 kg'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);

    await tester.tap(find.byTooltip('Por qué esta propuesta'));
    await tester.pump();
    expect(find.textContaining('la última vez hiciste 40 kg'), findsOneWidget);
    expect(find.textContaining('tu rutina sigue igual'), findsOneWidget);
  });

  testWidgets('tras fallos propone bajar; en repeticiones no da porcentaje', (
    tester,
  ) async {
    await pump(
      tester,
      const LoadSuggestion(
        plannedExerciseId: 'p1',
        metric: LoadMetric.weight,
        previous: 40,
        suggested: 36,
        changePercent: -10,
        reason: AdjustmentReason.failedReps,
        lastRpe: 8,
      ),
    );
    expect(find.text('Hoy baja a 36 kg (−10 %)'), findsOneWidget);

    await pump(
      tester,
      const LoadSuggestion(
        plannedExerciseId: 'p1',
        metric: LoadMetric.reps,
        previous: 10,
        suggested: 11,
        changePercent: 10,
        reason: AdjustmentReason.lowRpeMoreReps,
        lastRpe: 7,
      ),
    );
    expect(find.text('Hoy prueba 11 repeticiones'), findsOneWidget);
  });

  testWidgets('cabe con el texto al 200 % en 320 dp', (tester) async {
    await pump(tester, up, scale: 2);
    await tester.tap(find.byTooltip('Por qué esta propuesta'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
