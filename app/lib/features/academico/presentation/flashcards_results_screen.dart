import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/models/db_models.dart';

class FlashcardResultsScreen extends ConsumerWidget {
  const FlashcardResultsScreen({
    required this.materialId,
    required this.dominadas,
    required this.dudosas,
    required this.falladas,
    required this.total,
    required this.falladasIds,
    required this.preguntas,
    super.key,
  });

  final String materialId;
  final int dominadas;
  final int dudosas;
  final int falladas;
  final int total;
  final List<int> falladasIds;
  final List<PreguntaDb> preguntas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpGanado = (dominadas * 3) + (dudosas * 1);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SVColors.background,
        appBar: AppBar(
          title: const Text('Resultados',
              style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
          backgroundColor: SVColors.background,
          surfaceTintColor: SVColors.background,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(xpGanado),
                const SizedBox(height: 28),
                _buildMetricasGrid(),
                const SizedBox(height: 28),
                _buildProximoRepaso(ref),
                const SizedBox(height: 32),
                if ((dudosas + falladas) > 0) ...[
                  _buildBotonRepasarFalladas(context),
                  const SizedBox(height: 12),
                ],
                _buildBotonVolverTemario(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(int xpGanado) {
    return Column(children: [
      const SizedBox(height: 12),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (_, v, __) => Transform.scale(
          scale: v,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF4CAF50), size: 40),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text('¡Buen trabajo!',
          style: TextStyle(
              color: SVColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('Has completado la sesión de flashcards.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: SVColors.onSurfaceMuted, fontSize: 14, height: 1.4)),
      if (xpGanado > 0) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: SVShapes.standard12,
            border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 6),
            Text('+$xpGanado XP añadidos a tu perfil',
                style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildMetricasGrid() {
    return Row(children: [
      Expanded(
        child: _metricaCard(
          'Dominadas',
          '$dominadas',
          const Color(0xFF4CAF50),
          Icons.check_circle_outline_rounded,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _metricaCard(
          'Con dudas',
          '$dudosas',
          const Color(0xFFF59E0B),
          Icons.help_outline_rounded,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _metricaCard(
          'Falladas',
          '$falladas',
          const Color(0xFFEF5350),
          Icons.close_rounded,
        ),
      ),
    ]);
  }

  Widget _metricaCard(String label, String valor, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: SVShapes.large16,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(valor,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: SVColors.onSurfaceMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildProximoRepaso(WidgetRef ref) {
    return FutureBuilder<String>(
      future: _calcularProximoRepaso(),
      builder: (_, snap) {
        final texto = snap.data ?? 'Calculando...';
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SVColors.primary.withValues(alpha: 0.06),
            borderRadius: SVShapes.large16,
            border: Border.all(color: SVColors.primary.withValues(alpha: 0.12)),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SVColors.primary.withValues(alpha: 0.12),
                borderRadius: SVShapes.standard12,
              ),
              child: const Icon(Icons.schedule_rounded,
                  color: SVColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Próximo repaso programado',
                      style: TextStyle(
                          color: SVColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(texto,
                      style: const TextStyle(
                          color: SVColors.onSurfaceMuted,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<String> _calcularProximoRepaso() async {
    try {
      final client = Supabase.instance.client;
      final result = await client
          .from('materiales_estudio')
          .select('siguiente_repaso_en, estado_dominio, intervalo_actual_dias')
          .eq('id', materialId)
          .maybeSingle();
      if (result == null) return 'Repaso pendiente de programar.';
      final fecha = result['siguiente_repaso_en'] as String?;
      final intervalo = result['intervalo_actual_dias'] as int? ?? 1;
      if (fecha == null) return 'Repaso pendiente de programar.';

      final dt = DateTime.parse(fecha);
      final hoy = DateTime.now();
      final diff = dt.difference(DateTime(hoy.year, hoy.month, hoy.day));
      final dias = diff.inDays;

      final f = DateFormat("EEEE d 'de' MMMM 'a las' HH:mm", 'es').format(dt);

      if (dias == 0)
        return 'Hemos programado tu próximo repaso para hoy a las ${DateFormat('HH:mm', 'es').format(dt)}.';
      if (dias == 1) {
        return 'Basado en tus resultados, hemos programado tu próximo repaso para mañana a las ${DateFormat('HH:mm', 'es').format(dt)}.';
      }
      return 'Basado en tus resultados, hemos programado tu próximo repaso para $f. Intervalo actual: $intervalo días.';
    } catch (_) {
      return 'Repaso pendiente de programar.';
    }
  }

  Widget _buildBotonRepasarFalladas(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.pushReplacement('/academico/flashcards/$materialId/revision',
              extra: falladasIds);
        },
        icon: const Icon(Icons.replay_rounded, size: 20),
        label: const Text('Repasar falladas ahora',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF5350),
          side: const BorderSide(color: Color(0xFFEF5350)),
          shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12),
        ),
      ),
    );
  }

  Widget _buildBotonVolverTemario(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.pop();
        },
        icon: const Icon(Icons.menu_book_outlined, size: 20),
        label: const Text('Volver al Temario',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: SVColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12),
        ),
      ),
    );
  }
}
