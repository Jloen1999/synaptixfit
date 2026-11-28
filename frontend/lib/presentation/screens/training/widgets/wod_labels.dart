import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/training/wod.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Textos de un WOD (ADR 0069): el nombre de cada plantilla de ejemplo y de
/// sus movimientos (el servidor solo manda códigos), el titular del formato,
/// las cantidades y cómo se lee una marca.
abstract final class WodLabels {
  static String templateName(AppLocalizations l10n, String? code) =>
      switch (code) {
        'TRIPLE_TEN' => l10n.wodTemplateTripleTen,
        'TWELVE_NONSTOP' => l10n.wodTemplateTwelveNonstop,
        'MINUTE_BY_MINUTE' => l10n.wodTemplateMinuteByMinute,
        'FOUR_MINUTES' => l10n.wodTemplateFourMinutes,
        'RUN_AND_PUSH' => l10n.wodTemplateRunAndPush,
        'TWO_DUMBBELLS' => l10n.wodTemplateTwoDumbbells,
        'SWING_CLOCK' => l10n.wodTemplateSwingClock,
        'LONG_LIST' => l10n.wodTemplateLongList,
        _ => l10n.wodDefaultTitle,
      };

  /// Nombre de un movimiento de plantilla; nulo si el código no se conoce.
  static String? codeName(AppLocalizations l10n, String? code) =>
      switch (code) {
        'AIR_SQUAT' => l10n.wodMoveAirSquat,
        'PUSH_UP' => l10n.wodMovePushUp,
        'SIT_UP' => l10n.wodMoveSitUp,
        'BURPEE' => l10n.wodMoveBurpee,
        'LUNGE' => l10n.wodMoveLunge,
        'RUN' => l10n.wodMoveRun,
        'DUMBBELL_THRUSTER' => l10n.wodMoveDumbbellThruster,
        'DUMBBELL_ROW' => l10n.wodMoveDumbbellRow,
        'KETTLEBELL_SWING' => l10n.wodMoveKettlebellSwing,
        'JUMP_ROPE' => l10n.wodMoveJumpRope,
        _ => null,
      };

  static String movementName(AppLocalizations l10n, WodMovement m) =>
      m.name ?? codeName(l10n, m.code) ?? m.code ?? '';

  /// Título de la pizarra: el suyo, el de su plantilla o «WOD de hoy».
  static String title(AppLocalizations l10n, Wod wod) =>
      wod.title ?? templateName(l10n, wod.templateCode);

  /// El WOD con su título ya escrito en el idioma de la persona: así se
  /// guarda una plantilla de ejemplo como WOD propio y se nombra su marca.
  static Wod titled(AppLocalizations l10n, Wod wod) =>
      wod.title == null ? wod.copyWith(title: title(l10n, wod)) : wod;

  static String format(AppLocalizations l10n, WodFormat format) =>
      switch (format) {
        WodFormat.forTime => l10n.wodFormatForTime,
        WodFormat.amrap => l10n.wodFormatAmrap,
        WodFormat.emom => l10n.wodFormatEmom,
        WodFormat.tabata => l10n.wodFormatTabata,
      };

  /// Qué significa el formato, en una línea (la jerga siempre se explica).
  static String formatHelp(AppLocalizations l10n, WodFormat format) =>
      switch (format) {
        WodFormat.forTime => l10n.wodFormatHelpForTime,
        WodFormat.amrap => l10n.wodFormatHelpAmrap,
        WodFormat.emom => l10n.wodFormatHelpEmom,
        WodFormat.tabata => l10n.wodFormatHelpTabata,
      };

  static int _minutes(int? seconds) => ((seconds ?? 0) / 60).ceil();

  /// El titular: «3 rondas», «AMRAP 12 min», «EMOM 10 min», «Tabata».
  static String headline(AppLocalizations l10n, Wod wod) =>
      switch (wod.format) {
        WodFormat.forTime =>
          (wod.rounds ?? 1) > 1
              ? l10n.wodHeadlineRounds(wod.rounds!)
              : l10n.wodFormatForTime,
        WodFormat.amrap || WodFormat.emom => l10n.wodHeadlineMinutes(
          format(l10n, wod.format),
          _minutes(wod.timeCapSeconds),
        ),
        WodFormat.tabata => l10n.wodFormatTabata,
      };

  /// El límite de tiempo, donde el titular no lo dice ya.
  static String? timeCap(AppLocalizations l10n, Wod wod) =>
      switch (wod.format) {
        WodFormat.forTime =>
          wod.timeCapSeconds == null
              ? l10n.wodNoTimeCap
              : l10n.wodTimeCap(_minutes(wod.timeCapSeconds)),
        _ => null,
      };

  static String quantity(AppLocalizations l10n, WodMovement m) {
    final q = m.quantity;
    if (q == null) return l10n.wodMaxReps;
    return switch (m.unit) {
      WodUnit.reps => '$q',
      WodUnit.calories => l10n.wodQuantityCalories(q),
      WodUnit.meters => l10n.wodQuantityMeters(q),
    };
  }

  /// Kilos de un movimiento en esa división («16 kg»); nulo si no lleva.
  static String? kg(AppLocalizations l10n, WodMovement m, WodDivision d) {
    final value = d == WodDivision.rx ? m.rxKg : m.scaledKg;
    if (value == null) return null;
    return l10n.wodKg(
      NumberFormat.decimalPattern(l10n.localeName).format(value),
    );
  }

  static String division(AppLocalizations l10n, WodDivision d) => switch (d) {
    WodDivision.rx => l10n.wodDivisionRx,
    WodDivision.scaled => l10n.wodDivisionScaled,
  };

  /// «7:05» o, desde una hora, «1:02:03».
  static String clock(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final two = (s % 60).toString().padLeft(2, '0');
    if (s < 3600) return '${s ~/ 60}:$two';
    final minutes = (s % 3600 ~/ 60).toString().padLeft(2, '0');
    return '${s ~/ 3600}:$minutes:$two';
  }

  /// Cómo se lee una marca: «9:00», «5 rondas + 12 reps», «48 repeticiones».
  static String score(AppLocalizations l10n, WodResult r) {
    final text = switch (r.scoreType) {
      WodScoreType.time => clock(r.value),
      WodScoreType.roundsReps => l10n.wodScoreRoundsReps(
        r.value,
        r.extraReps ?? 0,
      ),
      WodScoreType.reps => l10n.wodScoreReps(r.value),
      WodScoreType.load => l10n.wodKg('${r.value}'),
    };
    return r.capped ? l10n.wodScoreCapped(text) : text;
  }
}

/// Una línea de la pizarra: la cantidad en negrita delante, el movimiento y,
/// si los lleva en esa división, los kilos.
class WodMovementLine extends StatelessWidget {
  const WodMovementLine({
    super.key,
    required this.movement,
    required this.division,
    this.style,
  });

  final WodMovement movement;
  final WodDivision division;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final base = style ?? DefaultTextStyle.of(context).style;
    final kg = WodLabels.kg(l10n, movement, division);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: WodLabels.quantity(l10n, movement),
            style: base.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: ' ${WodLabels.movementName(l10n, movement)}'),
          if (kg != null) TextSpan(text: ' · $kg'),
        ],
      ),
    );
  }
}
