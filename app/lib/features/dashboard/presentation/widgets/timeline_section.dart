import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../shared/models/db_models.dart';
import '../../../../shared/models/timeline_item.dart';
import '../../../retos/application/retos_provider.dart';
import '../../../academico/application/entregas_examenes_provider.dart';
import '../../application/timeline_provider.dart';

/// Timeline enriquecida con navegacion por tabs.
class TimelineSection extends ConsumerStatefulWidget {
  const TimelineSection({super.key});

  @override
  ConsumerState<TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends ConsumerState<TimelineSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.timeline_rounded,
                      size: 16, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text('Linea de tiempo',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/plan-semanal'),
                  icon: const Icon(Icons.calendar_month_rounded, size: 14),
                  label: const Text('Plan', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Hoy'),
              Tab(text: 'Semana'),
              Tab(text: 'Retos'),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _TabHoy(),
                _TabSemana(),
                _TabRetos(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB HOY ────────────────────────────────────────────────
class _TabHoy extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineHoyProvider);
    return timelineAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Center(child: Text('Error al cargar')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
              child: Text('Sin actividades hoy',
                  style: TextStyle(color: SVColors.onSurfaceMuted)));
        }
        // Separa entrenamiento pendiente del resto
        final entrenamientoPend = items
            .where((i) => i.tipo == TimelineTipo.entrenamientoPendiente)
            .toList();
        final otrosItems = items
            .where((i) => i.tipo != TimelineTipo.entrenamientoPendiente)
            .take(entrenamientoPend.isNotEmpty ? 4 : 5)
            .toList();

        final widgets = <Widget>[];
        // Card destacada de entrenamiento pendiente
        for (final ep in entrenamientoPend) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _EntrenamientoPendienteCard(item: ep),
          ));
        }
        // Resto de items normal
        for (final item in otrosItems) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _TimelineTarjeta(item: item),
          ));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: widgets,
        );
      },
    );
  }
}

// ─── TAB SEMANA ─────────────────────────────────────────────
class _TabSemana extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineHoyProvider);
    return timelineAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Center(child: Text('Error al cargar')),
      data: (items) {
        final entregas =
            items.where((i) => i.tipo == TimelineTipo.entrega).toList();
        if (entregas.isEmpty) {
          return const Center(
              child: Text('Sin entregas esta semana',
                  style: TextStyle(color: SVColors.onSurfaceMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entregas.length.clamp(0, 7),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _TimelineTarjeta(item: entregas[i]),
          ),
        );
      },
    );
  }
}

// ─── TAB RETOS ──────────────────────────────────────────────
class _TabRetos extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retosAsync = ref.watch(retosProvider);
    return retosAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Center(child: Text('Error al cargar')),
      data: (retos) {
        if (retos.isEmpty) {
          return const Center(
              child: Text('Sin retos activos',
                  style: TextStyle(color: SVColors.onSurfaceMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: retos.length.clamp(0, 5),
          itemBuilder: (_, i) {
            final r = retos[i];
            final pct = (r.progreso * 100).round();
            final dias = r.reto.fechaFin.difference(DateTime.now()).inDays;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _RetoCard(
                titulo: r.reto.titulo,
                progreso: pct,
                diasRestantes: dias,
                color: r.reto.tipo == 'fitness'
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF7C4DFF),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── TARJETA TIMELINE ───────────────────────────────────────
class _TimelineTarjeta extends ConsumerWidget {
  const _TimelineTarjeta({required this.item});
  final TimelineItem item;

  void _onTap(BuildContext context, WidgetRef ref) {
    switch (item.tipo) {
      case TimelineTipo.estudio:
      case TimelineTipo.clase:
      case TimelineTipo.deporte:
        context.push('/plan-semanal');
      case TimelineTipo.reto:
        context.push('/retos/${item.id}');
      case TimelineTipo.hitoReto:
        final datos = item.datosOriginales as Map<String, dynamic>;
        final reto = datos['reto'] as RetoDb;
        context.push('/retos/${reto.id}');
      case TimelineTipo.entrega:
        toggleEntregaCompletada(item.id, !item.completado, ref: ref);
        ref.invalidate(timelineHoyProvider);
      case TimelineTipo.sesion:
      case TimelineTipo.entrenamientoPendiente:
      case TimelineTipo.nutricion:
      case TimelineTipo.sueno:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = item.tipo.color;
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => _onTap(context, ref),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.tipo.icono, size: 14, color: color),
                          const SizedBox(width: 6),
                          if (item.tipo == TimelineTipo.reto)
                            Text(
                              item.diasRestantes != null
                                  ? '${item.diasRestantes} d'
                                  : 'Activo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SVColors.onSurfaceMuted),
                            )
                          else if (item.tipo == TimelineTipo.entrega)
                            Text(
                              item.diasRestantes != null
                                  ? '${item.diasRestantes} d'
                                  : 'Hoy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SVColors.onSurfaceMuted),
                            )
                          else if (item.tipo ==
                              TimelineTipo.entrenamientoPendiente)
                            Text(
                              'Pendiente',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SVColors.onSurfaceMuted),
                            )
                          else
                            Text(
                              '${fmt(item.horaInicio)} - ${fmt(item.horaFin)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SVColors.onSurfaceMuted),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(item.tipo.label,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ),
                          if (item.completado) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: SVColors.secondary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.titulo,
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (item.subtitulo.isNotEmpty)
                        Text(item.subtitulo,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: SVColors.onSurfaceMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TARJETA RETO ───────────────────────────────────────────
class _RetoCard extends StatelessWidget {
  const _RetoCard({
    required this.titulo,
    required this.progreso,
    required this.diasRestantes,
    required this.color,
  });

  final String titulo;
  final int progreso;
  final int diasRestantes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(titulo,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              Text('$diasRestantes d',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SVColors.onSurfaceMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progreso / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text('$progreso%',
              style: const TextStyle(
                  fontSize: 10, color: SVColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}

// ─── CARD ENTRENAMIENTO PENDIENTE ───────────────────────────
/// Tarjeta destacada para el entrenamiento pendiente del dia.
class _EntrenamientoPendienteCard extends StatelessWidget {
  const _EntrenamientoPendienteCard({required this.item});
  final TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFF9800).withAlpha(15),
        border:
            Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    size: 16, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tienes entrenamiento pendiente',
                        style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100))),
                    if (item.subtitulo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.subtitulo,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFF9800)
                                  .withValues(alpha: 0.7))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: item.rutinaId != null
                  ? () => context.push(
                        '/bienestar/rutina/sesion',
                        extra: {
                          'diaId': item.id,
                          'rutinaId': item.rutinaId,
                        },
                      )
                  : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Comenzar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(38),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
