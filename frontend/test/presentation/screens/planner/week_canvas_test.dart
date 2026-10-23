import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/planner/widgets/time_block_tile.dart';
import 'package:synaptixfit/presentation/screens/planner/widgets/week_canvas.dart';
import 'package:synaptixfit/presentation/theme/app_palette.dart';

import 'planner_fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  // Miércoles visible en el ancho de móvil.
  final wed11 = DateTime(2025, 10, 15, 11);

  Future<void> pump(
    WidgetTester tester, {
    required List<CalendarBlock> blocks,
    ValueChanged<DateTime>? onSlotTap,
    ValueChanged<CalendarBlock>? onBlockTap,
    void Function(CalendarBlock, DateTime, DateTime)? onReschedule,
    Size size = const Size(390, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
          body: WeekCanvas(
            weekStart: testMonday,
            blocks: blocks,
            titles: const {'b1': 'Cálculo'},
            busyIds: const {},
            now: testNow,
            onSlotTap: onSlotTap ?? (_) {},
            onBlockTap: onBlockTap ?? (_) {},
            onReschedule: onReschedule ?? (_, _, _) {},
            onLockedBlockTouched: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pinta los bloques de la semana en móvil y en web', (
    tester,
  ) async {
    final blocks = [
      block(),
      block(id: 'b2', start: DateTime(2025, 10, 16, 9, 30)),
      block(id: 'b3', start: DateTime(2025, 10, 19, 20), fixed: true),
    ];
    await pump(tester, blocks: blocks);
    expect(find.byType(TimeBlockTile), findsNWidgets(3));
    expect(find.text('Cálculo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pump(tester, blocks: blocks, size: const Size(1400, 900));
    expect(find.byType(TimeBlockTile), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar un bloque lo abre', (tester) async {
    CalendarBlock? tapped;
    await pump(
      tester,
      blocks: [block(start: wed11)],
      onBlockTap: (b) => tapped = b,
    );
    await tester.tap(find.text('Cálculo'));
    expect(tapped?.id, 'b1');
  });

  testWidgets('arrastrar un bloque con pulsación larga lo reprograma', (
    tester,
  ) async {
    DateTime? newStart;
    await pump(
      tester,
      blocks: [block(start: wed11)],
      onReschedule: (_, start, _) => newStart = start,
    );
    final center = tester.getCenter(find.text('Cálculo'));
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, WeekCanvas.hourHeight));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(newStart, DateTime(2025, 10, 15, 12));
  });
}
