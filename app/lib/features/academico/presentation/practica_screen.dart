import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../core/sync/dominio_evento.dart';
import '../../../../core/sync/sync_hub.dart';
import '../../../../shared/models/db_models.dart';
import '../application/materiales_estudio_provider.dart';
import '../application/practica_provider.dart';
import '../infrastructure/sm2_calculator.dart';

class PracticaScreen extends ConsumerStatefulWidget {
  const PracticaScreen({required this.materialId, super.key});

  final String materialId;

  @override
  ConsumerState<PracticaScreen> createState() => _PracticaScreenState();
}

class _PracticaScreenState extends ConsumerState<PracticaScreen> {
  int _indice = 0;
  final _respuestas = <int, bool>{};
  String? _seleccionada;
  bool _mostrandoFeedback = false;
  bool _completado = false;
  int _correctas = 0;

  final _huecoCtrl = TextEditingController();

  @override
  void dispose() {
    _huecoCtrl.dispose();
    super.dispose();
  }

  List<PreguntaDb> _preguntas = [];
  BancoPreguntasDb? _banco;

  @override
  Widget build(BuildContext context) {
    final datos = ref.watch(bancoPreguntasProvider(widget.materialId));

    return Scaffold(
      backgroundColor: SVColors.background,
      body: SafeArea(
        child: datos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48,
                    color: SVColors.error),
                const SizedBox(height: 12),
                Text('Error al cargar la práctica',
                    style: TextStyle(color: SVColors.error)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
          data: (data) {
            _banco = data.banco;
            _preguntas = data.preguntas;
            if (_preguntas.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 48,
                        color: SVColors.outlineVariant),
                    const SizedBox(height: 12),
                    const Text('Sin preguntas todavía',
                        style: TextStyle(color: SVColors.onSurfaceMuted)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              );
            }
            return _buildContenido();
          },
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_completado) return _buildResumen();
    return _buildPregunta();
  }

