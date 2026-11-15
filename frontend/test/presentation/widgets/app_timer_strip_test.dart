import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/app_timer_strip.dart';

/// Franja de temporizador (Pomodoro y sala «Estudiar juntos»): un solo botón
/// para el lector, con su etiqueta y su toque; el botón de pausa, aparte.
void main() {
  testWidgets('la franja es un botón con nombre y toque; pausar va aparte', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var opened = 0;
    var paused = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppTimerStrip(
            color: Colors.purple,
            icon: Icons.timer_outlined,
            label: 'Concentración · ronda 1 de 2',
            clock: '12:34',
            semanticLabel: 'Estudiar juntos, Concentración: quedan 12:34',
            onTap: () => opened++,
            trailing: IconButton(
              tooltip: 'Pausar',
              onPressed: () => paused++,
              icon: const Icon(Icons.pause),
            ),
          ),
        ),
      ),
    );

    final strip = find.bySemanticsLabel(
      'Estudiar juntos, Concentración: quedan 12:34',
    );
    expect(
      tester.getSemantics(strip),
      matchesSemantics(
        label: 'Estudiar juntos, Concentración: quedan 12:34',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await tester.tap(strip);
    await tester.tap(find.byTooltip('Pausar'));
    expect(opened, 1);
    expect(paused, 1);
    handle.dispose();
  });
}
