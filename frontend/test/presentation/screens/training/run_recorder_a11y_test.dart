import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/run.dart';
import 'package:synaptixfit/domain/enums/device_permission.dart';
import 'package:synaptixfit/domain/use_cases/profile/open_permission_settings_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/discard_run_recording_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/finish_run_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/is_location_service_enabled_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_run_workouts_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/load_run_recording_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_run_recording_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/track_run_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/run_recorder/bloc/run_recorder_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/run_recorder/page/run_recorder_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Grabar una carrera (ADR 0037), antes de empezar, con y sin entreno guiado:
/// objetivos táctiles de 48 dp, botones con nombre, contraste (tema oscuro) y
/// texto al 200 % sin desbordes.
void main() {
  setUp(() {
    getIt.registerFactory<RunRecorderBloc>(
      () => RunRecorderBloc(
        load: _Load(),
        save: _Save(),
        discard: _Discard(),
        finish: _Finish(),
        listWorkouts: _ListWorkouts(),
        serviceEnabled: _ServiceEnabled(),
        track: _Tracker(),
        openSettings: _OpenSettings(),
        clock: () => DateTime(2026, 11, 7, 18),
      ),
    );
  });
  tearDown(() => getIt.unregister<RunRecorderBloc>());

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    ThemeData? theme,
    String? workoutId,
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
        home: RunRecorderPage(workoutId: workoutId),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final workoutId in [null, 'w1']) {
    final label = workoutId == null ? 'libre' : 'con entreno';
    for (final (name, theme) in [
      ('claro', AppTheme.light),
      ('oscuro', AppTheme.dark),
    ]) {
      testWidgets('$label: cumple las guías de accesibilidad, tema $name', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, theme: theme, workoutId: workoutId);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // La guía de contraste de Flutter da falsos fallos en el tema claro
        // con la fuente de test; los tokens los prueba contrast_test.
        if (theme == AppTheme.dark) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        handle.dispose();
      });
    }

    testWidgets('$label: con el texto al 200 % no se desborda', (tester) async {
      await pump(tester, scale: 2, workoutId: workoutId);
      expect(tester.takeException(), isNull);
    });
  }
}

const _workouts = [
  RunWorkout(
    id: 'w1',
    name: 'Series de 400',
    groups: [
      RunStepGroup(
        steps: [
          RunStep(
            type: RunStepType.warmup,
            measure: RunMeasure.time,
            value: 300,
          ),
        ],
      ),
    ],
  ),
];

class _Load implements LoadRunRecordingUseCaseContract {
  @override
  Future<AppResult<RunRecording?>> call() async => const Success(null);
}

class _Save implements SaveRunRecordingUseCaseContract {
  @override
  Future<AppResult<Unit>> call(RunRecording recording) async =>
      const Success(unit);
}

class _Discard implements DiscardRunRecordingUseCaseContract {
  @override
  Future<AppResult<Unit>> call() async => const Success(unit);
}

class _Finish implements FinishRunUseCaseContract {
  @override
  Future<AppResult<RunSaved?>> call(
    RunRecording recording, {
    required int effort,
  }) async => const Success(null);
}

class _ListWorkouts implements ListRunWorkoutsUseCaseContract {
  @override
  Future<AppResult<List<RunWorkout>>> call() async => const Success(_workouts);
}

class _ServiceEnabled implements IsLocationServiceEnabledUseCaseContract {
  @override
  Future<AppResult<bool>> call() async => const Success(true);
}

class _Tracker implements TrackRunUseCaseContract {
  @override
  bool get supported => true;

  @override
  Stream<AppResult<RunFix>> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  }) => const Stream.empty();

  @override
  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  }) async {}

  @override
  Future<void> vibrate() async {}
}

class _OpenSettings implements OpenPermissionSettingsUseCaseContract {
  @override
  Future<AppResult<Unit>> call(DevicePermission permission) async =>
      const Success(unit);
}
