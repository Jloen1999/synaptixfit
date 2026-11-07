import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/page/clock_intro_sheet.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Fallo 7: con «No volver a explicarlo» marcado, cerrar la explicación del
/// cronómetro de cualquier forma (botones o «atrás» del móvil) debe recordar
/// la casilla; si no, al pausar, salir y volver se explicaba otra vez.
void main() {
  Future<Future<(bool, bool)>> open(WidgetTester tester) async {
    late BuildContext ctx;
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
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final result = showClockIntroSheet(ctx, minutes: 40);
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('«atrás» del móvil con la casilla marcada la recuerda', (
    tester,
  ) async {
    final result = await open(tester);
    await tester.tap(find.text('No volver a explicarlo'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await result, (true, true));
  });

  testWidgets('«Ahora no: pausar y salir» con la casilla la recuerda', (
    tester,
  ) async {
    final result = await open(tester);
    await tester.tap(find.text('No volver a explicarlo'));
    await tester.pump();
    await tester.tap(find.text('Ahora no: pausar y salir'));
    await tester.pumpAndSettle();
    expect(await result, (false, true));
  });

  testWidgets('sin marcar la casilla se vuelve a explicar', (tester) async {
    final result = await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await result, (true, false));
  });
}
