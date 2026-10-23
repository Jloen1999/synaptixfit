import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/app_focus_outline.dart';

/// El foco del teclado en la barra inferior y en el riel se ve como un anillo
/// (`AppNavFocusRing`) y solo en el destino enfocado (WCAG 2.4.7).
void main() {
  const ring = ValueKey('app-nav-focus-ring');

  Future<void> pump(WidgetTester tester, Widget navigation) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: Center(child: navigation)),
        ),
      );

  testWidgets('barra inferior: anillo en el destino con foco', (tester) async {
    await pump(
      tester,
      NavigationBar(
        selectedIndex: 0,
        destinations: [
          for (final icon in [Icons.home_outlined, Icons.flag_outlined])
            NavigationDestination(
              icon: AppNavFocusRing(child: Icon(icon)),
              label: '$icon',
            ),
        ],
      ),
    );
    expect(find.byKey(ring), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(ring), findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(find.byKey(ring)).decoration
            as ShapeDecoration;
    expect(
      (decoration.shape as StadiumBorder).side.color,
      AppTheme.dark.colorScheme.onSurface,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(ring), findsOneWidget);
  });

  testWidgets('riel: anillo en el destino con foco', (tester) async {
    await pump(
      tester,
      SizedBox(
        height: 400,
        child: NavigationRail(
          selectedIndex: 0,
          destinations: [
            for (final icon in [Icons.home_outlined, Icons.flag_outlined])
              NavigationRailDestination(
                icon: AppNavFocusRing(rail: true, child: Icon(icon)),
                label: Text('$icon'),
              ),
          ],
        ),
      ),
    );
    expect(find.byKey(ring), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(ring), findsOneWidget);
  });
}
