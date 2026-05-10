import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/design_system/sv_colors.dart';
import '../application/rutina_provider.dart';

class RutinaDetalleScreen extends ConsumerStatefulWidget {
  const RutinaDetalleScreen({required this.rutinaId, super.key});

  final String rutinaId;

  @override
  ConsumerState<RutinaDetalleScreen> createState() =>
      _RutinaDetalleScreenState();
}

class _RutinaDetalleScreenState extends ConsumerState<RutinaDetalleScreen> {
  int _semanaSeleccionada = 0;
  String? _semanaExpandidaId;
  final Map<String, bool> _diasExpandidos = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanasAsync = ref.watch(semanasDeRutinaProvider(widget.rutinaId));

    return FeatureScaffold(
      title: '',
      backPath: '/bienestar',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Eliminar rutina',
          onPressed: () => _confirmarEliminar(),
        ),
      ],
      child: semanasAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(fontSize: 13))),
        data: (semanas) {
          if (semanas.isEmpty) {
            return const EmptyState(
              title: 'Sin estructura',
              message: 'Esta rutina no tiene semanas configuradas.',
              icon: Icons.calendar_today_rounded,
            );
          }

          if (_semanaSeleccionada >= semanas.length) {
            _semanaSeleccionada = semanas.length - 1;
          }
          final semanaActual = semanas[_semanaSeleccionada];

          return Column(
            children: [
              _buildHeader(theme),
              const SizedBox(height: 8),
              _buildSemanaSelector(semanas, theme),
              const SizedBox(height: 12),
              Expanded(
                  child: _DiasList(
                      semanaId: semanaActual.id, rutinaId: widget.rutinaId)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .from('rutinas')
            .select('nombre, descripcion, objetivo, duracion_semanas, estado')
            .eq('id', widget.rutinaId)
            .maybeSingle(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data == null)
            return const SizedBox.shrink();
          final r = snap.data!;
          final semanasCompletadas = ref
                  .watch(semanasDeRutinaProvider(widget.rutinaId))
                  .valueOrNull
                  ?.where((s) => s.estado == 'completada')
                  .length ??
              0;
          final totalSemanas = r['duracion_semanas'] as int? ?? 1;
          final progreso =
              totalSemanas > 0 ? semanasCompletadas / totalSemanas : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['nombre'] as String? ?? 'Rutina',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _ObjetivoBadge(
                      objetivo: r['objetivo'] as String? ?? 'fuerza'),
                  const SizedBox(width: 8),
                  Text('$totalSemanas semanas',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: SVColors.onSurfaceMuted)),
                  const SizedBox(width: 8),
                  _EstadoBadge(estado: r['estado'] as String? ?? 'activo'),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 2),
              Text('${(progreso * 100).round()}% completado',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSemanaSelector(List<SemanaRutinaDb> semanas, ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: semanas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = semanas[i];
          final completada = s.estado == 'completada';
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (completada)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child:
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                  ),
                Text('Sem ${s.numeroSemana}'),
              ],
            ),
            selected: _semanaSeleccionada == i,
            onSelected: (_) => setState(() => _semanaSeleccionada = i),
          );
        },
      ),
    );
  }

  Future<void> _confirmarEliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: const Text('¿Eliminar esta rutina y toda su estructura?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await eliminarRutina(widget.rutinaId, ref);
      if (mounted) context.go('/bienestar');
    }
  }
}

class _DiasList extends ConsumerWidget {
  const _DiasList({required this.semanaId, required this.rutinaId});

  final String semanaId;
  final String rutinaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diasAsync = ref.watch(diasDeSemanaProvider(semanaId));
    return diasAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(fontSize: 13))),
      data: (dias) {
        if (dias.isEmpty)
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(children: [
              const EmptyState(
                  title: 'Sin días',
                  message: 'Añade días de entrenamiento a esta semana.',
                  icon: Icons.today_rounded),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                  onPressed: () => agregarDiaASemana(semanaId, 1, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir día')),
            ]),
          );
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: dias.length + 1,
          itemBuilder: (context, i) {
            if (i == dias.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                    onPressed: () =>
                        agregarDiaASemana(semanaId, dias.length + 1, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Añadir día',
                        style: TextStyle(fontSize: 12))),
              );
            }
            return _DiaCard(dia: dias[i], rutinaId: rutinaId);
          },
        );
      },
    );
  }
}

class _DiaCard extends ConsumerWidget {
  const _DiaCard({required this.dia, required this.rutinaId});

