import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../l10n/gen_l10n/app_localizations.dart';

/// Control del esfuerzo percibido (RPE 1-10): la cifra y su palabra grandes y
/// el deslizador. El lector de pantalla oye una sola vez «Esfuerzo» con su
/// valor (la cifra visible no se repite). Lo usan el diálogo de esfuerzo y el
/// de duración y esfuerzo de una sesión.
class AppEffortSlider extends StatelessWidget {
  const AppEffortSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool autofocus;

  /// Palabra del esfuerzo: fácil, moderado, duro o máximo.
  static String describe(AppLocalizations l10n, int value) => switch (value) {
    <= 3 => l10n.commonEffortEasy,
    <= 6 => l10n.commonEffortModerate,
    <= 8 => l10n.commonEffortHard,
    _ => l10n.commonEffortMax,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // La cifra y la palabra ya las dice el control al lector de pantalla.
        ExcludeSemantics(
          child: Column(
            children: [
              Text(
                '$value',
                style: context.textStyles.displaySmall?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              Text(describe(l10n, value), style: context.textStyles.labelLarge),
            ],
          ),
        ),
        Semantics(
          label: l10n.commonEffortTitle,
          child: Slider(
            autofocus: autofocus,
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$value',
            semanticFormatterCallback: (v) => l10n.commonEffortSemantics(
              v.round(),
              describe(l10n, v.round()),
            ),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
