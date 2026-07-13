import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'dart:math' as math;

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../../shared/utils/image_utils.dart';
import '../../../shared/widgets/dashboard_dialogs.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../academico/application/materiales_estudio_provider.dart';
import '../../admin/application/admin_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../perfil/application/perfil_provider.dart';
import '../application/dashboard_provider.dart';
import '../application/smart_banner_provider.dart';
import 'widgets/timeline_section.dart';
import 'widgets/cross_regulation_indicator.dart';
import '../../bienestar/application/neurofisiologia_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _userIdActual;

  @override
  Widget build(BuildContext context) {
    final currentUserId = sb.Supabase.instance.client.auth.currentUser?.id;
    final usuarioCambio = _userIdActual != null &&
        currentUserId != null &&
        _userIdActual != currentUserId;
    if (currentUserId != null && currentUserId != _userIdActual) {
      _userIdActual = currentUserId;
    }

    final data = ref.watch(dashboardProvider);
    if (usuarioCambio) {
      ref.invalidate(repasoUrgenteGlobalProvider(null));
      return const _LoadingDashboard();
    }

    return data.when(
      loading: () {
        if (data.hasValue) {
          final value = data.requireValue;
          return Column(
            children: [
              _WelcomeCard(data: value),
              const CrossRegulationIndicator(),
              const _RepasoUrgenteCard(),
              const _EstudioCaloriasChip(),
              const Expanded(child: DailyTimelineWidget()),
            ],
          );
        }
        return const _LoadingDashboard();
      },
      error: (error, _) {
        if (data.hasValue) {
          final value = data.requireValue;
          return Column(
            children: [
              _WelcomeCard(data: value),
              const CrossRegulationIndicator(),
              const _RepasoUrgenteCard(),
              const _EstudioCaloriasChip(),
              const Expanded(child: DailyTimelineWidget()),
            ],
          );
        }
        final msg = error.toString();
        final esErrorRed = msg.contains('SocketException') ||
            msg.contains('Failed host lookup') ||
            msg.contains('No address associated');
        return Center(
          child: EmptyState(
            title: esErrorRed ? 'Sin conexión' : 'Error al cargar',
            message: esErrorRed
                ? 'No se pudo conectar. Comprueba tu conexión.'
                : 'No se pudo cargar el dashboard.',
            icon: esErrorRed ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            action: TextButton(
              onPressed: () => ref.invalidate(dashboardProvider),
              child: const Text('Reintentar'),
            ),
          ),
        );
      },
      data: (value) {
        return Column(
          children: [
            _WelcomeCard(data: value),
            const CrossRegulationIndicator(),
            const _RepasoUrgenteCard(),
            const _EstudioCaloriasChip(),
            const Expanded(child: DailyTimelineWidget()),
          ],
        );
      },
    );
  }
}

