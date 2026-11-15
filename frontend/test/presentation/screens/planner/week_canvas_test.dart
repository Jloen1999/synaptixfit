import 'dart:ui' show Tristate;

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

  group('a 360 px (ADR 0050)', () {
    const phone = Size(360, 800);

    testWidgets('la tira lleva a los 7 días y marca el que se ve', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, blocks: const [], size: phone);

      const labels = [
        'Lunes 13',
        'Martes 14',
        'Hoy, miércoles 15',
        'Jueves 16',
        'Viernes 17',
        'Sábado 18',
        'Domingo 19',
      ];
      const headers = [
        'lun 13',
        'mar 14',
        'mié 15',
        'jue 16',
        'vie 17',
        'sáb 18',
        'dom 19',
      ];
      // Abre en hoy, marcado.
      bool selected(String label) =>
          tester
              .getSemantics(find.bySemanticsLabel(label))
              .flagsCollection
              .isSelected ==
          Tristate.isTrue;
      expect(selected(labels[2]), isTrue);
      // Cada día llega a la zona de toque de 48 dp, también a 360.
      for (final label in labels) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
      for (final (i, label) in labels.indexed) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pumpAndSettle();
        final header = tester.getRect(find.text(headers[i]));
        expect(
          header.left >= WeekCanvas.axisWidth && header.right <= phone.width,
          isTrue,
          reason: '$label se ve tras tocarlo',
        );
        expect(selected(label), isTrue);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('un evento a las 2:00 se ve al subir', (tester) async {
      await pump(
        tester,
        blocks: [block(start: DateTime(2025, 10, 15, 2))],
        size: phone,
      );
      final title = find.text('Cálculo');
      // Se abre una hora antes de ahora (10:00): la madrugada queda arriba.
      expect(title.hitTestable(), findsNothing);

      await tester.scrollUntilVisible(
        title,
        -200,
        scrollable: find.byWidgetPredicate(
          (w) =>
              w is Scrollable &&
              w.axisDirection == AxisDirection.down &&
              w.physics is! NeverScrollableScrollPhysics,
        ),
      );
      await tester.pumpAndSettle();
      expect(title.hitTestable(), findsOneWidget);
    });

    testWidgets('lo que cruza la medianoche se pinta en sus dos días', (
      tester,
    ) async {
      await pump(
        tester,
        blocks: [block(start: DateTime(2025, 10, 15, 23), minutes: 120)],
        size: const Size(1400, 900),
      );
      expect(find.byType(TimeBlockTile), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
