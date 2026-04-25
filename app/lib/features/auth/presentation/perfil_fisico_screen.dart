import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../infrastructure/bienestar_repository.dart';
import '../infrastructure/objetivo_ia_service.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/sv_primary_button.dart';

class PerfilFisicoScreen extends StatefulWidget {
  const PerfilFisicoScreen({super.key});

  @override
  State<PerfilFisicoScreen> createState() => _PerfilFisicoScreenState();
}

class _PerfilFisicoScreenState extends State<PerfilFisicoScreen> {
  static const _etapas = [
    'Datos demográficos',
    'Peso y altura',
    'Actividad y objetivos',
    'Disponibilidad y equipamiento',
  ];

  final _edadCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _objetivoIaService = ObjetivoIaService();
  final _bienestarRepository = const BienestarRepository();

  int _step = 0;
  String? _sexoSeleccionado;
  String? _nivelActividadSeleccionado;
  String? _objetivoPrincipal;
  int _diasDisponibles = 3;
  int _minutosPorSesion = 45;
  final Set<String> _equipamientoSeleccionado = {};
  bool _cargandoSugerencias = false;
  bool _mostrarSugerencias = true;
  bool _guardando = false;
  List<String> _sugerenciasIa = const [];

  static const _equipamientoOpciones = [
    {'valor': 'peso_corporal', 'label': 'Peso corporal', 'icono': Icons.accessibility_new_rounded},
    {'valor': 'mancuerna', 'label': 'Mancuernas', 'icono': Icons.fitness_center_rounded},
    {'valor': 'barra', 'label': 'Barra', 'icono': Icons.sports_gymnastics_rounded},
    {'valor': 'banda_elastica', 'label': 'Bandas elásticas', 'icono': Icons.cable_rounded},
    {'valor': 'kettlebell', 'label': 'Kettlebell', 'icono': Icons.sports_martial_arts_rounded},
    {'valor': 'polea', 'label': 'Polea / Cable', 'icono': Icons.settings_input_component_rounded},
    {'valor': 'maquina', 'label': 'Máquinas', 'icono': Icons.precision_manufacturing_rounded},
    {'valor': 'medicina_ball', 'label': 'Balón medicinal', 'icono': Icons.sports_baseball_rounded},
  ];

  static const _objetivosOpciones = [
    {'valor': 'fitness_general', 'label': 'Fitness general'},
    {'valor': 'perder_peso', 'label': 'Perder peso'},
    {'valor': 'ganar_masa', 'label': 'Ganar masa muscular'},
    {'valor': 'fuerza', 'label': 'Aumentar fuerza'},
    {'valor': 'resistencia', 'label': 'Mejorar resistencia'},
    {'valor': 'movilidad', 'label': 'Mejorar movilidad'},
  ];

  double? get _imcActual {
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
    final alturaCm = double.tryParse(_alturaCtrl.text.replaceAll(',', '.'));
    if (peso == null || alturaCm == null || peso <= 0 || alturaCm <= 0) {
      return null;
    }

    final alturaM = alturaCm / 100;
    if (alturaM <= 0) return null;
    return peso / (alturaM * alturaM);
  }

  String get _imcTexto {
    final imc = _imcActual;
    if (imc == null) return '--';
    return imc.toStringAsFixed(1);
  }