  Widget _buildPregunta() {
    final p = _preguntas[_indice];
    final progreso = '${_indice + 1}/${_preguntas.length}';

    return Column(
      children: [
        _barraProgreso(progreso),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _tipoChip(p.tipo),
                const SizedBox(height: 16),
                Text(p.enunciado,
                    style: const TextStyle(
                      color: SVColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    )),
                const SizedBox(height: 24),
                if (p.tipo == 'opcion_multiple') ..._buildOpciones(p),
                if (p.tipo == 'rellenar_hueco') _buildRellenarHueco(p),
              ],
            ),
          ),
        ),
        if (_mostrandoFeedback) _buildFeedback(p),
        _buildBotonComprobar(p),
      ],
    );
  }

  Widget _barraProgreso(String texto) {
    final ratio = (_indice) / _preguntas.length;
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: SVColors.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              Text(texto,
                  style: const TextStyle(
                      color: SVColors.onSurfaceMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: SVColors.surfaceContainerHighest,
          color: const Color(0xFF3B82F6),
          minHeight: 3,
        ),
      ],
    );
  }

  Widget _tipoChip(String tipo) {
    final esMultiple = tipo == 'opcion_multiple';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (esMultiple ? const Color(0xFF3B82F6) : const Color(0xFF10B981))
                .withValues(alpha: 0.12),
            borderRadius: SVShapes.standard,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esMultiple
                    ? Icons.radio_button_checked
                    : Icons.text_fields,
                size: 14,
                color:
                    esMultiple ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Text(
                esMultiple ? 'Opción múltiple' : 'Rellenar hueco',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: esMultiple
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOpciones(PreguntaDb p) {
    final opciones = p.opciones ?? [];
    return opciones.map((op) {
      final esSeleccionada = _seleccionada == op;
      final esCorrecta = op == p.respuestaCorrecta;
      Color? bg;
      Color? borde;
      if (_mostrandoFeedback) {
        if (esCorrecta) {
          bg = const Color(0xFF2E7D32).withValues(alpha: 0.1);
          borde = const Color(0xFF2E7D32);
        } else if (esSeleccionada && !esCorrecta) {
          bg = const Color(0xFFC62828).withValues(alpha: 0.1);
          borde = const Color(0xFFC62828);
        }
      } else if (esSeleccionada) {
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.08);
        borde = const Color(0xFF3B82F6);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: _mostrandoFeedback ? null : () => setState(() => _seleccionada = op),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bg ?? SVColors.surfaceContainerLowest,
              borderRadius: SVShapes.standard12,
              border: Border.all(
                color: borde ?? SVColors.outline.withValues(alpha: 0.2),
                width: borde != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  esSeleccionada
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: borde ?? SVColors.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(op,
                      style: TextStyle(
                        color: SVColors.onSurface,
                        fontSize: 15,
                        fontWeight:
                            esSeleccionada ? FontWeight.w600 : FontWeight.w400,
                      )),
                ),
                if (_mostrandoFeedback && esCorrecta)
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                if (_mostrandoFeedback && esSeleccionada && !esCorrecta)
                  const Icon(Icons.cancel, color: Color(0xFFC62828), size: 20),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRellenarHueco(PreguntaDb p) {
    return TextField(
      controller: _huecoCtrl,
      enabled: !_mostrandoFeedback,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _comprobar(p),
      decoration: InputDecoration(
        hintText: 'Escribe tu respuesta...',
        filled: true,
        fillColor: SVColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: BorderSide(color: SVColors.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SVShapes.standard12,
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
        suffixIcon: _mostrandoFeedback
            ? Icon(
                _respuestas[_indice] == true
                    ? Icons.check_circle
                    : Icons.cancel,
                color: _respuestas[_indice] == true
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              )
            : null,
      ),
    );
  }

  Widget _buildFeedback(PreguntaDb p) {
    final esCorrecta = _respuestas[_indice] == true;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esCorrecta
            ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
            : const Color(0xFFC62828).withValues(alpha: 0.08),
        borderRadius: SVShapes.standard12,
        border: Border.all(
          color: esCorrecta
              ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
              : const Color(0xFFC62828).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esCorrecta ? Icons.check_circle : Icons.cancel,
                color: esCorrecta
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                esCorrecta ? '¡Correcto!' : 'Incorrecto',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: esCorrecta
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          if (p.tipo == 'rellenar_hueco') ...[
            const SizedBox(height: 6),
            Text('Respuesta correcta: ${p.respuestaCorrecta}',
                style: const TextStyle(
                    color: SVColors.onSurfaceMuted, fontSize: 13)),
          ],
          if (p.explicacion != null && p.explicacion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.explicacion!,
                style: const TextStyle(
                    color: SVColors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonComprobar(PreguntaDb p) {
    final habilitado = !_mostrandoFeedback &&
        (_seleccionada != null || _huecoCtrl.text.trim().isNotEmpty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: habilitado
              ? () => _mostrandoFeedback ? _siguiente() : _comprobar(p)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _mostrandoFeedback
                ? const Color(0xFF2E7D32)
                : const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            disabledBackgroundColor: SVColors.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
                borderRadius: SVShapes.standard12),
          ),
          child: Text(
            _mostrandoFeedback
                ? (_indice < _preguntas.length - 1
                    ? 'Siguiente'
                    : 'Ver resultado')
                : 'Comprobar',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  void _comprobar(PreguntaDb p) {
    final respuestaUsuario = p.tipo == 'rellenar_hueco'
        ? _huecoCtrl.text.trim().toLowerCase()
        : _seleccionada ?? '';

    final esCorrecta =
        respuestaUsuario == p.respuestaCorrecta.toLowerCase();

    setState(() {
      _respuestas[_indice] = esCorrecta;
      _mostrandoFeedback = true;
    });

    ref.read(practicaRepositoryProvider).registrarIntento(
          preguntaId: p.id,
          esCorrecta: esCorrecta,
        );
  }

  void _siguiente() {
    if (_indice < _preguntas.length - 1) {
      setState(() {
        _indice++;
        _seleccionada = null;
        _huecoCtrl.clear();
        _mostrandoFeedback = false;
      });
    } else {
      setState(() {
        _completado = true;
      });
      _mostrarEvaluacion();
    }
  }

  Widget _buildResumen() {
    _correctas = _respuestas.values.where((v) => v).length;
    final total = _preguntas.length;
    final pct = total > 0 ? (_correctas / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            pct >= 80 ? Icons.emoji_events : pct >= 50 ? Icons.trending_up : Icons.school,
            size: 72,
            color: pct >= 80
                ? const Color(0xFFF59E0B)
                : pct >= 50
                    ? const Color(0xFF3B82F6)
                    : SVColors.onSurfaceMuted,
          ),
          const SizedBox(height: 16),
          Text('$_correctas/$total correctas',
              style: const TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('$pct%',
              style: const TextStyle(
                  color: SVColors.onSurfaceMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _mostrarEvaluacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: SVShapes.standard12),
              ),
              child: const Text('Evaluar dominio',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Volver sin evaluar',
                style: TextStyle(color: SVColors.onSurfaceMuted)),
          ),
        ],
      ),
    );
  }

  void _mostrarEvaluacion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SVColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      isScrollControlled: true,
      builder: (_) => _EvaluacionSheet(
        onSeleccion: _aplicarEvaluacion,
      ),
    );
  }

  Future<void> _aplicarEvaluacion(int calidad) async {
    final repo = ref.read(materialesEstudioRepositoryProvider);

    final existing = await Supabase.instance.client
        .from('materiales_estudio')
        .select()
        .eq('id', widget.materialId)
        .maybeSingle();

    if (existing == null) return;

    final material = MaterialEstudioDb.fromMap(existing);

    final sm2 = Sm2Calculator.calcular(
      calidad: calidad,
      intervaloActualDias: material.intervaloActualDias,
      facilidad: material.facilidad,
      repasosCompletados: material.repasosCompletados,
    );

    final siguiente = DateTime.now().add(Duration(days: sm2.intervaloDias));

    await repo.actualizarEstadoSm2(
      materialId: widget.materialId,
      estadoDominio: sm2.estadoDominio,
      intervaloActualDias: sm2.intervaloDias,
      facilidad: sm2.facilidad,
      repasosCompletados: material.repasosCompletados + (calidad == 2 ? 1 : 0),
      siguienteRepasoEn: siguiente,
      ultimoRepasoEn: DateTime.now(),
    );

    await _inyectarRepasoEnTimeline(material, siguiente);

    await _otorgarXp();

    if (mounted) {
      ref.invalidate(materialesAsignaturaProvider(material.asignaturaId));
      context.pop();
      context.pop();
    }
  }

  Future<void> _inyectarRepasoEnTimeline(
    MaterialEstudioDb material,
    DateTime fecha,
  ) async {
    try {
      final diaSemana = fecha.weekday;
      final inicio = DateTime(fecha.year, fecha.month, fecha.day, 9, 0);
      final fin = DateTime(fecha.year, fecha.month, fecha.day, 9, 30);

      await Supabase.instance.client.from('horarios_academicos').upsert({
        'usuario_id': material.usuarioId,
        'asignatura_id': material.asignaturaId,
        'tipo_actividad': 'repaso',
        'hora_inicio': inicio.toIso8601String(),
        'hora_fin': fin.toIso8601String(),
        'dia_semana': diaSemana,
        'es_fijo': false,
        'temas': 'Repaso: ${material.titulo}',
        'completado': false,
        'tiene_conflicto': false,
      });
    } catch (e) {
      debugPrint('Error al inyectar repaso en timeline: $e');
    }
  }

  Future<void> _otorgarXp() async {
    try {
      final repo = ref.read(practicaRepositoryProvider);
      final otorgado = await repo.otorgarXpSiProcede(_banco!.id);
      if (otorgado) {
        final syncHub = ref.read(syncHubProvider);
        syncHub.dispatch(
          DominioEvento.practicaCompletada,
          payload: const EventoPayload(xpGanado: 20),
        );
      }
    } catch (e) {
      debugPrint('Error al otorgar XP: $e');
    }
  }
}

class _EvaluacionSheet extends StatelessWidget {
  const _EvaluacionSheet({required this.onSeleccion});

  final void Function(int calidad) onSeleccion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: SVColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('¿Cómo dominas este tema?',
              style: TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _chip(
            icon: Icons.check_circle,
            label: 'Dominio absoluto',
            color: const Color(0xFF4CAF50),
            onTap: () => onSeleccion(2),
          ),
          const SizedBox(height: 10),
          _chip(
            icon: Icons.trending_up,
            label: 'Me cuesta',
            color: const Color(0xFFFFC107),
            onTap: () => onSeleccion(1),
          ),
          const SizedBox(height: 10),
          _chip(
            icon: Icons.refresh,
            label: 'Toca repasar',
            color: const Color(0xFFEF5350),
            onTap: () => onSeleccion(0),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: SVShapes.standard12,
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
