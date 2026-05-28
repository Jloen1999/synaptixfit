import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/exercise_media_widget.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../application/ejercicios_provider.dart';
import '../application/rutina_provider.dart';
import '../infrastructure/recomendacion_ia_service.dart';

// DTO local para el plan de ejercicios durante la creación
class _EjercicioPlan {
  const _EjercicioPlan({
    required this.ejercicioId,
    required this.nombre,
    required this.finalidad,
    this.urlGif,
    this.series = 3,
    this.repeticiones = 10,
    this.segundosDescanso = 90,
    this.pesoKg,
    this.duracionSegundos,
    this.distanciaMetros,
    this.tiempoIsometricoSegundos,
  });

  final String ejercicioId;
  final String nombre;
  final FinalidadEjercicio finalidad;
  final String? urlGif;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final double? pesoKg;
  final int? duracionSegundos;
  final int? distanciaMetros;
  final int? tiempoIsometricoSegundos;

  _EjercicioPlan copyWith({
    int? series,
    int? repeticiones,
    int? segundosDescanso,
    double? pesoKg,
    int? duracionSegundos,
    int? distanciaMetros,
    int? tiempoIsometricoSegundos,
  }) {
    return _EjercicioPlan(
      ejercicioId: ejercicioId,
      nombre: nombre,
      finalidad: finalidad,
      urlGif: urlGif,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      segundosDescanso: segundosDescanso ?? this.segundosDescanso,
      pesoKg: pesoKg ?? this.pesoKg,
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
  bool _ejerciciosRecomendados = false;
  Timer? _timerMensajes;
  String _mensajeCarga = '';

  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _visibilidad = 'private';
  String _objetivo = 'fuerza';
  int _duracionSemanas = 4;
  int _diasPorSemana = 3;

  int _semanaActiva = 0;
  final Map<int, Map<int, List<_EjercicioPlan>>> _estructura = {};

  static const _todosObjetivos = [
    'fitness_general',
    'perder_peso',
    'ganar_masa',
    'fuerza',
    'resistencia',
    'movilidad',
    'mixto',
  ];

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
      setState(() => _objetivo = perfil.objetivoPrincipal);
    }
  }

  String _formatearObjetivo(String o) {
    return o
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _sanitizarObjetivo(String o) {
    final l = o.toLowerCase().trim();
    if (_todosObjetivos.contains(l)) return l;
    const mapeo = {
      'hipertrofia': 'ganar_masa',
      'ganancia_muscular': 'ganar_masa',
      'perdida_de_peso': 'perder_peso',
      'bajar_de_peso': 'perder_peso',
      'cardio': 'resistencia',
      'flexibilidad': 'movilidad',
      'general': 'fitness_general',
    };
    return mapeo[l] ?? 'fuerza';
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

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Nueva rutina',
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today_rounded,
                      size: 14, color: const Color(0xFF7C3AED)),
                  const SizedBox(width: 6),
                  Text(
                    'Personalizando ejercicios',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED)),
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

