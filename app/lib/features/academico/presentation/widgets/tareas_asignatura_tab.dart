import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../shared/models/timeline_item.dart';
import '../../application/bloque_estudio_provider.dart';
import '../../application/tareas_asignatura_provider.dart';

enum _Estado { completado, pasado, actual, futuro }

/// Pestaña que muestra las tareas (bloques + entregas/exámenes) de una
/// asignatura concreta, siguiendo el mismo esquema visual que el timeline de
/// la pantalla de inicio: hora a la izquierda, conector con punto/línea y
/// tarjeta con icono, título y subtítulo. Permite marcar tareas como
/// completadas.
class TareasAsignaturaTab extends ConsumerStatefulWidget {
  const TareasAsignaturaTab({
    required this.asignaturaId,
    required this.color,
    super.key,
  });

  final String asignaturaId;
  final Color color;

  @override
  ConsumerState<TareasAsignaturaTab> createState() =>
      _TareasAsignaturaTabState();
}

class _TareasAsignaturaTabState extends ConsumerState<TareasAsignaturaTab> {
  Map<String, bool> _overlay = {};

  bool _completable(TimelineTipo t) => switch (t) {
        TimelineTipo.estudio ||
        TimelineTipo.clase ||
        TimelineTipo.deporte ||
        TimelineTipo.entrega =>
          true,
        _ => false,
      };

  _Estado _estadoDe(TimelineItem item, bool completado) {
    if (completado) return _Estado.completado;
    final now = DateTime.now();
    if (item.horaFin.isBefore(now)) return _Estado.pasado;
    if (item.horaInicio.isBefore(now) && item.horaFin.isAfter(now)) {
      return _Estado.actual;
    }
    return _Estado.futuro;
  }

  Future<void> _toggle(TimelineItem item) async {
    if (!_completable(item.tipo)) return;
    final actual = _overlay[item.id] ?? item.completado;
    final nuevo = !actual;

    setState(() => _overlay = {..._overlay, item.id: nuevo});
    HapticFeedback.selectionClick();

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      switch (item.tipo) {
        case TimelineTipo.estudio:
        case TimelineTipo.clase:
        case TimelineTipo.deporte:
          final dur = (item.duracionMinutos ??
                  item.horaFin.difference(item.horaInicio).inMinutes)
              .clamp(1, 480);
          await toggleBloqueCompletado(
            bloqueId: item.id,
            completado: nuevo,
            duracionMinutos: dur,
            ref: ref,
          );
        case TimelineTipo.entrega:
          await client
              .from('entregas_examenes')
              .update({'esta_completado': nuevo})
              .eq('id', item.id)
              .eq('usuario_id', user.id);
        default:
          break;
      }
      if (mounted) {
        ref.invalidate(tareasAsignaturaProvider(widget.asignaturaId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _overlay = {..._overlay, item.id: actual});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tareasAsignaturaProvider(widget.asignaturaId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          _vacio(Icons.error_outline, 'No se pudieron cargar las tareas', '$e'),
      data: (items) {
        if (items.isEmpty) {
          return _vacio(Icons.event_available_rounded, 'Sin tareas próximas',
              'Los bloques y entregas de esta asignatura aparecerán aquí.');
        }

        final widgets = <Widget>[];
        DateTime? diaPrevio;
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          final refTemporal = item.referenciaTemporal;
          final dia =
              DateTime(refTemporal.year, refTemporal.month, refTemporal.day);
          if (diaPrevio == null || dia != diaPrevio) {
            widgets.add(_encabezadoDia(dia, primero: diaPrevio == null));
            diaPrevio = dia;
          }
          widgets.add(_fila(item, esUltimo: i == items.length - 1));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          children: widgets,
        );
      },
    );
  }

  Widget _encabezadoDia(DateTime dia, {required bool primero}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, primero ? 4 : 16, 4, 8),
      child: Text(
        _labelDia(dia),
        style: const TextStyle(
          color: SVColors.onSurfaceMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _fila(TimelineItem item, {required bool esUltimo}) {
    final completado = _overlay[item.id] ?? item.completado;
    final estado = _estadoDe(item, completado);
    final color = item.tipo.color;
    final esActual = estado == _Estado.actual;
    final completable = _completable(item.tipo);
    final tieneHora = item.tipo != TimelineTipo.entrega;

    final double opacidad = completado
        ? 0.5
        : estado == _Estado.pasado
            ? 0.65
            : 1.0;

    return Opacity(
      opacity: opacidad,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hora
            SizedBox(
              width: 42,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  tieneHora ? _fmtHora(item.horaInicio) : '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: esActual ? FontWeight.w800 : FontWeight.w500,
                    color: esActual ? color : SVColors.onSurfaceMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            // Conector (punto + línea)
            SizedBox(
              width: 26,
              child: Column(
                children: [
                  const SizedBox(height: 13),
                  GestureDetector(
                    onTap: completable ? () => _toggle(item) : null,
                    behavior: HitTestBehavior.opaque,
                    child: _punto(estado, color),
                  ),
                  if (!esUltimo)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: SVColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Tarjeta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: completable ? () => _toggle(item) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: completado
                          ? SVColors.surfaceContainerLow
                          : esActual
                              ? color.withValues(alpha: 0.08)
                              : SVColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: esActual && !completado
                          ? Border.all(color: color, width: 1.5)
                          : Border.all(
                              color: SVColors.outlineVariant
                                  .withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: completado
                                ? const Color(0xFF27AE60)
                                    .withValues(alpha: 0.12)
                                : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            completado ? Icons.check_rounded : item.tipo.icono,
                            size: 17,
                            color: completado ? const Color(0xFF27AE60) : color,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: SVColors.onSurface,
                                  decoration: completado
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: SVColors.onSurfaceMuted,
                                ),
                              ),
                              if (item.subtitulo.isNotEmpty ||
                                  _fmtDuracion(item).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    item.subtitulo.isNotEmpty
                                        ? item.subtitulo
                                        : _fmtDuracion(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: SVColors.onSurfaceMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _badgeTipo(item, esActual, completado, color),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _punto(_Estado estado, Color color) {
    return switch (estado) {
      _Estado.completado => const Icon(Icons.check_circle_rounded,
          size: 16, color: Color(0xFF27AE60)),
      _Estado.actual => Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      _Estado.pasado => const Icon(Icons.radio_button_unchecked,
          size: 15, color: SVColors.outlineVariant),
      _Estado.futuro => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
    };
  }

  Widget _badgeTipo(
      TimelineItem item, bool esActual, bool completado, Color color) {
    if (esActual && !completado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('AHORA',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(item.tipo.label,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _vacio(IconData icono, String titulo, String subtitulo) {
    return ListView(
      children: [
        const SizedBox(height: 90),
        Icon(icono, size: 48, color: SVColors.outlineVariant),
        const SizedBox(height: 14),
        Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: SVColors.onSurfaceMuted, fontSize: 13)),
        ),
      ],
    );
  }

  String _labelDia(DateTime d) {
    final hoy = DateTime.now();
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    final diff = d.difference(h).inDays;
    if (diff == 0) return 'HOY';
    if (diff == 1) return 'MAÑANA';
    return DateFormat('EEEE d MMM', 'es').format(d).toUpperCase();
  }

  String _fmtHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDuracion(TimelineItem item) {
    final min = item.duracionMinutos ??
        item.horaFin.difference(item.horaInicio).inMinutes;
    if (min <= 0) return '';
    if (min >= 60 && min % 60 == 0) return '${min ~/ 60}h';
    if (min >= 60) return '${min ~/ 60}h ${min % 60}min';
    return '${min}min';
  }
}
