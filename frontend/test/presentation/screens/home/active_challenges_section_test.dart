import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/active_challenges_section.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final now = DateTime(2026, 11, 2, 10);

  Future<void> pump(WidgetTester tester, {required double scale}) async {
    tester.view.physicalSize = const Size(360, 1600);
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
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: app!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActiveChallengesSection(
              now: now,
              challenges: [
                HomeChallenge(
                  id: 'c1',
                  title: 'Repasar Física cada día',
                  academic: true,
                  endsAt: DateTime(2026, 11, 3, 23),
                  progress: 40,
                  currentStreak: 2,
                ),
                const HomeChallenge(
                  id: 'c2',
                  title: 'Correr 20 km',
                  academic: false,
                  progress: 75,
                  currentStreak: 0,
                ),
              ],
              onOpen: (_) {},
              onSeeAll: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('cada reto dice primero cuándo termina y cuánto lleva', (
    tester,
  ) async {
    await pump(tester, scale: 1);
    expect(tester.takeException(), isNull);
    expect(find.text('Termina mañana'), findsOneWidget);
    expect(find.text('Mañana'), findsOneWidget);
    expect(find.text('40 %'), findsOneWidget);
    // Sin fecha de fin, el bloque muestra el tipo.
    expect(find.text('Reto físico'), findsWidgets);
  });

  testWidgets('a 360 dp y texto al 200 %, sin desbordes', (tester) async {
    await pump(tester, scale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Repasar Física cada día'), findsOneWidget);
  });
}
