import 'package:flutter/material.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../domain/guia_docente_dto.dart';

class RastreadorTemarioWidget extends StatelessWidget {
  const RastreadorTemarioWidget({
    required this.temario,
    required this.colorAsignatura,
    required this.onToggleTema,
    super.key,
  });

  final List<TemaGuia> temario;
  final Color colorAsignatura;
  final void Function(int indice, bool completado) onToggleTema;

  @override
  Widget build(BuildContext context) {
    if (temario.isEmpty) return const SizedBox.shrink();

    final completados = temario.where((t) => t.completado).length;
    final progreso = temario.isNotEmpty ? completados / temario.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rastreador de temario',
                style: const TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Text(
              '$completados / ${temario.length}',
              style: TextStyle(
                color: colorAsignatura,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BarraProgresoCromatica(progreso: progreso, color: colorAsignatura),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: temario.length,
            itemBuilder: (context, i) {
              final tema = temario[i];
              return _TemaFila(
                indice: i,
                tema: tema,
                color: colorAsignatura,
                onToggle: onToggleTema,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BarraProgresoCromatica extends StatelessWidget {
  const _BarraProgresoCromatica({required this.progreso, required this.color});

  final double progreso;
  final Color color;

  Color _colorProgreso() {
    if (progreso >= 0.85) return const Color(0xFF2E7D32);
    if (progreso >= 0.60) return const Color(0xFF7CB342);
    if (progreso >= 0.35) return const Color(0xFFF9A825);
    if (progreso >= 0.10) return const Color(0xFFEF6C00);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _colorProgreso();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 8,
            backgroundColor: barColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progreso * 100).toStringAsFixed(0)}% del temario dominado',
          style: TextStyle(
            color: barColor.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TemaFila extends StatelessWidget {
  const _TemaFila({
    required this.indice,
    required this.tema,
    required this.color,
    required this.onToggle,
  });

  final int indice;
  final TemaGuia tema;
  final Color color;
  final void Function(int indice, bool completado) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: indice > 0
            ? const Border(
                top: BorderSide(color: SVColors.outlineVariant, width: 0.5))
            : null,
      ),
      child: _DeslizableFila(
        onSwipe: () => onToggle(indice, !tema.completado),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              _CirculoEstado(
                completado: tema.completado,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tema.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tema.completado
                            ? SVColors.onSurfaceMuted
                            : SVColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration:
                            tema.completado ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tema.tipo.etiqueta,
                      style: TextStyle(
                        color: tema.completado
                            ? SVColors.outline
                            : color.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (tema.completado)
                Icon(Icons.check_circle,
                    size: 20, color: color.withValues(alpha: 0.6))
              else
                Icon(Icons.swipe_rounded,
                    size: 16, color: SVColors.outline.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CirculoEstado extends StatelessWidget {
  const _CirculoEstado({required this.completado, required this.color});

  final bool completado;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completado ? color : Colors.transparent,
        border: Border.all(
          color: completado ? color : SVColors.outline,
          width: 2,
        ),
      ),
      child: completado
          ? const Icon(Icons.check, size: 16, color: SVColors.onPrimary)
          : null,
    );
  }
}

class _DeslizableFila extends StatefulWidget {
  const _DeslizableFila({required this.child, required this.onSwipe});

  final Widget child;
  final VoidCallback onSwipe;

  @override
  State<_DeslizableFila> createState() => _DeslizableFilaState();
}

class _DeslizableFilaState extends State<_DeslizableFila> {
  static const _umbral = 60.0;
  double _distanciaTotal = 0;
  double _backgroundOpacity = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) {
        setState(() {
          _distanciaTotal = 0;
          _backgroundOpacity = 0;
        });
      },
      onHorizontalDragUpdate: (d) {
        setState(() {
          _distanciaTotal += d.delta.dx;
          _backgroundOpacity = (_distanciaTotal.abs() / 200).clamp(0.0, 0.3);
        });
      },
      onHorizontalDragEnd: (d) {
        if (_distanciaTotal.abs() >= _umbral) {
          widget.onSwipe();
        }
        setState(() {
          _distanciaTotal = 0;
          _backgroundOpacity = 0;
        });
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _backgroundOpacity,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: _distanciaTotal > 0
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
