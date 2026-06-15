import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/pomodoro_provider.dart';
import '../domain/pomodoro_session.dart';
import 'widgets/pomodoro_progress_painter.dart';

/// Pantalla full-screen del temporizador Pomodoro.
class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(); // loop continuo para repaint suave
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Anillo de progreso
                _buildProgressRing(session),
                const SizedBox(height: 24),
                // Tiempo restante
                Text(
                  _formatTime(session.secondsRemaining),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ).animate().fadeIn(duration: 200.ms),
                const SizedBox(height: 8),
                // Etiqueta del estado
                _buildPhaseLabel(session, theme),
                const SizedBox(height: 4),
                // Contador de sesiones
                Text(
                  '${session.completedCount}/${session.sessionsBeforeLongBreak} sesiones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 32),
                // Botones de control
                _buildControls(session, notifier, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRing(PomodoroSession session) {
    return SizedBox(
      width: 264,
      height: 264,
      child: CustomPaint(
        painter: PomodoroProgressPainter(
          progress: session.progress,
          phase: session.phase,
          animation: _animCtrl,
        ),
      ),
    );
  }

  Widget _buildPhaseLabel(PomodoroSession session, ThemeData theme) {
    final (label, color) = switch (session.phase) {
      PomodoroPhase.work => ('Enfocado', const Color(0xFFE53935)),
      PomodoroPhase.shortBreak => ('Descanso corto', const Color(0xFF43A047)),
      PomodoroPhase.longBreak => ('Descanso largo', const Color(0xFF1E88E5)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildControls(
    PomodoroSession session,
    PomodoroNotifier notifier,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // Boton principal: Iniciar / Pausar / Reanudar
        _ControlButton(
          icon: switch (session.status) {
            PomodoroStatus.idle ||
            PomodoroStatus.completed =>
              Icons.play_arrow_rounded,
            PomodoroStatus.running => Icons.pause_rounded,
            PomodoroStatus.paused => Icons.play_arrow_rounded,
          },
          label: switch (session.status) {
            PomodoroStatus.idle || PomodoroStatus.completed => 'Iniciar',
            PomodoroStatus.running => 'Pausar',
            PomodoroStatus.paused => 'Reanudar',
          },
          color: theme.colorScheme.primary,
          onPressed: () {
            switch (session.status) {
              case PomodoroStatus.idle:
              case PomodoroStatus.completed:
                notifier.iniciar();
              case PomodoroStatus.running:
                notifier.pausar();
              case PomodoroStatus.paused:
                notifier.reanudar();
            }
          },
        ),
        // Reiniciar
        _ControlButton(
          icon: Icons.stop_rounded,
          label: 'Reiniciar',
          color: Colors.grey.shade600,
          onPressed: () {
            _showConfirmDialog(
              context,
              'Reiniciar Pomodoro',
              'Perderas el progreso actual.',
              () => notifier.reiniciar(),
            );
          },
        ),
        // Saltar descanso (solo visible en fase break)
        if (session.phase != PomodoroPhase.work &&
            session.status != PomodoroStatus.idle)
          _ControlButton(
            icon: Icons.skip_next_rounded,
            label: 'Saltar descanso',
            color: const Color(0xFFE8A838),
            onPressed: () => notifier.skipBreak(),
          ),
      ],
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Boton de control del Pomodoro con icono y etiqueta.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(100)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
