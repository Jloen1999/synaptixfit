import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../domain/models/planner/focus.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';

/// Hoja «Descansos» del Pomodoro (ADR 0053): el descanso entre bloques y el
/// largo, cada uno con atajos (el del día marcado «Recomendado») y ajuste fino
/// dentro de los límites del servidor ([FocusPlan]). Devuelve la elección (nulo
/// en un descanso = el recomendado del día) o nulo si se cierra sin guardar.
Future<FocusBreakChoice?> showPomodoroBreaksSheet(
  BuildContext context, {
  required FocusPlan plan,
  required int shortBreakMinutes,
  required int longBreakMinutes,
}) => showModalBottomSheet<FocusBreakChoice>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _BreaksSheet(
    plan: plan,
    shortBreak: shortBreakMinutes,
    longBreak: longBreakMinutes,
  ),
);

class _BreaksSheet extends StatefulWidget {
  const _BreaksSheet({
    required this.plan,
    required this.shortBreak,
    required this.longBreak,
  });

  final FocusPlan plan;
  final int shortBreak;
  final int longBreak;

  @override
  State<_BreaksSheet> createState() => _BreaksSheetState();
}

class _BreaksSheetState extends State<_BreaksSheet> {
  late int _short = widget.shortBreak;
  late int _long = widget.longBreak;

  /// Atajos de siempre; el recomendado del día se añade si no está.
  static const _shortShortcuts = [5, 10, 15];
  static const _longShortcuts = [15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final plan = widget.plan;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.m,
          0,
          TokensSpacing.m,
          TokensSpacing.m,
        ),
        child: AppContentWidth.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.plannerPomodoroBreaksTitle,
                  style: context.textStyles.titleLarge,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              _MinutesChoice(
                label: l10n.plannerPomodoroShortBreakLabel,
                stepperLabel: l10n.plannerPomodoroShortBreakMinutes,
                shortcuts: _shortShortcuts,
                recommended: plan.shortBreakMinutes,
                value: _short,
                min: plan.minShortBreakMinutes,
                max: plan.maxShortBreakMinutes,
                onChanged: (v) => setState(() => _short = v),
              ),
              const SizedBox(height: TokensSpacing.l),
              _MinutesChoice(
                label: l10n.plannerPomodoroLongBreakLabel(
                  plan.cyclesBeforeLongBreak,
                ),
                stepperLabel: l10n.plannerPomodoroLongBreakMinutes,
                shortcuts: _longShortcuts,
                recommended: plan.longBreakMinutes,
                value: _long,
                min: plan.minLongBreakMinutes,
                max: plan.maxLongBreakMinutes,
                onChanged: (v) => setState(() => _long = v),
              ),
              const SizedBox(height: TokensSpacing.m),
              Text(
                l10n.plannerPomodoroBreaksRemembered,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppPrimaryButton(
                label: l10n.commonSave,
                // Elegir el recomendado se guarda como «el del día»: si mañana
                // la recomendación cambia, se sigue.
                onPressed: () => unawaited(
                  Navigator.of(context).maybePop(
                    FocusBreakChoice(
                      shortBreakMinutes: _short == plan.shortBreakMinutes
                          ? null
                          : _short,
                      longBreakMinutes: _long == plan.longBreakMinutes
                          ? null
                          : _long,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un descanso: atajos en chips (el del día con «Recomendado») y un selector
/// de minutos para afinar.
class _MinutesChoice extends StatelessWidget {
  const _MinutesChoice({
    required this.label,
    required this.stepperLabel,
    required this.shortcuts,
    required this.recommended,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String stepperLabel;
  final List<int> shortcuts;
  final int recommended;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final options = {
      for (final m in [...shortcuts, recommended])
        if (m >= min && m <= max) m,
    }.toList()..sort();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Text(label, style: context.textStyles.titleSmall),
          ),
          const SizedBox(height: TokensSpacing.xs),
          // Chips que bajan de fila: «17 min · Recomendado» no se corta.
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              for (final m in options)
                ChoiceChip(
                  label: Text(
                    m == recommended
                        ? l10n.plannerPomodoroMinutesRecommended(m)
                        : l10n.plannerPomodoroMinutes(m),
                  ),
                  selected: m == value,
                  onSelected: (_) => onChanged(m),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          AppStepperField(
            label: stepperLabel,
            value: value.clamp(min, max),
            min: min,
            max: max,
            display: l10n.plannerPomodoroMinutes,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
