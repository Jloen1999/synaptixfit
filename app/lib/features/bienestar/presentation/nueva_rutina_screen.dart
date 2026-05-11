import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../application/ejercicios_provider.dart';
import '../application/rutina_provider.dart';
import '../infrastructure/recomendacion_ia_service.dart';

// DTO local para el plan de ejercicios durante la creación
class _EjercicioPlan {
  const _EjercicioPlan({
    required this.ejercicioId,
    required this.nombre,
    this.series = 3,
    this.repeticiones = 10,
    this.segundosDescanso = 90,
    this.pesoKg,
  });

  final String ejercicioId;
  final String nombre;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final double? pesoKg;

  _EjercicioPlan copyWith({
    int? series,
    int? repeticiones,
    int? segundosDescanso,
    double? pesoKg,
  }) {
    return _EjercicioPlan(
      ejercicioId: ejercicioId,
      nombre: nombre,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      segundosDescanso: segundosDescanso ?? this.segundosDescanso,
      pesoKg: pesoKg ?? this.pesoKg,
    );
  }

  EjercicioInput toInput() {
    return EjercicioInput(
      ejercicioId: ejercicioId,
      series: series,
      repeticiones: repeticiones,
      segundosDescanso: segundosDescanso,
      pesoKg: pesoKg,
    );
  }
}

class NuevaRutinaScreen extends ConsumerStatefulWidget {
  const NuevaRutinaScreen({super.key});

  @override
  ConsumerState<NuevaRutinaScreen> createState() => _NuevaRutinaScreenState();
}

