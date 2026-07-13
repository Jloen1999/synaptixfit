import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../shared/utils/image_utils.dart';
import '../../../admin/application/admin_provider.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../bienestar/application/rutina_provider.dart';
import '../../../perfil/application/perfil_provider.dart';
import 'streak_badge.dart';

/// Tarjeta de saludo premium con gradiente, avatar, XP y racha.
///
/// [diasEstudio] es nullable para diferenciar entre «cargando» (null)
/// y «sin datos de estudio» (0). Cuando es null, se muestra un indicador
/// sutil de carga en la fila de rachas en lugar de un 0 falso.
class SaludoCard extends StatelessWidget {
  const SaludoCard({
    required this.data,
    this.rachaEntrenamiento = 0,
    this.diasEstudio,
    super.key,
  });

  final dynamic data;
  final int rachaEntrenamiento;
  final int? diasEstudio;

  @override
  Widget build(BuildContext context) {
    final usuario = data.usuario;
    final nombre = usuario.nombreCompleto.split(' ').first;
    final tieneAvatar =
        usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/perfil'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF002546), Color(0xFF0D3B66), Color(0xFF153E5C)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF002546).withValues(alpha: 0.35),
              offset: const Offset(0, 10),
              blurRadius: 30,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF72FE8F).withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: tieneAvatar
                        ? Image.network(
                            normalizarUrlAvatar(usuario.urlAvatar!),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(
                                nombre, Colors.white.withValues(alpha: 0.18)),
                          )
                        : _avatarFallback(
                            nombre, Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $nombre 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Consumer(
                        builder: (context, ref, _) {
                          final energia =
                              ref.watch(estadoEnergeticoProvider).valueOrNull;
                          final energiaValor = energia?.valor ?? 50;
                          final dotColor = energiaValor < 30
                              ? SVColors.error
                              : energiaValor < 50
                                  ? const Color(0xFFE8A838)
                                  : energiaValor < 70
                                      ? const Color(0xFFF5A623)
                                      : SVColors.secondary;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Nivel ${usuario.nivel} · ${usuario.xpTotal} XP',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Botón de administración (solo visible para admins)
                Consumer(
                  builder: (context, ref, _) {
                    final esAdmin = ref.watch(esAdminProvider).valueOrNull;
                    if (esAdmin != true) return const SizedBox.shrink();
                    return IconButton(
                      onPressed: () => context.push('/admin'),
                      icon: const Icon(Icons.admin_panel_settings),
                      tooltip: 'Panel de Administración',
                      color: Colors.white70,
                      iconSize: 22,
                      splashRadius: 20,
                    );
                  },
                ),
                // Botón de cerrar sesión
                Consumer(
                  builder: (context, ref, _) => IconButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.logout_rounded,
                        size: 20, color: Colors.redAccent),
                    tooltip: 'Cerrar sesión',
                    splashRadius: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de XP
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data.usuario.xpTotal} / ${data.xpParaSiguienteNivel} XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Nivel ${data.usuario.nivel + 1}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.xpProgreso.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF72FE8F),
                    ),
                  ),
                ),
              ],
            ),
            if (rachaEntrenamiento > 0 ||
                (diasEstudio != null && diasEstudio! > 0) ||
                diasEstudio == null) ...[
              const SizedBox(height: 10),
              StreakRow(
                rachaEntrenamiento: rachaEntrenamiento,
                diasEstudio: diasEstudio ?? 0,
                isLoadingEstudio: diasEstudio == null,
              ),
            ],
            const SizedBox(height: 10),
            // Stats: sesiones, calorías, retos (XP ya arriba en barra)
            Consumer(
              builder: (context, ref, _) {
                final act = ref.watch(perfilActividadProvider).valueOrNull;
                if (act == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.fitness_center_rounded,
                        value: '${act.sesiones}',
                        label: 'Sesiones',
                      ),
                    ),
                    _StatDivider(),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.local_fire_department_rounded,
                        value: act.caloriasAcumuladas >= 1000
                            ? '${(act.caloriasAcumuladas / 1000).toStringAsFixed(1)}k'
                            : '${act.caloriasAcumuladas}',
                        label: 'Calorías',
                      ),
                    ),
                    _StatDivider(),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.emoji_events_rounded,
                        value: '${act.logros}',
                        label: 'Retos',
                      ),
                    ),
                  ],
                );
              },
            ),
            if (data.notificacionesNoLeidas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data.notificacionesNoLeidas.length} notificaciones sin leer',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String nombre, Color bgColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}
