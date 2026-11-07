import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/agenda_section.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/today_hero_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'home_fixtures.dart';

HomeTodayEvent _block(
  String id,
  HomeEventType type,
  ItemTimeStatus status, {
  bool completed = false,
  int hour = 10,
}) => HomeTodayEvent(
  id: id,
  kind: HomeEventKind.block,
  type: type,
  title: 'Bloque $id',
  start: DateTime(2026, 10, 31, hour),
  end: DateTime(2026, 10, 31, hour + 1),
  completed: completed,
  status: status,
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<List<TodayHeroAction>> pump(
    WidgetTester tester,
    List<HomeTodayEvent> events, {
    double textScale = 1,
  }) async {
    final actions = <TodayHeroAction>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('es'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodayHeroCard(
              dashboard: homeDashboardFixture.copyWith(todayEvents: events),
              focus: UsageFocus.both,
              onAction: actions.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return actions;
  }

  test('lo siguiente es lo que está en curso; si no, lo próximo sin hacer', () {
    final next = TodayHeroCard.nextEvent([
      _block('1', HomeEventType.study, ItemTimeStatus.done, completed: true),
      _block('2', HomeEventType.study, ItemTimeStatus.missed, hour: 11),
      _block('3', HomeEventType.sport, ItemTimeStatus.upcoming, hour: 18),
      _block('4', HomeEventType.study, ItemTimeStatus.inProgress, hour: 12),
    ]);

    expect(next?.id, '4');
    expect(
      TodayHeroCard.nextEvent([
        _block('5', HomeEventType.study, ItemTimeStatus.missed),
      ]),
      isNull,
    );
  });

  testWidgets('un bloque de estudio en curso ofrece concentrarse', (
    tester,
  ) async {
    final actions = await pump(tester, [
      _block('1', HomeEventType.study, ItemTimeStatus.done, completed: true),
      _block('2', HomeEventType.study, ItemTimeStatus.inProgress, hour: 12),
    ]);

    expect(find.text('Ahora'), findsOneWidget);
    expect(find.text('Bloque 2'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Has hecho 1 de 2 eventos de hoy'),
      findsOneWidget,
    );
    await tester.tap(find.text('Concentrarme'));
    expect(actions, [TodayHeroAction.focus]);
  });

  testWidgets('sin nada planificado invita a planificar el día', (
    tester,
  ) async {
    final actions = await pump(tester, const []);

    expect(
      find.text('Aún no tienes nada planificado para hoy.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Planificar el día'));
    expect(actions, [TodayHeroAction.openPlanner]);
  });

  testWidgets('con todo hecho lo celebra', (tester) async {
    await pump(tester, [
      _block('1', HomeEventType.study, ItemTimeStatus.done, completed: true),
    ]);

    expect(find.textContaining('Has terminado lo de hoy'), findsOneWidget);
  });

  testWidgets('con el texto al 200 % el anillo y las cifras caben', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, [
      for (var i = 0; i < 12; i++)
        _block(
          '$i',
          HomeEventType.study,
          i < 10 ? ItemTimeStatus.done : ItemTimeStatus.upcoming,
          completed: i < 10,
          hour: 8 + i,
        ),
    ], textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('10/12'), findsOneWidget);
    // Lo que falta para subir, no «120 de 300».
    expect(find.text('180 XP para el nivel 4'), findsOneWidget);
  });

  test('los títulos en mayúsculas se leen como texto normal', () {
    expect(
      readableEventTitle('AMPLIACIÓN DE MATEMÁTICAS'),
      'Ampliación de matemáticas',
    );
    expect(readableEventTitle('Tema 3: Límites'), 'Tema 3: Límites');
    expect(readableEventTitle('TFG'), 'TFG');
  });
}
