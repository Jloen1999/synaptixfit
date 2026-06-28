import 'package:flutter/material.dart';

class SVChip extends StatelessWidget {
  const SVChip({
    required this.label,
    required this.selected,
    this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
