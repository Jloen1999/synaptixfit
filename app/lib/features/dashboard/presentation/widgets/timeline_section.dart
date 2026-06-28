import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/models/db_models.dart';
import '../../../../shared/models/timeline_item.dart';
import '../../../../shared/widgets/undo_toast.dart';
import '../../../academico/application/bloque_estudio_provider.dart';
import '../../../bienestar/application/rutina_provider.dart';
import '../../../insignias/application/insignias_provider.dart';
import '../../../perfil/application/perfil_provider.dart';
import '../../../retos/application/retos_provider.dart';
import '../../application/dashboard_provider.dart';
import '../../application/timeline_provider.dart';

enum _EstadoBloque { completado, pasado, actual, futuro }

_EstadoBloque _calcularEstado(TimelineItem item, bool completado) {
  if (completado) return _EstadoBloque.completado;
  final now = DateTime.now();
  if (item.horaFin.isBefore(now)) return _EstadoBloque.pasado;
  if (item.horaInicio.isBefore(now) && item.horaFin.isAfter(now)) {
    return _EstadoBloque.actual;
  }
  return _EstadoBloque.futuro;
}

bool _esCompletable(TimelineTipo tipo) => switch (tipo) {
      TimelineTipo.estudio ||
      TimelineTipo.clase ||
      TimelineTipo.deporte ||
      TimelineTipo.entrega ||
      TimelineTipo.reto ||
      TimelineTipo.hitoReto =>
        true,
      _ => false,
    };

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

int _xpParaBloque(TimelineItem item) {
  final duracion = item.duracionMinutos ??
      item.horaFin.difference(item.horaInicio).inMinutes;
  return (duracion / 30).ceil() * 10;
}

int _xpParaTipo(TimelineItem item) => switch (item.tipo) {
      TimelineTipo.estudio ||
      TimelineTipo.clase ||
      TimelineTipo.deporte =>
        _xpParaBloque(item),
      TimelineTipo.entrega => 30,
      TimelineTipo.reto => 50,
      TimelineTipo.hitoReto => 20,
      _ => 0,
    };

void _syncMetricas(ProviderContainer container) {
  container.invalidate(dashboardProvider);
  container.invalidate(adherenciaAcademicaProvider);
  container.invalidate(estadoEnergeticoProvider);
  container.invalidate(cargaAcademicaSemanalProvider);
  container.invalidate(perfilActividadProvider);
  container.invalidate(retosProvider);
  evaluarInsigniasDesdeContainer(container);
}

DateTime _lunesActual() {
  final hoy = DateTime.now();
  return DateTime(hoy.year, hoy.month, hoy.day)
      .subtract(Duration(days: hoy.weekday - 1));
}

Future<void> _recalcularCargaSemanal() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  final lunes = _lunesActual();
  final domingo = lunes.add(const Duration(days: 7));
  final lunesStr = lunes.toIso8601String().substring(0, 10);

  final bloquesEstudio = await client
      .from('horarios_academicos')
      .select('hora_inicio, hora_fin')
      .eq('usuario_id', user.id)
      .eq('tipo_actividad', 'estudio')
      .eq('completado', true)
      .gte('hora_inicio', lunes.toIso8601String())
      .lt('hora_inicio', domingo.toIso8601String());

  int minutosReales = 0;
  for (final b in bloquesEstudio) {
    final inicio = DateTime.parse(b['hora_inicio'] as String);
    final fin = DateTime.parse(b['hora_fin'] as String);
    minutosReales += fin.difference(inicio).inMinutes;
  }

  final entregasData = await client
      .from('entregas_examenes')
      .select('esta_completado')
      .eq('usuario_id', user.id)
      .gte('fecha_limite', lunes.toIso8601String())
      .lt('fecha_limite', domingo.toIso8601String());

  final totalEntregas = entregasData.length;
  final entregasCompletadas =
      entregasData.where((e) => e['esta_completado'] == true).length;

  final perfilData = await client
      .from('perfil_academico_usuario')
      .select('horas_objetivo_estudio_semana')
      .eq('usuario_id', user.id)
      .maybeSingle();
  final horasPlaneadas =
      (perfilData?['horas_objetivo_estudio_semana'] as num?)?.toInt() ?? 14;

  final hoyStr = DateTime.now().toIso8601String().substring(0, 10);
  final estadoHoy = await client
      .from('estado_diario_usuario')
      .select('nivel_estres, calidad_sueno')
      .eq('usuario_id', user.id)
      .eq('fecha', hoyStr)
      .maybeSingle();

  await client.from('carga_academica_semanal').upsert({
    'usuario_id': user.id,
    'semana_inicio': lunesStr,
    'horas_estudio_planeadas': horasPlaneadas,
    'horas_estudio_reales': (minutosReales / 60.0).round(),
    'evaluaciones_semana': totalEntregas,
    'entregas_semana': entregasCompletadas,
    'nivel_estres': ((estadoHoy?['nivel_estres'] as int?) ?? 5).clamp(1, 10),
    'horas_sueno_promedio':
        ((estadoHoy?['calidad_sueno'] as int?) ?? 0).clamp(0, 14),
  }, onConflict: 'usuario_id,semana_inicio');
}

