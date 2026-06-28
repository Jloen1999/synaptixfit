import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/calendar_dtos.dart';
import '../../infrastructure/grid_math.dart';

/// Widget de bloque de tiempo con diseño plano (Flat Design).
/// Sin títulos — el tipo se infiere del icono, borde de color y contenido.
///
/// Umbrales de LayoutBuilder:
/// - < 40px: Solo icono centrado
/// - 40-70px: Icono + contenido compacto + duración
/// - > 70px: Icono + contenido expandido + badge duración
class TimeBlockWidget extends StatefulWidget {
  const TimeBlockWidget({
    required this.block,
    required this.onResize,
    this.columnWidthOverride,
    this.isDragging = false,
    this.onTap,
    super.key,
  });

  final TimeBlock block;
  final ValueChanged<double> onResize;
  final double? columnWidthOverride;
  final bool isDragging;
  final VoidCallback? onTap;

  @override
  State<TimeBlockWidget> createState() => _TimeBlockWidgetState();
}

class _TimeBlockWidgetState extends State<TimeBlockWidget> {
  bool _isResizing = false;
  double _currentHeight = 0;

  bool get _puedeRedimensionar => !widget.block.esFijo;

  @override
  void initState() {
    super.initState();
    _currentHeight = GridMath.duracionToHeight(
        widget.block.horaInicio, widget.block.horaFin);
  }

