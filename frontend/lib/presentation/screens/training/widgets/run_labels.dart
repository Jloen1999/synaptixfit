import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/training/run.dart';
import '../../../../domain/models/training/sport_activity.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Textos de las carreras con GPS y los entrenos de carrera (ADR 0037), con
/// el vocabulario de `docs/05-design/vocabulario.md`: «Carrera», «Paseo» o
/// «Bici» según el tipo; origen «GPS de la app» / «Apuntada a mano»; pasos
/// «Calentar», «Correr», «Recuperar», «Enfriar»; series «6 × 800 m».
abstract final class RunLabels {
  /// «3,2 km» (una decimal; dos por debajo de 1 km).
  static String km(AppLocalizations l10n, num meters) {
    final km = meters / 1000;
    final f = NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: km < 1 ? 2 : 1,
    );
    return l10n.runKm(f.format(km));
  }

  /// «18:40» o «1:02:15».
  static String clock(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
  }

  /// «5:33» (minutos por km), o «—» si aún no hay ritmo.
  static String pace(int? secondsPerKm) =>
      secondsPerKm == null ? '—' : clock(secondsPerKm);

  /// Ritmo para el lector de pantalla: «5 minutos y 33 segundos por km».
  static String paceSpoken(AppLocalizations l10n, int? secondsPerKm) =>
      secondsPerKm == null
      ? l10n.runPaceNone
      : l10n.runPaceSpoken(secondsPerKm ~/ 60, secondsPerKm % 60);

  /// Nombre de la actividad según su tipo: «Carrera», «Paseo», «Bici».
  static String kindName(AppLocalizations l10n, ActivityKind kind) =>
      switch (kind) {
        ActivityKind.walk => l10n.runKindWalk,
        ActivityKind.bike => l10n.runKindBike,
        _ => l10n.runKindRun,
      };

  static IconData kindIcon(ActivityKind kind) => switch (kind) {
    ActivityKind.walk => Icons.directions_walk_rounded,
    ActivityKind.bike => Icons.directions_bike_rounded,
    _ => Icons.directions_run_rounded,
  };

  static String source(AppLocalizations l10n, ActivitySource? source) =>
      switch (source) {
        ActivitySource.gps => l10n.runSourceGps,
        ActivitySource.manual => l10n.runSourceManual,
        null => l10n.runSourceCalendar,
      };

  static String stepType(AppLocalizations l10n, RunStepType type) =>
      switch (type) {
        RunStepType.warmup => l10n.runStepWarmup,
        RunStepType.run => l10n.runStepRun,
        RunStepType.recover => l10n.runStepRecover,
        RunStepType.cooldown => l10n.runStepCooldown,
      };

  /// «10 min», «45 s», «800 m», «10 km».
  static String amount(AppLocalizations l10n, RunStep step) {
    if (step.measure == RunMeasure.distance) {
      return step.value >= 1000 && step.value % 100 == 0
          ? km(l10n, step.value)
          : l10n.runMeters(step.value);
    }
    final v = step.value;
    if (v % 60 == 0) return l10n.runMinutes(v ~/ 60);
    if (v < 60) return l10n.runSeconds(v);
    return clock(v);
  }

  /// «Correr 800 m».
  static String step(AppLocalizations l10n, RunStep s) =>
      l10n.runStepLine(stepType(l10n, s.type), amount(l10n, s));

  /// «6 × 800 m · 2 min recuperando» o «Calentar 10 min».
  static String group(AppLocalizations l10n, RunStepGroup g) {
    if (g.repeat <= 1) return g.steps.map((s) => step(l10n, s)).join(' · ');
    final main = g.steps.first;
    final rest = g.steps.skip(1).map((s) {
      return s.type == RunStepType.recover
          ? l10n.runRecovering(amount(l10n, s))
          : step(l10n, s);
    });
    return [
      l10n.runRepeatLine(g.repeat, amount(l10n, main)),
      ...rest,
    ].join(' · ');
  }

  /// Nombre de una plantilla por su código (en el idioma de la app).
  static String templateName(AppLocalizations l10n, String? code) =>
      switch (code) {
        'START_WALK_RUN' => l10n.runTemplateStartName,
        'EASY_30' => l10n.runTemplateEasyName,
        'INTERVALS_6X800' => l10n.runTemplateIntervalsName,
        'PACE_CHANGES' => l10n.runTemplatePaceChangesName,
        'STEADY_20' => l10n.runTemplateSteadyName,
        'LONG_RUN' => l10n.runTemplateLongName,
        _ => l10n.runWorkoutUntitled,
      };

  /// Para qué sirve, en una frase sencilla.
  static String templateWhy(AppLocalizations l10n, String? code) =>
      switch (code) {
        'START_WALK_RUN' => l10n.runTemplateStartWhy,
        'EASY_30' => l10n.runTemplateEasyWhy,
        'INTERVALS_6X800' => l10n.runTemplateIntervalsWhy,
        'PACE_CHANGES' => l10n.runTemplatePaceChangesWhy,
        'STEADY_20' => l10n.runTemplateSteadyWhy,
        'LONG_RUN' => l10n.runTemplateLongWhy,
        _ => '',
      };

  /// «≈ 45 min».
  static String estimate(AppLocalizations l10n, int seconds) =>
      l10n.runEstimate((seconds / 60).ceil());
}
