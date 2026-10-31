import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

void main() {
  for (final (name, theme) in [
    ('claro', AppTheme.light),
    ('oscuro', AppTheme.dark),
  ]) {
    for (final tone in AppMessageTone.values) {
      testWidgets('$name, ${tone.name}: contraste y región viva', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: AppInlineMessage(
                  message: 'Ya puedes iniciar sesión con tu contraseña nueva.',
                  tone: tone,
                ),
              ),
            ),
          ),
        );

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(
          tester.getSemantics(find.byType(Text)),
          matchesSemantics(
            isLiveRegion: true,
            label: 'Ya puedes iniciar sesión con tu contraseña nueva.',
          ),
        );
        semantics.dispose();
      });
    }
  }
}
