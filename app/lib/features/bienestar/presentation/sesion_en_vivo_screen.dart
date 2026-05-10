import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../core/design_system/sv_colors.dart';
import '../application/rutina_provider.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({super.key});
  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  late final String _diaId;
  late final String _semanaId;
  late final String _rutinaId;

  Timer? _cronometro;
  int _segundosTotales = 0;

  Timer? _descansoTimer;
  int _descansoRestante = 0;
  String? _descansoActivoEjercicioId;
  int? _descansoActivoSerie;

  final Map<String, Map<int, _SerieLocal>> _seriesLocales = {};
  final Map<String, TextEditingController> _pesoCtrl = {};
  final Map<String, TextEditingController> _repsCtrl = {};

  String? _sesionId;
  bool _sesionIniciada = false;
  bool _finalizando = false;

  @override
  void initState() => super.initState();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null) {
      _diaId = extra['diaId'] as String;
      _semanaId = extra['semanaId'] as String;
      _rutinaId = extra['rutinaId'] as String;
    }
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    _descansoTimer?.cancel();
    for (final c in _pesoCtrl.values) c.dispose();
    for (final c in _repsCtrl.values) c.dispose();
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
                      child: Text('${_formatoTiempo(_segundosTotales)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700))),
                  const SizedBox(height: 16),
                  Text('RPE: $selectedRpe',
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
      await finalizarSesion(
          sesionId: _sesionId!,
          diaId: _diaId,
          duracionSegundos: _segundosTotales,
          rpe: result.rpe,
          ref: ref);
      if (mounted) context.go('/bienestar/rutina/$_rutinaId');
    }
  }

  String _formatoTiempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0)
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_sesionIniciada) {
      return FeatureScaffold(
          title: 'Entrenamiento',
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
        title: '',
        backPath: '/bienestar',
        child: Column(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: theme.colorScheme.surfaceContainerLowest,
              child: Row(children: [
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
              ])),
          Expanded(
              child: _EjerciciosList(
                  diaId: _diaId,
                  seriesLocales: _seriesLocales,
                  pesoCtrl: _pesoCtrl,
                  repsCtrl: _repsCtrl,
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
                            backgroundColor: Colors.red.shade700),
                        child: _finalizando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('🛑 Finalizar entrenamiento',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      )))),
        ]));
  }

  Widget _btn(String label, Color c, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, color: c, fontWeight: FontWeight.w600))));
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
      required this.descansoActivoEjercicioId,
      required this.descansoActivoSerie,
      required this.descansoRestante,
      required this.onMarcarSerie,
      required this.onSaltarDescanso,
      required this.onAjustarDescanso});
  final String diaId;
  final Map<String, Map<int, _SerieLocal>> seriesLocales;
  final Map<String, TextEditingController> pesoCtrl, repsCtrl;
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
  final String? descansoActivoEjercicioId;
  final int? descansoActivoSerie;
  final int descansoRestante;
  final void Function(String, int, bool) onMarcarSerie;
  final VoidCallback onSaltarDescanso;
  final void Function(int) onAjustarDescanso;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = ejercicio as dynamic;
    final enDescanso = descansoActivoEjercicioId == e.id;
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('ejercicios')
          .select('nombre')
          .eq('id', e.ejercicioId)
          .maybeSingle(),
      builder: (ctx, snap) {
        final nombre = snap.data?['nombre'] as String? ?? 'Ejercicio';
        return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: enDescanso
                        ? Colors.orange.withValues(alpha: 0.3)
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3))),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(nombre,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700))),
                        Text(
                            '${e.series}×${e.repeticiones} · ${e.segundosDescanso}s',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: SVColors.onSurfaceMuted))
                      ]),
                      const SizedBox(height: 10),
                      ...List.generate(e.series as int, (i) {
                        final numSerie = i + 1;
                        final local = seriesLocales[e.id]?[numSerie];
                        final completada = local?.completada ?? false;
                        final esDescanso =
                            enDescanso && descansoActivoSerie == numSerie;
                        final k = '${e.id}_$numSerie';
                        pesoCtrl.putIfAbsent(
                            k,
                            () => TextEditingController(
                                text: '${(e as dynamic).pesoKg ?? ''}'));
                        repsCtrl.putIfAbsent(
                            k,
                            () => TextEditingController(
                                text: '${e.repeticiones}'));
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
                                                  color:
                                                      Colors.orange.shade700)),
                                          Text('⏳',
                                              style: TextStyle(fontSize: 12))
                                        ])
                                      : InkWell(
                                          onTap: () => onMarcarSerie(
                                              e.id, numSerie, !completada),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Icon(
                                              completada
                                                  ? Icons.check_circle
                                                  : Icons
                                                      .radio_button_unchecked,
                                              size: 22,
                                              color: completada
                                                  ? Colors.green
                                                  : Colors.grey.shade400))),
                              const SizedBox(width: 8),
                              Text('S$numSerie',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              SizedBox(
                                  width: 52,
                                  child: TextField(
                                      controller: pesoCtrl[k],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11),
                                      decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 6),
                                          border: OutlineInputBorder(),
                                          hintText: 'kg'))),
                              const SizedBox(width: 4),
                              const Text('kg',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                              const SizedBox(width: 8),
                              const Text('×',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              const SizedBox(width: 8),
                              SizedBox(
                                  width: 40,
                                  child: TextField(
                                      controller: repsCtrl[k],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11),
                                      decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 6),
                                          border: const OutlineInputBorder(),
                                          hintText: '${e.repeticiones}'))),
                              const SizedBox(width: 4),
                              Text('reps',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
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
      },
    );
  }

  Widget _btn2(String label, Color c, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, color: c, fontWeight: FontWeight.w600))));
}
