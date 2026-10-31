import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/training/session_history.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Texto de una marca: «62,5 kg × 5» o «8 reps» (con peso solo si el récord
/// es de peso). Lo comparten el historial y el resumen final de la sesión.
String recordValueLabel(BuildContext context, PersonalRecord r) {
  final l10n = context.localizations;
  return r.kind == PersonalRecordKind.weight && r.weightKg != null
      ? l10n.trainingRecordWeight(
          NumberFormat('0.#').format(r.weightKg),
          r.reps,
        )
      : l10n.trainingRecordReps(r.reps);
}

/// Igual que [recordValueLabel] pero para el lector de pantalla («×» se leía
/// «multiplicado por»).
String recordValueSpoken(BuildContext context, PersonalRecord r) {
  final l10n = context.localizations;
  return r.kind == PersonalRecordKind.weight && r.weightKg != null
      ? l10n.trainingRecordWeightSpoken(
          NumberFormat('0.#').format(r.weightKg),
          r.reps,
        )
      : l10n.trainingRecordReps(r.reps);
}

/// Fila de récord batido con trofeo: «Récord: Press de banca, 65 kg × 8» (sin
/// nombre de ejercicio, «Récord: 65 kg × 8»).
class PersonalRecordRow extends StatelessWidget {
  const PersonalRecordRow({super.key, required this.record, this.style});

  final PersonalRecord record;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final name = record.exerciseName;
    final hasName = name != null && name.trim().isNotEmpty;
    String text(String value) => hasName
        ? l10n.trainingRecordBroken(name, value)
        : l10n.trainingRecordBrokenUnnamed(value);
    return Semantics(
      label: text(recordValueSpoken(context, record)),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: TokensSize.iconS,
            color: context.palette.accent,
          ),
          const SizedBox(width: TokensSpacing.xs),
          Expanded(
            child: Text(text(recordValueLabel(context, record)), style: style),
          ),
        ],
      ),
    );
  }
}