class _WelcomeCard extends ConsumerWidget {
  const _WelcomeCard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = sb.Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null && data.usuario.id != currentUserId) {
      return const _SkeletonWelcomeCard();
    }

    final usuario = data.usuario;
    final nombre = usuario.nombreCompleto.split(' ').first;
    final tieneAvatar =
        usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty;

    final adherenciaComp = ref.watch(adherenciaAcademicaProvider).valueOrNull;
    final energiaComp = ref.watch(estadoEnergeticoProvider).valueOrNull;
    final carga = ref.watch(cargaAcademicaSemanalProvider).valueOrNull;
    final consejo = ref.watch(consejoSmartProvider);
    final actividad = ref.watch(perfilActividadProvider).valueOrNull;

    final energia = energiaComp?.valor ?? 0.0;
    final adherencia = adherenciaComp?.valor ?? 0.0;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: GestureDetector(
          onTap: () => context.push('/perfil'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF002546),
                  Color(0xFF0D3B66),
                  Color(0xFF153E5C),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/perfil'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: tieneAvatar
                              ? Image.network(
                                  normalizarUrlAvatar(usuario.urlAvatar!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _avatarFallback(nombre),
                                )
                              : _avatarFallback(nombre),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $nombre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: energia < 30
                                      ? const Color(0xFFE74C3C)
                                      : energia < 50
                                          ? const Color(0xFFF1C40F)
                                          : const Color(0xFF72FE8F),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Nivel ${usuario.nivel} · ${usuario.xpTotal} XP',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final esAdmin = ref.watch(esAdminProvider).valueOrNull;
                        if (esAdmin != true) return const SizedBox.shrink();
                        return IconButton(
                          onPressed: () => context.push('/admin'),
                          icon:
                              const Icon(Icons.admin_panel_settings, size: 20),
                          color: Colors.white54,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) => IconButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        color: Colors.redAccent.withValues(alpha: 0.7),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data.usuario.xpTotal} / ${data.xpParaSiguienteNivel} XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open_rounded,
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.4)),
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
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.xpProgreso.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF72FE8F)),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                      mostrarDialogoConsejo(context, consejo.textoVisible),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 13,
                          color:
                              const Color(0xFF7C4DFF).withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          consejo.textoVisible,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 14, color: Colors.white.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (actividad != null) ...[
                      _StatChip(Icons.fitness_center_rounded,
                          '${actividad.sesiones}', 'Sesiones'),
                      const SizedBox(width: 6),
                      _StatChip(
                          Icons.local_fire_department_rounded,
                          actividad.caloriasAcumuladas >= 1000
                              ? '${(actividad.caloriasAcumuladas / 1000).toStringAsFixed(1)}k'
                              : '${actividad.caloriasAcumuladas}',
                          'kcal'),
                      const SizedBox(width: 6),
                      _StatChip(Icons.emoji_events_rounded,
                          '${actividad.logros}', 'Retos'),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: () => mostrarDialogoEnergia(context, energiaComp),
                      child: _MiniGauge(
                        value: energia,
                        label: 'Energía',
                        color: energia < 30
                            ? const Color(0xFFE74C3C)
                            : energia < 60
                                ? const Color(0xFFF1C40F)
                                : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          mostrarDialogoAdherencia(context, adherenciaComp),
                      child: _MiniGauge(
                        value: adherencia,
                        label: 'Acad.',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    if (carga != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => mostrarDialogoEstudio(context, carga),
                        child: _MiniGauge(
                          value: (carga.horasEstudioReales /
                                  carga.horasEstudioPlaneadas.clamp(1, 120) *
                                  100)
                              .clamp(0, 100),
                          label: 'Estudio',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String nombre) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.2)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 8,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _MiniGauge extends StatelessWidget {
  const _MiniGauge({
    required this.value,
    required this.label,
    required this.color,
  });
  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: CustomPaint(
            painter: _MiniGaugePainter(progress: pct, color: color),
            child: Center(
              child: Text(
                '${value.round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MiniGaugePainter extends CustomPainter {
  const _MiniGaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const strokeWidth = 3.0;
    const startAngle = -math.pi / 2;
    const sweepFull = 2 * math.pi;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_MiniGaugePainter old) =>
      old.progress != progress || old.color != color;
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF002546), Color(0xFF0D3B66)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 16),
            const SkeletonLoader(height: 56),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 56),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 56),
          ],
        ),
      ),
    );
  }
}

/// Chip motivacional que muestra las calorías quemadas estudiando hoy.
///
/// Usa el getter SUM en tiempo real de calorias_quemadas desde
/// horarios_academicos. Flat Design: sin sombras, fondo naranja
/// de baja opacidad, solo visible cuando hay kcal > 0.
class _EstudioCaloriasChip extends ConsumerWidget {
  const _EstudioCaloriasChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kcal = ref.watch(caloriasEstudioHoyProvider).valueOrNull ?? 0;
    if (kcal <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Tu cerebro también entrena: +${kcal.round()} kcal hoy estudiando',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade300),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepasoUrgenteCard extends ConsumerWidget {
  const _RepasoUrgenteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgente = ref.watch(repasoUrgenteGlobalProvider(null));

    return urgente.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (material) {
        if (material == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Material(
            color: SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
            elevation: 1,
            child: InkWell(
              borderRadius: SVShapes.standard12,
              onTap: () => context.push('/academico/practica/${material.id}'),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: SVShapes.standard12,
                  border: Border(
                      left: BorderSide(color: Color(0xFFEF5350), width: 4)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                        borderRadius: SVShapes.standard,
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: Color(0xFFEF5350), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Toca repasar: ${material.titulo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: SVColors.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            'Repaso pendiente · EF ${material.facilidad.toStringAsFixed(1)}',
                            style: const TextStyle(
                                color: SVColors.onSurfaceMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: SVColors.onSurfaceMuted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonWelcomeCard extends StatelessWidget {
  const _SkeletonWelcomeCard();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF002546), Color(0xFF0D3B66), Color(0xFF153E5C)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
