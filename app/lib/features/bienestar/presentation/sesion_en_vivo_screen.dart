import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/exercise_thumb.dart';
import '../../../shared/widgets/exercise_metrics.dart';
import '../../perfil/application/perfil_provider.dart';
import '../application/rutina_provider.dart';
import '../application/ejercicios_provider.dart';
import '../../dashboard/application/timeline_provider.dart';

/// Nombre del día de rutina (para mostrarlo en la cabecera del entrenamiento).
final _diaNombreProvider =
    FutureProvider.family<String?, String>((ref, diaId) async {
  final client = Supabase.instance.client;
  final row = await client
      .from('dias_rutina')
      .select('nombre, numero_dia')
      .eq('id', diaId)
      .maybeSingle();
  if (row == null) return null;
  final nombre = (row['nombre'] as String?)?.trim();
  if (nombre != null && nombre.isNotEmpty) return nombre;
  final num = row['numero_dia'];
  return num != null ? 'Día $num' : null;
});

class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({super.key});
  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  late final String _diaId;
  late final String _rutinaId;
  bool _paramsCargados = false;

  Timer? _cronometro;
  int _segundosTotales = 0;

  Timer? _descansoTimer;
  int _descansoRestante = 0;
  String? _descansoActivoEjercicioId;
  int? _descansoActivoSerie;

  final Map<String, Map<int, _SerieLocal>> _seriesLocales = {};
  final Map<String, TextEditingController> _pesoCtrl = {};
  final Map<String, TextEditingController> _repsCtrl = {};

  /// Sistema de vueltas (laps) basado en timestamps.
  /// Preciso aunque la app pase a segundo plano.
  final Map<String, DateTime> _lapStartTimes = {};
  final Map<String, int> _duracionRealMap = {};

  String? _sesionId;
  bool _sesionIniciada = false;
  bool _finalizando = false;
  bool _checkInMostrado = false;
  bool _mostrarOverlayCheckIn = false;
  bool _seriesReducidas = false;
  List<String> _zonasEvitar = [];

  @override
  void initState() => super.initState();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paramsCargados) return;
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null) {
      _diaId = extra['diaId'] as String;
      _rutinaId = extra['rutinaId'] as String;
      _paramsCargados = true;
    }
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    _descansoTimer?.cancel();
    for (final c in _pesoCtrl.values) {
      c.dispose();
    }
    for (final c in _repsCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  Future<void> _iniciarSesion() async {
    setState(() => _sesionIniciada = true);
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundosTotales++);
    });
    final id =
        await iniciarSesion(rutinaId: _rutinaId, diaId: _diaId, ref: ref);
    if (mounted) setState(() => _sesionId = id);
  }

  void _marcarSerie(String seleccionId, int numSerie, bool completada) {
    final key = seleccionId;
    _seriesLocales.putIfAbsent(key, () => {});
    _seriesLocales[key]![numSerie] = _SerieLocal(
      completada: completada,
      pesoKg: double.tryParse(_pesoCtrl['${key}_$numSerie']?.text ?? ''),
      reps: int.tryParse(_repsCtrl['${key}_$numSerie']?.text ?? ''),
    );
    setState(() {});

    // Sistema de laps por timestamp — primera interacción con el ejercicio
    if (completada) {
      _lapStartTimes.putIfAbsent(key, () => DateTime.now());
    }

    if (completada && _sesionId != null) {
      final reps = int.tryParse(_repsCtrl['${key}_$numSerie']?.text ?? '');
      final peso = double.tryParse(_pesoCtrl['${key}_$numSerie']?.text ?? '');
      registrarSerie(
          sesionId: _sesionId!,
          seleccionId: seleccionId,
          numeroSerie: numSerie,
          repeticionesRealizadas: reps,
          pesoKg: peso,
          completada: true);
    }
    if (completada) _iniciarDescanso(seleccionId, numSerie);
  }

  void _capturarLap(String seleccionId) {
    final inicio = _lapStartTimes[seleccionId];
    if (inicio == null) return;
    final delta = DateTime.now().difference(inicio).inSeconds;
    _duracionRealMap[seleccionId] =
        (_duracionRealMap[seleccionId] ?? 0) + delta;
    _lapStartTimes[seleccionId] = DateTime.now();
  }

  void _iniciarDescanso(String ejercicioId, int numSerie) {
    _descansoTimer?.cancel();
    _descansoRestante = 90;
    _descansoActivoEjercicioId = ejercicioId;
    _descansoActivoSerie = numSerie;
    setState(() {});
    _descansoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _descansoRestante--;
        if (_descansoRestante <= 0) {
          _descansoTimer?.cancel();
          _descansoActivoEjercicioId = null;
          _descansoActivoSerie = null;
        }
      });
    });
    if (!_checkInMostrado) _lanzarCheckInOverlay();
  }

  void _saltarDescanso() {
    _descansoTimer?.cancel();
    _descansoActivoEjercicioId = null;
    _descansoActivoSerie = null;
    setState(() {});
  }

  void _ajustarDescanso(int s) {
    _descansoRestante = (_descansoRestante + s).clamp(5, 600);
    setState(() {});
  }

  Future<void> _finalizarSesion() async {
    final result = await showDialog<_FinalizacionResult>(
      context: context,
      builder: (ctx) {
        int selectedRpe = 7;
        bool guardarCambios = false;
        return StatefulBuilder(builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('Finalizar entrenamiento'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Text(_formatoTiempo(_segundosTotales),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700))),
                  const SizedBox(height: 16),
                  Text('Esfuerzo: $selectedRpe/10',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                      value: selectedRpe.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$selectedRpe',
                      onChanged: (v) => setD(() => selectedRpe = v.round())),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('¿Guardar cambios en la rutina?',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: ChoiceChip(
                            label: const Text('Solo hoy',
                                style: TextStyle(fontSize: 11)),
                            selected: !guardarCambios,
                            onSelected: (_) =>
                                setD(() => guardarCambios = false))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: ChoiceChip(
                            label: const Text('Para siempre',
                                style: TextStyle(fontSize: 11)),
                            selected: guardarCambios,
                            onSelected: (_) =>
                                setD(() => guardarCambios = true))),
                  ]),
                ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(
                      ctx, _FinalizacionResult(selectedRpe, guardarCambios)),
                  child: const Text('Finalizar')),
            ],
          );
        });
      },
    );
    if (result != null && _sesionId != null && mounted) {
      setState(() => _finalizando = true);
      _cronometro?.cancel();
      _descansoTimer?.cancel();

      // Capturar todos los laps abiertos antes de finalizar
      for (final id in _lapStartTimes.keys.toList()) {
        _capturarLap(id);
      }

      final xpResult = await finalizarSesion(
          sesionId: _sesionId!,
          diaId: _diaId,
          rutinaId: _rutinaId,
          duracionSegundos: _segundosTotales,
          rpe: result.rpe,
          duracionRealPorEjercicio: Map<String, int>.from(_duracionRealMap),
          ref: ref);
      ref.invalidate(timelineHoyProvider);
      if (mounted) {
        if (xpResult != null && xpResult.subeNivel) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '¡Subiste a nivel ${xpResult.nuevoNivel}! 🎉 +${xpResult.xpGanado} XP'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (xpResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('+${xpResult.xpGanado} XP 🔥'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        context.go('/bienestar/rutina/$_rutinaId');
      }
    }
  }

  String _formatoTiempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------

  void _lanzarCheckInOverlay() {
    if (_checkInMostrado || _mostrarOverlayCheckIn) return;
    _checkInMostrado = true;

    // Verificar antes de mostrar el overlay
    ref.read(estadoDiarioHoyProvider.future).then((estadoHoy) {
      if (estadoHoy != null) return; // Ya hay check-in, no molestar
      if (!mounted) return;
      setState(() => _mostrarOverlayCheckIn = true);
    }).catchError((_) {
      // Si falla la consulta, mostrar igual para no perder la oportunidad
      if (mounted) setState(() => _mostrarOverlayCheckIn = true);
    });
  }

  Widget _buildTimerBar(ThemeData theme) {
    final ejerciciosAsync =
        _paramsCargados ? ref.watch(ejerciciosDeDiaProvider(_diaId)) : null;
    final ejercicios = ejerciciosAsync?.valueOrNull ?? [];
    final objetivoTotalSeg = ejercicios.fold<int>(
      0,
      (sum, e) => sum + (e.duracionObjetivoSegundos ?? 0),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Icon(Icons.timer_rounded, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Text(_formatoTiempo(_segundosTotales),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_descansoActivoEjercicioId != null) ...[
              Text('Descanso ${_formatoTiempo(_descansoRestante)}',
                  style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(width: 8),
              _btn('Saltar', Colors.orange, _saltarDescanso),
            ],
          ]),
          if (objetivoTotalSeg > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Objetivo: ${_formatoTiempo(objetivoTotalSeg)}',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diaNombre = _paramsCargados
        ? ref.watch(_diaNombreProvider(_diaId)).valueOrNull
        : null;
    if (!_sesionIniciada) {
      return FeatureScaffold(
          title: diaNombre ?? 'Entrenamiento',
          backPath: '/bienestar',
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fitness_center_rounded,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('¿Listo para entrenar?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            FilledButton.icon(
                onPressed: _iniciarSesion,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Empezar entrenamiento')),
          ])));
    }
    return FeatureScaffold(
        title: diaNombre ?? 'Entrenamiento',
        backPath: '/bienestar',
        child: Stack(children: [
          Column(children: [
            _buildTimerBar(theme),
            Expanded(
                child: _EjerciciosList(
                    diaId: _diaId,
                    seriesLocales: _seriesLocales,
                    pesoCtrl: _pesoCtrl,
                    repsCtrl: _repsCtrl,
                    seriesReducidas: _seriesReducidas,
                    zonasEvitar: _zonasEvitar,
                    descansoActivoEjercicioId: _descansoActivoEjercicioId,
                    descansoActivoSerie: _descansoActivoSerie,
                    descansoRestante: _descansoRestante,
                    onMarcarSerie: _marcarSerie,
                    onSaltarDescanso: _saltarDescanso,
                    onAjustarDescanso: _ajustarDescanso)),
            SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _finalizando ? null : _finalizarSesion,
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: _finalizando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.stop_circle_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Finalizar entrenamiento',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        )))),
          ]),
          if (_mostrarOverlayCheckIn)
            _CheckInOverlay(
              onGuardado: (r) {
                _mostrarOverlayCheckIn = false;
                setState(() {});
                _mostrarSugerenciasAdaptacion(r);
              },
              onOmitir: () => setState(() => _mostrarOverlayCheckIn = false),
            ),
        ]));
  }

  void _mostrarSugerenciasAdaptacion(_CheckInResult r) {
    final sugerencias = <_SugerenciaAdaptacion>[];
    final fatiga = (6 - r.sueno) * 5 +
        (r.estres - 1) * 5 +
        (6 - r.energia) * 4 +
        (r.dolor - 1) * 7;

    if (fatiga > 50) {
      sugerencias.add(_SugerenciaAdaptacion(
        icon: Icons.fitness_center_rounded,
        titulo: 'Reducir 1 serie por ejercicio',
        descripcion: 'Fatiga alta detectada.',
        aplicar: () => setState(() => _seriesReducidas = true),
      ));
    }
    if (r.dolor >= 3 && r.zonasDolor.isNotEmpty) {
      sugerencias.add(_SugerenciaAdaptacion(
        icon: Icons.healing_rounded,
        titulo: 'Evitar ejercicios de zonas con dolor',
        descripcion: r.zonasDolor.join(', '),
        aplicar: () => setState(() => _zonasEvitar = r.zonasDolor),
      ));
    }
    if (r.energia <= 2) {
      sugerencias.add(_SugerenciaAdaptacion(
        icon: Icons.battery_0_bar_rounded,
        titulo: 'Reducir intensidad general',
        descripcion: 'Hoy es día de mantener.',
        aplicar: () => setState(() => _seriesReducidas = true),
      ));
    }
    if (sugerencias.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => _AdaptacionDialog(sugerencias: sugerencias),
    );
  }

  Widget _btn(String label, Color c, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, color: c, fontWeight: FontWeight.w600))));
}

