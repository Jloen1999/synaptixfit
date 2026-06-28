import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../perfil/application/perfil_provider.dart';
import '../application/inbox_config_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContextualData();
    });
  }

  void _syncContextualData() {
    final notifier = ref.read(inboxConfigProvider.notifier);
    final config = ref.read(inboxConfigProvider);

    final yaConfigurado = config.horasEstudioObjetivo != 20.0 ||
        config.sesionesDeporteObjetivo != 3 ||
        config.minutosPorSesionDeporte != 60;

    if (!yaConfigurado) {
      ref.read(perfilUsuarioProvider.future).then((perfil) {
        if (!mounted) return;
        if (perfil.perfil.diasDisponibles.isNotEmpty) {
          notifier.setSesionesDeporte(perfil.perfil.diasDisponibles.length);
        }
        if (perfil.perfil.minutosPorSesion > 0) {
          notifier.setMinutosPorSesion(perfil.perfil.minutosPorSesion);
        }
      });

      ref.read(perfilAcademicoProvider.future).then((perfilAc) {
        if (!mounted || perfilAc == null) return;
        if (perfilAc.horasObjetivoEstudioSemana > 0) {
          notifier
              .setHorasEstudio(perfilAc.horasObjetivoEstudioSemana.toDouble());
        }
      });
    }

    if (config.asignaturasActivas.isEmpty) {
      ref.read(asignaturasActivasInboxProvider.future).then((asignaturas) {
        if (!mounted) return;
        notifier.setAsignaturasActivas(asignaturas);
      });
    }

    if (config.rutinasActivas.isEmpty) {
      ref.read(rutinasActivasInboxProvider.future).then((rutinas) {
        if (!mounted) return;
        notifier.setRutinasActivas(rutinas);
      });
    }

    if (config.horariosFijos.isEmpty) {
      ref.read(horariosFijosProvider.future).then((fijos) {
        if (!mounted) return;
        notifier.setHorariosFijos(fijos);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(inboxConfigProvider);
    final theme = Theme.of(context);

    return FeatureScaffold(
      title: 'Planificar mi semana',
      backPath: '/dashboard',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '¿Qué necesitas hacer esta semana?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define tus objetivos semanales y distribúyelos en el lienzo.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SVColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 24),
                _HorasEstudioSlider(
                  value: config.horasEstudioObjetivo,
                  onChanged: (v) =>
                      ref.read(inboxConfigProvider.notifier).setHorasEstudio(v),
                ),
                const SizedBox(height: 20),
                _SesionesDeporteSlider(
                  sesiones: config.sesionesDeporteObjetivo,
                  minutos: config.minutosPorSesionDeporte,
                  onSesionesChanged: (v) => ref
                      .read(inboxConfigProvider.notifier)
                      .setSesionesDeporte(v),
                  onMinutosChanged: (v) => ref
                      .read(inboxConfigProvider.notifier)
                      .setMinutosPorSesion(v),
                ),
                const SizedBox(height: 20),
                _EstadoFisicoBanner(),
              ],
            ),
          ),
          _BottomBar(
            isConfigured: config.horasEstudioObjetivo > 0 ||
                config.sesionesDeporteObjetivo > 0,
            onCancel: () => context.pop(),
            onGenerate: () => context.push('/academico/planificar'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Slider: Horas de estudio
// =============================================================================

class _HorasEstudioSlider extends StatelessWidget {
  const _HorasEstudioSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horas = value.toInt();
    final minutosFraccionales = ((value - horas) * 60).round();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: Color(0xFF3B82F6), size: 22),
                const SizedBox(width: 8),
                Text('Horas de estudio',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$horas h ${minutosFraccionales > 0 ? '${minutosFraccionales}min' : ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF3B82F6),
                inactiveTrackColor:
                    const Color(0xFF3B82F6).withValues(alpha: 0.15),
                thumbColor: const Color(0xFF3B82F6),
                overlayColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 50,
                divisions: 100,
                label: '${value.toStringAsFixed(1)}h',
                onChanged: onChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0h',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: SVColors.onSurfaceMuted)),
                  Text('25h',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: SVColors.onSurfaceMuted)),
                  Text('50h',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: SVColors.onSurfaceMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Slider: Sesiones de deporte
// =============================================================================

class _SesionesDeporteSlider extends StatelessWidget {
  const _SesionesDeporteSlider({
    required this.sesiones,
    required this.minutos,
    required this.onSesionesChanged,
    required this.onMinutosChanged,
  });

  final int sesiones;
  final int minutos;
  final ValueChanged<int> onSesionesChanged;
  final ValueChanged<int> onMinutosChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center_rounded,
                    color: Color(0xFFF97316), size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('Días de entrenamiento',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$sesiones días · ${minutos}min/día',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF97316),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFF97316),
                inactiveTrackColor:
                    const Color(0xFFF97316).withValues(alpha: 0.15),
                thumbColor: const Color(0xFFF97316),
                overlayColor: const Color(0xFFF97316).withValues(alpha: 0.12),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: sesiones.toDouble(),
                min: 0,
                max: 7,
                divisions: 7,
                label: sesiones == 0
                    ? 'Descanso'
                    : sesiones == 1
                        ? '1 día'
                        : '$sesiones días',
                onChanged: (v) => onSesionesChanged(v.toInt()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: SVColors.onSurfaceMuted)),
                  Text('3',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: SVColors.onSurfaceMuted)),
                  Text('7',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: SVColors.onSurfaceMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Duración por sesión',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: SVColors.onSurfaceMuted)),
                const Spacer(),
                DropdownButton<int>(
                  value: minutos,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(8),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 45, child: Text('45 min')),
                    DropdownMenuItem(value: 60, child: Text('60 min')),
                    DropdownMenuItem(value: 90, child: Text('90 min')),
                    DropdownMenuItem(value: 120, child: Text('120 min')),
                  ],
                  onChanged: (v) {
                    if (v != null) onMinutosChanged(v);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom bar
// =============================================================================

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isConfigured,
    required this.onCancel,
    required this.onGenerate,
  });

  final bool isConfigured;
  final VoidCallback onCancel;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isConfigured ? onGenerate : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ir al lienzo'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Banner de estado físico (energía + estrés)
// =============================================================================

class _EstadoFisicoBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energiaAsync = ref.watch(estadoEnergeticoProvider);
    final theme = Theme.of(context);

    return energiaAsync.when(
      data: (energia) {
        if (energia == null) return const SizedBox.shrink();
        final valor = (energia.valor * 100).round();
        final color = valor >= 60
            ? const Color(0xFF10B981)
            : valor >= 35
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);
        final mensaje = valor >= 60
            ? 'Buena energía para planificar'
            : valor >= 35
                ? 'Energía moderada — considera reducir carga'
                : 'Energía baja — prioriza descanso';

        return Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.battery_charging_full_rounded,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado energético: $valor%',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: valor / 100,
                            backgroundColor: color.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(mensaje,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: color, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
