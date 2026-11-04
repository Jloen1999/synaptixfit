import 'package:flutter/material.dart' hide Visibility;

import '../../../../domain/enums/challenge_difficulty.dart';
import '../../../../domain/enums/challenge_type.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/challenges/challenge_references.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'challenge_focus.dart';
import 'challenge_labels.dart';

/// Selector de esfuerzo con etiquetas amigables (sin cifras de XP).
class EffortSelector extends StatelessWidget {
  const EffortSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ChallengeDifficulty value;
  final ValueChanged<ChallengeDifficulty>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ChallengeDifficulty>(
        showSelectedIcon: false,
        segments: [
          for (final d in ChallengeDifficulty.values)
            ButtonSegment(
              value: d,
              icon: Icon(d.icon, size: TokensSize.iconXs),
              label: Text(d.effortLabel(context)),
            ),
        ],
        selected: {value},
        onSelectionChanged: onChanged == null
            ? null
            : (s) => onChanged!(s.first),
      ),
    );
  }
}

/// Selector de tipo de reto (académico / físico). Con un solo enfoque de uso no
/// hay nada que elegir y no se muestra (ver [ChallengeTypeField]).
class ChallengeTypeSelector extends StatelessWidget {
  const ChallengeTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ChallengeType value;
  final ValueChanged<ChallengeType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ChallengeType>(
        showSelectedIcon: false,
        segments: [
          for (final t in context.allowedChallengeTypes)
            ButtonSegment(
              value: t,
              icon: Icon(t.icon, size: TokensSize.iconXs),
              label: Text(t.label(context)),
            ),
        ],
        selected: {value},
        onSelectionChanged: onChanged == null
            ? null
            : (s) => onChanged!(s.first),
      ),
    );
  }
}

/// Etiqueta «Tipo» + [ChallengeTypeSelector], solo si el enfoque permite
/// elegir entre los dos tipos.
class ChallengeTypeField extends StatelessWidget {
  const ChallengeTypeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final ChallengeType value;
  final ValueChanged<ChallengeType>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (context.allowedChallengeTypes.length < 2) {
      return const SizedBox.shrink();
    }
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(label, style: context.textStyles.labelLarge),
          ),
          const SizedBox(height: TokensSpacing.s),
          ChallengeTypeSelector(value: value, onChanged: onChanged),
          const SizedBox(height: TokensSpacing.m),
        ],
      ),
    );
  }
}

/// Selector de visibilidad del reto.
class ChallengeVisibilitySelector extends StatelessWidget {
  const ChallengeVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Visibility value;
  final ValueChanged<Visibility>? onChanged;

  @override
  Widget build(BuildContext context) => AppAdaptiveChoice<Visibility>(
    values: Visibility.values,
    selected: value,
    labelOf: (v) => v.challengeLabel(context),
    iconOf: (v) => v.challengeIcon,
    onChanged: onChanged,
  );
}

/// Desplegable de asignatura con la opción «Sin asignatura».
class ChallengeSubjectDropdown extends StatelessWidget {
  const ChallengeSubjectDropdown({
    super.key,
    required this.subjects,
    required this.value,
    required this.onChanged,
    this.fallbackName,
  });

  final List<ChallengeSubjectOption> subjects;
  final String? value;
  final ValueChanged<String?>? onChanged;

  /// Nombre a mostrar si [value] aún no está en [subjects].
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final options = [...subjects];
    final current = value;
    if (current != null && !options.any((s) => s.id == current)) {
      options.add(
        ChallengeSubjectOption(id: current, name: fallbackName ?? current),
      );
    }
    return DropdownButtonFormField<String?>(
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.challengesFieldSubject,
        prefixIcon: const Icon(Icons.menu_book_outlined),
      ),
      items: [
        DropdownMenuItem<String?>(child: Text(l10n.challengesFieldNoSubject)),
        for (final s in options)
          DropdownMenuItem<String?>(
            value: s.id,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Campo de fecha que abre el selector de fecha.
class ChallengeDateField extends StatelessWidget {
  const ChallengeDateField({
    super.key,
    required this.label,
    required this.text,
    required this.onTap,
    this.icon = Icons.event_outlined,
    this.onClear,
  });

  final String label;
  final String text;
  final VoidCallback? onTap;
  final IconData icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return AppFocusOutline(
      borderRadius: BorderRadius.circular(TokensRadius.m),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: onClear == null
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClear,
                  ),
          ),
          child: Text(text, style: context.textStyles.bodyLarge),
        ),
      ),
    );
  }
}

/// Abre el selector de fecha y devuelve el día elegido a las 23:59 (hora local).
Future<DateTime?> pickChallengeEndDate(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
}) async {
  final now = DateTime.now();
  final firstDate = first ?? DateTime(now.year, now.month, now.day);
  final picked = await showDatePicker(
    context: context,
    initialDate: initial.isBefore(firstDate) ? firstDate : initial,
    firstDate: firstDate,
    lastDate: DateTime(now.year + 3),
  );
  if (picked == null) return null;
  return DateTime(picked.year, picked.month, picked.day, 23, 59);
}