// =============================================================================
// Overlay de check-in embebido
// =============================================================================

class _CheckInOverlay extends ConsumerStatefulWidget {
  const _CheckInOverlay({required this.onGuardado, required this.onOmitir});
  final void Function(_CheckInResult) onGuardado;
  final VoidCallback onOmitir;
  @override
  ConsumerState<_CheckInOverlay> createState() => _CheckInOverlayState();
}

class _CheckInOverlayState extends ConsumerState<_CheckInOverlay> {
  int _sueno = 3, _estres = 3, _energia = 3, _dolor = 1;
  final _zonas = <String>{};

  Future<void> _guardar() async {
    final r = _CheckInResult(
      sueno: _sueno,
      estres: _estres,
      energia: _energia,
      dolor: _dolor,
      zonasDolor: _zonas.toList(),
    );
    await guardarEstadoDiario(
      calidadSueno: _sueno,
      nivelEstres: _estres,
      nivelEnergia: _energia,
      dolorMuscular: _dolor,
      zonasDolor: _zonas.toList(),
      listoParaEntrenar: _sueno > 1 || _energia > 2,
      ref: ref,
    );
    if (mounted) widget.onGuardado(r);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Como te sientes hoy?",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                    "Tus respuestas adaptan el entrenamiento y mejoran las recomendaciones futuras.",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                _s("Calidad del sueno", _sueno, (v) => _sueno = v,
                    const ["Muy mal", "Mal", "Regular", "Bien", "Excelente"]),
                _s("Nivel de estres", _estres, (v) => _estres = v,
                    const ["Muy bajo", "Bajo", "Moderado", "Alto", "Muy alto"]),
                _s("Nivel de energia", _energia, (v) => _energia = v,
                    const ["Agotado", "Bajo", "Normal", "Alto", "Pleno"]),
                _s("Dolor / Agujetas", _dolor, (v) => _dolor = v,
                    const ["Ninguno", "Leve", "Moderado", "Fuerte", "Intenso"]),
                if (_dolor >= 3) ...[
                  const SizedBox(height: 12),
                  const Text("Donde sientes dolor?",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        "piernas",
                        "espalda",
                        "hombros",
                        "brazos",
                        "pecho",
                        "core",
                      ]
                          .map((z) => FilterChip(
                                label: Text(z[0].toUpperCase() + z.substring(1),
                                    style: const TextStyle(fontSize: 11)),
                                selected: _zonas.contains(z),
                                onSelected: (v) => setState(() {
                                  v ? _zonas.add(z) : _zonas.remove(z);
                                }),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList()),
                ],
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: widget.onOmitir, child: const Text("Omitir")),
                  const SizedBox(width: 8),
                  FilledButton(
                      onPressed: _guardar, child: const Text("Guardar")),
                ]),
              ]),
        ),
      ),
    );
  }

  Widget _s(
      String label, int v, void Function(int) onChange, List<String> labels) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(labels[v - 1],
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
      Slider(
          value: v.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: labels[v - 1],
          onChanged: (val) => setState(() => onChange(val.round()))),
    ]);
  }
}

