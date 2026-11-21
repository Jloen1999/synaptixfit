import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// `AppShortcutTile` (ADR 0061): la tarjetita de acceso de Tú › Retos,
/// Tú › Comunidad y el Perfil.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
    double textScale = 1,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  Widget grid(VoidCallback onTap) => AppShortcutGrid(
    tiles: [
      AppShortcutTile(
        icon: AppIcons.friends,
        label: 'Amigos',
        detail: 'Publicaciones',
        badgeCount: 2,
        onTap: onTap,
      ),
      AppShortcutTile(
        icon: AppIcons.add,
        label: 'Nuevo',
        semanticsLabel: 'Nuevo reto',
        emphasized: true,
        onTap: onTap,
      ),
      AppShortcutTile(icon: AppIcons.settings, label: 'Ajustes', onTap: onTap),
    ],
  );

  testWidgets('se lee como un botón con nombre y detalle, y se toca', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await pump(tester, grid(() => taps++));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Amigos, Publicaciones')),
      isSemantics(isButton: true, hasTapAction: true, isEnabled: true),
    );
    // El nombre para el lector contiene el texto visible (WCAG 2.5.3).
    expect(find.bySemanticsLabel('Nuevo reto'), findsOneWidget);
    // El globo enseña el número; el lector ya lo oye en el detalle.
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('tamaño táctil, etiquetas y contraste en claro y oscuro', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await pump(tester, grid(() {}), theme: theme);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
    semantics.dispose();
  });

  testWidgets('al 200 % las tarjetitas bajan de fila y no se cortan', (
    tester,
  ) async {
    await pump(tester, grid(() {}), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Ajustes')).dy,
      greaterThan(tester.getTopLeft(find.text('Amigos')).dy),
    );
  });

  testWidgets('a 320 px (1,0 · 1,2 · 2,0) ninguna palabra se parte', (
    tester,
  ) async {
    for (final scale in [1.0, 1.2, 2.0]) {
      await pump(tester, grid(() {}), width: 320, textScale: scale);
      expect(tester.takeException(), isNull, reason: '$scale');
      for (final word in ['Publicaciones', 'Amigos', 'Ajustes', 'Nuevo']) {
        expectWordNotSplit(tester, find.text(word));
      }
    }
  });

  testWidgets('más de 99: «99+»', (tester) async {
    await pump(
      tester,
      AppShortcutGrid(
        tiles: [
          AppShortcutTile(
            icon: AppIcons.friends,
            label: 'Amigos',
            badgeCount: 120,
            onTap: () {},
          ),
        ],
      ),
    );
    expect(find.text('99+'), findsOneWidget);
  });
}

/// El texto se ve entero: cabe en su caja sin cortarse ni difuminarse.
void expectWhole(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  expect(
    paragraph.size.width + 0.5,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
    reason: 'cortado: ${paragraph.text.toPlainText()}',
  );
}

/// Ninguna palabra se parte en dos líneas: una palabra sola cabe entera en
/// el ancho de su caja.
void expectWordNotSplit(WidgetTester tester, Finder text) =>
    expectWhole(tester, text);
