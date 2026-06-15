import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/design_system/sv_colors.dart';
import '../application/rutina_provider.dart';
import '../application/ejercicios_provider.dart';

class RutinaDetalleScreen extends ConsumerStatefulWidget {
  const RutinaDetalleScreen({required this.rutinaId, super.key});

  final String rutinaId;

  @override
  ConsumerState<RutinaDetalleScreen> createState() =>
      _RutinaDetalleScreenState();
}

class _RutinaDetalleScreenState extends ConsumerState<RutinaDetalleScreen> {
  int _semanaSeleccionada = 0;
  bool _celebracionMostrada = false;
  bool _completando = false;
  bool _reutilizando = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanasAsync = ref.watch(semanasDeRutinaProvider(widget.rutinaId));
    final todasCompletadas =
        semanasAsync.valueOrNull?.every((s) => s.estado == 'completada') ??
            false;

    return FeatureScaffold(
      title: '',
      backPath: '/bienestar',
      actions: [
        if (!todasCompletadas)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Editar rutina',
            onPressed: () => _editarRutina(),
          ),
        if (todasCompletadas)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reutilizar rutina',
            onPressed: () => _reutilizarRutina(),
          ),
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

          if (todasCompletadas && !_celebracionMostrada) {
            _celebracionMostrada = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _mostrarCelebracion());
          }

          return Column(
            children: [
              _buildHeader(theme, semanas),
              const SizedBox(height: 8),
              _buildSemanaSelector(semanas, theme),
              const SizedBox(height: 12),
              Expanded(
                  child: _DiasList(
                      semanaId: semanaActual.id, rutinaId: widget.rutinaId)),
              if (!todasCompletadas) _buildBotonCompletarRutina(theme),
              if (todasCompletadas) _buildBotonReutilizarRutina(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, List<SemanaRutinaDb> semanas) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .from('rutinas')
            .select('nombre, descripcion, objetivo, duracion_semanas, estado')
            .eq('id', widget.rutinaId)
            .maybeSingle(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data == null) {
            return const SizedBox.shrink();
          }
          final r = snap.data!;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Supabase.instance.client
                .from('sesiones_registradas')
                .select('duracion_minutos, dia_id, completada_en')
                .eq('rutina_id', widget.rutinaId)
                .order('completada_en', ascending: false),
            builder: (context, sesionSnap) {
              final sesiones =
                  sesionSnap.data ?? const <Map<String, dynamic>>[];
              final minutosTotales = sesiones.fold<int>(
                  0,
                  (sum, s) =>
                      sum + ((s['duracion_minutos'] as num?)?.toInt() ?? 0));

              final diasCompletados = semanas.fold<int>(
                0,
                (sum, sem) =>
                    sum +
                    (ref
                            .watch(diasDeSemanaProvider(sem.id))
                            .valueOrNull
                            ?.where((d) => d.estado == 'completado')
                            .length ??
                        0),
              );

              final totalSemanas = r['duracion_semanas'] as int? ?? 1;
              final totalDias = semanas.fold<int>(0, (sum, sem) {
                final dias =
                    ref.watch(diasDeSemanaProvider(sem.id)).valueOrNull;
                return sum + (dias?.length ?? 0);
              });
              final progreso = totalDias > 0
                  ? (diasCompletados / totalDias).clamp(0.0, 1.0)
                  : 0.0;

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
                      value: progreso,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                          '${(progreso * 100).round()}% completado · $diasCompletados días',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                      const Spacer(),
                      Text(_formatearMinutos(minutosTotales),
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatearMinutos(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '${h}h ${m}m total';
    return '${m}m total';
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
          final tipo = s.tipoSemana;
          final tipoColor = switch (tipo) {
            'adaptacion' => Colors.blue.shade700,
            'pico' => Colors.orange.shade700,
            'descarga' => Colors.teal.shade700,
            _ => Colors.green.shade700,
          };
          final tipoLabel = switch (tipo) {
            'adaptacion' => 'Preparación',
            'pico' => 'Intensidad',
            'descarga' => 'Recuperación',
            _ => '',
          };
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
                if (tipoLabel.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: tipoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tipoLabel,
                        style: TextStyle(
                            fontSize: 8,
                            color: tipoColor,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            selected: _semanaSeleccionada == i,
            onSelected: (_) => setState(() => _semanaSeleccionada = i),
          );
        },
      ),
    );
  }

  void _mostrarCelebracion() {
    showDialog(
      context: context,
      builder: (ctx) => const _CelebracionDialog(),
    );
  }

  Widget _buildBotonCompletarRutina(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _completando ? null : _completarRutina,
            icon: _completando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.emoji_events_rounded),
            label: Text(_completando ? 'Completando...' : 'Completar rutina'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF006E2D),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonReutilizarRutina(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _reutilizando ? null : _reutilizarRutina,
            icon: _reutilizando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh_rounded),
            label:
                Text(_reutilizando ? 'Reutilizando...' : 'Reutilizar rutina'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completarRutina() async {
    setState(() => _completando = true);
    try {
      await Supabase.instance.client
          .from('rutinas')
          .update({'estado': 'completado'}).eq('id', widget.rutinaId);
      if (mounted) {
        setState(() => _completando = false);
        ref.invalidate(rutinasUsuarioProvider);
        ref.invalidate(semanasDeRutinaProvider(widget.rutinaId));
        context.go('/bienestar');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _completando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al completar: $e')),
        );
      }
    }
  }

  Future<void> _reutilizarRutina() async {
    setState(() => _reutilizando = true);
    final client = Supabase.instance.client;
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('No autenticado');

      final rutinaMap = await client
          .from('rutinas')
          .select('nombre, descripcion, objetivo')
          .eq('id', widget.rutinaId)
          .maybeSingle();
      if (rutinaMap == null) throw Exception('Rutina no encontrada');

      final nuevaRutina = await client
          .from('rutinas')
          .insert({
            'usuario_id': user.id,
            'nombre': '${rutinaMap['nombre']} (copia)',
            'descripcion': rutinaMap['descripcion'],
            'visibilidad': 'private',
            'objetivo': rutinaMap['objetivo'],
            'cantidad_ejercicios': 0,
          })
          .select('id')
          .single();
      final nuevoId = nuevaRutina['id'] as String;

      final semanas = await client
          .from('semanas_rutina')
          .select()
          .eq('rutina_id', widget.rutinaId)
          .order('numero_semana', ascending: true);

      int totalEjercicios = 0;
      for (final sMap in semanas) {
        final nuevaSemana = await client
            .from('semanas_rutina')
            .insert({
              'rutina_id': nuevoId,
              'numero_semana': sMap['numero_semana'],
              'nombre': sMap['nombre'],
              'tipo_semana': sMap['tipo_semana'],
            })
            .select('id')
            .single();
        final nuevoSemanaId = nuevaSemana['id'] as String;

        final dias = await client
            .from('dias_rutina')
            .select()
            .eq('semana_id', sMap['id'])
            .order('numero_dia', ascending: true);

        for (final dMap in dias) {
          final nuevoDia = await client
              .from('dias_rutina')
              .insert({
                'semana_id': nuevoSemanaId,
                'numero_dia': dMap['numero_dia'],
                'nombre': dMap['nombre'],
              })
              .select('id')
              .single();
          final nuevoDiaId = nuevoDia['id'] as String;

          final ejercicios = await client
              .from('seleccion_de_ejercicios')
              .select()
              .eq('dia_id', dMap['id'])
              .order('indice_orden', ascending: true);

          if ((ejercicios as List).isNotEmpty) {
            final rows = ejercicios.map((eMap) {
              final row = <String, dynamic>{
                'rutina_id': nuevoId,
                'ejercicio_id': eMap['ejercicio_id'],
                'dia_id': nuevoDiaId,
                'series': eMap['series'],
                'repeticiones': eMap['repeticiones'],
                'segundos_descanso': eMap['segundos_descanso'],
                'indice_orden': eMap['indice_orden'],
              };
              if (eMap['peso_kg'] != null) row['peso_kg'] = eMap['peso_kg'];
              if (eMap['pesos_kg'] != null) row['pesos_kg'] = eMap['pesos_kg'];
              if (eMap['duracion_segundos'] != null) {
                row['duracion_segundos'] = eMap['duracion_segundos'];
              }
              if (eMap['distancia_metros'] != null) {
                row['distancia_metros'] = eMap['distancia_metros'];
              }
              if (eMap['tiempo_isometrico_segundos'] != null) {
                row['tiempo_isometrico_segundos'] =
                    eMap['tiempo_isometrico_segundos'];
              }
              return row;
            }).toList();
            await client.from('seleccion_de_ejercicios').insert(rows);
            totalEjercicios += ejercicios.length;
          }
        }
      }

      await client.from('rutinas').update({
        'cantidad_ejercicios': totalEjercicios,
      }).eq('id', nuevoId);

      if (mounted) {
        setState(() => _reutilizando = false);
        ref.invalidate(rutinasUsuarioProvider);
        context.go('/bienestar/rutina/$nuevoId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reutilizando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reutilizar: $e')),
        );
      }
    }
  }

  Future<void> _editarRutina() async {
    final semanas = ref.read(semanasDeRutinaProvider(widget.rutinaId));
    final todasCompletadas =
        semanas.valueOrNull?.every((s) => s.estado == 'completada') ?? false;
    if (todasCompletadas) return;
    final client = Supabase.instance.client;
    final data = await client
        .from('rutinas')
        .select('nombre, descripcion, visibilidad, objetivo')
        .eq('id', widget.rutinaId)
        .maybeSingle();
    if (data == null) return;

    final nombreCtrl =
        TextEditingController(text: data['nombre'] as String? ?? '');
    final descCtrl =
        TextEditingController(text: data['descripcion'] as String? ?? '');
    String visibilidad = data['visibilidad'] as String? ?? 'private';
    String objetivo = sanitizarObjetivo(
        data['objetivo'] as String? ?? 'Hipertrofia Muscular');

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Editar rutina'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'private', label: Text('Privada')),
                    ButtonSegment(value: 'friends', label: Text('Amigos')),
                    ButtonSegment(value: 'public', label: Text('Pública')),
                  ],
                  selected: {visibilidad},
                  onSelectionChanged: (v) => setD(() => visibilidad = v.first),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: objetivo,
                  decoration: const InputDecoration(labelText: 'Objetivo'),
                  items: finalidadesEstandar
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setD(() => objetivo = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      await client.from('rutinas').update({
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descCtrl.text.trim(),
        'visibilidad': visibilidad,
        'objetivo': objetivo,
      }).eq('id', widget.rutinaId);
      await reactivarSiCompletada(widget.rutinaId, ref);
      ref.invalidate(rutinasUsuarioProvider);
      ref.invalidate(rutinasComunidadProvider);
      if (mounted) setState(() {});
    }
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
        if (dias.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(children: [
              const EmptyState(
                  title: 'Sin días',
                  message: 'Añade días de entrenamiento a esta semana.',
                  icon: Icons.today_rounded),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                  onPressed: () =>
                      agregarDiaASemana(semanaId, 1, rutinaId, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir día')),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: dias.length + 1,
          itemBuilder: (context, i) {
            if (i == dias.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                    onPressed: () => agregarDiaASemana(
                        semanaId, dias.length + 1, rutinaId, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Añadir día',
                        style: TextStyle(fontSize: 12))),
              );
            }
            return _DiaCard(
                key: ValueKey(dias[i].id), dia: dias[i], rutinaId: rutinaId);
          },
        );
      },
    );
  }
}