// =============================================================================
// Sugerencia de adaptación
// =============================================================================

class _SugerenciaAdaptacion {
  const _SugerenciaAdaptacion(
      {required this.icon,
      required this.titulo,
      required this.descripcion,
      required this.aplicar});
  final IconData icon;
  final String titulo;
  final String descripcion;
  final VoidCallback aplicar;
}

class _AdaptacionDialog extends StatefulWidget {
  const _AdaptacionDialog({required this.sugerencias});
  final List<_SugerenciaAdaptacion> sugerencias;
  @override
  State<_AdaptacionDialog> createState() => _AdaptacionDialogState();
}

class _AdaptacionDialogState extends State<_AdaptacionDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.auto_awesome, size: 22, color: Color(0xFF006E2D)),
        SizedBox(width: 8),
        Expanded(child: Text('SynaptixFit AI')),
      ]),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basado en cómo te sientes, te sugiero:',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            ...widget.sugerencias.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(s.icon,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(s.titulo,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(s.descripcion,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600)),
                              ])),
                        ]),
                  ),
                )),
          ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ignorar')),
        FilledButton(
            onPressed: () {
              for (final s in widget.sugerencias) {
                s.aplicar();
              }
              Navigator.pop(context);
            },
            child: const Text('Aplicar')),
      ],
    );
  }
}

