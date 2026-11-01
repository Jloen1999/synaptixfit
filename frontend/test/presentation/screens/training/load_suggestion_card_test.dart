import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/training/load_suggestion.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/page/live_focus_view.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// «Hoy prueba 42 kg (+5 %)»: la propuesta dice la cifra, el porqué y que solo
/// cambia las series que faltan; se acepta y se deshace con un toque.
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
    bool accepted = false,
    double scale = 1,
    ValueChanged<bool>? onToggled,
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
            child: LoadSuggestionCard(
              suggestion: s,
              accepted: accepted,
              onToggled: onToggled ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('dice la cifra, el porqué y que la rutina no cambia', (
    tester,
  ) async {
    bool? toggled;
    await pump(tester, up, onToggled: (v) => toggled = v);

    expect(find.text('Hoy prueba 42,5 kg (+6 %)'), findsOneWidget);
    expect(find.textContaining('La última vez hiciste 40 kg'), findsOneWidget);
    expect(find.textContaining('RPE 6 de 10'), findsOneWidget);
    expect(find.textContaining('tu rutina sigue igual'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('un 6 por ciento más')),
      findsOneWidget,
    );

    await tester.tap(find.text('Usar en las series que faltan'));
    expect(toggled, isTrue);
  });

  testWidgets('aceptada, se puede deshacer', (tester) async {
    bool? toggled;
    await pump(tester, up, accepted: true, onToggled: (v) => toggled = v);

    expect(
      find.text('Listo: lo usarás en las series que te faltan.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Deshacer'));
    expect(toggled, isFalse);
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
    expect(find.textContaining('fallaste repeticiones'), findsOneWidget);

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
    expect(tester.takeException(), isNull);
  });
}
