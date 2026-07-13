import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../application/artefacto_efimero_provider.dart';
import 'simulacro_test_screen.dart';

/// Pantalla de resultados tras completar un simulacro tipo test.
///
/// Muestra la puntuación con un círculo coloreado semánticamente, el desglose
/// de cada pregunta (acierto/fallo, respuesta correcta, explicación), y acciones
/// para repetir, regenerar o salir. Guarda el resultado en [test_sessions].
class ResultadosSimulacroScreen extends ConsumerStatefulWidget {
  const ResultadosSimulacroScreen({super.key});

  @override
  ConsumerState<ResultadosSimulacroScreen> createState() =>
      _ResultadosSimulacroScreenState();
}

class _ResultadosSimulacroScreenState
    extends ConsumerState<ResultadosSimulacroScreen> {
  /// Indica si estamos regenerando el cuestionario para crear uno nuevo.
  bool _regenerando = false;

  @override
  void initState() {
    super.initState();
    // Guardar resultado de la sesión al entrar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardarResultadoSesion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artefactoEfimeroProvider);
    final puntuacion = state.puntuacion ?? 0;
    final total = state.totalPreguntas ?? state.preguntas.length;
    final porcentaje = total > 0 ? puntuacion / total : 0.0;

    // Detectar cuando la regeneración termina para navegar al inicio del flujo.
    if (_regenerando &&
        state.estado != EstadoGeneracion.cargando &&
        state.puntuacion == null) {
      // La regeneración ha completado (puntuacion se resetea a null
      // porque las preguntas son nuevas y no se han respondido aún).
      _regenerando = false;

      // Navegar al selector de formato para que el usuario pueda elegir.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }

    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SVColors.surfaceContainerLowest,
        surfaceTintColor: SVColors.surfaceContainerLowest,
        title: const Text(
          'Resultados',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: SVColors.onSurface,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _regenerando
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: SVColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Generando nuevo cuestionario...',
                    style: TextStyle(color: SVColors.onSurfaceMuted),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          _buildScoreCircle(puntuacion, total, porcentaje),
                          const SizedBox(height: 28),
                          _buildSeccionHeader(context, 'Respuestas'),
                          const SizedBox(height: 12),
                          _buildRespuestasList(state.preguntas),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(context, ref, state),
                ],
              ),
            ),
    );
  }

  /// Círculo central con la puntuación y color semántico.
  Widget _buildScoreCircle(int puntuacion, int total, double porcentaje) {
    final scoreColor = _colorPorPorcentaje(porcentaje);
    final porcentajeTexto = total > 0 ? '${(porcentaje * 100).round()}%' : '0%';

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: porcentaje),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.08),
              border: Border.all(
                color: scoreColor.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: scoreColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$puntuacion/$total',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      porcentajeTexto,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scoreColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Encabezado de sección "Respuestas".
  Widget _buildSeccionHeader(BuildContext context, String titulo) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: SVColors.primary,
            borderRadius: SVShapes.pill,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: SVColors.onSurface,
              ),
        ),
      ],
    );
  }

  /// Lista de preguntas con su resultado individual.
  Widget _buildRespuestasList(List<PreguntaGenerada> preguntas) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: preguntas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildRespuestaCard(preguntas[index], index, preguntas.length);
      },
    );
  }

  /// Tarjeta individual con el detalle de cada pregunta.
  Widget _buildRespuestaCard(
    PreguntaGenerada pregunta,
    int index,
    int total,
  ) {
    final esCorrecta = pregunta.esCorrecta == true;
    final respondida = pregunta.respuestaUsuario != null;

    return Material(
      color: SVColors.surfaceContainerLow,
      borderRadius: SVShapes.standard12,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera: número + icono acierto/fallo ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SVColors.surfaceContainerHighest,
                    borderRadius: SVShapes.pill,
                  ),
                  child: Text(
                    '${index + 1}/$total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SVColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                if (respondida)
                  Icon(
                    esCorrecta
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: esCorrecta ? SVColors.secondary : SVColors.error,
                    size: 22,
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Enunciado ──
            Text(
              pregunta.enunciado,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: SVColors.onSurface,
              ),
            ),

            const SizedBox(height: 10),

            // ── Tu respuesta ──
            if (respondida) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Tu respuesta:',
                      style: TextStyle(
                        fontSize: 12,
                        color: SVColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pregunta.respuestaUsuario!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: esCorrecta ? SVColors.secondary : SVColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // ── Respuesta correcta (si falló o no respondió) ──
            if (!esCorrecta && pregunta.respuestaCorrecta.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Correcta:',
                      style: TextStyle(
                        fontSize: 12,
                        color: SVColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pregunta.respuestaCorrecta,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: SVColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // ── Explicación ──
            if (pregunta.explicacion != null &&
                pregunta.explicacion!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SVColors.surfaceContainerLowest,
                  borderRadius: SVShapes.standard,
                ),
                child: Text(
                  pregunta.explicacion!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: SVColors.onSurfaceMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Barra inferior con las tres acciones principales.
  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    ArtefactoEfimeroState state,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Repetir este cuestionario ──
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _regenerando ? null : () => _repetirCuestionario(),
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: const Text('Repetir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SVColors.primary,
                  side: const BorderSide(color: SVColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: SVShapes.standard12,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── Generar uno nuevo ──
            Expanded(
              child: FilledButton.icon(
                onPressed: _regenerando ? null : _generarNuevo,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text('Nuevo'),
                style: FilledButton.styleFrom(
                  backgroundColor: SVColors.secondary,
                  foregroundColor: SVColors.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: SVShapes.standard12,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── Salir ──
            Expanded(
              child: TextButton.icon(
                onPressed: _regenerando ? null : () => _salir(),
                icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                label: const Text('Salir'),
                style: TextButton.styleFrom(
                  foregroundColor: SVColors.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: SVShapes.standard12,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reinicia las respuestas de todas las preguntas y vuelve al simulacro.
  void _repetirCuestionario() {
    final state = ref.read(artefactoEfimeroProvider);

    // Limpiar respuestas previas para repetir el mismo conjunto.
    for (final p in state.preguntas) {
      p.respuestaUsuario = null;
      p.esCorrecta = null;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SimulacroTestScreen(),
      ),
    );
  }

  /// Dispara la regeneración del cuestionario.
  ///
  /// Cuando el estado vuelve a [EstadoGeneracion.completado], el [build]
  /// detecta el cambio y navega al inicio del flujo.
  void _generarNuevo() {
    setState(() => _regenerando = true);
    ref.read(artefactoEfimeroProvider.notifier).regenerar();
  }

  /// Sale del flujo completo.
  ///
  /// Guarda el resultado en [test_sessions] y hace pop hasta la raíz.
  void _salir() {
    _guardarResultadoSesion();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Inserta un registro en [test_sessions] con el resultado del simulacro.
  Future<void> _guardarResultadoSesion() async {
    try {
      final state = ref.read(artefactoEfimeroProvider);
      if (state.puntuacion == null) return; // Sin resultados que guardar.

      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final userId = currentUser.id;
      final materialId = state.asignaturaId ?? 'simulacro';
      final score = state.puntuacion!;
      final totalPreguntas = state.totalPreguntas ?? state.preguntas.length;

      // Construir maps de respuestas y resultados al estilo de la tabla.
      final respuestasMap = <String, dynamic>{};
      final resultadosMap = <String, dynamic>{};
      final preguntasIds = <String>[];

      for (final p in state.preguntas) {
        preguntasIds.add(p.id);
        respuestasMap[p.id] = p.respuestaUsuario ?? '';
        resultadosMap[p.id] = p.esCorrecta == true;
      }

      await client.from('test_sessions').insert({
        'usuario_id': userId,
        'material_id': materialId,
        'preguntas_ids': preguntasIds,
        'respuestas': respuestasMap,
        'resultados': resultadosMap,
        'indice_actual': state.preguntas.length,
        'status': 'completed',
        'score': score,
        'total_preguntas': totalPreguntas,
        'completado_en': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silencioso: no interrumpir la UX si falla el guardado.
    }
  }

  /// Color según el porcentaje de aciertos:
  /// verde ≥ 70%, ámbar ≥ 40%, rojo < 40%.
  Color _colorPorPorcentaje(double porcentaje) {
    if (porcentaje >= 0.70) return SVColors.secondary;
    if (porcentaje >= 0.40) return SVColors.accent;
    return SVColors.error;
  }
}
