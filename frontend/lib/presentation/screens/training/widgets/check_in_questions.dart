import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';

/// Las tres preguntas de «¿Qué tal estás hoy?» (sueño, energía y agujetas),
/// un toque cada una. Es el único registro diario de la app (ADR 0039): lo
/// usan la tarjeta de Entreno y la pantalla del registro, que añade los
/// detalles opcionales.
///
/// Todas las respuestas van en el mismo sentido: **a la derecha, lo mejor**
/// («Mal · Regular · Bien», «Muchas · Algo · Nada»). Solo cambia el orden en
/// pantalla: el servidor sigue guardando las escalas 1-5 de siempre (en
/// agujetas, 5 = muchas), así no cambian las fórmulas de fatiga ni de energía.
class CheckInQuestions extends StatelessWidget {
  const CheckInQuestions({
    super.key,
    required this.sleep,
    required this.energy,
    required this.soreness,
    required this.onSleep,
    required this.onEnergy,
    required this.onSoreness,
  });

  /// Valores 1-5 del servidor (nulo: sin contestar).
  final int? sleep;
  final int? energy;
  final int? soreness;
  final ValueChanged<int> onSleep;
  final ValueChanged<int> onEnergy;
  final ValueChanged<int> onSoreness;

  /// Valor que se guarda con cada respuesta: los extremos y el centro de la
  /// escala 1-5.
  static const bad = 1;
  static const mid = 3;
  static const good = 5;

  /// Respuesta que se marca para un valor de la escala 1-5 (un registro
  /// antiguo puede traer un 2 o un 4: se marca la más cercana).
  static int? snap(int? value) => switch (value) {
    null => null,
    <= 2 => bad,
    3 => mid,
    _ => good,
  };

  /// Las tres respuestas de cada pregunta, de peor a mejor (izquierda a
  /// derecha). En agujetas, «Nada» es lo mejor y se guarda como 1.
  static List<(int, String)> sleepOptions(AppLocalizations l10n) => [
    (bad, l10n.trainingQuickBad),
    (mid, l10n.trainingQuickSoSo),
    (good, l10n.trainingQuickGood),
  ];

  static List<(int, String)> energyOptions(AppLocalizations l10n) => [
    (bad, l10n.trainingQuickLow),
    (mid, l10n.trainingQuickMid),
    (good, l10n.trainingQuickHigh),
  ];

  static List<(int, String)> sorenessOptions(AppLocalizations l10n) => [
    (good, l10n.trainingQuickSoreLot),
    (mid, l10n.trainingQuickSoreSome),
    (bad, l10n.trainingQuickSoreNone),
  ];

  /// La respuesta en palabras de un valor guardado (historial).
  static String answer(List<(int, String)> options, int value) {
    final snapped = snap(value);
    return options.firstWhere((o) => o.$1 == snapped).$2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Question(
          label: l10n.trainingQuickSleep,
          options: sleepOptions(l10n),
          value: snap(sleep),
          onChanged: onSleep,
        ),
        _Question(
          label: l10n.trainingQuickEnergy,
          options: energyOptions(l10n),
          value: snap(energy),
          onChanged: onEnergy,
        ),
        _Question(
          label: l10n.trainingQuickSoreness,
          options: sorenessOptions(l10n),
          // En agujetas el 1 es «Nada» y el 5 «Muchas»: el centro no cambia.
          value: snap(soreness),
          onChanged: onSoreness,
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<(int, String)> options;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TokensSpacing.m),
    child: Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(label, style: context.textStyles.titleSmall),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              for (final (score, text) in options)
                ChoiceChip(
                  label: Text(text),
                  selected: value == score,
                  onSelected: (_) => onChanged(score),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