Future<void> _syncCompletarDB(TimelineItem item, WidgetRef ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  switch (item.tipo) {
    case TimelineTipo.entrega:
      await client
          .from('entregas_examenes')
          .update({'esta_completado': true})
          .eq('id', item.id)
          .eq('usuario_id', user.id);
      try {
        await client.rpc('otorgar_xp',
            params: {'p_usuario_id': user.id, 'p_cantidad_xp': 30});
      } catch (_) {}
      await _recalcularCargaSemanal();

    case TimelineTipo.estudio:
    case TimelineTipo.clase:
    case TimelineTipo.deporte:
      final duracion = (item.duracionMinutos ??
              item.horaFin.difference(item.horaInicio).inMinutes)
          .clamp(1, 480);
      await toggleBloqueCompletado(
        bloqueId: item.id,
        completado: true,
        duracionMinutos: duracion,
        ref: ref,
      );

    case TimelineTipo.reto:
      await client
          .from('retos')
          .update({'esta_completado': true})
          .eq('id', item.id)
          .eq('usuario_id', user.id);
      try {
        await client.rpc('otorgar_xp',
            params: {'p_usuario_id': user.id, 'p_cantidad_xp': 50});
      } catch (_) {}

    case TimelineTipo.hitoReto:
      await client
          .from('hitos_reto')
          .update({'esta_completado': true}).eq('id', item.id);
      try {
        await client.rpc('otorgar_xp',
            params: {'p_usuario_id': user.id, 'p_cantidad_xp': 20});
      } catch (_) {}

    default:
      return;
  }
}

Future<void> _syncDeshacerDB(TimelineItem item) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  final xp = _xpParaTipo(item);

  switch (item.tipo) {
    case TimelineTipo.entrega:
      await client
          .from('entregas_examenes')
          .update({'esta_completado': false})
          .eq('id', item.id)
          .eq('usuario_id', user.id);

    case TimelineTipo.estudio:
    case TimelineTipo.clase:
    case TimelineTipo.deporte:
      await client
          .from('horarios_academicos')
          .update({
            'completado': false,
            'asistencia_registrada_en': null,
            'xp_bloque_otorgado': false,
          })
          .eq('id', item.id)
          .eq('usuario_id', user.id);

    case TimelineTipo.reto:
      await client
          .from('retos')
          .update({'esta_completado': false})
          .eq('id', item.id)
          .eq('usuario_id', user.id);

    case TimelineTipo.hitoReto:
      await client
          .from('hitos_reto')
          .update({'esta_completado': false}).eq('id', item.id);

    default:
      return;
  }

  if (xp > 0) {
    try {
      final userData = await client
          .from('usuarios')
          .select('xp_total')
          .eq('id', user.id)
          .single();
      final currentXp = (userData['xp_total'] as num?)?.toInt() ?? 0;
      final newXp = (currentXp - xp).clamp(0, 999999);
      await client
          .from('usuarios')
          .update({'xp_total': newXp}).eq('id', user.id);
    } catch (_) {}
  }

  await _recalcularCargaSemanal();
}

