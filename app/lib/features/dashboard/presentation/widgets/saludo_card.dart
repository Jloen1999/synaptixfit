import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../bienestar/application/rutina_provider.dart';
import 'streak_badge.dart';

/// Tarjeta de saludo premium con gradiente, avatar, XP y racha.
class SaludoCard extends StatelessWidget {
  const SaludoCard({
    required this.data,
    this.rachaEntrenamiento = 0,
    this.diasEstudio = 0,
    super.key,
  });

  final dynamic data;
  final int rachaEntrenamiento;
  final int diasEstudio;

  @override
  Widget build(BuildContext context) {
    final usuario = data.usuario;
    final nombre = usuario.nombreCompleto.split(' ').first;
    final tieneAvatar =
        usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/perfil'),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF002546), Color(0xFF0D3B66), Color(0xFF153E5C)],
          ),
          borderRadius: BorderRadius.circular(22),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(14),
                    child: tieneAvatar
                        ? Image.network(
                            usuario.urlAvatar!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(
                                nombre, Colors.white.withValues(alpha: 0.18)),
                          )
                        : _avatarFallback(
                            nombre, Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $nombre 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
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
              ],
            ),
            const SizedBox(height: 18),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Nivel ${data.usuario.nivel + 1}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: data.xpProgreso.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF72FE8F),
                    ),
                  ),
                ),
              ],
            ),
            if (rachaEntrenamiento > 0 || diasEstudio > 0) ...[
              const SizedBox(height: 14),
              StreakRow(
                rachaEntrenamiento: rachaEntrenamiento,
                diasEstudio: diasEstudio,
              ),
            ],
            if (data.notificacionesNoLeidas.isNotEmpty) ...[
              const SizedBox(height: 14),
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
