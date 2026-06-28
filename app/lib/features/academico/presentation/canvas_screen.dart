import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../core/sync/dominio_evento.dart';
import '../../../core/sync/sync_hub.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../perfil/application/perfil_provider.dart';
import '../application/calendar_grid_provider.dart';
import '../application/inbox_config_provider.dart';
import '../domain/calendar_dtos.dart';
import '../infrastructure/grid_math.dart';
import 'widgets/progress_gamification_bar.dart';
import 'widgets/academic_block_sheet.dart';
import 'widgets/reto_banner_widget.dart';

import 'widgets/time_block_widget.dart';
import 'widgets/time_grid_painter.dart';

/// Ancho de la columna izquierda reservada para las etiquetas de hora,
/// para que los bloques del lunes (columna 0) no se solapen con ellas.
const double _kHourGutter = 44.0;

class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  bool _cargando = true;
  int _bloquesInicialesCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializar();
    });
  }

  Future<void> _inicializar() async {
    final notifier = ref.read(inboxConfigProvider.notifier);

    try {
      final perfil = await ref.read(perfilUsuarioProvider.future);
      if (perfil.perfil.diasDisponibles.isNotEmpty) {
        notifier.setSesionesDeporte(perfil.perfil.diasDisponibles.length);
      }
      if (perfil.perfil.minutosPorSesion > 0) {
        notifier.setMinutosPorSesion(perfil.perfil.minutosPorSesion);
      }
    } catch (_) {}

    try {
      final perfilAc = await ref.read(perfilAcademicoProvider.future);
      if (perfilAc != null && perfilAc.horasObjetivoEstudioSemana > 0) {
        notifier
            .setHorasEstudio(perfilAc.horasObjetivoEstudioSemana.toDouble());
      }
    } catch (_) {}

    try {
      final asignaturas =
          await ref.read(asignaturasActivasInboxProvider.future);
      notifier.setAsignaturasActivas(asignaturas);
    } catch (_) {}

    try {
      final rutinas = await ref.read(rutinasActivasInboxProvider.future);
      notifier.setRutinasActivas(rutinas);
    } catch (_) {}

    try {
      final fijos = await ref.read(horariosFijosProvider.future);
      notifier.setHorariosFijos(fijos);
    } catch (_) {}

    if (!mounted) return;
    final config = ref.read(inboxConfigProvider);
    final gridNotifier = ref.read(calendarGridProvider.notifier);
    gridNotifier.inicializar(config);
    await gridNotifier.cargarBloquesGuardados();

    _bloquesInicialesCount = ref
        .read(calendarGridProvider)
        .bloques
        .where((b) => !b.esFijo && !b.esSugerencia)
        .length;

    setState(() => _cargando = false);
  }

  bool get _tieneModificaciones {
    final bloquesActuales = ref
        .read(calendarGridProvider)
        .bloques
        .where((b) => !b.esFijo && !b.esSugerencia)
        .length;
    return bloquesActuales != _bloquesInicialesCount;
  }

  Future<void> _handleBack(BuildContext context) async {
    if (!_tieneModificaciones) {
      if (context.mounted) context.pop();
      return;
    }
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content:
            const Text('Has realizado cambios en tu plan. ¿Qué deseas hacer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'descartar'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'guardar'),
            child: const Text('Guardar y salir'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (resultado == 'guardar') {
      final notifier = ref.read(calendarGridProvider.notifier);
      await notifier.guardarPlan();
      if (context.mounted) context.pop();
    } else if (resultado == 'descartar') {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarGridProvider);

    if (_cargando) {
      return const FeatureScaffold(
        title: 'Mi Plan Semanal',
        backPath: '/dashboard',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FeatureScaffold(
      title: state.planNombre ?? 'Mi Plan Semanal',
      onBack: () => _handleBack(context),
      child: Column(
        children: [
          ProgressGamificationBar(
            metadata: state.metadata,
            config: state.config,
            onEditEstudio: () => _mostrarEditorEstudio(state.config),
            onEditDeporte: () => _mostrarEditorDeporte(state.config),
          ),
          _buildWeekNavBar(state),
          _buildColorLegend(),
          if (state.retoBanners.isNotEmpty) _buildRetoBannerRow(state),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 300) {
                  ref.read(calendarGridProvider.notifier).navegarSemana(-1);
                } else if (velocity < -300) {
                  ref.read(calendarGridProvider.notifier).navegarSemana(1);
                }
              },
              child: _buildGrid(state),
            ),
          ),
          _buildBottomBar(state),
        ],
      ),
    );
  }

  Widget _buildWeekNavBar(CalendarGridState state) {
    final inicio = state.fechaInicioPantalla;
    final fin = state.fechaFinPantalla;
    final fmt = DateFormat('d MMM', 'es');
    final label = '${fmt.format(inicio)} – ${fmt.format(fin)} ${fin.year}';
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DragTarget<TimeBlock>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (d) => _moverBloqueASemana(d.data, -1, state),
            builder: (context, candidate, rejected) {
              final hover = candidate.isNotEmpty;
              return Material(
                color: hover
                    ? tema.colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () =>
                      ref.read(calendarGridProvider.notifier).navegarSemana(-1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 12),
                    child: Icon(Icons.chevron_left,
                        size: 20,
                        color: hover
                            ? tema.colorScheme.primary
                            : tema.colorScheme.onSurface
                                .withValues(alpha: 0.7)),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tema.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DragTarget<TimeBlock>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (d) => _moverBloqueASemana(d.data, 1, state),
            builder: (context, candidate, rejected) {
              final hover = candidate.isNotEmpty;
              return Material(
                color: hover
                    ? tema.colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () =>
                      ref.read(calendarGridProvider.notifier).navegarSemana(1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 12),
                    child: Icon(Icons.chevron_right,
                        size: 20,
                        color: hover
                            ? tema.colorScheme.primary
                            : tema.colorScheme.onSurface
                                .withValues(alpha: 0.7)),
                  ),
                ),
              );
            },
          ),
          if (state.semanaOffset != 0)
            TextButton(
              onPressed: () => ref.read(calendarGridProvider.notifier).irAHoy(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Hoy',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tema.colorScheme.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildColorLegend() {
    const items = [
      (Color(0xFF4A90D9), 'Estudio'),
      (Color(0xFFD97706), 'Examen'),
      (Color(0xFFDC2626), 'Entrega'),
      (Color(0xFF059669), 'Deporte'),
      (Color(0xFF64748B), 'Clase'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: items[i].$1.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              items[i].$2,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRetoBannerRow(CalendarGridState state) {
    final visibles = state.retoBanners
        .where((b) => b.abarcaSemana(
              state.fechaInicioPantalla,
              state.fechaFinPantalla,
            ))
        .toList();
    if (visibles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final columnWidth = constraints.maxWidth / 7;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: visibles.map((banner) {
            final startCol = banner.columnaInicio(state.fechaInicioPantalla);
            final endCol = banner.columnaFin(state.fechaInicioPantalla);
            final leftOffset = startCol * columnWidth;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: leftOffset),
                  child: RetoBannerWidget(
                    banner: banner,
                    columnWidth: columnWidth,
                    startCol: startCol,
                    endCol: endCol,
                    onTap: () => _showRetoDetalleSheet(banner),
                    onTapTarea: banner.esComplejo
                        ? () => _showRetoTareaPlacement(banner, state)
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  void _showRetoDetalleSheet(RetoBanner banner) {
    final tema = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: banner.color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    banner.titulo,
                    style: tema.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (banner.meta != null && banner.meta!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.flag_rounded,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      banner.meta!,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _detalleChip(Icons.category_rounded, banner.tipo),
                const SizedBox(width: 8),
                _detalleChip(
                  Icons.calendar_today,
                  '${DateFormat('d MMM', 'es').format(banner.fechaInicio)} → ${DateFormat('d MMM', 'es').format(banner.fechaFin)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: banner.progreso.clamp(0.0, 1.0),
                backgroundColor: banner.color.withValues(alpha: 0.1),
                color: banner.color,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(banner.progreso * 100).round()}%',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: banner.color),
              ),
            ),
            if (banner.esComplejo && banner.tareas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Tareas',
                  style: tema.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...banner.tareas.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          t.completada
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: t.completada
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.titulo,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: t.completada
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: t.completada ? Colors.grey.shade500 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/retos/${banner.retoId}');
                },
                child: const Text('Ver reto completo'),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _detalleChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  void _showRetoTareaPlacement(RetoBanner banner, CalendarGridState state) {
    final tareasDisponibles =
        banner.tareas.where((t) => !t.completada).toList();
    if (tareasDisponibles.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Colocar tareas de "${banner.titulo}"',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Selecciona una tarea para colocarla en el día actual del lienzo',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ...tareasDisponibles.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: banner.color.withValues(alpha: 0.3)),
                    ),
                    leading:
                        Icon(Icons.task_alt, color: banner.color, size: 20),
                    title: Text(t.titulo, style: const TextStyle(fontSize: 13)),
                    trailing: Icon(Icons.add_circle_outline,
                        color: banner.color, size: 20),
                    onTap: () {
                      final hoy = DateTime.now();
                      ref.read(calendarGridProvider.notifier).placeRetoTarea(
                            retoId: banner.retoId,
                            retoTitulo: banner.titulo,
                            hitoId: t.hitoId,
                            hitoTitulo: t.titulo,
                            fecha: DateTime(hoy.year, hoy.month, hoy.day),
                            horaInicio: const TimeOfDay(hour: 10, minute: 0),
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('"${t.titulo}" colocada en el calendario'),
                          backgroundColor: banner.color,
                        ),
                      );
                    },
                  ),
                )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(CalendarGridState state) {
    final now = DateTime.now();
    final hoyDate = DateTime(now.year, now.month, now.day);

    return LayoutBuilder(builder: (context, constraints) {
      final columnWidth = (constraints.maxWidth - _kHourGutter) / 7;

      return Column(
        children: [
          // Cabecera fija de días
          _buildDayHeaderRow(columnWidth, state, hoyDate),
          // Grid scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: constraints.maxWidth,
                height: GridConstants.totalGridHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(color: const Color(0xFFF8FAFC)),
                    ),
                    CustomPaint(
                      size: Size(
                        constraints.maxWidth,
                        GridConstants.totalGridHeight,
                      ),
                      painter: const TimeGridPainter(hourGutter: _kHourGutter),
                    ),
                    for (var col = 0; col < 7; col++)
                      for (var slot = 0; slot < 34; slot++)
                        _buildDropTarget(col, slot, columnWidth, state),
                    for (final block in state.bloquesFijos)
                      _buildPositionedBlock(
                          block, columnWidth, state, context, false),
                    for (final block in state.bloques
                        .where((b) => !b.esFijo && !b.esSugerencia))
                      _buildDraggableBlock(block, columnWidth, state),
                    for (final block in state.bloquesSugeridos)
                      _buildSuggestedBlock(block, columnWidth, state),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPositionedBlock(TimeBlock block, double columnWidth,
      CalendarGridState state, BuildContext context, bool isFixed) {
    final colIndex = _colIndexForBlock(block, state);
    if (colIndex < 0 || colIndex >= 7) return const SizedBox.shrink();
    final left = _kHourGutter + colIndex * columnWidth;
    final top = GridMath.horaToOffsetY(block.horaInicio);
    final height = GridMath.duracionToHeight(block.horaInicio, block.horaFin);

    return Positioned(
      top: top,
      left: left,
      width: columnWidth - 4,
      height: height,
      child: TimeBlockWidget(
        block: block,
        onResize: (_) {},
        columnWidthOverride: columnWidth,
        onTap: () => _showEditBlockSheet(block),
      ),
    );
  }

  Widget _buildDraggableBlock(
      TimeBlock block, double columnWidth, CalendarGridState state) {
    final colIndex = _colIndexForBlock(block, state);
    if (colIndex < 0 || colIndex >= 7) return const SizedBox.shrink();
    final left = _kHourGutter + colIndex * columnWidth;

    return _DraggableBlock(
      block: block,
      leftOverride: left,
      columnWidthOverride: columnWidth,
      onTap: () => _showEditBlockSheet(block),
      onResize: (deltaY) {
        final oldFin = block.horaFin;
        final deltaMinutes =
            (deltaY / GridConstants.pixelsPerHour * 60).round();
        var newMinutes = oldFin.hour * 60 + oldFin.minute + deltaMinutes;
        newMinutes = (newMinutes / 30).round() * 30;
        newMinutes = newMinutes.clamp(0, 23 * 60);
        final newFin = TimeOfDay(
          hour: newMinutes ~/ 60,
          minute: newMinutes % 60,
        );
        ref.read(calendarGridProvider.notifier).resizeBlock(
              block.idLocal,
              newFin,
            );
      },
    );
  }

  Widget _buildSuggestedBlock(
      TimeBlock block, double columnWidth, CalendarGridState state) {
    final colIndex = _colIndexForBlock(block, state);
    if (colIndex < 0 || colIndex >= 7) return const SizedBox.shrink();
    final left = _kHourGutter + colIndex * columnWidth;
    final top = GridMath.horaToOffsetY(block.horaInicio);
    final height = GridMath.duracionToHeight(block.horaInicio, block.horaFin);

    return Positioned(
      top: top,
      left: left,
      width: columnWidth - 4,
      height: height,
      child: SuggestedBlockWidget(
        block: block,
        columnWidthOverride: columnWidth,
        onAccept: () =>
            ref.read(calendarGridProvider.notifier).acceptSuggestion(
                  block.idLocal,
                ),
        onReject: () =>
            ref.read(calendarGridProvider.notifier).rejectSuggestion(
                  block.idLocal,
                ),
      ),
    );
  }

  Widget _buildDayHeader(int col, CalendarGridState state, DateTime hoyDate) {
    final fecha = state.fechaInicioPantalla.add(Duration(days: col));
    final esHoy = state.semanaOffset == 0 &&
        fecha.year == hoyDate.year &&
        fecha.month == hoyDate.month &&
        fecha.day == hoyDate.day;
    return _DayHeader(fecha: fecha, esHoy: esHoy);
  }

  Widget _buildDayHeaderRow(
      double columnWidth, CalendarGridState state, DateTime hoyDate) {
    return SizedBox(
      height: GridConstants.headerHeight,
      child: Row(
        children: [
          const SizedBox(width: _kHourGutter),
          for (var col = 0; col < 7; col++)
            SizedBox(
              width: columnWidth,
              child: _buildDayHeader(col, state, hoyDate),
            ),
        ],
      ),
    );
  }

  Widget _buildDropTarget(
      int col, int slot, double columnWidth, CalendarGridState state) {
    final fechaColumna = state.fechaInicioPantalla.add(Duration(days: col));
    return Positioned(
      top: slot * GridConstants.snapHalfHour,
      left: _kHourGutter + col * columnWidth,
      width: columnWidth,
      height: GridConstants.snapHalfHour,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onCellTap(fechaColumna, slot),
        child: DragTarget<Object>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            final data = details.data;
            if (data is Map<String, dynamic>) {
              final tipo = data['tipo'] as String? ?? 'estudio';
              ref.read(calendarGridProvider.notifier).placeBlock(
                    asignaturaId: data['asignaturaId'] as String?,
                    asignaturaNombre: data['asignaturaNombre'] as String?,
                    diaSemana: fechaColumna.weekday,
                    horaInicio: GridMath.offsetYToHora(
                        slot * GridConstants.snapHalfHour),
                    tipo: tipo == 'deporte'
                        ? TimeBlockTipo.deporte
                        : TimeBlockTipo.estudio,
                    rutinaId: data['rutinaId'] as String?,
                    rutinaNombre: data['rutinaNombre'] as String?,
                    temas: data['temas'] as String?,
                    fecha: fechaColumna,
                  );
            } else if (data is TimeBlock) {
              ref.read(calendarGridProvider.notifier).moveBlock(
                    data.idLocal,
                    fechaColumna.weekday,
                    GridMath.offsetYToHora(slot * GridConstants.snapHalfHour),
                    nuevaFecha: fechaColumna,
                  );
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            Color hoverColor = const Color(0xFF3B82F6);
            if (isHovering && candidateData.first is TimeBlock) {
              hoverColor = (candidateData.first as TimeBlock).color;
            }
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: isHovering
                  ? BoxDecoration(
                      color: hoverColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hoverColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }

  int _colIndexForBlock(TimeBlock block, CalendarGridState state) {
    final fechaBloque = block.fecha ??
        state.fechaInicioPantalla.add(Duration(
            days:
                (block.diaSemana - state.fechaInicioPantalla.weekday + 7) % 7));
    return fechaBloque.difference(state.fechaInicioPantalla).inDays;
  }

  /// Mueve un bloque a la semana anterior (delta -1) o siguiente (delta +1),
  /// conservando el mismo día de la semana y hora, y navega hasta ella.
  void _moverBloqueASemana(
      TimeBlock block, int delta, CalendarGridState state) {
    final fechaActual = block.fecha ??
        state.fechaInicioPantalla.add(Duration(
            days:
                (block.diaSemana - state.fechaInicioPantalla.weekday + 7) % 7));
    final base = DateTime(fechaActual.year, fechaActual.month, fechaActual.day);
    final nuevaFecha = base.add(Duration(days: 7 * delta));

    ref.read(calendarGridProvider.notifier).moveBlock(
          block.idLocal,
          block.diaSemana,
          block.horaInicio,
          nuevaFecha: nuevaFecha,
        );
    ref.read(calendarGridProvider.notifier).navegarSemana(delta);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(delta < 0
            ? 'Bloque movido a la semana anterior'
            : 'Bloque movido a la semana siguiente'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  void _onCellTap(DateTime fecha, int slot) {
    final hora = GridMath.offsetYToHora(slot * GridConstants.snapHalfHour);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AcademicBlockSheet(fecha: fecha, horaInicio: hora),
    );
  }

  void _showEditBlockSheet(TimeBlock block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AcademicBlockSheet(
        fecha: block.fecha ?? DateTime.now(),
        horaInicio: block.horaInicio,
        editBlock: block,
      ),
    );
  }

  void _mostrarEditorEstudio(InboxConfig config) {
    double horas = config.horasEstudioObjetivo;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          color: Color(0xFF3B82F6), size: 22),
                      const SizedBox(width: 8),
                      Text('Horas de estudio',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${horas.toStringAsFixed(1)}h',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF3B82F6),
                      inactiveTrackColor:
                          const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      thumbColor: const Color(0xFF3B82F6),
                      overlayColor:
                          const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      trackHeight: 6,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: horas,
                      min: 0,
                      max: 50,
                      divisions: 100,
                      label: '${horas.toStringAsFixed(1)}h',
                      onChanged: (v) => setLocalState(() => horas = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0h',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                      Text('25h',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                      Text('50h',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(inboxConfigProvider.notifier)
                            .setHorasEstudio(horas);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarEditorDeporte(InboxConfig config) {
    int sesiones = config.sesionesDeporteObjetivo;
    int minutos = config.minutosPorSesionDeporte;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded,
                          color: Color(0xFFF97316), size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Días de entrenamiento',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$sesiones días · ${minutos}min/día',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF97316)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFF97316),
                      inactiveTrackColor:
                          const Color(0xFFF97316).withValues(alpha: 0.15),
                      thumbColor: const Color(0xFFF97316),
                      overlayColor:
                          const Color(0xFFF97316).withValues(alpha: 0.12),
                      trackHeight: 6,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: sesiones.toDouble(),
                      min: 0,
                      max: 7,
                      divisions: 7,
                      label: sesiones == 0
                          ? 'Descanso'
                          : sesiones == 1
                              ? '1 día'
                              : '$sesiones días',
                      onChanged: (v) =>
                          setLocalState(() => sesiones = v.toInt()),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                      Text('3',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                      Text('7',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Duración por sesión',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: minutos,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(8),
                        items: const [
                          DropdownMenuItem(value: 30, child: Text('30 min')),
                          DropdownMenuItem(value: 45, child: Text('45 min')),
                          DropdownMenuItem(value: 60, child: Text('60 min')),
                          DropdownMenuItem(value: 90, child: Text('90 min')),
                          DropdownMenuItem(value: 120, child: Text('120 min')),
                        ],
                        onChanged: (v) {
                          if (v != null) setLocalState(() => minutos = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(inboxConfigProvider.notifier)
                            .setSesionesDeporte(sesiones);
                        ref
                            .read(inboxConfigProvider.notifier)
                            .setMinutosPorSesion(minutos);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(CalendarGridState state) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            TextButton(
              onPressed: state.guardando ? null : () => _handleBack(context),
              child: const Text('← Volver'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: state.guardando
                  ? null
                  : () async {
                      final notifier = ref.read(calendarGridProvider.notifier);
                      try {
                        final planId = await notifier.guardarPlan();
                        if (planId != null && mounted) {
                          await syncCargaAcademicaSemanal(ref);
                          ref.read(syncHubProvider).dispatch(
                                DominioEvento.planGuardado,
                                payload: EventoPayload(planId: planId),
                              );
                          final bloquesAceptados = ref
                              .read(calendarGridProvider)
                              .bloquesAceptados
                              .length;
                          final xpPlanificacion =
                              100 + (5 * bloquesAceptados).clamp(0, 100);
                          final client = Supabase.instance.client;
                          final user = client.auth.currentUser;
                          final xpResult = user != null
                              ? await otorgarXp(
                                  client, user.id, xpPlanificacion)
                              : null;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(xpResult != null &&
                                        xpResult.subeNivel
                                    ? '¡Semana guardada! +$xpPlanificacion XP · ¡Subiste de nivel! 🎉'
                                    : '¡Semana guardada! +$xpPlanificacion XP'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                          ref.read(inboxConfigProvider.notifier).reset();
                          if (mounted) {
                            context.go('/plan-semanal');
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              icon: state.guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.fecha, required this.esHoy});

  final DateTime fecha;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final label = GridMath.dayHeaderLabel(fecha);
    final tema = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: esHoy ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : null,
        border: Border(
          right:
              BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
          top: esHoy
              ? const BorderSide(color: Color(0xFF3B82F6), width: 2)
              : BorderSide.none,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: esHoy ? 11 : 10,
            fontWeight: esHoy ? FontWeight.w800 : FontWeight.w500,
            color: esHoy
                ? const Color(0xFF1E3A5F)
                : tema.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _DraggableBlock extends StatelessWidget {
  const _DraggableBlock({
    required this.block,
    required this.onResize,
    required this.leftOverride,
    required this.columnWidthOverride,
    this.onTap,
  });

  final TimeBlock block;
  final void Function(double deltaY) onResize;
  final VoidCallback? onTap;
  final double leftOverride;
  final double columnWidthOverride;

  @override
  Widget build(BuildContext context) {
    final top = GridMath.horaToOffsetY(block.horaInicio);
    final height = GridMath.duracionToHeight(block.horaInicio, block.horaFin);
    final width = columnWidthOverride - 4;

    return Positioned(
      top: top,
      left: leftOverride,
      width: width,
      height: height,
      child: LongPressDraggable<TimeBlock>(
        data: block,
        delay: const Duration(milliseconds: 250),
        feedback: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: width,
            height: height,
            child: TimeBlockWidget(
              block: block,
              onResize: (_) {},
              columnWidthOverride: columnWidthOverride,
              isDragging: true,
            ),
          ),
        ),
        childWhenDragging: CustomPaint(
          painter: _DashedBorderPainter(color: Colors.grey.shade400),
          child: Opacity(
            opacity: 0.2,
            child: TimeBlockWidget(
              block: block,
              onResize: (_) {},
              columnWidthOverride: columnWidthOverride,
            ),
          ),
        ),
        child: TimeBlockWidget(
          block: block,
          onResize: onResize,
          columnWidthOverride: columnWidthOverride,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({this.color = Colors.grey});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