class DailyTimelineWidget extends ConsumerWidget {
  const DailyTimelineWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dia = ref.watch(selectedDiaProvider);
    final now = DateTime.now();
    final esHoy =
        dia.year == now.year && dia.month == now.month && dia.day == now.day;
    final timelineAsync = esHoy
        ? ref.watch(timelineHoyProvider)
        : ref.watch(timelineDiaProvider(dia));
    final overlay = ref.watch(completionOverlayProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 2),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Línea de tiempo',
                  style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Material(
                color: SVColors.surfaceContainerLow,
                borderRadius: SVShapes.standard,
                child: InkWell(
                  borderRadius: SVShapes.standard,
                  onTap: () => context.push('/academico/planificar'),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_view_week,
                            size: 14, color: SVColors.onSurfaceVariant),
                        const SizedBox(width: 5),
                        const Text(
                          'Ver Semana',
                          style: TextStyle(
                            color: SVColors.onSurfaceVariant,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const _DaySelectorTabs(),
        Expanded(
          child: _buildContenido(context, timelineAsync, overlay, esHoy),
        ),
      ],
    );
  }

  Widget _buildContenido(
    BuildContext context,
    AsyncValue<List<TimelineItem>> timelineAsync,
    Map<String, bool> overlay,
    bool esHoy,
  ) {
    final items = timelineAsync.valueOrNull;
    if (items == null && timelineAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (items == null) {
      return Center(
        child: Text(
          'Error al cargar',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      );
    }
    if (items.isEmpty && (!esHoy || overlay.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 40,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15)),
            const SizedBox(height: 10),
            Text(esHoy ? 'Sin actividades hoy' : 'Sin actividades este día',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(esHoy ? 'Tu día está libre' : 'Día libre',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.25),
                    fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final completado = overlay[item.id] ?? item.completado;
        final estado = _calcularEstado(item, completado);
        final esUltimo = index == items.length - 1;
        return _TimelineRow(
          item: item,
          completado: completado,
          estado: estado,
          esUltimo: esUltimo,
        );
      },
    );
  }
}

/// Pestañas pequeñas de los días de la semana (lun→dom). Por defecto marca hoy;
/// al tocar una, el timeline muestra las tareas de ese día. (Clean UI: píldoras
/// planas, sin sombras, color sólido para el día seleccionado.)
class _DaySelectorTabs extends ConsumerWidget {
  const _DaySelectorTabs();