  final DiaRutinaDb dia;
  final String rutinaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ejerciciosAsync = ref.watch(ejerciciosDeDiaProvider(dia.id));
    final completado = dia.estado == 'completado';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: completado ? Colors.green.withValues(alpha: 0.04) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: completado
              ? Colors.green.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
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
                    color: completado
                        ? Colors.green.withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    completado
                        ? Icons.check_circle
                        : Icons.fitness_center_rounded,
                    size: 16,
                    color:
                        completado ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dia.nombre.isNotEmpty ? dia.nombre : 'Día ${dia.numeroDia}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (completado)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Completado',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600)),
                  )
                else
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/bienestar/rutina/sesion',
                      extra: {
                        'rutinaId': rutinaId,
                        'diaId': dia.id,
                        'semanaId': dia.semanaId,
                      },
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Iniciar',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ejerciciosAsync.when(
              data: (ejercicios) {
                return Column(
                  children: [
                    if (ejercicios.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 42),
                        child: Text('Sin ejercicios aún.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: SVColors.onSurfaceMuted)),
                      )
                    else
                      ...ejercicios.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final e = entry.value;
                        return _EjercicioRow(
                          index: idx + 1,
                          ejercicio: e,
                          diaId: dia.id,
                          rutinaId: rutinaId,
                        );
                      }),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _mostrarBuscador(context, ref),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Añadir ejercicio',
                          style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(left: 42),
                child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(fontSize: 11, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarBuscador(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _BuscadorEjerciciosSheet(onSelected: (id, nombre) {
        agregarEjercicioADia(
            rutinaId: rutinaId,
            diaId: dia.id,
            ejercicioId: id,
            series: 3,
            repeticiones: 10,
            segundosDescanso: 90,
            ref: ref);
      }),
    );
  }
}

class _EjercicioRow extends ConsumerStatefulWidget {
  const _EjercicioRow(
      {required this.index,
      required this.ejercicio,
      required this.diaId,
      required this.rutinaId});

  final int index;
  final SeleccionEjercicioDb ejercicio;
  final String diaId;
  final String rutinaId;

  @override
  ConsumerState<_EjercicioRow> createState() => _EjercicioRowState();
}

class _EjercicioRowState extends ConsumerState<_EjercicioRow> {
  bool _editando = false;
  late int _series, _reps, _descanso;
  late double? _peso;

  @override
  void initState() {
    super.initState();
    _series = widget.ejercicio.series;
    _reps = widget.ejercicio.repeticiones;
    _descanso = widget.ejercicio.segundosDescanso;
    _peso = widget.ejercicio.pesoKg;
  }

  void _guardarCambios() {
    actualizarEjercicioDia(
        widget.ejercicio.id,
        {
          'series': _series,
          'repeticiones': _reps,
          'segundos_descanso': _descanso,
          if (_peso != null) 'peso_kg': _peso,
        },
        widget.diaId,
        ref);
    setState(() => _editando = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.ejercicio;
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('ejercicios')
          .select('nombre')
          .eq('id', e.ejercicioId)
          .maybeSingle(),
      builder: (context, snap) {
        final nombre = snap.data?['nombre'] as String? ?? 'Ejercicio';
        return Column(
          children: [
            InkWell(
              onLongPress: () => _sustituirEjercicio(context, nombre),
              onTap: () => setState(() => _editando = !_editando),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                      child: Text('${widget.index}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(nombre,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                            '${_editando ? _series : e.series}×${_editando ? _reps : e.repeticiones} · ${_editando ? _descanso : e.segundosDescanso}s descanso${(_editando ? _peso : e.pesoKg) != null ? ' · ${(_editando ? _peso : e.pesoKg)!.toStringAsFixed(1)} kg' : ''}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: SVColors.onSurfaceMuted)),
                      ])),
                  IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      onPressed: () =>
                          quitarEjercicioDeDia(e.id, widget.diaId, ref),
                      visualDensity: VisualDensity.compact),
                ]),
              ),
            ),
            if (_editando)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 48),
                child: Row(children: [
                  _paramChip('Series', _series,
                      (v) => setState(() => _series = v.clamp(1, 10))),
                  const Text(' × ', style: TextStyle(fontSize: 12)),
                  _paramChip('Reps', _reps,
                      (v) => setState(() => _reps = v.clamp(1, 50))),
                  const Text(' · ',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  _paramChip('Desc', _descanso,
                      (v) => setState(() => _descanso = v.clamp(15, 600)),
                      sufijo: 's'),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                        controller: TextEditingController(
                            text: _peso?.toStringAsFixed(1) ?? ''),
                        decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            border: OutlineInputBorder(),
                            hintText: 'kg'),
                        onChanged: (v) =>
                            setState(() => _peso = double.tryParse(v)),
                        onSubmitted: (_) => _guardarCambios(),
                      )),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: _guardarCambios,
                      child:
                          const Text('Guardar', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero)),
                ]),
              ),
          ],
        );
      },
    );
  }

  Widget _paramChip(String label, int val, void Function(int) onChange,
      {String sufijo = ''}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
          onTap: () => onChange(val - 1),
          child: const Icon(Icons.remove, size: 14)),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('$val$sufijo',
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      InkWell(
          onTap: () => onChange(val + 1),
          child: const Icon(Icons.add, size: 14)),
    ]);
  }

  void _sustituirEjercicio(BuildContext context, String nombreActual) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) => _SustitucionSheet(
            nombreActual: nombreActual,
            onSeleccionado: (nuevoId) {
              actualizarEjercicioDia(widget.ejercicio.id,
                  {'ejercicio_id': nuevoId}, widget.diaId, ref);
              Navigator.pop(ctx);
            }));
  }
}

