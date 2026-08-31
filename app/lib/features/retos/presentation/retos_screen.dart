import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/string_utils.dart';
import '../../../shared/widgets/badge_reutilizado.dart';
import '../../../shared/widgets/challenge_progress_bar.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/retos_provider.dart';
import 'crear_reto_simple_sheet.dart';

/// Vista unificada de retos: muestra activos y completados con filtros.
class RetosScreen extends ConsumerStatefulWidget {
  const RetosScreen({super.key});

  @override
  ConsumerState<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends ConsumerState<RetosScreen> {
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';
  String _vista = 'mios'; // 'mios' | 'comunidad'
  String? _filtroEstado = 'activos'; // 'activos' | 'completados' | null (todos)
  String? _filtroTipo; // null | 'fitness' | 'academic'
  String? _filtroTareas; // null | 'con' | 'sin'

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  bool get _esComunidad => _vista == 'comunidad';

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Retos',
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarCrearRetoSimpleSheet(context),
        child: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          // Navegación principal: Mis retos / Comunidad
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'mios',
                    label: Text('Mis retos'),
                    icon: Icon(Icons.flag_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 'comunidad',
                    label: Text('Comunidad'),
                    icon: Icon(Icons.public_rounded, size: 16),
                  ),
                ],
                selected: {_vista},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _vista = s.first),
              ),
            ),
          ),

          // Búsqueda (+ filtros avanzados solo en «Mis retos»)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: InputDecoration(
                      hintText: _esComunidad
                          ? 'Buscar en la comunidad...'
                          : 'Buscar por título...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _busquedaCtrl.clear();
                                setState(() => _busqueda = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) =>
                        setState(() => _busqueda = normalizeSearch(v)),
                  ),
                ),
                if (!_esComunidad) ...[
                  const SizedBox(width: 8),
                  _BotonFiltros(
                    activos: _hayFiltrosAvanzados,
                    onTap: _abrirFiltros,
                  ),
                ],
              ],
            ),
          ),

          // Filtro rápido de estado (solo en «Mis retos»)
          if (!_esComunidad) _buildEstadoChips(),

          const SizedBox(height: 6),
          // Lista
          Expanded(
            child: _esComunidad ? _buildListaComunidad() : _buildLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChips() {
    Widget chip(String label, String? value) {
      final selected = _filtroEstado == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => setState(() => _filtroEstado = value),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        children: [
          chip('Activos', 'activos'),
          chip('Completados', 'completados'),
          chip('Todos', null),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lista de retos públicos de la comunidad
  // ---------------------------------------------------------------------------
  Widget _buildListaComunidad() {
    final async = ref.watch(retosPublicosProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (retos) {
        if (retos.isEmpty) {
          return const EmptyState(
            icon: Icons.public_off,
            title: 'Sin retos públicos',
            message: 'Aún no hay retos compartidos por la comunidad.',
          );
        }

        var filtrados = retos;
        if (_busqueda.isNotEmpty) {
          filtrados = retos
              .where((r) =>
                  normalizeSearch(r.reto.titulo).contains(_busqueda) ||
                  normalizeSearch(r.reto.meta).contains(_busqueda))
              .toList();
        }

        if (filtrados.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.search_off,
              title: 'Sin resultados',
              message: 'No hay retos que coincidan con tu búsqueda.',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(retosPublicosProvider);
            return ref.read(retosPublicosProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            itemCount: filtrados.length,
            itemBuilder: (context, index) {
              final item = filtrados[index];
              return _RetoComunidadCard(
                item: item,
                onTap: () => context.push('/retos/${item.reto.id}'),
                onClonar: () => _clonarReto(item),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _clonarReto(RetoResumen item) async {
    final nuevoId = await clonarReto(item.reto.id, ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(nuevoId != null
              ? 'Reto "${item.reto.titulo}" añadido a tus retos'
              : 'No se pudo copiar el reto'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    if (nuevoId != null) setState(() => _vista = 'mios');
  }

  // ---------------------------------------------------------------------------
  // Lista unificada (activos + completados) con filtros aplicados
  // ---------------------------------------------------------------------------
  Widget _buildLista() {
    final async = ref.watch(todosRetosProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (retos) {
        // Aplicar filtros
        var filtrados = _aplicarFiltros(retos);

        if (retos.isEmpty) {
          return const EmptyState(
            icon: Icons.flag_outlined,
            title: 'Sin retos',
            message: 'Crea tu primer reto para empezar.',
          );
        }

        if (filtrados.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.search_off,
              title: 'Sin resultados',
              message: 'No hay retos que coincidan con los filtros.',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todosRetosProvider);
            return ref.read(todosRetosProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            itemCount: filtrados.length,
            itemBuilder: (context, index) {
              final item = filtrados[index];
              final completado =
                  item.reto.estaCompletado || item.progreso >= 1.0;
              return _RetoCard(
                item: item,
                onComplete: completado
                    ? null
                    : () => _confirmarCompletar(context, item.reto.id),
                onTap: () => context.push('/retos/${item.reto.id}'),
                onEdit: () =>
                    mostrarCrearRetoSimpleSheet(context, retoId: item.reto.id),
                onDelete: () => _confirmarEliminar(context, item),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Filtros
  // ---------------------------------------------------------------------------
  List<RetoResumen> _aplicarFiltros(List<RetoResumen> retos) {
    var filtrados = retos;

    // Filtro por estado
    if (_filtroEstado == 'activos') {
      filtrados = filtrados
          .where((r) => !r.reto.estaCompletado && r.progreso < 1.0)
          .toList();
    } else if (_filtroEstado == 'completados') {
      filtrados = filtrados
          .where((r) => r.reto.estaCompletado || r.progreso >= 1.0)
          .toList();
    }
    // _filtroEstado == null → mostrar todos

    // Búsqueda
    if (_busqueda.isNotEmpty) {
      filtrados = filtrados
          .where((r) =>
              normalizeSearch(r.reto.titulo).contains(_busqueda) ||
              normalizeSearch(r.reto.meta).contains(_busqueda))
          .toList();
    }

    // Tipo
    if (_filtroTipo != null) {
      filtrados = filtrados.where((r) => r.reto.tipo == _filtroTipo).toList();
    }

    // Tareas
    if (_filtroTareas == 'con') {
      filtrados = filtrados.where((r) => r.tieneHitos).toList();
    } else if (_filtroTareas == 'sin') {
      filtrados = filtrados.where((r) => !r.tieneHitos).toList();
    }

    return filtrados;
  }

  bool get _hayFiltrosAvanzados => _filtroTipo != null || _filtroTareas != null;

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          Widget chip(String label, bool sel, VoidCallback onTap) => Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: FilterChip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  selected: sel,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    onTap();
                    setSheet(() {});
                    setState(() {});
                  },
                ),
              );
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Filtros',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    if (_hayFiltrosAvanzados)
                      TextButton(
                        onPressed: () {
                          _filtroTipo = null;
                          _filtroTareas = null;
                          setSheet(() {});
                          setState(() {});
                        },
                        child: const Text('Limpiar'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Tipo',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(children: [
                  chip('Todos', _filtroTipo == null, () => _filtroTipo = null),
                  chip('Fitness', _filtroTipo == 'fitness',
                      () => _filtroTipo = 'fitness'),
                  chip('Académico', _filtroTipo == 'academic',
                      () => _filtroTipo = 'academic'),
                ]),
                const SizedBox(height: 10),
                const Text('Tareas',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(children: [
                  chip('Todas', _filtroTareas == null,
                      () => _filtroTareas = null),
                  chip('Con tareas', _filtroTareas == 'con',
                      () => _filtroTareas = 'con'),
                  chip('Sin tareas', _filtroTareas == 'sin',
                      () => _filtroTareas = 'sin'),
                ]),
              ],
            ),
          );
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Diálogo de confirmación para eliminar reto
  // ---------------------------------------------------------------------------
  void _confirmarEliminar(BuildContext context, RetoResumen item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reto'),
        content: Text(
            '¿Seguro que quieres eliminar "${item.reto.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await eliminarReto(item.reto.id, ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Reto eliminado')),
                  );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Diálogo de confirmación para completar reto
  // ---------------------------------------------------------------------------
  void _confirmarCompletar(BuildContext context, String retoId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar reto'),
        content: const Text('¿Marcar este reto como completado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await completarReto(retoId, ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.emoji_events,
                              color: Colors.amber, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('¡Reto completado!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1B5E20),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(12),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              }
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Card de reto individual
// =============================================================================
class _RetoCard extends ConsumerStatefulWidget {
  const _RetoCard({
    required this.item,
    this.onComplete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final RetoResumen item;
  final VoidCallback? onComplete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<_RetoCard> createState() => _RetoCardState();
}

class _RetoCardState extends ConsumerState<_RetoCard> {
  bool _expanded = false;
  final Map<String, bool> _optimistas = {};

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reto = item.reto;
    final tipoIcono = reto.tipo == 'fitness'
        ? Icons.fitness_center_rounded
        : Icons.school_rounded;
    final tipoColor = reto.tipo == 'fitness' ? Colors.green : Colors.blue;
    final diasRestantes = reto.fechaFin.difference(DateTime.now()).inDays;
    final textoDias = diasRestantes > 0
        ? '$diasRestantes d'
        : diasRestantes == 0
            ? 'Hoy'
            : 'Vencido';
    final completado = reto.estaCompletado || item.progreso >= 1.0;
    final expandible = item.tieneHitos && !completado;

    final tareasAsync =
        _expanded ? ref.watch(tareasDeRetoProvider(reto.id)) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tipoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(tipoIcono, size: 18, color: tipoColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reto.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: completado
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: completado ? Colors.grey : null,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reto.meta.isNotEmpty
                              ? reto.meta
                              : (reto.tipo == 'fitness'
                                  ? 'Fitness'
                                  : 'Académico'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        if (reto.esReutilizado) ...[
                          const SizedBox(height: 3),
                          const BadgeReutilizado(
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (completado)
                    const Icon(Icons.check_circle,
                        size: 18, color: Colors.green)
                  else
                    Text(
                      textoDias,
                      style: TextStyle(
                        fontSize: 11,
                        color: diasRestantes <= 3 ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  SizedBox(
                    width: 32,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      tooltip: 'Opciones',
                      onSelected: (v) {
                        if (v == 'editar') widget.onEdit();
                        if (v == 'eliminar') widget.onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'editar',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Editar'),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'eliminar',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: ChallengeProgressBar(progress: item.progreso)),
                  const SizedBox(width: 8),
                  Text('${(item.progreso * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                ],
              ),

              // Botón completar (solo si no está completado)
              if (widget.onComplete != null && !completado)
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: widget.onComplete,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Completar',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Tareas expandibles (solo para retos con tareas no completados)
              if (expandible) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expanded ? 'Ocultar tareas' : 'Ver tareas',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_expanded && tareasAsync != null)
                  tareasAsync.when(
                    data: (tareas) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          ...tareas.map((t) {
                            final tareaCompletada =
                                _optimistas.containsKey(t.id)
                                    ? _optimistas[t.id]!
                                    : t.estaCompletado;
                            return InkWell(
                              onTap: () async {
                                final nuevoValor = !tareaCompletada;
                                setState(() => _optimistas[t.id] = nuevoValor);
                                try {
                                  await toggleTareaCompletada(
                                      t.id, item.reto.id,
                                      completada: nuevoValor, ref: ref);
                                } catch (_) {
                                  if (!context.mounted) return;
                                  setState(() => _optimistas.remove(t.id));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error al ${nuevoValor ? "completar" : "desmarcar"} tarea'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      tareaCompletada
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: tareaCompletada
                                          ? Colors.green
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        t.titulo,
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration: tareaCompletada
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: tareaCompletada
                                              ? Colors.grey
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${t.porcentajePeso}%',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: widget.onTap,
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('Ver detalle',
                                  style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, _) =>
                        Text('Error: $e', style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Botón de filtros avanzados (con punto indicador si hay filtros activos)
// =============================================================================
class _BotonFiltros extends StatelessWidget {
  const _BotonFiltros({required this.activos, required this.onTap});

  final bool activos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: const Icon(Icons.tune_rounded, size: 20),
          visualDensity: VisualDensity.compact,
          tooltip: 'Filtros',
        ),
        if (activos)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Card de reto público de la comunidad (solo lectura + acción «Usar»)
// =============================================================================
class _RetoComunidadCard extends StatelessWidget {
  const _RetoComunidadCard({
    required this.item,
    required this.onTap,
    required this.onClonar,
  });

  final RetoResumen item;
  final VoidCallback onTap;
  final VoidCallback onClonar;

  @override
  Widget build(BuildContext context) {
    final reto = item.reto;
    final theme = Theme.of(context);
    final tipoIcono = reto.tipo == 'fitness'
        ? Icons.fitness_center_rounded
        : Icons.school_rounded;
    final tipoColor = reto.tipo == 'fitness' ? Colors.green : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(tipoIcono, size: 18, color: tipoColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reto.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reto.tipo == 'fitness' ? 'Fitness' : 'Académico',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onClonar,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Usar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
