import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../domain/models/social/together.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';

/// Minutos de cada ronda de una sala (ADR 0053): los atajos que manda el
/// servidor (25 + 5, 50 + 10) y, debajo, el ajuste fino de la concentración y
/// del descanso dentro de los límites de `/together/limits`. Lo usan «Estudiar
/// con amigos» y la hoja «Cambiar tiempos» de la sala.
class StudyRoomTimesPicker extends StatelessWidget {
  const StudyRoomTimesPicker({
    super.key,
    required this.limits,
    required this.value,
    required this.onChanged,
  });

  final TogetherLimits limits;
  final StudyRoomTimes value;
  final ValueChanged<StudyRoomTimes> onChanged;

  /// [times] dentro de los límites de [limits] (p. ej. los de un enlace).
  static StudyRoomTimes clamp(StudyRoomTimes times, TogetherLimits limits) =>
      StudyRoomTimes(
        focusMinutes: limits.studyRoomFocusMinutes.clamp(times.focusMinutes),
        breakMinutes: limits.studyRoomBreakMinutes.clamp(times.breakMinutes),
      );

  /// La concentración se ajusta de 5 en 5 (como el Pomodoro); el descanso,
  /// minuto a minuto.
  static const _focusStep = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final presets = limits.studyRoomPresets;
    final focus = limits.studyRoomFocusMinutes;
    final rest = limits.studyRoomBreakMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (presets.isNotEmpty) ...[
          AppSegmentedChoice<StudyRoomTimes>(
            label: l10n.togetherStudyLength,
            values: presets,
            // Unos minutos a medida no marcan ningún atajo.
            selected: presets.contains(value) ? value : null,
            labelOf: (t) =>
                l10n.togetherStudyLengthOption(t.focusMinutes, t.breakMinutes),
            onChanged: (t) {
              if (t != null) onChanged(t);
            },
          ),
          const SizedBox(height: TokensSpacing.m),
        ],
        AppStepperField(
          label: l10n.togetherStudyFocusLabel,
          value: focus.clamp(value.focusMinutes),
          min: focus.min,
          max: focus.max,
          step: _focusStep,
          display: l10n.togetherStudyMinutesValue,
          onChanged: (v) => onChanged(value.copyWith(focusMinutes: v)),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppStepperField(
          label: l10n.togetherStudyBreakLabel,
          value: rest.clamp(value.breakMinutes),
          min: rest.min,
          max: rest.max,
          display: l10n.togetherStudyMinutesValue,
          onChanged: (v) => onChanged(value.copyWith(breakMinutes: v)),
        ),
      ],
    );
  }
}

/// Hoja «Cambiar tiempos» de una sala que aún no ha empezado: devuelve los
/// minutos elegidos o nulo si se cierra sin guardar.
Future<StudyRoomTimes?> showStudyRoomTimesSheet(
  BuildContext context, {
  required TogetherLimits limits,
  required StudyRoomTimes initial,
}) => showModalBottomSheet<StudyRoomTimes>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _TimesSheet(limits: limits, initial: initial),
);

class _TimesSheet extends StatefulWidget {
  const _TimesSheet({required this.limits, required this.initial});

  final TogetherLimits limits;
  final StudyRoomTimes initial;

  @override
  State<_TimesSheet> createState() => _TimesSheetState();
}

class _TimesSheetState extends State<_TimesSheet> {
  late StudyRoomTimes _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          TokensSpacing.m,
          0,
          TokensSpacing.m,
          TokensSpacing.m + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AppContentWidth.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.togetherStudyTimesTitle,
                  style: context.textStyles.titleLarge,
                ),
              ),
              const SizedBox(height: TokensSpacing.xs),
              Text(
                l10n.togetherStudyTimesHint,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              StudyRoomTimesPicker(
                limits: widget.limits,
                value: _value,
                onChanged: (v) => setState(() => _value = v),
              ),
              const SizedBox(height: TokensSpacing.l),
              AppPrimaryButton(
                label: l10n.commonSave,
                onPressed: () =>
                    unawaited(Navigator.of(context).maybePop(_value)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
