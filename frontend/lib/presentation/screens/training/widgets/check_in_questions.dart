import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/training/check_in_answers.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Las tres preguntas de «¿Qué tal estás hoy?» (sueño, energía y agujetas),
/// un toque cada una. Es el único registro diario de la app (ADR 0039): lo
/// usan la tarjeta de Entreno y la pantalla del registro, que añade los
/// detalles opcionales.
///
/// Todas las respuestas van en el mismo sentido: **a la derecha, lo mejor**
/// («Mal · Regular · Bien», «Muchas · Algo · Nada»). El sentido de cada escala
/// lo da el dominio ([CheckInScale]): el servidor sigue guardando las escalas
/// 1-5 de siempre, así no cambian las fórmulas de fatiga ni de energía.
class CheckInQuestions extends StatelessWidget {
  const CheckInQuestions({
    super.key,
    required this.answers,
    required this.onAnswer,
  });

  /// Lo contestado hasta ahora (valores 1-5 del servidor).
  final CheckInAnswers answers;
  final void Function(CheckInQuestion question, int value) onAnswer;

  static String title(AppLocalizations l10n, CheckInQuestion q) => switch (q) {
    CheckInQuestion.sleep => l10n.trainingQuickSleep,
    CheckInQuestion.energy => l10n.trainingQuickEnergy,
    CheckInQuestion.soreness => l10n.trainingQuickSoreness,
  };

  /// Palabras de peor a mejor de cada pregunta (izquierda a derecha).
  static List<String> _words(AppLocalizations l10n, CheckInQuestion q) =>
      switch (q) {
        CheckInQuestion.sleep => [
          l10n.trainingQuickBad,
          l10n.trainingQuickSoSo,
          l10n.trainingQuickGood,
        ],
        CheckInQuestion.energy => [
          l10n.trainingQuickLow,
          l10n.trainingQuickMid,
          l10n.trainingQuickHigh,
        ],
        CheckInQuestion.soreness => [
          l10n.trainingQuickSoreLot,
          l10n.trainingQuickSoreSome,
          l10n.trainingQuickSoreNone,
        ],
      };

  /// Las tres respuestas de una pregunta: (valor que se guarda, palabra), de
  /// peor a mejor según el sentido de su escala.
  static List<(int, String)> options(AppLocalizations l10n, CheckInQuestion q) {
    final words = _words(l10n, q);
    final values = q.scale.threeWorstToBest;
    return [for (var i = 0; i < values.length; i++) (values[i], words[i])];
  }

  /// La respuesta en palabras de un valor guardado (historial).
  static String answer(AppLocalizations l10n, CheckInQuestion q, int value) {
    final snapped = CheckInScale.snap(value);
    return options(l10n, q).firstWhere((o) => o.$1 == snapped).$2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final q in CheckInQuestion.values)
          _Question(
            label: title(l10n, q),
            options: options(l10n, q),
            value: CheckInScale.snap(answers[q]),
            onChanged: (v) => onAnswer(q, v),
          ),
      ],
    );
  }
}

/// Una pregunta con sus tres respuestas cortas: el mismo control que el resto
/// de opciones cortas de la app ([AppSegmentedChoice]), que pasa a chips con
/// el texto grande o en pantallas estrechas.
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
    child: AppSegmentedChoice<int>(
      label: label,
      values: [for (final (score, _) in options) score],
      selected: value,
      labelOf: (score) => options.firstWhere((o) => o.$1 == score).$2,
      // Sin «vacío»: tocar la ya elegida no la quita (la respuesta sigue).
      onChanged: (score) {
        if (score != null) onChanged(score);
      },
    ),
  );
}

/// Confirmación que se queda a la vista tras guardar el registro: icono ✓ y
/// «Guardado hoy a las 9:41», en la tarjeta de Gimnasio y en la pantalla del
/// registro (ADR 0062). No es región viva: quien la muestra lo anuncia una
/// sola vez al guardar ([spoken]), así no se repite al desplazarse.
class CheckInSavedNote extends StatelessWidget {
  const CheckInSavedNote({super.key, required this.savedAt});

  final DateTime savedAt;

  /// «Guardado hoy a las 9:41» (la hora sigue el idioma de la app).
  static String text(AppLocalizations l10n, DateTime savedAt) =>
      l10n.trainingCheckInSavedAt(DateFormat.Hm().format(savedAt));

  /// Lo que se anuncia al guardar: la confirmación y, si la hay, la frase que
  /// la acompaña en pantalla ([summary]).
  static String spoken(
    AppLocalizations l10n,
    DateTime savedAt, {
    String? summary,
  }) => summary == null
      ? text(l10n, savedAt)
      : l10n.trainingCheckInSavedSpoken(text(l10n, savedAt), summary);

  @override
  Widget build(BuildContext context) => AppInlineMessage(
    message: text(context.localizations, savedAt),
    tone: AppMessageTone.success,
    live: false,
  );
}
