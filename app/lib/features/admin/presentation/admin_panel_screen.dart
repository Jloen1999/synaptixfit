import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/image_utils.dart';
import '../application/admin_provider.dart';
import '../domain/admin_dto.dart';
import '../infrastructure/admin_repository.dart';
import 'widgets/admin_wipe_dialog.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _rolFiltro = 'todos';
  String _ordenarPor = 'creado_en';
  bool _ascendente = false;
  final Set<String> _selectedIds = {};
  bool _modoSeleccion = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = _searchController.text.trim());
    });
  }

  AdminFiltrosParams get _filtros => AdminFiltrosParams(
        query: _query,
        rolFiltro: _rolFiltro,
        ordenarPor: _ordenarPor,
        ascendente: _ascendente,
      );

  void _toggleSeleccion(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleModoSeleccion() {
    setState(() {
      _modoSeleccion = !_modoSeleccion;
      if (!_modoSeleccion) _selectedIds.clear();
    });
  }

  void _seleccionarTodos(List<UsuarioAdmin> usuarios) {
    setState(() {
      if (_selectedIds.length == usuarios.length) {
        _selectedIds.clear();
        _modoSeleccion = false;
      } else {
        _selectedIds.addAll(usuarios.map((u) => u.id));
      }
    });
  }

  Future<void> _batchEliminar(List<UsuarioAdmin> usuarios) async {
    final seleccionados =
        usuarios.where((u) => _selectedIds.contains(u.id)).toList();
    if (seleccionados.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${seleccionados.length} usuarios'),
        content: Text(
            'Vas a eliminar permanentemente a:\n${seleccionados.map((u) => '• ${u.nombreCompleto}').join('\n')}\n\nEsta acción es IRREVERSIBLE.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.person_remove, size: 18),
            label: const Text('Eliminar todos'),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    for (final u in seleccionados) {
      if (!mounted) return;
      try {
        await eliminarUsuario(ref, u.id);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      _modoSeleccion = false;
    });
    ref.invalidate(adminUsuariosProvider(_filtros));
  }

  Future<void> _batchWipe(List<UsuarioAdmin> usuarios) async {
    final seleccionados =
        usuarios.where((u) => _selectedIds.contains(u.id)).toList();
    if (seleccionados.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Wipe de ${seleccionados.length} usuarios'),
        content: Text(
            'Se eliminarán todos los datos de actividad de:\n${seleccionados.map((u) => '• ${u.nombreCompleto}').join('\n')}\n\nSe conservará el perfil y la cuenta.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Ejecutar wipe'),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    for (final u in seleccionados) {
      if (!mounted) return;
      try {
        await wipeUserData(ref, u.id);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      _modoSeleccion = false;
    });
    ref.invalidate(adminUsuariosProvider(_filtros));
  }

  @override
  Widget build(BuildContext context) {
    final usuariosAsync = ref.watch(adminUsuariosProvider(_filtros));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final data = usuariosAsync.valueOrNull ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por email o nombre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        if (mounted) setState(() => _query = '');
                      },
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFiltroChip('Todos', 'todos', Icons.people),
                const SizedBox(width: 8),
                _buildFiltroChip('Admin', 'admin', Icons.admin_panel_settings),
                const SizedBox(width: 8),
                _buildFiltroChip('Usuario', 'usuario', Icons.person),
                const SizedBox(width: 12),
                _buildOrdenDropdown(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ActionChip(
                avatar: Icon(_modoSeleccion ? Icons.close : Icons.checklist,
                    size: 18),
                label: Text(_modoSeleccion
                    ? 'Cancelar selección'
                    : 'Seleccionar usuarios'),
                onPressed: _toggleModoSeleccion,
              ),
              if (_modoSeleccion)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text('${_selectedIds.length} seleccionados',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        Expanded(
          child: usuariosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: $err'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    onPressed: () =>
                        ref.invalidate(adminUsuariosProvider(_filtros)),
                  ),
                ],
              ),
            ),
            data: (usuarios) {
              if (usuarios.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _query.isNotEmpty
                            ? 'Sin resultados para "$_query"'
                            : 'No hay usuarios registrados',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminUsuariosProvider(_filtros)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: usuarios.length + (_modoSeleccion ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_modoSeleccion && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedIds.length == usuarios.length &&
                                  usuarios.isNotEmpty,
                              tristate: _selectedIds.isNotEmpty &&
                                  _selectedIds.length < usuarios.length,
                              onChanged: (_) => _seleccionarTodos(usuarios),
                            ),
                            Text(
                                '${_selectedIds.length} de ${usuarios.length} seleccionados',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      );
                    }
                    final i = _modoSeleccion ? index - 1 : index;
                    return _UsuarioAdminCard(
                      usuario: usuarios[i],
                      modoSeleccion: _modoSeleccion,
                      seleccionado: _selectedIds.contains(usuarios[i].id),
                      onToggleSeleccion: () => _toggleSeleccion(usuarios[i].id),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_modoSeleccion && _selectedIds.isNotEmpty)
          SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Text('${_selectedIds.length} seleccionados',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _batchWipe(data),
                    icon: const Icon(Icons.delete_forever),
                    color: Colors.orange,
                    tooltip: 'Wipe de datos',
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _batchEliminar(data),
                    icon: const Icon(Icons.person_remove),
                    color: Colors.red,
                    tooltip: 'Eliminar usuarios',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String valor, IconData icon) {
    final activo = _rolFiltro == valor;
    return FilterChip(
      selected: activo,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onSelected: (_) => setState(() => _rolFiltro = valor),
      showCheckmark: false,
      selectedColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildOrdenDropdown() {
    final labels = {
      'creado_en': 'Fecha registro',
      'nivel': 'Nivel',
      'xp_total': 'XP',
      'racha_actual': 'Racha',
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<String>(
          value: _ordenarPor,
          underline: const SizedBox(),
          isDense: true,
          items: AdminRepository.camposOrden.map((campo) {
            return DropdownMenuItem(
              value: campo,
              child: Text(labels[campo] ?? campo,
                  style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _ordenarPor = val);
          },
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(_ascendente ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18),
          onPressed: () => setState(() => _ascendente = !_ascendente),
          tooltip: _ascendente ? 'Ascendente' : 'Descendente',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _UsuarioAdminCard extends ConsumerWidget {
  final UsuarioAdmin usuario;
  final bool modoSeleccion;
  final bool seleccionado;
  final VoidCallback? onToggleSeleccion;

  const _UsuarioAdminCard({
    required this.usuario,
    this.modoSeleccion = false,
    this.seleccionado = false,
    this.onToggleSeleccion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolColor =
        usuario.rol == 'admin' ? Colors.amber.shade700 : Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: seleccionado
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          width: seleccionado ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (modoSeleccion) {
            onToggleSeleccion?.call();
          } else {
            context.push('/admin/usuario/${usuario.id}');
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty
                          ? Image.network(
                              normalizarUrlAvatar(usuario.urlAvatar!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(usuario),
                            )
                          : _avatarFallback(usuario),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.nombreCompleto,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(usuario.email,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rolColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(usuario.rol.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: rolColor,
                                  letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.stars_rounded,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 3),
                        Text('Nv. ${usuario.nivel}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(width: 10),
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Colors.deepOrange),
                        const SizedBox(width: 3),
                        Text('${usuario.rachaActual}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
              if (modoSeleccion)
                Checkbox(
                    value: seleccionado,
                    onChanged: (_) => onToggleSeleccion?.call())
              else
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(context, ref, action),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'detalle',
                        child: ListTile(
                            leading: Icon(Icons.visibility),
                            title: Text('Ver detalle'),
                            dense: true,
                            contentPadding: EdgeInsets.zero)),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'cambiar_rol',
                      child: ListTile(
                        leading: Icon(
                            usuario.rol == 'admin'
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: usuario.rol == 'admin'
                                ? Colors.amber.shade700
                                : null),
                        title: Text(usuario.rol == 'admin'
                            ? 'Quitar admin'
                            : 'Hacer admin'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'wipe',
                        child: ListTile(
                            leading:
                                Icon(Icons.delete_forever, color: Colors.red),
                            title: Text('Eliminar datos (Wipe)',
                                style: TextStyle(color: Colors.red)),
                            dense: true,
                            contentPadding: EdgeInsets.zero)),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'eliminar',
                        child: ListTile(
                            leading:
                                Icon(Icons.person_remove, color: Colors.red),
                            title: Text('Eliminar usuario',
                                style: TextStyle(color: Colors.red)),
                            dense: true,
                            contentPadding: EdgeInsets.zero)),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'detalle':
        context.push('/admin/usuario/${usuario.id}');
      case 'cambiar_rol':
        _showCambiarRolDialog(context, ref);
      case 'wipe':
        _showWipeDialog(context, ref);
      case 'eliminar':
        _showEliminarDialog(context, ref);
    }
  }

  void _showCambiarRolDialog(BuildContext context, WidgetRef ref) {
    final nuevoRol = usuario.rol == 'admin' ? 'usuario' : 'admin';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: Text(
            '¿${nuevoRol == 'admin' ? 'Otorgar' : 'Revocar'} permisos de administrador a ${usuario.nombreCompleto}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await cambiarRolUsuario(ref, usuario.id, nuevoRol);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Rol actualizado a "$nuevoRol" para ${usuario.nombreCompleto}'),
                      backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child:
                Text(nuevoRol == 'admin' ? 'Otorgar admin' : 'Revocar admin'),
          ),
        ],
      ),
    );
  }

  void _showWipeDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AdminWipeDialog(
          nombreUsuario: usuario.nombreCompleto, usuarioId: usuario.id),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final result = await wipeUserData(ref, usuario.id);
          if (context.mounted) {
            final success = result['success'] == true;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? 'Wipe completado. ${result['registros_eliminados']} registros eliminados.'
                    : 'Error: ${result['error'] ?? 'Desconocido'}'),
                backgroundColor: success ? Colors.green : Colors.red));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error al ejecutar wipe: $e'),
                backgroundColor: Colors.red));
          }
        }
      }
    });
  }

  void _showEliminarDialog(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    bool confirmado = false;

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
                child: Text('Eliminar usuario permanentemente',
                    style: TextStyle(fontSize: 17))),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'Vas a eliminar permanentemente a ${usuario.nombreCompleto} (${usuario.email}).\n\n'
                    'Esta acción es IRREVERSIBLE. Se eliminarán:\n'
                    '• Todos los datos personales\n'
                    '• Historial de entrenamiento\n'
                    '• Rutinas, retos e insignias\n'
                    '• Interacciones sociales\n'
                    '• Apuntes y horarios\n\n'
                    'Escribe ELIMINAR para confirmar:',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                      labelText: 'ELIMINAR',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit)),
                  onChanged: (val) => setDialogState(
                      () => confirmado = val.trim() == 'ELIMINAR'),
                ),
                const SizedBox(height: 4),
                Text('ID: ${usuario.id}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: confirmado ? () => Navigator.pop(ctx, true) : null,
              icon: const Icon(Icons.person_remove, size: 18),
              label: const Text('Eliminar usuario'),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      confirmController.dispose();
      if (confirmed == true && context.mounted) {
        try {
          final result = await eliminarUsuario(ref, usuario.id);
          if (context.mounted) {
            final success = result['success'] == true;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? 'Usuario ${result['email']} eliminado permanentemente.'
                    : 'Error: ${result['error'] ?? 'Desconocido'}'),
                backgroundColor: success ? Colors.green : Colors.red));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error al eliminar usuario: $e'),
                backgroundColor: Colors.red));
          }
        }
      }
    });
  }

  Widget _avatarFallback(UsuarioAdmin usuario) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        usuario.nombreCompleto.isNotEmpty
            ? usuario.nombreCompleto[0].toUpperCase()
            : '?',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
    );
  }
}
