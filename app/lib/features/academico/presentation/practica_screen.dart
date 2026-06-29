import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const PracticaScreen({
    required this.materialId,
    this.sessionId,
    this.modoRevision = false,
    super.key,
  });

  final String materialId;
  final String? sessionId;
  final bool modoRevision;

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
  TestSessionDb? _session;
  int _totalPreguntas = 0;

  final _huecoCtrl = TextEditingController();
  final _huecoFocus = FocusNode();
  List<TextEditingController> _huecosCtrls = [];
  List<FocusNode> _huecosFoci = [];
  List<PreguntaDb> _preguntas = [];
  BancoPreguntasDb? _banco;
  bool _cargando = true;
  bool _mostroEvaluacion = false;

  @override
  void dispose() {
    _huecoCtrl.dispose();
    _huecoFocus.dispose();
    for (final c in _huecosCtrls) c.dispose();
    for (final f in _huecosFoci) f.dispose();
    super.dispose();
  }

  void _disponerHuecos(int n) {
    for (final c in _huecosCtrls) c.dispose();
    for (final f in _huecosFoci) f.dispose();
    _huecosCtrls = List.generate(n, (_) => TextEditingController());
    _huecosFoci = List.generate(n, (_) => FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionId != null) return _buildDesdeSesion();
    final datos = ref.watch(bancoPreguntasProvider(widget.materialId));
    return Scaffold(
      backgroundColor: SVColors.background,
      body: SafeArea(
        child: datos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _err(e.toString()),
          data: (data) {
            _banco = data.banco;
            if (_preguntas.isEmpty) _preguntas = data.preguntas;
            if (_preguntas.isEmpty) return _vacio();
            return _completado ? _buildResumen() : _buildPregunta();
          },
        ),
      ),
    );
  }

  Widget _buildDesdeSesion() {
    final sAsync = ref.watch(sesionSesionProvider(widget.sessionId!));
    return Scaffold(
      backgroundColor: SVColors.background,
      body: SafeArea(
        child: sAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _err(e.toString()),
          data: (s) {
            _session = s;
            if (s.status == 'completed' && !widget.modoRevision) {
              _correctas = s.score;
              _totalPreguntas = s.totalPreguntas;
              return _buildResumen();
            }
            if (_cargando) {
              _cargando = false;
              final repo = ref.read(practicaRepositoryProvider);
              repo.obtenerPreguntasDeSesion(s.preguntasIds).then((ps) {
                if (!mounted) return;
                List<PreguntaDb> mostrar = ps;
                if (widget.modoRevision) {
                  final falladas = s.resultados.entries
                      .where((e) => e.value == false)
                      .map((e) => e.key)
                      .toSet();
                  mostrar = ps.where((p) => falladas.contains(p.id)).toList();
                  for (var i = 0; i < mostrar.length; i++)
                    _respuestas[i] = false;
                } else {
                  for (final e in s.resultados.entries) {
                    final idx = s.preguntasIds.indexOf(e.key);
                    if (idx >= 0) _respuestas[idx] = e.value == true;
                  }
                }
                setState(() {
                  _preguntas = mostrar;
                  _totalPreguntas = s.totalPreguntas;
                  if (!widget.modoRevision) {
                    _indice = s.indiceActual.clamp(0, ps.length - 1);
                    _mostrandoFeedback =
                        s.resultados.containsKey(s.preguntasIds[_indice]);
                  }
                });
              });
              return const Center(child: CircularProgressIndicator());
            }
            if (_preguntas.isEmpty) return _vacio();
            return _completado ? _buildResumen() : _buildPregunta();
          },
        ),
      ),
    );
  }

  Widget _err(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: SVColors.error),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: SVColors.error)),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: () => context.pop(), child: const Text('Volver')),
          ],
        ),
      );

  Widget _vacio() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_outlined,
                size: 48, color: SVColors.outlineVariant),
            const SizedBox(height: 12),
            const Text('Sin preguntas todavía',
                style: TextStyle(color: SVColors.onSurfaceMuted)),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: () => context.pop(), child: const Text('Volver')),
          ],
        ),
      );

  Widget _buildPregunta() {
    final p = _preguntas[_indice];
    final esHueco = p.tipo == 'rellenar_hueco';

    return Column(
      children: [
        _barraProgreso(),
        if (_preguntas.length > 1) _navegador(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.modoRevision) ...[
                  _tipoChip(p.tipo),
                  const SizedBox(height: 12),
                ],
                if (!widget.modoRevision && !esHueco)
                  Text(p.enunciado,
                      style: const TextStyle(
                          color: SVColors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.45)),
                const SizedBox(height: 20),
                if (p.tipo == 'opcion_multiple') ..._buildOpciones(p),
                if (esHueco) _buildRellenarHueco(p),
              ],
            ),
          ),
        ),
        if (_mostrandoFeedback && !widget.modoRevision) _buildFeedback(p),
        _buildBotonAccion(p),
      ],
    );
  }

  Widget _barraProgreso() {
    final r = _preguntas.isNotEmpty ? _indice / _preguntas.length : 0.0;
    return Column(children: [
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          IconButton(
              onPressed: _confirmarSalida,
              icon: const Icon(Icons.close, color: SVColors.onSurfaceVariant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
          const Spacer(),
          Text('${_indice + 1}/${_preguntas.length}',
              style: const TextStyle(
                  color: SVColors.onSurfaceMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 6),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: r),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            backgroundColor: SVColors.surfaceContainerHighest,
            color: const Color(0xFF3B82F6),
            minHeight: 3),
      ),
    ]);
  }

  Widget _navegador() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(_preguntas.length, (i) {
          final respondida = _respuestas.containsKey(i);
          final correcta = _respuestas[i] == true;
          final actual = i == _indice;
          final color = respondida
              ? (correcta ? const Color(0xFF4CAF50) : const Color(0xFFEF5350))
              : SVColors.outlineVariant;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: respondida ? () => _navegarA(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: actual ? 28 : 22,
                height: actual ? 28 : 22,
                decoration: BoxDecoration(
                  color: actual
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: actual ? color : color.withValues(alpha: 0.4),
                      width: actual ? 2 : 1.5),
                ),
                child: Center(
                  child: respondida
                      ? (actual
                          ? Text('${i + 1}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700))
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)))
                      : (actual
                          ? Text('${i + 1}',
                              style: const TextStyle(
                                  color: SVColors.onSurfaceMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700))
                          : Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: SVColors.outlineVariant
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle))),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tipoChip(String tipo) {
    final esM = tipo == 'opcion_multiple';
    final c = esM ? const Color(0xFF3B82F6) : const Color(0xFF10B981);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12), borderRadius: SVShapes.standard),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(esM ? Icons.radio_button_checked : Icons.text_fields,
              size: 14, color: c),
          const SizedBox(width: 6),
          Text(esM ? 'Opción múltiple' : 'Rellenar hueco',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c)),
        ]),
      ),
    ]);
  }

  List<Widget> _buildOpciones(PreguntaDb p) {
    final opciones = p.opciones ?? [];
    final fb = _mostrandoFeedback;
    final rev = widget.modoRevision;
    return opciones.map((op) {
      final sel = _seleccionada == op;
      final correcta = op == p.respuestaCorrecta;
      Color? bg, borde;
      if (fb || rev) {
        if (correcta) {
          bg = const Color(0xFF2E7D32).withValues(alpha: 0.12);
          borde = const Color(0xFF2E7D32);
        } else if (sel) {
          bg = const Color(0xFFC62828).withValues(alpha: 0.12);
          borde = const Color(0xFFC62828);
        }
      } else if (sel) {
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        borde = const Color(0xFF3B82F6);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: (fb || rev)
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  setState(() => _seleccionada = op);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: bg ?? SVColors.surfaceContainerLowest,
                borderRadius: SVShapes.standard12,
                border: Border.all(
                    color: borde ?? SVColors.outline.withValues(alpha: 0.2),
                    width: borde != null ? 1.5 : 1)),
            child: Row(children: [
              Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20, color: borde ?? SVColors.outline),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(op,
                      style: TextStyle(
                          color: SVColors.onSurface,
                          fontSize: 15,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400))),
              if ((fb || rev) && correcta)
                const Icon(Icons.check_circle,
                    color: Color(0xFF2E7D32), size: 20),
              if ((fb || rev) && sel && !correcta)
                const Icon(Icons.cancel, color: Color(0xFFC62828), size: 20),
            ]),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRellenarHueco(PreguntaDb p) {
    final palabras = p.respuestaCorrecta.trim().split(RegExp(r'\s+'));
    if (_huecosCtrls.length != palabras.length)
      _disponerHuecos(palabras.length);
    return _HuecoInline(
      enunciado: p.enunciado,
      palabrasEsperadas: palabras,
      controllers: _huecosCtrls,
      foci: _huecosFoci,
      mostrandoFb: _mostrandoFeedback || widget.modoRevision,
      esCorrecta: _respuestas[_indice] == true,
      respuestaCorrecta: p.respuestaCorrecta,
      onChanged: () => setState(() {}),
      onSubmit: () {
        if (!_mostrandoFeedback && !widget.modoRevision) _comprobar(p);
        if (_mostrandoFeedback) _siguiente();
      },
    );
  }

  Widget _buildFeedback(PreguntaDb p) {
    final ok = _respuestas[_indice] == true;
    final c = ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: SVShapes.standard12,
          border: Border.all(color: c.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, color: c, size: 20),
          const SizedBox(width: 8),
          Text(ok ? '¡Correcto!' : 'Incorrecto',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: c))
        ]),
        if (!ok || p.tipo == 'rellenar_hueco') ...[
          const SizedBox(height: 8),
          Text('Respuesta correcta: ${p.respuestaCorrecta}',
              style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600)),
        ],
        if (p.explicacion != null && p.explicacion!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(p.explicacion!,
              style: const TextStyle(
                  color: SVColors.onSurfaceVariant, fontSize: 13, height: 1.4)),
        ],
      ]),
    );
  }

  Widget _buildBotonAccion(PreguntaDb p) {
    if (widget.modoRevision) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_indice < _preguntas.length - 1)
                setState(() => _indice++);
              else
                context.pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF546E7A),
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: SVShapes.standard12)),
            child: Text(
                _indice < _preguntas.length - 1
                    ? 'Siguiente'
                    : 'Finalizar revisión',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    final fb = _mostrandoFeedback;
    final ok = _respuestas[_indice] == true;
    final esUltima = _indice >= _preguntas.length - 1;

    bool habilitado;
    if (fb)
      habilitado = true;
    else
      habilitado = _seleccionada != null ||
          _huecosCtrls.any((c) => c.text.trim().isNotEmpty);

    Color bg;
    String txt;
    if (fb) {
      if (ok) {
        bg = const Color(0xFF3B82F6);
        txt = esUltima ? 'Ver resultado' : 'Continuar';
      } else {
        bg = const Color(0xFF546E7A);
        txt = esUltima ? 'Ver resultado' : 'Entendido — Siguiente';
      }
    } else {
      bg = const Color(0xFF3B82F6);
      txt = 'Comprobar';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed:
              habilitado ? () => fb ? _siguiente() : _comprobar(p) : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: Colors.white,
              disabledBackgroundColor: SVColors.surfaceContainerHighest,
              disabledForegroundColor: SVColors.onSurfaceMuted,
              shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12)),
          child: Text(txt,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  void _comprobar(PreguntaDb p) {
    final resp = p.tipo == 'rellenar_hueco'
        ? _huecosCtrls.map((c) => c.text.trim()).join(' ').toLowerCase()
        : (_seleccionada ?? '').toLowerCase();
    final ok = resp == p.respuestaCorrecta.toLowerCase();
    HapticFeedback.mediumImpact();
    setState(() {
      _respuestas[_indice] = ok;
      _mostrandoFeedback = true;
    });
    ref
        .read(practicaRepositoryProvider)
        .registrarIntento(preguntaId: p.id, esCorrecta: ok);
    _guardarProgreso();
  }

  void _guardarProgreso() {
    if (_session == null || _preguntas.isEmpty) return;
    final resp = <String, dynamic>{}, resul = <String, dynamic>{};
    int sc = 0;
    for (var i = 0; i < _preguntas.length; i++) {
      if (!_respuestas.containsKey(i)) continue;
      final r = _preguntas[i].tipo == 'rellenar_hueco'
          ? _huecosCtrls.map((c) => c.text.trim()).join(' ')
          : (_seleccionada ?? '');
      resp[_preguntas[i].id] = r;
      resul[_preguntas[i].id] = _respuestas[i]!;
      if (_respuestas[i] == true) sc++;
    }
    ref.read(practicaRepositoryProvider).guardarProgresoSesion(
          sessionId: _session!.id,
          respuestas: resp,
          resultados: resul,
          indiceActual: _indice,
          score: sc,
        );
  }

  void _siguiente() {
    int next = _indice + 1;
    while (next < _preguntas.length && _respuestas.containsKey(next)) next++;
    if (next >= _preguntas.length) {
      if (_respuestas.length >= _preguntas.length) {
        _correctas = _respuestas.values.where((v) => v).length;
        setState(() => _completado = true);
        return;
      }
      next = _preguntas.length - 1;
    }
    _navegarA(next);
  }

  void _navegarA(int i) {
    setState(() {
      _indice = i;
      _seleccionada = null;
      _huecoCtrl.clear();
      for (final c in _huecosCtrls) c.clear();
      _mostrandoFeedback = _respuestas.containsKey(i);
    });
  }

  void _confirmarSalida() async {
    final sale = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SVColors.surfaceContainerLowest,
        title: const Text('¿Seguro que quieres salir?',
            style: TextStyle(color: SVColors.onSurface)),
        content: const Text('Perderás el progreso de esta sesión.',
            style: TextStyle(color: SVColors.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Salir', style: TextStyle(color: SVColors.error))),
        ],
      ),
    );
    if (sale == true && mounted) context.pop();
  }

  Widget _buildResumen() {
    _correctas = _respuestas.values.where((v) => v).length;
    final total = _totalPreguntas > 0 ? _totalPreguntas : _preguntas.length;
    final pct = total > 0 ? (_correctas / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 32),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: pct / 100),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => SizedBox(
              width: 120,
              height: 120,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 8,
                    color: SVColors.surfaceContainerHighest),
                CircularProgressIndicator(
                    value: v,
                    strokeWidth: 8,
                    color: pct >= 80
                        ? const Color(0xFF4CAF50)
                        : pct >= 50
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFEF5350),
                    strokeCap: StrokeCap.round),
                Text('$pct%',
                    style: TextStyle(
                        color: pct >= 80
                            ? const Color(0xFF4CAF50)
                            : pct >= 50
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFEF5350),
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
              ])),
        ),
        const SizedBox(height: 20),
        Text('$_correctas/$total correctas',
            style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _buildEstrellas(pct),
        const SizedBox(height: 28),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (_, v, __) => Transform.scale(
              scale: v,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: SVShapes.standard12,
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                  SizedBox(width: 8),
                  Text('+20 XP',
                      style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ]),
              )),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _mostrarEvaluacion,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: SVShapes.standard12)),
            child: const Text('Evaluar dominio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
            onPressed: () => context.pop(),
            child: const Text('Volver sin evaluar',
                style: TextStyle(color: SVColors.onSurfaceMuted))),
      ]),
    );
  }

  Widget _buildEstrellas(int pct) {
    final n = pct >= 90
        ? 3
        : pct >= 60
            ? 2
            : pct >= 30
                ? 1
                : 0;
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            3,
            (i) => AnimatedOpacity(
                  duration: Duration(milliseconds: 300 + i * 150),
                  opacity: i < n ? 1.0 : 0.2,
                  child: Icon(
                      i < n ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 32),
                )));
  }

  void _mostrarEvaluacion() {
    if (_mostroEvaluacion) return;
    _mostroEvaluacion = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: SVColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _EvaluacionSheet(onSeleccion: _aplicarEvaluacion),
    );
  }

  Future<void> _aplicarEvaluacion(int calidad) async {
    final repo = ref.read(materialesEstudioRepositoryProvider);
    final existing = await Supabase.instance.client
        .from('materiales_estudio')
        .select()
        .eq('id', widget.materialId)
        .maybeSingle();
    if (existing == null || !mounted) return;
    final material = MaterialEstudioDb.fromMap(existing);
    final sm2 = Sm2Calculator.calcular(
        calidad: calidad,
        intervaloActualDias: material.intervaloActualDias,
        facilidad: material.facilidad,
        repasosCompletados: material.repasosCompletados);
    final siguiente = DateTime.now().add(Duration(days: sm2.intervaloDias));
    await repo.actualizarEstadoSm2(
        materialId: widget.materialId,
        estadoDominio: sm2.estadoDominio,
        intervaloActualDias: sm2.intervaloDias,
        facilidad: sm2.facilidad,
        repasosCompletados: sm2.repasosCompletados,
        siguienteRepasoEn: siguiente,
        ultimoRepasoEn: DateTime.now());
    await _inyectarRepaso(material, siguiente);
    if (_session != null) {
      _correctas = _respuestas.values.where((v) => v).length;
      await ref
          .read(practicaRepositoryProvider)
          .completarSesion(_session!.id, _correctas);
    }
    await _otorgarXp();
    if (mounted) {
      ref.invalidate(materialesAsignaturaProvider(material.asignaturaId));
      if (context.mounted) {
        context.pop();
        context.pop();
      }
    }
  }

  Future<void> _inyectarRepaso(MaterialEstudioDb m, DateTime f) async {
    try {
      final client = Supabase.instance.client;
      final inicio = DateTime(f.year, f.month, f.day, 9, 0),
          fin = DateTime(f.year, f.month, f.day, 9, 30);
      final ex = await client
          .from('horarios_academicos')
          .select('id')
          .eq('asignatura_id', m.asignaturaId)
          .eq('tipo_actividad', 'repaso')
          .eq('temas', 'Repaso: ${m.titulo}')
          .eq('completado', false)
          .maybeSingle();
      final d = {
        'usuario_id': m.usuarioId,
        'asignatura_id': m.asignaturaId,
        'tipo_actividad': 'repaso',
        'hora_inicio': inicio.toIso8601String(),
        'hora_fin': fin.toIso8601String(),
        'dia_semana': f.weekday,
        'es_fijo': false,
        'temas': 'Repaso: ${m.titulo}',
        'completado': false,
        'tiene_conflicto': false
      };
      if (ex != null)
        await client.from('horarios_academicos').update(d).eq('id', ex['id']);
      else
        await client.from('horarios_academicos').insert(d);
    } catch (e) {
      debugPrint('Error repaso: $e');
    }
  }

  Future<void> _otorgarXp() async {
    try {
      final repo = ref.read(practicaRepositoryProvider);
      final sid = _session?.id;
      final otorgado = sid != null
          ? await repo.otorgarXpSiProcede(sid)
          : await repo.otorgarXpSiProcede(_banco!.id);
      if (!otorgado) return;
      final total = _totalPreguntas > 0 ? _totalPreguntas : _preguntas.length;
      final pct = total > 0 ? _correctas / total : 0;
      final xp = 20 + (pct >= 0.8 ? 10 : 0);
      ref.read(syncHubProvider).dispatch(DominioEvento.practicaCompletada,
          payload: EventoPayload(xpGanado: xp));
    } catch (e) {
      debugPrint('Error XP: $e');
    }
  }
}

