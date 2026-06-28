import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/social_provider.dart';
import '../../domain/social_dto.dart';
import 'comentario_card.dart';
import 'comentario_input.dart';

/// Card de publicación para el feed social.
///
/// Basado en el [FeedCard] del shared/widgets, pero con datos del DTO
/// [Publicacion] y soporte completo de comentarios expandibles.
class FeedItemCard extends ConsumerStatefulWidget {
  const FeedItemCard({
    required this.publicacion,
    super.key,
  });

  final Publicacion publicacion;

  @override
  ConsumerState<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends ConsumerState<FeedItemCard> {
  bool _comentariosExpandidos = false;
  bool _likeAnimando = false;

  IconData get _iconoActividad => switch (widget.publicacion.tipo) {
        'session_completed' => Icons.fitness_center_rounded,
        'challenge_completed' => Icons.emoji_events_rounded,
        'milestone_reached' => Icons.flag_rounded,
        'badge_unlocked' => Icons.workspace_premium_rounded,
        'rutina' => Icons.fitness_center_rounded,
        'reto' => Icons.flag_rounded,
        _ => Icons.celebration_rounded,
      };

  Color _colorActividad(BuildContext context) =>
      switch (widget.publicacion.tipo) {
        'session_completed' => Theme.of(context).colorScheme.primary,
        'challenge_completed' => const Color(0xFF006E2D),
        'milestone_reached' => const Color(0xFFE65100),
        'badge_unlocked' => const Color(0xFF7B1FA2),
        'rutina' => Theme.of(context).colorScheme.primary,
        'reto' => const Color(0xFF006E2D),
        _ => Theme.of(context).colorScheme.secondary,
      };

  String get _etiquetaActividad => switch (widget.publicacion.tipo) {
        'session_completed' => 'Sesión completada',
        'challenge_completed' => 'Reto completado',
        'milestone_reached' => 'Hito alcanzado',
        'badge_unlocked' => 'Insignia desbloqueada',
        'rutina' => 'Rutina',
        'reto' => 'Reto',
        _ => 'Logro',
      };

  String get _tiempoRelativo {
    final diff = DateTime.now().difference(widget.publicacion.fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${widget.publicacion.fecha.day}/${widget.publicacion.fecha.month}';
  }

  /// Parsea la entidad vinculada (insignia / rutina / reto) desde la metadata
  /// JSON de la publicación. Devuelve null si no hay entidad asociada.
  Map<String, dynamic>? get _entidadMeta {
    final raw = widget.publicacion.metadata;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded['entidad_nombre'] != null) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Indica si la publicación pertenece al usuario autenticado.
  bool get _esMia {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null && uid == widget.publicacion.usuarioId;
  }

  /// Navega a la entidad vinculada (rutina / reto / insignia). El control de
  /// permisos (acciones de propietario vs. visitante) se resuelve en la
  /// pantalla de destino y por RLS.
  void _navegarAEntidad() {
    final meta = _entidadMeta;
    if (meta == null) return;
    final tipo = meta['entidad_tipo'] as String?;
    final id = meta['entidad_id'] as String?;
    switch (tipo) {
      case 'rutina':
        if (id != null) context.push('/bienestar/rutina/$id');
        break;
      case 'reto':
        if (id != null) context.push('/retos/$id');
        break;
      default:
        context.push('/insignias');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorActividad(context);
    final pub = widget.publicacion;
    final initial =
        pub.nombreUsuario.isNotEmpty ? pub.nombreUsuario[0].toUpperCase() : '?';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar + Nombre + Tipo + Timestamp
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pub.nombreUsuario,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(_iconoActividad, size: 14, color: color),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _etiquetaActividad,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (pub.fueEditada) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.edit_outlined,
                                    size: 11,
                                    color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Text(
                                  'editado',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _tiempoRelativo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_esMia) _buildMenuPropietario(theme),
                  ],
                ),
                const SizedBox(height: 12),
                // Contenido
                Text(
                  pub.descripcion,
                  style: theme.textTheme.bodyMedium,
                ),
                // Entidad vinculada (insignia / rutina / reto)
                if (_entidadMeta != null) ...[
                  const SizedBox(height: 10),
                  _buildEntidadChip(theme, color),
                ],
                // Imagen si tiene
                if (pub.urlImagen != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      pub.urlImagen!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Acciones
                Row(
                  children: [
                    _ActionButton(
                      icon: pub.likedByMe
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_alt_outlined,
                      label: '${pub.likesCount}',
                      isActive: pub.likedByMe,
                      activeColor: theme.colorScheme.primary,
                      onTap: () => _toggleLike(),
                    ),
                    const SizedBox(width: 4),
                    _ActionButton(
                      icon: _comentariosExpandidos
                          ? Icons.mode_comment_rounded
                          : Icons.mode_comment_outlined,
                      label: '${pub.comentariosCount}',
                      isActive: _comentariosExpandidos,
                      onTap: () {
                        setState(() =>
                            _comentariosExpandidos = !_comentariosExpandidos);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sección de comentarios expandible
          if (_comentariosExpandidos) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            _seccionComentarios(),
          ],
        ],
      ),
    );
  }

  Widget _buildEntidadChip(ThemeData theme, Color color) {
    final meta = _entidadMeta!;
    final nombre = meta['entidad_nombre'] as String? ?? '';
    final emoji = meta['entidad_icono'] as String?;
    final tipo = meta['entidad_tipo'] as String? ?? 'insignia';
    final icon = switch (tipo) {
      'rutina' => Icons.fitness_center_rounded,
      'reto' => Icons.flag_rounded,
      _ => Icons.workspace_premium_rounded,
    };
    return Row(
      children: [
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navegarAEntidad,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null && emoji.isNotEmpty)
                      Text(emoji, style: const TextStyle(fontSize: 16))
                    else
                      Icon(icon, size: 16, color: color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: color),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuPropietario(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded,
          size: 20, color: theme.colorScheme.onSurfaceVariant),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      tooltip: 'Opciones',
      onSelected: (v) {
        if (v == 'editar') _mostrarDialogoEditarPublicacion();
        if (v == 'eliminar') _confirmarEliminarPublicacion();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
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
                size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Text('Eliminar', style: TextStyle(color: theme.colorScheme.error)),
          ]),
        ),
      ],
    );
  }

  void _mostrarDialogoEditarPublicacion() {
    final controller =
        TextEditingController(text: widget.publicacion.descripcion);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar publicación'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: '¿Qué quieres compartir?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final texto = controller.text.trim();
              if (texto.isEmpty || texto.length > 500) return;
              await editarPublicacionMutation(
                ref,
                publicacionId: widget.publicacion.id,
                descripcion: texto,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarPublicacion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
            '¿Seguro que quieres eliminar esta publicación? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await eliminarPublicacionMutation(
        ref,
        publicacionId: widget.publicacion.id,
      );
    }
  }

  Widget _seccionComentarios() {
    final comentariosAsync =
        ref.watch(socialCommentsProvider(widget.publicacion.id));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        comentariosAsync.when(
          data: (comentarios) {
            if (comentarios.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sé el primero en comentar',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              itemCount: comentarios.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final c = comentarios[index];
                return ComentarioCard(
                  comentario: c,
                  onEditar: c.esMio ? () => _mostrarDialogoEditar(c) : null,
                  onEliminar: c.esMio
                      ? () => _confirmarEliminar(c.id, widget.publicacion.id)
                      : null,
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error al cargar comentarios: $error'),
          ),
        ),
        ComentarioInput(
          onEnviar: (texto) {
            enviarComentario(
              ref,
              actividadId: widget.publicacion.id,
              texto: texto,
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleLike() async {
    if (_likeAnimando) return;
    setState(() => _likeAnimando = true);

    await toggleLike(
      ref,
      widget.publicacion.id,
      isLiked: widget.publicacion.likedByMe,
    );

    if (mounted) {
      setState(() => _likeAnimando = false);
    }
  }

  void _mostrarDialogoEditar(Comentario comentario) {
    final controller = TextEditingController(text: comentario.texto);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe tu comentario...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final texto = controller.text.trim();
              if (texto.isEmpty || texto.length > 500) return;

              await editarComentarioMutation(
                ref,
                comentarioId: comentario.id,
                actividadId: widget.publicacion.id,
                texto: texto,
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(
      String comentarioId, String actividadId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Estás seguro de eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await eliminarComentarioMutation(
        ref,
        comentarioId: comentarioId,
        actividadId: actividadId,
      );
    }
  }
}

/// Botón de acción reutilizable (like, comentarios).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? (activeColor ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
