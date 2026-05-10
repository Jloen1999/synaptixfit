DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value == null) {
    return DateTime.now();
  }
  return DateTime.parse(value.toString());
}

double _parseDouble(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value == null) {
    return fallback;
  }
  return double.tryParse(value.toString()) ?? fallback;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value == null) {
    return fallback;
  }
  return int.tryParse(value.toString()) ?? fallback;
}

bool _parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value == null) {
    return fallback;
  }
  final normalized = value.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

class UsuarioDb {
  const UsuarioDb({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    this.urlAvatar,
    required this.nivel,
    required this.xpTotal,
    required this.rachaActual,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String email;
  final String nombreCompleto;
  final String? urlAvatar;
  final int nivel;
  final int xpTotal;
  final int rachaActual;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  factory UsuarioDb.fromMap(Map<String, dynamic> map) {
    return UsuarioDb(
      id: map['id'] as String,
      email: map['email'] as String,
      nombreCompleto: map['nombre_completo'] as String,
      urlAvatar: map['url_avatar'] as String?,
      nivel: _parseInt(map['nivel'], fallback: 1),
      xpTotal: _parseInt(map['xp_total']),
      rachaActual: _parseInt(map['racha_actual']),
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nombre_completo': nombreCompleto,
      'url_avatar': urlAvatar,
      'nivel': nivel,
      'xp_total': xpTotal,
      'racha_actual': rachaActual,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

class EjercicioDb {
  const EjercicioDb({
    required this.id,
    this.exerciseDbId,
    required this.nombre,
    this.urlGif,
    required this.instrucciones,
    required this.dificultad,
    this.descripcion,
    required this.partesCuerpo,
    required this.musculosObjetivo,
    required this.musculosSecundarios,
    required this.equipamientos,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String? exerciseDbId;
  final String nombre;
  final String? urlGif;
  final List<String> instrucciones;
  final String dificultad;
  final String? descripcion;
  final List<String> partesCuerpo;
  final List<String> musculosObjetivo;
  final List<String> musculosSecundarios;
  final List<String> equipamientos;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  /// Primer músculo objetivo como etiqueta resumida.
  String get musculoPrincipal =>
      musculosObjetivo.isNotEmpty ? musculosObjetivo.first : 'General';

  /// Primer equipamiento como etiqueta resumida.
  String get equipamientoPrincipal =>
      equipamientos.isNotEmpty ? equipamientos.first : 'Sin equipo';

  /// Primera parte del cuerpo como etiqueta resumida.
  String get parteCuerpoPrincipal =>
      partesCuerpo.isNotEmpty ? partesCuerpo.first : 'General';

  factory EjercicioDb.fromMap(Map<String, dynamic> map) {
    return EjercicioDb(
      id: map['id'] as String,
      exerciseDbId: map['exercise_db_id'] as String?,
      nombre: map['nombre'] as String,
      urlGif: map['url_gif'] as String?,
      instrucciones: _parseStringList(map['instrucciones']),
      dificultad: (map['dificultad'] as String?) ?? 'medio',
      descripcion: map['descripcion'] as String?,
      partesCuerpo: _parseStringList(map['partes_cuerpo']),
      musculosObjetivo: _parseStringList(map['musculos_objetivo']),
      musculosSecundarios: _parseStringList(map['musculos_secundarios']),
      equipamientos: _parseStringList(map['equipamientos']),
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_db_id': exerciseDbId,
      'nombre': nombre,
      'url_gif': urlGif,
      'instrucciones': instrucciones,
      'dificultad': dificultad,
      'descripcion': descripcion,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

class RutinaDb {
  const RutinaDb({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.descripcion,
    required this.visibilidad,
    required this.cantidadEjercicios,
    required this.duracionSemanas,
    required this.objetivo,
    required this.estado,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final String nombre;
  final String? descripcion;
  final String visibilidad;
  final int cantidadEjercicios;
  final int duracionSemanas;
  final String objetivo;
  final String estado;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  factory RutinaDb.fromMap(Map<String, dynamic> map) {
    return RutinaDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      visibilidad: (map['visibilidad'] as String?) ?? 'private',
      cantidadEjercicios: _parseInt(map['cantidad_ejercicios']),
      duracionSemanas: _parseInt(map['duracion_semanas'], fallback: 1),
      objetivo: (map['objetivo'] as String?) ?? 'fuerza',
      estado: (map['estado'] as String?) ?? 'activo',
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'descripcion': descripcion,
      'visibilidad': visibilidad,
      'cantidad_ejercicios': cantidadEjercicios,
      'duracion_semanas': duracionSemanas,
      'objetivo': objetivo,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

class SeleccionEjercicioDb {
  const SeleccionEjercicioDb({
    required this.id,
    required this.rutinaId,
    required this.ejercicioId,
    required this.series,
    required this.repeticiones,
    required this.segundosDescanso,
    required this.indiceOrden,
    this.diaId,
    this.pesoKg,
  });

  final String id;
  final String rutinaId;
  final String ejercicioId;
  final int series;
  final int repeticiones;
  final int segundosDescanso;
  final int indiceOrden;
  final String? diaId;
  final double? pesoKg;

  factory SeleccionEjercicioDb.fromMap(Map<String, dynamic> map) {
    return SeleccionEjercicioDb(
      id: map['id'] as String,
      rutinaId: map['rutina_id'] as String,
      ejercicioId: map['ejercicio_id'] as String,
      series: _parseInt(map['series'], fallback: 3),
      repeticiones: _parseInt(map['repeticiones'], fallback: 10),
      segundosDescanso: _parseInt(map['segundos_descanso'], fallback: 90),
      indiceOrden: _parseInt(map['indice_orden'], fallback: 1),
      diaId: map['dia_id'] as String?,
      pesoKg: map['peso_kg'] != null ? _parseDouble(map['peso_kg']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rutina_id': rutinaId,
      'ejercicio_id': ejercicioId,
      'series': series,
      'repeticiones': repeticiones,
      'segundos_descanso': segundosDescanso,
      'indice_orden': indiceOrden,
      if (diaId != null) 'dia_id': diaId,
      if (pesoKg != null) 'peso_kg': pesoKg,
    };
  }
}

class SesionRegistradaDb {
  const SesionRegistradaDb({
    required this.id,
    required this.usuarioId,
    required this.rutinaId,
    required this.duracionMinutos,
    required this.caloriasQuemadas,
    required this.rpe,
    required this.completadaEn,
    required this.creadoEn,
    this.diaId,
    required this.tipo,
  });

  final String id;
  final String usuarioId;
  final String rutinaId;
  final int duracionMinutos;
  final double caloriasQuemadas;
  final int rpe;
  final DateTime completadaEn;
  final DateTime creadoEn;
  final String? diaId;
  final String tipo;

  factory SesionRegistradaDb.fromMap(Map<String, dynamic> map) {
    return SesionRegistradaDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      rutinaId: map['rutina_id'] as String,
      duracionMinutos: _parseInt(map['duracion_minutos']),
      caloriasQuemadas: _parseDouble(map['calorias_quemadas']),
      rpe: _parseInt(map['rpe']),
      completadaEn: _parseDateTime(map['completada_en']),
      creadoEn: _parseDateTime(map['creado_en']),
      diaId: map['dia_id'] as String?,
      tipo: (map['tipo'] as String?) ?? 'libre',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'rutina_id': rutinaId,
      'duracion_minutos': duracionMinutos,
      'calorias_quemadas': caloriasQuemadas,
      'rpe': rpe,
      'completada_en': completadaEn.toIso8601String(),
      'creado_en': creadoEn.toIso8601String(),
      if (diaId != null) 'dia_id': diaId,
      'tipo': tipo,
    };
  }
}

class RetoDb {
  const RetoDb({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.tipo,
    required this.meta,
    required this.visibilidad,
    required this.estaCompletado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final String titulo;
  final String tipo;
  final String meta;
  final String visibilidad;
  final bool estaCompletado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  factory RetoDb.fromMap(Map<String, dynamic> map) {
    return RetoDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      titulo: map['titulo'] as String,
      tipo: map['tipo'] as String,
      meta: map['meta'] as String,
      visibilidad: (map['visibilidad'] as String?) ?? 'private',
      estaCompletado: _parseBool(map['esta_completado']),
      fechaInicio: _parseDateTime(map['fecha_inicio']),
      fechaFin: _parseDateTime(map['fecha_fin']),
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'tipo': tipo,
      'meta': meta,
      'visibilidad': visibilidad,
      'esta_completado': estaCompletado,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

class HitoRetoDb {
  const HitoRetoDb({
    required this.id,
    required this.retoId,
    required this.titulo,
    required this.porcentajePeso,
    required this.indiceOrden,
    required this.progresoActual,
    required this.estaCompletado,
  });

  final String id;
  final String retoId;
  final String titulo;
  final double porcentajePeso;
  final int indiceOrden;
  final double progresoActual;
  final bool estaCompletado;

  factory HitoRetoDb.fromMap(Map<String, dynamic> map) {
    return HitoRetoDb(
      id: map['id'] as String,
      retoId: map['reto_id'] as String,
      titulo: map['titulo'] as String,
      porcentajePeso: _parseDouble(map['porcentaje_peso']),
      indiceOrden: _parseInt(map['indice_orden'], fallback: 1),
      progresoActual: _parseDouble(map['progreso_actual']),
      estaCompletado: _parseBool(map['esta_completado']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reto_id': retoId,
      'titulo': titulo,
      'porcentaje_peso': porcentajePeso,
      'indice_orden': indiceOrden,
      'progreso_actual': progresoActual,
      'esta_completado': estaCompletado,
    };
  }
}

class ProgresoRetoDb {
  const ProgresoRetoDb({
    required this.id,
    required this.retoId,
    this.hitoId,
    required this.usuarioId,
    required this.cantidadCompletada,
    required this.registradoEn,
    required this.creadoEn,
  });

  final String id;
  final String retoId;
  final String? hitoId;
  final String usuarioId;
  final double cantidadCompletada;
  final DateTime registradoEn;
  final DateTime creadoEn;

  factory ProgresoRetoDb.fromMap(Map<String, dynamic> map) {
    return ProgresoRetoDb(
      id: map['id'] as String,
      retoId: map['reto_id'] as String,
      hitoId: map['hito_id'] as String?,
      usuarioId: map['usuario_id'] as String,
      cantidadCompletada: _parseDouble(map['cantidad_completada']),
      registradoEn: _parseDateTime(map['registrado_en']),
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reto_id': retoId,
      'hito_id': hitoId,
      'usuario_id': usuarioId,
      'cantidad_completada': cantidadCompletada,
      'registrado_en': registradoEn.toIso8601String(),
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

class NotificacionDb {
  const NotificacionDb({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    this.descripcion,
    required this.prioridad,
    required this.tipo,
    this.urlAccion,
    this.etiquetaAccion,
    required this.estaLeida,
    required this.creadoEn,
    this.leidaEn,
  });

  final String id;
  final String usuarioId;
  final String titulo;
  final String? descripcion;
  final String prioridad;
  final String tipo;
  final String? urlAccion;
  final String? etiquetaAccion;
  final bool estaLeida;
  final DateTime creadoEn;
  final DateTime? leidaEn;

  factory NotificacionDb.fromMap(Map<String, dynamic> map) {
    return NotificacionDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String?,
      prioridad: map['prioridad'] as String,
      tipo: map['tipo'] as String,
      urlAccion: map['url_accion'] as String?,
      etiquetaAccion: map['etiqueta_accion'] as String?,
      estaLeida: _parseBool(map['esta_leida']),
      creadoEn: _parseDateTime(map['creado_en']),
      leidaEn: map['leida_en'] == null ? null : _parseDateTime(map['leida_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'tipo': tipo,
      'url_accion': urlAccion,
      'etiqueta_accion': etiquetaAccion,
      'esta_leida': estaLeida,
      'creado_en': creadoEn.toIso8601String(),
      'leida_en': leidaEn?.toIso8601String(),
    };
  }
}

class AsignaturaDb {
  const AsignaturaDb({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.codigo,
    this.descripcion,
    this.docente,
    this.catalogoAsignaturaId,
    required this.archivado,
    required this.creadoEn,
  });

  final String id;
  final String usuarioId;
  final String nombre;
  final String? codigo;
  final String? descripcion;
  final String? docente;
  final String? catalogoAsignaturaId;
  final bool archivado;
  final DateTime creadoEn;

  AsignaturaDb copyWith({
    String? nombre,
    String? codigo,
    String? descripcion,
    String? docente,
    String? catalogoAsignaturaId,
    bool? archivado,
  }) {
    return AsignaturaDb(
      id: id,
      usuarioId: usuarioId,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      docente: docente ?? this.docente,
      catalogoAsignaturaId: catalogoAsignaturaId ?? this.catalogoAsignaturaId,
      archivado: archivado ?? this.archivado,
      creadoEn: creadoEn,
    );
  }

  factory AsignaturaDb.fromMap(Map<String, dynamic> map) {
    return AsignaturaDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      nombre: map['nombre'] as String,
      codigo: map['codigo'] as String?,
      descripcion: map['descripcion'] as String?,
      docente: map['docente'] as String?,
      catalogoAsignaturaId: map['catalogo_asignatura_id'] as String?,
      archivado: _parseBool(map['archivado']),
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'docente': docente,
      'archivado': archivado,
      'catalogo_asignatura_id': catalogoAsignaturaId,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

class HorarioAcademicoDb {
  const HorarioAcademicoDb({
    required this.id,
    required this.usuarioId,
    required this.asignaturaId,
    required this.horaInicio,
    required this.horaFin,
    this.ubicacion,
    required this.tieneConflicto,
    this.planEstudioId,
    required this.prioridad,
    required this.creadoEn,
  });

  final String id;
  final String usuarioId;
  final String asignaturaId;
  final DateTime horaInicio;
  final DateTime horaFin;
  final String? ubicacion;
  final bool tieneConflicto;
  final String? planEstudioId;
  final String prioridad;
  final DateTime creadoEn;

  factory HorarioAcademicoDb.fromMap(Map<String, dynamic> map) {
    return HorarioAcademicoDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      asignaturaId: map['asignatura_id'] as String,
      horaInicio: _parseDateTime(map['hora_inicio']),
      horaFin: _parseDateTime(map['hora_fin']),
      ubicacion: map['ubicacion'] as String?,
      tieneConflicto: _parseBool(map['tiene_conflicto']),
      planEstudioId: map['plan_estudio_id'] as String?,
      prioridad: (map['prioridad'] as String?) ?? 'media',
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'asignatura_id': asignaturaId,
      'hora_inicio': horaInicio.toIso8601String(),
      'hora_fin': horaFin.toIso8601String(),
      'ubicacion': ubicacion,
      'tiene_conflicto': tieneConflicto,
      'plan_estudio_id': planEstudioId,
      'prioridad': prioridad,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

class ActividadSocialDb {
  const ActividadSocialDb({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.descripcion,
    this.urlImagen,
    required this.creadoEn,
  });

  final String id;
  final String usuarioId;
  final String tipo;
  final String descripcion;
  final String? urlImagen;
  final DateTime creadoEn;

  factory ActividadSocialDb.fromMap(Map<String, dynamic> map) {
    return ActividadSocialDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      tipo: map['tipo'] as String,
      descripcion: map['descripcion'] as String,
      urlImagen: map['url_imagen'] as String?,
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'tipo': tipo,
      'descripcion': descripcion,
      'url_imagen': urlImagen,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

class InteraccionSocialDb {
  const InteraccionSocialDb({
    required this.id,
    required this.actividadId,
    required this.usuarioId,
    required this.tipoInteraccion,
    this.textoComentario,
    required this.creadoEn,
  });

  final String id;
  final String actividadId;
  final String usuarioId;
  final String tipoInteraccion;
  final String? textoComentario;
  final DateTime creadoEn;

  factory InteraccionSocialDb.fromMap(Map<String, dynamic> map) {
    return InteraccionSocialDb(
      id: map['id'] as String,
      actividadId: map['actividad_id'] as String,
      usuarioId: map['usuario_id'] as String,
      tipoInteraccion: map['tipo_interaccion'] as String,
      textoComentario: map['texto_comentario'] as String?,
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actividad_id': actividadId,
      'usuario_id': usuarioId,
      'tipo_interaccion': tipoInteraccion,
      'texto_comentario': textoComentario,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------------
// 14) perfil_bienestar_usuario
// ---------------------------------------------------------------------------
class PerfilBienestarDb {
  const PerfilBienestarDb({
    required this.id,
    required this.usuarioId,
    required this.edad,
    required this.sexo,
    this.ciudad,
    required this.pesoKg,
    required this.alturaCm,
    required this.imc,
    required this.nivelActividad,
    required this.objetivoPrincipal,
    required this.objetivos,
    required this.equipamientoDisponible,
    required this.diasDisponiblesSemana,
    required this.minutosPorSesion,
    required this.onboardingCompletado,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final int edad;
  final String sexo;
  final String? ciudad;
  final double pesoKg;
  final double alturaCm;
  final double imc;
  final String nivelActividad;
  final String objetivoPrincipal;
  final List<String> objetivos;
  final List<String> equipamientoDisponible;
  final int diasDisponiblesSemana;
  final int minutosPorSesion;
  final bool onboardingCompletado;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  String get imcCategoria {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  factory PerfilBienestarDb.fromMap(Map<String, dynamic> map) {
    return PerfilBienestarDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      edad: _parseInt(map['edad'], fallback: 20),
      sexo: (map['sexo'] as String?) ?? 'prefiero_no_decirlo',
      ciudad: map['ciudad'] as String?,
      pesoKg: _parseDouble(map['peso_kg'], fallback: 70),
      alturaCm: _parseDouble(map['altura_cm'], fallback: 170),
      imc: _parseDouble(map['imc'], fallback: 24.2),
      nivelActividad: (map['nivel_actividad'] as String?) ?? 'sedentario',
      objetivoPrincipal:
          (map['objetivo_principal'] as String?) ?? 'fitness_general',
      objetivos: _parseStringList(map['objetivos']),
      equipamientoDisponible: _parseStringList(map['equipamiento_disponible']),
      diasDisponiblesSemana:
          _parseInt(map['dias_disponibles_semana'], fallback: 3),
      minutosPorSesion: _parseInt(map['minutos_por_sesion'], fallback: 45),
      onboardingCompletado: _parseBool(map['onboarding_completado']),
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'edad': edad,
      'sexo': sexo,
      'ciudad': ciudad,
      'peso_kg': pesoKg,
      'altura_cm': alturaCm,
      'imc': imc,
      'nivel_actividad': nivelActividad,
      'objetivo_principal': objetivoPrincipal,
      'objetivos': objetivos,
      'equipamiento_disponible': equipamientoDisponible,
      'dias_disponibles_semana': diasDisponiblesSemana,
      'minutos_por_sesion': minutosPorSesion,
      'onboarding_completado': onboardingCompletado,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }

  PerfilBienestarDb copyWith({
    double? pesoKg,
    double? alturaCm,
    double? imc,
    String? nivelActividad,
    String? objetivoPrincipal,
    List<String>? objetivos,
    List<String>? equipamientoDisponible,
    int? diasDisponiblesSemana,
    int? minutosPorSesion,
    bool? onboardingCompletado,
  }) {
    return PerfilBienestarDb(
      id: id,
      usuarioId: usuarioId,
      edad: edad,
      sexo: sexo,
      ciudad: ciudad,
      pesoKg: pesoKg ?? this.pesoKg,
      alturaCm: alturaCm ?? this.alturaCm,
      imc: imc ?? this.imc,
      nivelActividad: nivelActividad ?? this.nivelActividad,
      objetivoPrincipal: objetivoPrincipal ?? this.objetivoPrincipal,
      objetivos: objetivos ?? this.objetivos,
      equipamientoDisponible:
          equipamientoDisponible ?? this.equipamientoDisponible,
      diasDisponiblesSemana:
          diasDisponiblesSemana ?? this.diasDisponiblesSemana,
      minutosPorSesion: minutosPorSesion ?? this.minutosPorSesion,
      onboardingCompletado: onboardingCompletado ?? this.onboardingCompletado,
      creadoEn: creadoEn,
      actualizadoEn: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// 15) historial_peso
// ---------------------------------------------------------------------------
class HistorialPesoDb {
  const HistorialPesoDb({
    required this.id,
    required this.usuarioId,
    required this.pesoKg,
    required this.alturaCm,
    required this.imc,
    required this.registradoEn,
  });

  final String id;
  final String usuarioId;
  final double pesoKg;
  final double alturaCm;
  final double imc;
  final DateTime registradoEn;

  factory HistorialPesoDb.fromMap(Map<String, dynamic> map) {
    return HistorialPesoDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      pesoKg: _parseDouble(map['peso_kg'], fallback: 70),
      alturaCm: _parseDouble(map['altura_cm'], fallback: 170),
      imc: _parseDouble(map['imc'], fallback: 24.2),
      registradoEn: _parseDateTime(map['registrado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'peso_kg': pesoKg,
      'altura_cm': alturaCm,
      'imc': imc,
      'registrado_en': registradoEn.toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------------
// 16) plan_entrenamiento_semanal
// ---------------------------------------------------------------------------
class PlanEntrenamientoSemanalDb {
  const PlanEntrenamientoSemanalDb({
    required this.id,
    required this.usuarioId,
    required this.semanaInicio,
    required this.sesionesPlanificadas,
    required this.intensidad,
    required this.duracionMinPorSesion,
    required this.estado,
    this.notas,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final DateTime semanaInicio;
  final int sesionesPlanificadas;
  final String intensidad;
  final int duracionMinPorSesion;
  final String estado;
  final String? notas;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  factory PlanEntrenamientoSemanalDb.fromMap(Map<String, dynamic> map) {
    return PlanEntrenamientoSemanalDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      semanaInicio: _parseDateTime(map['semana_inicio']),
      sesionesPlanificadas:
          _parseInt(map['sesiones_planificadas'], fallback: 3),
      intensidad: (map['intensidad'] as String?) ?? 'moderada',
      duracionMinPorSesion:
          _parseInt(map['duracion_min_por_sesion'], fallback: 45),
      estado: (map['estado'] as String?) ?? 'activo',
      notas: map['notas'] as String?,
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'semana_inicio': semanaInicio.toIso8601String(),
      'sesiones_planificadas': sesionesPlanificadas,
      'intensidad': intensidad,
      'duracion_min_por_sesion': duracionMinPorSesion,
      'estado': estado,
      'notas': notas,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------------
// 17) preferencias_notificacion
// ---------------------------------------------------------------------------
class PreferenciasNotificacionDb {
  const PreferenciasNotificacionDb({
    required this.id,
    required this.usuarioId,
    required this.categoriasActivas,
    this.horaSilencioInicio,
    this.horaSilencioFin,
    required this.limiteDiario,
    required this.modoActual,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final List<String> categoriasActivas;
  final String? horaSilencioInicio;
  final String? horaSilencioFin;
  final int limiteDiario;
  final String modoActual;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  factory PreferenciasNotificacionDb.fromMap(Map<String, dynamic> map) {
    return PreferenciasNotificacionDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      categoriasActivas: _parseStringList(map['categorias_activas']),
      horaSilencioInicio: map['hora_silencio_inicio'] as String?,
      horaSilencioFin: map['hora_silencio_fin'] as String?,
      limiteDiario: _parseInt(map['limite_diario'], fallback: 10),
      modoActual: (map['modo_actual'] as String?) ?? 'normal',
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'categorias_activas': categoriasActivas,
      'hora_silencio_inicio': horaSilencioInicio,
      'hora_silencio_fin': horaSilencioFin,
      'limite_diario': limiteDiario,
      'modo_actual': modoActual,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------------
// 18) amistades
// ---------------------------------------------------------------------------
class AmistadDb {
  const AmistadDb({
    required this.id,
    required this.solicitanteId,
    required this.receptorId,
    required this.estado,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String solicitanteId;
  final String receptorId;
  final String estado;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  factory AmistadDb.fromMap(Map<String, dynamic> map) {
    return AmistadDb(
      id: map['id'] as String,
      solicitanteId: map['solicitante_id'] as String,
      receptorId: map['receptor_id'] as String,
      estado: (map['estado'] as String?) ?? 'pendiente',
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'solicitante_id': solicitanteId,
      'receptor_id': receptorId,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

/// Plan de estudio semanal: agrupa bloques por semana.
class PlanEstudioDb {
  const PlanEstudioDb({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.semanaInicio,
    required this.semanaFin,
    required this.visibilidad,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final String nombre;
  final DateTime semanaInicio;
  final DateTime semanaFin;
  final String visibilidad;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  factory PlanEstudioDb.fromMap(Map<String, dynamic> map) {
    return PlanEstudioDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      nombre: map['nombre'] as String,
      semanaInicio: _parseDateTime(map['semana_inicio']),
      semanaFin: _parseDateTime(map['semana_fin']),
      visibilidad: (map['visibilidad'] as String?) ?? 'privado',
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'semana_inicio': semanaInicio.toIso8601String(),
      'semana_fin': semanaFin.toIso8601String(),
      'visibilidad': visibilidad,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

/// Apunte o nota rápida con contenido Markdown.
class ApunteDb {
  const ApunteDb({
    required this.id,
    required this.usuarioId,
    this.asignaturaId,
    required this.titulo,
    required this.contenido,
    required this.visibilidad,
    required this.esNotaRapida,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final String? asignaturaId;
  final String titulo;
  final String contenido;
  final String visibilidad;
  final bool esNotaRapida;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  ApunteDb copyWith({
    String? titulo,
    String? contenido,
    String? asignaturaId,
    String? visibilidad,
    bool? esNotaRapida,
  }) {
    return ApunteDb(
      id: id,
      usuarioId: usuarioId,
      asignaturaId: asignaturaId ?? this.asignaturaId,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      visibilidad: visibilidad ?? this.visibilidad,
      esNotaRapida: esNotaRapida ?? this.esNotaRapida,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }

  factory ApunteDb.fromMap(Map<String, dynamic> map) {
    return ApunteDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      asignaturaId: map['asignatura_id'] as String?,
      titulo: map['titulo'] as String,
      contenido: (map['contenido'] as String?) ?? '',
      visibilidad: (map['visibilidad'] as String?) ?? 'privado',
      esNotaRapida: _parseBool(map['es_nota_rapida']),
      creadoEn: _parseDateTime(map['creado_en']),
      actualizadoEn: _parseDateTime(map['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'asignatura_id': asignaturaId,
      'titulo': titulo,
      'contenido': contenido,
      'visibilidad': visibilidad,
      'es_nota_rapida': esNotaRapida,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

/// Catálogo — universidad (solo lectura)
class CatalogoUniversidadDb {
  const CatalogoUniversidadDb({
    required this.id,
    required this.nombre,
    required this.creadoEn,
  });

  final String id;
  final String nombre;
  final DateTime creadoEn;

  factory CatalogoUniversidadDb.fromMap(Map<String, dynamic> map) {
    return CatalogoUniversidadDb(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }
}

/// Catálogo — carrera (solo lectura)
class CatalogoCarreraDb {
  const CatalogoCarreraDb({
    required this.id,
    required this.universidadId,
    required this.nombre,
    this.universidadNombre,
    required this.creadoEn,
  });

  final String id;
  final String universidadId;
  final String nombre;
  final String? universidadNombre;
  final DateTime creadoEn;

  factory CatalogoCarreraDb.fromMap(Map<String, dynamic> map) {
    String? univNombre;
    final univData = map['catalogo_universidades'];
    if (univData != null) {
      if (univData is Map<String, dynamic>) {
        univNombre = univData['nombre'] as String?;
      } else if (univData is List && univData.isNotEmpty) {
        univNombre =
            (univData.first as Map<String, dynamic>)['nombre'] as String?;
      }
    }
    return CatalogoCarreraDb(
      id: map['id'] as String,
      universidadId: map['universidad_id'] as String,
      nombre: map['nombre'] as String,
      universidadNombre: univNombre,
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }
}

/// Catálogo — asignatura predefinida (solo lectura, vinculada a una carrera)
class CatalogoAsignaturaDb {
  const CatalogoAsignaturaDb({
    required this.id,
    required this.carreraId,
    required this.nombre,
    this.curso,
    this.semestre,
    this.caracter,
    this.creditos,
    required this.creadoEn,
  });

  final String id;
  final String carreraId;
  final String nombre;
  final int? curso;
  final int? semestre;
  final String? caracter;
  final double? creditos;
  final DateTime creadoEn;

  factory CatalogoAsignaturaDb.fromMap(Map<String, dynamic> map) {
    return CatalogoAsignaturaDb(
      id: map['id'] as String,
      carreraId: map['carrera_id'] as String,
      nombre: map['nombre'] as String,
      curso: _parseInt(map['curso'], fallback: 0),
      semestre: _parseInt(map['semestre'], fallback: 0),
      caracter: map['caracter'] as String?,
      creditos: map['creditos'] != null ? _parseDouble(map['creditos']) : null,
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  bool get isNullCurso => curso == null || curso == 0;
  bool get isNullSemestre => semestre == null || semestre == 0;
}

// ---------------------------------------------------------------------------
// Helper: parsea arrays de strings desde Postgres/JSON
// ---------------------------------------------------------------------------
List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String) {
    // Postgres devuelve '{a,b,c}' cuando no se usa json
    final trimmed = value.replaceAll(RegExp(r'^\{|\}$'), '');
    if (trimmed.isEmpty) return [];
    return trimmed.split(',').map((e) => e.trim()).toList();
  }
  return [];
}

// ---------------------------------------------------------------------------
// Modelos de periodización de rutinas
// ---------------------------------------------------------------------------

class SemanaRutinaDb {
  const SemanaRutinaDb({
    required this.id,
    required this.rutinaId,
    required this.numeroSemana,
    required this.nombre,
    required this.estado,
    required this.creadoEn,
  });

  final String id;
  final String rutinaId;
  final int numeroSemana;
  final String nombre;
  final String estado;
  final DateTime creadoEn;

  factory SemanaRutinaDb.fromMap(Map<String, dynamic> map) {
    return SemanaRutinaDb(
      id: map['id'] as String,
      rutinaId: map['rutina_id'] as String,
      numeroSemana: _parseInt(map['numero_semana'], fallback: 1),
      nombre: (map['nombre'] as String?) ?? '',
      estado: (map['estado'] as String?) ?? 'pendiente',
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rutina_id': rutinaId,
      'numero_semana': numeroSemana,
      'nombre': nombre,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

class DiaRutinaDb {
  const DiaRutinaDb({
    required this.id,
    required this.semanaId,
    required this.numeroDia,
    required this.nombre,
    required this.estado,
    required this.creadoEn,
  });

  final String id;
  final String semanaId;
  final int numeroDia;
  final String nombre;
  final String estado;
  final DateTime creadoEn;

  factory DiaRutinaDb.fromMap(Map<String, dynamic> map) {
    return DiaRutinaDb(
      id: map['id'] as String,
      semanaId: map['semana_id'] as String,
      numeroDia: _parseInt(map['numero_dia'], fallback: 1),
      nombre: (map['nombre'] as String?) ?? '',
      estado: (map['estado'] as String?) ?? 'pendiente',
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semana_id': semanaId,
      'numero_dia': numeroDia,
      'nombre': nombre,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

class SerieSesionDb {
  const SerieSesionDb({
    required this.id,
    required this.sesionId,
    this.seleccionId,
    required this.numeroSerie,
    this.repeticionesRealizadas,
    this.pesoKg,
    required this.completada,
    required this.creadoEn,
  });

  final String id;
  final String sesionId;
  final String? seleccionId;
  final int numeroSerie;
  final int? repeticionesRealizadas;
  final double? pesoKg;
  final bool completada;
  final DateTime creadoEn;

  factory SerieSesionDb.fromMap(Map<String, dynamic> map) {
    return SerieSesionDb(
      id: map['id'] as String,
      sesionId: map['sesion_id'] as String,
      seleccionId: map['seleccion_id'] as String?,
      numeroSerie: _parseInt(map['numero_serie'], fallback: 1),
      repeticionesRealizadas: map['repeticiones_realizadas'] != null
          ? _parseInt(map['repeticiones_realizadas'])
          : null,
      pesoKg: map['peso_kg'] != null ? _parseDouble(map['peso_kg']) : null,
      completada: _parseBool(map['completada']),
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sesion_id': sesionId,
      if (seleccionId != null) 'seleccion_id': seleccionId,
      'numero_serie': numeroSerie,
      if (repeticionesRealizadas != null)
        'repeticiones_realizadas': repeticionesRealizadas,
      if (pesoKg != null) 'peso_kg': pesoKg,
      'completada': completada,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}

class UsuarioCarreraDb {
  const UsuarioCarreraDb({
    required this.id,
    required this.usuarioId,
    required this.carreraId,
    required this.creadoEn,
  });

  final String id;
  final String usuarioId;
  final String carreraId;
  final DateTime creadoEn;

  factory UsuarioCarreraDb.fromMap(Map<String, dynamic> map) {
    return UsuarioCarreraDb(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      carreraId: map['carrera_id'] as String,
      creadoEn: _parseDateTime(map['creado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'carrera_id': carreraId,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}
