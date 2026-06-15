import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                              Text(
                                _etiquetaActividad,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                  ],
                ),
                const SizedBox(height: 12),
                // Contenido
                Text(
                  pub.descripcion,
                  style: theme.textTheme.bodyMedium,
                ),
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