// =============================================================================

class _SerieLocal {
  const _SerieLocal({this.completada = false, this.pesoKg, this.reps});
  final bool completada;
  final double? pesoKg;
  final int? reps;
}

class _FinalizacionResult {
  const _FinalizacionResult(this.rpe, this.guardarCambios);
  final int rpe;
  final bool guardarCambios;
}

class _EjerciciosList extends ConsumerWidget {
  const _EjerciciosList(
      {required this.diaId,
      required this.seriesLocales,
      required this.pesoCtrl,
      required this.repsCtrl,
      required this.seriesReducidas,
      required this.zonasEvitar,
      required this.descansoActivoEjercicioId,
      required this.descansoActivoSerie,
      required this.descansoRestante,
      required this.onMarcarSerie,
      required this.onSaltarDescanso,
      required this.onAjustarDescanso});
  final String diaId;
  final Map<String, Map<int, _SerieLocal>> seriesLocales;
  final Map<String, TextEditingController> pesoCtrl, repsCtrl;
  final bool seriesReducidas;
  final List<String> zonasEvitar;
  final String? descansoActivoEjercicioId;
  final int? descansoActivoSerie;
  final int descansoRestante;
  final void Function(String, int, bool) onMarcarSerie;
  final VoidCallback onSaltarDescanso;
  final void Function(int) onAjustarDescanso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ejerciciosDeDiaProvider(diaId));
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(fontSize: 13))),
      data: (ejercicios) => ejercicios.isEmpty
          ? const Center(
              child:
                  Text('Sin ejercicios', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: ejercicios.length,
              itemBuilder: (ctx, i) => _EjercicioLiveCard(
                  key: ValueKey(ejercicios[i].id),
                  ejercicio: ejercicios[i],
                  seriesLocales: seriesLocales,
                  pesoCtrl: pesoCtrl,
                  repsCtrl: repsCtrl,
                  seriesReducidas: seriesReducidas,
                  zonasEvitar: zonasEvitar,
                  descansoActivoEjercicioId: descansoActivoEjercicioId,
                  descansoActivoSerie: descansoActivoSerie,
                  descansoRestante: descansoRestante,
                  onMarcarSerie: onMarcarSerie,
                  onSaltarDescanso: onSaltarDescanso,
                  onAjustarDescanso: onAjustarDescanso)),
    );
  }
}

