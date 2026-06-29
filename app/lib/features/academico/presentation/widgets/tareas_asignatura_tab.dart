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

class _ItemAgrupado {
  final TimelineItem principal;
  final List<TimelineItem> items;
  final DateTime horaInicio;
  final DateTime horaFin;
  final String? tipoClase;

  const _ItemAgrupado({
    required this.principal,
    required this.items,
    required this.horaInicio,
    required this.horaFin,
    this.tipoClase,
  });

  bool get esAgrupado => items.length > 1;
  TimelineTipo get tipo => principal.tipo;
  String get titulo => principal.titulo;
  ClassType? get classType => principal.classType;

  Duration get duracion => horaFin.difference(horaInicio);
  int get duracionMinutos => duracion.inMinutes;
}

List<_ItemAgrupado> _agruparItems(List<TimelineItem> items) {
  final result = <_ItemAgrupado>[];
  for (final item in items) {
    if (item.tipo == TimelineTipo.clase && result.isNotEmpty) {
      final anterior = result.last;
      if (anterior.tipo == TimelineTipo.clase &&
          anterior.titulo == item.titulo &&
          anterior.tipoClase == item.tipoClase &&
          anterior.horaFin == item.horaInicio) {
        result[result.length - 1] = _ItemAgrupado(
          principal: anterior.principal,
          items: [...anterior.items, item],
          horaInicio: anterior.horaInicio,
          horaFin: item.horaFin,
          tipoClase: item.tipoClase,
        );
        continue;
      }
    }
    result.add(_ItemAgrupado(
      principal: item,
      items: [item],
      horaInicio: item.horaInicio,
      horaFin: item.horaFin,
      tipoClase: item.tipoClase,
    ));
  }
  return result;
}

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
      await _persistirToggle(item, nuevo);
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

  Future<void> _persistirToggle(TimelineItem item, bool nuevo) async {
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
  }

  Future<void> _toggleGrupo(_ItemAgrupado grupo) async {
    final primero = grupo.principal;
    if (!_completable(primero.tipo)) return;
    final actual = _overlay[primero.id] ?? primero.completado;
    final nuevo = !actual;

    for (final item in grupo.items) {
      setState(() => _overlay = {..._overlay, item.id: nuevo});
    }
    HapticFeedback.selectionClick();

    try {
      for (final item in grupo.items) {
        await _persistirToggle(item, nuevo);
      }
    } catch (e) {
      for (final item in grupo.items) {
        if (mounted) {
          setState(() => _overlay = {..._overlay, item.id: actual});
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')),
        );
      }
      return;
    }
    if (mounted) {
      ref.invalidate(tareasAsignaturaProvider(widget.asignaturaId));
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

        final agrupados = _agruparItems(items);
        final widgets = <Widget>[];
        DateTime? diaPrevio;
        for (var i = 0; i < agrupados.length; i++) {
          final grupo = agrupados[i];
          final refTemporal = grupo.horaInicio;
          final dia =
              DateTime(refTemporal.year, refTemporal.month, refTemporal.day);
          if (diaPrevio == null || dia != diaPrevio) {
            widgets.add(_encabezadoDia(dia, primero: diaPrevio == null));
            diaPrevio = dia;
          }
          widgets
              .add(_filaAgrupado(grupo, esUltimo: i == agrupados.length - 1));
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
                        if (item.isPrivate == true)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.lock_outline,
                                size: 14, color: SVColors.onSurfaceMuted),
                          ),
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

  Widget _filaAgrupado(_ItemAgrupado grupo, {required bool esUltimo}) {
    final item = grupo.principal;
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
            SizedBox(
              width: 56,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  tieneHora
                      ? grupo.esAgrupado
                          ? '${_fmtHora(grupo.horaInicio)}\n -\n${_fmtHora(grupo.horaFin)}'
                          : _fmtHora(grupo.horaInicio)
                      : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: esActual ? FontWeight.w800 : FontWeight.w500,
                    color: esActual ? color : SVColors.onSurfaceMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.3,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 26,
              child: Column(
                children: [
                  const SizedBox(height: 13),
                  GestureDetector(
                    onTap: grupo.esAgrupado
                        ? () => _toggleGrupo(grupo)
                        : completable
                            ? () => _toggle(item)
                            : null,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: grupo.esAgrupado
                      ? () => _toggleGrupo(grupo)
                      : completable
                          ? () => _toggle(item)
                          : null,
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
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _subtituloAgrupado(grupo, item),
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
                        if (item.isPrivate == true)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.lock_outline,
                                size: 14, color: SVColors.onSurfaceMuted),
                          ),
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

  String _subtituloAgrupado(_ItemAgrupado grupo, TimelineItem item) {
    if (item.subtitulo.isNotEmpty) return item.subtitulo;
    final dur = grupo.duracionMinutos;
    if (dur <= 0) return '';
    if (dur >= 60 && dur % 60 == 0) return '${dur ~/ 60}h';
    if (dur >= 60) return '${dur ~/ 60}h ${dur % 60}min';
    return '${dur}min';
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
    final (label, badgeColor) = switch (item.tipo) {
      TimelineTipo.clase => _claseBadge(item),
      _ => (item.tipo.label, color),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: badgeColor)),
    );
  }

  (String, Color) _claseBadge(TimelineItem item) {
    final ct = item.classType;
    if (ct != null) return (ct.label, ct.color);
    return ('Clase', const Color(0xFF8B5CF6));
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
