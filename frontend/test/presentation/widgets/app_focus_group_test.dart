import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/widgets/app_focus_group.dart';
import 'package:synaptixfit/presentation/widgets/app_scroll_behavior.dart';

/// Orden de foco con teclado en maquetas de dos columnas (WCAG 2.4.3 y 2.4.11).
void main() {
  Widget button(String label, {double gapBefore = 0}) => Padding(
    padding: EdgeInsets.only(top: gapBefore),
    child: TextButton(onPressed: () {}, child: Text(label)),
  );

  String focusedLabel() {
    final context = FocusManager.instance.primaryFocus!.context!;
    final text = context.findAncestorWidgetOfExactType<TextButton>()?.child;
    return (text as Text?)?.data ??
        ((context.widget as dynamic).child as Text).data!;
  }

  Future<List<String>> tabs(WidgetTester tester, int n) async {
    final labels = <String>[];
    for (var i = 0; i < n; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      labels.add(focusedLabel());
    }
    return labels;
  }

  testWidgets('con un grupo por columna se recorre la izquierda y luego la '
      'derecha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppFocusGroup(
                  child: Column(
                    children: [button('A1'), button('A2', gapBefore: 300)],
                  ),
                ),
              ),
              Expanded(
                child: AppFocusGroup(
                  child: Column(
                    children: [button('B1'), button('B2', gapBefore: 100)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Sin grupos, el orden geométrico sería A1, B1, B2, A2.
    expect(await tabs(tester, 4), ['A1', 'A2', 'B1', 'B2']);
  });

  testWidgets('al pasar a la otra columna desplaza hacia arriba para que el '
      'foco se vea', (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFocusGroup(
            child: SingleChildScrollView(
              controller: scroll,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppFocusGroup(
                      child: Column(
                        children: [
                          button('A1'),
                          button('A2', gapBefore: 500),
                          button('A3', gapBefore: 500),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: AppFocusGroup(child: button('B1'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(await tabs(tester, 3), ['A1', 'A2', 'A3']);
    expect(scroll.offset, greaterThan(500));

    expect(await tabs(tester, 1), ['B1']);
    final rect = tester.getRect(find.text('B1'));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(400));
  });

  testWidgets('con AppScrollBehavior la lista desplazada va entre la barra '
      'superior y el pie fijo', (tester) async {
    tester.view.physicalSize = const Size(800, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) => AppFocusGroup(child: child!),
        home: Scaffold(
          appBar: AppBar(
            actions: [TextButton(onPressed: () {}, child: const Text('Barra'))],
          ),
          body: ListView(
            children: [
              for (var i = 1; i <= 8; i++) button('L$i', gapBefore: 60),
            ],
          ),
          bottomNavigationBar: button('Pie'),
        ),
      ),
    );

    // Recorre la lista entera: el pie no se cuela entre sus elementos aunque
    // los últimos queden por debajo del borde.
    final first = await tabs(tester, 10);
    expect(first, ['Barra', for (var i = 1; i <= 8; i++) 'L$i', 'Pie']);
    // Al dar la vuelta vuelve a la barra, no al primer elemento desplazado.
    expect(await tabs(tester, 1), ['Barra']);
  });
}
