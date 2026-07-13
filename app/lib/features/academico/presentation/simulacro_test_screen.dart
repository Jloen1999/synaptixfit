import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../application/artefacto_efimero_provider.dart';
import 'resultados_simulacro_screen.dart';

/// Experiencia de test cronometrado pregunta por pregunta.
///
/// El usuario responde secuencialmente cada pregunta del simulacro.
/// Al finalizar, se calcula la puntuación y se navega a los resultados.
class SimulacroTestScreen extends ConsumerStatefulWidget {
  const SimulacroTestScreen({super.key});

  @override
  ConsumerState<SimulacroTestScreen> createState() =>
      _SimulacroTestScreenState();
}

class _SimulacroTestScreenState extends ConsumerState<SimulacroTestScreen> {
  int _indice = 0;
  final Map<int, String> _respuestas = {};

  /// Controlador para preguntas de tipo "rellenar_hueco".
  final _huecoCtrl = TextEditingController();
  final _huecoFocus = FocusNode();

  @override
  void dispose() {
    _huecoCtrl.dispose();
    _huecoFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artefactoEfimeroProvider);
    final preguntas = state.preguntas;

    // Sincronizar el TextField con la respuesta guardada si existe.
    if (preguntas.isNotEmpty && _indice < preguntas.length) {
      final guardada = _respuestas[_indice];
      final preguntaActual = preguntas[_indice];
      if (preguntaActual.esOpcionMultiple) {
        // No necesita sincronización: RadioListTile usa _respuestas.
      } else {
        if (guardada != null && _huecoCtrl.text != guardada) {
          _huecoCtrl.text = guardada;
        } else if (guardada == null && _huecoCtrl.text.isNotEmpty) {
          _huecoCtrl.clear();
        }
      }
    }

    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SVColors.surfaceContainerLowest,
        surfaceTintColor: SVColors.surfaceContainerLowest,
        title: const Text(
          'Simulacro',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: SVColors.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _confirmarSalida(),
        ),
      ),
      body: preguntas.isEmpty
          ? const Center(
              child: Text(
                'No hay preguntas para este simulacro.',
                style: TextStyle(color: SVColors.onSurfaceMuted),
              ),
            )
          : _buildTestBody(preguntas),
    );
  }

  /// Cuerpo principal del test: barra de progreso + pregunta actual.
  Widget _buildTestBody(List<PreguntaGenerada> preguntas) {
    final total = preguntas.length;
    final progreso = (_indice + 1) / total;
    final pregunta = preguntas[_indice];

    return SafeArea(
      child: Column(
        children: [
          // ── Barra de progreso ──
          _buildProgressBar(progreso, total),
          // ── Contenido de la pregunta ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _buildPreguntaCard(pregunta, total),
            ),
          ),
          // ── Botón de navegación ──
          _buildNavegacion(preguntas, total),
        ],
      ),
    );
  }

  /// Barra de progreso superior con indicador "Pregunta X de N".
  Widget _buildProgressBar(double progreso, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      color: SVColors.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregunta ${_indice + 1} de $total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SVColors.onSurfaceVariant,
                    ),
              ),
              Text(
                '${(_indice + 1) * 100 ~/ total}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SVColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: SVShapes.pill,
            child: LinearProgressIndicator(
              value: progreso,
              backgroundColor: SVColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(SVColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con el enunciado y las opciones / campo de texto.
  Widget _buildPreguntaCard(PreguntaGenerada pregunta, int total) {
    return Material(
      color: SVColors.surfaceContainerLow,
      borderRadius: SVShapes.standard12,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Enunciado ──
            Text(
              pregunta.enunciado,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SVColors.onSurface,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 24),
            // ── Divisor decorativo ──
            Container(height: 1, color: SVColors.outlineVariant),
            const SizedBox(height: 20),
            // ── Opciones o campo de texto según tipo ──
            if (pregunta.esOpcionMultiple)
              _buildOpcionesMultiples(pregunta)
            else
              _buildRellenarHueco(pregunta),
          ],
        ),
      ),
    );
  }

  /// Lista de [RadioListTile] para preguntas de opción múltiple.
  Widget _buildOpcionesMultiples(PreguntaGenerada pregunta) {
    final opciones = pregunta.opciones;
    final seleccionada = _respuestas[_indice];
    const letras = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Column(
      children: List.generate(opciones.length, (i) {
        final letra = i < letras.length ? letras[i] : '?';
        final valor = opciones[i];
        final esSeleccionada = seleccionada == valor;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: esSeleccionada
                ? SVColors.primary.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: SVShapes.standard12,
            border: esSeleccionada
                ? Border.all(color: SVColors.primary.withOpacity(0.3), width: 1)
                : null,
          ),
          child: RadioListTile<String>(
            value: valor,
            groupValue: seleccionada,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _respuestas[_indice] = v);
            },
            title: Text(
              valor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        esSeleccionada ? FontWeight.w600 : FontWeight.w400,
                    color:
                        esSeleccionada ? SVColors.primary : SVColors.onSurface,
                  ),
            ),
            secondary: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: esSeleccionada
                    ? SVColors.primary.withOpacity(0.12)
                    : SVColors.surfaceContainerHighest,
                borderRadius: SVShapes.standard,
              ),
              child: Text(
                letra,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: esSeleccionada
                      ? SVColors.primary
                      : SVColors.onSurfaceVariant,
                ),
              ),
            ),
            activeColor: SVColors.primary,
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return SVColors.primary;
              }
              return SVColors.outlineVariant;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: SVShapes.standard12,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        );
      }),
    );
  }

  /// [TextField] para preguntas de tipo "rellenar_hueco".
  Widget _buildRellenarHueco(PreguntaGenerada pregunta) {
    return TextField(
      controller: _huecoCtrl,
      focusNode: _huecoFocus,
      onChanged: (v) => _respuestas[_indice] = v.trim(),
      decoration: InputDecoration(
        hintText: 'Escribe tu respuesta...',
        hintStyle: const TextStyle(color: SVColors.onSurfaceMuted),
        filled: true,
        fillColor: SVColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: const BorderSide(color: SVColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: const BorderSide(color: SVColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: const BorderSide(color: SVColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// Botón "Siguiente" / "Finalizar" en la parte inferior.
  Widget _buildNavegacion(List<PreguntaGenerada> preguntas, int total) {
    final esUltima = _indice == total - 1;
    final tieneRespuesta =
        _respuestas.containsKey(_indice) && _respuestas[_indice]!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Retroceder (no visible en primera pregunta) ──
            if (_indice > 0)
              IconButton(
                onPressed: () {
                  setState(() => _indice--);
                  _huecoCtrl.clear();
                  if (_respuestas.containsKey(_indice)) {
                    _huecoCtrl.text = _respuestas[_indice]!;
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: SVColors.onSurfaceVariant,
              ),
            const Spacer(),
            // ── Siguiente / Finalizar ──
            FilledButton.icon(
              onPressed: tieneRespuesta
                  ? () => _avanzar(preguntas, total, esUltima)
                  : null,
              icon: Icon(
                esUltima ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                size: 20,
              ),
              label: Text(esUltima ? 'Finalizar' : 'Siguiente'),
              style: FilledButton.styleFrom(
                backgroundColor: SVColors.primary,
                foregroundColor: SVColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: SVShapes.standard12,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avanza a la siguiente pregunta o finaliza el simulacro.
  void _avanzar(
    List<PreguntaGenerada> preguntas,
    int total,
    bool esUltima,
  ) {
    // Registrar respuesta actual.
    final respuesta = _respuestas[_indice]!;
    ref
        .read(artefactoEfimeroProvider.notifier)
        .responderPregunta(_indice, respuesta);

    if (esUltima) {
      // ── Finalizar simulacro ──
      ref.read(artefactoEfimeroProvider.notifier).finalizarSimulacro();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ResultadosSimulacroScreen(),
        ),
      );
      return;
    }

    // ── Siguiente pregunta ──
    setState(() {
      _indice++;
      _huecoCtrl.clear();
      if (_respuestas.containsKey(_indice)) {
        _huecoCtrl.text = _respuestas[_indice]!;
      }
    });

    // Enfocar el campo de texto si es rellenar_hueco.
    if (!preguntas[_indice].esOpcionMultiple) {
      _huecoFocus.requestFocus();
    }
  }

  /// Diálogo de confirmación antes de abandonar el simulacro.
  Future<void> _confirmarSalida() async {
    final respondidas = _respuestas.values.where((v) => v.isNotEmpty).length;
    if (respondidas == 0) {
      Navigator.of(context).pop();
      return;
    }

    final sale = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SVColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: SVShapes.large16,
        ),
        title: const Text('¿Abandonar simulacro?'),
        content: Text(
          'Has respondido $respondidas pregunta(s). '
          'Si sales ahora, perderás el progreso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: SVColors.error,
            ),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );

    if (sale == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}