class _NuevaRutinaScreenState extends ConsumerState<NuevaRutinaScreen> {
  int _paso = 0;
  bool _creando = false;
  bool _loadingIA = false;
  bool _rutinaRecomendada = false;
  bool _ejerciciosRecomendados = false;

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
  ];

  @override
  void initState() {
    super.initState();
    _inicializarEstructura();
    _cargarObjetivoPerfil();
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

  void _inicializarEstructura() {
    _estructura.clear();
    for (var s = 1; s <= _duracionSemanas; s++) {
      _estructura[s] = {};
      for (var d = 1; d <= _diasPorSemana; d++) {
        _estructura[s]![d] = [];
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Nueva rutina',
      backPath: '/bienestar',
      child: _paso == 0
          ? _buildPaso1()
          : _paso == 1
              ? _buildPaso2()
              : _buildPaso3(),
    );
  }

  Widget _buildPaso1() {
    final theme = Theme.of(context);
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
          autofocus: true,
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
        if (EnvConfig.hasGeminiApiKey) ...[
          OutlinedButton.icon(
            onPressed: _loadingIA ? null : _recomendarRutina,
            icon: _loadingIA
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_loadingIA
                ? 'Generando recomendación...'
                : _rutinaRecomendada
                    ? 'Cambiar rutina con IA'
                    : 'Recomendar rutina con IA'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (_rutinaRecomendada) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadingIA ? null : _recomendarEjercicios,
              icon: _loadingIA
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.fitness_center, size: 18),
              label: Text(_loadingIA
                  ? 'Generando ejercicios...'
                  : 'Recomendar ejercicios'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: () {
            if (_nombreCtrl.text.trim().length < 3) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('El nombre debe tener al menos 3 caracteres')));
              return;
            }
            setState(() => _paso = 1);
          },
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Siguiente — Añadir ejercicios'),
        ),
      ],
    );
  }

  Widget _buildPaso2() {
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
              _resumenFila('Objetivo', _objetivo),
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
    setState(() => _loadingIA = true);
    try {
      final perfil = await ref.read(perfilBienestarProvider.future);

      if (perfil == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Completa tu perfil de bienestar para recibir recomendaciones')),
          );
        }
        setState(() => _loadingIA = false);
        return;
      }

      final apiKey = EnvConfig.geminiApiKey;
      if (apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Configura GEMINI_API_KEY en el archivo .env')),
          );
        }
        setState(() => _loadingIA = false);
        return;
      }

      final ejercicios = await ref.read(ejerciciosProvider.future);
      final historial = await ref.read(historialSesionUsuarioProvider.future);
      final estadoDiario = await ref.read(estadoDiarioHoyProvider.future);

      final servicio = RecomendacionIaService();
      final resultado = await servicio.generarRecomendacionRutina(
        apiKey: apiKey,
        perfil: perfil,
        ejerciciosDisponibles: ejercicios,
        historial: historial,
        estadoDiario: estadoDiario,
      );
      if (!mounted) return;

      if (resultado.tieneError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.error!)),
        );
        setState(() => _loadingIA = false);
        return;
      }

      // Solo autocompletar metadatos, NO ejercicios
      _nombreCtrl.text = resultado.nombre;
      _descCtrl.text = resultado.descripcion;
      _objetivo = resultado.objetivo;
      _duracionSemanas = resultado.duracionSemanas.clamp(1, 12);

      final semanaKeys = resultado.estructura.keys.toList()..sort();
      if (semanaKeys.isNotEmpty) {
        _diasPorSemana =
            resultado.estructura[semanaKeys.first]!.length.clamp(1, 7);
      }

      setState(() {
        _loadingIA = false;
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
        setState(() => _loadingIA = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar recomendación: $e')),
        );
      }
    }
  }

  Future<void> _recomendarEjercicios() async {
    setState(() => _loadingIA = true);
    try {
      final perfil = await ref.read(perfilBienestarProvider.future);
      final ejercicios = await ref.read(ejerciciosProvider.future);
      final historial = await ref.read(historialSesionUsuarioProvider.future);
      final estadoDiario = await ref.read(estadoDiarioHoyProvider.future);

      if (perfil == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Completa tu perfil de bienestar para recibir recomendaciones')),
          );
        }
        setState(() => _loadingIA = false);
        return;
      }

      final apiKey = EnvConfig.geminiApiKey;
      if (apiKey.isEmpty) {
        setState(() => _loadingIA = false);
        return;
      }

      // Siempre llama a la IA con la configuración ACTUAL de la rutina
      final servicio = RecomendacionIaService();
      final resultado = await servicio.generarEstructuraCompleta(
        apiKey: apiKey,
        perfil: perfil,
        ejerciciosDisponibles: ejercicios,
        nombreRutina: _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text : 'Rutina',
        descripcionRutina: _descCtrl.text,
        objetivoRutina: _objetivo,
        duracionSemanas: _duracionSemanas,
        diasPorSemana: _diasPorSemana,
        historial: historial,
        estadoDiario: estadoDiario,
      );

      if (!mounted) return;

      if (resultado.tieneError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.error!)),
        );
        setState(() => _loadingIA = false);
        return;
      }

      if (resultado.estructura.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La IA no generó ejercicios. Intenta de nuevo.')),
        );
        setState(() => _loadingIA = false);
        return;
      }

      _llenarEstructuraDesdeRecomendacion(resultado.estructura, ejercicios);

      setState(() {
        _loadingIA = false;
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
        setState(() => _loadingIA = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al recomendar ejercicios: $e')),
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
                (ex) => (ex?.exerciseDbId ?? ex?.id) == e.ejercicioId,
                orElse: () => null,
              );
          return _EjercicioPlan(
            ejercicioId: match?.id ?? e.ejercicioId,
            nombre: match?.nombre ?? 'Ejercicio recomendado',
            series: e.series,
            repeticiones: e.repeticiones,
            segundosDescanso: e.segundosDescanso,
            pesoKg: e.pesoKg,
          );
        }).toList();
      }
    }
  }

  Future<void> _sugerirEjerciciosIA(int semana, int dia) async {
    setState(() => _loadingIA = true);
    try {
      final perfil = await ref.read(perfilBienestarProvider.future);
      final ejercicios = await ref.read(ejerciciosProvider.future);
      final historial = await ref.read(historialSesionUsuarioProvider.future);
      final estadoDiario = await ref.read(estadoDiarioHoyProvider.future);

      if (perfil == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Completa tu perfil de bienestar para recibir sugerencias')),
          );
        }
        setState(() => _loadingIA = false);
        return;
      }

      final apiKey = EnvConfig.geminiApiKey;
      if (apiKey.isEmpty) {
        setState(() => _loadingIA = false);
        return;
      }

      final ejerciciosActuales =
          _estructura[semana]![dia]!.map((e) => e.ejercicioId).toList();

      final servicio = RecomendacionIaService();
      final resultado = await servicio.generarRecomendacionEjercicios(
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
      );

      if (!mounted) return;

      if (resultado.tieneError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.error!)),
        );
        setState(() => _loadingIA = false);
        return;
      }

      if (resultado.ejercicios.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se encontraron ejercicios para recomendar')),
        );
        setState(() => _loadingIA = false);
        return;
      }

      // Si es "Sugerir otros" (viene de ejercicios recomendados), limpiar el día
      if (_ejerciciosRecomendados) {
        _estructura[semana]![dia]!.clear();
      }

      for (final rec in resultado.ejercicios) {
        final match = ejercicios.cast<EjercicioDb?>().firstWhere(
              (ex) => (ex?.exerciseDbId ?? ex?.id) == rec.ejercicioId,
              orElse: () => null,
            );
        _estructura[semana]![dia]!.add(_EjercicioPlan(
          ejercicioId: match?.id ?? rec.ejercicioId,
          nombre: match?.nombre ?? 'Ejercicio sugerido',
          series: rec.series,
          repeticiones: rec.repeticiones,
          segundosDescanso: rec.segundosDescanso,
          pesoKg: rec.pesoKg,
        ));
      }
      setState(() => _loadingIA = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${resultado.ejercicios.length} ejercicios sugeridos añadidos al Día $dia')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingIA = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sugerir ejercicios: $e')),
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
          onSelected: (id, nombre) => widget.onEjercicioAdded(
              _EjercicioPlan(ejercicioId: id, nombre: nombre))),
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

  @override
  void initState() {
    super.initState();
    _series = widget.ejercicio.series;
    _reps = widget.ejercicio.repeticiones;
    _descanso = widget.ejercicio.segundosDescanso;
    _peso = widget.ejercicio.pesoKg;
  }

  void _emit({int? s, int? r, int? d, double? p}) {
    s ??= _series;
    r ??= _reps;
    d ??= _descanso;
    p ??= _peso;
    setState(() {
      _series = s!;
      _reps = r!;
      _descanso = d!;
      _peso = p;
    });
    widget.onChanged(widget.ejercicio.copyWith(
        series: _series,
        repeticiones: _reps,
        segundosDescanso: _descanso,
        pesoKg: _peso));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
            flex: 2,
            child: InkWell(
                onTap: () => context.push(
                    '/bienestar/ejercicio/${widget.ejercicio.ejercicioId}'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(widget.ejercicio.nombre,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ))),
        _s(_series, 1, 10, (v) => _emit(s: v)),
        const Text('×', style: TextStyle(fontSize: 10, color: Colors.grey)),
        _s(_reps, 1, 50, (v) => _emit(r: v)),
        const SizedBox(width: 4),
        _s(_descanso, 15, 300, (v) => _emit(d: v), sufijo: 's'),
        const SizedBox(width: 4),
        SizedBox(
            width: 36,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9),
              controller:
                  TextEditingController(text: _peso?.toStringAsFixed(1) ?? ''),
              decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 1, vertical: 4),
                  border: OutlineInputBorder(),
                  hintText: 'kg',
                  hintStyle: TextStyle(fontSize: 8)),
              onChanged: (v) => _emit(p: double.tryParse(v)),
            )),
        IconButton(
            icon: const Icon(Icons.close, size: 14, color: Colors.red),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20)),
      ]),
    );
  }

  Widget _s(int val, int min, int max, void Function(int) onChange,
      {String sufijo = ''}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
          onTap: val > min ? () => onChange(val - 1) : null,
          child: Icon(Icons.remove,
              size: 11, color: val > min ? Colors.grey : Colors.grey.shade300)),
      Text('$val$sufijo',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      InkWell(
          onTap: val < max ? () => onChange(val + 1) : null,
          child: Icon(Icons.add,
              size: 11, color: val < max ? Colors.grey : Colors.grey.shade300)),
    ]);
  }
}

// =============================================================================
class _BuscadorEjerciciosSheet extends StatefulWidget {
  const _BuscadorEjerciciosSheet({required this.onSelected});
  final void Function(String id, String nombre) onSelected;
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
              .select('id, nombre')
              .limit(50)
              .then((d) => d as List<Map<String, dynamic>>)
          : client
              .from('v_ejercicios_completos')
              .select('id, nombre')
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
            return ListTile(
                dense: true,
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
                  widget.onSelected(eId, eNombre);
                  Navigator.pop(context);
                });
          },
        );
      },
    );
  }
}