    if (_loadingIA) {
      return _buildPantallaGeneracion(theme);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.fitness_center_rounded,
            size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text('Paso 1 — Define tu rutina',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Nombre, objetivo y duración',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(
          controller: _nombreCtrl,
          textCapitalization: TextCapitalization.sentences,
          autofocus: !widget.autoRecomendar,
          decoration: const InputDecoration(
              labelText: 'Nombre *', hintText: 'ej: Rutina de fuerza'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Descripción (opcional)', alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),
        Text('Objetivo',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _todosObjetivos
              .map((o) => ChoiceChip(
                    label: Text(_formatearObjetivo(o)),
                    selected: _objetivo == o,
                    onSelected: (_) => setState(() => _objetivo = o),
                  ))
              .toList(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Puedes cambiar tu objetivo principal desde tu perfil en la pantalla de inicio.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),
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
          onSelectionChanged: (v) => setState(() => _visibilidad = v.first),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Duración:',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          IconButton(
              onPressed: _duracionSemanas > 1
                  ? () => setState(() => _duracionSemanas--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline)),
          Text('$_duracionSemanas semanas',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          IconButton(
              onPressed: _duracionSemanas < 12
                  ? () => setState(() => _duracionSemanas++)
                  : null,
              icon: const Icon(Icons.add_circle_outline)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Días por semana:',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          IconButton(
              onPressed: _diasPorSemana > 1
                  ? () => setState(() => _diasPorSemana--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline)),
          Text('$_diasPorSemana días',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          IconButton(
              onPressed: _diasPorSemana < 7
                  ? () => setState(() => _diasPorSemana++)
                  : null,
              icon: const Icon(Icons.add_circle_outline)),
        ]),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Atrás'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        const SizedBox(height: 28),
        if (EnvConfig.hasGeminiApiKey) ...[
          OutlinedButton.icon(
            onPressed: _loadingIA ? null : _recomendarRutina,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(_rutinaRecomendada
                ? 'Cambiar rutina con IA'
                : 'Recomendar rutina con IA'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadingIA ? null : _recomendarEjercicios,
            icon: const Icon(Icons.fitness_center, size: 18),
            label: const Text('Recomendar ejercicios'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
    final totalEjercicios = _estructura.values.fold<int>(0,
        (t, dias) => t + dias.values.fold<int>(0, (t2, ej) => t2 + ej.length));
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 48, color: Colors.green),
              const SizedBox(height: 8),
              Text('Revisa tu rutina',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    isDense: true,
                  ),
                ),
              ),
              _resumenFila('Objetivo', _formatearObjetivo(_objetivo)),
              _resumenFila(
                  'Visibilidad',
                  _visibilidad == 'private'
                      ? 'Privada'
                      : _visibilidad == 'friends'
                          ? 'Amigos'
                          : 'Pública'),
              _resumenFila('Duración', '$_duracionSemanas semanas'),
              _resumenFila('Total ejercicios', '$totalEjercicios'),
              const SizedBox(height: 16),
              const Divider(),
              ..._estructura.entries.map((sem) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Semana ${sem.key}',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              ...sem.value.entries.map((dia) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, bottom: 4),
                                    child: Row(children: [
                                      Text('Día ${dia.key}:',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(
                                              dia.value
                                                  .map((e) => e.nombre)
                                                  .join(', '),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis)),
                                    ]),
                                  )),
                            ]),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => setState(() => _paso = 1),
                      child: const Text('Editar'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                onPressed: _creando ? null : _crearRutina,
                child: _creando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Crear rutina'),
              )),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _resumenFila(String label, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey))),
          Expanded(
              child: Text(valor,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );

  Future<void> _recomendarRutina() async {
    setState(() {
      _loadingIA = true;
      _tipoCarga = 'rutina';
    });
    _iniciarSecuenciaMensajes();
    try {
      // Invalidar providers para datos frescos y evitar errores cacheados
      ref.invalidate(perfilBienestarProvider);
      ref.invalidate(ejerciciosProvider);
      ref.invalidate(historialSesionUsuarioProvider);
      ref.invalidate(estadoDiarioHoyProvider);

      // Cargar datos en paralelo: perfil, ejercicios, historial, estado diario
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
                    'Completa tu perfil de bienestar para recibir recomendaciones'),
                duration: Duration(seconds: 2)),
          );
        }
        _terminarCargaIA();
        return;
      }

      final apiKey = EnvConfig.geminiApiKey;
      if (apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Configura GEMINI_API_KEY en el archivo .env'),
                duration: Duration(seconds: 2)),
          );
        }
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

      // Llamada a Gemini
      final servicio = RecomendacionIaService();
      final resultado = await servicio
          .generarRecomendacionRutina(
            apiKey: apiKey,
            perfil: perfil,
            ejerciciosDisponibles: ejercicios,
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

      // Solo autocompletar metadatos, NO ejercicios
      _nombreCtrl.text = resultado.nombre;
      _descCtrl.text = resultado.descripcion;
      _objetivo = _sanitizarObjetivo(resultado.objetivo);
      _duracionSemanas = resultado.duracionSemanas.clamp(1, 12);

      final semanaKeys = resultado.estructura.keys.toList()..sort();
      if (semanaKeys.isNotEmpty) {
        _diasPorSemana =
            resultado.estructura[semanaKeys.first]!.length.clamp(1, 7);
      }

      _detenerMensajesCarga();
      setState(() {
        _loadingIA = false;
        _tipoCarga = '';
        _rutinaRecomendada = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  '¡Rutina recomendada! Configúrala a tu gusto y luego recomienda los ejercicios.'),
              duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        _terminarCargaIA();
        final msg = e is TimeoutException
            ? 'La IA tardó demasiado en responder. Inténtalo de nuevo.'
            : 'Error al generar recomendación. Verifica tu conexión e inténtalo de nuevo.';
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

  Future<void> _recomendarEjercicios() async {
    setState(() {
      _loadingIA = true;
      _tipoCarga = 'ejercicios';
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
                    'Completa tu perfil de bienestar para recibir recomendaciones'),
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

      // Siempre llama a la IA con la configuración ACTUAL de la rutina
      final servicio = RecomendacionIaService();
      final resultado = await servicio
          .generarEstructuraCompleta(
            apiKey: apiKey,
            perfil: perfil,
            ejerciciosDisponibles: ejercicios,
            nombreRutina:
                _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text : 'Rutina',
            descripcionRutina: _descCtrl.text,
            objetivoRutina: _objetivo,
            duracionSemanas: _duracionSemanas,
            diasPorSemana: _diasPorSemana,
            historial: historial,
            estadoDiario: estadoDiario,
          )
          .timeout(const Duration(seconds: 45));

      if (!mounted) return;
      if (!_loadingIA) return; // usuario canceló

      if (resultado.tieneError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(resultado.error!),
              duration: const Duration(seconds: 3)),
        );
        _terminarCargaIA();
        return;
      }

      if (resultado.estructura.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La IA no generó ejercicios. Intenta de nuevo.'),
              duration: Duration(seconds: 2)),
        );
        _terminarCargaIA();
        return;
      }

      _llenarEstructuraDesdeRecomendacion(resultado.estructura, ejercicios);

      _detenerMensajesCarga();
      setState(() {
        _loadingIA = false;
        _tipoCarga = '';
        _ejerciciosRecomendados = true;
        _paso = 1;
      });

      if (mounted) {
        final totalEj = resultado.estructura.values.fold<int>(
            0,
            (t, dias) =>
                t + dias.values.fold<int>(0, (t2, ej) => t2 + ej.length));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '¡$totalEj ejercicios añadidos en ${resultado.estructura.length} semanas! Revisa y ajusta.'),
              duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        _terminarCargaIA();
        final msg = e is TimeoutException
            ? 'La IA tardó demasiado en recomendar ejercicios. Inténtalo de nuevo.'
            : 'Error al recomendar ejercicios. Verifica tu conexión e inténtalo de nuevo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  void _llenarEstructuraDesdeRecomendacion(
      Map<int, Map<int, List<EjercicioRecomendado>>> estructura,
      List<EjercicioDb> ejercicios) {
    _estructura.clear();
    for (final s in estructura.entries) {
      _estructura[s.key] = {};
      for (final d in s.value.entries) {
        _estructura[s.key]![d.key] = d.value.map((e) {
          final match = ejercicios.cast<EjercicioDb?>().firstWhere(
                (ex) => ex?.id == e.ejercicioId,
                orElse: () => null,
              );
          return _EjercicioPlan(
            ejercicioId: match?.id ?? e.ejercicioId,
            nombre: match?.nombre ?? 'Ejercicio recomendado',
            finalidad: match?.finalidadPrincipal ?? FinalidadEjercicio.fuerza,
            urlGif: match?.urlGif,
            series: e.series,
            repeticiones: e.repeticiones,
            segundosDescanso: e.segundosDescanso,
            pesoKg: e.pesoKg,
            duracionSegundos: e.duracionSegundos,
            distanciaMetros: e.distanciaMetros,
            tiempoIsometricoSegundos: e.tiempoIsometricoSegundos,
          );
        }).toList();
      }
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

      // Si es "Sugerir otros" (viene de ejercicios recomendados), limpiar el día
      if (_ejerciciosRecomendados) {
        _estructura[semana]![dia]!.clear();
      }

      for (final rec in resultado.ejercicios) {
        final match = ejercicios.cast<EjercicioDb?>().firstWhere(
              (ex) => ex?.id == rec.ejercicioId,
              orElse: () => null,
            );
        _estructura[semana]![dia]!.add(_EjercicioPlan(
          ejercicioId: match?.id ?? rec.ejercicioId,
          nombre: match?.nombre ?? 'Ejercicio sugerido',
          finalidad: match?.finalidadPrincipal ?? FinalidadEjercicio.fuerza,
          urlGif: match?.urlGif,
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
  const _MiniGifPreview({this.urlGif, this.size = 48});
  final String? urlGif;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          urlGif != null ? () => _mostrarGifAmpliado(context, urlGif!) : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExerciseMediaWidget(
          url: urlGif,
          size: ExerciseMediaSize.mini,
          borderRadius: BorderRadius.circular(8),
          onTap: urlGif != null
              ? () => _mostrarGifAmpliado(context, urlGif!)
              : null,
        ),
      ),
    );
  }

  void _mostrarGifAmpliado(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withValues(alpha: 0.85),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Center(
                  child: url.endsWith('.mp4')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: ExerciseMediaWidget(
                              url: url,
                              size: ExerciseMediaSize.card,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: url,
                          width: 260,
                          height: 260,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
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
            ...widget.ejercicios.asMap().entries.map((entry) =>
                _EjercicioCompacto(
                    ejercicio: entry.value,
                    onRemove: () => widget.onEjercicioRemoved(entry.key),
                    onChanged: (nuevo) =>
                        widget.onEjercicioUpdated(entry.key, nuevo))),
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

  void _mostrarBuscador(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _BuscadorEjerciciosSheet(
          onSelected: (id, nombre, finalidad, urlGif) =>
              widget.onEjercicioAdded(_EjercicioPlan(
                  ejercicioId: id,
                  nombre: nombre,
                  finalidad: FinalidadEjercicio.fromString(finalidad),
                  urlGif: urlGif))),
    );
  }
}

// =============================================================================
class _EjercicioCompacto extends StatefulWidget {
  const _EjercicioCompacto(
      {required this.ejercicio,
      required this.onRemove,
      required this.onChanged});
  final _EjercicioPlan ejercicio;
  final VoidCallback onRemove;
  final void Function(_EjercicioPlan) onChanged;
  @override
  State<_EjercicioCompacto> createState() => _EjercicioCompactoState();
}

class _EjercicioCompactoState extends State<_EjercicioCompacto> {
  late int _series, _reps, _descanso;
  late double? _peso;
  late int? _duracionSegundos;
  late int? _distanciaMetros;
  late int? _tiempoIsometrico;
  final _pesoCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _distanciaCtrl = TextEditingController();
  final _tiempoIsoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _series = widget.ejercicio.series;
    _reps = widget.ejercicio.repeticiones;
    _descanso = widget.ejercicio.segundosDescanso;
    _peso = widget.ejercicio.pesoKg;
    _duracionSegundos = widget.ejercicio.duracionSegundos;
    _distanciaMetros = widget.ejercicio.distanciaMetros;
    _tiempoIsometrico = widget.ejercicio.tiempoIsometricoSegundos;
    _pesoCtrl.text = _peso != null
        ? _peso!.toStringAsFixed(_peso! == _peso!.roundToDouble() ? 0 : 1)
        : '';
    _duracionCtrl.text =
        _duracionSegundos != null ? _fmtDuracion(_duracionSegundos!) : '';
    _distanciaCtrl.text =
        _distanciaMetros != null ? _distanciaMetros.toString() : '';
    _tiempoIsoCtrl.text =
        _tiempoIsometrico != null ? _tiempoIsometrico.toString() : '';
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _duracionCtrl.dispose();
    _distanciaCtrl.dispose();
    _tiempoIsoCtrl.dispose();
    super.dispose();
  }

  void _emit({
    int? s,
    int? r,
    int? d,
    double? p,
    int? dur,
    int? dist,
    int? tIso,
  }) {
    s ??= _series;
    r ??= _reps;
    d ??= _descanso;
    p ??= _peso;
    dur ??= _duracionSegundos;
    dist ??= _distanciaMetros;
    tIso ??= _tiempoIsometrico;
    setState(() {
      _series = s!;
      _reps = r!;
      _descanso = d!;
      _peso = p;
      _duracionSegundos = dur;
      _distanciaMetros = dist;
      _tiempoIsometrico = tIso;
    });
    widget.onChanged(widget.ejercicio.copyWith(
      series: _series,
      repeticiones: _reps,
      segundosDescanso: _descanso,
      pesoKg: _peso,
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
            // ── Nombre del ejercicio + chip de finalidad + GIF ──
            Row(
              children: [
                if (widget.ejercicio.urlGif != null) ...[
                  _MiniGifPreview(urlGif: widget.ejercicio.urlGif, size: 42),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: () => context.push(
                              '/bienestar/ejercicio/${widget.ejercicio.ejercicioId}'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              widget.ejercicio.nombre,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    cs.onSurfaceVariant.withValues(alpha: 0.3),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _finalidadChip(finalidad, cs),
                    ],
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
            const SizedBox(height: 4),
            // ── Campos dinámicos según finalidad ──
            LayoutBuilder(
              builder: (context, constraints) {
                final anchoPill = (constraints.maxWidth - 12) / 2;
                return _buildCamposDinamicos(finalidad, anchoPill, cs);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chip de finalidad (miniatura)
  // ---------------------------------------------------------------------------
  Widget _finalidadChip(FinalidadEjercicio f, ColorScheme cs) {
    Color chipColor;
    switch (f) {
      case FinalidadEjercicio.fuerza:
        chipColor = Colors.orange;
      case FinalidadEjercicio.cardio:
        chipColor = Colors.teal;
      case FinalidadEjercicio.isometrico:
        chipColor = Colors.indigo;
      case FinalidadEjercicio.hipertrofia:
        chipColor = Colors.red;
      case FinalidadEjercicio.resistencia:
        chipColor = Colors.blue;
      case FinalidadEjercicio.movilidad:
        chipColor = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        '${f.icono} ${f.etiqueta}',
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
  Widget _buildCamposDinamicos(
      FinalidadEjercicio f, double anchoPill, ColorScheme cs) {
    switch (f) {
      case FinalidadEjercicio.fuerza:
        return _camposFuerza(anchoPill, cs);
      case FinalidadEjercicio.cardio:
        return _camposCardio(anchoPill, cs);
      case FinalidadEjercicio.isometrico:
        return _camposIsometrico(anchoPill, cs);
      case FinalidadEjercicio.hipertrofia:
      case FinalidadEjercicio.resistencia:
        return _camposFuerza(anchoPill, cs);
      case FinalidadEjercicio.movilidad:
        return _camposIsometrico(anchoPill, cs);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FUERZA: Series, Reps, Descanso, Peso (grid 2×2 original)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _camposFuerza(double anchoPill, ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _paramPill('Series', _series, 1, 10, (v) => _emit(s: v), anchoPill, cs),
        _paramPill('Reps', _reps, 1, 50, (v) => _emit(r: v), anchoPill, cs),
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
  String _fmtDuracion(int segundos) {
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    if (min > 0 && sec > 0) return '${min}m ${sec}s';
    if (min > 0) return '${min} min';
    return '${sec}s';
  }

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
            Text('Peso (kg)',
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

// =============================================================================
class _BuscadorEjerciciosSheet extends StatefulWidget {
  const _BuscadorEjerciciosSheet({required this.onSelected});
  final void Function(
      String id, String nombre, String finalidad, String? urlGif) onSelected;
  @override
  State<_BuscadorEjerciciosSheet> createState() =>
      _BuscadorEjerciciosSheetState();
}

class _BuscadorEjerciciosSheetState extends State<_BuscadorEjerciciosSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Buscar ejercicio...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true),
              onChanged: (v) => setState(() => _q = v.toLowerCase())),
          const SizedBox(height: 8),
          Expanded(child: _buildLista(scrollCtrl)),
        ]),
      ),
    );
  }

  Widget _buildLista(ScrollController scrollCtrl) {
    final client = Supabase.instance.client;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _q.isEmpty
          ? client
              .from('v_ejercicios_completos')
              .select('id, nombre, finalidad, url_gif')
              .limit(50)
              .then((d) => d as List<Map<String, dynamic>>)
          : client
              .from('v_ejercicios_completos')
              .select('id, nombre, finalidad, url_gif')
              .ilike('nombre', '%$_q%')
              .limit(50)
              .then((d) => d as List<Map<String, dynamic>>),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        if (snap.data!.isEmpty)
          return const Center(
              child:
                  Text('Sin resultados', style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          controller: scrollCtrl,
          itemCount: snap.data!.length,
          itemBuilder: (context, i) {
            final e = snap.data![i];
            final eId = e['id'] as String;
            final eNombre = e['nombre'] as String;
            final eFinalidadRaw = e['finalidad'];
            final eFinalidad = (eFinalidadRaw is List && eFinalidadRaw.isNotEmpty)
                ? eFinalidadRaw[0].toString()
                : (eFinalidadRaw is String ? eFinalidadRaw : 'fuerza');
            final eGif = e['url_gif'] as String?;
            return ListTile(
                dense: true,
                leading: _MiniGifPreview(urlGif: eGif),
                title: Text(eNombre, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/bienestar/ejercicio/$eId');
                  },
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () {
                  widget.onSelected(eId, eNombre, eFinalidad, eGif);
                  Navigator.pop(context);
                });
          },
        );
      },
    );
  }
}
