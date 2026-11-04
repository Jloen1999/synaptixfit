import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

enum _Who { everyone, friends, me }

Widget _app({
  required double textScale,
  required ValueChanged<_Who> onChanged,
}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AppAdaptiveChoice<_Who>(
          values: _Who.values,
          selected: _Who.me,
          // Etiquetas largas, como en francés o portugués.
          labelOf: (w) => switch (w) {
            _Who.everyone => 'Toute la communauté',
            _Who.friends => 'Mes amis seulement',
            _Who.me => 'Seulement moi',
          },
          iconOf: (_) => Icons.public,
          enabledOf: (w) => w != _Who.everyone,
          disabledHint: 'Ton profil est privé',
          onChanged: onChanged,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('con texto normal y sitio se ve como botones segmentados', (
    tester,
  ) async {
    await tester.pumpWidget(_app(textScale: 1, onChanged: (_) {}));
    expect(find.byType(SegmentedButton<_Who>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'con texto grande pasa a una lista: nada se corta, se elige y lo bloqueado lo explica',
    (tester) async {
      _Who? chosen;
      await tester.pumpWidget(_app(textScale: 2, onChanged: (w) => chosen = w));
      expect(find.byType(SegmentedButton<_Who>), findsNothing);
      expect(find.byType(RadioListTile<_Who>), findsNWidgets(3));
      expect(find.text('Ton profil est privé'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Mes amis seulement'));
      await tester.pump();
      expect(chosen, _Who.friends);

      await tester.tap(find.text('Toute la communauté'));
      await tester.pump();
      expect(chosen, _Who.friends);
    },
  );
}