class _DiaCard extends ConsumerStatefulWidget {
  const _DiaCard({required this.dia, required this.rutinaId, super.key});

  final DiaRutinaDb dia;
  final String rutinaId;

  @override
  ConsumerState<_DiaCard> createState() => _DiaCardState();
}

class _DiaCardState extends ConsumerState<_DiaCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ejerciciosAsync = ref.watch(ejerciciosDeDiaProvider(widget.dia.id));
    final completado = widget.dia.estado == 'completado';

    final tiempoDia = ref.watch(tiempoDiaProvider(widget.dia.id));

    final tieneEjercicios =
        ejerciciosAsync.whenOrNull(data: (e) => e.isNotEmpty) ?? false;

    // Verifica si este dia es el dia pendiente actual
    final diaPend = ref.watch(diaPendienteProvider).valueOrNull;
    final esHoy = diaPend != null && diaPend['diaId'] == widget.dia.id;

    return Card(
      elevation: completado ? 0 : 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: completado ? Colors.green.withValues(alpha: 0.04) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: completado
              ? Colors.green.withValues(alpha: 0.5)
              : _expandido
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: tieneEjercicios
            ? () => setState(() => _expandido = !_expandido)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                  theme, completado, tiempoDia, tieneEjercicios, esHoy),
              if (_expandido && tieneEjercicios) ...[
                const SizedBox(height: 10),
                ejerciciosAsync.when(
                  data: (ejercicios) {
                    return Column(
                      children: [
                        ...ejercicios.asMap().entries.map((entry) {
                          return _EjercicioRow(
                            index: entry.key + 1,
                            ejercicio: entry.value,
                            diaId: widget.dia.id,
                            semanaId: widget.dia.semanaId,
                            rutinaId: widget.rutinaId,
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
              ] else if (!_expandido && tieneEjercicios)
                ejerciciosAsync.when(
                  data: (ejercicios) => _buildPreview(theme, ejercicios),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                )
              else if (!tieneEjercicios)
                ejerciciosAsync.when(
                  data: (_) => Padding(
                    padding: const EdgeInsets.only(left: 42, top: 4),
                    child: Row(
                      children: [
                        Text('Sin ejercicios aún.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: SVColors.onSurfaceMuted)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _mostrarBuscador(context, ref),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Añadir ejercicio',
                              style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool completado,
      AsyncValue<int> tiempoDia, bool tieneEjercicios, bool esHoy) {
    return Row(
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
            completado ? Icons.check_circle : Icons.fitness_center_rounded,
            size: 16,
            color: completado ? Colors.green : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.dia.nombre.isNotEmpty
                          ? widget.dia.nombre
                          : 'Día ${widget.dia.numeroDia}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  // Badge "Hoy" cuando el dia coincide con el dia pendiente
                  if (esHoy && !completado) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Hoy',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF9800))),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (tieneEjercicios)
                    AnimatedRotation(
                      turns: _expandido ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: Colors.grey.shade500),
                    ),
                ],
              ),
              tiempoDia.when(
                data: (mins) => mins > 0
                    ? Text('${mins}min',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600))
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (completado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<int?>(
                future: _contarEjerciciosDelDia(),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  if (count == 0 &&
                      snap.connectionState == ConnectionState.done) {
                    return TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Este día no tiene ejercicios. Añade al menos uno antes de iniciar.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Iniciar',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        disabledBackgroundColor:
                            Colors.grey.withValues(alpha: 0.08),
                        disabledForegroundColor: Colors.grey,
                      ),
                    );
                  }
                  return TextButton.icon(
                    onPressed: () => context.push(
                      '/bienestar/rutina/sesion',
                      extra: {
                        'rutinaId': widget.rutinaId,
                        'diaId': widget.dia.id,
                        'semanaId': widget.dia.semanaId,
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
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Eliminar día',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _confirmarEliminarDia(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme, List<SeleccionEjercicioDb> ejercicios) {
    final count = ejercicios.length;
    final preview = ejercicios.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...preview.asMap().entries.map((entry) {
          final e = entry.value;
          return FutureBuilder<Map<String, dynamic>?>(
            future: Supabase.instance.client
                .from('ejercicios')
                .select('nombre, modalidad_entrenamiento, es_circuito')
                .eq('id', e.ejercicioId)
                .maybeSingle(),
            builder: (context, snap) {
              final nombre = snap.data?['nombre'] as String? ?? 'Ejercicio';
              final modalidad =
                  snap.data?['modalidad_entrenamiento'] as String? ?? '';
              final esCircuito = (snap.data?['es_circuito'] as bool?) ?? false;
              return Padding(
                padding: const EdgeInsets.only(left: 42, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nombre,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (modalidad.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(modalidad,
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary)),
                          ),
                        Text(
                          '${e.series}×${e.repeticiones}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Row(children: [
                        if (esCircuito)
                          Text('Circuito · ',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500)),
                        if (e.pesosKg != null && e.pesosKg!.any((w) => w > 0))
                          Text(
                            e.pesosKg!
                                .where((w) => w > 0)
                                .map((w) => w.toStringAsFixed(
                                    w == w.roundToDouble() ? 0 : 1))
                                .join('/'),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400),
                          )
                        else if (e.pesoKg != null && e.pesoKg! > 0)
                          Text(
                            '${e.pesoKg!.toStringAsFixed(e.pesoKg! == e.pesoKg!.roundToDouble() ? 0 : 1)} kg',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400),
                          ),
                      ]),
                    ),
                  ],
                ),
              );
            },
          );
        }),
        if (count > 3)
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 2),
            child: Text('+ ${count - 3} ejercicios más',
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Future<int?> _contarEjerciciosDelDia() async {
    final data = await Supabase.instance.client
        .from('seleccion_de_ejercicios')
        .select('id')
        .eq('dia_id', widget.dia.id);
    return (data as List).length;
  }

  void _mostrarBuscador(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _BuscadorEjerciciosSheet(onSelected: (id, nombre) {
        agregarEjercicioADia(
            rutinaId: widget.rutinaId,
            diaId: widget.dia.id,
            ejercicioId: id,
            series: 3,
            repeticiones: 10,
            segundosDescanso: 90,
            ref: ref);
        _invalidarDiaSiCompletado(ref);
      }),
    );
  }

  Future<void> _confirmarEliminarDia() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar día'),
        content:
            Text('¿Eliminar "${widget.dia.nombre}" y todos sus ejercicios?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await eliminarDiaDeSemana(
          widget.dia.id, widget.dia.semanaId, widget.rutinaId, ref);
    }
  }

  void _invalidarDiaSiCompletado(WidgetRef ref) {
    if (widget.dia.estado == 'completado') {
      final client = Supabase.instance.client;
      client
          .from('dias_rutina')
          .update({'estado': 'pendiente'}).eq('id', widget.dia.id);
      ref.invalidate(diasDeSemanaProvider(widget.dia.semanaId));
      ref.invalidate(semanasDeRutinaProvider(widget.rutinaId));
    }
  }
}

class _EjercicioRow extends ConsumerStatefulWidget {
  const _EjercicioRow(
      {required this.index,
      required this.ejercicio,
      required this.diaId,
      required this.semanaId,
      required this.rutinaId});

  final int index;
  final SeleccionEjercicioDb ejercicio;
  final String diaId;
  final String semanaId;
  final String rutinaId;

  @override
  ConsumerState<_EjercicioRow> createState() => _EjercicioRowState();
}

class _EjercicioRowState extends ConsumerState<_EjercicioRow> {
  bool _editando = false;
  late int _series, _reps, _descanso;
  late double? _peso;
  late List<double> _pesosKg;
  late bool _mismoPeso;
  late int? _duracionSegundos;
  late int? _distanciaMetros;
  late int? _tiempoIsometrico;

  final _pesoCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _distanciaCtrl = TextEditingController();
  final _tiempoIsoCtrl = TextEditingController();
  List<TextEditingController> _pesosKgCtrls = [];

  @override
  void initState() {
    super.initState();
    _initFromEjercicio();
  }

  void _initFromEjercicio() {
    final e = widget.ejercicio;
    _series = e.series;
    _reps = e.repeticiones;
    _descanso = e.segundosDescanso;
    _peso = e.pesoKg;
    _pesosKg = e.pesosKg ?? List.filled(e.series, 0.0);
    _mismoPeso = e.pesosKg == null;
    _duracionSegundos = e.duracionSegundos;
    _distanciaMetros = e.distanciaMetros;
    _tiempoIsometrico = e.tiempoIsometricoSegundos;
    _syncCtrls();
    _initPesosKgCtrls();
  }

  void _syncCtrls() {
    _pesoCtrl.text = (_peso ?? 0) > 0
        ? (_peso! == _peso!.roundToDouble()
            ? '${_peso!.toInt()}'
            : _peso!.toStringAsFixed(1))
        : '';
    _duracionCtrl.text =
        (_duracionSegundos ?? 0) > 0 ? _fmtDuracion(_duracionSegundos!) : '';
    _distanciaCtrl.text =
        (_distanciaMetros ?? 0) > 0 ? '$_distanciaMetros' : '';
    _tiempoIsoCtrl.text =
        (_tiempoIsometrico ?? 0) > 0 ? '$_tiempoIsometrico' : '';
  }

  void _initPesosKgCtrls() {
    for (final c in _pesosKgCtrls) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _pesosKgCtrls = List.generate(_pesosKg.length, (i) {
      final w = _pesosKg[i];
      return TextEditingController(
        text: w > 0
            ? (w == w.roundToDouble() ? '${w.toInt()}' : w.toStringAsFixed(1))
            : '',
      );
    });
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _duracionCtrl.dispose();
    _distanciaCtrl.dispose();
    _tiempoIsoCtrl.dispose();
    for (final c in _pesosKgCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    final updateMap = <String, dynamic>{
      'series': _series,
      'repeticiones': _reps,
      'segundos_descanso': _descanso,
      if (_peso != null) 'peso_kg': _peso,
      if (_duracionSegundos != null) 'duracion_segundos': _duracionSegundos,
      if (_distanciaMetros != null) 'distancia_metros': _distanciaMetros,
      if (_tiempoIsometrico != null)
        'tiempo_isometrico_segundos': _tiempoIsometrico,
    };
    if (_mismoPeso) {
      updateMap['pesos_kg'] = null;
    } else {
      updateMap['pesos_kg'] = _pesosKg;
    }
    await actualizarEjercicioDia(
        widget.ejercicio.id, updateMap, widget.diaId, ref);
    await reactivarSiCompletada(widget.rutinaId, ref);
    _invalidarDiaSiCompletado();
    setState(() => _editando = false);
  }

  void _invalidarDiaSiCompletado() {
    final client = Supabase.instance.client;
    client
        .from('dias_rutina')
        .select('estado')
        .eq('id', widget.diaId)
        .maybeSingle()
        .then((row) {
      if (row != null && row['estado'] == 'completado') {
        client
            .from('dias_rutina')
            .update({'estado': 'pendiente'}).eq('id', widget.diaId);
        ref.invalidate(diasDeSemanaProvider(widget.semanaId));
        ref.invalidate(semanasDeRutinaProvider(widget.rutinaId));
        ref.invalidate(ejerciciosDeDiaProvider(widget.diaId));
        ref.invalidate(nombresEjerciciosProvider(widget.diaId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.ejercicio;
    final nombresAsync = ref.watch(nombresEjerciciosProvider(widget.diaId));
    final nombre = nombresAsync.valueOrNull?[e.ejercicioId];
    final ejercicioAsync = ref.watch(ejercicioDetalleProvider(e.ejercicioId));
    final ej = ejercicioAsync.valueOrNull;
    final finalidad = ej?.finalidadPrincipal ?? 'fuerza';
    final modalidad = ej?.modalidadEntrenamiento ?? '';
    final esCircuito = ej?.esCircuito ?? false;
    return Column(
      children: [
        InkWell(
          onLongPress: () => _sustituirEjercicio(context, nombre ?? ''),
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
                    GestureDetector(
                      onTap: nombre != null
                          ? () => context
                              .push('/bienestar/ejercicio/${e.ejercicioId}')
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Text(nombre ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: nombre != null
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.3)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      if (modalidad.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(modalidad,
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary)),
                        ),
                      if (esCircuito)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Circuito',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.tertiary)),
                        ),
                      if (finalidad.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(finalidad,
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey)),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    _buildParamPills(finalidad, esCircuito, theme),
                  ])),
              if (!_editando)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.edit_note_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3)),
                ),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: () {
                    quitarEjercicioDeDia(
                        e.id, widget.diaId, widget.rutinaId, ref);
                    _invalidarDiaSiCompletado();
                  },
                  visualDensity: VisualDensity.compact),
            ]),
          ),
        ),
        if (_editando) _buildEditFields(finalidad, esCircuito),
      ],
    );
  }

  Widget _buildParamPills(String finalidad, bool esCircuito, ThemeData theme) {
    final cs = theme.colorScheme;
    final lower = finalidad.toLowerCase();

    if (lower.contains('cardio') || lower.contains('acondicionamiento')) {
      final dur = _duracionSegundos ?? 0;
      final mins = dur ~/ 60;
      final segs = dur % 60;
      final durStr = mins > 0 ? '${mins}m ${segs}s' : '${segs}s';
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _buildDisplayPill('$_series int.', cs),
          _buildDisplayPill(durStr, cs),
          if (_distanciaMetros != null)
            _buildDisplayPill('${_distanciaMetros}m', cs),
          _buildDisplayPill('${_descanso}s', cs),
        ],
      );
    }

    if (lower.contains('isometric') ||
        lower.contains('movilidad') ||
        lower.contains('flexibilidad') ||
        lower.contains('estabilidad')) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _buildDisplayPill('$_series\u00d7${_tiempoIsometrico ?? 0}s', cs),
          _buildDisplayPill('${_descanso}s', cs),
        ],
      );
    }

    if (esCircuito) {
      final dur = _duracionSegundos ?? 0;
      final mins = dur ~/ 60;
      final segs = dur % 60;
      final durStr = mins > 0 ? '${mins}m ${segs}s' : '${segs}s';
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _buildDisplayPill(durStr, cs),
          _buildDisplayPill('${_descanso}s desc', cs),
        ],
      );
    }

    final pesoStr = () {
      if (_pesosKg.any((w) => w > 0)) {
        return _pesosKg
            .where((w) => w > 0)
            .map((w) => w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1))
            .join('/');
      }
      if (_peso != null) {
        return _peso!.toStringAsFixed(_peso == _peso?.roundToDouble() ? 0 : 1);
      }
      return null;
    }();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildDisplayPill('$_series\u00d7$_reps', cs),
        _buildDisplayPill('${_descanso}s', cs),
        if (pesoStr != null) _buildDisplayPill('$pesoStr kg', cs),
      ],
    );
  }

  Widget _buildDisplayPill(String text, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.outlineVariant.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant)),
    );
  }

  Widget _buildEditFields(String finalidad, bool esCircuito) {
    final lower = finalidad.toLowerCase();
    if (lower.contains('cardio') || lower.contains('acondicionamiento')) {
      return _buildCardioEditFields();
    }
    if (lower.contains('isometric') ||
        lower.contains('movilidad') ||
        lower.contains('flexibilidad') ||
        lower.contains('estabilidad')) {
      return _buildIsometricoEditFields();
    }
    return _buildFuerzaEditFields(esCircuito: esCircuito);
  }

  Widget _buildFuerzaEditFields({bool esCircuito = false}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 48),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final anchoPill = (constraints.maxWidth - 8) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!esCircuito)
                    _paramPill('Series', _series, 1, 10, _onSeriesChanged,
                        anchoPill, cs),
                  if (!esCircuito)
                    _paramPill('Reps', _reps, 1, 50,
                        (v) => setState(() => _reps = v), anchoPill, cs),
                  if (esCircuito) _duracionPill(anchoPill, cs),
                  _paramPill('Descanso', _descanso, 15, 600,
                      (v) => setState(() => _descanso = v), anchoPill, cs,
                      sufijo: 's'),
                  _pesoPill(anchoPill, cs),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _guardarCambios,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Guardar cambios'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: cs.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSeriesChanged(int v) {
    setState(() {
      _series = v;
      if (!_mismoPeso) {
        final nuevos = List<double>.generate(
            v, (i) => i < _pesosKg.length ? _pesosKg[i] : 0.0);
        _pesosKg = nuevos;
        _initPesosKgCtrls();
      }
    });
  }

  Widget _buildCardioEditFields() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 48),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final anchoPill = (constraints.maxWidth - 8) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _paramPill('Intervalos', _series, 1, 20,
                      (v) => setState(() => _series = v), anchoPill, cs),
                  _duracionPill(anchoPill, cs),
                  _distanciaPill(anchoPill, cs),
                  _paramPill('Descanso', _descanso, 15, 600,
                      (v) => setState(() => _descanso = v), anchoPill, cs,
                      sufijo: 's'),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _guardarCambios,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Guardar cambios'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: cs.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIsometricoEditFields() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 48),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final anchoPill = (constraints.maxWidth - 8) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _paramPill('Series', _series, 1, 10, _onSeriesChanged,
                      anchoPill, cs),
                  _tiempoIsometricoPill(anchoPill, cs),
                  _paramPill('Descanso', _descanso, 15, 600,
                      (v) => setState(() => _descanso = v), anchoPill, cs,
                      sufijo: 's'),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _guardarCambios,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Guardar cambios'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: cs.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paramPill(String label, int val, int min, int max,
      void Function(int) onChange, double width, ColorScheme cs,
      {String sufijo = ''}) {
    final canDown = val > min;
    final canUp = val < max;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5)),
                  Text('$val$sufijo',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: 32,
                  height: 28,
                  child: IconButton(
                    onPressed: canUp ? () => onChange(val + 1) : null,
                    icon: Icon(Icons.keyboard_arrow_up_rounded,
                        size: 20,
                        color: canUp ? cs.primary : cs.outlineVariant),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 28,
                  child: IconButton(
                    onPressed: canDown ? () => onChange(val - 1) : null,
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: canDown ? cs.primary : cs.outlineVariant),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Peso pills (single weight + per-series)
  // ---------------------------------------------------------------------------
  Widget _pesoPill(double width, ColorScheme cs) {
    if (_mismoPeso) return _buildSingleWeightPill(width, cs);
    return _buildPerSeriesWeightSection(width, cs);
  }

  Widget _buildSingleWeightPill(double width, ColorScheme cs) {
    final pesoActual = _peso ?? 0;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Peso (kg)',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5)),
                const Spacer(),
                _pesoModeToggle(cs),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                    icon: Icons.remove,
                    onTap: () {
                      if (pesoActual > 0) {
                        final nuevo = (pesoActual - 2.5).clamp(0, 999);
                        _peso = nuevo == 0
                            ? null
                            : double.parse(nuevo.toStringAsFixed(1));
                        _pesoCtrl.text = nuevo == 0
                            ? ''
                            : nuevo.toStringAsFixed(
                                nuevo == nuevo.roundToDouble() ? 0 : 1);
                        setState(() {});
                      }
                    }),
                const SizedBox(width: 4),
                SizedBox(
                  width: 52,
                  height: 32,
                  child: TextField(
                    controller: _pesoCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: TextStyle(
                          fontSize: 18,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed != null) {
                        final limpio = parsed.clamp(0, 999).toDouble();
                        _peso = limpio == 0 ? null : limpio;
                      } else if (v.isEmpty) {
                        _peso = null;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                    icon: Icons.add,
                    onTap: () {
                      final nuevo = (pesoActual + 2.5).clamp(0, 999);
                      _peso = nuevo == 0
                          ? null
                          : double.parse(nuevo.toStringAsFixed(1));
                      _pesoCtrl.text = nuevo == 0
                          ? ''
                          : nuevo.toStringAsFixed(
                              nuevo == nuevo.roundToDouble() ? 0 : 1);
                      setState(() {});
                    }),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPerSeriesWeightSection(double width, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Peso x serie',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5)),
              const Spacer(),
              _pesoModeToggle(cs),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(_pesosKg.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}.',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 4),
                  _btnDelta(
                      icon: Icons.remove,
                      onTap: () {
                        final actual = _pesosKg[i];
                        if (actual > 0) {
                          final nuevo = (actual - 2.5).clamp(0, 999);
                          final pesos = List<double>.from(_pesosKg);
                          pesos[i] = double.parse(nuevo.toStringAsFixed(1));
                          _pesosKgCtrls[i].text = nuevo == 0
                              ? ''
                              : nuevo.toStringAsFixed(
                                  nuevo == nuevo.roundToDouble() ? 0 : 1);
                          setState(() => _pesosKg = pesos);
                        }
                      }),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 48,
                    height: 28,
                    child: TextField(
                      controller: _pesosKgCtrls[i],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '—',
                        hintStyle: TextStyle(
                            fontSize: 15,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed != null) {
                          final limpio = parsed.clamp(0, 999).toDouble();
                          final pesos = List<double>.from(_pesosKg);
                          pesos[i] = limpio;
                          setState(() => _pesosKg = pesos);
                        } else if (v.isEmpty) {
                          final pesos = List<double>.from(_pesosKg);
                          pesos[i] = 0;
                          setState(() => _pesosKg = pesos);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  _btnDelta(
                      icon: Icons.add,
                      onTap: () {
                        final actual = _pesosKg[i];
                        final nuevo = (actual + 2.5).clamp(0, 999);
                        final pesos = List<double>.from(_pesosKg);
                        pesos[i] = double.parse(nuevo.toStringAsFixed(1));
                        _pesosKgCtrls[i].text = nuevo == 0
                            ? ''
                            : nuevo.toStringAsFixed(
                                nuevo == nuevo.roundToDouble() ? 0 : 1);
                        setState(() => _pesosKg = pesos);
                      }),
                  const SizedBox(width: 8),
                  if (i == 0)
                    Text('kg',
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _pesoModeToggle(ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        if (_mismoPeso) {
          final pesos = List<double>.filled(_series, _peso ?? 0);
          _initPesosKgCtrls();
          setState(() {
            _mismoPeso = false;
            _pesosKg = pesos;
          });
        } else {
          final single = _pesosKg.any((w) => w > 0)
              ? _pesosKg.firstWhere((w) => w > 0, orElse: () => 0.0)
              : 0.0;
          _peso = single > 0 ? single : null;
          _pesoCtrl.text = single > 0
              ? (single == single.roundToDouble()
                  ? '${single.toInt()}'
                  : single.toStringAsFixed(1))
              : '';
          setState(() => _mismoPeso = true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _mismoPeso ? Icons.content_copy_rounded : Icons.tune_rounded,
              size: 12,
              color: cs.primary,
            ),
            const SizedBox(width: 2),
            Text(
              _mismoPeso ? 'Igual' : 'x serie',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Duración, Distancia, Tiempo Isométrico pills
  // ---------------------------------------------------------------------------
  Widget _duracionPill(double width, ColorScheme cs) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Duración',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                  icon: Icons.remove,
                  onTap: () {
                    final actual = _duracionSegundos ?? 0;
                    final nuevo = (actual - 30).clamp(0, 86400);
                    _duracionSegundos = nuevo == 0 ? null : nuevo;
                    _duracionCtrl.text = nuevo == 0 ? '' : _fmtDuracion(nuevo);
                    setState(() {});
                  },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 58,
                  height: 32,
                  child: TextField(
                    controller: _duracionCtrl,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'ej. 5m',
                      hintStyle: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      if (v.isEmpty) {
                        _duracionSegundos = null;
                      } else {
                        final segundos = _parseDuracion(v);
                        if (segundos > 0) _duracionSegundos = segundos;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                  icon: Icons.add,
                  onTap: () {
                    final actual = _duracionSegundos ?? 0;
                    final nuevo = (actual + 30).clamp(0, 86400);
                    _duracionSegundos = nuevo == 0 ? null : nuevo;
                    _duracionCtrl.text = nuevo == 0 ? '' : _fmtDuracion(nuevo);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _distanciaPill(double width, ColorScheme cs) {
    final distActual = _distanciaMetros ?? 0;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Distancia (m)',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                  icon: Icons.remove,
                  onTap: () {
                    if (distActual > 0) {
                      final nuevo = (distActual - 100).clamp(0, 42195);
                      _distanciaMetros = nuevo == 0 ? null : nuevo;
                      _distanciaCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 52,
                  height: 32,
                  child: TextField(
                    controller: _distanciaCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) {
                        _distanciaMetros = parsed.clamp(0, 42195);
                        if (_distanciaMetros == 0) _distanciaMetros = null;
                      } else if (v.isEmpty) {
                        _distanciaMetros = null;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                  icon: Icons.add,
                  onTap: () {
                    final nuevo = (distActual + 100).clamp(0, 42195);
                    _distanciaMetros = nuevo == 0 ? null : nuevo;
                    _distanciaCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _tiempoIsometricoPill(double width, ColorScheme cs) {
    final tiActual = _tiempoIsometrico ?? 0;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Tiempo (s)',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                  icon: Icons.remove,
                  onTap: () {
                    if (tiActual > 0) {
                      final nuevo = (tiActual - 5).clamp(0, 3600);
                      _tiempoIsometrico = nuevo == 0 ? null : nuevo;
                      _tiempoIsoCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 52,
                  height: 32,
                  child: TextField(
                    controller: _tiempoIsoCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) {
                        _tiempoIsometrico = parsed.clamp(0, 3600);
                        if (_tiempoIsometrico == 0) _tiempoIsometrico = null;
                      } else if (v.isEmpty) {
                        _tiempoIsometrico = null;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                  icon: Icons.add,
                  onTap: () {
                    final nuevo = (tiActual + 5).clamp(0, 3600);
                    _tiempoIsometrico = nuevo == 0 ? null : nuevo;
                    _tiempoIsoCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _btnDelta({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }

  String _fmtDuracion(int segundos) {
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    if (min > 0 && sec > 0) return '${min}m ${sec}s';
    if (min > 0) return '$min min';
    return '${sec}s';
  }

  int _parseDuracion(String texto) {
    texto = texto.trim().toLowerCase();
    final colon = RegExp(r'^(\d+):(\d+)$').firstMatch(texto);
    if (colon != null) {
      return int.parse(colon.group(1)!) * 60 + int.parse(colon.group(2)!);
    }
    int total = 0;
    final minMatch = RegExp(r'(\d+)\s*(?:min|m)\b').firstMatch(texto);
    final secMatch = RegExp(r'(\d+)\s*(?:seg|s)\b').firstMatch(texto);
    if (minMatch != null) total += int.parse(minMatch.group(1)!) * 60;
    if (secMatch != null) total += int.parse(secMatch.group(1)!);
    if (minMatch == null && secMatch == null) {
      final soloNum = int.tryParse(texto);
      if (soloNum != null) total = soloNum;
    }
    return total;
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
              .then((d) => d)
          : client
              .from('v_ejercicios_completos')
              .select('id, nombre')
              .ilike('nombre', '%$_q%')
              .limit(50)
              .then((d) => d),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snap.data!.isEmpty) {
          return const Center(
              child:
                  Text('Sin resultados', style: TextStyle(color: Colors.grey)));
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
              .then((d) => d)
          : client
              .from('v_ejercicios_completos')
              .select('id, nombre')
              .ilike('nombre', '%$_busqueda%')
              .limit(50)
              .then((d) => d),
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
    final o = sanitizarObjetivo(objetivo);
    final icono = iconoFinalidad(o);
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
          Text(o,
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

// =============================================================================
// Diálogo de celebración al completar la rutina
// =============================================================================

class _CelebracionDialog extends StatefulWidget {
  const _CelebracionDialog();

  @override
  State<_CelebracionDialog> createState() => _CelebracionDialogState();
}

class _CelebracionDialogState extends State<_CelebracionDialog>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_anim.value * 0.08),
              child: child,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text('¡Rutina completada!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
              'Has terminado todas las semanas.\nTu dedicación es impresionante.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.local_fire_department,
                size: 20, color: Colors.orange),
            const SizedBox(width: 4),
            Text('¡Sigue así!',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade700)),
          ]),
        ],
      ),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Gracias!')),
      ],
    );
  }
}