  static const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sel = ref.watch(selectedDiaProvider);
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Row(
        children: List.generate(7, (i) {
          final dia = lunes.add(Duration(days: i));
          final esSel = dia == sel;
          final esHoy = dia == hoy;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: esSel ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      ref.read(selectedDiaProvider.notifier).state = dia,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: (esHoy && !esSel)
                          ? Border.all(color: cs.primary.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: esSel ? cs.onPrimary : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dia.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: esSel
                                ? cs.onPrimary
                                : (esHoy ? cs.primary : cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({
    required this.item,
    required this.completado,
    required this.estado,
    required this.esUltimo,
  });

  final TimelineItem item;
  final bool completado;
  final _EstadoBloque estado;
  final bool esUltimo;

  void _onCardTap(BuildContext context) {
    switch (item.tipo) {
      case TimelineTipo.estudio:
      case TimelineTipo.clase:
      case TimelineTipo.deporte:
        context.push('/academico');
      case TimelineTipo.reto:
        context.push('/retos/${item.id}');
      case TimelineTipo.hitoReto:
        final datos = item.datosOriginales as Map<String, dynamic>;
        final reto = datos['reto'] as RetoDb;
        context.push('/retos/${reto.id}');
      case TimelineTipo.entrenamientoPendiente:
        if (item.rutinaId != null) {
          context.push('/bienestar/rutina/sesion',
              extra: {'diaId': item.id, 'rutinaId': item.rutinaId});
        }
      default:
        break;
    }
  }

  void _completar(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    final container = ProviderScope.containerOf(context);
    container
        .read(completionOverlayProvider.notifier)
        .update((state) => {...state, item.id: true});
    _syncCompletarDB(item, ref)
        .then((_) => _syncMetricas(container))
        .catchError((_) {});
    _mostrarSnackBar(context, container);
  }

  void _deshacer(BuildContext context) {
    HapticFeedback.mediumImpact();
    final container = ProviderScope.containerOf(context);
    container
        .read(completionOverlayProvider.notifier)
        .update((state) => {...state, item.id: false});
    _syncDeshacerDB(item)
        .then((_) => _syncMetricas(container))
        .catchError((_) {});
  }

  void _mostrarSnackBar(BuildContext context, ProviderContainer container) {
    UndoToast.show(
      context,
      message: 'Bloque completado',
      actionLabel: 'Deshacer',
      duration: const Duration(seconds: 4),
      onAction: () {
        HapticFeedback.lightImpact();
        container
            .read(completionOverlayProvider.notifier)
            .update((state) => {...state, item.id: false});
        _syncDeshacerDB(item)
            .then((_) => _syncMetricas(container))
            .catchError((_) {});
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = item.tipo.color;
    final esActual = estado == _EstadoBloque.actual;
    final tieneHora =
        item.tipo != TimelineTipo.reto && item.tipo != TimelineTipo.hitoReto;
    final completable = _esCompletable(item.tipo);

    final double opacity;
    if (completado) {
      opacity = 0.45;
    } else if (estado == _EstadoBloque.pasado) {
      opacity = 0.6;
    } else {
      opacity = 1.0;
    }

    Widget row = Opacity(
      opacity: opacity,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 46,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  tieneHora ? _fmtHora(item.horaInicio) : '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: esActual ? FontWeight.w800 : FontWeight.w500,
                    color: esActual
                        ? color
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: completable
                        ? () {
                            if (!completado) {
                              _completar(context, ref);
                            } else {
                              _deshacer(context);
                            }
                          }
                        : null,
                    child: completado
                        ? const Icon(Icons.check_circle_rounded,
                            size: 14, color: Color(0xFF27AE60))
                        : esActual
                            ? _PulsingDot(color: color)
                            : estado == _EstadoBloque.pasado
                                ? Icon(Icons.radio_button_unchecked,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.2))
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color.withValues(alpha: 0.2),
                                      border:
                                          Border.all(color: color, width: 1.5),
                                    ),
                                  ),
                  ),
                  if (!esUltimo)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.25),
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
                  onTap: () => _onCardTap(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: completado
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.25)
                          : esActual
                              ? color.withValues(alpha: 0.08)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                      border: esActual && !completado
                          ? Border.all(color: color, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: completado
                                ? const Color(0xFF27AE60)
                                    .withValues(alpha: 0.12)
                                : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            completado ? Icons.check_rounded : item.tipo.icono,
                            size: 15,
                            color: completado ? const Color(0xFF27AE60) : color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.titulo,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: esActual && !completado
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  decoration: completado
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_fmtDuracion(item).isNotEmpty ||
                                  item.subtitulo.isNotEmpty)
                                Text(
                                  _fmtDuracion(item).isNotEmpty
                                      ? _fmtDuracion(item)
                                      : item.subtitulo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (esActual && !completado)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                          ),
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

    if (!completable) return row;

    return Dismissible(
      key: ValueKey('dismiss_${item.id}_$completado'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && !completado) {
          _completar(context, ref);
        } else if (direction == DismissDirection.endToStart && completado) {
          _deshacer(context);
        }
        return false;
      },
      direction: completado
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF27AE60),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE67E22).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.undo_rounded, color: Colors.white, size: 22),
      ),
      child: row,
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (context, child) {
              return Container(
                width: 14 * _scale.value,
                height: 14 * _scale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.2 / _scale.value),
                ),
              );
            },
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
