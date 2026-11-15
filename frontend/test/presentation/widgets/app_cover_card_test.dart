import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/theme/tokens.g.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

const _url = 'https://example.com/foto.webp';
const _cardWidth = 320.0;

Future<void> _pump(
  WidgetTester tester, {
  double scale = 1,
  AppCoverLayout layout = AppCoverLayout.side,
  String? url = _url,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: app!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _cardWidth,
            child: AppCoverCard(
              imageUrl: url,
              layout: layout,
              padding: EdgeInsets.zero,
              footer: const SizedBox(height: 48, key: Key('pie')),
              child: const Text('Fuerza A', key: Key('texto')),
            ),
          ),
        ),
      ),
    ),
  );
}

/// La foto de las tarjetas se ve tal cual en el lado final y el texto queda en
/// la zona lisa (AA con cualquier foto); con texto grande vuelve el fondo a
/// dos tonos, que también cumple AA (contrast_test).
void main() {
  testWidgets('con texto normal el texto no pisa la foto', (tester) async {
    await _pump(tester);
    final text = tester.getRect(find.byKey(const Key('texto')));
    final card = tester.getRect(find.byType(AppCoverCard));
    final photoStart = card.right - _cardWidth * TokensLayout.coverPhotoShare;
    expect(text.right, lessThanOrEqualTo(photoStart + 0.5));
    // El pie (botones, progreso) usa el ancho entero y va debajo de la foto.
    final footer = tester.getRect(find.byKey(const Key('pie')));
    expect(footer.width, closeTo(_cardWidth, 0.5));
    expect(footer.top, greaterThanOrEqualTo(text.bottom));
    // La foto ya no lleva el filtro a dos tonos.
    final decorated = tester
        .widgetList<Ink>(find.byType(Ink))
        .map((i) => i.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.image != null);
    expect(decorated, hasLength(1));
    expect(decorated.single.image!.colorFilter, isNull);
  });

  testWidgets('con texto grande usa el ancho entero y el fondo a dos tonos', (
    tester,
  ) async {
    await _pump(tester, scale: 2);
    final decorated = tester
        .widgetList<Ink>(find.byType(Ink))
        .map((i) => i.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.image != null);
    expect(decorated.single.image!.colorFilter, isNotNull);
  });

  group('texto abajo (sesiones, ADR 0042)', () {
    testWidgets('la foto a dos tonos queda arriba y el texto abajo', (
      tester,
    ) async {
      await _pump(tester, layout: AppCoverLayout.bottom);
      final text = tester.getRect(find.byKey(const Key('texto')));
      final card = tester.getRect(find.byType(AppCoverCard));
      // La franja de la foto queda a la vista encima del texto.
      expect(text.top - card.top, greaterThanOrEqualTo(TokensSize.coverBanner));
      final footer = tester.getRect(find.byKey(const Key('pie')));
      expect(footer.top, greaterThanOrEqualTo(text.bottom));
      expect(footer.width, closeTo(_cardWidth, 0.5));
      final photo = tester
          .widgetList<Ink>(find.byType(Ink))
          .map((i) => i.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.image != null)
          .single;
      // A dos tonos: el texto cumple AA en cualquier punto (contrast_test).
      expect(photo.image!.colorFilter, isNotNull);
      // Mientras carga o si falla, debajo queda el color de reserva.
      expect(photo.gradient, isNotNull);
      // Degradado vertical de tres paradas hacia la superficie.
      final gradient = tester
          .widgetList<Ink>(find.byType(Ink))
          .map((i) => i.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.image == null)
          .map((d) => d.gradient)
          .whereType<LinearGradient>()
          .single;
      expect(gradient.colors, hasLength(3));
    });

    testWidgets('con el texto al 200 % no se desborda', (tester) async {
      await _pump(tester, layout: AppCoverLayout.bottom, scale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Fuerza A'), findsOneWidget);
    });

    testWidgets('sin foto queda el color de reserva, en claro y oscuro', (
      tester,
    ) async {
      for (final dark in [false, true]) {
        await _pump(
          tester,
          layout: AppCoverLayout.bottom,
          url: null,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        final images = tester
            .widgetList<Ink>(find.byType(Ink))
            .map((i) => i.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.image != null);
        expect(images, isEmpty);
        expect(find.text('Fuerza A'), findsOneWidget);
      }
    });
  });
}
