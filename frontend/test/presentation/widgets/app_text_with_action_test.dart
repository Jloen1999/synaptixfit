import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// `AppTextWithAction` (ADR 0065): el botón va al lado del texto si caben
/// los dos; a 320 px con el texto al 200 % baja a su propia línea (WCAG
/// 1.4.10). Lo usan la ficha del calendario, «Lo próximo» de la asignatura y
/// la barra de la sesión libre.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double width,
    required double scale,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextWithAction(
              actionLabel: 'Terminar',
              actionIcon: true,
              action: TextButton.icon(
                onPressed: () {},
                icon: const Icon(AppIcons.finish),
                label: const Text('Terminar'),
              ),
              child: const Text('3 series apuntadas'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('con sitio, el botón va al lado del texto', (tester) async {
    await pump(tester, width: 390, scale: 1);
    final text = tester.getRect(find.text('3 series apuntadas'));
    final button = tester.getRect(find.text('Terminar'));
    expect(button.left, greaterThan(text.right));
    expect((button.center.dy - text.center.dy).abs(), lessThan(24));
  });

  testWidgets('a 320 px y texto al 200 % el botón baja, sin desbordes', (
    tester,
  ) async {
    await pump(tester, width: 320, scale: 2);
    expect(tester.takeException(), isNull);
    final text = tester.getRect(find.text('3 series apuntadas'));
    final button = tester.getRect(find.text('Terminar'));
    expect(button.top, greaterThanOrEqualTo(text.bottom));
    // El botón cabe en una línea: su texto mide lo que pediría sin límite.
    final label = tester.renderObject<RenderParagraph>(find.text('Terminar'));
    expect(
      label.size.width + 0.5,
      greaterThanOrEqualTo(label.getMaxIntrinsicWidth(double.infinity)),
    );
  });
}
