import 'package:flutter/material.dart';

import '../../../../domain/enums/home_acwr_zone.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// «Tu equilibrio» en formato compacto: una fila por la mente (carga
/// cognitiva) y otra por el cuerpo (carga física), cada una con su valor, una
/// barra y el nivel en palabras; debajo, la pauta de estudio con su acción.
/// Es pequeña a propósito: lo primero que se ve en Inicio es la agenda.
/// Con un solo enfoque («Tu estado») se muestra solo su fila.
class StateSection extends StatelessWidget {
  const StateSection({
    super.key,
    required this.cognitive,
    required this.crossRegulation,
    required this.wellbeing,
    this.focus = UsageFocus.both,
    required this.onOpenAnalytics,
    required this.onStudyNow,
  });

  final HomeCognitiveState cognitive;
  final HomeCrossRegulation crossRegulation;
  final HomeWellbeing wellbeing;
  final UsageFocus focus;
  final VoidCallback onOpenAnalytics;

  /// Abre el Pomodoro: la recomendación termina en algo que hacer.
  final VoidCallback onStudyNow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final good = context.palette.success;
    final mid = context.palette.warning;
    final bad = context.colors.error;
    final muted = context.colors.onSurfaceVariant;

    // Carga cognitiva: más alta es peor.
    final load = cognitive.cognitiveLoad;
    final (loadLevel, loadColor) = load < 0.3
        ? (l10n.homeLevelLow, good)
        : load < 0.6
        ? (l10n.homeLevelModerate, mid)
        : load < 0.8
        ? (l10n.homeLevelHigh, mid)
        : (l10n.homeLevelCritical, bad);

    // Atención: más alta es mejor.
    final attention = cognitive.attentionCapacity;
    final attentionLevel = attention >= 0.7
        ? l10n.homeLevelHigh
        : attention >= 0.4
        ? l10n.homeLevelModerate
        : l10n.homeLevelLow;

    // Carga física: se muestra la zona en palabras; el ratio queda en la
    // analítica para quien lo quiera (aquí sería jerga).
    final acwr = crossRegulation.acwr;
    final (zoneLabel, zoneColor) = switch (crossRegulation.zone) {
      HomeAcwrZone.noData => (l10n.homeZoneNoData, muted),
      HomeAcwrZone.undertraining => (l10n.homeZoneUndertraining, mid),
      HomeAcwrZone.optimal => (l10n.homeZoneOptimal, good),
      HomeAcwrZone.danger => (l10n.homeZoneDanger, mid),
      HomeAcwrZone.overtraining => (l10n.homeZoneOvertraining, bad),
    };

    // Energía (0-100): solo existe con check-in.
    final energy = wellbeing.energyScore;

    final mind = _Metric(
      title: l10n.homeGaugeCognitiveLoad,
      icon: Icons.psychology_outlined,
      iconColor: context.palette.study,
      value: l10n.homeGaugePercent((load * 100).round()),
      level: loadLevel,
      levelColor: loadColor,
      progress: load,
      detail: l10n.homeBalanceAttention(attentionLevel),
      hint: '${l10n.homeGaugeCognitiveLoadHint} ${l10n.homeGaugeAttentionHint}',
    );
    final body = _Metric(
      title: l10n.homeGaugeAcwr,
      icon: Icons.directions_run_rounded,
      iconColor: context.palette.sessions,
      value: zoneLabel,
      level: null,
      levelColor: zoneColor,
      // Escala visual 0-2: la mitad de la barra corresponde a la carga
      // habitual (ratio 1).
      progress: acwr == null ? null : (acwr / 2).clamp(0, 1).toDouble(),
      detail: energy == null
          ? l10n.homeBalanceEnergyMissing
          : l10n.homeBalanceEnergy(energy.round()),
      hint:
          '${l10n.homeGaugeAcwrHint} '
          '${energy == null ? l10n.homeGaugeEnergyNoCheckIn : l10n.homeGaugeEnergyHint}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: focus == UsageFocus.both
              ? l10n.homeBalanceTitle
              : l10n.homeStateTitle,
          // La analítica es de entrenamiento: con solo estudios no hay enlace.
          actionLabel: focus.includesFitness
              ? l10n.homeBalanceSeeAnalysis
              : null,
          onAction: focus.includesFitness ? onOpenAnalytics : null,
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(TokensSpacing.m),
                child: switch (focus) {
                  UsageFocus.academic => mind,
                  UsageFocus.fitness => body,
                  UsageFocus.both => LayoutBuilder(
                    builder: (context, constraints) =>
                        // En móvil se apilan: lado a lado cada columna quedaría muy estrecha.
                        constraints.maxWidth >=
                            context.scaled(TokensLayout.formMaxWidth)
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: mind),
                              const SizedBox(width: TokensSpacing.l),
                              Expanded(child: body),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              mind,
                              const SizedBox(height: TokensSpacing.m),
                              body,
                            ],
                          ),
                  ),
                },
              ),
              if (focus.includesAcademic)
                // La misma recomendación con la que arranca el Pomodoro.
                _Link(
                  focusMinutes: crossRegulation.focusMinutes,
                  breakMinutes: crossRegulation.focusBreakMinutes,
                  onStudyNow: onStudyNow,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Indicador compacto: nombre y valor en una línea, una barra fina y, debajo,
/// el nivel y el dato secundario (atención o energía). La explicación sale en
/// el tooltip y en el lector de pantalla.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.level,
    required this.levelColor,
    required this.progress,
    required this.detail,
    required this.hint,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String value;

  /// Nivel en palabras; nulo cuando [value] ya lo es (zona de carga física).
  final String? level;
  final Color levelColor;

  /// 0-1; nulo sin datos (la barra queda vacía).
  final double? progress;
  final String detail;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final summary = [?level, detail].join(' · ');
    // El lector ya lee la explicación como pista: el tooltip no la repite.
    return Tooltip(
      message: hint,
      excludeFromSemantics: true,
      child: Semantics(
        label: l10n.homeGaugeSemantics(
          title,
          value,
          [?level, detail].join(', '),
        ),
        hint: hint,
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: TokensSize.iconS, color: iconColor),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(title, style: context.textStyles.titleSmall),
                ),
                const SizedBox(width: TokensSpacing.s),
                // Título y valor se reparten el ancho: con texto grande el
                // valor baja de línea en vez de aplastar el título.
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: context.textStyles.titleMedium?.copyWith(
                      color: level == null ? levelColor : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            ClipRRect(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: LinearProgressIndicator(
                value: progress ?? 0,
                color: levelColor,
                backgroundColor: context.colors.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              summary,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Franja inferior: cómo se regulan entre sí estudio y ejercicio, y la acción
/// que se deriva (empezar un bloque de estudio).
class _Link extends StatelessWidget {
  const _Link({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.onStudyNow,
  });

  final int focusMinutes;
  final int breakMinutes;
  final VoidCallback onStudyNow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.m,
        vertical: TokensSpacing.s,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      // Una sola línea con la recomendación y, al lado, su acción. Si no
      // cabe (móvil estrecho o texto grande) el botón baja debajo.
      child: Wrap(
        spacing: TokensSpacing.s,
        runSpacing: TokensSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_alt_rounded, color: colors.primary),
              const SizedBox(width: TokensSpacing.sm),
              Flexible(
                child: Text(
                  l10n.homeBalanceFocusPlan(focusMinutes, breakMinutes),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onStudyNow,
            icon: const Icon(Icons.timer_outlined),
            label: Text(l10n.homeBalanceStudyNow),
          ),
        ],
      ),
    );
  }
}
