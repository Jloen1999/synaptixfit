import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import 'training_labels.dart';

import '../../../theme/app_icons.dart';

/// Selector horizontal de semanas con botón opcional para añadir una. La
/// semana elegida se desplaza hasta quedar a la vista (con las fechas, las
/// pastillas son anchas y la semana 5 podría quedar fuera).
class WeekSelector extends StatefulWidget {
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
  State<WeekSelector> createState() => _WeekSelectorState();
}

class _WeekSelectorState extends State<WeekSelector> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(WeekSelector old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _revealSelected();
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _selectedKey.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: context.motion(TokensDuration.normal),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SizedBox(
      height: context.scaled(TokensLayout.minTouchTarget),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < widget.count; i++)
            Padding(
              key: i == widget.selected ? _selectedKey : null,
              padding: const EdgeInsets.only(right: TokensSpacing.xs),
              // «S2 · 3 nov – 9 nov» se lee «ese dos»: el lector oye
              // «Semana 2, 3 nov – 9 nov».
              child: Semantics(
                label: i < widget.ranges.length && widget.ranges[i] != null
                    ? l10n.trainingWeekSpoken(i + 1, widget.ranges[i]!)
                    : weekTitle(l10n, i + 1, null),
                selected: i == widget.selected,
                button: true,
                excludeSemantics: true,
                child: ChoiceChip(
                  selected: i == widget.selected,
                  avatar: widget.completed.contains(i)
                      ? const Icon(Icons.check_rounded, size: TokensSize.iconXs)
                      : null,
                  label: Text(
                    i < widget.ranges.length && widget.ranges[i] != null
                        ? l10n.trainingWeekChip(
                            l10n.trainingWeekShort(i + 1),
                            widget.ranges[i]!,
                          )
                        : l10n.trainingWeekShort(i + 1),
                  ),
                  tooltip: weekTitle(l10n, i + 1, null),
                  onSelected: (_) => widget.onSelected(i),
                ),
              ),
            ),
          if (widget.onAdd != null)
            ActionChip(
              avatar: const Icon(AppIcons.add, size: TokensSize.iconS),
              label: Text(l10n.trainingAddWeek),
              onPressed: widget.onAdd,
            ),
        ],
      ),
    );
  }
}
