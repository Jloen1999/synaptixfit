import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/exercise_media_widget.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../application/ejercicios_provider.dart';
import '../application/rutina_provider.dart';
import '../infrastructure/recomendacion_ia_service.dart';
import '../infrastructure/parametros_objetivo.dart';
import 'seleccion_ejercicios_screen.dart';

// DTO local para el plan de ejercicios durante la creación
class _EjercicioPlan {
  const _EjercicioPlan({
    required this.ejercicioId,
    required this.nombre,
    required this.finalidad,
    this.urlGif,
    this.urlPreview,
    this.modalidadEntrenamiento = 'fuerza',
    this.tipoMedicion = const ['repeticiones'],
    this.esCircuito = false,
    this.series = 3,
    this.repeticiones = 10,
    this.segundosDescanso = 90,
    this.pesoKg,
    this.pesosKg,
    this.mismoPeso = true,
    this.duracionSegundos,
    this.distanciaMetros,
    this.tiempoIsometricoSegundos,
  });

  final String ejercicioId;
  final String nombre;
  final String finalidad;
  final String? urlGif;
  final String? urlPreview;
  final String modalidadEntrenamiento;
  final List<String> tipoMedicion;
  final bool esCircuito;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final double? pesoKg;
  final List<double>? pesosKg;
  final bool mismoPeso;
  final int? duracionSegundos;
  final int? distanciaMetros;
  final int? tiempoIsometricoSegundos;

  _EjercicioPlan copyWith({
    int? series,
    int? repeticiones,
    int? segundosDescanso,
    double? pesoKg,
    List<double>? pesosKg,
    bool? mismoPeso,
    int? duracionSegundos,
    int? distanciaMetros,
    int? tiempoIsometricoSegundos,
  }) {
    return _EjercicioPlan(
      ejercicioId: ejercicioId,
      nombre: nombre,
      finalidad: finalidad,
      urlGif: urlGif,
      urlPreview: urlPreview,
      modalidadEntrenamiento: modalidadEntrenamiento,
      tipoMedicion: tipoMedicion,
      esCircuito: esCircuito,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      segundosDescanso: segundosDescanso ?? this.segundosDescanso,
      pesoKg: pesoKg ?? this.pesoKg,
      pesosKg: pesosKg ?? this.pesosKg,
      mismoPeso: mismoPeso ?? this.mismoPeso,
      duracionSegundos: duracionSegundos ?? this.duracionSegundos,
      distanciaMetros: distanciaMetros ?? this.distanciaMetros,
      tiempoIsometricoSegundos:
          tiempoIsometricoSegundos ?? this.tiempoIsometricoSegundos,
    );
  }

  EjercicioInput toInput() {
    return EjercicioInput(
      ejercicioId: ejercicioId,
      series: series,
      repeticiones: repeticiones,
      segundosDescanso: segundosDescanso,
      pesoKg: pesoKg,
      pesosKg: mismoPeso ? null : pesosKg,
      duracionSegundos: duracionSegundos,
      distanciaMetros: distanciaMetros,
      tiempoIsometricoSegundos: tiempoIsometricoSegundos,
    );
  }
}

class NuevaRutinaScreen extends ConsumerStatefulWidget {
  const NuevaRutinaScreen({this.autoRecomendar = false, super.key});

  final bool autoRecomendar;

  @override
  ConsumerState<NuevaRutinaScreen> createState() => _NuevaRutinaScreenState();
}

class _NuevaRutinaScreenState extends ConsumerState<NuevaRutinaScreen> {
  int _paso = 0;
  bool _creando = false;
  bool _loadingIA = false;
  String _tipoCarga = '';
  bool _rutinaRecomendada = false;
  bool _iaRefinada = false;
  String? _motivoAjustes;
  final bool _ejerciciosRecomendados = false;
  Timer? _timerMensajes;
  String _mensajeCarga = '';

  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _visibilidad = 'private';
  String _objetivo = 'Hipertrofia Muscular';
  int _duracionSemanas = 4;
  int _diasPorSemana = 3;

  int _semanaActiva = 0;
  final Map<int, Map<int, List<_EjercicioPlan>>> _estructura = {};

