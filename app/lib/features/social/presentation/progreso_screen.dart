import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../insignias/application/insignias_provider.dart';
import '../../insignias/domain/insignia_dto.dart';
import '../../perfil/application/perfil_provider.dart';
import '../../social/application/social_provider.dart';
import '../../social/presentation/widgets/feed_item_card.dart';

class ProgresoScreen extends ConsumerWidget {
  const ProgresoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: SVColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 0, 16),
                child: Text(
                  'Progreso',
                  style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              _SeccionMiNivel(),
              const SizedBox(height: 24),
              _SeccionMisMedallas(),
              const SizedBox(height: 24),
              _SeccionComunidad(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeccionMiNivel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilUsuarioProvider);
    final rachaAsync = ref.watch(rachaStateProvider);

    return perfilAsync.when(
      loading: () => const _SeccionEsqueleto(altura: 160),
      error: (e, _) => const SizedBox.shrink(),
      data: (perfil) {
        final u = perfil.usuario;
        final nivel = u.nivel;
        final xp = u.xpTotal;
        final xpMeta = nivel * 100;
        final progreso = xpMeta > 0 ? (xp / xpMeta).clamp(0.0, 1.0) : 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Mi Nivel',
                  style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                rachaAsync.whenOrNull(
                      data: (r) => r.diasConsecutivos > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: SVColors.accentContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Racha ${r.diasConsecutivos} días',
                                style: const TextStyle(
                                  color: SVColors.onAccentContainer,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: SVColors.surfaceContainerLowest,
                borderRadius: SVShapes.standard12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$nivel',
                        style: const TextStyle(
                          color: SVColors.primary,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Nivel',
                        style: TextStyle(
                          color: SVColors.onSurfaceMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$xp / $xpMeta XP',
                        style: const TextStyle(
                          color: SVColors.onSurfaceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 6,
                      backgroundColor: SVColors.primary.withValues(alpha: 0.12),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(SVColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progreso * 100).toStringAsFixed(0)}% hasta el nivel ${nivel + 1}',
                    style: TextStyle(
                      color: SVColors.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SeccionMisMedallas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insigniasAsync = ref.watch(insigniasUsuarioProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mis Medallas',
              style: TextStyle(
                color: SVColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            ref.watch(insigniasCountProvider).whenOrNull(
                      data: (count) => Text(
                        '$count obtenidas',
                        style: const TextStyle(
                          color: SVColors.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                    ) ??
                const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: insigniasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (insignias) {
              if (insignias.isEmpty) {
                return _vacio('Sin medallas todavía',
                    'Completa retos y mantén tu racha para desbloquearlas.');
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: insignias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final ins = insignias[i];
                  return _MedallaCard(insignia: ins);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/insignias'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Ver todas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SVColors.primary,
              side: BorderSide(color: SVColors.primary.withValues(alpha: 0.25)),
              shape:
                  const RoundedRectangleBorder(borderRadius: SVShapes.standard),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vacio(String titulo, String subtitulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo,
              style: const TextStyle(
                  color: SVColors.onSurfaceMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitulo,
              style: const TextStyle(
                  color: SVColors.outlineVariant, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MedallaCard extends StatelessWidget {
  const _MedallaCard({required this.insignia});

  final Insignia insignia;

  @override
  Widget build(BuildContext context) {
    final color = Color(insignia.colorRareza);
    return Container(
      width: 80,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: SVShapes.standard12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(insignia.icono, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              insignia.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SVColors.onSurface,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionComunidad extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(socialFeedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comunidad',
          style: TextStyle(
            color: SVColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error al cargar',
              style: const TextStyle(
                  color: SVColors.onSurfaceMuted, fontSize: 12)),
          data: (publicaciones) {
            if (publicaciones.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay publicaciones aún. ¡Sé el primero en compartir!',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: SVColors.outlineVariant, fontSize: 12),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: publicaciones.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                return FeedItemCard(publicacion: publicaciones[i]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _SeccionEsqueleto extends StatelessWidget {
  const _SeccionEsqueleto({required this.altura});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      child: Container(
        decoration: const BoxDecoration(
          color: SVColors.surfaceContainerLowest,
          borderRadius: SVShapes.standard12,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
