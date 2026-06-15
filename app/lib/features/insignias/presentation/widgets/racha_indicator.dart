import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/insignias_provider.dart';
import '../../domain/insignia_dto.dart';

/// Widget que muestra la racha actual con barra de progreso y alerta de riesgo.
class RachaIndicator extends StatelessWidget {
  const RachaIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final rachaAsync = ref.watch(rachaStateProvider);

        return rachaAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => const SizedBox.shrink(),
          data: (racha) => _buildIndicator(context, racha),
        );
      },
    );
  }

  Widget _buildIndicator(BuildContext context, RachaState racha) {
    final dias = racha.diasConsecutivos;
    final hoyTieneActividad = !racha.enRiesgo || dias == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: racha.enRiesgo
              ? const Color(0xFFF97316).withValues(alpha: 0.4)
              : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila principal: icono + contador
          Row(
            children: [
              // Ícono de fuego
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                  ),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Racha actual',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dias día${dias == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF1F5F9),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Indicador de hoy completado
              if (hoyTieneActividad && dias > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: Color(0xFF4ADE80)),
                      SizedBox(width: 4),
                      Text(
                        '¡Hoy completado!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Alerta de riesgo
          if (racha.enRiesgo) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF97316).withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded,
                      size: 16, color: Color(0xFFF97316)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡No pierdas tu racha! Completa una actividad hoy.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Barra de progreso hacia el próximo hito
          if (racha.proximoHito != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Día $dias de ${racha.etiquetaProximoHito}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(racha.progresoHito * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: racha.progresoHito,
                minHeight: 6,
                backgroundColor: const Color(0xFF334155),
                valueColor: AlwaysStoppedAnimation<Color>(
                  racha.proximoHito == 100
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFF97316),
                ),
              ),
            ),
          ],

          // Mejor racha histórica
          if (racha.mejorRacha > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'Récord: ${racha.mejorRacha} días',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
