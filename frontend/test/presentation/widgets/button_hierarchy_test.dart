import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// Jerarquía de botones (ADR 0065): ningún botón es texto de color suelto,
/// borrar va en rojo con borde y los elementos de una tira o lista son nodos
/// propios para el lector (no se funden con su padre).
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
  }) async {
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
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('TextButton del tema', () {
    for (final (name, theme) in [
      ('claro', AppTheme.light),
      ('oscuro', AppTheme.dark),
    ]) {
      test('lleva contorno visible en el tema $name', () {
        final side = theme.textButtonTheme.style!.side!.resolve({});
        expect(side, isNotNull);
        expect(side!.style, BorderStyle.solid);
        expect(side.width, greaterThan(0));
        expect(side.color.a, greaterThan(0));
        // Con el foco, el anillo común (más grueso) sustituye al contorno.
        final focused = theme.textButtonTheme.style!.side!.resolve({
          WidgetState.focused,
        });
        expect(focused!.width, greaterThan(side.width));
      });

      test('«Otra opción» lleva fondo de superficie en el tema $name', () {
        // Como `.btn-o` de la maqueta: sobre una tarjeta tintada sigue
        // pareciendo un botón (el contraste del borde, en contrast_test).
        final surface = theme.colorScheme.surface;
        for (final style in [
          theme.textButtonTheme.style!,
          theme.outlinedButtonTheme.style!,
        ]) {
          expect(style.backgroundColor!.resolve({}), surface);
          expect(
            style.foregroundColor!.resolve({}),
            theme.colorScheme.onSurface,
          );
        }
      });

      test('con el texto partido, rectángulo redondeado y no un óvalo', () {
        for (final style in [
          theme.filledButtonTheme.style!,
          theme.outlinedButtonTheme.style!,
          theme.textButtonTheme.style!,
        ]) {
          expect(style.shape!.resolve({}), isA<RoundedRectangleBorder>());
        }
      });
    }

    testWidgets('la acción de un aviso no hereda el contorno', (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Eliminado'),
                action: SnackBarAction(label: 'Deshacer', onPressed: () {}),
              ),
            ),
            child: const Text('Avisar'),
          ),
        ),
      );
      await tester.tap(find.text('Avisar'));
      await tester.pumpAndSettle();
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Deshacer'),
      );
      final context = tester.element(find.text('Deshacer'));
      final themed = TextButtonTheme.of(context).style?.side?.resolve({});
      expect(button.style?.side?.resolve({}), isNull);
      expect(themed, isNull);
    });
  });

  group('AppDangerButton', () {
    testWidgets('texto y borde rojos, y se pulsa', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppDangerButton(label: 'Eliminar', onPressed: () => taps++),
      );
      final error = AppTheme.light.colorScheme.error;
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.style!.foregroundColor!.resolve({}), error);
      expect(button.style!.side!.resolve({})!.color, error);
      expect(find.byIcon(AppIcons.delete), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      expect(taps, 1);
    });

    testWidgets('desactivado, el borde deja de ser rojo', (tester) async {
      await pump(
        tester,
        const AppDangerButton(label: 'Eliminar', onPressed: null),
      );
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(
        button.style!.side!.resolve({WidgetState.disabled})!.color,
        AppTheme.light.colorScheme.outlineVariant,
      );
    });
  });

  group('nodos propios para el lector', () {
    testWidgets('el primer día de una tira no se funde con el padre', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final tapped = <int>[];
      await pump(
        tester,
        Semantics(
          label: 'Esta semana',
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: AppDayChip(
                    caption: 'd$i',
                    dayNumber: 16 + i,
                    selected: i == 1,
                    semanticLabel: 'Día ${16 + i}',
                    onTap: () => tapped.add(i),
                  ),
                ),
            ],
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        final node = tester.getSemantics(find.byType(AppDayChip).at(i));
        // Solo su nombre: si se fundiera, llevaría también «Esta semana».
        expect(node.label, 'Día ${16 + i}');
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      }
      tester.semantics.tap(find.semantics.byLabel('Día 16'));
      expect(tapped, [0]);
      handle.dispose();
    });

    testWidgets('cada tarjetita es su propio botón', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pump(
        tester,
        Semantics(
          label: 'Accesos',
          child: SizedBox(
            width: 360,
            child: AppShortcutGrid(
              tiles: [
                AppShortcutTile(
                  icon: AppIcons.friends,
                  label: 'Amigos',
                  onTap: () => taps++,
                ),
                AppShortcutTile(
                  icon: AppIcons.settings,
                  label: 'Ajustes',
                  tone: AppTileTone.neutral,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final first = tester.getSemantics(find.byType(AppShortcutTile).first);
      expect(first.label, 'Amigos');
      tester.semantics.tap(find.semantics.byLabel('Amigos'));
      expect(taps, 1);
      handle.dispose();
    });
  });

  testWidgets('el cuadradito neutro no usa el color principal', (tester) async {
    await pump(
      tester,
      const Row(
        children: [
          AppTintedIcon(icon: AppIcons.settings, tone: AppTileTone.neutral),
          AppTintedIcon(icon: AppIcons.subject, tone: AppTileTone.tertiary),
        ],
      ),
    );
    final colors = AppTheme.light.colorScheme;
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons[0].color, colors.onSurface);
    expect(icons[1].color, colors.onTertiaryContainer);
  });
}