  @override
  void initState() {
    super.initState();
    _inicializarEstructura();
    _cargarObjetivoPerfil();
    if (widget.autoRecomendar) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recomendarRutina());
    }
  }

  Future<void> _cargarObjetivoPerfil() async {
    final perfil = await ref.read(perfilBienestarProvider.future);
    if (perfil != null && mounted) {
      final v = sanitizarObjetivo(perfil.objetivoPrincipal);
      setState(() => _objetivo = v);
    }
  }

  void _inicializarEstructura() {
    _estructura.clear();
    for (var s = 1; s <= _duracionSemanas; s++) {
      _estructura[s] = {};
      for (var d = 1; d <= _diasPorSemana; d++) {
        _estructura[s]![d] = [];
      }
    }
  }

  void _syncEstructura() {
    _estructura.removeWhere((s, _) => s > _duracionSemanas);
    for (var s = 1; s <= _duracionSemanas; s++) {
      _estructura.putIfAbsent(s, () => {});
    }
    for (final s in _estructura.keys.toList()) {
      final dias = _estructura[s]!;
      dias.removeWhere((d, _) => d > _diasPorSemana);
      for (var d = 1; d <= _diasPorSemana; d++) {
        dias.putIfAbsent(d, () => []);
      }
    }
  }

  @override
  void dispose() {
    _timerMensajes?.cancel();
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  static const _mensajesRutina = [
    'Analizando tu perfil físico...',
    'Consultando tu historial de entrenamiento...',
    'Revisando tu estado diario...',
    'Procesando catálogo de ejercicios...',
    'Aplicando reglas de periodización...',
    'Personalizando según tu objetivo...',
    'Estructurando semanas y días...',
    '¡Casi listo! Ajustando detalles finales...',
  ];

  static const _mensajesEjercicios = [
    'Analizando estructura de la rutina...',
    'Evaluando periodización por semana...',
    'Distribuyendo grupos musculares...',
    'Seleccionando ejercicios compatibles...',
    'Ajustando volumen e intensidad...',
    'Organizando días de entrenamiento...',
    'Verificando progresión de cargas...',
    '¡Casi listo! Últimos ajustes...',
  ];

  static const _mensajesSugerir = [
    'Analizando ejercicios del día...',
    'Identificando grupos musculares trabajados...',
    'Buscando ejercicios complementarios...',
    'Seleccionando según tu equipamiento...',
    'Ajustando series y repeticiones...',
    'Optimizando tiempos de descanso...',
    'Verificando balance muscular...',
    '¡Casi listo! Últimos ajustes...',
  ];

  void _iniciarSecuenciaMensajes() {
    _timerMensajes?.cancel();
    final mensajes = _tipoCarga == 'ejercicios'
        ? _mensajesEjercicios
        : _tipoCarga == 'sugerir'
            ? _mensajesSugerir
            : _mensajesRutina;
    _mensajeCarga = mensajes.first;
    int i = 0;
    _timerMensajes = Timer.periodic(const Duration(milliseconds: 1800), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      i++;
      if (i < mensajes.length) {
        setState(() => _mensajeCarga = mensajes[i]);
      }
    });
  }

  void _detenerMensajesCarga() {
    _timerMensajes?.cancel();
    _timerMensajes = null;
  }

  void _terminarCargaIA() {
    _detenerMensajesCarga();
    setState(() {
      _loadingIA = false;
      _tipoCarga = '';
    });
  }

  void _cancelarCargaIA() {
    _detenerMensajesCarga();
    setState(() {
      _loadingIA = false;
      _tipoCarga = '';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Recomendación cancelada.'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  String fmtDuracion(int segundos) {
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    if (min > 0 && sec > 0) return '${min}m ${sec}s';
    if (min > 0) return '$min min';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: _paso >= 1 && _nombreCtrl.text.trim().isNotEmpty
          ? _nombreCtrl.text.trim()
          : 'Nueva rutina',
      backPath: '/bienestar',
      onBack: () {
        if (_paso > 0) {
          setState(() => _paso--);
        } else {
          context.go('/bienestar');
        }
      },
      child: _paso == 0
          ? _buildPaso1()
          : _paso == 1
              ? _buildPaso2()
              : _buildPaso3(),
    );
  }

  Widget _buildPantallaGeneracion(ThemeData theme) {
    final esEjercicios = _tipoCarga == 'ejercicios';
    final iconWidget = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006E2D), Color(0xFF00C853)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2D).withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 40, color: Colors.white),
          Positioned(
            top: 18,
            right: 18,
            child: Icon(Icons.auto_awesome, size: 14, color: Colors.white70),
          ),
        ],
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1.08),
              duration: const Duration(milliseconds: 1200),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: iconWidget,
              onEnd: () {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 48),
            Text(
              'SynaptixFit AI',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              esEjercicios
                  ? 'Generando estructura de ejercicios'
                  : 'Generando tu rutina personalizada',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 4,
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  color: const Color(0xFF00C853),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_mensajeCarga),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _mensajeCarga,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            TextButton.icon(
              onPressed: _cancelarCargaIA,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPantallaGeneracionEjerciciosDia(ThemeData theme) {
    final iconWidget = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 28,
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, size: 36, color: Colors.white),
          Positioned(
            bottom: 14,
            right: 14,
            child: Icon(Icons.auto_awesome, size: 12, color: Colors.white70),
          ),
        ],
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.93, end: 1.07),
              duration: const Duration(milliseconds: 900),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: iconWidget,
              onEnd: () {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 40),
            Text(
              'SynaptixFit AI',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sugiriendo ejercicios para tu día',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today_rounded, size: 14, color: Color(0xFF7C3AED)),
                  SizedBox(width: 6),
                  Text(
                    'Personalizando ejercicios',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 4,
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor:
                      const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_mensajeCarga),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _mensajeCarga,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            TextButton.icon(
              onPressed: _cancelarCargaIA,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaso1() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loadingIA) {
      return _buildPantallaGeneracion(theme);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.fitness_center_rounded, size: 48, color: cs.primary),
        const SizedBox(height: 8),
        Text('Paso 1 — Define tu rutina',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Nombre, objetivo y duración',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Nombre y descripción',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: !widget.autoRecomendar,
                  decoration: const InputDecoration(
                      labelText: 'Nombre *', hintText: 'ej: Rutina de fuerza'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      alignLabelWithHint: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_fixed_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Objetivo',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 400 ? 3 : 2;
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: finalidadesEstandar
                          .map((f) => SizedBox(
                                width: (constraints.maxWidth - (cols - 1) * 6) /
                                    cols,
                                child: ChoiceChip(
                                  avatar: Icon(
                                    iconoFinalidad(f),
                                    size: 14,
                                    color: _objetivo == f
                                        ? cs.onSecondaryContainer
                                        : cs.onSurfaceVariant,
                                  ),
                                  label: Text(f,
                                      style: const TextStyle(fontSize: 12)),
                                  selected: _objetivo == f,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) =>
                                      setState(() => _objetivo = f),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Visibilidad',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'private',
                        icon: Icon(Icons.lock_outline, size: 16),
                        label: Text('Privada')),
                    ButtonSegment(
                        value: 'friends',
                        icon: Icon(Icons.people_outline, size: 16),
                        label: Text('Amigos')),
                    ButtonSegment(
                        value: 'public',
                        icon: Icon(Icons.public_outlined, size: 16),
                        label: Text('Pública')),
                  ],
                  selected: {_visibilidad},
                  onSelectionChanged: (v) =>
                      setState(() => _visibilidad = v.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Duración',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStepper(
                  label: 'Semanas',
                  value: _duracionSemanas,
                  min: 1,
                  max: 12,
                  suffix: 'semanas',
                  onChanged: (v) => setState(() => _duracionSemanas = v),
                  cs: cs,
                ),
                const SizedBox(height: 8),
                _buildStepper(
                  label: 'Días por semana',
                  value: _diasPorSemana,
                  min: 1,
                  max: 7,
                  suffix: 'días',
                  onChanged: (v) => setState(() => _diasPorSemana = v),
                  cs: cs,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _loadingIA ? null : _recomendarRutina,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text(_rutinaRecomendada ? 'Cambiar rutina' : 'Generar rutina'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            if (_nombreCtrl.text.trim().length < 3) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('El nombre debe tener al menos 3 caracteres')));
              return;
            }
            _syncEstructura();
            setState(() => _paso = 1);
          },
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Siguiente — Añadir ejercicios'),
        ),
      ],
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required void Function(int) onChanged,
    required ColorScheme cs,
  }) {
    final canDown = value > min;
    final canUp = value < max;
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            onPressed: canDown ? () => onChanged(value - 1) : null,
            icon: Icon(Icons.remove_rounded,
                size: 20, color: canDown ? cs.primary : cs.outlineVariant),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$value $suffix',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            onPressed: canUp ? () => onChanged(value + 1) : null,
            icon: Icon(Icons.add_rounded,
                size: 20, color: canUp ? cs.primary : cs.outlineVariant),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildPaso2() {
    if (_loadingIA) {
      return _buildPantallaGeneracionEjerciciosDia(Theme.of(context));
    }

    final semanas = _estructura.keys.toList()..sort();
    if (semanas.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Sin semanas', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
              onPressed: () => _agregarSemana(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Añadir semana')),
        ]),
      );
    }
    if (_semanaActiva >= semanas.length) _semanaActiva = semanas.length - 1;
    final semanaActual = semanas[_semanaActiva];
    final diasDeSemana = (_estructura[semanaActual]?.keys.toList() ?? [])
      ..sort();

    return Column(
      children: [
        if (_rutinaRecomendada) ...[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Chip(
              avatar: Icon(
                _iaRefinada ? Icons.auto_awesome : Icons.bolt_rounded,
                size: 16,
                color:
                    _iaRefinada ? Colors.blue.shade700 : Colors.orange.shade700,
              ),
              label: Text(
                _iaRefinada ? 'IA' : 'Reglas',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _iaRefinada
                      ? Colors.blue.shade700
                      : Colors.orange.shade700,
                ),
              ),
              backgroundColor:
                  _iaRefinada ? Colors.blue.shade50 : Colors.orange.shade50,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            if (_motivoAjustes != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: _motivoAjustes!,
                child: Chip(
                  avatar: Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.amber.shade800),
                  label: Text('Adaptado',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade800)),
                  backgroundColor: Colors.amber.shade50,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
        ],
        // Selector de semanas con botón eliminar y añadir
        SizedBox(
          height: 44,
          child: Row(children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: semanas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, i) {
                  final s = semanas[i];
                  final totalEj = _estructura[s]
                          ?.values
                          .fold<int>(0, (t, ej) => t + ej.length) ??
                      0;
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    ChoiceChip(
                      label: Text('Sem $s ($totalEj)',
                          style: const TextStyle(fontSize: 12)),
                      selected: _semanaActiva == i,
                      onSelected: (_) => setState(() => _semanaActiva = i),
                    ),
                    if (semanas.length > 1)
                      InkWell(
                        onTap: () => _eliminarSemana(s),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                            padding: EdgeInsets.all(2),
                            child:
                                Icon(Icons.close, size: 14, color: Colors.red)),
                      ),
                  ]);
                },
              ),
            ),
            InkWell(
              onTap: _agregarSemana,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.add_circle_outline,
                      size: 22, color: Colors.grey)),
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount:
                diasDeSemana.length + 2, // days + add button + nav buttons
            itemBuilder: (context, diaIdx) {
              // Navigation buttons at the end
              if (diaIdx >= diasDeSemana.length) {
                final isLast = diaIdx == diasDeSemana.length;
                return Padding(
                  padding: EdgeInsets.only(top: isLast ? 4 : 12),
                  child: isLast
                      ? TextButton.icon(
                          onPressed: () => _agregarDia(semanaActual),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Añadir día',
                              style: TextStyle(fontSize: 12)))
                      : Row(children: [
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () => setState(() => _paso = 0),
                                  child: const Text('Atrás'))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: FilledButton(
                                  onPressed: () => setState(() => _paso = 2),
                                  child: const Text('Revisar y crear'))),
                        ]),
                );
              }
              final diaNum = diasDeSemana[diaIdx];
              final ejercicios = _estructura[semanaActual]?[diaNum] ?? [];
              return _DiaEditorCard(
                semanaNum: semanaActual,
                diaNum: diaNum,
                ejercicios: ejercicios,
                objetivo: _objetivo,
                canDelete: diasDeSemana.length > 1,
                onDelete: () => _eliminarDia(semanaActual, diaNum),
                onEjercicioAdded: (e) =>
                    setState(() => _estructura[semanaActual]![diaNum]!.add(e)),
                onEjercicioRemoved: (idx) => setState(
                    () => _estructura[semanaActual]![diaNum]!.removeAt(idx)),
                onEjercicioUpdated: (idx, e) => setState(
                    () => _estructura[semanaActual]![diaNum]![idx] = e),
                onSugerirEjerciciosIA: EnvConfig.hasGeminiApiKey
                    ? () => _sugerirEjerciciosIA(semanaActual, diaNum)
                    : null,
                labelSugerirIA: _ejerciciosRecomendados
                    ? 'Sugerir otros ejercicios'
                    : 'Sugerir ejercicios con IA',
                loadingIA: _loadingIA,
              );
            },
          ),
        ),
      ],
    );
  }

  void _agregarSemana() {
    final maxSemana = _estructura.keys.isEmpty
        ? 0
        : _estructura.keys.reduce((a, b) => a > b ? a : b);
    final nuevaSemana = maxSemana + 1;
    final dias = _estructura.values.firstOrNull;
    final numDias = dias?.length ?? _diasPorSemana;
    setState(() {
      _estructura[nuevaSemana] = {};
      for (var d = 1; d <= numDias; d++) {
        _estructura[nuevaSemana]![d] = [];
      }
      _duracionSemanas = _estructura.length;
      _semanaActiva = (_estructura.keys.toList()..sort()).indexOf(nuevaSemana);
    });
  }

  void _eliminarSemana(int semana) {
    setState(() {
      _estructura.remove(semana);
      _duracionSemanas = _estructura.length;
      if (_estructura.isEmpty) {
        _agregarSemana();
      }
      if (_semanaActiva >= _estructura.length) {
        _semanaActiva = _estructura.length - 1;
      }
    });
  }

  void _agregarDia(int semana) {
    final dias = (_estructura[semana]?.keys.toList() ?? [])..sort();
    final maxDia = dias.isEmpty ? 0 : dias.last;
    setState(() {
      _estructura[semana]![maxDia + 1] = [];
    });
  }

  void _eliminarDia(int semana, int dia) {
    setState(() {
      _estructura[semana]!.remove(dia);
    });
  }

  Widget _buildPaso3() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalEjercicios = _estructura.values.fold<int>(0,
        (t, dias) => t + dias.values.fold<int>(0, (t2, ej) => t2 + ej.length));
    final semanasVacias = _estructura.entries
        .where((sem) => sem.value.values.every((d) => d.isEmpty))
        .map((sem) => sem.key)
        .toList();
    final visibilidadStr = _visibilidad == 'private'
        ? 'Privada'
        : _visibilidad == 'friends'
            ? 'Amigos'
            : 'Pública';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // ── Compact header ──
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_circle_rounded,
                size: 24, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Revisa tu rutina',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _paso = 1),
            icon: const Icon(Icons.edit_rounded, size: 14),
            label: const Text('Editar', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // ── Name + stats in a compact card ──
        Container(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Nombre de la rutina',
                  hintStyle: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              if (_descCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Icon(Icons.description_outlined,
                        size: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(_descCtrl.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic)),
                    ),
                  ]),
                ),
              const Divider(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _miniChip(Icons.flag_rounded, _objetivo, cs),
                  const SizedBox(width: 8),
                  _miniChip(Icons.visibility_rounded, visibilidadStr, cs),
                  const SizedBox(width: 8),
                  _miniChip(Icons.calendar_month_rounded,
                      '$_duracionSemanas sem', cs),
                  const SizedBox(width: 8),
                  _miniChip(
                      Icons.fitness_center_rounded, '$totalEjercicios ej', cs),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Weeks progress bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            ..._estructura.entries.map((sem) {
              final totalDia =
                  sem.value.values.fold<int>(0, (t, ej) => t + ej.length);
              final pct =
                  sem.value.isEmpty ? 0.0 : totalDia / (sem.value.length * 5);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: semanasVacias.contains(sem.key)
                        ? () => _confirmarEliminarSemana(sem.key)
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: totalDia > 0
                                ? cs.primary.withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor:
                                totalDia > 0 ? pct.clamp(0.1, 1.0) : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    totalDia > 0 ? cs.primary : Colors.orange,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('S${sem.key}',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: totalDia > 0
                                    ? cs.onSurfaceVariant
                                    : Colors.orange.shade600)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Week detail cards ──
        ..._estructura.entries.map((sem) {
          final dias = sem.value;
          final totalDia = dias.values.fold<int>(0, (t, ej) => t + ej.length);
          final estaVacia = totalDia == 0;
          return Card(
            elevation: estaVacia ? 0 : 0.5,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: estaVacia
                    ? Colors.orange.withValues(alpha: 0.4)
                    : cs.outlineVariant.withValues(alpha: 0.3),
                width: estaVacia ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: estaVacia
                              ? Colors.orange.withValues(alpha: 0.1)
                              : cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${sem.key}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: estaVacia ? Colors.orange : cs.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Semana ${sem.key}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      _buildTipoSemanaChip(
                          cs, _calcularTipoSemana(sem.key, _estructura.length)),
                      const Spacer(),
                      if (estaVacia)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Vacía',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade600)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _confirmarEliminarSemana(sem.key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.delete_rounded,
                                  size: 14, color: Colors.red.shade400),
                            ),
                          ),
                        ])
                      else
                        Text('$totalDia ej. · ${dias.length} días',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  if (estaVacia)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Elimínala o edítala para agregar ejercicios.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700)),
                          ),
                        ]),
                      ),
                    ),
                  if (!estaVacia) ...[
                    const SizedBox(height: 8),
                    ...dias.entries.map(
                      (dia) => _buildDaySummary(dia.key, dia.value, cs),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // ── Action buttons ──
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => setState(() => _paso = 1),
                  child: const Text('Volver a editar'))),
          const SizedBox(width: 12),
          Expanded(
              child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed:
                _creando || semanasVacias.isNotEmpty ? null : _crearRutina,
            child: _creando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Crear rutina'),
          )),
        ]),
        if (semanasVacias.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              semanasVacias.length == 1
                  ? 'Elimina o llena la Semana ${semanasVacias.first} antes de crear.'
                  : 'Elimina o llena las semanas ${semanasVacias.join(", ")} antes de crear.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _miniChip(IconData icon, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: cs.primary),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant)),
      ]),
    );
  }

  void _confirmarEliminarSemana(int semana) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar semana'),
        content: Text('¿Eliminar la Semana $semana y todos sus días?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarSemana(semana);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummary(
      int diaNum, List<_EjercicioPlan> ejercicios, ColorScheme cs) {
    if (ejercicios.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 42, bottom: 6),
        child: Text('Día $diaNum — Sin ejercicios',
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 42, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Día $diaNum',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ...ejercicios.map(
            (e) => _buildExerciseSummaryRow(e),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSummaryRow(_EjercicioPlan e) {
    final params = _buildParametrosEjercicio(e);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: SVColors.primary, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      e.nombre,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (e.esCircuito) ...[
                    const SizedBox(width: 4),
                    _circuitoChip(),
                  ],
                  const SizedBox(width: 4),
                  _finalidadBadge(e.finalidad),
                  const SizedBox(width: 4),
                  _buildModalidadChip(e),
                ]),
                if (params.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(params,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildParametrosEjercicio(_EjercicioPlan e) {
    final parts = <String>[];
    final hasTiempo = e.tipoMedicion.contains('tiempo');
    final hasDistancia = e.tipoMedicion.contains('distancia');
    final hasRepeticiones = e.tipoMedicion.contains('repeticiones');
    final hasPeso = e.tipoMedicion.contains('peso');
    final hasCalorias = e.tipoMedicion.contains('calorias');

    if (e.esCircuito) {
      if (e.duracionSegundos != null && e.duracionSegundos! > 0) {
        parts.add(fmtDuracion(e.duracionSegundos!));
      }
    } else if (hasTiempo && !hasRepeticiones && !hasDistancia && !hasCalorias) {
      if (e.tiempoIsometricoSegundos != null &&
          e.tiempoIsometricoSegundos! > 0) {
        parts.add('${e.series}×${e.tiempoIsometricoSegundos}s');
      }
    } else if (hasRepeticiones) {
      parts.add('${e.series}×${e.repeticiones}');
    }

    if (hasPeso && e.pesosKg != null && e.pesosKg!.any((w) => w > 0)) {
      parts.add(
          'P: ${e.pesosKg!.where((w) => w > 0).map((w) => w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1)).join('/')} kg');
    } else if (hasPeso && e.pesoKg != null && e.pesoKg! > 0) {
      parts.add('${e.pesoKg!.toStringAsFixed(1)} kg');
    }

    if ((hasDistancia || hasCalorias) &&
        e.distanciaMetros != null &&
        e.distanciaMetros! > 0) {
      parts.add(_fmtDistancia(e.distanciaMetros!));
    }

    if (!e.esCircuito &&
        hasTiempo &&
        e.duracionSegundos != null &&
        e.duracionSegundos! > 0) {
      parts.add(fmtDuracion(e.duracionSegundos!));
    }

    if (e.segundosDescanso > 0) {
      parts.add('${e.segundosDescanso}s desc.');
    }

    return parts.join(' · ');
  }

  String _fmtDistancia(int metros) {
    if (metros >= 1000) return '${(metros / 1000).toStringAsFixed(1)} km';
    return '$metros m';
  }

  Widget _circuitoChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Circuito',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Colors.purple)),
      );

  Widget _buildModalidadChip(_EjercicioPlan e) {
    final (label, color) = switch (e.modalidadEntrenamiento) {
      'fuerza' => ('Fuerza', Colors.redAccent),
      'aerobica' => ('Aeróbica', Colors.teal),
      'metabolica' => ('Metabólica', Colors.orange),
      'movilidad' => ('Movilidad', Colors.indigo),
      _ => (null, null),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _finalidadBadge(String finalidad) {
    final color = _colorFinalidad(finalidad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
          finalidad.length <= 10 ? finalidad : '${finalidad.substring(0, 9)}…',
          style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Color _colorFinalidad(String f) {
    final lower = f.toLowerCase();
    if (lower.contains('hipertrofia')) {
      return Colors.redAccent;
    }
    if (lower.contains('fuerza') || lower.contains('potencia')) {
      return Colors.orange;
    }
    if (lower.contains('cardio') || lower.contains('acondicionamiento')) {
      return Colors.teal;
    }
    if (lower.contains('resistencia')) {
      return Colors.blue;
    }
    if (lower.contains('movilidad') || lower.contains('flexibilidad')) {
      return Colors.green;
    }
    if (lower.contains('isométrico')) {
      return Colors.indigo;
    }
    return Colors.grey;
  }

  String _calcularTipoSemana(int semanaNum, int totalSemanas) {
    if (totalSemanas <= 1) return 'carga';
    if (semanaNum == 1) return 'adaptacion';
    if (semanaNum == totalSemanas && totalSemanas >= 4) return 'descarga';
    if (semanaNum == totalSemanas && totalSemanas >= 3) return 'pico';
    return 'carga';
  }

  Widget _buildTipoSemanaChip(ColorScheme cs, String tipo) {
    final (label, color) = switch (tipo) {
      'adaptacion' => ('Adaptación', Colors.amber),
      'carga' => ('Carga', Colors.orange),
      'pico' => ('Pico', Colors.redAccent),
      'descarga' => ('Descarga', Colors.teal),
      _ => ('', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Future<void> _recomendarRutina() async {
    setState(() {
      _loadingIA = true;
      _tipoCarga = 'rutina';
    });
    _iniciarSecuenciaMensajes();
    try {
      ref.invalidate(perfilBienestarProvider);
      ref.invalidate(ejerciciosProvider);
      ref.invalidate(historialSesionUsuarioProvider);
      ref.invalidate(estadoDiarioHoyProvider);

      await syncCargaAcademicaSemanal(ref);

      final catalogoAsync = ref.read(ejerciciosProvider.future);
      final conIA = EnvConfig.hasGeminiApiKey;
      final resultado = await ref
          .read(generarRutinaProvider(
              (conIA: conIA, duracionSemanas: _duracionSemanas)).future)
          .timeout(const Duration(seconds: 45));
      final catalogo = await catalogoAsync;
      if (!mounted) return;
      if (!_loadingIA) return;

      if (resultado.tieneError) {
        _terminarCargaIA();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(resultado.error!),
                duration: const Duration(seconds: 3)),
          );
        }
        return;
      }

      _nombreCtrl.text = resultado.nombre;
      _descCtrl.text = resultado.descripcion;
      _objetivo = sanitizarObjetivo(resultado.objetivo);
      _duracionSemanas = resultado.duracionSemanas.clamp(1, 12);
      _diasPorSemana =
          resultado.estructura[1]?.length.clamp(1, 7) ?? _diasPorSemana;
      _syncEstructura();

      setState(() {
        _estructura.clear();
        for (final semana in resultado.estructura.entries) {
          _estructura[semana.key] = {};
          for (final dia in semana.value.entries) {
            _estructura[semana.key]![dia.key] = dia.value.map((e) {
              final match = catalogo.cast<EjercicioDb?>().firstWhere(
                    (ex) => ex?.id == e.ejercicioId,
                    orElse: () => null,
                  );
              return _EjercicioPlan(
                ejercicioId: match?.id ?? e.ejercicioId,
                nombre: match?.nombre ?? e.ejercicioId,
                finalidad: match?.finalidadPrincipal ?? resultado.objetivo,
                urlGif: match?.urlGif,
                urlPreview: match?.urlPreview,
                modalidadEntrenamiento:
                    match?.modalidadEntrenamiento ?? 'fuerza',
                tipoMedicion: match?.tipoMedicion ?? const ['repeticiones'],
                esCircuito: match?.esCircuito ?? false,
                series: e.series,
                repeticiones: e.repeticiones,
                segundosDescanso: e.segundosDescanso,
                pesoKg: e.pesoKg,
                pesosKg: e.pesosKg,
                duracionSegundos: e.duracionSegundos,
                distanciaMetros: e.distanciaMetros,
                tiempoIsometricoSegundos: e.tiempoIsometricoSegundos,
              );
            }).toList();
          }
        }
      });

      _detenerMensajesCarga();
      setState(() {
        _loadingIA = false;
        _tipoCarga = '';
        _rutinaRecomendada = true;
        _iaRefinada = resultado.metadatos.iaRefinada;
        _motivoAjustes = resultado.metadatos.motivoAjustes;
        _paso = 1;
      });

      if (mounted && !resultado.tieneError) {
        final motivoIA = resultado.metadatos.motivoAjustes;
        final mensaje = resultado.metadatos.iaRefinada
            ? '¡Rutina generada con IA! Configúrala a tu gusto.'
            : motivoIA != null
                ? 'Rutina generada con reglas. $motivoIA.'
                : '¡Rutina generada! Configúrala a tu gusto.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(mensaje), duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        _terminarCargaIA();
        final msg = e is TimeoutException
            ? 'La generación tardó demasiado. Inténtalo de nuevo.'
            : 'Error al generar rutina. Verifica tu conexión.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<T?> _obtenerOConTimeout<T>(
      Future<T> Function() obtener, String nombre) async {
    try {
      return await obtener().timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('⚠ No se pudo cargar $nombre: $e');
      return null;
    }
  }

  Future<void> _sugerirEjerciciosIA(int semana, int dia) async {
    setState(() {
      _loadingIA = true;
      _tipoCarga = 'sugerir';
    });
    _iniciarSecuenciaMensajes();
    try {
      ref.invalidate(perfilBienestarProvider);
      ref.invalidate(ejerciciosProvider);
      ref.invalidate(historialSesionUsuarioProvider);
      ref.invalidate(estadoDiarioHoyProvider);

      PerfilBienestarDb? perfil;
      List<EjercicioDb> ejercicios = [];
      HistorialSesionDto? historial;
      EstadoDiarioDb? estadoDiario;

      final resultados = await Future.wait([
        _obtenerOConTimeout(
            () => ref.read(perfilBienestarProvider.future), 'perfil'),
        _obtenerOConTimeout(() => ref.read(ejerciciosProvider.future),
            'catálogo de ejercicios'),
        _obtenerOConTimeout(
            () => ref.read(historialSesionUsuarioProvider.future), 'historial'),
        _obtenerOConTimeout(
            () => ref.read(estadoDiarioHoyProvider.future), 'estado diario'),
      ]);

      perfil = resultados[0] as PerfilBienestarDb?;
      ejercicios = (resultados[1] as List<EjercicioDb>?) ?? [];
      historial = resultados[2] as HistorialSesionDto?;
      estadoDiario = resultados[3] as EstadoDiarioDb?;

      if (!mounted) return;
      if (!_loadingIA) return;

      if (perfil == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Completa tu perfil de bienestar para recibir sugerencias'),
                duration: Duration(seconds: 2)),
          );
        }
        _terminarCargaIA();
        return;
      }

      final apiKey = EnvConfig.geminiApiKey;
      if (apiKey.isEmpty) {
        _terminarCargaIA();
        return;
      }

      if (ejercicios.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'No se pudo cargar el catálogo de ejercicios. Verifica tu conexión.'),
                duration: Duration(seconds: 2)),
          );
        }
        _terminarCargaIA();
        return;
      }

      final ejerciciosActuales =
          _estructura[semana]![dia]!.map((e) => e.ejercicioId).toList();

      final servicio = RecomendacionIaService();
      final resultado = await servicio
          .generarRecomendacionEjercicios(
            apiKey: apiKey,
            perfil: perfil,
            ejerciciosDisponibles: ejercicios,
            nombreRutina: _nombreCtrl.text.isNotEmpty
                ? _nombreCtrl.text
                : 'Rutina personalizada',
            objetivoRutina: _objetivo,
            diaNum: dia,
            ejerciciosYaAgregados: ejerciciosActuales,
            historial: historial,
            estadoDiario: estadoDiario,
          )
          .timeout(const Duration(seconds: 45));

      if (!mounted) return;
      if (!_loadingIA) return;

      if (resultado.tieneError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(resultado.error!),
              duration: const Duration(seconds: 3)),
        );
        _terminarCargaIA();
        return;
      }

      if (resultado.ejercicios.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se encontraron ejercicios para recomendar'),
              duration: Duration(seconds: 2)),
        );
        _terminarCargaIA();
        return;
      }

      final idsValidos = ejercicios.map((e) => e.id).toSet();
      final ejerciciosValidos = resultado.ejercicios
          .where((rec) => idsValidos.contains(rec.ejercicioId))
          .toList();

      if (ejerciciosValidos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('La IA no devolvió ejercicios válidos del catálogo.'),
                duration: Duration(seconds: 2)),
          );
        }
        _terminarCargaIA();
        return;
      }

      // Si es "Sugerir otros" (viene de ejercicios recomendados), limpiar el día
      if (_ejerciciosRecomendados) {
        _estructura[semana]![dia]!.clear();
      }

      for (final rec in ejerciciosValidos) {
        final match = ejercicios.cast<EjercicioDb?>().firstWhere(
              (ex) => ex?.id == rec.ejercicioId,
              orElse: () => null,
            );
        _estructura[semana]![dia]!.add(_EjercicioPlan(
          ejercicioId: match?.id ?? rec.ejercicioId,
          nombre: match?.nombre ?? 'Ejercicio sugerido',
          finalidad: match?.finalidadPrincipal ?? 'Hipertrofia Muscular',
          urlGif: match?.urlGif,
          urlPreview: match?.urlPreview,
          modalidadEntrenamiento: match?.modalidadEntrenamiento ?? 'fuerza',
          tipoMedicion: match?.tipoMedicion ?? const ['repeticiones'],
          esCircuito: match?.esCircuito ?? false,
          series: rec.series,
          repeticiones: rec.repeticiones,
          segundosDescanso: rec.segundosDescanso,
          pesoKg: rec.pesoKg,
          duracionSegundos: rec.duracionSegundos,
          distanciaMetros: rec.distanciaMetros,
          tiempoIsometricoSegundos: rec.tiempoIsometricoSegundos,
        ));
      }

      _detenerMensajesCarga();
      setState(() {
        _loadingIA = false;
        _tipoCarga = '';
        _semanaActiva = semana;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${resultado.ejercicios.length} ejercicios sugeridos para el Día $dia'),
              duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        _terminarCargaIA();
        final msg = e is TimeoutException
            ? 'La IA tardó demasiado en sugerir ejercicios. Inténtalo de nuevo.'
            : 'Error al sugerir ejercicios. Verifica tu conexión e inténtalo de nuevo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _crearRutina() async {
    final semanasVacias = _estructura.entries
        .where((sem) => sem.value.values.every((d) => d.isEmpty))
        .map((sem) => sem.key)
        .toList();
    if (semanasVacias.isNotEmpty) {
      setState(() => _creando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              semanasVacias.length == 1
                  ? 'La Semana ${semanasVacias.first} no tiene ejercicios'
                  : 'Las semanas ${semanasVacias.join(", ")} no tienen ejercicios',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _creando = true);
    try {
      final estructuraInput = <int, Map<int, List<EjercicioInput>>>{};
      for (final s in _estructura.entries) {
        estructuraInput[s.key] = {};
        for (final d in s.value.entries) {
          estructuraInput[s.key]![d.key] =
              d.value.map((e) => e.toInput()).toList();
        }
      }
      final rutinaId = await crearRutinaCompleta(
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        visibilidad: _visibilidad,
        objetivo: _objetivo,
        duracionSemanas: _duracionSemanas,
        estructura: estructuraInput,
        ref: ref,
      );
      if (mounted) context.go('/bienestar/rutina/$rutinaId');
    } catch (e) {
      if (mounted) {
        setState(() => _creando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al crear: $e')));
      }
    }
  }
}

// =============================================================================
// Miniatura reusable de GIF para previsualización de ejercicios
// =============================================================================
class _MiniGifPreview extends StatelessWidget {
  const _MiniGifPreview({this.urlGif, this.previewUrl, this.size = 56});
  final String? urlGif;
  final String? previewUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final preview = previewUrl ??
        (urlGif != null && urlGif!.endsWith('.mp4') ? null : urlGif);

    return GestureDetector(
      onTap: preview != null && preview.isNotEmpty
          ? () => _mostrarGifAmpliado(context, urlGif, previewUrl)
          : null,
      child: Container(
        width: size,
        height: size * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF1A1A1E),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: preview != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: preview,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => _placeholder(context),
                    errorWidget: (_, __, ___) => _placeholder(context),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: 20,
        color: Colors.white38,
      ),
    );
  }

  void _mostrarGifAmpliado(BuildContext context, String? url, String? preview) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.88,
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: ExerciseMediaWidget(
                    url: url,
                    previewUrl: preview,
                    size: ExerciseMediaSize.dialog,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _DiaEditorCard extends StatefulWidget {
  const _DiaEditorCard(
      {required this.semanaNum,
      required this.diaNum,
      required this.ejercicios,
      required this.objetivo,
      required this.canDelete,
      required this.onDelete,
      required this.onEjercicioAdded,
      required this.onEjercicioRemoved,
      required this.onEjercicioUpdated,
      this.onSugerirEjerciciosIA,
      this.labelSugerirIA = 'Sugerir ejercicios con IA',
      this.loadingIA = false});
  final int semanaNum, diaNum;
  final List<_EjercicioPlan> ejercicios;
  final String objetivo;
  final bool canDelete;
  final VoidCallback onDelete;
  final void Function(_EjercicioPlan) onEjercicioAdded;
  final void Function(int) onEjercicioRemoved;
  final void Function(int, _EjercicioPlan) onEjercicioUpdated;
  final VoidCallback? onSugerirEjerciciosIA;
  final String labelSugerirIA;
  final bool loadingIA;
  @override
  State<_DiaEditorCard> createState() => _DiaEditorCardState();
}

class _DiaEditorCardState extends State<_DiaEditorCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text('${widget.diaNum}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: theme.colorScheme.primary)))),
            const SizedBox(width: 10),
            Text('Día ${widget.diaNum}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${widget.ejercicios.length} ej.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            if (widget.canDelete)
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                  onPressed: widget.onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28)),
          ]),
          if (widget.ejercicios.isNotEmpty) ...[
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.ejercicios.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex--;
                final item = widget.ejercicios.removeAt(oldIndex);
                widget.ejercicios.insert(newIndex, item);
                setState(() {});
              },
              itemBuilder: (context, index) {
                final entry = widget.ejercicios[index];
                return _EjercicioCompacto(
                  key: ValueKey(entry.ejercicioId),
                  ejercicio: entry,
                  onRemove: () => widget.onEjercicioRemoved(index),
                  onChanged: (nuevo) => widget.onEjercicioUpdated(index, nuevo),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          if (widget.onSugerirEjerciciosIA != null)
            TextButton.icon(
                onPressed:
                    widget.loadingIA ? null : widget.onSugerirEjerciciosIA,
                icon: widget.loadingIA
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(
                    widget.loadingIA ? 'Sugiriendo...' : widget.labelSugerirIA,
                    style: const TextStyle(fontSize: 11))),
          TextButton.icon(
              onPressed: () => _mostrarBuscador(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Añadir ejercicio',
                  style: TextStyle(fontSize: 12))),
        ]),
      ),
    );
  }

  void _mostrarBuscador(BuildContext context) async {
    final previos = widget.ejercicios.map((e) => e.ejercicioId).toList();
    final resultado = await Navigator.of(context).push<List<EjercicioDb>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            SeleccionEjerciciosScreen(seleccionadosPrevios: previos),
      ),
    );
    if (resultado == null) return;
    if (!context.mounted) return;
    final existingIds = widget.ejercicios.map((e) => e.ejercicioId).toSet();
    final params = ParametrosObjetivo.de(widget.objetivo);
    final container = ProviderScope.containerOf(context);
    final estadoHoy = container.read(estadoDiarioHoyProvider).valueOrNull;
    final zonasDolor = estadoHoy?.zonasDolor ?? [];

    for (final ej in resultado) {
      if (existingIds.contains(ej.id)) continue;
      if (zonasDolor.isNotEmpty) {
        final musculosEvitar = _musculosPorZonas(zonasDolor);
        final musculosEj =
            ej.musculosObjetivo.map((m) => m.toLowerCase()).toSet();
        final afectados = musculosEj.intersection(musculosEvitar);
        if (afectados.isNotEmpty) {
          if (!context.mounted) return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Zona con dolor detectada'),
              content: Text('Este ejercicio trabaja: ${afectados.join(", ")}.\n'
                  'Hoy reportaste dolor en estas zonas. ¿Añadirlo de todos modos?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Añadir')),
              ],
            ),
          );
          if (confirmed != true) continue;
        }
      }
      widget.onEjercicioAdded(_EjercicioPlan(
        ejercicioId: ej.id,
        nombre: ej.nombre,
        finalidad: ej.finalidad.isNotEmpty ? ej.finalidad.first : 'fuerza',
        urlGif: ej.urlGif,
        urlPreview: ej.urlPreview,
        modalidadEntrenamiento: ej.modalidadEntrenamiento,
        tipoMedicion: ej.tipoMedicion,
        esCircuito: ej.esCircuito,
        series: params.seriesDefault,
        repeticiones: params.repsDefault,
        segundosDescanso: params.descansoDefault,
      ));
    }
  }

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

  Set<String> _musculosPorZonas(List<String> zonas) {
    final musculos = <String>{};
    for (final zona in zonas) {
      final mapped = _mapZonasAMusculos[zona.toLowerCase().trim()];
      if (mapped != null) musculos.addAll(mapped.map((m) => m.toLowerCase()));
    }
    return musculos;
  }
}