class _BuscadorEjerciciosSheet extends StatefulWidget {
  const _BuscadorEjerciciosSheet({required this.onSelected});
  final void Function(String id, String nombre) onSelected;
  @override
  State<_BuscadorEjerciciosSheet> createState() =>
      _BuscadorEjerciciosSheetState();
}

class _BuscadorEjerciciosSheetState extends State<_BuscadorEjerciciosSheet> {
  final _ctrl = TextEditingController();
  String _q = '';
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollCtrl) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(children: [
                Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                TextField(
                    controller: _ctrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                        hintText: 'Buscar ejercicio...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        isDense: true),
                    onChanged: (v) => setState(() => _q = v.toLowerCase())),
                const SizedBox(height: 8),
                Expanded(child: _buildLista(scrollCtrl)),
              ]),
            ));
  }

  Widget _buildLista(ScrollController scrollCtrl) {
    final client = Supabase.instance.client;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _q.isEmpty
          ? client
              .from('v_ejercicios_completos')
              .select('id, nombre')
              .limit(50)
              .then((d) => d as List<Map<String, dynamic>>)
          : client
              .from('v_ejercicios_completos')
              .select('id, nombre')
              .ilike('nombre', '%$_q%')
              .limit(50)
              .then((d) => d as List<Map<String, dynamic>>),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        if (snap.data!.isEmpty)
          return const Center(
              child:
                  Text('Sin resultados', style: TextStyle(color: Colors.grey)));
        return ListView.builder(
            controller: scrollCtrl,
            itemCount: snap.data!.length,
            itemBuilder: (context, i) {
              final e = snap.data![i];
              return ListTile(
                  dense: true,
                  title: Text(e['nombre'] as String,
                      style: const TextStyle(fontSize: 13)),
                  onTap: () {
                    widget.onSelected(e['id'] as String, e['nombre'] as String);
                    Navigator.pop(context);
                  });
            });
      },
    );
  }
}

class _SustitucionSheet extends ConsumerStatefulWidget {
  const _SustitucionSheet({
    required this.nombreActual,
    required this.onSeleccionado,
  });

  final String nombreActual;
  final void Function(String ejercicioId) onSeleccionado;

  @override
  ConsumerState<_SustitucionSheet> createState() => _SustitucionSheetState();
}

class _SustitucionSheetState extends ConsumerState<_SustitucionSheet> {
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Text('Sustituir "${widget.nombreActual}"',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _busquedaCtrl,
                decoration: const InputDecoration(
                  hintText: 'Buscar ejercicio...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildLista(scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLista(ScrollController scrollCtrl) {
    final client = Supabase.instance.client;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _busqueda.isEmpty
          ? client
              .from('v_ejercicios_completos')
              .select('id, nombre')
              .limit(50)
              .then((d) => d as List<Map<String, dynamic>>)
          : client
              .from('v_ejercicios_completos')
              .select('id, nombre')
              .ilike('nombre', '%$_busqueda%')
              .limit(50)
              .then((d) => d as List<Map<String, dynamic>>),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return ListView.builder(
          controller: scrollCtrl,
          itemCount: snap.data!.length,
          itemBuilder: (context, i) {
            final e = snap.data![i];
            return ListTile(
              dense: true,
              title: Text(e['nombre'] as String,
                  style: const TextStyle(fontSize: 13)),
              onTap: () => widget.onSeleccionado(e['id'] as String),
            );
          },
        );
      },
    );
  }
}

class _ObjetivoBadge extends StatelessWidget {
  const _ObjetivoBadge({required this.objetivo});

  final String objetivo;

  @override
  Widget build(BuildContext context) {
    final (icono, label) = switch (objetivo) {
      'fuerza' => (Icons.fitness_center_rounded, 'Fuerza'),
      'resistencia' => (Icons.directions_run_rounded, 'Resistencia'),
      'hipertrofia' => (Icons.trending_up_rounded, 'Hipertrofia'),
      'movilidad' => (Icons.accessibility_new_rounded, 'Movilidad'),
      _ => (Icons.help_outline_rounded, objetivo),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (estado) {
      'activo' => (Colors.green, 'Activo'),
      'pausado' => (Colors.orange, 'Pausado'),
      'completado' => (Colors.blue, 'Completado'),
      _ => (Colors.grey, estado),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
