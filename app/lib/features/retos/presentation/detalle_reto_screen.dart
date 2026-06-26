import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/exercise_metrics.dart';
import '../../bienestar/infrastructure/calorie_calculator_service.dart';
import '../../perfil/application/perfil_provider.dart';
import '../application/retos_provider.dart';

class DetalleRetoScreen extends ConsumerWidget {
  const DetalleRetoScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(retoDetalleProvider(id));

    ref.listen(retoDetalleProvider(id), (prev, next) {
      final data = next.valueOrNull;
      if (data != null &&
          data.progresoGeneral >= 1.0 &&
          !data.reto.estaCompletado &&
          _esPropio(data.reto.usuarioId)) {
        completarReto(id, ref).then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Reto completado automáticamente!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: SVColors.background,
      body: detalleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: SVColors.onSurface)),
        ),
        data: (detalle) {
          if (detalle == null) {
            return const Center(
              child: Text('Reto no encontrado',
                  style: TextStyle(color: SVColors.onSurface)),
            );
          }

          final esPropio = _esPropio(detalle.reto.usuarioId);
          final completado = detalle.reto.estaCompletado;
          final tipoLabel =
              detalle.reto.tipo == 'fitness' ? 'Fitness' : 'Académico';
          final tipoColor = detalle.reto.tipo == 'fitness'
              ? const Color(0xFF2E7D32)
              : const Color(0xFF1976D2);

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CabeceraPlana(
                  titulo: detalle.reto.titulo,
                  tipoLabel: tipoLabel,
                  tipoColor: tipoColor,
                  completado: completado,
                  esPropio: esPropio,
                  onVolver: () => context.pop(),
                  onDesmarcar: esPropio && completado
                      ? () async => await descompletarReto(id, ref)
                      : null,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      const SizedBox(height: 10),
                      if (detalle.hitos.isNotEmpty)
                        _BarraProgresoPlana(progreso: detalle.progresoGeneral),
                      if (detalle.hitos.isNotEmpty) const SizedBox(height: 6),
                      if (detalle.reto.meta.isNotEmpty) ...[
                        Text(
                          detalle.reto.meta,
                          style: const TextStyle(
                            color: SVColors.onSurface,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _FilaMetadatos(
                        inicio: detalle.reto.fechaInicio,
                        fin: detalle.reto.fechaFin,
                        visibilidad: detalle.reto.visibilidad,
                      ),
                      if (detalle.reto.tipo == 'fitness') ...[
                        const SizedBox(height: 10),
                        _FilaCaloriasEstimadas(
                          hitos: detalle.hitos,
                          completado: completado,
                          pesoUsuarioKg: ref
                              .watch(perfilUsuarioProvider)
                              .valueOrNull
                              ?.perfil
                              .pesoKg,
                        ),
                      ],
                      if (detalle.hitos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text(
                              'Tareas',
                              style: TextStyle(
                                color: SVColors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${detalle.hitos.where((h) => h.estaCompletado).length} / ${detalle.hitos.length}',
                              style: TextStyle(
                                color: tipoColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(detalle.hitos.length, (i) {
                          final hito = detalle.hitos[i];
                          return _TareaDeslizable(
                            key: ValueKey(hito.id),
                            hito: hito,
                            color: tipoColor,
                            editable: esPropio && !completado,
                            onToggle: esPropio && !completado
                                ? () async {
                                    HapticFeedback.mediumImpact();
                                    await toggleTareaCompletada(
                                      hito.id,
                                      id,
                                      completada: !hito.estaCompletado,
                                      ref: ref,
                                    );
                                  }
                                : null,
                          );
                        }),
                      ],
                      if (!completado && esPropio) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Marcar como completado'),
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: SVColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                                borderRadius: SVShapes.standard12),
                          ),
                          onPressed: () => _confirmarCompletar(context, ref),
                        ),
                      ],
                      if (!esPropio) ...[
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Clonar reto a mi perfil'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SVColors.primary,
                            side: BorderSide(
                                color: SVColors.primary.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                                borderRadius: SVShapes.standard12),
                          ),
                          onPressed: () => _clonar(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _esPropio(String usuarioId) {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id == usuarioId;
  }

  void _confirmarCompletar(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar reto'),
        content: const Text(
            '¿Marcar este reto como completado? No se podrá editar después.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await completarReto(id, ref);
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  void _clonar(BuildContext context, WidgetRef ref) async {
    final nuevoId = await clonarReto(id, ref);
    if (nuevoId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reto clonado correctamente')),
      );
      context.go('/retos/$nuevoId');
    }
  }
}

class _CabeceraPlana extends StatelessWidget {
  const _CabeceraPlana({
    required this.titulo,
    required this.tipoLabel,
    required this.tipoColor,
    required this.completado,
    required this.esPropio,
    required this.onVolver,
    this.onDesmarcar,
  });

  final String titulo;
  final String tipoLabel;
  final Color tipoColor;
  final bool completado;
  final bool esPropio;
  final VoidCallback onVolver;
  final VoidCallback? onDesmarcar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onVolver,
            icon:
                const Icon(Icons.arrow_back, color: SVColors.onSurfaceVariant),
            tooltip: 'Volver',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tipoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tipoLabel,
                        style: TextStyle(
                          color: tipoColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (completado) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Completado',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (esPropio && completado && onDesmarcar != null)
            TextButton(
              onPressed: onDesmarcar,
              child: const Text(
                'Desmarcar',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarraProgresoPlana extends StatelessWidget {
  const _BarraProgresoPlana({required this.progreso});

  final double progreso;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 6,
            backgroundColor: SVColors.primary.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(SVColors.primary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Progreso general: ${(progreso * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: SVColors.primary.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FilaMetadatos extends StatelessWidget {
  const _FilaMetadatos({
    required this.inicio,
    required this.fin,
    required this.visibilidad,
  });

  final DateTime inicio;
  final DateTime fin;
  final String visibilidad;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        borderRadius: SVShapes.standard12,
      ),
      child: Row(
        children: [
          _ItemMeta(
              icono: Icons.calendar_today,
              label: 'Inicio',
              valor: fmt.format(inicio)),
          const SizedBox(width: 20),
          _ItemMeta(
              icono: Icons.flag_outlined, label: 'Fin', valor: fmt.format(fin)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: visibilidad == 'public'
                  ? SVColors.accent.withValues(alpha: 0.12)
                  : SVColors.outlineVariant.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              visibilidad == 'public' ? 'Público' : 'Privado',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: visibilidad == 'public'
                    ? SVColors.accent
                    : SVColors.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemMeta extends StatelessWidget {
  const _ItemMeta({
    required this.icono,
    required this.label,
    required this.valor,
  });

  final IconData icono;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: SVColors.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: SVColors.onSurfaceMuted),
        ),
        Text(
          valor,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: SVColors.onSurface),
        ),
      ],
    );
  }
}

class _TareaDeslizable extends StatefulWidget {
  const _TareaDeslizable({
    required this.hito,
    required this.color,
    required this.editable,
    this.onToggle,
    super.key,
  });

  final HitoRetoDb hito;
  final Color color;
  final bool editable;
  final VoidCallback? onToggle;

  @override
  State<_TareaDeslizable> createState() => _TareaDeslizableState();
}

class _TareaDeslizableState extends State<_TareaDeslizable> {
  static const _umbral = 60.0;
  double _distanciaTotal = 0;

  @override
  Widget build(BuildContext context) {
    final completado = widget.hito.estaCompletado;

    return GestureDetector(
      onTap: widget.editable ? widget.onToggle : null,
      onHorizontalDragStart: (_) => _distanciaTotal = 0,
      onHorizontalDragUpdate: (d) {
        _distanciaTotal += d.delta.dx;
        if (!widget.editable) return;
        setState(() {});
      },
      onHorizontalDragEnd: (d) {
        if (_distanciaTotal.abs() >= _umbral && widget.editable) {
          widget.onToggle?.call();
          HapticFeedback.mediumImpact();
        }
        _distanciaTotal = 0;
        setState(() {});
      },
      child: AnimatedOpacity(
        opacity: completado ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _distanciaTotal.abs() / 200 > 0.05
                ? const Color(0xFF2E7D32)
                    .withValues(alpha: _distanciaTotal.abs() / 400)
                : SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completado ? widget.color : Colors.transparent,
                  border: Border.all(
                    color: completado ? widget.color : SVColors.outline,
                    width: 2,
                  ),
                ),
                child: completado
                    ? const Icon(Icons.check,
                        size: 14, color: SVColors.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.hito.titulo,
                      style: TextStyle(
                        color: completado
                            ? SVColors.onSurfaceMuted
                            : SVColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration:
                            completado ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.hito.porcentajePeso}% del total',
                      style: TextStyle(
                        color: completado
                            ? SVColors.outline
                            : SVColors.onSurfaceMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.editable && !completado)
                Icon(Icons.swipe_rounded,
                    size: 14, color: SVColors.outline.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de calorías estimadas para retos de tipo fitness.
///
/// Calcula el gasto calórico total iterando sobre los hitos (o el reto
/// completo si no tiene hitos) usando la fórmula MET:
///   Σ (MET × Peso × Tiempo) + Σ (1.5 × Peso × Descanso)
///
/// Si el reto no tiene hitos se estima una duración por defecto de 30 min.
class _FilaCaloriasEstimadas extends StatelessWidget {
  const _FilaCaloriasEstimadas({
    required this.hitos,
    required this.completado,
    this.pesoUsuarioKg,
  });

  final List<HitoRetoDb> hitos;
  final bool completado;
  final double? pesoUsuarioKg;

  static double _metDesdeDificultad(String dificultad) => switch (dificultad) {
        'alta' => 8.0,
        'baja' => 3.0,
        _ => 4.5, // media
      };

  static int _segundosDesdeDificultad(String dificultad) =>
      switch (dificultad) {
        'alta' => 1800, // 30 min
        'baja' => 600, // 10 min
        _ => 1200, // 20 min (media)
      };

  @override
  Widget build(BuildContext context) {
    double totalKcal = 0;

    if (hitos.isEmpty) {
      totalKcal = CalorieCalculatorService.calcular(
        valorMet: _metDesdeDificultad('media'),
        pesoUsuarioKg: pesoUsuarioKg,
        duracionSegundos: 1800, // 30 min por defecto
      );
    } else {
      for (final hito in hitos) {
        final met = _metDesdeDificultad(hito.dificultad);
        final dur = _segundosDesdeDificultad(hito.dificultad);
        totalKcal += CalorieCalculatorService.calcular(
          valorMet: met,
          pesoUsuarioKg: pesoUsuarioKg,
          duracionSegundos: dur,
        );
        totalKcal += CalorieCalculatorService.calcularDescanso(
          pesoUsuarioKg: pesoUsuarioKg,
          duracionSegundos: 300, // 5 min de descanso entre tareas
        );
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SemantiCalorieChip(calorias: totalKcal),
    );
  }
}