// =============================================================================
class _EjercicioCompacto extends StatefulWidget {
  const _EjercicioCompacto(
      {required this.ejercicio,
      required this.onRemove,
      required this.onChanged,
      super.key});
  final _EjercicioPlan ejercicio;
  final VoidCallback onRemove;
  final void Function(_EjercicioPlan) onChanged;
  @override
  State<_EjercicioCompacto> createState() => _EjercicioCompactoState();
}

class _EjercicioCompactoState extends State<_EjercicioCompacto> {
  late int _series, _reps, _descanso;
  late double? _peso;
  late List<double> _pesosKg;
  late bool _mismoPeso;
  late int? _duracionSegundos;
  late int? _distanciaMetros;
  late int? _tiempoIsometrico;
  bool _expanded = true;
  final _pesoCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _distanciaCtrl = TextEditingController();
  final _tiempoIsoCtrl = TextEditingController();
  final List<TextEditingController> _pesosKgCtrls = [];

  @override
  void initState() {
    super.initState();
    _series = widget.ejercicio.series;
    _reps = widget.ejercicio.repeticiones;
    _descanso = widget.ejercicio.segundosDescanso;
    _peso = widget.ejercicio.pesoKg;
    _mismoPeso = widget.ejercicio.mismoPeso;
    _pesosKg = widget.ejercicio.pesosKg != null
        ? List.from(widget.ejercicio.pesosKg!)
        : List.filled(_series, widget.ejercicio.pesoKg ?? 0);
    _syncPesoCtrl();
    _duracionSegundos = widget.ejercicio.duracionSegundos;
    _distanciaMetros = widget.ejercicio.distanciaMetros;
    _tiempoIsometrico = widget.ejercicio.tiempoIsometricoSegundos;
    _duracionCtrl.text =
        _duracionSegundos != null ? _fmtDuracion(_duracionSegundos!) : '';
    _distanciaCtrl.text =
        _distanciaMetros != null ? _distanciaMetros.toString() : '';
    _tiempoIsoCtrl.text =
        _tiempoIsometrico != null ? _tiempoIsometrico.toString() : '';
    _initPesosKgCtrls();
  }

