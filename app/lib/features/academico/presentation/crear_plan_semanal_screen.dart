import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../core/design_system/sv_colors.dart';
import '../application/asignaturas_provider.dart';
import '../application/planes_estudio_provider.dart';
import '../application/wizard_plan_provider.dart';

class CrearPlanSemanalScreen extends ConsumerStatefulWidget {
  const CrearPlanSemanalScreen({super.key});

  @override
  ConsumerState<CrearPlanSemanalScreen> createState() =>
      _CrearPlanSemanalScreenState();
}

class _CrearPlanSemanalScreenState
    extends ConsumerState<CrearPlanSemanalScreen> {
  static const _pasosLabels = [
    'Entregas',
    'Horario fijo',
    'Estudio',
    'Deporte',
  ];

  static const _pasosSubtitulos = [
    '¿Qué entregas o exámenes tienes?',
    '¿Qué bloques fijos tienes?',
    'Asigna tus bloques de estudio',
    'Añade bloques deportivos',
  ];

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardPlanProvider);
    final theme = Theme.of(context);

    return FeatureScaffold(
      title: 'Crear plan semanal',
      backPath: '/dashboard',
      child: Column(
        children: [
          _StepIndicator(
            pasoActual: wizard.pasoActual,
            labels: _pasosLabels,
          ),
          Expanded(
            child: [
              _buildPaso1(wizard),
              _buildPaso2(wizard),
              _buildPaso3(wizard, theme),
              _buildPaso4(wizard, theme),
            ][wizard.pasoActual],
          ),
          _buildNavegacion(wizard, theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Paso 1: Entregas y exámenes
  // ---------------------------------------------------------------------------
  Widget _buildPaso1(WizardPlanState wizard) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_pasosSubtitulos[0],
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        if (wizard.entregas.isEmpty)
          _emptyCard(Icons.assignment_outlined, 'Sin entregas añadidas')
        else
          ...wizard.entregas.asMap().entries.map((e) => _EntregaCard(
                entrega: e.value,
                onDelete: () =>
                    ref.read(wizardPlanProvider.notifier).removeEntrega(e.key),
              )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _mostrarDialogoEntrega(),
          icon: const Icon(Icons.add),
          label: const Text('Añadir entrega o examen'),
        ),
      ],
    );
  }

  // Paso 2: Horario fijo
  Widget _buildPaso2(WizardPlanState wizard) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_pasosSubtitulos[1],
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        if (wizard.horarioFijo.isEmpty)
          _emptyCard(Icons.schedule_outlined, 'Sin bloques fijos')
        else
          ...wizard.horarioFijo.asMap().entries.map((e) => _BloqueFijoCard(
                bloque: e.value,
                onDelete: () => ref
                    .read(wizardPlanProvider.notifier)
                    .removeHorarioFijo(e.key),
              )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _mostrarDialogoBloqueFijo(),
          icon: const Icon(Icons.add),
          label: const Text('Añadir bloque fijo'),
        ),
      ],
    );
  }

  // Paso 3: Bloques de estudio
  Widget _buildPaso3(WizardPlanState wizard, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_pasosSubtitulos[2],
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (wizard.cargandoSugerencias)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (wizard.errorSugerencia != null)
          _errorCard(wizard.errorSugerencia!)
        else if (wizard.bloquesEstudio.isEmpty)
          _emptyCard(Icons.menu_book_outlined, 'Sin bloques de estudio')
        else ...[
          const SizedBox(height: 8),
          ...wizard.bloquesEstudio.asMap().entries.map((e) {
            final b = e.value;
            return _SugerenciaCard(
              bloque: b,
              color: theme.colorScheme.primary,
              onAccept: () => ref
                  .read(wizardPlanProvider.notifier)
                  .acceptSugerenciaEstudio(e.key),
              onDelete: () => ref
                  .read(wizardPlanProvider.notifier)
                  .removeSugerenciaEstudio(e.key),
              onEdit: () =>
                  _mostrarDialogoBloqueEstudio(editar: b, index: e.key),
            );
          }),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: wizard.cargandoSugerencias
                    ? null
                    : () => ref
                        .read(wizardPlanProvider.notifier)
                        .generarSugerenciasEstudio(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Sugerir con IA'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _mostrarDialogoBloqueEstudio(),
                icon: const Icon(Icons.add),
                label: const Text('Añadir manual'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Paso 4: Bloques deportivos
  Widget _buildPaso4(WizardPlanState wizard, ThemeData theme) {
    final totalEstudio =
        wizard.bloquesEstudio.where((b) => b.aceptado).fold<double>(0, (t, b) {
      final hi = int.parse(b.horaInicio.split(':')[0]);
      final mi = int.parse(b.horaInicio.split(':')[1]);
      final hf = int.parse(b.horaFin.split(':')[0]);
      final mf = int.parse(b.horaFin.split(':')[1]);
      return t + ((hf * 60 + mf) - (hi * 60 + mi)) / 60.0;
    });

    final totalDeporte =
        wizard.bloquesDeporte.where((b) => b.aceptado).fold<double>(0, (t, b) {
      final hi = int.parse(b.horaInicio.split(':')[0]);
      final mi = int.parse(b.horaInicio.split(':')[1]);
      final hf = int.parse(b.horaFin.split(':')[0]);
      final mf = int.parse(b.horaFin.split(':')[1]);
      return t + ((hf * 60 + mf) - (hi * 60 + mi)) / 60.0;
    });

    final estadoBalance = totalDeporte == 0 ? 'carga_estudio' : 'equilibrado';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_pasosSubtitulos[3],
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _BalanceCard(
          estudio: totalEstudio,
          deporte: totalDeporte,
          estado: estadoBalance,
        ),
        const SizedBox(height: 16),
        if (wizard.cargandoSugerencias)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (wizard.bloquesDeporte.isEmpty)
          _emptyCard(Icons.fitness_center_outlined, 'Sin bloques deportivos')
        else
          ...wizard.bloquesDeporte.asMap().entries.map((e) {
            final b = e.value;
            return _SugerenciaCard(
              bloque: b,
              color: const Color(0xFF00ACC1),
              onAccept: () => ref
                  .read(wizardPlanProvider.notifier)
                  .acceptSugerenciaDeporte(e.key),
              onDelete: () => ref
                  .read(wizardPlanProvider.notifier)
                  .removeSugerenciaDeporte(e.key),
            );
          }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: wizard.cargandoSugerencias
                    ? null
                    : () => ref
                        .read(wizardPlanProvider.notifier)
                        .generarSugerenciasDeporte(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Sugerir con IA'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _mostrarDialogoBloqueDeporte(),
                icon: const Icon(Icons.add),
                label: const Text('Añadir manual'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Navegación
  // ---------------------------------------------------------------------------
  Widget _buildNavegacion(WizardPlanState wizard, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (wizard.pasoActual > 0)
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(wizardPlanProvider.notifier).anteriorPaso(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
              )
            else
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
            const Spacer(),
            if (wizard.pasoActual < 3)
              FilledButton.icon(
                onPressed: () =>
                    ref.read(wizardPlanProvider.notifier).siguientePaso(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Siguiente'),
              )
            else
              FilledButton.icon(
                onPressed: () => _confirmarCrear(wizard),
                icon: const Icon(Icons.check),
                label: const Text('Crear plan'),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Diálogos
  // ---------------------------------------------------------------------------
  void _mostrarDialogoEntrega() {
    String titulo = '';
    String tipo = 'examen';
    String dificultad = 'media';
    String? asignaturaId;
    DateTime fechaLimite = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final asignaturasAsync = ref.watch(asignaturasActivasProvider);
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Título'),
                    autofocus: true,
                    onChanged: (v) => titulo = v,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['examen', 'entrega', 'presentacion', 'otro']
                        .map((t) => ChoiceChip(
                              label: Text(_tipoLabel(t)),
                              selected: tipo == t,
                              onSelected: (_) => setSheet(() => tipo = t),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  asignaturasAsync.when(
                    data: (asigs) => DropdownButtonFormField<String?>(
                      initialValue: asignaturaId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Asignatura'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Sin asignatura')),
                        ...asigs.map((a) => DropdownMenuItem(
                            value: a.id, child: Text(a.nombre))),
                      ],
                      onChanged: (v) => setSheet(() => asignaturaId = v),
                    ),
                    loading: () =>
                        const CircularProgressIndicator(strokeWidth: 2),
                    error: (_, __) => const Text('Error al cargar'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: fechaLimite,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setSheet(() => fechaLimite = d);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Fecha límite'),
                            child: Text(
                                DateFormat('dd/MM/yyyy').format(fechaLimite)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: dificultad,
                          decoration:
                              const InputDecoration(labelText: 'Dificultad'),
                          items: ['baja', 'media', 'alta']
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text(_dificultadLabel(d))))
                              .toList(),
                          onChanged: (v) => setSheet(() => dificultad = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: titulo.trim().isEmpty
                        ? null
                        : () {
                            ref.read(wizardPlanProvider.notifier).addEntrega(
                                  EntregaWizard(
                                    titulo: titulo.trim(),
                                    tipo: tipo,
                                    dificultad: dificultad,
                                    fechaLimite: fechaLimite,
                                    asignaturaId: asignaturaId,
                                    asignaturaNombre: null,
                                  ),
                                );
                            Navigator.pop(ctx);
                          },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoBloqueFijo() {
    int diaSemana = DateTime.now().weekday;
    String horaInicio = '09:00';
    String horaFin = '10:30';
    String nombre = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Nombre o asignatura'),
                    autofocus: true,
                    onChanged: (v) => nombre = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'Inicio',
                          value: horaInicio,
                          onChanged: (v) => setSheet(() => horaInicio = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeField(
                          label: 'Fin',
                          value: horaFin,
                          onChanged: (v) => setSheet(() => horaFin = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Día', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(7, (i) {
                        final d = i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(_diaLabel(d)),
                            selected: diaSemana == d,
                            onSelected: (_) => setSheet(() => diaSemana = d),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: nombre.trim().isEmpty
                        ? null
                        : () {
                            ref
                                .read(wizardPlanProvider.notifier)
                                .addHorarioFijo(BloqueWizard(
                                  diaSemana: diaSemana,
                                  horaInicio: horaInicio,
                                  horaFin: horaFin,
                                  asignaturaNombre: nombre.trim(),
                                  tipoActividad: 'clase',
                                  esClaseFija: true,
                                ));
                            Navigator.pop(ctx);
                          },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoBloqueEstudio({BloqueWizard? editar, int? index}) {
    int diaSemana = DateTime.now().weekday;
    String horaInicio = '16:00';
    String horaFin = '17:30';
    String? asignaturaId;
    String? asignaturaNombre;
    String? temas;

    if (editar != null) {
      diaSemana = editar.diaSemana;
      horaInicio = editar.horaInicio;
      horaFin = editar.horaFin;
      asignaturaId = editar.asignaturaId;
      asignaturaNombre = editar.asignaturaNombre;
      temas = editar.temas;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final asignaturasAsync = ref.watch(asignaturasActivasProvider);
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  asignaturasAsync.when(
                    data: (asigs) => DropdownButtonFormField<String?>(
                      initialValue: asignaturaId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Asignatura'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Sin asignatura')),
                        ...asigs.map((a) => DropdownMenuItem(
                            value: a.id, child: Text(a.nombre))),
                      ],
                      onChanged: (v) => setSheet(() => asignaturaId = v),
                    ),
                    loading: () =>
                        const CircularProgressIndicator(strokeWidth: 2),
                    error: (_, __) => const Text('Error al cargar'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'Inicio',
                          value: horaInicio,
                          onChanged: (v) => setSheet(() => horaInicio = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeField(
                          label: 'Fin',
                          value: horaFin,
                          onChanged: (v) => setSheet(() => horaFin = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Día', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(7, (i) {
                        final d = i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(_diaLabel(d)),
                            selected: diaSemana == d,
                            onSelected: (_) => setSheet(() => diaSemana = d),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                        labelText: 'Temas a repasar (opcional)'),
                    onChanged: (v) => temas = v,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final bloque = BloqueWizard(
                        diaSemana: diaSemana,
                        horaInicio: horaInicio,
                        horaFin: horaFin,
                        asignaturaId: asignaturaId,
                        asignaturaNombre: asignaturaNombre,
                        tipoActividad: 'estudio',
                        temas: temas?.trim().isNotEmpty == true
                            ? temas?.trim()
                            : null,
                      );

                      if (editar != null && index != null) {
                        ref
                            .read(wizardPlanProvider.notifier)
                            .removeSugerenciaEstudio(index);
                      }
                      ref
                          .read(wizardPlanProvider.notifier)
                          .addBloqueEstudioManual(bloque);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoBloqueDeporte() {
    int diaSemana = DateTime.now().weekday;
    String horaInicio = '17:00';
    String horaFin = '18:00';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'Inicio',
                          value: horaInicio,
                          onChanged: (v) => setSheet(() => horaInicio = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeField(
                          label: 'Fin',
                          value: horaFin,
                          onChanged: (v) => setSheet(() => horaFin = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Día', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(7, (i) {
                        final d = i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(_diaLabel(d)),
                            selected: diaSemana == d,
                            onSelected: (_) => setSheet(() => diaSemana = d),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(wizardPlanProvider.notifier)
                          .addBloqueDeporteManual(
                            BloqueWizard(
                              diaSemana: diaSemana,
                              horaInicio: horaInicio,
                              horaFin: horaFin,
                              tipoActividad: 'deporte',
                            ),
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmarCrear(WizardPlanState wizard) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear plan semanal'),
        content: Text(
          'Se crearán ${wizard.entregas.length} entregas, '
          '${wizard.horarioFijo.length} bloques fijos, '
          '${wizard.bloquesEstudio.where((b) => b.aceptado).length} bloques de estudio '
          'y ${wizard.bloquesDeporte.where((b) => b.aceptado).length} bloques deportivos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final now = DateTime.now();
    final lunes = now.subtract(Duration(days: now.weekday - 1));
    final domingo = lunes.add(const Duration(days: 6));

    final entregas = wizard.entregas
        .map((e) => {
              'titulo': e.titulo,
              'tipo': e.tipo,
              'fecha_limite': e.fechaLimite.toIso8601String(),
              'dificultad': e.dificultad,
              if (e.asignaturaId != null) 'asignatura_id': e.asignaturaId,
            })
        .toList();

    final bloques = <Map<String, dynamic>>[];
    for (final b in wizard.horarioFijo) {
      bloques.add({
        'dia_semana': b.diaSemana,
        'hora_inicio': b.horaInicio,
        'hora_fin': b.horaFin,
        'tipo_actividad': 'clase',
        'prioridad': 'alta',
      });
    }
    for (final b in wizard.bloquesEstudio.where((b) => b.aceptado)) {
      bloques.add({
        'dia_semana': b.diaSemana,
        'hora_inicio': b.horaInicio,
        'hora_fin': b.horaFin,
        'tipo_actividad': 'estudio',
        if (b.asignaturaId != null) 'asignatura_id': b.asignaturaId,
        if (b.temas != null) 'temas': b.temas,
      });
    }
    for (final b in wizard.bloquesDeporte.where((b) => b.aceptado)) {
      bloques.add({
        'dia_semana': b.diaSemana,
        'hora_inicio': b.horaInicio,
        'hora_fin': b.horaFin,
        'tipo_actividad': 'deporte',
        if (b.rutinaId != null) 'rutina_id': b.rutinaId,
      });
    }

    final planId = await crearPlanCompleto(
      nombre: 'Plan ${DateFormat('dd/MM', 'es').format(lunes)}',
      semanaInicio: lunes,
      semanaFin: domingo,
      visibilidad: 'privado',
      entregas: entregas,
      bloques: bloques,
    );

    if (planId != null && mounted) {
      ref.read(wizardPlanProvider.notifier).setPlanId(planId);
      ref.invalidate(planesEstudioProvider);
      ref.read(wizardPlanProvider.notifier).reset();
      if (mounted) context.go('/plan-semanal');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static String _diaLabel(int d) {
    return ['L', 'M', 'X', 'J', 'V', 'S', 'D'][d - 1];
  }

  static String _tipoLabel(String t) {
    return {
          'examen': 'Examen',
          'entrega': 'Entrega',
          'presentacion': 'Presentación',
          'otro': 'Otro'
        }[t] ??
        t;
  }

  static String _dificultadLabel(String d) {
    return {'baja': 'Baja', 'media': 'Media', 'alta': 'Alta'}[d] ?? d;
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.pasoActual, required this.labels});

  final int pasoActual;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final completado = i < pasoActual;
          final activo = i == pasoActual;
          final color = completado || activo
              ? theme.colorScheme.primary
              : SVColors.onSurfaceMuted.withValues(alpha: 0.3);
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(child: Container(height: 2, color: color)),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activo
                            ? theme.colorScheme.primary
                            : completado
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.2)
                                : SVColors.onSurfaceMuted
                                    .withValues(alpha: 0.1),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: completado
                            ? Icon(Icons.check,
                                size: 14, color: theme.colorScheme.primary)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                      ),
                    ),
                    if (i < labels.length - 1)
                      Expanded(child: Container(height: 2, color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                      color: color),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

Widget _emptyCard(IconData icon, String message) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: SVColors.onSurfaceMuted.withValues(alpha: 0.2)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: SVColors.onSurfaceMuted.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(color: SVColors.onSurfaceMuted)),
        ],
      ),
    ),
  );
}

Widget _errorCard(String error) {
  return Card(
    elevation: 0,
    color: Colors.red.shade50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
              child: Text(error,
                  style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    ),
  );
}

class _EntregaCard extends StatelessWidget {
  const _EntregaCard({required this.entrega, this.onDelete});
  final EntregaWizard entrega;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(
          entrega.tipo == 'examen'
              ? Icons.quiz_outlined
              : Icons.assignment_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(entrega.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
          '${_dificultadLabel(entrega.dificultad)} · ${DateFormat('dd/MM').format(entrega.fechaLimite)}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _BloqueFijoCard extends StatelessWidget {
  const _BloqueFijoCard({required this.bloque, this.onDelete});
  final BloqueWizard bloque;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.school_outlined, color: Colors.purple),
        title: Text(bloque.asignaturaNombre ?? 'Sin nombre',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
          '${_diaLabel(bloque.diaSemana)} ${bloque.horaInicio}-${bloque.horaFin}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _SugerenciaCard extends StatelessWidget {
  const _SugerenciaCard({
    required this.bloque,
    required this.color,
    this.onAccept,
    this.onDelete,
    this.onEdit,
  });
  final BloqueWizard bloque;
  final Color color;
  final VoidCallback? onAccept;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: bloque.aceptado
              ? color.withValues(alpha: 0.3)
              : SVColors.onSurfaceMuted.withValues(alpha: 0.15),
        ),
      ),
      color: bloque.aceptado
          ? null
          : SVColors.onSurfaceMuted.withValues(alpha: 0.03),
      child: ListTile(
        leading: Icon(
          bloque.tipoActividad == 'deporte'
              ? Icons.fitness_center_rounded
              : Icons.menu_book_rounded,
          color: bloque.aceptado ? color : SVColors.onSurfaceMuted,
        ),
        title: Text(
          bloque.tipoActividad == 'deporte'
              ? (bloque.rutinaNombre ?? 'Entrenamiento')
              : (bloque.asignaturaNombre ?? 'Estudio'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: bloque.aceptado ? null : SVColors.onSurfaceMuted,
          ),
        ),
        subtitle: Text(
          '${_diaLabel(bloque.diaSemana)} ${bloque.horaInicio}-${bloque.horaFin}${bloque.temas != null ? ' · ${bloque.temas}' : ''}',
          style: TextStyle(
            fontSize: 11,
            color: bloque.aceptado ? null : SVColors.onSurfaceMuted,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: onEdit,
              ),
            if (onAccept != null)
              IconButton(
                icon: Icon(
                  bloque.aceptado
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  size: 18,
                  color: bloque.aceptado ? color : SVColors.onSurfaceMuted,
                ),
                onPressed: onAccept,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.estudio,
    required this.deporte,
    required this.estado,
  });

  final double estudio;
  final double deporte;
  final String estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = estado == 'equilibrado' ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Icon(
                  estado == 'equilibrado'
                      ? Icons.balance_rounded
                      : Icons.warning_amber_rounded,
                  color: color,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance semanal',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${estudio.toStringAsFixed(1)}h estudio · ${deporte.toStringAsFixed(1)}h deporte',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: SVColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (estudio + deporte) == 0
                          ? 0
                          : deporte / (estudio + deporte),
                      minHeight: 6,
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00ACC1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ),
        );
        if (time != null) {
          onChanged(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value),
      ),
    );
  }
}

String _diaLabel(int d) {
  return ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][d - 1];
}

String _dificultadLabel(String d) {
  return {'baja': 'Baja', 'media': 'Media', 'alta': 'Alta'}[d] ?? d;
}
