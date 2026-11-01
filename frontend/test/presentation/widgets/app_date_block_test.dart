import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget Function(BuildContext context) builder, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 800);
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
        body: Center(child: Builder(builder: builder)),
      ),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final now = DateTime(2026, 11, 2, 10);

  group('AppDueDates', () {
    test('cuenta días naturales y marca como pronto solo hoy y mañana', () {
      expect(AppDueDates.daysUntil(DateTime(2026, 11, 2, 23), now), 0);
      expect(AppDueDates.daysUntil(DateTime(2026, 11, 3, 1), now), 1);
      expect(AppDueDates.daysUntil(DateTime(2026, 11, 1), now), -1);
      expect(AppDueDates.isSoon(DateTime(2026, 11, 3), now), isTrue);
      expect(AppDueDates.isSoon(DateTime(2026, 11, 4), now), isFalse);
      // Lo vencido ya no urge igual.
      expect(AppDueDates.isSoon(DateTime(2026, 11, 1), now), isFalse);
    });

    testWidgets('dice cuándo vence en palabras', (tester) async {
      final texts = <String>[];
      await _pump(tester, (context) {
        texts
          ..clear()
          ..addAll([
            AppDueDates.text(context, DateTime(2026, 11, 2, 20), now),
            AppDueDates.text(context, DateTime(2026, 11, 3), now),
            AppDueDates.text(context, DateTime(2026, 11, 5), now),
            AppDueDates.text(context, DateTime(2026, 10, 30), now),
            // Vencía hoy a las 9 y el servidor ya la da por vencida.
            AppDueDates.text(
              context,
              DateTime(2026, 11, 2, 9),
              now,
              overdue: true,
            ),
          ]);
        return const SizedBox();
      });
      expect(texts[0], 'Vence hoy');
      expect(texts[1], 'Vence mañana');
      expect(texts[2], 'Vence en 3 días');
      expect(texts[3], startsWith('Venció el 30'));
      expect(texts[4], startsWith('Venció el 2'));
    });
  });

  group('AppDateBlock', () {
    testWidgets('«Hoy · 2» y fecha con día, a 200 % sin desbordes', (
      tester,
    ) async {
      await _pump(
        tester,
        (context) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDateBlock.due(
              context,
              due: DateTime(2026, 11, 2, 23),
              now: now,
              color: Colors.orange,
            ),
            AppDateBlock.due(
              context,
              due: DateTime(2026, 11, 10),
              now: now,
              color: Colors.purple,
            ),
          ],
        ),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      // La cifra es siempre el día; «Hoy» va en la etiqueta de arriba.
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('compacto: una sola línea', (tester) async {
      await _pump(
        tester,
        (context) => AppDateBlock.due(
          context,
          due: DateTime(2026, 11, 3),
          now: now,
          color: Colors.orange,
          compact: true,
        ),
        scale: 2,
      );
      expect(find.text('Mañana · 3 · nov'), findsOneWidget);
    });
  });

  group('AppCardTapArea', () {
    testWidgets('se anuncia como un botón con su contenido', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await _pump(
        tester,
        (_) => AppCardTapArea(
          onTap: () => taps++,
          child: const Column(children: [Text('Título'), Text('Detalle')]),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AppCardTapArea)),
        matchesSemantics(
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: 'Título\nDetalle',
        ),
      );
      await tester.tap(find.text('Título'));
      expect(taps, 1);
      handle.dispose();
    });
  });
}