  void _syncPesoCtrl() {
    _pesoCtrl.text = _peso != null
        ? _peso!.toStringAsFixed(_peso! == _peso!.roundToDouble() ? 0 : 1)
        : '';
  }

  void _initPesosKgCtrls() {
    for (final c in _pesosKgCtrls) {
      c.dispose();
    }
    _pesosKgCtrls.clear();
    for (var i = 0; i < _pesosKg.length; i++) {
      final ctrl = TextEditingController(
        text: _pesosKg[i] > 0
            ? _pesosKg[i].toStringAsFixed(
                _pesosKg[i] == _pesosKg[i].roundToDouble() ? 0 : 1)
            : '',
      );
      _pesosKgCtrls.add(ctrl);
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _duracionCtrl.dispose();
    _distanciaCtrl.dispose();
    _tiempoIsoCtrl.dispose();
    for (final c in _pesosKgCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit({
    int? s,
    int? r,
    int? d,
    double? p,
    List<double>? pesos,
    bool? mismoPeso,
    int? dur,
    int? dist,
    int? tIso,
  }) {
    s ??= _series;
    r ??= _reps;
    d ??= _descanso;
    p ??= _peso;
    final mismoPesoFinal = mismoPeso ?? _mismoPeso;
    dur ??= _duracionSegundos;
    dist ??= _distanciaMetros;
    tIso ??= _tiempoIsometrico;

    setState(() {
      _series = s!;
      _reps = r!;
      _descanso = d!;
      _peso = p;
      _mismoPeso = mismoPesoFinal;
      _duracionSegundos = dur!;
      _distanciaMetros = dist!;
      _tiempoIsometrico = tIso!;
      if (_mismoPeso) {
        _pesosKg = List.filled(_series, _peso ?? 0);
      } else if (s != _series) {
        final lastVal = _pesosKg.isNotEmpty ? _pesosKg.last : (_peso ?? 0);
        if (_series > _pesosKg.length) {
          _pesosKg = List<double>.from(_pesosKg)
            ..addAll(List.filled(_series - _pesosKg.length, lastVal));
        } else if (_series < _pesosKg.length) {
          _pesosKg = _pesosKg.sublist(0, _series);
        }
      }
    });
    if (!_mismoPeso) {
      _initPesosKgCtrls();
    }
    widget.onChanged(widget.ejercicio.copyWith(
      series: _series,
      repeticiones: _reps,
      segundosDescanso: _descanso,
      pesoKg: _mismoPeso ? _peso : null,
      pesosKg: _mismoPeso ? null : _pesosKg,
      mismoPeso: _mismoPeso,
      duracionSegundos: _duracionSegundos,
      distanciaMetros: _distanciaMetros,
      tiempoIsometricoSegundos: _tiempoIsometrico,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final finalidad = widget.ejercicio.finalidad;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nombre del ejercicio + chip de finalidad + preview ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 20,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                if (widget.ejercicio.urlGif != null ||
                    widget.ejercicio.urlPreview != null) ...[
                  _MiniGifPreview(
                    urlGif: widget.ejercicio.urlGif,
                    previewUrl: widget.ejercicio.urlPreview,
                    size: 56,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => context.push(
                                    '/bienestar/ejercicio/${widget.ejercicio.ejercicioId}',
                                    extra: true),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    widget.ejercicio.nombre,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: cs.onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: _finalidadChip(finalidad, cs),
                                  ),
                                  const SizedBox(width: 6),
                                  if (widget.ejercicio.esCircuito)
                                    Text(
                                      'Circuito',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            cs.tertiary.withValues(alpha: 0.9),
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      '$_series×$_reps',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    if (_mismoPeso && _peso != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_peso!.toStringAsFixed(_peso! == _peso!.roundToDouble() ? 0 : 1)} kg',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              cs.primary.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ] else if (!_mismoPeso &&
                                        _pesosKg.any((w) => w > 0)) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        _pesosKg
                                            .map((w) => w > 0
                                                ? w.toStringAsFixed(
                                                    w == w.roundToDouble()
                                                        ? 0
                                                        : 1)
                                                : '—')
                                            .join('/'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              cs.primary.withValues(alpha: 0.8),
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: cs.error.withValues(alpha: 0.7)),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final anchoPill = (constraints.maxWidth - 12) / 2;
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _buildCamposDinamicos(
                            widget.ejercicio.tipoMedicion,
                            widget.ejercicio.esCircuito,
                            anchoPill,
                            cs,
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chip de finalidad (miniatura)
  // ---------------------------------------------------------------------------
  Widget _finalidadChip(String f, ColorScheme cs) {
    final lower = f.toLowerCase();
    Color chipColor;
    if (lower.contains('hipertrofia')) {
      chipColor = Colors.red;
    } else if (lower.contains('fuerza') || lower.contains('potencia')) {
      chipColor = Colors.orange;
    } else if (lower.contains('cardio') ||
        lower.contains('acondicionamiento')) {
      chipColor = Colors.teal;
    } else if (lower.contains('resistencia')) {
      chipColor = Colors.blue;
    } else if (lower.contains('movilidad') || lower.contains('flexibilidad')) {
      chipColor = Colors.green;
    } else if (lower.contains('isometric')) {
      chipColor = Colors.indigo;
    } else {
      chipColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        f,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: chipColor.withValues(alpha: 0.9),
            letterSpacing: 0.3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Renderizado condicional de campos según finalidad
  // ---------------------------------------------------------------------------
  Widget _buildCamposDinamicos(List<String> tipoMedicion, bool esCircuito,
      double anchoPill, ColorScheme cs) {
    final hasTime = tipoMedicion.contains('tiempo');
    final hasDistOrCal =
        tipoMedicion.contains('distancia') || tipoMedicion.contains('calorias');

    if (hasTime && hasDistOrCal) return _camposCardio(anchoPill, cs);
    if (hasTime) return _camposIsometrico(anchoPill, cs);
    return _camposFuerza(anchoPill, cs, esCircuito: esCircuito);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FUERZA / METABOLICA: Series, Reps, Descanso, Peso (grid 2x2)
  // Si esCircuito: oculta Series, muestra Duracion total en su lugar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _camposFuerza(double anchoPill, ColorScheme cs,
      {bool esCircuito = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!esCircuito)
          _paramPill(
              'Series', _series, 1, 10, (v) => _emit(s: v), anchoPill, cs),
        if (!esCircuito)
          _paramPill('Reps', _reps, 1, 50, (v) => _emit(r: v), anchoPill, cs),
        if (esCircuito) _duracionPill(anchoPill, cs),
        _paramPill(
            'Descanso', _descanso, 15, 300, (v) => _emit(d: v), anchoPill, cs,
            sufijo: 's'),
        _pesoPill(anchoPill, cs),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARDIO: Intervalos (=series), Duración, Distancia (opcional), Descanso
  // ─────────────────────────────────────────────────────────────────────────
  Widget _camposCardio(double anchoPill, ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _paramPill(
            'Intervalos', _series, 1, 20, (v) => _emit(s: v), anchoPill, cs),
        _duracionPill(anchoPill, cs),
        _distanciaPill(anchoPill, cs),
        _paramPill(
            'Descanso', _descanso, 15, 300, (v) => _emit(d: v), anchoPill, cs,
            sufijo: 's'),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ISOMÉTRICO: Series, Tiempo de sujeción, Descanso
  // ─────────────────────────────────────────────────────────────────────────
  Widget _camposIsometrico(double anchoPill, ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _paramPill('Series', _series, 1, 10, (v) => _emit(s: v), anchoPill, cs),
        _tiempoIsometricoPill(anchoPill, cs),
        _paramPill(
            'Descanso', _descanso, 15, 300, (v) => _emit(d: v), anchoPill, cs,
            sufijo: 's'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de formato
  // ---------------------------------------------------------------------------
  String _fmtDuracion(int segundos) => fmtDuracion(segundos);

  int _parseDuracion(String texto) {
    // Formatos: "5m 30s", "5:30", "300", "5 min", "5m"
    texto = texto.trim().toLowerCase();
    final colon = RegExp(r'^(\d+):(\d+)$').firstMatch(texto);
    if (colon != null) {
      return int.parse(colon.group(1)!) * 60 + int.parse(colon.group(2)!);
    }
    int total = 0;
    final minMatch = RegExp(r'(\d+)\s*(?:min|m)\b').firstMatch(texto);
    final secMatch = RegExp(r'(\d+)\s*(?:seg|s)\b').firstMatch(texto);
    if (minMatch != null) total += int.parse(minMatch.group(1)!) * 60;
    if (secMatch != null) total += int.parse(secMatch.group(1)!);
    if (minMatch == null && secMatch == null) {
      final soloNum = int.tryParse(texto);
      if (soloNum != null) total = soloNum;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Pill genérico (+/- buttons)
  // ---------------------------------------------------------------------------
  Widget _paramPill(String label, int val, int min, int max,
      void Function(int) onChange, double width, ColorScheme cs,
      {String sufijo = ''}) {
    final canDown = val > min;
    final canUp = val < max;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5)),
                  Text('$val$sufijo',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: 32,
                  height: 28,
                  child: IconButton(
                    onPressed: canUp ? () => onChange(val + 1) : null,
                    icon: Icon(Icons.keyboard_arrow_up_rounded,
                        size: 20,
                        color: canUp ? cs.primary : cs.outlineVariant),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 28,
                  child: IconButton(
                    onPressed: canDown ? () => onChange(val - 1) : null,
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: canDown ? cs.primary : cs.outlineVariant),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pill de Duración (cardio) — input de texto con formato libre
  // ---------------------------------------------------------------------------
  Widget _duracionPill(double width, ColorScheme cs) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Duración',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                  icon: Icons.remove,
                  onTap: () {
                    final actual = _duracionSegundos ?? 0;
                    final nuevo = (actual - 30).clamp(0, 86400);
                    _emit(dur: nuevo == 0 ? null : nuevo);
                    _duracionCtrl.text = nuevo == 0 ? '' : _fmtDuracion(nuevo);
                  },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 58,
                  height: 32,
                  child: TextField(
                    controller: _duracionCtrl,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'ej. 5m',
                      hintStyle: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      if (v.isEmpty) {
                        _emit(dur: null);
                      } else {
                        final segundos = _parseDuracion(v);
                        if (segundos > 0) _emit(dur: segundos);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                  icon: Icons.add,
                  onTap: () {
                    final actual = _duracionSegundos ?? 0;
                    final nuevo = (actual + 30).clamp(0, 86400);
                    _emit(dur: nuevo == 0 ? null : nuevo);
                    _duracionCtrl.text = nuevo == 0 ? '' : _fmtDuracion(nuevo);
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pill de Distancia (cardio, opcional) — input numérico en metros
  // ---------------------------------------------------------------------------
  Widget _distanciaPill(double width, ColorScheme cs) {
    final distActual = _distanciaMetros ?? 0;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Distancia (m)',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                  icon: Icons.remove,
                  onTap: () {
                    if (distActual > 0) {
                      final nuevo = (distActual - 100).clamp(0, 42195);
                      _emit(dist: nuevo == 0 ? null : nuevo);
                      _distanciaCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                    }
                  },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 52,
                  height: 32,
                  child: TextField(
                    controller: _distanciaCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) {
                        final limpio = parsed.clamp(0, 42195);
                        _emit(dist: limpio == 0 ? null : limpio);
                      } else if (v.isEmpty) {
                        _emit(dist: null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                  icon: Icons.add,
                  onTap: () {
                    final nuevo = (distActual + 100).clamp(0, 42195);
                    _emit(dist: nuevo == 0 ? null : nuevo);
                    _distanciaCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pill de Tiempo Isométrico — input numérico en segundos
  // ---------------------------------------------------------------------------
  Widget _tiempoIsometricoPill(double width, ColorScheme cs) {
    final tiActual = _tiempoIsometrico ?? 0;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Tiempo (s)',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                  icon: Icons.remove,
                  onTap: () {
                    if (tiActual > 0) {
                      final nuevo = (tiActual - 5).clamp(0, 3600);
                      _emit(tIso: nuevo == 0 ? null : nuevo);
                      _tiempoIsoCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                    }
                  },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 52,
                  height: 32,
                  child: TextField(
                    controller: _tiempoIsoCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) {
                        final limpio = parsed.clamp(0, 3600);
                        _emit(tIso: limpio == 0 ? null : limpio);
                      } else if (v.isEmpty) {
                        _emit(tIso: null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                  icon: Icons.add,
                  onTap: () {
                    final nuevo = (tiActual + 5).clamp(0, 3600);
                    _emit(tIso: nuevo == 0 ? null : nuevo);
                    _tiempoIsoCtrl.text = nuevo == 0 ? '' : nuevo.toString();
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _pesoPill(double width, ColorScheme cs) {
    if (_mismoPeso) {
      return _buildSingleWeightPill(width, cs);
    }
    return _buildPerSeriesWeightSection(width, cs);
  }

  Widget _buildSingleWeightPill(double width, ColorScheme cs) {
    final pesoActual = _peso ?? 0;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Peso (kg)',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5)),
                const Spacer(),
                _pesoModeToggle(cs),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btnDelta(
                    icon: Icons.remove,
                    onTap: () {
                      if (pesoActual > 0) {
                        final nuevo = (pesoActual - 2.5).clamp(0, 999);
                        _emit(
                            p: nuevo == 0
                                ? null
                                : double.parse(nuevo.toStringAsFixed(1)));
                        _pesoCtrl.text = nuevo == 0
                            ? ''
                            : nuevo.toStringAsFixed(
                                nuevo == nuevo.roundToDouble() ? 0 : 1);
                      }
                    }),
                const SizedBox(width: 4),
                SizedBox(
                  width: 52,
                  height: 32,
                  child: TextField(
                    controller: _pesoCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: TextStyle(
                          fontSize: 18,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed != null) {
                        final limpio = parsed.clamp(0, 999).toDouble();
                        _emit(p: limpio == 0 ? null : limpio);
                      } else if (v.isEmpty) {
                        _emit(p: null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                _btnDelta(
                    icon: Icons.add,
                    onTap: () {
                      final nuevo = (pesoActual + 2.5).clamp(0, 999);
                      _emit(
                          p: nuevo == 0
                              ? null
                              : double.parse(nuevo.toStringAsFixed(1)));
                      _pesoCtrl.text = nuevo == 0
                          ? ''
                          : nuevo.toStringAsFixed(
                              nuevo == nuevo.roundToDouble() ? 0 : 1);
                    }),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPerSeriesWeightSection(double width, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Peso x serie',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5)),
              const Spacer(),
              _pesoModeToggle(cs),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(_pesosKg.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}.',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 4),
                  _btnDelta(
                      icon: Icons.remove,
                      onTap: () {
                        final actual = _pesosKg[i];
                        if (actual > 0) {
                          final nuevo = (actual - 2.5).clamp(0, 999);
                          final pesos = List<double>.from(_pesosKg);
                          pesos[i] = double.parse(nuevo.toStringAsFixed(1));
                          _pesosKgCtrls[i].text = nuevo == 0
                              ? ''
                              : nuevo.toStringAsFixed(
                                  nuevo == nuevo.roundToDouble() ? 0 : 1);
                          _emit(pesos: pesos);
                        }
                      }),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 48,
                    height: 28,
                    child: TextField(
                      controller: _pesosKgCtrls[i],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '—',
                        hintStyle: TextStyle(
                            fontSize: 15,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed != null) {
                          final limpio = parsed.clamp(0, 999).toDouble();
                          final pesos = List<double>.from(_pesosKg);
                          pesos[i] = limpio;
                          _emit(pesos: pesos);
                        } else if (v.isEmpty) {
                          final pesos = List<double>.from(_pesosKg);
                          pesos[i] = 0;
                          _emit(pesos: pesos);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  _btnDelta(
                      icon: Icons.add,
                      onTap: () {
                        final actual = _pesosKg[i];
                        final nuevo = (actual + 2.5).clamp(0, 999);
                        final pesos = List<double>.from(_pesosKg);
                        pesos[i] = double.parse(nuevo.toStringAsFixed(1));
                        _pesosKgCtrls[i].text = nuevo == 0
                            ? ''
                            : nuevo.toStringAsFixed(
                                nuevo == nuevo.roundToDouble() ? 0 : 1);
                        _emit(pesos: pesos);
                      }),
                  const SizedBox(width: 8),
                  if (i == 0)
                    Text('kg',
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _pesoModeToggle(ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        if (_mismoPeso) {
          final pesos = List<double>.filled(_series, _peso ?? 0);
          _initPesosKgCtrls();
          _emit(mismoPeso: false, pesos: pesos);
        } else {
          final single = _pesosKg.any((w) => w > 0)
              ? _pesosKg.firstWhere((w) => w > 0, orElse: () => 0.0)
              : 0.0;
          _emit(mismoPeso: true, p: single > 0 ? single : null);
          _syncPesoCtrl();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _mismoPeso ? Icons.content_copy_rounded : Icons.tune_rounded,
              size: 12,
              color: cs.primary,
            ),
            const SizedBox(width: 2),
            Text(
              _mismoPeso ? 'Igual' : 'x serie',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btnDelta({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}

String fmtDuracion(int segundos) {
  final min = segundos ~/ 60;
  final sec = segundos % 60;
  if (min > 0 && sec > 0) return '${min}m ${sec}s';
  if (min > 0) return '$min min';
  return '${sec}s';
}