class _EjercicioLiveCard extends StatelessWidget {
  const _EjercicioLiveCard(
      {required this.ejercicio,
      required this.seriesLocales,
      required this.pesoCtrl,
      required this.repsCtrl,
      required this.seriesReducidas,
      required this.zonasEvitar,
      required this.descansoActivoEjercicioId,
      required this.descansoActivoSerie,
      required this.descansoRestante,
      required this.onMarcarSerie,
      required this.onSaltarDescanso,
      required this.onAjustarDescanso,
      super.key});
  final dynamic ejercicio;
  final Map<String, Map<int, _SerieLocal>> seriesLocales;
  final Map<String, TextEditingController> pesoCtrl, repsCtrl;
  final bool seriesReducidas;
  final List<String> zonasEvitar;
  final String? descansoActivoEjercicioId;
  final int? descansoActivoSerie;
  final int descansoRestante;
  final void Function(String, int, bool) onMarcarSerie;
  final VoidCallback onSaltarDescanso;
  final void Function(int) onAjustarDescanso;

  static const _mapZonasAMusculos = {
    'piernas': [
      'Cuádriceps',
      'Isquiotibiales',
      'Glúteo mayor',
      'Glúteo medio',
      'Aductores',
      'Abductores',
      'Gemelos',
      'Sóleo',
      'Tibial anterior'
    ],
    'espalda': [
      'Dorsal ancho',
      'Romboides',
      'Trapecio superior',
      'Trapecio medio',
      'Trapecio inferior',
      'Erectores espinales'
    ],
    'hombros': ['Deltoides anterior', 'Deltoides medio', 'Deltoides posterior'],
    'brazos': [
      'Bíceps braquial',
      'Tríceps braquial',
      'Braquial',
      'Braquiorradial'
    ],
    'pecho': ['Pectoral mayor', 'Pectoral menor', 'Serrato anterior'],
    'core': ['Recto abdominal', 'Oblicuos', 'Transverso abdominal'],
  };

