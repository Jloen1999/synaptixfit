import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../bienestar/application/bienestar_semanal_provider.dart';
import '../application/asignaturas_provider.dart';
import '../application/planes_estudio_provider.dart';

class PlanSemanalScreen extends ConsumerStatefulWidget {
  const PlanSemanalScreen({super.key});

  @override
  ConsumerState<PlanSemanalScreen> createState() => _PlanSemanalScreenState();
}

class _PlanSemanalScreenState extends ConsumerState<PlanSemanalScreen> {
  String? _planExpandidoId;
  final _nombreCtrl = TextEditingController();
  late DateTime _semanaInicio;
  late DateTime _semanaFin;
  String _visibilidad = 'privado';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _semanaInicio = _lunesDeEstaSemana();
    _semanaFin = _semanaInicio.add(const Duration(days: 6));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  static DateTime _lunesDeEstaSemana() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Plan Semanal',
      backPath: '/dashboard',
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoCrearPlan(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo plan'),
            )
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Académico')),
                ButtonSegment(value: 1, label: Text('Bienestar')),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (v) => setState(() => _tabIndex = v.first),
            ),
          ),
          Expanded(
            child: _tabIndex == 0 ? _buildAcademico() : _buildBienestar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademico() {
    final planesAsync = ref.watch(planesEstudioProvider);
    return planesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (planes) {
        if (planes.isEmpty) {
          return EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Sin planes de estudio',
            message:
                'Crea tu primer plan semanal para organizar tus bloques de estudio.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(planesEstudioProvider);
            return ref.read(planesEstudioProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: planes.length,
            itemBuilder: (context, index) {
              final plan = planes[index];
              final expandido = _planExpandidoId == plan.id;
              return _PlanCard(
                plan: plan,
                expandido: expandido,
                onToggleExpand: () {
                  setState(() {
                    _planExpandidoId = expandido ? null : plan.id;
                  });
                },
                onEliminar: () => _confirmarEliminarPlan(plan),
                onCrearBloque: () => _mostrarDialogoCrearBloque(plan),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBienestar() {
    final bienestarAsync = ref.watch(bienestarSemanalProvider);

    return bienestarAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (dto) {
        if (dto.plan == null && dto.sesionesCompletadas == 0) {
          return const EmptyState(
            icon: Icons.favorite_outline,
            title: 'Sin datos de bienestar',
            message:
                'Completa tu perfil de bienestar para recibir un plan semanal de entrenamiento.',
          );
        }

        final cumplimientoPct = (dto.cumplimiento * 100).round();
        final colorCumplimiento = cumplimientoPct >= 80
            ? Colors.green
            : cumplimientoPct >= 50
                ? Colors.orange
                : Colors.red;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bienestarSemanalProvider);
            return ref.read(bienestarSemanalProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tarjeta principal de cumplimiento
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: dto.cumplimiento,
                                strokeWidth: 10,
                                backgroundColor:
                                    colorCumplimiento.withValues(alpha: 0.15),
                                valueColor:
                                    AlwaysStoppedAnimation(colorCumplimiento),
                              ),
                            ),
                            Text(
                              '$cumplimientoPct%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorCumplimiento,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cumplimiento semanal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Indicador(
                            icon: Icons.event_available,
                            label: 'Planificado',
                            value: '${dto.sesionesPlanificadas}',
                          ),
                          const SizedBox(width: 32),
                          _Indicador(
                            icon: Icons.check_circle_outline,
                            label: 'Completado',
                            value: '${dto.sesionesCompletadas}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Plan activo
              if (dto.plan != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan actual',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _PlanDetalle(
                              icon: Icons.fitness_center,
                              label: 'Intensidad',
                              value: dto.plan!.intensidad,
                            ),
                            const SizedBox(width: 16),
                            _PlanDetalle(
                              icon: Icons.timer_outlined,
                              label: 'Por sesión',
                              value: '${dto.plan!.duracionMinPorSesion} min',
                            ),
                            const SizedBox(width: 16),
                            _PlanDetalle(
                              icon: Icons.repeat,
                              label: 'Estado',
                              value: dto.plan!.estado,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Tendencia
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tendencia',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            dto.tendencia == 'Mejorando'
                                ? Icons.trending_up
                                : dto.tendencia == 'Bajando'
                                    ? Icons.trending_down
                                    : Icons.trending_flat,
                            color: dto.tendencia == 'Mejorando'
                                ? Colors.green
                                : dto.tendencia == 'Bajando'
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dto.tendencia,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          Text(
                            'Semana anterior: ${(dto.cumplimientoAnterior * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sugerencia
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dto.sugerencia,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoCrearPlan() {
    _nombreCtrl.text =
        'Plan ${DateFormat('dd/MM', 'es').format(_semanaInicio)}';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo plan semanal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nombreCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del plan'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Inicio',
                        date: _semanaInicio,
                        onChanged: (d) =>
                            setDialogState(() => _semanaInicio = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Fin',
                        date: _semanaFin,
                        onChanged: (d) => setDialogState(() => _semanaFin = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _visibilidad,
                  decoration: const InputDecoration(labelText: 'Visibilidad'),
                  items: const [
                    DropdownMenuItem(value: 'privado', child: Text('Privado')),
                    DropdownMenuItem(value: 'publico', child: Text('Público')),
                    DropdownMenuItem(
                        value: 'solo_amigos', child: Text('Solo amigos')),
                  ],
                  onChanged: (v) => setDialogState(() => _visibilidad = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (_nombreCtrl.text.trim().length < 2) return;
                await crearPlanEstudio(
                  nombre: _nombreCtrl.text.trim(),
                  semanaInicio: _semanaInicio,
                  semanaFin: _semanaFin,
                  visibilidad: _visibilidad,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(planesEstudioProvider);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCrearBloque(PlanEstudioDb plan) {
    String? asignaturaId;
    final horaInicioCtrl =
        TextEditingController(text: DateFormat('HH:mm').format(DateTime.now()));
    final horaFinCtrl = TextEditingController(
        text: DateFormat('HH:mm')
            .format(DateTime.now().add(const Duration(hours: 1, minutes: 30))));
    String prioridad = 'media';
    String? ubicacion;

    showDialog(
      context: context,
      builder: (ctx) {
        final asignaturasAsync = ref.watch(asignaturasActivasProvider);
        return AlertDialog(
          title: const Text('Nuevo bloque de estudio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                asignaturasAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (asigs) => DropdownButtonFormField<String>(
                    value: asignaturaId,
                    decoration:
                        const InputDecoration(labelText: 'Asignatura *'),
                    items: asigs
                        .map((a) => DropdownMenuItem(
                            value: a.id, child: Text(a.nombre)))
                        .toList(),
                    onChanged: (v) => asignaturaId = v,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: horaInicioCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Hora inicio (HH:MM)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: horaFinCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Hora fin (HH:MM)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: prioridad,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: const [
                    DropdownMenuItem(value: 'alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'media', child: Text('Media')),
                    DropdownMenuItem(value: 'baja', child: Text('Baja')),
                  ],
                  onChanged: (v) => prioridad = v!,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration:
                      const InputDecoration(labelText: 'Ubicación (opcional)'),
                  onChanged: (v) => ubicacion = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (asignaturaId == null) return;
                final hi = _parseHora(horaInicioCtrl.text);
                final hf = _parseHora(horaFinCtrl.text);
                if (hi == null || hf == null) return;

                final inicio = DateTime(
                    plan.semanaInicio.year,
                    plan.semanaInicio.month,
                    plan.semanaInicio.day,
                    hi.hour,
                    hi.minute);
                final fin = DateTime(
                    plan.semanaInicio.year,
                    plan.semanaInicio.month,
                    plan.semanaInicio.day,
                    hf.hour,
                    hf.minute);

                await crearBloqueEstudio(
                  asignaturaId: asignaturaId!,
                  horaInicio: inicio,
                  horaFin: fin,
                  planEstudioId: plan.id,
                  ubicacion: ubicacion?.isEmpty ?? true ? null : ubicacion,
                  prioridad: prioridad,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(bloquesPorPlanProvider(plan.id));
                ref.invalidate(planesEstudioProvider);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminarPlan(PlanEstudioDb plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plan'),
        content: Text('¿Eliminar «${plan.nombre}» y todos sus bloques?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await eliminarPlanEstudio(plan.id);
              setState(() => _planExpandidoId = null);
              ref.invalidate(planesEstudioProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  TimeOfDay? _parseHora(String text) {
    final parts = text.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.plan,
    required this.expandido,
    required this.onToggleExpand,
    required this.onEliminar,
    required this.onCrearBloque,
  });

  final PlanEstudioDb plan;
  final bool expandido;
  final VoidCallback onToggleExpand;
  final VoidCallback onEliminar;
  final VoidCallback onCrearBloque;

  String _rangoFechas(BuildContext context) {
    final fmt = DateFormat('d MMM', 'es');
    return '${fmt.format(plan.semanaInicio)} - ${fmt.format(plan.semanaFin)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: Text(plan.nombre),
            subtitle: Text(_rangoFechas(context)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _VisibilidadBadge(visibilidad: plan.visibilidad),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(expandido ? Icons.expand_less : Icons.expand_more),
                  onPressed: onToggleExpand,
                ),
              ],
            ),
            onTap: onToggleExpand,
          ),
          if (expandido) _BloquesList(plan: plan),
          if (expandido)
            ButtonBar(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir bloque'),
                  onPressed: onCrearBloque,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar plan'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: onEliminar,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VisibilidadBadge extends StatelessWidget {
  const _VisibilidadBadge({required this.visibilidad});

  final String visibilidad;

  @override
  Widget build(BuildContext context) {
    final color = switch (visibilidad) {
      'publico' => Colors.green,
      'solo_amigos' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        visibilidad == 'solo_amigos' ? 'amigos' : visibilidad,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}

class _BloquesList extends ConsumerWidget {
  const _BloquesList({required this.plan});

  final PlanEstudioDb plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloquesAsync = ref.watch(bloquesPorPlanProvider(plan.id));

    return bloquesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $err'),
      ),
      data: (bloques) {
        if (bloques.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sin bloques. Añade uno con el botón inferior.',
                textAlign: TextAlign.center),
          );
        }
        return Column(
          children: bloques.map((b) => _BloqueTile(bloque: b)).toList(),
        );
      },
    );
  }
}

class _BloqueTile extends ConsumerWidget {
  const _BloqueTile({required this.bloque});

  final HorarioAcademicoDb bloque;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmtHora = DateFormat('HH:mm');
    final hora =
        '${fmtHora.format(bloque.horaInicio)} - ${fmtHora.format(bloque.horaFin)}';

    final asignaturasAsync = ref.watch(asignaturasActivasProvider);
    final colorPrioridad = switch (bloque.prioridad) {
      'alta' => Colors.red,
      'media' => Colors.orange,
      _ => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: colorPrioridad,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                asignaturasAsync.when(
                  data: (asigs) {
                    final a = asigs
                        .where((e) => e.id == bloque.asignaturaId)
                        .firstOrNull;
                    return Text(a?.nombre ?? 'Asignatura',
                        style: Theme.of(context).textTheme.bodyMedium);
                  },
                  loading: () =>
                      const Text('...', style: TextStyle(fontSize: 12)),
                  error: (_, __) => const Text('?'),
                ),
                Text(hora, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (bloque.ubicacion != null)
            Text(bloque.ubicacion!,
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () async {
              await eliminarBloqueEstudio(bloque.id);
              ref.invalidate(bloquesPorPlanProvider(bloque.planEstudioId!));
            },
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
          locale: const Locale('es'),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(DateFormat('dd/MM/yyyy').format(date)),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PlanDetalle extends StatelessWidget {
  const _PlanDetalle({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
