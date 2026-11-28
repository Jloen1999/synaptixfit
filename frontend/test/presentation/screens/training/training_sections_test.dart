import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptixfit/presentation/extensions/context_extensions.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/training_routes.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/training_section_bar.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Pestaña Entreno con apartados «Gimnasio | Deportes | WOD» (ADR 0037 y 0069): cada uno
/// tiene su enlace en `/training`, se cambia con `go` (sin apilar) y los
/// enlaces de siempre a rutinas no cambian.
void main() {
  test('rutas de los apartados, de Correr y de las rutinas', () {
    expect(TrainingPaths.section(TrainingSection.gym), '/training');
    expect(TrainingPaths.section(TrainingSection.run), '/training?section=run');
    expect(TrainingSection.fromQuery('run'), TrainingSection.run);
    expect(TrainingPaths.section(TrainingSection.wod), '/training?section=wod');
    expect(TrainingSection.fromQuery('wod'), TrainingSection.wod);
    expect(TrainingSection.values, hasLength(3));
    expect(TrainingPaths.wodEditor, '/training/wods/edit');
    expect(TrainingPaths.wodLive, '/training/wods/live');
    expect(TrainingSection.fromQuery(null), TrainingSection.gym);
    expect(TrainingSection.fromQuery('crossfit'), TrainingSection.gym);
    expect(TrainingPaths.routine('r1'), '/training/routines/r1');
    expect(TrainingPaths.run('b1'), '/training/runs/b1');
    expect(TrainingPaths.recordRun(), '/training/run/record');
    expect(
      TrainingPaths.recordRun(workoutId: 'w1', eventId: 'e1'),
      '/training/run/record?workout=w1&event=e1',
    );
    expect(TrainingPaths.activities, '/training/history?tab=activities');
  });

  testWidgets('el selector cambia de apartado con go, sin apilar pantallas', (
    tester,
  ) async {
    Widget page(TrainingSection s) => Scaffold(
      appBar: AppBar(bottom: TrainingSectionBar(current: s)),
      body: Text('section:${s.query}'),
    );
    final router = GoRouter(
      initialLocation: '/training',
      routes: [
        GoRoute(
          path: '/training',
          builder: (_, state) => page(
            TrainingSection.fromQuery(state.uri.queryParameters['section']),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('section:gym'), findsOneWidget);
    expect(find.text('Gimnasio'), findsOneWidget);

    // Un aviso con «Deshacer» del apartado que se deja: se cierra y confirma
    // (su bloc se cierra al cambiar y su «Deshacer» ya no podría deshacer).
    var undone = false;
    var committed = false;
    tester
        .element(find.text('section:gym'))
        .showUndoSnack(
          'Sugerencia descartada',
          onUndo: () => undone = true,
          onCommit: () => committed = true,
        );
    await tester.pump();
    expect(find.text('Sugerencia descartada'), findsOneWidget);

    await tester.tap(find.text('Deportes'));
    await tester.pumpAndSettle();
    expect(find.text('section:run'), findsOneWidget);
    expect(find.text('Sugerencia descartada'), findsNothing);
    expect(committed, isTrue);
    expect(undone, isFalse);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/training?section=run',
    );
    // `go`, no `push`: no hay nada debajo a lo que volver.
    expect(router.canPop(), isFalse);

    // El tercer apartado (ADR 0069).
    await tester.tap(find.text('WOD'));
    await tester.pumpAndSettle();
    expect(find.text('section:wod'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/training?section=wod',
    );
    expect(router.canPop(), isFalse);
  });
}
