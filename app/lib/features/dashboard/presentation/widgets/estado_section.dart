import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bienestar/application/rutina_provider.dart';
import '../../../../shared/widgets/metric_gauge.dart';
import '../../../../shared/widgets/dashboard_dialogs.dart';

/// Sección de métricas de estado actual: Energía, Adherencia y Estudio.
///
/// Muestra gauges radiales con animación. Se oculta si no hay datos
/// de ningún componente (energético, adherencia o carga académica).
class EstadoSection extends ConsumerWidget {
  const EstadoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adherenciaComp = ref.watch(adherenciaAcademicaProvider).valueOrNull;
    final energiaComp = ref.watch(estadoEnergeticoProvider).valueOrNull;
    final carga = ref.watch(cargaAcademicaSemanalProvider).valueOrNull;

    if (adherenciaComp == null && energiaComp == null && carga == null) {
      return const SizedBox.shrink();
    }

    final adherencia = adherenciaComp?.valor ?? 0;
    final energia = energiaComp?.valor ?? 0;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String? energiaAlert(double v, bool tieneDatos) {
      if (!tieneDatos) return 'Pendiente de check-in';
      if (v < 30) return 'Descanso recomendado';
      if (v < 50) return 'Intensidad baja';
      return null;
    }

    String? adherenciaAlert(double v, bool tieneDatos) {
      if (!tieneDatos) return 'Sin datos académicos';
      if (v < 40) return 'Necesita atención';
      if (v < 70) return 'En progreso';
      return null;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.08),
        ),
      ),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Estado actual',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final count = (carga != null ? 3 : 2);
                final gaps = (count - 1) * 8;
                final gaugeSize = ((constraints.maxWidth - gaps) / count)
                    .floorToDouble()
                    .clamp(70.0, 100.0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => mostrarDialogoEnergia(context, energiaComp),
                      child: MetricGauge(
                        value: energia,
                        label: 'Energético',
                        alert: energiaAlert(energia, energiaComp != null),
                        size: gaugeSize,
                      ),
                    ),
                    if (count > 1) const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () =>
                          mostrarDialogoAdherencia(context, adherenciaComp),
                      child: MetricGauge(
                        value: adherencia,
                        label: 'Adherencia',
                        subtitle: 'Academica',
                        alert:
                            adherenciaAlert(adherencia, adherenciaComp != null),
                        size: gaugeSize,
                      ),
                    ),
                    if (count > 2) const SizedBox(width: 10),
                    if (carga != null)
                      GestureDetector(
                        onTap: () => mostrarDialogoEstudio(context, carga),
                        child: MetricGauge(
                          value: (carga.horasEstudioReales /
                                  carga.horasEstudioPlaneadas.clamp(1, 120) *
                                  100)
                              .clamp(0, 100),
                          label: 'Estudio',
                          subtitle:
                              '${carga.horasEstudioReales}/${carga.horasEstudioPlaneadas}h',
                          size: gaugeSize,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