class _EvaluacionSheet extends StatelessWidget {
  const _EvaluacionSheet({required this.onSeleccion});
  final void Function(int) onSeleccion;
  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: SVColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('¿Cómo dominas este tema?',
              style: TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _chip(Icons.check_circle, 'Dominio absoluto', const Color(0xFF4CAF50),
              () => onSeleccion(2)),
          const SizedBox(height: 10),
          _chip(Icons.trending_up, 'Me cuesta', const Color(0xFFFFC107),
              () => onSeleccion(1)),
          const SizedBox(height: 10),
          _chip(Icons.refresh, 'Toca repasar', const Color(0xFFEF5350),
              () => onSeleccion(0)),
        ]),
      );
  Widget _chip(IconData i, String l, Color co, VoidCallback t) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: t,
          style: ElevatedButton.styleFrom(
              backgroundColor: co.withValues(alpha: 0.1),
              foregroundColor: co,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: SVShapes.standard12,
                  side: BorderSide(color: co.withValues(alpha: 0.3)))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, size: 22),
            const SizedBox(width: 10),
            Text(l,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _HuecoInline extends StatelessWidget {
  const _HuecoInline(
      {required this.enunciado,
      required this.palabrasEsperadas,
      required this.controllers,
      required this.foci,
      required this.mostrandoFb,
      required this.esCorrecta,
      required this.respuestaCorrecta,
      required this.onChanged,
      required this.onSubmit});
  final String enunciado;
  final List<String> palabrasEsperadas;
  final List<TextEditingController> controllers;
  final List<FocusNode> foci;
  final bool mostrandoFb, esCorrecta;
  final String respuestaCorrecta;
  final VoidCallback onChanged, onSubmit;

  @override
  Widget build(BuildContext c) {
    final n = palabrasEsperadas.length;
    final todosLlenos = controllers.every((c) => c.text.trim().isNotEmpty);
    final b = _borde();
    final partes = enunciado.split('___');
    final antes = partes.isNotEmpty ? partes.first.trim() : '';
    final despues = partes.length > 1 ? partes[1].trim() : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: SVColors.surfaceContainerLowest,
          borderRadius: SVShapes.standard12,
          border: Border.all(color: SVColors.outline.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(
            text: TextSpan(
                style: const TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 17,
                    height: 1.6,
                    fontWeight: FontWeight.w500),
                children: [
              if (antes.isNotEmpty) TextSpan(text: '$antes '),
              ...List.generate(n, (i) {
                final ancho =
                    (palabrasEsperadas[i].length * 13.0).clamp(48.0, 150.0);
                final bg = mostrandoFb
                    ? (esCorrecta
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.07)
                        : const Color(0xFFC62828).withValues(alpha: 0.07))
                    : null;
                return WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: SizedBox(
                        width: ancho,
                        child: _InputBlanco(
                            controller: controllers[i],
                            focusNode: foci[i],
                            habilitado: !mostrandoFb,
                            bordeColor: b,
                            bgColor: bg,
                            hint: '${i + 1}ª',
                            onChanged: () {
                              final t = controllers[i].text;
                              if (t.contains(' ') && i < n - 1) {
                                controllers[i].text = t.split(' ').first;
                                controllers[i + 1].text =
                                    t.split(' ').skip(1).join(' ');
                                foci[i + 1].requestFocus();
                              }
                              onChanged();
                            },
                            onSubmit: () {
                              if (!mostrandoFb &&
                                  i < n - 1 &&
                                  controllers[i].text.trim().isNotEmpty)
                                foci[i + 1].requestFocus();
                              else
                                onSubmit();
                            })));
              }),
              if (despues.isNotEmpty) TextSpan(text: ' $despues'),
            ])),
        if (!mostrandoFb && n > 1)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Icon(Icons.info_outline,
                    size: 13,
                    color: SVColors.onSurfaceMuted.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text('$n palabras',
                    style: TextStyle(
                        color: SVColors.onSurfaceMuted.withValues(alpha: 0.7),
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic)),
                if (todosLlenos) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle,
                      size: 14, color: Color(0xFF4CAF50))
                ],
              ])),
        if (mostrandoFb) ...[
          const SizedBox(height: 14),
          Row(children: [
            Icon(esCorrecta ? Icons.check_circle : Icons.cancel,
                color: esCorrecta
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
                size: 20),
            const SizedBox(width: 8),
            Flexible(
                child: Text(esCorrecta ? '¡Correcto!' : respuestaCorrecta,
                    style: TextStyle(
                        color: esCorrecta
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration:
                            esCorrecta ? null : TextDecoration.underline,
                        decorationColor: const Color(0xFF2E7D32),
                        decorationThickness: 2))),
          ]),
        ],
      ]),
    );
  }

  Color _borde() {
    if (!mostrandoFb) return const Color(0xFF10B981);
    return esCorrecta ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
  }
}

class _InputBlanco extends StatelessWidget {
  const _InputBlanco(
      {required this.controller,
      required this.focusNode,
      required this.habilitado,
      required this.bordeColor,
      this.bgColor,
      this.onSubmit,
      this.onChanged,
      this.hint});
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool habilitado;
  final Color bordeColor;
  final Color? bgColor;
  final VoidCallback? onSubmit, onChanged;
  final String? hint;

  @override
  Widget build(BuildContext c) => TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: habilitado,
        autofocus: true,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.done,
        style: TextStyle(
            color: habilitado ? SVColors.onSurface : bordeColor,
            fontSize: 17,
            fontWeight: FontWeight.w600),
        cursorColor: bordeColor,
        onSubmitted: (_) => onSubmit?.call(),
        onChanged: (_) => onChanged?.call(),
        decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: bgColor != null,
            fillColor: bgColor,
            hintText: habilitado ? (hint ?? '...') : null,
            hintStyle:
                TextStyle(color: SVColors.outline.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: bordeColor, width: 2)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: bordeColor, width: 2.5)),
            disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: bordeColor, width: 2))),
      );
}
