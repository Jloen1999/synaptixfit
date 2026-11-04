import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'training_labels.dart';

/// Selector horizontal de semanas con botón opcional para añadir una.
class WeekSelector extends StatelessWidget {
  const WeekSelector({
    super.key,
    required this.count,
    required this.selected,
    required this.onSelected,
    this.onAdd,
    this.completed = const {},
    this.ranges = const [],
  });

  final int count;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback? onAdd;

  /// Índices de semanas completadas (se marcan con un icono).
  final Set<int> completed;

  /// Fechas de cada semana («3 nov – 9 nov»), si las tiene.
  final List<String?> ranges;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SizedBox(
      height: context.scaled(TokensLayout.minTouchTarget),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(right: TokensSpacing.xs),
              child: ChoiceChip(
                selected: i == selected,
                avatar: completed.contains(i)
                    ? const Icon(Icons.check_rounded, size: 16)
                    : null,
                label: Text(
                  i < ranges.length && ranges[i] != null
                      ? l10n.trainingWeekChip(
                          l10n.trainingWeekShort(i + 1),
                          ranges[i]!,
                        )
                      : l10n.trainingWeekShort(i + 1),
                ),
                tooltip: weekTitle(l10n, i + 1, null),
                onSelected: (_) => onSelected(i),
              ),
            ),
          if (onAdd != null)
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.trainingAddWeek),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}
