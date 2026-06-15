import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bienestar/application/rutina_provider.dart';

/// Barra compacta que muestra el progreso semanal del plan activo.
class PlanWeekBar extends ConsumerWidget {
  const PlanWeekBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinaId = ref.watch(rutinaActivaSeleccionadaProvider);
    if (rutinaId == null) return const SizedBox.shrink();

    final semanasAsync = ref.watch(semanasDeRutinaProvider(rutinaId));
    final cs = Theme.of(context).colorScheme;

    return semanasAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (semanas) {
        if (semanas.isEmpty) return const SizedBox.shrink();
        final total = semanas.length;
        final ahora = DateTime.now();

        // Calcular semana actual basado en tiempo transcurrido desde la
        // creación de la primera semana. Cada semana del plan dura 7 días reales.
        final primeraSemana = semanas.first;
        final inicio = primeraSemana.creadoEn;
        final semanasTranscurridas =
            (ahora.difference(inicio).inDays / 7).ceil().clamp(1, 999);
        final actual = semanasTranscurridas.clamp(1, total);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Semana $actual de $total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: actual / total,
                    backgroundColor: cs.primaryContainer,
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
