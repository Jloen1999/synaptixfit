import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../domain/periodo_analitica.dart';
import '../../application/analitica_provider.dart';

// ---------------------------------------------------------------------------
// Fila de tres chips para seleccionar el periodo de analitica:
// Semanal (4s) | Mensual (12s) | Trimestral (52s).
// ---------------------------------------------------------------------------

class SelectorPeriodo extends ConsumerWidget {
  const SelectorPeriodo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoSeleccionadoProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: PeriodoAnalitica.values.map((p) {
        final selected = periodo == p;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ChoiceChip(
            label: Text(
              p.etiqueta,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? SVColors.onPrimary : SVColors.onSurfaceVariant,
              ),
            ),
            selected: selected,
            onSelected: (_) {
              ref.read(periodoSeleccionadoProvider.notifier).state = p;
            },
            selectedColor: SVColors.primary,
            backgroundColor: SVColors.surfaceContainerHighest,
            side: BorderSide(
              color: selected ? SVColors.primary : SVColors.outlineVariant,
              width: 1.5,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: SVShapes.pill,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }
}
