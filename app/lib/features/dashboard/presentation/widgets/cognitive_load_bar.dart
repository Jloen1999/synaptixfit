import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bienestar/application/neurofisiologia_provider.dart';

/// Barra horizontal que muestra la capacidad atencional actual del usuario.
///
/// Lee de estado_cognitivo_usuario.capacidad_atencion_actual (0.000–1.000),
/// calculada con la fórmula de decaimiento exponencial A(t)=A₀·e^(−β·t).
class CognitiveLoadBar extends ConsumerWidget {
  const CognitiveLoadBar({super.key});

  Color _colorForValue(double v) {
    if (v < 30) return const Color(0xFF2E7D32);
    if (v < 60) return const Color(0xFFF5A623);
    if (v < 80) return const Color(0xFFE8A838);
    return const Color(0xFFBA1A1A);
  }

  String _labelForValue(double v) {
    if (v < 30) return 'Baja';
    if (v < 60) return 'Moderada';
    if (v < 80) return 'Alta';
    return 'Crítica';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cogState = ref.watch(estadoCognitivoProvider);
    final cs = Theme.of(context).colorScheme;

    return cogState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (state == null) return const SizedBox.shrink();
        final valor = (state.capacidadAtencionActual * 100).clamp(0.0, 100.0);
        final color = _colorForValue(valor);

        return Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text('Carga cognitiva',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                    const Spacer(),
                    Text(_labelForValue(valor),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: valor / 100,
                    backgroundColor: color.withAlpha(30),
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
