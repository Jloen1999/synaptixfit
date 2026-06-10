import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bienestar/application/rutina_provider.dart';

/// Barra horizontal que muestra el nivel de carga cognitiva actual.
class CognitiveLoadBar extends ConsumerWidget {
  const CognitiveLoadBar({super.key});

  Color _colorForValue(double v) {
    if (v < 30) return const Color(0xFF2E7D32);
    if (v < 60) return const Color(0xFFF5A623);
    if (v < 80) return const Color(0xFFE8A838);
    return const Color(0xFFBA1A1A);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carga = ref.watch(cargaCognitivaProvider);
    final cs = Theme.of(context).colorScheme;

    return carga.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final color = _colorForValue(data.valor);

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
                    Text(data.nivelLabel,
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
                    value: data.valor / 100,
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
