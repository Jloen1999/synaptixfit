import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/image_utils.dart';
import '../application/admin_provider.dart';
import '../domain/admin_dto.dart';
import '../infrastructure/admin_repository.dart';
import 'widgets/admin_wipe_dialog.dart';

/// Panel de usuarios — Clean UI Flat Design profesional.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _rol = 'todos';
  String _orden = 'creado_en';
  bool _asc = false;
  final _sel = <String>{};
  bool _modo = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _query = _searchCtrl.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  AdminFiltrosParams get _filtros => AdminFiltrosParams(
      query: _query, rolFiltro: _rol, ordenarPor: _orden, ascendente: _asc);

  void _batchDel(List<UsuarioAdmin> list) async {
    final sel = list.where((u) => _sel.contains(u.id)).toList();
    if (sel.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${sel.length} usuarios'),
        content: Text(
            'Esta acción es IRREVERSIBLE.\n${sel.map((u) => '• ${u.nombreCompleto}').join('\n')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.person_remove, size: 18),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    for (final u in sel) {
      try {
        await eliminarUsuario(ref, u.id);
      } catch (_) {}
    }
    setState(() {
      _sel.clear();
      _modo = false;
    });
    ref.invalidate(adminUsuariosProvider(_filtros));
  }

  void _batchWipe(List<UsuarioAdmin> list) async {
    final sel = list.where((u) => _sel.contains(u.id)).toList();
    if (sel.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AdminWipeDialog(
          nombreUsuario: '${sel.length} usuarios', usuarioId: 'multiple'),
    );
    if (ok != true || !mounted) return;
    for (final u in sel) {
      try {
        await wipeUserData(ref, u.id);
      } catch (_) {}
    }
    setState(() {
      _sel.clear();
      _modo = false;
    });
    ref.invalidate(adminUsuariosProvider(_filtros));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminUsuariosProvider(_filtros));
    final cs = Theme.of(context).colorScheme;
    final list = data.valueOrNull ?? [];

    return Column(children: [
      // ── Fila de búsqueda ──
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'todos',
                  label: Text('Todos', style: TextStyle(fontSize: 11))),
              ButtonSegment(
                  value: 'admin',
                  label: Text('Admin', style: TextStyle(fontSize: 11))),
              ButtonSegment(
                  value: 'usuario',
                  label: Text('Usuario', style: TextStyle(fontSize: 11))),
            ],
            selected: {_rol},
            onSelectionChanged: (s) => setState(() => _rol = s.first),
            style: ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ]),
      ),

      // ── Orden + selección ──
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
        child: Row(children: [
          Text('${list.length} usuarios',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          const Spacer(),
          DropdownMenu<String>(
            initialSelection: _orden,
            width: 140,
            textStyle: const TextStyle(fontSize: 12),
            inputDecorationTheme: const InputDecorationTheme(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
            onSelected: (v) => setState(() => _orden = v ?? _orden),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'creado_en', label: 'Más recientes'),
              DropdownMenuEntry(value: 'nivel', label: 'Por nivel'),
              DropdownMenuEntry(value: 'xp_total', label: 'Por XP'),
              DropdownMenuEntry(value: 'racha_actual', label: 'Por racha'),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(_asc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18),
            onPressed: () => setState(() => _asc = !_asc),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(_modo ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18),
            onPressed: () => setState(() {
              _modo = !_modo;
              _sel.clear();
            }),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),

      // ── Lista ──
      Expanded(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text('Error: $e', style: TextStyle(color: cs.error))),
          data: (users) {
            if (users.isEmpty)
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_search,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(_query.isNotEmpty ? 'Sin resultados' : 'Sin usuarios',
                      style: TextStyle(color: Colors.grey.shade400)),
                ]),
              );
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(adminUsuariosProvider(_filtros)),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  final sel = _sel.contains(u.id);
                  final rolColor = u.rol == 'admin'
                      ? Colors.amber.shade700
                      : Colors.blueGrey;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: sel
                              ? cs.primary
                              : cs.outlineVariant.withValues(alpha: 0.3),
                          width: sel ? 2 : 1),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (_modo)
                          setState(
                              () => sel ? _sel.remove(u.id) : _sel.add(u.id));
                        else
                          context.push('/admin/usuario/${u.id}');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(children: [
                          ClipOval(
                            child: SizedBox(
                                width: 40,
                                height: 40,
                                child: u.urlAvatar != null &&
                                        u.urlAvatar!.isNotEmpty
                                    ? Image.network(
                                        normalizarUrlAvatar(u.urlAvatar!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatar(u.nombreCompleto, 16))
                                    : _avatar(u.nombreCompleto, 16)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(
                                        child: Text(u.nombreCompleto,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 6),
                                    _badge(u.rol.toUpperCase(), rolColor),
                                    if (u.isShadowbanned) ...[
                                      const SizedBox(width: 4),
                                      _badge('SB', const Color(0xFF7B2D8E))
                                    ],
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(u.email,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.45)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    _tag('Nv.${u.nivel}', Icons.stars_rounded,
                                        Colors.amber, cs),
                                    const SizedBox(width: 8),
                                    _tag(
                                        '${u.xpTotal} XP',
                                        Icons.emoji_events_outlined,
                                        Colors.purple,
                                        cs),
                                    const SizedBox(width: 8),
                                    _tag(
                                        '${u.rachaActual} racha',
                                        Icons.local_fire_department_rounded,
                                        Colors.deepOrange,
                                        cs),
                                  ]),
                                ]),
                          ),
                          if (!_modo)
                            PopupMenuButton<String>(
                              onSelected: (a) => _act(context, ref, a, u),
                              icon: Icon(Icons.more_vert,
                                  size: 18,
                                  color: cs.onSurface.withValues(alpha: 0.3)),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                    value: 'detalle',
                                    child: ListTile(
                                        leading: const Icon(Icons.visibility,
                                            size: 18),
                                        title: const Text('Ver detalle'),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact)),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                    value: 'cambiar_rol',
                                    child: ListTile(
                                        leading: const Icon(
                                            Icons.manage_accounts,
                                            size: 18),
                                        title: Text(u.rol == 'admin'
                                            ? 'Quitar admin'
                                            : 'Hacer admin'),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact)),
                                PopupMenuItem(
                                    value: 'shadowban',
                                    child: ListTile(
                                        leading: Icon(
                                            u.isShadowbanned
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: 18),
                                        title: Text(u.isShadowbanned
                                            ? 'Quitar shadowban'
                                            : 'Shadowban'),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact)),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                    value: 'wipe',
                                    child: ListTile(
                                        leading: const Icon(
                                            Icons.delete_forever,
                                            size: 18,
                                            color: Colors.orange),
                                        title: const Text('Wipe datos',
                                            style: TextStyle(
                                                color: Colors.orange)),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact)),
                                PopupMenuItem(
                                    value: 'eliminar',
                                    child: ListTile(
                                        leading: const Icon(Icons.person_remove,
                                            size: 18, color: Colors.red),
                                        title: const Text('Eliminar',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact)),
                              ],
                            ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),

      // ── Barra batch ──
      if (_modo && _sel.isNotEmpty)
        Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Text('${_sel.length} seleccionados',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.orange),
                tooltip: 'Wipe',
                onPressed: () => _batchWipe(list),
                visualDensity: VisualDensity.compact),
            IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.red),
                tooltip: 'Eliminar',
                onPressed: () => _batchDel(list),
                visualDensity: VisualDensity.compact),
          ]),
        ),
    ]);
  }

  Widget _badge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4)),
        child: Text(t,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: c,
                letterSpacing: 0.4)),
      );

  Widget _tag(String t, IconData i, Color c, ColorScheme cs) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 11, color: c.withValues(alpha: 0.6)),
        const SizedBox(width: 2),
        Text(t,
            style: TextStyle(
                fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
      ]);

  Widget _avatar(String n, double fs) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Text(n.isNotEmpty ? n[0].toUpperCase() : '?',
            style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700)),
      );

  void _act(BuildContext c, WidgetRef r, String a, UsuarioAdmin u) {
    switch (a) {
      case 'detalle':
        context.push('/admin/usuario/${u.id}');
      case 'cambiar_rol':
        final nr = u.rol == 'admin' ? 'usuario' : 'admin';
        cambiarRolUsuario(r, u.id, nr);
        ScaffoldMessenger.of(c).showSnackBar(SnackBar(
            content: Text('Rol cambiado a $nr'),
            backgroundColor: Colors.green));
      case 'shadowban':
        toggleShadowbanUsuario(r, u.id, !u.isShadowbanned);
        ScaffoldMessenger.of(c).showSnackBar(SnackBar(
            content: Text(
                u.isShadowbanned ? 'Shadowban quitado' : 'Shadowban aplicado'),
            backgroundColor: Colors.green));
      case 'wipe':
        _confirmWipe(c, r, u);
      case 'eliminar':
        _confirmDel(c, r, u);
    }
  }

  void _confirmWipe(BuildContext c, WidgetRef r, UsuarioAdmin u) async {
    final ok = await showDialog<bool>(
        context: c,
        builder: (ctx) =>
            AdminWipeDialog(nombreUsuario: u.nombreCompleto, usuarioId: u.id));
    if (ok == true && c.mounted) {
      final res = await wipeUserData(r, u.id);
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(
        content: Text(res['success'] == true
            ? 'Wipe completado'
            : 'Error: ${res['error']}'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ));
    }
  }

  void _confirmDel(BuildContext c, WidgetRef r, UsuarioAdmin u) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Colors.red),
          SizedBox(width: 8),
          Text('Eliminar usuario', style: TextStyle(fontSize: 17))
        ]),
        content: Text(
            '¿Eliminar permanentemente a ${u.nombreCompleto} (${u.email})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.person_remove, size: 16),
              label: const Text('Eliminar'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red)),
        ],
      ),
    );
    if (ok == true && c.mounted) {
      final res = await eliminarUsuario(r, u.id);
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(
        content: Text(
            res['success'] == true ? 'Eliminado' : 'Error: ${res['error']}'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ));
    }
  }
}
