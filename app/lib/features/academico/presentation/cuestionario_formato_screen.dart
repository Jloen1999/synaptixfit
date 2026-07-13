import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../application/artefacto_efimero_provider.dart';
import 'simulacro_test_screen.dart';
import 'tarjetas_estudio_screen.dart';

class CuestionarioFormatoScreen extends ConsumerStatefulWidget {
  const CuestionarioFormatoScreen({super.key});

  @override
  ConsumerState<CuestionarioFormatoScreen> createState() =>
      _CuestionarioFormatoScreenState();
}

class _CuestionarioFormatoScreenState
    extends ConsumerState<CuestionarioFormatoScreen> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(artefactoEfimeroProvider, (prev, next) {
      if (next.estado == EstadoGeneracion.completado && mounted) {
        _navegarAResultado(next);
      } else if (next.estado == EstadoGeneracion.error && mounted) {
        setState(() => _generando = false);
      }
    });

    final state = ref.watch(artefactoEfimeroProvider);

    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SVColors.surfaceContainerLowest,
        surfaceTintColor: SVColors.surfaceContainerLowest,
        title: const Text(
          'Formato de cuestionario',
          style:
              TextStyle(fontWeight: FontWeight.w700, color: SVColors.onSurface),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: _buildBody(state)),
    );
  }

  Widget _buildBody(ArtefactoEfimeroState state) {
    if (state.estado == EstadoGeneracion.cargando) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: SVColors.primary),
            const SizedBox(height: 16),
            const Text('Generando cuestionario…',
                style: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Puedes salir de esta pantalla, la generación continúa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 12)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(artefactoEfimeroProvider.notifier).cancelar();
                if (mounted) {
                  setState(() => _generando = false);
                }
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SVColors.error,
                side: const BorderSide(color: SVColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (state.estado == EstadoGeneracion.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: SVColors.error),
              const SizedBox(height: 12),
              Text(state.error ?? 'Error al generar',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SVColors.error)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(artefactoEfimeroProvider.notifier).regenerar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final preguntas = state.preguntas;
    final tienePreguntas = preguntas.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Elige el formato',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SVColors.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          if (tienePreguntas)
            Text(
              '${preguntas.length} preguntas generadas. ¿Cómo quieres estudiarlas?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SVColors.onSurfaceMuted,
                  ),
            )
          else
            Text(
              'Selecciona un formato para generar las preguntas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SVColors.onSurfaceMuted,
                  ),
            ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                _FormatoCard(
                  icon: Icons.style_outlined,
                  titulo: 'Tarjetas de estudio',
                  subtitulo: 'Pregunta y respuesta para repasar después',
                  onTap: _generando
                      ? null
                      : () => _iniciarGeneracion(FormatoCuestionario.tarjetas),
                ),
                const SizedBox(height: 16),
                _FormatoCard(
                  icon: Icons.quiz_outlined,
                  titulo: 'Simulacro tipo test',
                  subtitulo: 'Responde ahora y obtén tu nota',
                  onTap: _generando
                      ? null
                      : () => _iniciarGeneracion(FormatoCuestionario.simulacro),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _iniciarGeneracion(FormatoCuestionario formato) {
    setState(() => _generando = true);
    final notifier = ref.read(artefactoEfimeroProvider.notifier);
    notifier.setFormato(formato);

    if (formato == FormatoCuestionario.tarjetas) {
      notifier.generarCuestionario();
    } else {
      notifier.generarCuestionarioSimulacro();
    }
  }

  void _navegarAResultado(ArtefactoEfimeroState state) {
    if (!mounted) return;
    setState(() => _generando = false);

    final Widget destino =
        state.formatoCuestionario == FormatoCuestionario.tarjetas
            ? const TarjetasEstudioScreen()
            : const SimulacroTestScreen();

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino));
  }
}

class _FormatoCard extends StatelessWidget {
  const _FormatoCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SVColors.surfaceContainerLow,
      borderRadius: SVShapes.standard12,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: SVShapes.standard12,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: SVShapes.standard12,
            border: const Border(
              left: BorderSide(color: SVColors.primary, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SVColors.primary.withOpacity(0.08),
                  borderRadius: SVShapes.standard12,
                ),
                child: Icon(icon, color: SVColors.primary, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: SVColors.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitulo,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: SVColors.onSurfaceMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: SVColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}