  @override
  void didUpdateWidget(covariant TimeBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isResizing) {
      _currentHeight = GridMath.duracionToHeight(
          widget.block.horaInicio, widget.block.horaFin);
    }
  }

  String _duracionTooltip() {
    final newMinutes = (_currentHeight / GridConstants.pixelsPerHour * 60)
        .round()
        .clamp(30, 240);
    final snappedMinutes = (newMinutes / 30).round() * 30;
    final h = snappedMinutes ~/ 60;
    final m = snappedMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  // ──────────────────────────────────────────────────────
  // Colors — un color distinto por tipo de bloque
  // ──────────────────────────────────────────────────────

  static const _typeColors = <TimeBlockTipo, Color>{
    TimeBlockTipo.estudio: Color(0xFF4A90D9),
    TimeBlockTipo.examen: Color(0xFFD97706),
    TimeBlockTipo.entrega: Color(0xFFDC2626),
    TimeBlockTipo.deporte: Color(0xFF059669),
    TimeBlockTipo.clase: Color(0xFF64748B),
    TimeBlockTipo.descanso: Color(0xFF14B8A6),
    TimeBlockTipo.comida: Color(0xFFF97316),
    TimeBlockTipo.sueno: Color(0xFF6366F1),
  };

  Color _backgroundColor(TimeBlock block) {
    final base = _typeColors[block.tipo] ?? const Color(0xFF4A90D9);
    if (block.esFijo) return base.withValues(alpha: 0.75);
    if (block.esSugerencia) return base.withValues(alpha: 0.5);
    return base.withValues(alpha: 0.88);
  }

  Color get _textColor => Colors.white;
  Color get _faintColor => Colors.white.withValues(alpha: 0.75);

  // ──────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final height = _isResizing
        ? _currentHeight
        : GridMath.duracionToHeight(block.horaInicio, block.horaFin);
    final colW = widget.columnWidthOverride ?? GridConstants.columnWidth;
    final width = colW - 4;

    if (height <= 0) return const SizedBox.shrink();

    final isDragging = widget.isDragging;

    Widget child = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _backgroundColor(block),
        borderRadius: BorderRadius.circular(8),
        border: isDragging
            ? Border.all(color: Colors.white, width: 1.5)
            : block.esSugerencia
                ? Border.all(
                    color: _typeColors[block.tipo] ?? Colors.blue, width: 1.5)
                : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final isTiny = h < 40;
          final isSmall = h >= 40 && h < 70;
          return _buildContent(block, isTiny, isSmall);
        },
      ),
    );

    // Indicador visual de bloque completado: atenuado + check verde.
    if (block.completado) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(opacity: 0.55, child: child),
          Positioned(
            top: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      );
    }

    Widget interactiveChild = child;
    if (widget.onTap != null) {
      interactiveChild = InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    }

    if (block.esFijo) {
      return Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 300)),
          SlideEffect(
            begin: Offset(0, -0.05),
            end: Offset.zero,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        ],
        child: interactiveChild,
      );
    }

    if (!_puedeRedimensionar) return interactiveChild;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        interactiveChild,
        if (_isResizing)
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _duracionTooltip(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 14,
          child: GestureDetector(
            onVerticalDragStart: (_) => setState(() => _isResizing = true),
            onVerticalDragUpdate: (details) {
              setState(() {
                _currentHeight = (_currentHeight + details.delta.dy).clamp(
                  GridConstants.pixelsPerHour * 0.5,
                  GridConstants.pixelsPerHour * 4,
                );
              });
              widget.onResize(details.delta.dy);
            },
            onVerticalDragEnd: (_) => setState(() => _isResizing = false),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              child: Center(
                child: Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _isResizing
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────
  // Content dispatcher
  // ──────────────────────────────────────────────────────

  Widget _buildContent(TimeBlock block, bool isTiny, bool isSmall) {
    final durationStr = _formatDuration(block.duracion);
    final acronym = block.asignaturaNombre != null
        ? _acronym(block.asignaturaNombre!)
        : null;

    if (isTiny) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(_iconForTipo(block.tipo),
                size: 10, color: _textColor.withValues(alpha: 0.8)),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                acronym ?? block.rutinaNombre ?? block.titulo ?? '',
                style: TextStyle(
                    color: _textColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(durationStr,
                style: TextStyle(color: _faintColor, fontSize: 7)),
          ],
        ),
      );
    }

    final tipo = block.tipo;
    if (tipo == TimeBlockTipo.examen) {
      return _buildExamLayout(block, acronym, isSmall, durationStr);
    }
    if (tipo == TimeBlockTipo.entrega) {
      return _buildEntregaLayout(block, acronym, isSmall, durationStr);
    }
    if (tipo == TimeBlockTipo.deporte || block.retoId != null) {
      return _buildDeporteLayout(block, isSmall, durationStr);
    }
    if (tipo == TimeBlockTipo.clase) {
      return _buildClaseLayout(block, acronym, isSmall, durationStr);
    }
    return _buildEstudioLayout(block, acronym, isSmall, durationStr);
  }

  // ──────────────────────────────────────────────────────
  // ESTUDIO — 📚 AL → temas (itálica) → 1h 30min
  // ──────────────────────────────────────────────────────

  Widget _buildEstudioLayout(
      TimeBlock block, String? acronym, bool isSmall, String durationStr) {
    final hasTemas = block.temas != null && block.temas!.isNotEmpty;

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _headerRow(block.tipo, acronym ?? ''),
            Text(
              [if (hasTemas) block.temas!, durationStr]
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              style: TextStyle(color: _faintColor, fontSize: 8, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(block.tipo, acronym ?? ''),
          const SizedBox(height: 3),
          if (hasTemas)
            Expanded(
              child: Text(
                block.temas!,
                style: TextStyle(
                    color: _faintColor,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    height: 1.3),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          _durationBadge(durationStr),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // EXAMEN — 📝 AL → título → ⏰ hora 📍 aula → 2h
  // ──────────────────────────────────────────────────────

  Widget _buildExamLayout(
      TimeBlock block, String? acronym, bool isSmall, String durationStr) {
    final hasUbicacion = block.ubicacion != null && block.ubicacion!.isNotEmpty;
    final horaStr = GridMath.formatTimeOfDay(block.horaInicio);
    final titulo = block.titulo ?? '';

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _headerRow(block.tipo, acronym ?? titulo),
            Text(
              [horaStr, if (hasUbicacion) block.ubicacion!, durationStr]
                  .join(' · '),
              style: TextStyle(color: _faintColor, fontSize: 8, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(block.tipo, acronym ?? ''),
          const SizedBox(height: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo.isNotEmpty)
                  Text(titulo,
                      style: TextStyle(
                          color: _textColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '$horaStr${hasUbicacion ? ' · ${block.ubicacion}' : ''}',
                  style: TextStyle(
                      color: _faintColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      height: 1.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _durationBadge(durationStr),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // ENTREGA — 📋 AL → título entregable → 1h 30min
  // ──────────────────────────────────────────────────────

  Widget _buildEntregaLayout(
      TimeBlock block, String? acronym, bool isSmall, String durationStr) {
    final titulo = block.titulo ?? '';

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _headerRow(block.tipo, acronym ?? titulo),
            Text(
              [if (titulo.isNotEmpty && acronym != null) titulo, durationStr]
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              style: TextStyle(color: _faintColor, fontSize: 8, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(block.tipo, acronym ?? ''),
          const SizedBox(height: 3),
          if (titulo.isNotEmpty)
            Expanded(
              child: Text(titulo,
                  style: TextStyle(
                      color: _textColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      height: 1.3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            )
          else
            const Spacer(),
          _durationBadge(durationStr),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // DEPORTE / RETO — 💪 nombre rutina → reto → 1h
  // ──────────────────────────────────────────────────────

  Widget _buildDeporteLayout(
      TimeBlock block, bool isSmall, String durationStr) {
    final nombre = block.rutinaNombre ?? block.titulo ?? 'Entrenamiento';
    final isReto = block.retoId != null;
    final isRutinaBlock = block.diaRutinaId != null;
    final diaNombre =
        isRutinaBlock && block.titulo != null && block.titulo != nombre
            ? block.titulo
            : null;

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          children: [
            if (isRutinaBlock)
              Container(
                width: 3,
                height: 20,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerRow(block.tipo, diaNombre ?? nombre),
                  Text(durationStr,
                      style: TextStyle(
                          color: _faintColor, fontSize: 8, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          if (isRutinaBlock)
            Container(
              width: 3,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerRow(block.tipo, diaNombre ?? nombre),
                const SizedBox(height: 3),
                if (isReto && block.retoTitulo != null)
                  Expanded(
                    child: Text(block.retoTitulo!,
                        style: TextStyle(
                            color: _faintColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  )
                else if (isRutinaBlock && diaNombre != null)
                  Expanded(
                    child: Text(nombre,
                        style: TextStyle(
                            color: _faintColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  )
                else
                  const Spacer(),
                _durationBadge(durationStr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // CLASE — 🏫 AL → 📍 ubicación → 1h
  // ──────────────────────────────────────────────────────

  Widget _buildClaseLayout(
      TimeBlock block, String? acronym, bool isSmall, String durationStr) {
    final hasUbicacion = block.ubicacion != null && block.ubicacion!.isNotEmpty;
    final horaStr = GridMath.formatTimeOfDay(block.horaInicio);

    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _headerRow(block.tipo, acronym ?? ''),
            Text(
              [horaStr, if (hasUbicacion) block.ubicacion!].join(' · '),
              style: TextStyle(color: _faintColor, fontSize: 8, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(block.tipo, acronym ?? ''),
          const SizedBox(height: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 9, color: _faintColor),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(horaStr,
                          style: TextStyle(
                              color: _faintColor, fontSize: 8, height: 1.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (hasUbicacion) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 9, color: _faintColor),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(block.ubicacion!,
                            style: TextStyle(
                                color: _faintColor, fontSize: 8, height: 1.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _durationBadge(durationStr),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Shared widgets
  // ──────────────────────────────────────────────────────

  Widget _headerRow(TimeBlockTipo tipo, String text) {
    return Row(
      children: [
        Icon(_iconForTipo(tipo),
            size: 12, color: _textColor.withValues(alpha: 0.85)),
        const SizedBox(width: 3),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: _textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _durationBadge(String str) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(str,
            style: const TextStyle(
                color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Static helpers
  // ──────────────────────────────────────────────────────

  static IconData _iconForTipo(TimeBlockTipo tipo) {
    return switch (tipo) {
      TimeBlockTipo.estudio => Icons.menu_book_rounded,
      TimeBlockTipo.deporte => Icons.fitness_center_rounded,
      TimeBlockTipo.clase => Icons.school_rounded,
      TimeBlockTipo.descanso => Icons.self_improvement_rounded,
      TimeBlockTipo.comida => Icons.restaurant_rounded,
      TimeBlockTipo.sueno => Icons.bedtime_rounded,
      TimeBlockTipo.entrega => Icons.assignment_turned_in_rounded,
      TimeBlockTipo.examen => Icons.quiz_rounded,
      TimeBlockTipo.repaso => Icons.replay_rounded,
    };
  }

  static String _acronym(String name) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.map((w) => w[0].toUpperCase()).take(3).join();
  }

  static String _formatDuration(Duration d) {
    final totalMin = d.inMinutes;
    if (totalMin <= 0) return '';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h${m}m';
  }
}

/// Widget de bloque sugerido por IA con botones aceptar/rechazar.
class SuggestedBlockWidget extends StatelessWidget {
  const SuggestedBlockWidget({
    required this.block,
    required this.onAccept,
    required this.onReject,
    this.columnWidthOverride,
    super.key,
  });

  final TimeBlock block;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final double? columnWidthOverride;

  @override
  Widget build(BuildContext context) {
    final height = GridMath.duracionToHeight(block.horaInicio, block.horaFin);
    final colW = columnWidthOverride ?? GridConstants.columnWidth;

    if (height <= 0) return const SizedBox.shrink();

    return Container(
      width: colW - 4,
      height: height,
      decoration: BoxDecoration(
        color: block.color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: block.color,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.titulo ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: block.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (height >= 40)
                    Text(
                      '${GridMath.formatTimeOfDay(block.horaInicio)} – ${GridMath.formatTimeOfDay(block.horaFin)}',
                      style: TextStyle(fontSize: 10, color: block.color),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onReject,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        const Icon(Icons.check, size: 14, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
