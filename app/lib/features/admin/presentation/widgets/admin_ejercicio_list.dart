import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_ejercicio_provider.dart';
import '../../domain/admin_ejercicio_dto.dart';
import 'admin_paginacion_bar.dart';

/// Catálogo de ejercicios — Clean UI con búsqueda, filtros y edición.
class AdminEjercicioList extends ConsumerStatefulWidget {
  const AdminEjercicioList({super.key});

  @override
  ConsumerState<AdminEjercicioList> createState() => _AdminEjercicioListState();
}

class _AdminEjercicioListState extends ConsumerState<AdminEjercicioList> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _page = 0;
  String _query = '';
  String? _filtroDificultad;
  bool _grid = false;
  static const _porPagina = 30;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _query = _searchCtrl.text.trim();
            _page = 0;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _edit(AdminEjercicio e) => _showEdit(e);

  @override
  Widget build(BuildContext context) {
    final async =
        ref.watch(adminEjerciciosProvider((page: _page, query: _query)));
    final cs = Theme.of(context).colorScheme;
    final list = async.valueOrNull ?? [];
    final total = async.whenOrNull(data: (d) => d.length) ?? 0;
    final activos =
        async.whenOrNull(data: (d) => d.where((x) => x.activo).length) ?? 0;

    return Column(children: [
      // ── Barra superior ──
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                        })
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (total > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle,
                    size: 13, color: Colors.green.shade600),
                const SizedBox(width: 3),
                Text('$activos/$total',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700)),
              ]),
            ),
          IconButton(
              icon: Icon(_grid ? Icons.list : Icons.grid_view, size: 18),
              onPressed: () => setState(() => _grid = !_grid),
              visualDensity: VisualDensity.compact,
              tooltip: _grid ? 'Lista' : 'Cuadrícula'),
        ]),
      ),

      // ── Filtros ──
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            FilterChip(
              label: const Text('Todos', style: TextStyle(fontSize: 11)),
              selected: _filtroDificultad == null,
              onSelected: (_) => setState(() {
                _filtroDificultad = null;
                _page = 0;
              }),
            ),
            const SizedBox(width: 4),
            for (final d in ['Principiante', 'Intermedio', 'Avanzado']) ...[
              FilterChip(
                label: Text(d, style: const TextStyle(fontSize: 11)),
                selected: _filtroDificultad == d,
                onSelected: (_) => setState(() {
                  _filtroDificultad = _filtroDificultad == d ? null : d;
                  _page = 0;
                }),
              ),
              const SizedBox(width: 4),
            ],
          ]),
        ),
      ),

      // ── Contenido ──
      Expanded(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text('Error: $e', style: TextStyle(color: cs.error))),
          data: (items) {
            final filtered = _filtroDificultad != null
                ? items
                    .where((x) =>
                        (x.dificultad ?? '').toLowerCase() ==
                        _filtroDificultad!.toLowerCase())
                    .toList()
                : items;
            if (filtered.isEmpty)
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.fitness_center,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(_query.isNotEmpty ? 'Sin resultados' : 'Sin ejercicios',
                      style: TextStyle(color: Colors.grey.shade400)),
                ]),
              );
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                    adminEjerciciosProvider((page: _page, query: _query)));
              },
              child:
                  _grid ? _buildGrid(filtered, cs) : _buildList(filtered, cs),
            );
          },
        ),
      ),

      AdminPaginacionBar(
          paginaActual: _page,
          totalPaginas: total >= _porPagina ? _page + 2 : _page + 1,
          onPageChanged: (p) => setState(() => _page = p)),
    ]);
  }

  Widget _buildList(List<AdminEjercicio> items, ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: items.length,
      itemBuilder: (_, i) => _EjercicioTile(
          ejercicio: items[i],
          onToggle: (v) async {
            await toggleEjercicioActivo(ref,
                id: items[i].id, nombre: items[i].nombre, activo: v);
            ref.invalidate(
                adminEjerciciosProvider((page: _page, query: _query)));
          },
          onEdit: () => _edit(items[i])),
    );
  }

  Widget _buildGrid(List<AdminEjercicio> items, ColorScheme cs) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => _EjercicioCard(
          ejercicio: items[i],
          onToggle: (v) async {
            await toggleEjercicioActivo(ref,
                id: items[i].id, nombre: items[i].nombre, activo: v);
            ref.invalidate(
                adminEjerciciosProvider((page: _page, query: _query)));
          },
          onEdit: () => _edit(items[i])),
    );
  }

  void _showEdit(AdminEjercicio e) {
    final nombre = TextEditingController(text: e.nombre);
    final dif = TextEditingController(text: e.dificultad ?? '');
    final mod = TextEditingController(text: e.modalidadEntrenamiento ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar ejercicio', style: TextStyle(fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nombre,
                decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 10),
            TextField(
                controller: dif,
                decoration: const InputDecoration(
                    labelText: 'Dificultad',
                    border: OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 10),
            TextField(
                controller: mod,
                decoration: const InputDecoration(
                    labelText: 'Modalidad',
                    border: OutlineInputBorder(),
                    isDense: true)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () async {
              await actualizarEjercicio(
                ref,
                id: e.id,
                nombre: nombre.text.trim().isEmpty ? null : nombre.text.trim(),
                dificultad: dif.text.trim().isEmpty ? null : dif.text.trim(),
                modalidadEntrenamiento:
                    mod.text.trim().isEmpty ? null : mod.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(
                  adminEjerciciosProvider((page: _page, query: _query)));
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

/// Tile compacto para modo lista.
class _EjercicioTile extends StatelessWidget {
  final AdminEjercicio ejercicio;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _EjercicioTile(
      {required this.ejercicio, required this.onToggle, required this.onEdit});

  static const _colores = {
    'principiante': Color(0xFF4CAF50),
    'intermedio': Color(0xFFFF9800),
    'avanzado': Color(0xFFE53935)
  };

  Color get _acento =>
      _colores[ejercicio.dificultad?.toLowerCase()] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(
                color: ejercicio.activo ? _acento : Colors.grey.shade300,
                width: 3)),
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ejercicio.nombre,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: ejercicio.activo
                                ? cs.onSurface
                                : Colors.grey.shade400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(spacing: 4, runSpacing: 2, children: [
                      if (ejercicio.dificultad != null)
                        _tag(ejercicio.dificultad!, _acento),
                      if (ejercicio.modalidadEntrenamiento != null)
                        _tag(ejercicio.modalidadEntrenamiento!,
                            const Color(0xFF1565C0)),
                    ]),
                  ]),
            ),
            Switch(
              value: ejercicio.activo,
              onChanged: onToggle,
              activeColor: _acento,
            ),
            IconButton(
              icon: Icon(Icons.edit,
                  size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
              onPressed: onEdit,
            ),
          ]),
        ),
      ), // Card
    ); // Container
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4)),
        child: Text(t,
            style:
                TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
      );
}

/// Card compacto para modo grid.
class _EjercicioCard extends StatelessWidget {
  final AdminEjercicio ejercicio;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _EjercicioCard(
      {required this.ejercicio, required this.onToggle, required this.onEdit});

  static const _colores = {
    'principiante': Color(0xFF4CAF50),
    'intermedio': Color(0xFFFF9800),
    'avanzado': Color(0xFFE53935)
  };

  Color get _acento =>
      _colores[ejercicio.dificultad?.toLowerCase()] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(
                color: ejercicio.activo ? _acento : Colors.grey.shade300,
                width: 3)),
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(ejercicio.nombre,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: ejercicio.activo
                              ? cs.onSurface
                              : Colors.grey.shade400),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)),
              Switch(
                  value: ejercicio.activo,
                  onChanged: onToggle,
                  activeColor: _acento,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ]),
            const Spacer(),
            Wrap(spacing: 3, runSpacing: 2, children: [
              if (ejercicio.dificultad != null)
                _tag(ejercicio.dificultad!, _acento),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.edit,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.3)))),
            ]),
          ]),
        ),
      ), // Card
    ); // Container
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(3)),
        child: Text(t,
            style:
                TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: c)),
      );
}