  bool _enZonaDolor(EjercicioDb? ej) {
    if (ej == null || zonasEvitar.isEmpty) return false;
    final musculosEvitar = <String>{};
    for (final zona in zonasEvitar) {
      final mapped = _mapZonasAMusculos[zona.toLowerCase().trim()];
      if (mapped != null) {
        musculosEvitar.addAll(mapped.map((m) => m.toLowerCase()));
      }
    }
    final musculosEj = ej.musculosObjetivo.map((m) => m.toLowerCase()).toSet();
    return musculosEj.intersection(musculosEvitar).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = ejercicio as SeleccionEjercicioDb;
    final enDescanso = descansoActivoEjercicioId == e.id;
    final seriesEfectivas =
        seriesReducidas ? (e.series - 1).clamp(1, 99) : e.series;
    return Consumer(builder: (context, ref, _) {
      final ejercicioAsync = ref.watch(ejercicioDetalleProvider(e.ejercicioId));
      final ej = ejercicioAsync.valueOrNull;
      final nombre = ej?.nombre ?? 'Ejercicio';
      final modalidad = ej?.modalidadEntrenamiento ?? '';
      final esCircuito = ej?.esCircuito ?? false;
      final finalidad = ej?.finalidadPrincipal ?? '';
      final enZonaDolor = _enZonaDolor(ej);
      final finL = finalidad.toLowerCase();
      final esCardio = esCircuito ||
          finL.contains('cardio') ||
          finL.contains('acondicionamiento');
      final esIso = !esCardio &&
          (finL.contains('isometric') ||
              finL.contains('movilidad') ||
              finL.contains('flexibilidad') ||
              finL.contains('estabilidad'));
      final esFuerza = !esCardio && !esIso;
      if (ej == null && ejercicioAsync.isLoading) {
        return _skeletonCard(theme);
      }
      final seriesCompletadas = List.generate(
        seriesEfectivas,
        (i) => seriesLocales[e.id]?[i + 1]?.completada ?? false,
      ).where((c) => c).length;
      final ejercicioCompletado =
          seriesEfectivas > 0 && seriesCompletadas == seriesEfectivas;
      return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          color:
              ejercicioCompletado ? Colors.green.withValues(alpha: 0.04) : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: ejercicioCompletado
                      ? Colors.green.withValues(alpha: 0.45)
                      : enZonaDolor
                          ? Colors.amber.withValues(alpha: 0.5)
                          : enDescanso || seriesReducidas
                              ? Colors.orange.withValues(alpha: 0.3)
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3))),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => context
                            .push('/bienestar/ejercicio/${e.ejercicioId}'),
                        child: ExerciseThumb(
                            urlGif: ej?.urlGif, urlPreview: ej?.urlPreview),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.push(
                                      '/bienestar/ejercicio/${e.ejercicioId}'),
                                  child: Text(nombre,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: theme
                                                  .colorScheme.primary
                                                  .withValues(alpha: 0.3))),
                                ),
                              ),
                              if (enZonaDolor)
                                Tooltip(
                                  message:
                                      'Ejercicio en zona de dolor reportada hoy',
                                  child: Icon(Icons.warning_amber_rounded,
                                      size: 18, color: Colors.amber.shade700),
                                ),
                            ]),
                            if (modalidad.isNotEmpty || esCircuito)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child:
                                    Wrap(spacing: 6, runSpacing: 4, children: [
                                  if (modalidad.isNotEmpty)
                                    _TipoPill(
                                        texto: modalidad,
                                        color: theme.colorScheme.primary),
                                  if (esCircuito)
                                    _TipoPill(
                                        texto: 'Circuito',
                                        color: theme.colorScheme.tertiary),
                                ]),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: ExerciseMetricsRow(
                                      categoria: esFuerza
                                          ? ExerciseMetricCategoria.fuerza
                                          : esCardio
                                              ? ExerciseMetricCategoria.aerobico
                                              : ExerciseMetricCategoria
                                                  .isometrico,
                                      color: seriesReducidas
                                          ? Colors.orange.shade700
                                          : null,
                                      series: seriesEfectivas,
                                      repeticiones: e.repeticiones,
                                      pesoKg: e.pesoKg,
                                      pesosKg: e.pesosKg,
                                      segundosDescanso: e.segundosDescanso,
                                    ),
                                  ),
                                  if (seriesReducidas) ...[
                                    const SizedBox(width: 6),
                                    Text('(adaptado)',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700)),
                                  ],
                                ],
                              ),
                            ),
                            if ((e.tiempoIsometricoSegundos ?? 0) > 0 ||
                                (e.duracionObjetivoSegundos ?? 0) > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if ((e.tiempoIsometricoSegundos ?? 0) > 0)
                                      SemanticMicroChip(
                                        icon: Icons.timer,
                                        label: '${e.tiempoIsometricoSegundos}s',
                                        dense: true,
                                      ),
                                    if ((e.duracionObjetivoSegundos ?? 0) > 0)
                                      buildCalorieChip(
                                        valorMet: ej?.valorMet,
                                        pesoUsuarioKg: ref
                                            .watch(perfilUsuarioProvider)
                                            .valueOrNull
                                            ?.perfil
                                            .pesoKg,
                                        duracionSegundos:
                                            e.duracionObjetivoSegundos,
                                        modalidad: ej?.modalidadEntrenamiento ??
                                            'fuerza',
                                        esCircuito: ej?.esCircuito ?? false,
                                        dense: true,
                                      ),
                                  ],
                                ),
                              ),
                          ])),
                      if (ejercicioCompletado) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle,
                                size: 14, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text('Completado',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700)),
                          ]),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 10),
                    if (esFuerza)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          const SizedBox(width: 104),
                          SizedBox(
                            width: 74,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fitness_center,
                                      size: 12,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Text('Peso',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                          SizedBox(
                            width: 78,
                            child: Center(
                              child: Text('Reps',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ),
                          ),
                        ]),
                      ),
                    ...List.generate(seriesEfectivas, (i) {
                      final numSerie = i + 1;
                      final local = seriesLocales[e.id]?[numSerie];
                      final completada = local?.completada ?? false;
                      final esDescanso =
                          enDescanso && descansoActivoSerie == numSerie;
                      final k = '${e.id}_$numSerie';
                      pesoCtrl.putIfAbsent(k, () {
                        final pesoInicial = (e.pesosKg != null &&
                                i < e.pesosKg!.length &&
                                e.pesosKg![i] > 0)
                            ? e.pesosKg![i]
                            : e.pesoKg;
                        return TextEditingController(
                            text: pesoInicial != null && pesoInicial > 0
                                ? pesoInicial.toStringAsFixed(
                                    pesoInicial == pesoInicial.roundToDouble()
                                        ? 0
                                        : 1)
                                : '');
                      });
                      repsCtrl.putIfAbsent(
                          k,
                          () =>
                              TextEditingController(text: '${e.repeticiones}'));
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            SizedBox(
                                width: 32,
                                child: esDescanso
                                    ? Column(children: [
                                        Text('${descansoRestante}s',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.orange.shade700)),
                                        const Text('⏳',
                                            style: TextStyle(fontSize: 12))
                                      ])
                                    : InkWell(
                                        onTap: () => onMarcarSerie(
                                            e.id, numSerie, !completada),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Icon(
                                            completada
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            size: 22,
                                            color: completada
                                                ? Colors.green
                                                : Colors.grey.shade400))),
                            const SizedBox(width: 8),
                            SizedBox(
                                width: 56,
                                child: Text(
                                    esCardio
                                        ? 'Ronda $numSerie'
                                        : 'Serie $numSerie',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600))),
                            const SizedBox(width: 8),
                            if (esFuerza) ...[
                              _InputMetrica(
                                  controller: pesoCtrl[k]!,
                                  suffixText: 'kg',
                                  width: 74),
                              const SizedBox(width: 8),
                              SizedBox(
                                  width: 12,
                                  child: Center(
                                      child: Text('×',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant)))),
                              const SizedBox(width: 8),
                              _InputMetrica(
                                  controller: repsCtrl[k]!,
                                  suffixText: 'reps',
                                  width: 78),
                            ] else if (esCardio) ...[
                              if ((e.duracionObjetivoSegundos ?? 0) > 0)
                                SemanticMicroChip(
                                    icon: Icons.timer_outlined,
                                    label:
                                        _fmtDurLive(e.duracionObjetivoSegundos),
                                    dense: true),
                              if ((e.distanciaMetros ?? 0) > 0) ...[
                                const SizedBox(width: 6),
                                SemanticMicroChip(
                                    icon: Icons.route,
                                    label: e.distanciaMetros! >= 1000
                                        ? '${(e.distanciaMetros! / 1000).toStringAsFixed(1)} km'
                                        : '${e.distanciaMetros} m',
                                    dense: true),
                              ],
                            ] else ...[
                              if ((e.tiempoIsometricoSegundos ?? 0) > 0)
                                SemanticMicroChip(
                                    icon: Icons.timer,
                                    label: '${e.tiempoIsometricoSegundos}s',
                                    dense: true),
                            ],
                          ]));
                    }),
                    if (enDescanso) ...[
                      const SizedBox(height: 4),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _btn2('-15s', Colors.orange,
                                () => onAjustarDescanso(-15)),
                            const SizedBox(width: 6),
                            _btn2('Saltar', Colors.red, onSaltarDescanso),
                            const SizedBox(width: 6),
                            _btn2('+15s', Colors.orange,
                                () => onAjustarDescanso(15))
                          ])
                    ],
                  ])));
    });
  }

  Widget _skeletonCard(ThemeData theme) {
    final base =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    Widget box(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          box(48, 48),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(150, 14),
                const SizedBox(height: 8),
                box(90, 10),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtDurLive(int? secs) {
    final s = secs ?? 0;
    final m = s ~/ 60;
    final r = s % 60;
    return m > 0 ? '${m}m ${r}s' : '${r}s';
  }

  Widget _btn2(String label, Color c, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, color: c, fontWeight: FontWeight.w600))));
}

// =============================================================================
// Helper widgets
// =============================================================================

class _TipoPill extends StatelessWidget {
  const _TipoPill({required this.texto, required this.color});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _InputMetrica extends StatelessWidget {
  const _InputMetrica({
    required this.controller,
    required this.suffixText,
    this.width,
  });
  final TextEditingController controller;
  final String suffixText;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width ?? 72,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Check-in diario
// =============================================================================

class _CheckInResult {
  const _CheckInResult({
    required this.sueno,
    required this.estres,
    required this.energia,
    required this.dolor,
    required this.zonasDolor,
  });
  final int sueno, estres, energia, dolor;
  final List<String> zonasDolor;
}
