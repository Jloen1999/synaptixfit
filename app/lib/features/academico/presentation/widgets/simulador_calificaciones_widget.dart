import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../domain/guia_docente_dto.dart';

class SimuladorCalificacionesWidget extends StatefulWidget {
  const SimuladorCalificacionesWidget({
    required this.evaluacion,
    required this.colorAsignatura,
    required this.onNotaCambiada,
    super.key,
  });

  final List<CriterioEvaluacion> evaluacion;
  final Color colorAsignatura;
  final void Function(int indice, double? nota) onNotaCambiada;

  @override
  State<SimuladorCalificacionesWidget> createState() =>
      _SimuladorCalificacionesWidgetState();
}

class _SimuladorCalificacionesWidgetState
    extends State<SimuladorCalificacionesWidget> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.evaluacion.length; i++) {
      final c = widget.evaluacion[i];
      _controllers[i] = TextEditingController(
        text: c.notaObtenida?.toString() ?? '',
      );
      _focusNodes[i] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  double? _parseNota(String valor) {
    final trimmed = valor.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    final n = double.tryParse(trimmed);
    if (n == null || n < 0 || n > 10) return null;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.evaluacion.isEmpty) return const SizedBox.shrink();

    final estado = GuiaDocenteDto(
      profesores: const [],
      temario: const [],
      evaluacion: List.generate(widget.evaluacion.length, (i) {
        final text = _controllers[i]?.text ?? '';
        return widget.evaluacion[i].copyWith(notaObtenida: _parseNota(text));
      }),
    ).estadoCalculadora;

    final notaEstimada = estado.notaEstimada;
    final porcentajeCubierto = estado.porcentajeCubierto;
    final mensaje = estado.mensaje;
    final color = widget.colorAsignatura;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Simulador de calificaciones',
            style: TextStyle(
              color: SVColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    notaEstimada.toStringAsFixed(1),
                    style: TextStyle(
                      color: color,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '/ 10',
                    style: TextStyle(
                      color: SVColors.onSurfaceMuted,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (porcentajeCubierto > 0)
                    Text(
                      '${porcentajeCubierto.toStringAsFixed(0)}% cubierto',
                      style: const TextStyle(
                        color: SVColors.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Nota actual estimada',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (mensaje != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SVColors.accentContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: SVColors.onAccentContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ...List.generate(widget.evaluacion.length, (i) {
                final c = widget.evaluacion[i];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i < widget.evaluacion.length - 1 ? 10 : 0),
                  child: _FilaCriterio(
                    nombre: c.nombre,
                    porcentaje: c.porcentaje,
                    controller: _controllers[i]!,
                    focusNode: _focusNodes[i]!,
                    color: color,
                    onChanged: (v) {
                      final nota = _parseNota(v);
                      widget.onNotaCambiada(i, nota);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaCriterio extends StatelessWidget {
  const _FilaCriterio({
    required this.nombre,
    required this.porcentaje,
    required this.controller,
    required this.focusNode,
    required this.color,
    required this.onChanged,
  });

  final String nombre;
  final double porcentaje;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SVColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${porcentaje.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 54,
          height: 36,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              LengthLimitingTextInputFormatter(4),
            ],
            style: const TextStyle(
              color: SVColors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              hintText: '0-10',
              hintStyle: const TextStyle(
                color: SVColors.outline,
                fontSize: 12,
              ),
              filled: true,
              fillColor: SVColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
