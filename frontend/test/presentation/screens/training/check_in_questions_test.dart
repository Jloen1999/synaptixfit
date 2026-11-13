import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/check_in_questions.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// «¿Qué tal estás hoy?» (ADR 0039): todas las respuestas con lo mejor a la
/// derecha, guardando las escalas 1-5 de siempre.
void main() {
  Future<Map<String, int>> pump(
    WidgetTester tester, {
    int? sleep,
    int? energy,
    int? soreness,
  }) async {
    final answers = <String, int>{};
    tester.view.physicalSize = const Size(400, 1200);
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
        home: Scaffold(
          body: CheckInQuestions(
            sleep: sleep,
            energy: energy,
            soreness: soreness,
            onSleep: (v) => answers['sleep'] = v,
            onEnergy: (v) => answers['energy'] = v,
            onSoreness: (v) => answers['soreness'] = v,
          ),
        ),
      ),
    );
    return answers;
  }

  double x(WidgetTester tester, String label) =>
      tester.getCenter(find.widgetWithText(ChoiceChip, label)).dx;

  testWidgets('lo mejor va siempre a la derecha', (tester) async {
    await pump(tester);

    expect(x(tester, 'Mal'), lessThan(x(tester, 'Regular')));
    expect(x(tester, 'Regular'), lessThan(x(tester, 'Bien')));
    expect(x(tester, 'Baja'), lessThan(x(tester, 'Alta')));
    expect(x(tester, 'Muchas'), lessThan(x(tester, 'Algo')));
    expect(x(tester, 'Algo'), lessThan(x(tester, 'Nada')));
  });

  testWidgets('se guarda en la escala de siempre: agujetas «Nada» = 1', (
    tester,
  ) async {
    final answers = await pump(tester);

    await tester.tap(find.text('Bien'));
    await tester.tap(find.text('Nada'));
    await tester.tap(find.text('Muchas'));

    expect(answers['sleep'], 5);
    expect(answers['soreness'], 5, reason: 'el último toque fue «Muchas»');
  });

  testWidgets('un registro antiguo con 2 o 4 marca la respuesta cercana', (
    tester,
  ) async {
    await pump(tester, sleep: 4, energy: 2, soreness: 3);

    ChoiceChip chip(String label) =>
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
    expect(chip('Bien').selected, isTrue);
    expect(chip('Baja').selected, isTrue);
    expect(chip('Algo').selected, isTrue);
  });

  test('el historial dice la respuesta en palabras', () {
    final options = [(1, 'Mal'), (3, 'Regular'), (5, 'Bien')];
    expect(CheckInQuestions.answer(options, 4), 'Bien');
    expect(CheckInQuestions.answer(options, 2), 'Mal');
  });
}
