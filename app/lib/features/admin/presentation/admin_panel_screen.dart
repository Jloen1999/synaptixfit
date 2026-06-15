import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/admin_provider.dart';
import '../domain/admin_dto.dart';
import 'widgets/admin_wipe_dialog.dart';

/// Pantalla principal del panel de administración.
///
/// Muestra un listado paginado de usuarios con búsqueda por email
/// o nombre. Cada usuario tiene acciones: ver detalle, cambiar rol
/// y eliminar datos (wipe).
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

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
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(esAdminProvider);

    return esAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error al verificar permisos'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(esAdminProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          // Redirigir al dashboard si no es admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/dashboard');
            }
          });
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes permisos de administrador',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildAdminContent();
      },
    );
  }

  Widget _buildAdminContent() {
    final usuariosAsync = ref.watch(adminUsuariosProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () => ref.invalidate(adminUsuariosProvider(_query)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
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
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
              ),
            ),
          ),

          // Listado de usuarios
          Expanded(
            child: usuariosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error: $err'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      onPressed: () =>
                          ref.invalidate(adminUsuariosProvider(_query)),
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
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminUsuariosProvider(_query));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      return _UsuarioAdminCard(usuario: usuarios[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual de usuario en el panel de administración.
class _UsuarioAdminCard extends ConsumerWidget {
  final UsuarioAdmin usuario;

  const _UsuarioAdminCard({required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolColor =
        usuario.rol == 'admin' ? Colors.amber.shade700 : Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.push('/admin/usuario/${usuario.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty
                        ? NetworkImage(usuario.urlAvatar!)
                        : null,
                child: usuario.urlAvatar == null || usuario.urlAvatar!.isEmpty
                    ? Text(
                        usuario.nombreCompleto.isNotEmpty
                            ? usuario.nombreCompleto[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Badge de rol
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rolColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            usuario.rol.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: rolColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nivel
                        Icon(Icons.stars_rounded,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 3),
                        Text(
                          'Nv. ${usuario.nivel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Racha
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Colors.deepOrange),
                        const SizedBox(width: 3),
                        Text(
                          '${usuario.rachaActual}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menú de acciones
              PopupMenuButton<String>(
                onSelected: (action) => _handleAction(context, ref, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detalle',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Ver detalle'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
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
                            : null,
                      ),
                      title: Text(
                        usuario.rol == 'admin' ? 'Quitar admin' : 'Hacer admin',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'wipe',
                    child: ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text('Eliminar datos (Wipe)',
                          style: TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
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
        break;
      case 'cambiar_rol':
        _showCambiarRolDialog(context, ref);
        break;
      case 'wipe':
        _showWipeDialog(context, ref);
        break;
    }
  }

  void _showCambiarRolDialog(BuildContext context, WidgetRef ref) {
    final nuevoRol = usuario.rol == 'admin' ? 'usuario' : 'admin';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: Text(
          '¿${nuevoRol == 'admin' ? 'Otorgar' : 'Revocar'} permisos de administrador a ${usuario.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await cambiarRolUsuario(
                  ref,
                  usuario.id,
                  nuevoRol,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Rol actualizado a "$nuevoRol" para ${usuario.nombreCompleto}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              nuevoRol == 'admin' ? 'Otorgar admin' : 'Revocar admin',
            ),
          ),
        ],
      ),
    );
  }

  void _showWipeDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AdminWipeDialog(
        nombreUsuario: usuario.nombreCompleto,
        usuarioId: usuario.id,
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final result = await wipeUserData(ref, usuario.id);
          if (context.mounted) {
            final success = result['success'] == true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Wipe completado. ${result['registros_eliminados']} registros eliminados.'
                      : 'Error: ${result['error'] ?? 'Desconocido'}',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al ejecutar wipe: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }
}
