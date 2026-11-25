import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/next_training_card.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/today_hero_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'home_fixtures.dart';

/// «Empezar» pesa lo mismo en «Tu día» y en «Próximo entreno» (revisión del
/// 25 nov, ADR 0059): relleno si es el único destacado de Inicio, tonal si
/// «Tu día» ya lleva el suyo; nunca con borde.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final now = DateTime.now();
  HomeTodayEvent event(HomeEventType type) => HomeTodayEvent(
    id: 'x1',
    kind: HomeEventKind.block,
    type: type,
    title: 'Bases de datos',
    start: DateTime(now.year, now.month, now.day, 17),
    end: DateTime(now.year, now.month, now.day, 18),
    completed: false,
  );
  HomeDashboard withSpotlight(HomeTodayEvent? spotlight) =>
      homeDashboardFixture.copyWith(
        todayEvents: [?spotlight],
        todaySummary: HomeTodaySummary(
          done: 0,
          total: spotlight == null ? 0 : 1,
          spotlightEventId: spotlight?.id,
          state: homeDashboardFixture.todaySummary.state,
        ),
      );

  group('¿«Tu día» lleva el botón relleno?', () {
    test('una clase sola no tiene botón: no', () {
      expect(
        TodayHeroCard.hasPrimaryAction(
          dashboard: withSpotlight(event(HomeEventType.classSession)),
          focus: UsageFocus.both,
        ),
        isFalse,
      );
    });

    test('un estudio lleva «Concentrarme»: sí', () {
      expect(
        TodayHeroCard.hasPrimaryAction(
          dashboard: withSpotlight(event(HomeEventType.study)),
          focus: UsageFocus.both,
        ),
        isTrue,
      );
    });

    test('el entreno de hoy lleva «Empezar»: sí', () {
      final dashboard = withSpotlight(event(HomeEventType.classSession))
          .copyWith(
            nextTrainingDay: homeDashboardFixture.nextTrainingDay!.copyWith(
              dueToday: true,
            ),
          );
      expect(
        TodayHeroCard.hasPrimaryAction(
          dashboard: dashboard,
          focus: UsageFocus.both,
        ),
        isTrue,
      );
    });

    test('sin nada que nombrar, «Añadir al calendario»: sí', () {
      expect(
        TodayHeroCard.hasPrimaryAction(
          dashboard: withSpotlight(null).copyWith(nextDeadline: null),
          focus: UsageFocus.both,
        ),
        isTrue,
      );
    });

    test('con la tarjeta «Sin terminar» arriba: no', () {
      expect(
        TodayHeroCard.hasPrimaryAction(
          dashboard: withSpotlight(event(HomeEventType.study)),
          focus: UsageFocus.both,
          primaryElsewhere: true,
        ),
        isFalse,
      );
    });
  });

  Future<void> pump(WidgetTester tester, {required bool startPrimary}) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: NextTrainingCard(
              day: homeDashboardFixture.nextTrainingDay!.copyWith(
                totalDays: 24,
              ),
              checkInDone: false,
              startPrimary: startPrimary,
              onStart: () {},
              onCheckIn: () {},
            ),
          ),
        ),
      ),
    );
  }

  Finder start() => find.ancestor(
    of: find.text('Empezar'),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );

  Color? fillOf(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(of: start(), matching: find.byType(Material)).first,
      )
      .color;

  testWidgets('sin destacado en «Tu día», «Empezar» es el relleno', (
    tester,
  ) async {
    await pump(tester, startPrimary: true);
    expect(start(), findsOneWidget);
    expect(tester.widget(start()), isA<FilledButton>());
    // Relleno de marca, no tonal.
    expect(
      fillOf(tester),
      Theme.of(tester.element(start())).colorScheme.primary,
    );
    // «¿Qué tal estás hoy?» sigue con borde; el ciclo, sin barra.
    expect(
      find.widgetWithText(OutlinedButton, '¿Qué tal estás hoy?'),
      findsOneWidget,
    );
    expect(find.text('0 de 24 días'), findsOneWidget);
  });

  testWidgets('con destacado en «Tu día», «Empezar» es tonal, no con borde', (
    tester,
  ) async {
    await pump(tester, startPrimary: false);
    expect(start(), findsOneWidget);
    expect(tester.widget(start()), isA<FilledButton>());
    expect(find.widgetWithText(OutlinedButton, 'Empezar'), findsNothing);
    expect(
      fillOf(tester),
      Theme.of(tester.element(start())).colorScheme.secondaryContainer,
    );
  });
}
