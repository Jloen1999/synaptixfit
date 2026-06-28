import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/calendar_dtos.dart';
import '../infrastructure/grid_math.dart';

class CalendarGridNotifier extends StateNotifier<CalendarGridState> {
  final Map<String, Timer> _persistTimers = {};

  String _newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'block_${now}_${state.bloques.length}';
  }

  CalendarGridNotifier() : super(CalendarGridState());

  // ===========================================================================
  // Inicialización
  // ===========================================================================

  /// Inicializa el grid con una [InboxConfig] y horarios fijos.
  void inicializar(InboxConfig config) {
    final semanaInicio = _calcularLunes();
    final semanaFin = semanaInicio.add(const Duration(days: 6));

    final bloquesFijos = config.horariosFijos
        .map((h) => TimeBlock(
              idLocal: _newId(),
              diaSemana: h.diaSemana,
              horaInicio: h.horaInicio,
              horaFin: h.horaFin,
              tipo: h.tipo,
              titulo: h.titulo,
              asignaturaId: h.asignaturaId,
              asignaturaNombre: h.asignaturaNombre,
              ubicacion: h.ubicacion,
              color: _colorParaTipo(h.tipo),
              esFijo: true,
              dbId: h.id,
              completado: h.completado,
            ))
        .toList();

    state = CalendarGridState(
      fase: PlanificadorFase.canvas,
      config: config,
      bloques: bloquesFijos,
      semanaInicio: semanaInicio,
      semanaFin: semanaFin,
      planNombre: 'Mi plan semanal',
      fechaInicioPantalla: semanaInicio,
      semanaOffset: 0,
    );
  }

  Future<void> cargarBloquesGuardados() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final data = await client
          .from('horarios_academicos')
          .select('*, asignaturas(nombre), rutinas(nombre)')
          .eq('usuario_id', user.id)
          .eq('es_fijo', false)
          .order('hora_inicio', ascending: true);

      final bloquesCargados = <TimeBlock>[];
      for (final map in (data as List)) {
        final row = map as Map<String, dynamic>;
        final horaInicio = DateTime.parse(row['hora_inicio'] as String);
        final horaFin = DateTime.parse(row['hora_fin'] as String);
        final tipoStr = row['tipo_actividad'] as String? ?? 'estudio';
        final tipo = switch (tipoStr) {
          'deporte' => TimeBlockTipo.deporte,
          'examen' => TimeBlockTipo.examen,
          'entrega' => TimeBlockTipo.entrega,
          'clase' => TimeBlockTipo.clase,
          'descanso' => TimeBlockTipo.descanso,
          'comida' => TimeBlockTipo.comida,
          'sueno' => TimeBlockTipo.sueno,
          _ => TimeBlockTipo.estudio,
        };

        final asigJoin = row['asignaturas'];
        final rutJoin = row['rutinas'];

        bloquesCargados.add(TimeBlock(
          idLocal: 'db_${row['id']}',
          dbId: row['id'] as String?,
          diaSemana: (row['dia_semana'] as int?) ?? horaInicio.weekday,
          horaInicio: TimeOfDay.fromDateTime(horaInicio),
          horaFin: TimeOfDay.fromDateTime(horaFin),
          tipo: tipo,
          titulo: row['temas'] as String?,
          asignaturaId: row['asignatura_id'] as String?,
          asignaturaNombre:
              asigJoin is Map ? asigJoin['nombre'] as String? : null,
          rutinaId: row['rutina_id'] as String?,
          rutinaNombre: rutJoin is Map ? rutJoin['nombre'] as String? : null,
          temas: row['temas'] as String?,
          ubicacion: row['ubicacion'] as String?,
          color: _colorParaTipo(tipo),
          esFijo: false,
          esSugerencia: false,
          fecha: DateTime(horaInicio.year, horaInicio.month, horaInicio.day),
          diaRutinaId: row['dia_rutina_id'] as String?,
          semanaRutinaId: row['semana_rutina_id'] as String?,
          retoId: row['reto_id'] as String?,
          hitoId: row['hito_id'] as String?,
          esHitoInamovible: (row['es_hito_inamovible'] as bool?) ?? false,
          completado: (row['completado'] as bool?) ?? false,
          aceptado: true,
        ));
      }

      if (bloquesCargados.isNotEmpty) {
        state = state.copyWith(
          bloques: [...state.bloques, ...bloquesCargados],
        );
      }
    } catch (_) {}
  }

  void navegarSemana(int delta) {
    final nuevoOffset = state.semanaOffset + delta;
    final lunes = _calcularLunes();
    state = state.copyWith(
      semanaOffset: nuevoOffset,
      fechaInicioPantalla: lunes.add(Duration(days: nuevoOffset * 7)),
    );
  }

  void irAHoy() {
    final lunes = _calcularLunes();
    state = state.copyWith(
      semanaOffset: 0,
      fechaInicioPantalla: lunes,
    );
  }

  // ===========================================================================
  // CRUD de bloques
  // ===========================================================================

  /// Añade un bloque al grid desde el inbox.
  void placeBlock({
    required String? asignaturaId,
    required String? asignaturaNombre,
    required int diaSemana,
    required TimeOfDay horaInicio,
    TimeOfDay? horaFin,
    TimeBlockTipo tipo = TimeBlockTipo.estudio,
    String? rutinaId,
    String? rutinaNombre,
    String? titulo,
    String? ubicacion,
    String? temas,
    DateTime? fecha,
    String? retoId,
    String? hitoId,
    String? retoTitulo,
    String? diaRutinaId,
    String? semanaRutinaId,
  }) {
    final hFin = horaFin ??
        TimeOfDay(
          hour: (horaInicio.hour + 1) % 24,
          minute: horaInicio.minute,
        );

    final bloque = TimeBlock(
      idLocal: _newId(),
      diaSemana: diaSemana.clamp(1, 7),
      horaInicio: horaInicio,
      horaFin: hFin,
      tipo: tipo,
      titulo: titulo,
      asignaturaId: asignaturaId,
      asignaturaNombre: asignaturaNombre,
      rutinaId: rutinaId,
      rutinaNombre: rutinaNombre,
      ubicacion: ubicacion,
      temas: temas,
      color: _colorParaTipo(tipo),
      esSugerencia: false,
      fecha: fecha,
      retoId: retoId,
      hitoId: hitoId,
      retoTitulo: retoTitulo,
      diaRutinaId: diaRutinaId,
      semanaRutinaId: semanaRutinaId,
    );

    final conflictos = GridMath.validarConstraints(bloque, state.bloques);
    if (conflictos.any((c) => c.severidad == ConflictSeverity.error)) {
      return;
    }

    final hayMismoTipoSolapado = retoId == null &&
        state.bloques
            .any((b) => b.tipo == bloque.tipo && GridMath.seSolapan(bloque, b));
    if (hayMismoTipoSolapado) return;

    state = state.copyWith(
      bloques: [...state.bloques, bloque],
      metadata: _calcularMetadata(),
    );

    _persistInsert(bloque);
  }

  /// Mueve un bloque a una nueva posición.
  void moveBlock(String blockId, int nuevoDia, TimeOfDay nuevaHoraInicio,
      {DateTime? nuevaFecha}) {
    final idx = state.bloques.indexWhere((b) => b.idLocal == blockId);
    if (idx == -1) return;

    final viejo = state.bloques[idx];
    final duracionMin = viejo.duracion.inMinutes;
    final inicioMin = nuevaHoraInicio.hour * 60 + nuevaHoraInicio.minute;
    final finMin = (inicioMin + duracionMin).clamp(0, 23 * 60 + 59);
    final nuevaHoraFin = TimeOfDay(hour: finMin ~/ 60, minute: finMin % 60);

    final nuevo = viejo.copyWith(
      diaSemana: nuevoDia,
      horaInicio: nuevaHoraInicio,
      horaFin: nuevaHoraFin,
      fecha: nuevaFecha,
    );

    // Movimiento libre: se permite cualquier reubicación (incluidos solapamientos
    // y bloques antes inamovibles). Los solapamientos se reportan como avisos en
    // la metadata, no bloquean el movimiento.
    final nuevosBloques = [...state.bloques];
    nuevosBloques[idx] = nuevo;

    state = state.copyWith(
      bloques: nuevosBloques,
      metadata: _calcularMetadata(),
    );

    if (nuevo.dbId != null) {
      _schedulePersist(nuevo);
    }
  }

  /// Redimensiona un bloque cambiando su hora de fin.
  void resizeBlock(String blockId, TimeOfDay nuevaHoraFin) {
    final idx = state.bloques.indexWhere((b) => b.idLocal == blockId);
    if (idx == -1) return;

    final viejo = state.bloques[idx];
    final resized = viejo.copyWith(horaFin: nuevaHoraFin);

    // Solo se impide reducir por debajo del mínimo (30 min); los solapamientos
    // se permiten y se reportan como avisos en la metadata.
    if (resized.duracion.inMinutes < 30) return;

    final nuevosBloques = [...state.bloques];
    nuevosBloques[idx] = resized;

    state = state.copyWith(
      bloques: nuevosBloques,
      metadata: _calcularMetadata(),
    );

    if (resized.dbId != null) {
      _schedulePersist(resized);
    }
  }

  /// Actualiza todas las propiedades de un bloque existente.
  void updateBlock({
    required String blockId,
    required int diaSemana,
    required TimeOfDay horaInicio,
    TimeOfDay? horaFin,
    TimeBlockTipo tipo = TimeBlockTipo.estudio,
    String? asignaturaId,
    String? asignaturaNombre,
    String? rutinaId,
    String? rutinaNombre,
    String? titulo,
    String? ubicacion,
    String? temas,
    String? retoId,
    String? retoTitulo,
  }) {
    final idx = state.bloques.indexWhere((b) => b.idLocal == blockId);
    if (idx == -1) return;
    if (state.bloques[idx].esFijo) return;

    final viejo = state.bloques[idx];
    final hFin = horaFin ??
        TimeOfDay(
          hour: (horaInicio.hour + 1) % 24,
          minute: horaInicio.minute,
        );

    final actualizado = viejo.copyWith(
      diaSemana: diaSemana.clamp(1, 7),
      horaInicio: horaInicio,
      horaFin: hFin,
      tipo: tipo,
      titulo: titulo,
      asignaturaId: asignaturaId,
      asignaturaNombre: asignaturaNombre,
      rutinaId: rutinaId,
      rutinaNombre: rutinaNombre,
      ubicacion: ubicacion,
      temas: temas,
      retoId: retoId,
      retoTitulo: retoTitulo,
      color: _colorParaTipo(tipo),
    );

    final conflictos = GridMath.validarConstraints(
      actualizado,
      state.bloques,
      ignorarId: blockId,
    );
    if (conflictos.any((c) => c.severidad == ConflictSeverity.error)) return;

    final nuevosBloques = [...state.bloques];
    nuevosBloques[idx] = actualizado;

    state = state.copyWith(
      bloques: nuevosBloques,
      metadata: _calcularMetadata(),
    );

    _persistUpdate(actualizado);
  }

  /// Elimina un bloque del grid (de cualquier tipo, incluidos los fijos como
  /// clases, exámenes, etc.). Si tiene `dbId`, se borra también de la base de
  /// datos en `horarios_academicos`.
  void removeBlock(String blockId) {
    final idx = state.bloques.indexWhere((b) => b.idLocal == blockId);
    if (idx == -1) return;

    final dbId = state.bloques[idx].dbId;
    final nuevosBloques = [...state.bloques]..removeAt(idx);
    state = state.copyWith(
      bloques: nuevosBloques,
      metadata: _calcularMetadata(),
    );

    if (dbId != null) _persistDelete(dbId);
  }

  /// Acepta una sugerencia IA (la convierte en planificada).
  void acceptSuggestion(String blockId) {
    final idx = state.bloques.indexWhere((b) => b.idLocal == blockId);
    if (idx == -1) return;

    final nuevosBloques = [...state.bloques];
    nuevosBloques[idx] = nuevosBloques[idx].copyWith(
      esSugerencia: false,
      aceptado: true,
    );

    state = state.copyWith(
      bloques: nuevosBloques,
      metadata: _calcularMetadata(),
    );
  }

  /// Rechaza una sugerencia IA.
  void rejectSuggestion(String blockId) {
    final idx = state.bloques.indexWhere((b) => b.idLocal == blockId);
    if (idx == -1) return;

    final nuevosBloques = [...state.bloques]..removeAt(idx);
    state = state.copyWith(
      bloques: nuevosBloques,
      metadata: _calcularMetadata(),
    );
  }

  /// Aplica sugerencias generadas por IA al grid.
  void applyAISuggestions(List<TimeBlock> sugerencias) {
    final sinSugerenciasPrevias =
        state.bloques.where((b) => !b.esSugerencia || b.aceptado).toList();
    final todas = [...sinSugerenciasPrevias, ...sugerencias];
    state = state.copyWith(
      bloques: todas,
      metadata: _calcularMetadata(),
    );
  }

  /// Elimina todas las sugerencias IA no aceptadas.
  void clearSuggestions() {
    final soloAceptados = state.bloques.where((b) => !b.esSugerencia).toList();
    state = state.copyWith(
      bloques: soloAceptados,
      metadata: _calcularMetadata(),
    );
  }

  // ===========================================================================
  // Inyección en cascada de rutinas
  // ===========================================================================

  Future<int> inyectarRutinaCascada(
    String rutinaId,
    DateTime fechaInicio,
    TimeOfDay hora,
  ) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return 0;

      final semanasData = await client
          .from('semanas_rutina')
          .select('id, numero_semana')
          .eq('rutina_id', rutinaId)
          .eq('usuario_id', user.id)
          .order('numero_semana', ascending: true);

      final semanas = (semanasData as List)
          .map((s) => (s as Map<String, dynamic>))
          .toList();

      if (semanas.isEmpty) return 0;

      final semanaIds = semanas.map((s) => s['id'] as String).toList();
      final diasData = await client
          .from('dias_rutina')
          .select('id, semana_rutina_id, dia_semana, enfoque')
          .inFilter('semana_rutina_id', semanaIds)
          .order('dia_semana', ascending: true);

      final dias =
          (diasData as List).map((d) => d as Map<String, dynamic>).toList();

      if (dias.isEmpty) return 0;

      final diaSemanaInicio = fechaInicio.weekday;
      final diasOffset = (diaSemanaInicio - 1) % 7;
      final inicioSemana0 = fechaInicio.subtract(Duration(days: diasOffset));

      final nuevosBloques = <TimeBlock>[];
      final config = state.config;
      final rutinaNombre = config.rutinasActivas
          .where((r) => r.id == rutinaId)
          .firstOrNull
          ?.nombre;

      for (final dia in dias) {
        final semanaRutinaId = dia['semana_rutina_id'] as String;
        final semana = semanas.firstWhere(
          (s) => s['id'] == semanaRutinaId,
        );
        final numSemana = (semana['numero_semana'] as num).toInt();
        final diaSemana = (dia['dia_semana'] as num).toInt();

        final fechaBloque = inicioSemana0
            .add(Duration(days: (numSemana - 1) * 7 + diaSemana - 1));

        final bloque = TimeBlock(
          idLocal: _newId(),
          diaSemana: fechaBloque.weekday,
          horaInicio: hora,
          horaFin: TimeOfDay(
            hour: (hora.hour + 1) % 24,
            minute: hora.minute,
          ),
          tipo: TimeBlockTipo.deporte,
          rutinaId: rutinaId,
          rutinaNombre: rutinaNombre,
          color: const Color(0xFFF97316),
          esSugerencia: false,
          fecha: fechaBloque,
          diaRutinaId: dia['id'] as String,
          semanaRutinaId: semanaRutinaId,
          temas: dia['enfoque'] as String?,
        );

        final conflictos = GridMath.validarConstraints(bloque, state.bloques);
        final tieneError =
            conflictos.any((c) => c.severidad == ConflictSeverity.error);
        if (!tieneError) {
          nuevosBloques.add(bloque);
        }
      }

      if (nuevosBloques.isNotEmpty) {
        state = state.copyWith(
          bloques: [...state.bloques, ...nuevosBloques],
          metadata: _calcularMetadata(),
        );
      }

      return nuevosBloques.length;
    } catch (_) {
      return 0;
    }
  }

  // ===========================================================================
  // Persistencia (esqueleto — Sprint 3 implementará guardado real)
  // ===========================================================================

  /// Guarda el plan completo en Supabase.
  Future<String?> guardarPlan() async {
    state = state.copyWith(guardando: true, errorGuardado: null);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return null;

      final semanaInicio = state.semanaInicio ?? _calcularLunes();
      final semanaFin =
          state.semanaFin ?? semanaInicio.add(const Duration(days: 6));
      final nombre =
          state.planNombre ?? 'Plan ${semanaInicio.day}/${semanaInicio.month}';

      final planData = await client
          .from('planes_estudio')
          .insert({
            'usuario_id': user.id,
            'nombre': nombre,
            'semana_inicio': semanaInicio.toIso8601String().split('T')[0],
            'semana_fin': semanaFin.toIso8601String().split('T')[0],
            'visibilidad': 'private',
          })
          .select('id')
          .single();

      final planId = planData['id'] as String;

      try {
        final bloquesAGuardar = state.bloques
            .where((b) => !b.esFijo && b.aceptado && b.dbId == null)
            .toList();

        if (bloquesAGuardar.isNotEmpty) {
          final rows = bloquesAGuardar.map((b) {
            final fechaBase = b.fecha ??
                _fechaDesdeDiaYHora(semanaInicio, b.diaSemana, b.horaInicio);
            final fechaInicio = DateTime(fechaBase.year, fechaBase.month,
                fechaBase.day, b.horaInicio.hour, b.horaInicio.minute);
            final fechaFin = DateTime(fechaBase.year, fechaBase.month,
                fechaBase.day, b.horaFin.hour, b.horaFin.minute);
            return {
              'usuario_id': user.id,
              'plan_estudio_id': planId,
              'asignatura_id': b.asignaturaId,
              'hora_inicio': fechaInicio.toIso8601String(),
              'hora_fin': fechaFin.toIso8601String(),
              'prioridad': 'media',
              'tipo_actividad': b.tipo == TimeBlockTipo.deporte
                  ? 'deporte'
                  : b.tipo == TimeBlockTipo.examen
                      ? 'examen'
                      : b.tipo == TimeBlockTipo.entrega
                          ? 'entrega'
                          : 'estudio',
              'es_fijo': false,
              'dia_semana': b.diaSemana,
              if (b.rutinaId != null) 'rutina_id': b.rutinaId,
              if (b.temas != null) 'temas': b.temas,
              if (b.diaRutinaId != null) 'dia_rutina_id': b.diaRutinaId,
              if (b.semanaRutinaId != null)
                'semana_rutina_id': b.semanaRutinaId,
              if (b.retoId != null) 'reto_id': b.retoId,
              if (b.hitoId != null) 'hito_id': b.hitoId,
            };
          }).toList();

          await client.from('horarios_academicos').insert(rows);
        }

        if (state.config.entregas.isNotEmpty) {
          for (final entrega in state.config.entregas) {
            await client
                .from('entregas_examenes')
                .update({'plan_estudio_id': planId})
                .eq('id', entrega.id)
                .eq('usuario_id', user.id);
          }
        }

        state = state.copyWith(
          planId: planId,
          guardando: false,
          fase: PlanificadorFase.completado,
        );

        return planId;
      } catch (_) {
        await client
            .from('planes_estudio')
            .delete()
            .eq('id', planId)
            .eq('usuario_id', user.id);
        rethrow;
      }
    } catch (e) {
      state = state.copyWith(
        guardando: false,
        errorGuardado: e.toString(),
      );
      return null;
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  // ===========================================================================
  // Persistencia instantánea con debounce
  // ===========================================================================

  void _schedulePersist(TimeBlock block) {
    final id = block.dbId!;
    _persistTimers[id]?.cancel();
    _persistTimers[id] = Timer(const Duration(milliseconds: 500), () {
      _doPersist(block);
    });
  }

  Future<void> _doPersist(TimeBlock block) async {
    if (block.dbId == null) return;
    state = state.copyWith(sincronizando: true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final fechaBase = block.fecha ??
          _fechaDesdeDiaYHora(
              state.fechaInicioPantalla, block.diaSemana, block.horaInicio);
      final fechaInicio = DateTime(fechaBase.year, fechaBase.month,
          fechaBase.day, block.horaInicio.hour, block.horaInicio.minute);
      final fechaFin = DateTime(fechaBase.year, fechaBase.month, fechaBase.day,
          block.horaFin.hour, block.horaFin.minute);

      await client
          .from('horarios_academicos')
          .update({
            'hora_inicio': fechaInicio.toIso8601String(),
            'hora_fin': fechaFin.toIso8601String(),
            'dia_semana': block.diaSemana,
          })
          .eq('id', block.dbId!)
          .eq('usuario_id', user.id);
    } catch (_) {}
    if (!mounted) return;
    state = state.copyWith(sincronizando: false);
  }

  WeekPlanMetadata _calcularMetadata() {
    final aceptados = state.bloquesAceptados;
    final horasEstudio = aceptados
        .where((b) => b.tipo == TimeBlockTipo.estudio)
        .fold(0.0, (s, b) => s + b.duracionHoras);
    final sesionesDeporte =
        aceptados.where((b) => b.tipo == TimeBlockTipo.deporte).length;
    final sugeridos =
        state.bloques.where((b) => b.esSugerencia && !b.aceptado).length;

    return WeekPlanMetadata(
      horasEstudioColocadas: horasEstudio,
      sesionesDeporteColocadas: sesionesDeporte,
      horasDeporteColocadas:
          sesionesDeporte * state.config.minutosPorSesionDeporte / 60.0,
      progresoEstudio: state.config.horasEstudioObjetivo > 0
          ? (horasEstudio / state.config.horasEstudioObjetivo).clamp(0, 1)
          : 0,
      progresoDeporte: state.config.sesionesDeporteObjetivo > 0
          ? sesionesDeporte / state.config.sesionesDeporteObjetivo
          : 0,
      bloquesTotales: state.bloques.length,
      bloquesAceptados: aceptados.length,
      bloquesRechazados: sugeridos,
    );
  }

  Color _colorParaTipo(TimeBlockTipo tipo) {
    // estudio, examen y entrega comparten el mismo azul base;
    // se diferencian por el color marginal (borde izquierdo) en el widget.
    return switch (tipo) {
      TimeBlockTipo.estudio => const Color(0xFF3B82F6),
      TimeBlockTipo.examen => const Color(0xFF3B82F6),
      TimeBlockTipo.entrega => const Color(0xFF3B82F6),
      TimeBlockTipo.repaso => const Color(0xFF3B82F6),
      TimeBlockTipo.deporte => const Color(0xFFF97316),
      TimeBlockTipo.clase => const Color(0xFF4A90D9),
      TimeBlockTipo.descanso => const Color(0xFF10B981),
      TimeBlockTipo.comida => const Color(0xFFF59E0B),
      TimeBlockTipo.sueno => const Color(0xFF6366F1),
    };
  }

  // ===========================================================================
  // Carga de banners de retos
  // ===========================================================================

  /*Future<void> cargarRetoBanners() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final retosData = await client
          .from('retos')
          .select()
          .eq('usuario_id', user.id)
          .eq('esta_completado', false)
          .order('fecha_inicio', ascending: true)
          .limit(10);

      final retos = retosData as List;
      if (retos.isEmpty) {
        state = state.copyWith(retoBanners: []);
        return;
      }

      final retoIds = retos.map((r) => (r as Map)['id'] as String).toList();

      final hitosData = await client
          .from('hitos_de_reto')
          .select()
          .inFilter('reto_id', retoIds)
          .order('indice_orden', ascending: true);

      final hitosPorReto = <String, List<Map<String, dynamic>>>{};
      for (final h in (hitosData as List)) {
        final map = h as Map<String, dynamic>;
        final rId = map['reto_id'] as String;
        hitosPorReto.putIfAbsent(rId, () => []).add(map);
      }

      final banners = retos.map((r) {
        final map = r as Map<String, dynamic>;
        final retoId = map['id'] as String;
        final tipo = map['tipo'] as String? ?? 'fitness';
        final hitos = hitosPorReto[retoId] ?? [];
        final esComplejo = hitos.isNotEmpty;

        return RetoBanner(
          retoId: retoId,
          titulo: map['titulo'] as String? ?? '',
          meta: map['meta'] as String?,
          tipo: tipo,
          fechaInicio: DateTime.parse(map['fecha_inicio'] as String),
          fechaFin: DateTime.parse(map['fecha_fin'] as String),
          esComplejo: esComplejo,
          color: tipo == 'fitness'
              ? const Color(0xFFE74C3C)
              : const Color(0xFF7B1FA2),
          tareas: hitos
              .map((h) => RetoTareaBanner(
                    hitoId: h['id'] as String,
                    titulo: h['titulo'] as String? ?? '',
                    indiceOrden: (h['indice_orden'] as num?)?.toInt() ?? 0,
                    progreso: (h['progreso_actual'] as num?)?.toDouble() ?? 0,
                    completada: h['esta_completado'] as bool? ?? false,
                    estado: h['estado'] as String? ?? 'disponible',
                  ))
              .toList(),
        );
      }).toList();

      state = state.copyWith(retoBanners: banners);
    } catch (_) {}
  }
*/

  // ===========================================================================
  // Distribución de bloques de rutina
  // ===========================================================================

  Future<int> placeRutinaDistribuida({
    required String rutinaId,
    required String rutinaNombre,
    required List<int> diasSemana,
    required int duracionMinutos,
    required DateTime fechaInicio,
    required int duracionSemanas,
  }) async {
    if (diasSemana.isEmpty) return 0;

    final sortedDias = [...diasSemana]..sort();

    List<Map<String, dynamic>> diasOrdenados = [];
    try {
      final client = Supabase.instance.client;

      final semanasData = await client
          .from('semanas_rutina')
          .select('id, numero_semana')
          .eq('rutina_id', rutinaId)
          .order('numero_semana', ascending: true);

      final semanas =
          (semanasData as List).map((s) => s as Map<String, dynamic>).toList();

      if (semanas.isNotEmpty) {
        final semanaIds = semanas.map((s) => s['id'] as String).toList();
        final diasData = await client
            .from('dias_rutina')
            .select('id, semana_id, numero_dia, nombre')
            .inFilter('semana_id', semanaIds)
            .order('numero_dia', ascending: true);

        final dias =
            (diasData as List).map((d) => d as Map<String, dynamic>).toList();

        for (final semana in semanas) {
          final semId = semana['id'] as String;
          diasOrdenados.addAll(dias.where((d) => d['semana_id'] == semId));
        }
      }
    } catch (_) {}

    final totalDias = diasOrdenados.isNotEmpty
        ? diasOrdenados.length
        : duracionSemanas * sortedDias.length;

    if (totalDias <= 0) return 0;

    final duracionHoras = duracionMinutos / 60.0;
    const horaDefecto = TimeOfDay(hour: 8, minute: 0);
    final horaFin = TimeOfDay(
      hour: (horaDefecto.hour + duracionHoras.floor()) % 24,
      minute: (horaDefecto.minute + ((duracionHoras % 1) * 60).round()) % 60,
    );

    final nuevosBloques = <TimeBlock>[];
    var fechaCursor = fechaInicio;
    var bloqueCount = 0;
    final baseTs = DateTime.now().microsecondsSinceEpoch;

    while (bloqueCount < totalDias) {
      if (sortedDias.contains(fechaCursor.weekday)) {
        final diaRutina = bloqueCount < diasOrdenados.length
            ? diasOrdenados[bloqueCount]
            : null;

        final bloque = TimeBlock(
          idLocal: 'rut_${baseTs}_$bloqueCount',
          diaSemana: fechaCursor.weekday,
          horaInicio: horaDefecto,
          horaFin: horaFin,
          tipo: TimeBlockTipo.deporte,
          rutinaId: rutinaId,
          rutinaNombre: rutinaNombre,
          titulo: diaRutina?['nombre'] as String? ?? 'Día ${bloqueCount + 1}',
          color: const Color(0xFFF97316),
          esSugerencia: false,
          fecha: fechaCursor,
          diaRutinaId: diaRutina?['id'] as String?,
          semanaRutinaId: diaRutina?['semana_id'] as String?,
          temas: diaRutina?['nombre'] as String?,
        );

        nuevosBloques.add(bloque);
        bloqueCount++;
      }
      fechaCursor = fechaCursor.add(const Duration(days: 1));
      if (fechaCursor.difference(fechaInicio).inDays > 365) break;
    }

    if (nuevosBloques.isNotEmpty) {
      state = state.copyWith(
        bloques: [...state.bloques, ...nuevosBloques],
        metadata: _calcularMetadata(),
      );
      for (final b in nuevosBloques) {
        _persistInsert(b);
      }
    }

    return nuevosBloques.length;
  }

  // ===========================================================================
  // Colocación de tarea de reto complejo en el grid
  // ===========================================================================

  void placeRetoTarea({
    required String retoId,
    required String retoTitulo,
    required String hitoId,
    required String hitoTitulo,
    required DateTime fecha,
    required TimeOfDay horaInicio,
    int duracionMinutos = 60,
  }) {
    final horaFin = TimeOfDay(
      hour: (horaInicio.hour + duracionMinutos ~/ 60) % 24,
      minute: (horaInicio.minute + duracionMinutos % 60) % 60,
    );

    final bloque = TimeBlock(
      idLocal: _newId(),
      diaSemana: fecha.weekday,
      horaInicio: horaInicio,
      horaFin: horaFin,
      tipo: TimeBlockTipo.deporte,
      titulo: hitoTitulo,
      retoId: retoId,
      retoTitulo: retoTitulo,
      hitoId: hitoId,
      color: const Color(0xFFE74C3C),
      esSugerencia: false,
      fecha: fecha,
      esHitoInamovible: false,
    );

    final conflictos = GridMath.validarConstraints(bloque, state.bloques);
    if (conflictos.any((c) => c.severidad == ConflictSeverity.error)) return;

    state = state.copyWith(
      bloques: [...state.bloques, bloque],
      metadata: _calcularMetadata(),
    );

    _persistInsert(bloque);
  }

  // ===========================================================================
  // Persistencia inmediata de bloques (calendario vivo)
  // ===========================================================================

  DateTime _fechaInicioDe(TimeBlock b) {
    final base = b.fecha ??
        _fechaDesdeDiaYHora(
            state.fechaInicioPantalla, b.diaSemana, b.horaInicio);
    return DateTime(base.year, base.month, base.day, b.horaInicio.hour,
        b.horaInicio.minute);
  }

  DateTime _fechaFinDe(TimeBlock b) {
    final base = b.fecha ??
        _fechaDesdeDiaYHora(
            state.fechaInicioPantalla, b.diaSemana, b.horaInicio);
    return DateTime(
        base.year, base.month, base.day, b.horaFin.hour, b.horaFin.minute);
  }

  /// Inserta un bloque nuevo en `horarios_academicos` y fija su `dbId` en el
  /// estado para que persista y sea editable/movible más adelante.
  Future<void> _persistInsert(TimeBlock b) async {
    if (b.esFijo || b.dbId != null) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final row = await client
          .from('horarios_academicos')
          .insert({
            'usuario_id': user.id,
            if (b.asignaturaId != null) 'asignatura_id': b.asignaturaId,
            'hora_inicio': _fechaInicioDe(b).toIso8601String(),
            'hora_fin': _fechaFinDe(b).toIso8601String(),
            'prioridad': 'media',
            'tipo_actividad': b.tipo.name,
            'es_fijo': false,
            'dia_semana': b.diaSemana,
            if (b.rutinaId != null) 'rutina_id': b.rutinaId,
            if (b.temas != null) 'temas': b.temas,
            if (b.ubicacion != null) 'ubicacion': b.ubicacion,
            if (b.diaRutinaId != null) 'dia_rutina_id': b.diaRutinaId,
            if (b.semanaRutinaId != null) 'semana_rutina_id': b.semanaRutinaId,
            if (b.retoId != null) 'reto_id': b.retoId,
            if (b.hitoId != null) 'hito_id': b.hitoId,
          })
          .select('id')
          .single();

      final newId = row['id'] as String;
      if (!mounted) return;
      final idx = state.bloques.indexWhere((x) => x.idLocal == b.idLocal);
      if (idx != -1) {
        final nuevos = [...state.bloques];
        nuevos[idx] = nuevos[idx].copyWith(dbId: newId);
        state = state.copyWith(bloques: nuevos);
      }
    } catch (_) {}
  }

  Future<void> _persistUpdate(TimeBlock b) async {
    if (b.dbId == null) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      await client
          .from('horarios_academicos')
          .update({
            'asignatura_id': b.asignaturaId,
            'hora_inicio': _fechaInicioDe(b).toIso8601String(),
            'hora_fin': _fechaFinDe(b).toIso8601String(),
            'tipo_actividad': b.tipo.name,
            'dia_semana': b.diaSemana,
            'rutina_id': b.rutinaId,
            'temas': b.temas,
            'ubicacion': b.ubicacion,
            'reto_id': b.retoId,
          })
          .eq('id', b.dbId!)
          .eq('usuario_id', user.id);
    } catch (_) {}
  }

  Future<void> _persistDelete(String dbId) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      await client
          .from('horarios_academicos')
          .delete()
          .eq('id', dbId)
          .eq('usuario_id', user.id);
    } catch (_) {}
  }

  DateTime _calcularLunes() {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    return hoy.subtract(Duration(days: hoy.weekday - 1));
  }

  DateTime _fechaDesdeDiaYHora(
      DateTime semanaInicio, int diaSemana, TimeOfDay hora) {
    final dia = semanaInicio.add(Duration(days: diaSemana - 1));
    return DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
  }
}

/// Provider principal del grid de time-blocking.
final calendarGridProvider =
    StateNotifierProvider<CalendarGridNotifier, CalendarGridState>((ref) {
  return CalendarGridNotifier();
});
