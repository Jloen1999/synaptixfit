import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/models/db_models.dart';
import '../application/flashcards_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({
    required this.materialId,
    this.revisionIds,
    super.key,
  });
  final String materialId;
  final List<int>? revisionIds;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  bool _isFlipped = false;
  Set<int> _flippedThisRound = {};
  bool _mostrandoTransicion = false;

  late final AnimationController _transicionCtrl;
  late final Animation<double> _transicionScale;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    _flipCtrl.addListener(() => setState(() {}));

    _transicionCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _transicionScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _transicionCtrl,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _transicionCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    _isFlipped = !_isFlipped;
    _flippedThisRound.add(ref.read(flashcardIndiceProvider));
  }

  void _anterior() {
    final idx = ref.read(flashcardIndiceProvider);
    if (idx > 0) {
      _resetFlip();
      ref.read(flashcardIndiceProvider.notifier).state = idx - 1;
    }
  }

  void _siguiente() {
    final preguntas = ref.read(flashcardPreguntasProvider(widget.materialId));
    final total = preguntas.valueOrNull?.length ?? 0;
    final idx = ref.read(flashcardIndiceProvider);
    if (idx < total - 1) {
      _resetFlip();
      ref.read(flashcardIndiceProvider.notifier).state = idx + 1;
    }
  }

  void _marcar(bool dominado) {
    final idx = ref.read(flashcardIndiceProvider);
    ref.read(flashcardResultadosProvider.notifier).update((state) {
      return {...state, idx: dominado};
    });
    HapticFeedback.selectionClick();

    final preguntas = ref.read(flashcardPreguntasProvider(widget.materialId));
    final total = preguntas.valueOrNull?.length ?? 0;
    final resultados = ref.read(flashcardResultadosProvider);

    if (resultados.length >= total && !_mostrandoTransicion) {
      _iniciarTransicion();
      return;
    }

    if (idx < total - 1) {
      _resetFlip();
      ref.read(flashcardIndiceProvider.notifier).state = idx + 1;
    }
  }

  void _iniciarTransicion() {
    HapticFeedback.heavyImpact();
    _resetFlip();
    setState(() => _mostrandoTransicion = true);
    _transicionCtrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _navegarAResultados();
    });
  }

  void _navegarAResultados() {
    final resultados = ref.read(flashcardResultadosProvider);
    final preguntas =
        ref.read(flashcardPreguntasProvider(widget.materialId)).valueOrNull ??
            [];
    final dominadas = resultados.values.where((v) => v).length;
    final dudosas = 0;
    final falladas = resultados.values.where((v) => !v).length;

    final falladasIds = <int>[];
    for (final e in resultados.entries) {
      if (!e.value && e.key < preguntas.length) {
        falladasIds.add(e.key);
      }
    }

    final service = ref.read(flashcardServicioProvider);
    service.aplicarSrs(
      materialId: widget.materialId,
      dominado: dominadas >= (preguntas.length / 2).ceil(),
    );

    if (context.mounted) {
      context.pushReplacement(
        '/academico/flashcards/${widget.materialId}/resultados',
        extra: {
          'dominadas': dominadas,
          'dudosas': dudosas,
          'falladas': falladas,
          'total': preguntas.length,
          'falladasIds': falladasIds,
          'preguntas': preguntas,
        },
      );
    }
  }

  void _resetFlip() {
    if (_isFlipped) {
      _flipCtrl.reset();
      _isFlipped = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SVColors.background,
      appBar: AppBar(
        title: const Text('Flashcards',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: SVColors.background,
        surfaceTintColor: SVColors.background,
      ),
      body: _mostrandoTransicion
          ? _buildTransicion()
          : _preguntasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: SVColors.error),
                  const SizedBox(height: 12),
                  Text('Error: $e',
                      style: const TextStyle(color: SVColors.error),
                      textAlign: TextAlign.center),
                ]),
              ),
              data: (preguntas) {
                if (preguntas.isEmpty) return _vacio();
                return _buildTarjetas(preguntas);
              },
            ),
    );
  }

  AsyncValue<List<PreguntaDb>> get _preguntasAsync {
    final asyncVal = ref.watch(flashcardPreguntasProvider(widget.materialId));
    return asyncVal.whenData((preguntas) {
      if (widget.revisionIds != null && widget.revisionIds!.isNotEmpty) {
        final filtradas = <PreguntaDb>[];
        for (final idx in widget.revisionIds!) {
          if (idx < preguntas.length) filtradas.add(preguntas[idx]);
        }
        return filtradas;
      }
      return preguntas;
    });
  }

  Widget _vacio() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.style_outlined,
            size: 72, color: SVColors.outlineVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        const Text('Sin preguntas disponibles',
            style: TextStyle(
                color: SVColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Genera preguntas con IA primero para estudiar con flashcards.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver'),
          style: ElevatedButton.styleFrom(
            backgroundColor: SVColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12),
          ),
        ),
      ]),
    );
  }

  Widget _buildTarjetas(List<PreguntaDb> preguntas) {
    final idx = ref.watch(flashcardIndiceProvider);
    final resultados = ref.watch(flashcardResultadosProvider);
    final total = preguntas.length;
    final correctas = resultados.values.where((v) => v).length;
    final incorrectas = resultados.values.where((v) => !v).length;

    final pregunta = preguntas[idx];

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Row(children: [
            Text('${idx + 1}/$total',
                style: const TextStyle(
                    color: SVColors.onSurfaceMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$correctas ✓',
                  style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$incorrectas ✗',
                  style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total > 0 ? (idx + 1) / total : 0,
          backgroundColor: SVColors.surfaceContainerHighest,
          color: SVColors.primary,
          minHeight: 3,
        ),
        const Spacer(),
        GestureDetector(
          onTap: _toggleFlip,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _flipAnim,
              builder: (_, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipAnim.value * 3.14159),
                  child: _flipAnim.value <= 0.5
                      ? _tarjetaFrontal(pregunta)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _tarjetaTrasera(pregunta, resultados[idx]),
                        ),
                );
              },
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botonNavegacion(Icons.arrow_back_rounded, 'Anterior',
                  idx > 0 ? _anterior : null),
              _botonAccion(Icons.close_rounded, 'Aún no\nme lo sé',
                  const Color(0xFFEF5350), () => _marcar(false)),
              _botonAccion(Icons.check_rounded, 'Lo domino',
                  const Color(0xFF4CAF50), () => _marcar(true)),
              _botonNavegacion(Icons.arrow_forward_rounded, 'Siguiente',
                  idx < total - 1 ? _siguiente : null),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _tarjetaFrontal(PreguntaDb p) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        borderRadius: SVShapes.large16,
        boxShadow: [
          BoxShadow(
            color: SVColors.outlineVariant.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('PREGUNTA',
                style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 20),
          if (p.tipo == 'rellenar_hueco')
            _huecoEnunciado(p)
          else
            Text(
              _sanearMarkdown(p.enunciado),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaTrasera(PreguntaDb p, bool? fueCorrecta) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        borderRadius: SVShapes.large16,
        boxShadow: [
          BoxShadow(
            color: SVColors.outlineVariant.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('RESPUESTA',
                style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 20),
          Text(
            p.respuestaCorrecta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SVColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          if ((p.explicacion ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SVColors.primary.withValues(alpha: 0.06),
                borderRadius: SVShapes.standard12,
                border:
                    Border.all(color: SVColors.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: SVColors.primary),
                    SizedBox(width: 6),
                    Text('Explicación IA',
                        style: TextStyle(
                            color: SVColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    p.explicacion!,
                    style: const TextStyle(
                      color: SVColors.onSurfaceMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _botonNavegacion(
      IconData icon, String label, VoidCallback? onPressed) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          color:
              onPressed != null ? SVColors.onSurface : SVColors.outlineVariant,
          style: IconButton.styleFrom(
            backgroundColor: SVColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              color: onPressed != null
                  ? SVColors.onSurfaceMuted
                  : SVColors.outlineVariant,
              fontSize: 10,
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _botonAccion(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 64,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12),
          ),
          child: Icon(icon, size: 28),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.2)),
    ]);
  }

  Widget _buildTransicion() {
    return Center(
      child: AnimatedBuilder(
        animation: _transicionScale,
        builder: (_, child) {
          return Transform.scale(
            scale: _transicionScale.value,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF4CAF50), size: 44),
              ),
              const SizedBox(height: 20),
              const Text('¡Sesión completada!',
                  style: TextStyle(
                      color: SVColors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Preparando tus resultados...',
                  style:
                      TextStyle(color: SVColors.onSurfaceMuted, fontSize: 14)),
            ]),
          );
        },
      ),
    );
  }

  Widget _huecoEnunciado(PreguntaDb p) {
    final partes = p.enunciado.split('___');
    final spans = <InlineSpan>[];
    for (int i = 0; i < partes.length; i++) {
      if (partes[i].isNotEmpty) {
        spans.add(TextSpan(
          text: _sanearMarkdown(partes[i]),
          style: const TextStyle(
            color: SVColors.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ));
      }
      if (i < partes.length - 1) {
        final ancho = (p.respuestaCorrecta.length * 10.0).clamp(60.0, 140.0);
        spans.add(WidgetSpan(
          child: Container(
            width: ancho,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: SVColors.primary.withValues(alpha: 0.7),
                  width: 2.5,
                ),
              ),
              color: SVColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
        ));
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

  String _sanearMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*{1,2}([^*]+)\*{1,2}'), '\$1')
        .replaceAll('_', '')
        .replaceAll(RegExp(r'#{1,6}\s?'), '')
        .trim();
  }
}
