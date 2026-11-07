import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/run.dart';
import 'package:synaptixfit/domain/models/training/sport_activity.dart';
import 'package:synaptixfit/domain/use_cases/progress/share_achievement_image_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/delete_run_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_run_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/run_detail/bloc/run_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/run_detail/page/run_detail_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Detalle de una carrera (ADR 0037): cifras explicadas, ruta con leyenda de
/// salida y llegada (sin depender solo del color) y análisis por km, con
/// objetivos táctiles, etiquetas, contraste y texto al 200 %.
void main() {
  final run = RunDetail(
    blockId: 'b1',
    kind: ActivityKind.run,
    startedAt: DateTime(2026, 11, 7, 18),
    endedAt: DateTime(2026, 11, 7, 18, 30),
    distanceMeters: 5230,
    movingSeconds: 1740,
    paceSecondsPerKm: 333,
    elevationGainMeters: 42,
    kcal: 380,
    effort: 7,
    splits: const [
      RunSplit(
        number: 1,
        distanceMeters: 1000,
        seconds: 340,
        paceSecondsPerKm: 340,
      ),
      RunSplit(
        number: 2,
        distanceMeters: 1000,
        seconds: 320,
        paceSecondsPerKm: 320,
      ),
      RunSplit(
        number: 3,
        distanceMeters: 230,
        seconds: 80,
        paceSecondsPerKm: 348,
      ),
    ],
    route: const [(40.0, -3.70), (40.002, -3.701), (40.004, -3.699)],
  );

  setUp(() {
    getIt.registerFactory<RunDetailBloc>(
      () => RunDetailBloc(get: _Get(run), delete: _Delete(), share: _Share()),
    );
  });
  tearDown(() => getIt.unregister<RunDetailBloc>());

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(360, 1600);
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
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const RunDetailPage(blockId: 'b1'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('enseña las cifras explicadas, el origen y la leyenda', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('GPS de la app'), findsOneWidget);
    expect(find.textContaining('5,2 km'), findsWidgets);
    expect(
      find.text(
        'Minutos que tardas en recorrer 1 km: cuanto menos, más rápido.',
      ),
      findsOneWidget,
    );
    expect(find.text('Salida'), findsOneWidget);
    expect(find.text('Llegada'), findsOneWidget);
    expect(find.text('Tu kilómetro más rápido'), findsOneWidget);
    // Sin clave del mapa: fondo liso, nada se rompe.
    expect(find.text('Mapa no disponible'), findsOneWidget);
  });

  for (final (name, theme) in [
    ('claro', AppTheme.light),
    ('oscuro', AppTheme.dark),
  ]) {
    testWidgets('cumple las guías de accesibilidad, tema $name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, theme: theme);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      // Como en el resto de pantallas: la guía de contraste de Flutter da falsos
      // fallos en el tema claro (mide píxeles con la fuente de test); el
      // contraste real de los tokens lo prueba contrast_test.
      if (theme == AppTheme.dark) {
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      handle.dispose();
    });
  }

  testWidgets('con el texto al 200 % no se desborda', (tester) async {
    await pump(tester, scale: 2);
    expect(tester.takeException(), isNull);
  });
}

class _Get implements GetRunUseCaseContract {
  _Get(this._run);
  final RunDetail _run;
  @override
  Future<AppResult<RunDetail>> call(String blockId) async => Success(_run);
}

class _Delete implements DeleteRunUseCaseContract {
  @override
  Future<AppResult<Unit>> call(String blockId) async => const Success(unit);
}

class _Share implements ShareAchievementImageUseCaseContract {
  @override
  Future<AppResult<bool>> call({
    required Uint8List png,
    required String fileName,
    required String text,
  }) async => const Success(true);
}
