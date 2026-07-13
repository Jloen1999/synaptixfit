import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sv_colors.dart';
import '../../core/design_system/sv_shapes.dart';
import '../../features/academico/application/artefacto_efimero_provider.dart';
import '../../features/academico/application/generacion_global_provider.dart';

class BadgeGeneracionWidget extends ConsumerStatefulWidget {
  const BadgeGeneracionWidget({super.key});

  @override
  ConsumerState<BadgeGeneracionWidget> createState() =>
      _BadgeGeneracionWidgetState();
}

class _BadgeGeneracionWidgetState extends ConsumerState<BadgeGeneracionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _prevCompletado = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(artefactoEfimeroProvider, (prev, next) {
      if (next.tareaGlobalId == null) return;
      if (next.estado == EstadoGeneracion.completado) {
        ref.read(generacionGlobalProvider).completarTarea(next.tareaGlobalId!);
      } else if (next.estado == EstadoGeneracion.error) {
        ref.read(generacionGlobalProvider).fallarTarea(next.tareaGlobalId!);
      }
    });

    final global = ref.watch(generacionGlobalProvider);
    final tarea = global.tareaMasReciente;
    if (tarea == null) return const SizedBox.shrink();

    final acabaDeCompletar = tarea.completado && !_prevCompletado;
    _prevCompletado = tarea.completado;

    if (acabaDeCompletar) {
      _pulseCtrl.forward(from: 0);
    }

    final estaGenerando = tarea.estado == EstadoTareaGlobal.generando;
    final colorFondo = estaGenerando
        ? SVColors.primary
        : tarea.estado == EstadoTareaGlobal.completado
            ? const Color(0xFF2E7D32)
            : SVColors.error;

    final scale = _pulseCtrl.isAnimating || _pulseCtrl.isCompleted
        ? 1.0 + math.sin(_pulseCtrl.value * math.pi * 3) * 0.06
        : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: tarea.completado ? tarea.onNavigate : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colorFondo.withValues(alpha: 0.92),
                  borderRadius: SVShapes.pill,
                  boxShadow: [
                    BoxShadow(
                      color: colorFondo.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (estaGenerando)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (tarea.completado)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18)
                    else
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      estaGenerando
                          ? 'Generando ${tarea.etiqueta}…'
                          : tarea.completado
                              ? '${tarea.etiqueta} listo'
                              : 'Error en ${tarea.etiqueta}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (estaGenerando) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(artefactoEfimeroProvider.notifier)
                              .cancelar();
                          ref
                              .read(generacionGlobalProvider)
                              .eliminarTarea(tarea.id);
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