  String get _imcCategoria {
    final imc = _imcActual;
    if (imc == null) return '';
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  @override
  void dispose() {
    _edadCtrl.dispose();
    _ciudadCtrl.dispose();
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _objetivoCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoracionCampo(String labelText, {Widget? prefixIcon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLowest,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      floatingLabelAlignment: FloatingLabelAlignment.start,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validaciones por paso
  // ---------------------------------------------------------------------------
  String? _validarPasoActual() {
    switch (_step) {
      case 0: // Datos demográficos
        final edad = int.tryParse(_edadCtrl.text);
        if (edad == null || edad < 15 || edad > 80) {
          return 'La edad debe estar entre 15 y 80 años';
        }
        if (_sexoSeleccionado == null) {
          return 'Selecciona una opción de sexo';
        }
        return null;

      case 1: // Peso y altura
        final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
        if (peso == null || peso < 30 || peso > 200) {
          return 'El peso debe estar entre 30 y 200 kg';
        }
        final altura = double.tryParse(_alturaCtrl.text.replaceAll(',', '.'));
        if (altura == null || altura < 140 || altura > 220) {
          return 'La altura debe estar entre 140 y 220 cm';
        }
        return null;

      case 2: // Actividad y objetivos
        if (_nivelActividadSeleccionado == null) {
          return 'Selecciona tu nivel de actividad';
        }
        if (_objetivoPrincipal == null && _objetivoCtrl.text.isEmpty) {
          return 'Define tu objetivo principal';
        }
        return null;

      case 3: // Disponibilidad
        // No hay validación obligatoria, todos tienen defaults
        return null;

      default:
        return null;
    }
  }

  Future<void> _cargarSugerenciasObjetivo() async {
    if (_cargandoSugerencias) return;

    if (!EnvConfig.hasGeminiApiKey) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró GEMINI_API_KEY en .env'),
        ),
      );
      return;
    }

    setState(() => _cargandoSugerencias = true);

    final result = await _objetivoIaService.generarSugerencias(
      apiKey: EnvConfig.geminiApiKey,
      edad: _edadCtrl.text,
      sexo: _sexoSeleccionado,
      nivelActividad: _nivelActividadSeleccionado,
      ciudad: _ciudadCtrl.text,
    );

    if (!mounted) return;

    setState(() {
      _cargandoSugerencias = false;
      _sugerenciasIa = result.sugerencias;
      _mostrarSugerencias = true;
    });

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  Future<void> _avanzarPaso() async {
    // Validar paso actual
    final error = _validarPasoActual();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_step < _etapas.length - 1) {
      setState(() => _step++);
      return;
    }

    // Último paso: guardar y navegar
    await _guardarYNavegar();
  }

  Future<void> _guardarYNavegar() async {
    setState(() => _guardando = true);

    try {
      final objetivo = _objetivoPrincipal ?? _objetivoCtrl.text;
      final objetivoFinal = _objetivosOpciones.any((o) => o['valor'] == objetivo)
          ? objetivo
          : 'fitness_general';

      await _bienestarRepository.guardarPerfilBienestar(
        edad: int.parse(_edadCtrl.text),
        sexo: _sexoSeleccionado!,
        ciudad: _ciudadCtrl.text.isEmpty ? null : _ciudadCtrl.text,
        pesoKg: double.parse(_pesoCtrl.text.replaceAll(',', '.')),
        alturaCm: double.parse(_alturaCtrl.text.replaceAll(',', '.')),
        nivelActividad: _nivelActividadSeleccionado ?? 'sedentario',
        objetivoPrincipal: objetivoFinal,
        equipamientoDisponible: _equipamientoSeleccionado.toList(),
        diasDisponiblesSemana: _diasDisponibles,
        minutosPorSesion: _minutosPorSesion,
      );

      await _bienestarRepository.marcarOnboardingCompletado();

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _guardarYNavegar,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _volverPaso() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Perfil Físico y Bienestar Inicial',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgresoPasos(
                  pasoActual: _step,
                  pasos: _etapas,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Stepper(
                      currentStep: _step,
                      onStepTapped: (index) {
                        if (index <= _step) {
                          setState(() => _step = index);
                        }
                      },
                      onStepContinue: _guardando ? null : _avanzarPaso,
                      onStepCancel: _volverPaso,
                      controlsBuilder: (context, details) {
                        final esUltimoPaso = _step == _etapas.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: SVPrimaryButton(
                              label: _guardando
                                  ? 'Guardando...'
                                  : esUltimoPaso
                                      ? 'Finalizar y continuar'
                                      : 'Guardar y seguir',
                              onPressed:
                                  _guardando ? null : details.onStepContinue,
                            ).animate().fade(duration: 220.ms).slideY(begin: 0.08),
                          ),
                        );
                      },
                      steps: [
                        // --- PASO 0: Datos demográficos ---
                        Step(
                          isActive: _step >= 0,
                          state:
                              _step > 0 ? StepState.complete : StepState.indexed,
                          title: const Text('Datos demográficos'),
                          content: _SeccionPaso(
                            children: [
                              TextField(
                                controller: _edadCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _decoracionCampo(
                                  'Edad (15-80)',
                                  prefixIcon: const Icon(Icons.cake_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _sexoSeleccionado,
                                decoration: _decoracionCampo(
                                  'Sexo',
                                  prefixIcon: const Icon(Icons.wc_rounded),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'hombre', child: Text('Hombre')),
                                  DropdownMenuItem(
                                      value: 'mujer', child: Text('Mujer')),
                                  DropdownMenuItem(
                                      value: 'no_binario',
                                      child: Text('No binario')),
                                  DropdownMenuItem(
                                      value: 'prefiero_no_decirlo',
                                      child: Text('Prefiero no decirlo')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _sexoSeleccionado = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _ciudadCtrl,
                                decoration: _decoracionCampo(
                                  'Ciudad (opcional)',
                                  prefixIcon:
                                      const Icon(Icons.location_city_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // --- PASO 1: Peso y altura ---
                        Step(
                          isActive: _step >= 1,
                          state: _step > 1
                              ? StepState.complete
                              : (_step == 1
                                  ? StepState.editing
                                  : StepState.indexed),
                          title: const Text('Peso y altura'),
                          content: _SeccionPaso(
                            children: [
                              TextField(
                                controller: _pesoCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: _decoracionCampo(
                                  'Peso (30-200 kg)',
                                  prefixIcon:
                                      const Icon(Icons.fitness_center_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _alturaCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: _decoracionCampo(
                                  'Altura (140-220 cm)',
                                  prefixIcon: const Icon(Icons.height_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _imcActual != null
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.28)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.monitor_weight_rounded),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'IMC estimado: $_imcTexto',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          if (_imcCategoria.isNotEmpty)
                                            Text(
                                              _imcCategoria,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // --- PASO 2: Actividad y objetivos ---
                        Step(
                          isActive: _step >= 2,
                          state: _step > 2
                              ? StepState.complete
                              : (_step == 2
                                  ? StepState.editing
                                  : StepState.indexed),
                          title: const Text('Actividad y objetivos'),
                          content: _SeccionPaso(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _nivelActividadSeleccionado,
                                isExpanded: true,
                                decoration: _decoracionCampo(
                                  'Nivel de actividad',
                                  prefixIcon:
                                      const Icon(Icons.directions_run_rounded),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'sedentario',
                                      child: Text('Sedentario')),
                                  DropdownMenuItem(
                                      value: 'ligero', child: Text('Ligero')),
                                  DropdownMenuItem(
                                      value: 'moderado',
                                      child: Text('Moderado')),
                                  DropdownMenuItem(
                                      value: 'alto', child: Text('Alto')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _nivelActividadSeleccionado = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Referencia: Ligero (1-2 días), Moderado (3-4), Alto (5+).',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Objetivo principal',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _objetivosOpciones.map((opt) {
                                  final seleccionado =
                                      _objetivoPrincipal == opt['valor'];
                                  return FilterChip(
                                    label: Text(opt['label'] as String),
                                    selected: seleccionado,
                                    onSelected: (selected) {
                                      setState(() {
                                        _objetivoPrincipal =
                                            selected ? opt['valor'] as String : null;
                                        if (selected) {
                                          _objetivoCtrl.text =
                                              opt['label'] as String;
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final apilar = constraints.maxWidth < 420;
                                  final titulo = Text(
                                    'Sugerencias de IA para tu objetivo',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  );

                                  final acciones = Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: _cargandoSugerencias
                                            ? null
                                            : _cargarSugerenciasObjetivo,
                                        icon: const Icon(
                                            Icons.auto_awesome_rounded),
                                        label: Text(
                                          _cargandoSugerencias
                                              ? 'Generando...'
                                              : 'Generar',
                                        ),
                                      ),
                                      if (_sugerenciasIa.isNotEmpty)
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _mostrarSugerencias =
                                                  !_mostrarSugerencias;
                                            });
                                          },
                                          icon: Icon(
                                            _mostrarSugerencias
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                          ),
                                          label: Text(
                                            _mostrarSugerencias
                                                ? 'Ocultar'
                                                : 'Mostrar',
                                          ),
                                        ),
                                    ],
                                  );

                                  if (apilar) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        titulo,
                                        const SizedBox(height: 6),
                                        acciones,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: titulo),
                                      const SizedBox(width: 8),
                                      Flexible(child: acciones),
                                    ],
                                  );
                                },
                              ),
                              if (_cargandoSugerencias)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child:
                                      LinearProgressIndicator(minHeight: 3),
                                ),
                              if (_sugerenciasIa.isNotEmpty &&
                                  _mostrarSugerencias)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _sugerenciasIa
                                        .map(
                                          (item) => ActionChip(
                                            avatar: const Icon(
                                                Icons
                                                    .tips_and_updates_outlined,
                                                size: 18),
                                            label: Text(item),
                                            onPressed: () {
                                              setState(() {
                                                _objetivoCtrl.text = item;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              TextField(
                                controller: _objetivoCtrl,
                                decoration: _decoracionCampo(
                                  'O escribe tu objetivo libre',
                                  prefixIcon:
                                      const Icon(Icons.flag_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // --- PASO 3: Disponibilidad y equipamiento ---
                        Step(
                          isActive: _step >= 3,
                          state: _step == 3
                              ? StepState.editing
                              : StepState.indexed,
                          title: const Text('Disponibilidad y equipamiento'),
                          content: _SeccionPaso(
                            children: [
                              Text(
                                'Días disponibles por semana',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Row(
                                children: [
                                  Text('$_diasDisponibles',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )),
                                  const SizedBox(width: 4),
                                  Text('días',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  Expanded(
                                    child: Slider(
                                      value: _diasDisponibles.toDouble(),
                                      min: 1,
                                      max: 7,
                                      divisions: 6,
                                      label: '$_diasDisponibles',
                                      onChanged: (v) {
                                        setState(() =>
                                            _diasDisponibles = v.round());
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Minutos por sesión',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Row(
                                children: [
                                  Text('$_minutosPorSesion',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )),
                                  const SizedBox(width: 4),
                                  Text('min',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  Expanded(
                                    child: Slider(
                                      value: _minutosPorSesion.toDouble(),
                                      min: 15,
                                      max: 120,
                                      divisions: 21,
                                      label: '$_minutosPorSesion min',
                                      onChanged: (v) {
                                        setState(() =>
                                            _minutosPorSesion = v.round());
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Equipamiento disponible',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _equipamientoOpciones.map((opt) {
                                  final valor = opt['valor'] as String;
                                  final seleccionado =
                                      _equipamientoSeleccionado
                                          .contains(valor);
                                  return FilterChip(
                                    avatar: Icon(opt['icono'] as IconData,
                                        size: 18),
                                    label: Text(opt['label'] as String),
                                    selected: seleccionado,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _equipamientoSeleccionado
                                              .add(valor);
                                        } else {
                                          _equipamientoSeleccionado
                                              .remove(valor);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 260.ms).slideY(begin: 0.05),
                ),
              ],
            ),
          ),
          // Overlay de loading durante guardado
          if (_guardando)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Guardando tu perfil...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgresoPasos extends StatelessWidget {
  const _ProgresoPasos({required this.pasoActual, required this.pasos});

  final int pasoActual;
  final List<String> pasos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(pasos.length * 2 - 1, (index) {
            if (index.isOdd) {
              final completed = pasoActual > index ~/ 2;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: completed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final completed = pasoActual > stepIndex;
            final active = pasoActual == stepIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: completed || active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: completed || active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: completed
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : Text(
                        '${stepIndex + 1}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: active
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          pasos[pasoActual],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SeccionPaso extends StatelessWidget {
  const _SeccionPaso({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
