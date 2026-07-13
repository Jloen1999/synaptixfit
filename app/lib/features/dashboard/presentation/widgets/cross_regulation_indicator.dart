import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bienestar/application/neurofisiologia_provider.dart';

/// Indicador de regulación cruzada para la cabecera del Dashboard.
///
/// Muestra alertas de fatiga física (ACWR), proximidad de exámenes,
/// y el tope de estudio recomendado. Solo visible cuando hay una
/// condición que requiere atención.
///
/// Flat Design: sin sombras, fondo de baja opacidad, altura fija 48px.
class CrossRegulationIndicator extends ConsumerWidget {
  const CrossRegulationIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cross = ref.watch(estadoRegulacionCruzadaProvider).valueOrNull;
    if (cross == null) return const SizedBox.shrink();

    final acwr = cross.acwrActual;
    final diasExamen = cross.diasProximoExamen;
    final tMax = cross.minEstudioMaxRecomendado;

    final tieneFatiga = acwr > 1.3;
    final tieneExamen = diasExamen != null && diasExamen < 7;

    if (!tieneFatiga && !tieneExamen) return const SizedBox.shrink();

    final colorFondo = acwr > 1.5
        ? Colors.red.withOpacity(0.08)
        : Colors.amber.withOpacity(0.08);
    final colorTexto = acwr > 1.5 ? Colors.red.shade300 : Colors.amber.shade700;

    final mensajes = <String>[];
    if (tieneFatiga) {
      mensajes.add('Fatiga detectada');
    }
    if (tieneExamen) {
      mensajes.add('Examen en $diasExamen d');
    }
    if (tMax < 90) {
      mensajes.add('Tope de estudio: $tMax min');
    }

    return SizedBox(
      height: 48,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              tieneFatiga ? Icons.fitness_center_rounded : Icons.school_rounded,
              size: 18,
              color: colorTexto,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensajes.join(' · '),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorTexto,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
