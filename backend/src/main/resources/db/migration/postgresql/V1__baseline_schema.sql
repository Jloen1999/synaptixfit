-- Esquema base de SynaptixFit (PostgreSQL 17).
-- Consolida las 62 migraciones heredadas de Supabase en un único punto de partida.
-- Cambios respecto al esquema heredado: docs/01-architecture/data_model.md
-- Las reglas de negocio que antes vivían en funciones y triggers están ahora en el dominio Java.

CREATE TABLE recomendaciones_pendientes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    tipo text NOT NULL,
    titulo text NOT NULL,
    descripcion text,
    ejercicio_id uuid,
    rutina_id uuid,
    datos jsonb DEFAULT '{}'::jsonb,
    aplicada boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT recomendaciones_pendientes_tipo_check CHECK ((tipo = ANY (ARRAY['progresion'::text, 'degradacion'::text, 'descarga'::text, 'variante'::text, 'academico'::text])))
);

CREATE TABLE actividades_sociales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    tipo text NOT NULL,
    descripcion text NOT NULL,
    url_imagen text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    metadata text,
    reportado boolean DEFAULT false,
    reportado_por uuid,
    editado_en timestamp with time zone,
    CONSTRAINT ck_actividad_tipo CHECK ((tipo = ANY (ARRAY['session_completed'::text, 'challenge_completed'::text, 'milestone_reached'::text, 'badge_unlocked'::text, 'rutina'::text, 'reto'::text])))
);

CREATE TABLE admin_auditoria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid,
    accion text NOT NULL,
    entidad text NOT NULL,
    entidad_id uuid,
    detalle jsonb DEFAULT '{}'::jsonb,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE amistades (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    solicitante_id uuid NOT NULL,
    receptor_id uuid NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_amistad_estado CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'bloqueada'::text]))),
    CONSTRAINT ck_amistad_no_self CHECK ((solicitante_id <> receptor_id))
);

CREATE TABLE apuntes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    asignatura_id uuid,
    titulo text NOT NULL,
    contenido text DEFAULT ''::text NOT NULL,
    visibilidad text DEFAULT 'private'::text NOT NULL,
    es_nota_rapida boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT apuntes_visibilidad_check CHECK ((visibilidad = ANY (ARRAY['private'::text, 'friends'::text, 'public'::text]))),
    CONSTRAINT ck_apuntes_titulo_len CHECK ((char_length(titulo) >= 1))
);

CREATE TABLE archivos_asignatura (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    asignatura_id uuid NOT NULL,
    nombre_archivo text NOT NULL,
    cloudflare_object_key text NOT NULL,
    url_publica_o_firmada text NOT NULL,
    tamano_bytes bigint DEFAULT 0 NOT NULL,
    tipo_mime text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_archivos_nombre_len CHECK ((char_length(nombre_archivo) >= 1)),
    CONSTRAINT ck_archivos_tamano_pos CHECK ((tamano_bytes >= 0))
);

CREATE TABLE asignaturas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    nombre text NOT NULL,
    codigo text,
    descripcion text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    dificultad_percibida integer DEFAULT 3 NOT NULL,
    creditos integer DEFAULT 3 NOT NULL,
    prioridad text DEFAULT 'media'::text NOT NULL,
    proxima_evaluacion timestamp with time zone,
    docente text,
    archivado boolean DEFAULT false NOT NULL,
    catalogo_asignatura_id uuid,
    ics_url text,
    ultima_sincronizacion timestamp with time zone,
    CONSTRAINT ck_asignaturas_creditos CHECK (((creditos >= 1) AND (creditos <= 30))),
    CONSTRAINT ck_asignaturas_dificultad CHECK (((dificultad_percibida >= 1) AND (dificultad_percibida <= 5))),
    CONSTRAINT ck_asignaturas_nombre_len CHECK ((char_length(nombre) >= 2)),
    CONSTRAINT ck_asignaturas_prioridad CHECK ((prioridad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text])))
);

CREATE TABLE asignaturas_catalogo (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    carrera_id uuid NOT NULL,
    nombre text NOT NULL,
    curso integer,
    semestre integer,
    caracter text,
    creditos numeric(5,2),
    horas integer,
    departamento text,
    idioma_imparticion text,
    url_guia_docente text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE asignaturas_usuario_semestre (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    asignatura_id uuid NOT NULL,
    curso integer NOT NULL,
    semestre integer NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT asignaturas_usuario_semestre_curso_check CHECK ((curso >= 1)),
    CONSTRAINT asignaturas_usuario_semestre_semestre_check CHECK ((semestre = ANY (ARRAY[1, 2])))
);

CREATE TABLE bancos_preguntas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    material_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    xp_otorgado boolean DEFAULT false NOT NULL,
    generado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE bibliografia_asignatura (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asignatura_id uuid NOT NULL,
    referencia text NOT NULL
);

CREATE TABLE carga_academica_semanal (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    semana_inicio date NOT NULL,
    horas_estudio_planeadas integer DEFAULT 0 NOT NULL,
    horas_estudio_reales integer DEFAULT 0 NOT NULL,
    evaluaciones_semana integer DEFAULT 0 NOT NULL,
    entregas_semana integer DEFAULT 0 NOT NULL,
    nivel_estres integer DEFAULT 5 NOT NULL,
    horas_sueno_promedio double precision DEFAULT 7 NOT NULL,
    notas text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    xp_estudio_otorgado boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_carga_entregas CHECK (((entregas_semana >= 0) AND (entregas_semana <= 20))),
    CONSTRAINT ck_carga_estres CHECK (((nivel_estres >= 1) AND (nivel_estres <= 10))),
    CONSTRAINT ck_carga_evaluaciones CHECK (((evaluaciones_semana >= 0) AND (evaluaciones_semana <= 20))),
    CONSTRAINT ck_carga_horas_planeadas CHECK (((horas_estudio_planeadas >= 0) AND (horas_estudio_planeadas <= 120))),
    CONSTRAINT ck_carga_horas_reales CHECK (((horas_estudio_reales >= 0) AND (horas_estudio_reales <= 120))),
    CONSTRAINT ck_carga_sueno CHECK (((horas_sueno_promedio >= (0)::double precision) AND (horas_sueno_promedio <= (14)::double precision)))
);

CREATE TABLE carreras (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    centro_id uuid NOT NULL,
    nombre text NOT NULL,
    total_creditos integer,
    total_horas integer,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE centros (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    universidad_id uuid NOT NULL,
    nombre text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE comentarios_feed (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actividad_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    texto text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    editado_en timestamp with time zone,
    eliminado boolean DEFAULT false NOT NULL,
    reportado boolean DEFAULT false,
    CONSTRAINT comentarios_feed_texto_check CHECK (((char_length(texto) >= 1) AND (char_length(texto) <= 500)))
);

CREATE TABLE configuracion_global (
    id boolean DEFAULT true NOT NULL,
    lockdown_activo boolean DEFAULT false NOT NULL,
    lockdown_iniciado_en timestamp with time zone,
    lockdown_iniciado_por uuid,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT configuracion_global_id_check CHECK ((id = true))
);

CREATE TABLE criterios_evaluacion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asignatura_id uuid NOT NULL,
    examen_final_porcentaje real DEFAULT 0,
    evaluacion_continua_porcentaje real DEFAULT 0,
    practicas_laboratorio_porcentaje real DEFAULT 0
);

CREATE TABLE dias_rutina (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    semana_id uuid NOT NULL,
    numero_dia integer NOT NULL,
    nombre text DEFAULT ''::text NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_dias_rutina_numero_dia CHECK (((numero_dia >= 1) AND (numero_dia <= 7))),
    CONSTRAINT dias_rutina_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'en_progreso'::text, 'completado'::text])))
);

CREATE TABLE documentos_ia (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    asignatura_id uuid,
    fuente_tipo text NOT NULL,
    fuente_id text NOT NULL,
    tipo text NOT NULL,
    fuente_titulo text,
    contenido text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT documentos_ia_fuente_tipo_check CHECK ((fuente_tipo = ANY (ARRAY['apunte'::text, 'archivo'::text, 'guia_docente'::text, 'practica'::text]))),
    CONSTRAINT documentos_ia_tipo_check CHECK ((tipo = ANY (ARRAY['resumen'::text, 'mapa_mental'::text, 'guia_docente'::text, 'practica'::text])))
);

CREATE TABLE ejercicio_equipamiento (
    ejercicio_id uuid NOT NULL,
    equipamiento_id integer NOT NULL
);

CREATE TABLE ejercicio_musculo_objetivo (
    ejercicio_id uuid NOT NULL,
    musculo_id integer NOT NULL
);

CREATE TABLE ejercicio_musculo_secundario (
    ejercicio_id uuid NOT NULL,
    musculo_id integer NOT NULL
);

CREATE TABLE ejercicio_parte_cuerpo (
    ejercicio_id uuid NOT NULL,
    parte_cuerpo_id integer NOT NULL
);

CREATE TABLE ejercicios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    url_gif text,
    instrucciones text[] DEFAULT '{}'::text[] NOT NULL,
    dificultad text DEFAULT 'intermedio'::text NOT NULL,
    descripcion text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    finalidad text[] DEFAULT ARRAY['fuerza'::text] NOT NULL,
    url_preview text,
    modalidad_entrenamiento text DEFAULT 'fuerza'::text NOT NULL,
    tipo_medicion text[] DEFAULT ARRAY['repeticiones'::text] NOT NULL,
    es_circuito boolean DEFAULT false NOT NULL,
    activo boolean DEFAULT true,
    valor_met double precision DEFAULT 6.0 NOT NULL,
    CONSTRAINT ck_ejercicios_dificultad CHECK ((dificultad = ANY (ARRAY['principiante'::text, 'intermedio'::text, 'avanzado'::text])))
);

CREATE TABLE entregas_examenes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    asignatura_id uuid,
    titulo text NOT NULL,
    tipo text NOT NULL,
    fecha_limite timestamp with time zone NOT NULL,
    dificultad text DEFAULT 'media'::text NOT NULL,
    esta_completado boolean DEFAULT false NOT NULL,
    plan_estudio_id uuid,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    xp_entrega_otorgado boolean DEFAULT false NOT NULL,
    descripcion text,
    hora_inicio_str text,
    ics_uid text,
    CONSTRAINT entregas_examenes_dificultad_check CHECK ((dificultad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text]))),
    CONSTRAINT entregas_examenes_tipo_check CHECK ((tipo = ANY (ARRAY['examen'::text, 'entrega'::text, 'presentacion'::text, 'otro'::text])))
);

CREATE TABLE equipamientos (
    id integer NOT NULL,
    nombre text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE equipamientos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE equipamientos_id_seq OWNED BY equipamientos.id;

CREATE TABLE estado_cognitivo_usuario (
    usuario_id uuid NOT NULL,
    carga_cognitiva_actual numeric(6,4) DEFAULT 0 NOT NULL,
    capacidad_atencion_actual numeric(4,3) DEFAULT 1.000 NOT NULL,
    duracion_ultimo_bloque_min integer DEFAULT 0 NOT NULL,
    fecha_ultimo_descanso timestamp with time zone,
    rmr_base numeric(6,2),
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT estado_cognitivo_usuario_capacidad_atencion_actual_check CHECK (((capacidad_atencion_actual >= (0)::numeric) AND (capacidad_atencion_actual <= (1)::numeric)))
);

CREATE TABLE estado_diario_usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date DEFAULT CURRENT_DATE NOT NULL,
    calidad_sueno integer,
    nivel_estres integer,
    nivel_energia integer,
    dolor_muscular integer,
    zonas_dolor text[] DEFAULT '{}'::text[],
    listo_para_entrenar boolean DEFAULT true,
    notas text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT estado_diario_usuario_calidad_sueno_check CHECK (((calidad_sueno >= 1) AND (calidad_sueno <= 5))),
    CONSTRAINT estado_diario_usuario_dolor_muscular_check CHECK (((dolor_muscular >= 1) AND (dolor_muscular <= 5))),
    CONSTRAINT estado_diario_usuario_nivel_energia_check CHECK (((nivel_energia >= 1) AND (nivel_energia <= 5))),
    CONSTRAINT estado_diario_usuario_nivel_estres_check CHECK (((nivel_estres >= 1) AND (nivel_estres <= 5)))
);

CREATE TABLE estado_regulacion_cruzada (
    usuario_id uuid NOT NULL,
    carga_aguda_7d numeric(8,2),
    carga_cronica_28d numeric(8,2),
    acwr_actual numeric(4,2) GENERATED ALWAYS AS ((carga_aguda_7d / NULLIF(carga_cronica_28d, (0)::numeric))) STORED,
    min_estudio_max_recomendado integer DEFAULT 90 NOT NULL,
    dias_proximo_examen integer,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE historial_objetivos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    objetivo text NOT NULL,
    objetivo_anterior text,
    fecha_inicio date DEFAULT CURRENT_DATE NOT NULL,
    fecha_fin date,
    rutina_ids uuid[] DEFAULT '{}'::uuid[],
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE historial_peso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    peso_kg double precision NOT NULL,
    altura_cm double precision NOT NULL,
    imc double precision NOT NULL,
    registrado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_hist_altura CHECK (((altura_cm >= (120)::double precision) AND (altura_cm <= (230)::double precision))),
    CONSTRAINT ck_hist_imc CHECK ((imc > (0)::double precision)),
    CONSTRAINT ck_hist_peso CHECK (((peso_kg >= (30)::double precision) AND (peso_kg <= (250)::double precision)))
);

CREATE TABLE hitos_de_reto (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reto_id uuid NOT NULL,
    titulo text NOT NULL,
    porcentaje_peso double precision NOT NULL,
    indice_orden integer NOT NULL,
    progreso_actual double precision DEFAULT 0 NOT NULL,
    esta_completado boolean DEFAULT false NOT NULL,
    estado text DEFAULT 'bloqueado'::text NOT NULL,
    dependencias uuid[] DEFAULT '{}'::uuid[],
    tipo_condicion text DEFAULT 'AND'::text NOT NULL,
    condicion_n integer DEFAULT 1 NOT NULL,
    asignatura_id uuid,
    dificultad text DEFAULT 'media'::text NOT NULL,
    entidad_vinculada_id uuid,
    entidad_vinculada_tipo text,
    xp_otorgado integer DEFAULT 0 NOT NULL,
    apunte_id uuid,
    archivo_id uuid,
    CONSTRAINT ck_hitos_adjunto_unico CHECK (((apunte_id IS NULL) OR (archivo_id IS NULL))),
    CONSTRAINT ck_hitos_dificultad CHECK ((dificultad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text]))),
    CONSTRAINT ck_hitos_entidad_tipo CHECK (((entidad_vinculada_tipo IS NULL) OR (entidad_vinculada_tipo = ANY (ARRAY['examen'::text, 'entrega'::text, 'bloque'::text])))),
    CONSTRAINT ck_hitos_peso CHECK (((porcentaje_peso > (0)::double precision) AND (porcentaje_peso <= (100)::double precision))),
    CONSTRAINT ck_hitos_progreso CHECK (((progreso_actual >= (0)::double precision) AND (progreso_actual <= (100)::double precision))),
    CONSTRAINT ck_hitos_titulo_len CHECK (((char_length(titulo) >= 3) AND (char_length(titulo) <= 80))),
    CONSTRAINT hitos_de_reto_condicion_n_check CHECK ((condicion_n >= 1)),
    CONSTRAINT hitos_de_reto_estado_check CHECK ((estado = ANY (ARRAY['bloqueado'::text, 'disponible'::text, 'en_progreso'::text, 'completado'::text]))),
    CONSTRAINT hitos_de_reto_tipo_condicion_check CHECK ((tipo_condicion = ANY (ARRAY['AND'::text, 'OR'::text, 'X_OF_Y'::text])))
);

CREATE TABLE horarios_academicos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    asignatura_id uuid,
    hora_inicio timestamp with time zone NOT NULL,
    hora_fin timestamp with time zone NOT NULL,
    ubicacion text,
    tiene_conflicto boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    plan_estudio_id uuid,
    prioridad text DEFAULT 'media'::text NOT NULL,
    tipo_actividad text DEFAULT 'estudio'::text NOT NULL,
    rutina_id uuid,
    temas text,
    completado boolean DEFAULT false NOT NULL,
    asistencia_registrada_en timestamp with time zone,
    es_fijo boolean DEFAULT false NOT NULL,
    dia_semana integer,
    xp_bloque_otorgado boolean DEFAULT false NOT NULL,
    reto_id uuid,
    hito_id uuid,
    dia_rutina_id uuid,
    semana_rutina_id uuid,
    entrega_examen_id uuid,
    es_hito_inamovible boolean DEFAULT false NOT NULL,
    ics_uid text,
    is_private boolean DEFAULT false NOT NULL,
    tipo_clase character varying,
    met_value numeric(4,2) DEFAULT 1.30,
    calorias_quemadas numeric(6,2),
    carga_cognitiva_generada numeric(6,4),
    CONSTRAINT ck_horarios_dia_semana CHECK (((dia_semana IS NULL) OR ((dia_semana >= 1) AND (dia_semana <= 7)))),
    CONSTRAINT ck_horarios_duracion CHECK ((EXTRACT(epoch FROM (hora_fin - hora_inicio)) >= (1800)::numeric)),
    CONSTRAINT ck_horarios_tiempo CHECK ((hora_fin > hora_inicio)),
    CONSTRAINT ck_horarios_tipo_actividad CHECK ((tipo_actividad = ANY (ARRAY['estudio'::text, 'deporte'::text, 'clase'::text, 'descanso'::text, 'comida'::text, 'sueno'::text, 'examen'::text, 'entrega'::text, 'repaso'::text]))),
    CONSTRAINT horarios_academicos_prioridad_check CHECK ((prioridad = ANY (ARRAY['alta'::text, 'media'::text, 'baja'::text])))
);

CREATE TABLE insignias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    descripcion text NOT NULL,
    icono text DEFAULT '🏅'::text NOT NULL,
    categoria text NOT NULL,
    criterio_tipo text NOT NULL,
    criterio_valor integer DEFAULT 1 NOT NULL,
    rareza text DEFAULT 'comun'::text NOT NULL,
    orden integer DEFAULT 0 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT insignias_categoria_check CHECK ((categoria = ANY (ARRAY['entrenamiento'::text, 'estudio'::text, 'social'::text, 'racha'::text, 'especial'::text]))),
    CONSTRAINT insignias_rareza_check CHECK ((rareza = ANY (ARRAY['comun'::text, 'rara'::text, 'epica'::text, 'legendaria'::text])))
);

CREATE TABLE intentos_pregunta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    pregunta_id uuid NOT NULL,
    es_correcta boolean NOT NULL,
    respondido_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE interacciones_sociales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actividad_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    tipo_interaccion text DEFAULT 'like'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_interaccion_tipo CHECK ((tipo_interaccion = 'like'::text))
);

CREATE TABLE materiales_estudio (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    asignatura_id uuid NOT NULL,
    tipo_origen text NOT NULL,
    origen_id uuid NOT NULL,
    titulo text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    estado_dominio text DEFAULT 'sin_evaluar'::text NOT NULL,
    ultimo_repaso_en timestamp with time zone,
    siguiente_repaso_en timestamp with time zone,
    intervalo_actual_dias integer DEFAULT 0,
    facilidad real DEFAULT 2.5,
    repasos_completados integer DEFAULT 0,
    repasos_fallidos integer DEFAULT 0,
    xp_practica_otorgado boolean DEFAULT false NOT NULL,
    CONSTRAINT materiales_estudio_estado_dominio_check CHECK ((estado_dominio = ANY (ARRAY['sin_evaluar'::text, 'dominado'::text, 'en_progreso'::text, 'necesita_repaso'::text, 'abandonado'::text]))),
    CONSTRAINT materiales_estudio_tipo_origen_check CHECK ((tipo_origen = ANY (ARRAY['archivo'::text, 'apunte'::text])))
);

CREATE TABLE musculos (
    id integer NOT NULL,
    nombre text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    url_imagen text
);

CREATE SEQUENCE musculos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE musculos_id_seq OWNED BY musculos.id;

CREATE TABLE notificaciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    titulo text NOT NULL,
    descripcion text,
    prioridad text NOT NULL,
    tipo text NOT NULL,
    url_accion text,
    etiqueta_accion text,
    esta_leida boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    leida_en timestamp with time zone,
    CONSTRAINT ck_notif_prioridad CHECK ((prioridad = ANY (ARRAY['critical'::text, 'recommended'::text, 'informative'::text]))),
    CONSTRAINT ck_notif_tipo CHECK ((tipo = ANY (ARRAY['conflict'::text, 'fatigue_alert'::text, 'milestone'::text, 'social'::text, 'academic'::text])))
);

CREATE TABLE partes_cuerpo (
    id integer NOT NULL,
    nombre text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE partes_cuerpo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE partes_cuerpo_id_seq OWNED BY partes_cuerpo.id;

CREATE TABLE perfil_academico_usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    universidad text,
    carrera text,
    semestre_actual integer DEFAULT 1 NOT NULL,
    modalidad text DEFAULT 'presencial'::text NOT NULL,
    creditos_semestre_actual integer DEFAULT 20 NOT NULL,
    horas_objetivo_estudio_semana integer DEFAULT 14 NOT NULL,
    promedio_objetivo double precision,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    fecha_inicio_clases date,
    fecha_fin_clases date,
    CONSTRAINT ck_perfil_acad_creditos CHECK (((creditos_semestre_actual >= 1) AND (creditos_semestre_actual <= 60))),
    CONSTRAINT ck_perfil_acad_horas CHECK (((horas_objetivo_estudio_semana >= 0) AND (horas_objetivo_estudio_semana <= 80))),
    CONSTRAINT ck_perfil_acad_modalidad CHECK ((modalidad = ANY (ARRAY['presencial'::text, 'hibrida'::text, 'virtual'::text]))),
    CONSTRAINT ck_perfil_acad_promedio CHECK (((promedio_objetivo IS NULL) OR ((promedio_objetivo >= (0)::double precision) AND (promedio_objetivo <= (5)::double precision)))),
    CONSTRAINT ck_perfil_acad_semestre CHECK (((semestre_actual >= 1) AND (semestre_actual <= 20)))
);

CREATE TABLE perfil_bienestar_usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    edad integer NOT NULL,
    sexo text NOT NULL,
    ciudad text,
    peso_kg double precision NOT NULL,
    altura_cm double precision NOT NULL,
    imc double precision NOT NULL,
    nivel_actividad text DEFAULT 'sedentario'::text NOT NULL,
    objetivo_principal text DEFAULT 'fitness_general'::text NOT NULL,
    objetivos text[] DEFAULT '{}'::text[] NOT NULL,
    equipamiento_disponible text[] DEFAULT '{}'::text[] NOT NULL,
    dias_disponibles_semana integer DEFAULT 3 NOT NULL,
    minutos_por_sesion integer DEFAULT 45 NOT NULL,
    onboarding_completado boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    dias_disponibles integer[] DEFAULT '{1,3,5}'::integer[],
    CONSTRAINT ck_perfil_altura CHECK (((altura_cm >= (120)::double precision) AND (altura_cm <= (230)::double precision))),
    CONSTRAINT ck_perfil_dias CHECK (((dias_disponibles_semana >= 1) AND (dias_disponibles_semana <= 7))),
    CONSTRAINT ck_perfil_edad CHECK (((edad >= 15) AND (edad <= 80))),
    CONSTRAINT ck_perfil_imc CHECK ((imc > (0)::double precision)),
    CONSTRAINT ck_perfil_minutos CHECK (((minutos_por_sesion >= 10) AND (minutos_por_sesion <= 180))),
    CONSTRAINT ck_perfil_nivel_actividad CHECK ((nivel_actividad = ANY (ARRAY['sedentario'::text, 'ligero'::text, 'moderado'::text, 'alto'::text]))),
    CONSTRAINT ck_perfil_objetivo_estandar CHECK ((objetivo_principal = ANY (ARRAY['Hipertrofia Muscular'::text, 'Fuerza Máxima'::text, 'Potencia y Explosividad'::text, 'Fuerza Resistencia'::text, 'Movilidad y Flexibilidad'::text, 'Estabilidad y Control Motor'::text, 'Acondicionamiento Metabólico'::text]))),
    CONSTRAINT ck_perfil_peso CHECK (((peso_kg >= (30)::double precision) AND (peso_kg <= (250)::double precision))),
    CONSTRAINT ck_perfil_sexo CHECK ((sexo = ANY (ARRAY['hombre'::text, 'mujer'::text, 'no_binario'::text, 'prefiero_no_decirlo'::text])))
);

CREATE TABLE plan_entrenamiento_semanal (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    semana_inicio date NOT NULL,
    sesiones_planificadas integer DEFAULT 3 NOT NULL,
    intensidad text DEFAULT 'moderada'::text NOT NULL,
    duracion_min_por_sesion integer DEFAULT 45 NOT NULL,
    estado text DEFAULT 'activo'::text NOT NULL,
    notas text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_plan_duracion CHECK (((duracion_min_por_sesion >= 10) AND (duracion_min_por_sesion <= 180))),
    CONSTRAINT ck_plan_estado CHECK ((estado = ANY (ARRAY['activo'::text, 'pausado'::text, 'completado'::text, 'ajustado'::text]))),
    CONSTRAINT ck_plan_intensidad CHECK ((intensidad = ANY (ARRAY['baja'::text, 'moderada'::text, 'alta'::text]))),
    CONSTRAINT ck_plan_sesiones CHECK (((sesiones_planificadas >= 1) AND (sesiones_planificadas <= 7)))
);

CREATE TABLE planes_estudio (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    nombre text NOT NULL,
    semana_inicio date NOT NULL,
    semana_fin date NOT NULL,
    visibilidad text DEFAULT 'private'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    xp_planificacion_otorgado boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_planes_fechas CHECK ((semana_fin >= semana_inicio)),
    CONSTRAINT ck_planes_nombre_len CHECK ((char_length(nombre) >= 2)),
    CONSTRAINT planes_estudio_visibilidad_check CHECK ((visibilidad = ANY (ARRAY['private'::text, 'friends'::text, 'public'::text])))
);

CREATE TABLE preferencias_notificacion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    categorias_activas text[] DEFAULT '{conflict,fatigue_alert,milestone,social,academic}'::text[] NOT NULL,
    hora_silencio_inicio time without time zone,
    hora_silencio_fin time without time zone,
    limite_diario integer DEFAULT 10 NOT NULL,
    modo_actual text DEFAULT 'normal'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_pref_limite CHECK (((limite_diario >= 0) AND (limite_diario <= 50))),
    CONSTRAINT ck_pref_modo CHECK ((modo_actual = ANY (ARRAY['normal'::text, 'examenes'::text, 'descanso'::text])))
);

CREATE TABLE preguntas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    banco_id uuid NOT NULL,
    tipo text NOT NULL,
    enunciado text NOT NULL,
    opciones jsonb,
    respuesta_correcta text NOT NULL,
    explicacion text,
    orden integer DEFAULT 0 NOT NULL,
    CONSTRAINT preguntas_tipo_check CHECK ((tipo = ANY (ARRAY['opcion_multiple'::text, 'rellenar_hueco'::text])))
);

CREATE TABLE prerrequisitos_asignatura (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asignatura_id uuid NOT NULL,
    nombre_asignatura text NOT NULL
);

CREATE TABLE profesores_asignatura (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asignatura_id uuid NOT NULL,
    nombre_completo text NOT NULL
);

CREATE TABLE progreso_de_reto (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reto_id uuid NOT NULL,
    hito_id uuid,
    usuario_id uuid NOT NULL,
    cantidad_completada double precision NOT NULL,
    registrado_en timestamp with time zone NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_progreso_cantidad CHECK ((cantidad_completada >= (0)::double precision))
);

CREATE TABLE registros_carga_fisica (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    fecha_registro date DEFAULT CURRENT_DATE NOT NULL,
    rpe_sesion smallint NOT NULL,
    duracion_minutos integer NOT NULL,
    carga_diaria numeric(7,2) GENERATED ALWAYS AS ((rpe_sesion * duracion_minutos)) STORED,
    sesion_id uuid,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT registros_carga_fisica_duracion_minutos_check CHECK ((duracion_minutos > 0)),
    CONSTRAINT registros_carga_fisica_rpe_sesion_check CHECK (((rpe_sesion >= 1) AND (rpe_sesion <= 10)))
);

CREATE TABLE registros_repaso_srs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    material_estudio_id uuid NOT NULL,
    fecha_repaso timestamp with time zone DEFAULT now() NOT NULL,
    q_real smallint NOT NULL,
    q_ajustado numeric(3,2) NOT NULL,
    coeficiente_fatiga numeric(4,3) DEFAULT 0 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT registros_repaso_srs_q_real_check CHECK (((q_real >= 0) AND (q_real <= 5)))
);

CREATE TABLE retos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    titulo text NOT NULL,
    tipo text NOT NULL,
    meta text NOT NULL,
    visibilidad text DEFAULT 'private'::text NOT NULL,
    esta_completado boolean DEFAULT false NOT NULL,
    fecha_inicio timestamp with time zone NOT NULL,
    fecha_fin timestamp with time zone NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    racha_actual integer DEFAULT 0 NOT NULL,
    mejor_racha integer DEFAULT 0 NOT NULL,
    ultimo_dia_activo date,
    tiene_dependencias boolean DEFAULT false NOT NULL,
    asignatura_id uuid,
    dificultad text DEFAULT 'media'::text NOT NULL,
    entidad_vinculada_id uuid,
    entidad_vinculada_tipo text,
    xp_otorgado integer DEFAULT 0 NOT NULL,
    origen_id uuid,
    origen_propietario_id uuid,
    origen_propietario_nombre text,
    CONSTRAINT ck_retos_dificultad CHECK ((dificultad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text]))),
    CONSTRAINT ck_retos_entidad_tipo CHECK (((entidad_vinculada_tipo IS NULL) OR (entidad_vinculada_tipo = ANY (ARRAY['examen'::text, 'entrega'::text, 'bloque'::text])))),
    CONSTRAINT ck_retos_fechas CHECK ((fecha_fin > fecha_inicio)),
    CONSTRAINT ck_retos_tipo CHECK ((tipo = ANY (ARRAY['fitness'::text, 'academic'::text]))),
    CONSTRAINT ck_retos_titulo_len CHECK (((char_length(titulo) >= 5) AND (char_length(titulo) <= 80))),
    CONSTRAINT ck_retos_visibilidad CHECK ((visibilidad = ANY (ARRAY['private'::text, 'friends'::text, 'public'::text])))
);

CREATE TABLE rutinas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    nombre text NOT NULL,
    descripcion text,
    visibilidad text DEFAULT 'private'::text NOT NULL,
    cantidad_ejercicios integer DEFAULT 0 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    eliminado_en timestamp with time zone,
    duracion_semanas integer DEFAULT 1 NOT NULL,
    estado text DEFAULT 'activo'::text NOT NULL,
    objetivo text DEFAULT 'fuerza'::text NOT NULL,
    fecha_inicio date,
    origen_id uuid,
    origen_propietario_id uuid,
    origen_propietario_nombre text,
    CONSTRAINT ck_rutinas_cantidad CHECK ((cantidad_ejercicios >= 0)),
    CONSTRAINT ck_rutinas_nombre_len CHECK ((char_length(nombre) >= 3)),
    CONSTRAINT ck_rutinas_visibilidad CHECK ((visibilidad = ANY (ARRAY['private'::text, 'friends'::text, 'public'::text]))),
    CONSTRAINT rutinas_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'pausado'::text, 'completado'::text, 'archivado'::text]))),
    CONSTRAINT rutinas_objetivo_check CHECK ((objetivo = ANY (ARRAY['Hipertrofia Muscular'::text, 'Fuerza Máxima'::text, 'Potencia y Explosividad'::text, 'Fuerza Resistencia'::text, 'Movilidad y Flexibilidad'::text, 'Estabilidad y Control Motor'::text, 'Acondicionamiento Metabólico'::text])))
);

CREATE TABLE seleccion_de_ejercicios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rutina_id uuid NOT NULL,
    ejercicio_id uuid NOT NULL,
    series integer DEFAULT 3 NOT NULL,
    repeticiones integer DEFAULT 10 NOT NULL,
    segundos_descanso integer DEFAULT 90 NOT NULL,
    indice_orden integer NOT NULL,
    dia_id uuid,
    peso_kg double precision,
    duracion_objetivo_segundos integer,
    distancia_metros integer,
    tiempo_isometrico_segundos integer,
    pesos_kg jsonb,
    duracion_real_segundos integer,
    CONSTRAINT ck_sel_descanso CHECK (((segundos_descanso >= 30) AND (segundos_descanso <= 300))),
    CONSTRAINT ck_sel_repeticiones CHECK (((repeticiones >= 1) AND (repeticiones <= 100))),
    CONSTRAINT ck_sel_series CHECK (((series >= 1) AND (series <= 10)))
);

CREATE TABLE semanas_rutina (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rutina_id uuid NOT NULL,
    numero_semana integer NOT NULL,
    nombre text DEFAULT ''::text NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    tipo_semana text DEFAULT 'carga'::text,
    CONSTRAINT semanas_rutina_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'en_progreso'::text, 'completada'::text]))),
    CONSTRAINT semanas_rutina_tipo_semana_check CHECK ((tipo_semana = ANY (ARRAY['adaptacion'::text, 'carga'::text, 'pico'::text, 'descarga'::text])))
);

CREATE TABLE series_sesion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sesion_id uuid NOT NULL,
    seleccion_id uuid,
    numero_serie integer NOT NULL,
    repeticiones_realizadas integer,
    peso_kg double precision,
    completada boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    failed_reps integer DEFAULT 0 NOT NULL,
    CONSTRAINT series_sesion_failed_reps_check CHECK ((failed_reps >= 0))
);

CREATE TABLE sesiones_focus (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    duracion_minutos integer DEFAULT 25 NOT NULL,
    ciclos_completados integer DEFAULT 1 NOT NULL,
    tipo_fase text DEFAULT 'focus'::text NOT NULL,
    completada boolean DEFAULT true NOT NULL,
    fecha date DEFAULT CURRENT_DATE NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sesiones_focus_tipo_fase_check CHECK ((tipo_fase = ANY (ARRAY['focus'::text, 'short_break'::text, 'long_break'::text])))
);

CREATE TABLE sesiones_registradas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    rutina_id uuid,
    duracion_minutos integer NOT NULL,
    calorias_quemadas double precision,
    rpe integer,
    completada_en timestamp with time zone NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    dia_id uuid,
    tipo text DEFAULT 'libre'::text NOT NULL,
    CONSTRAINT ck_sesiones_duracion CHECK ((duracion_minutos > 0)),
    CONSTRAINT ck_sesiones_rpe CHECK (((rpe IS NULL) OR ((rpe >= 1) AND (rpe <= 10)))),
    CONSTRAINT sesiones_registradas_tipo_check CHECK ((tipo = ANY (ARRAY['libre'::text, 'rutina'::text, 'semanal'::text])))
);

CREATE TABLE test_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    material_id uuid NOT NULL,
    preguntas_ids jsonb DEFAULT '[]'::jsonb NOT NULL,
    respuestas jsonb DEFAULT '{}'::jsonb NOT NULL,
    resultados jsonb DEFAULT '{}'::jsonb NOT NULL,
    indice_actual integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'in_progress'::text NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    total_preguntas integer DEFAULT 0 NOT NULL,
    iniciado_en timestamp with time zone DEFAULT now() NOT NULL,
    completado_en timestamp with time zone,
    xp_otorgado boolean DEFAULT false NOT NULL,
    CONSTRAINT test_sessions_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'completed'::text, 'abandoned'::text])))
);

CREATE TABLE universidades (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE usuario_carreras (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    carrera_id uuid NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE usuario_insignias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    insignia_id uuid NOT NULL,
    obtenida_en timestamp with time zone DEFAULT now() NOT NULL,
    notificada boolean DEFAULT false NOT NULL,
    visible boolean DEFAULT true NOT NULL
);

CREATE TABLE usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    password_hash text,
    google_sub text,
    nombre_completo text NOT NULL,
    url_avatar text,
    nivel integer DEFAULT 1 NOT NULL,
    xp_nivel_actual integer DEFAULT 0 NOT NULL,
    racha_actual integer DEFAULT 0 NOT NULL,
    nivel_privacidad text DEFAULT 'private'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    eliminado_en timestamp with time zone,
    rol text DEFAULT 'usuario'::text NOT NULL,
    is_shadowbanned boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_usuarios_email_len CHECK ((char_length(email) >= 5)),
    CONSTRAINT ck_usuarios_nivel CHECK ((nivel >= 1)),
    CONSTRAINT ck_usuarios_nombre_len CHECK ((char_length(nombre_completo) >= 2)),
    CONSTRAINT ck_usuarios_privacidad CHECK ((nivel_privacidad = ANY (ARRAY['public'::text, 'friends'::text, 'private'::text]))),
    CONSTRAINT ck_usuarios_racha_actual CHECK ((racha_actual >= 0)),
    CONSTRAINT ck_usuarios_xp_nivel_actual CHECK ((xp_nivel_actual >= 0)),
    CONSTRAINT usuarios_rol_check CHECK ((rol = ANY (ARRAY['usuario'::text, 'admin'::text]))),
    CONSTRAINT ck_usuarios_credencial CHECK (((password_hash IS NOT NULL) OR (google_sub IS NOT NULL)))
);

CREATE OR REPLACE VIEW v_admin_metricas AS
 SELECT ( SELECT count(*) AS count
           FROM usuarios) AS total_usuarios,
    ( SELECT count(DISTINCT sesiones_registradas.usuario_id) AS count
           FROM sesiones_registradas
          WHERE ((sesiones_registradas.completada_en)::date = CURRENT_DATE)) AS usuarios_activos_hoy,
    ( SELECT count(*) AS count
           FROM sesiones_registradas
          WHERE ((sesiones_registradas.completada_en)::date = CURRENT_DATE)) AS sesiones_hoy,
    ( SELECT count(*) AS count
           FROM rutinas
          WHERE (rutinas.eliminado_en IS NULL)) AS rutinas_activas,
    ( SELECT count(*) AS count
           FROM retos
          WHERE (retos.esta_completado = false)) AS retos_activos,
    (( SELECT count(*) AS count
           FROM actividades_sociales
          WHERE (actividades_sociales.reportado = true)) + ( SELECT count(*) AS count
           FROM comentarios_feed
          WHERE ((comentarios_feed.reportado = true) AND (comentarios_feed.eliminado = false)))) AS contenido_reportado_pendiente;

CREATE OR REPLACE VIEW v_analitica_semanal AS
 SELECT usuario_id,
    (date_trunc('week'::text, completada_en))::date AS semana_inicio,
    (count(*))::integer AS sesiones,
    COALESCE(round(avg(rpe), 1), (0)::numeric) AS rpe_promedio,
    (COALESCE(sum(duracion_minutos), (0)::bigint))::integer AS minutos_totales,
    (COALESCE(sum(calorias_quemadas), (0)::double precision))::integer AS calorias_totales
   FROM sesiones_registradas
  WHERE (completada_en IS NOT NULL)
  GROUP BY usuario_id, ((date_trunc('week'::text, completada_en))::date)
  ;

CREATE OR REPLACE VIEW v_ejercicios_completos AS
 SELECT id,
    nombre,
    url_gif,
    url_preview,
    instrucciones,
    dificultad,
    descripcion,
    finalidad,
    modalidad_entrenamiento,
    tipo_medicion,
    es_circuito,
    valor_met,
    COALESCE(( SELECT string_agg(DISTINCT pc.nombre, ', '::text) AS string_agg
           FROM (ejercicio_parte_cuerpo epc
             JOIN partes_cuerpo pc ON ((pc.id = epc.parte_cuerpo_id)))
          WHERE (epc.ejercicio_id = e.id)), ''::text) AS partes_cuerpo,
    COALESCE(( SELECT string_agg(DISTINCT m.nombre, ', '::text) AS string_agg
           FROM (ejercicio_musculo_objetivo emo
             JOIN musculos m ON ((m.id = emo.musculo_id)))
          WHERE (emo.ejercicio_id = e.id)), ''::text) AS musculos_objetivo,
    COALESCE(( SELECT string_agg(DISTINCT m.nombre, ', '::text) AS string_agg
           FROM (ejercicio_musculo_secundario ems
             JOIN musculos m ON ((m.id = ems.musculo_id)))
          WHERE (ems.ejercicio_id = e.id)), ''::text) AS musculos_secundarios,
    COALESCE(( SELECT string_agg(DISTINCT eq.nombre, ', '::text) AS string_agg
           FROM (ejercicio_equipamiento eeq
             JOIN equipamientos eq ON ((eq.id = eeq.equipamiento_id)))
          WHERE (eeq.ejercicio_id = e.id)), ''::text) AS equipamientos,
    creado_en
   FROM ejercicios e;

ALTER TABLE ONLY equipamientos ALTER COLUMN id SET DEFAULT nextval('equipamientos_id_seq'::regclass);

ALTER TABLE ONLY musculos ALTER COLUMN id SET DEFAULT nextval('musculos_id_seq'::regclass);

ALTER TABLE ONLY partes_cuerpo ALTER COLUMN id SET DEFAULT nextval('partes_cuerpo_id_seq'::regclass);

ALTER TABLE ONLY actividades_sociales
    ADD CONSTRAINT actividades_sociales_pkey PRIMARY KEY (id);

ALTER TABLE ONLY admin_auditoria
    ADD CONSTRAINT admin_auditoria_pkey PRIMARY KEY (id);

ALTER TABLE ONLY amistades
    ADD CONSTRAINT amistades_pkey PRIMARY KEY (id);

ALTER TABLE ONLY amistades
    ADD CONSTRAINT amistades_solicitante_id_receptor_id_key UNIQUE (solicitante_id, receptor_id);

ALTER TABLE ONLY apuntes
    ADD CONSTRAINT apuntes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY archivos_asignatura
    ADD CONSTRAINT archivos_asignatura_pkey PRIMARY KEY (id);

ALTER TABLE ONLY asignaturas_catalogo
    ADD CONSTRAINT asignaturas_catalogo_carrera_id_nombre_key UNIQUE (carrera_id, nombre);

ALTER TABLE ONLY asignaturas_catalogo
    ADD CONSTRAINT asignaturas_catalogo_pkey PRIMARY KEY (id);

ALTER TABLE ONLY asignaturas
    ADD CONSTRAINT asignaturas_pkey PRIMARY KEY (id);

ALTER TABLE ONLY asignaturas_usuario_semestre
    ADD CONSTRAINT asignaturas_usuario_semestre_pkey PRIMARY KEY (id);

ALTER TABLE ONLY asignaturas_usuario_semestre
    ADD CONSTRAINT asignaturas_usuario_semestre_usuario_id_asignatura_id_key UNIQUE (usuario_id, asignatura_id);

ALTER TABLE ONLY bancos_preguntas
    ADD CONSTRAINT bancos_preguntas_pkey PRIMARY KEY (id);

ALTER TABLE ONLY bibliografia_asignatura
    ADD CONSTRAINT bibliografia_asignatura_pkey PRIMARY KEY (id);

ALTER TABLE ONLY carga_academica_semanal
    ADD CONSTRAINT carga_academica_semanal_pkey PRIMARY KEY (id);

ALTER TABLE ONLY carga_academica_semanal
    ADD CONSTRAINT carga_academica_semanal_usuario_id_semana_inicio_key UNIQUE (usuario_id, semana_inicio);

ALTER TABLE ONLY carreras
    ADD CONSTRAINT carreras_centro_id_nombre_key UNIQUE (centro_id, nombre);

ALTER TABLE ONLY carreras
    ADD CONSTRAINT carreras_pkey PRIMARY KEY (id);

ALTER TABLE ONLY centros
    ADD CONSTRAINT centros_pkey PRIMARY KEY (id);

ALTER TABLE ONLY centros
    ADD CONSTRAINT centros_universidad_id_nombre_key UNIQUE (universidad_id, nombre);

ALTER TABLE ONLY comentarios_feed
    ADD CONSTRAINT comentarios_feed_pkey PRIMARY KEY (id);

ALTER TABLE ONLY configuracion_global
    ADD CONSTRAINT configuracion_global_pkey PRIMARY KEY (id);

ALTER TABLE ONLY criterios_evaluacion
    ADD CONSTRAINT criterios_evaluacion_asignatura_id_key UNIQUE (asignatura_id);

ALTER TABLE ONLY criterios_evaluacion
    ADD CONSTRAINT criterios_evaluacion_pkey PRIMARY KEY (id);

ALTER TABLE ONLY dias_rutina
    ADD CONSTRAINT dias_rutina_pkey PRIMARY KEY (id);

ALTER TABLE ONLY dias_rutina
    ADD CONSTRAINT dias_rutina_semana_id_numero_dia_key UNIQUE (semana_id, numero_dia);

ALTER TABLE ONLY documentos_ia
    ADD CONSTRAINT documentos_ia_pkey PRIMARY KEY (id);

ALTER TABLE ONLY documentos_ia
    ADD CONSTRAINT documentos_ia_unico UNIQUE (usuario_id, fuente_tipo, fuente_id, tipo);

ALTER TABLE ONLY ejercicio_equipamiento
    ADD CONSTRAINT ejercicio_equipamiento_pkey PRIMARY KEY (ejercicio_id, equipamiento_id);

ALTER TABLE ONLY ejercicio_musculo_objetivo
    ADD CONSTRAINT ejercicio_musculo_objetivo_pkey PRIMARY KEY (ejercicio_id, musculo_id);

ALTER TABLE ONLY ejercicio_musculo_secundario
    ADD CONSTRAINT ejercicio_musculo_secundario_pkey PRIMARY KEY (ejercicio_id, musculo_id);

ALTER TABLE ONLY ejercicio_parte_cuerpo
    ADD CONSTRAINT ejercicio_parte_cuerpo_pkey PRIMARY KEY (ejercicio_id, parte_cuerpo_id);

ALTER TABLE ONLY ejercicios
    ADD CONSTRAINT ejercicios_pkey PRIMARY KEY (id);

ALTER TABLE ONLY entregas_examenes
    ADD CONSTRAINT entregas_examenes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY equipamientos
    ADD CONSTRAINT equipamientos_nombre_key UNIQUE (nombre);

ALTER TABLE ONLY equipamientos
    ADD CONSTRAINT equipamientos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY estado_cognitivo_usuario
    ADD CONSTRAINT estado_cognitivo_usuario_pkey PRIMARY KEY (usuario_id);

ALTER TABLE ONLY estado_diario_usuario
    ADD CONSTRAINT estado_diario_usuario_pkey PRIMARY KEY (id);

ALTER TABLE ONLY estado_diario_usuario
    ADD CONSTRAINT estado_diario_usuario_usuario_id_fecha_key UNIQUE (usuario_id, fecha);

ALTER TABLE ONLY estado_regulacion_cruzada
    ADD CONSTRAINT estado_regulacion_cruzada_pkey PRIMARY KEY (usuario_id);

ALTER TABLE ONLY historial_objetivos
    ADD CONSTRAINT historial_objetivos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY historial_peso
    ADD CONSTRAINT historial_peso_pkey PRIMARY KEY (id);

ALTER TABLE ONLY hitos_de_reto
    ADD CONSTRAINT hitos_de_reto_pkey PRIMARY KEY (id);

ALTER TABLE ONLY hitos_de_reto
    ADD CONSTRAINT hitos_de_reto_reto_id_indice_orden_key UNIQUE (reto_id, indice_orden);

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY insignias
    ADD CONSTRAINT insignias_nombre_key UNIQUE (nombre);

ALTER TABLE ONLY insignias
    ADD CONSTRAINT insignias_pkey PRIMARY KEY (id);

ALTER TABLE ONLY intentos_pregunta
    ADD CONSTRAINT intentos_pregunta_pkey PRIMARY KEY (id);

ALTER TABLE ONLY interacciones_sociales
    ADD CONSTRAINT interacciones_sociales_actividad_id_usuario_id_tipo_interac_key UNIQUE (actividad_id, usuario_id, tipo_interaccion);

ALTER TABLE ONLY interacciones_sociales
    ADD CONSTRAINT interacciones_sociales_pkey PRIMARY KEY (id);

ALTER TABLE ONLY materiales_estudio
    ADD CONSTRAINT materiales_estudio_pkey PRIMARY KEY (id);

ALTER TABLE ONLY materiales_estudio
    ADD CONSTRAINT materiales_estudio_usuario_id_tipo_origen_origen_id_key UNIQUE (usuario_id, tipo_origen, origen_id);

ALTER TABLE ONLY musculos
    ADD CONSTRAINT musculos_nombre_key UNIQUE (nombre);

ALTER TABLE ONLY musculos
    ADD CONSTRAINT musculos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id);

ALTER TABLE ONLY partes_cuerpo
    ADD CONSTRAINT partes_cuerpo_nombre_key UNIQUE (nombre);

ALTER TABLE ONLY partes_cuerpo
    ADD CONSTRAINT partes_cuerpo_pkey PRIMARY KEY (id);

ALTER TABLE ONLY perfil_academico_usuario
    ADD CONSTRAINT perfil_academico_usuario_pkey PRIMARY KEY (id);

ALTER TABLE ONLY perfil_academico_usuario
    ADD CONSTRAINT perfil_academico_usuario_usuario_id_key UNIQUE (usuario_id);

ALTER TABLE ONLY perfil_bienestar_usuario
    ADD CONSTRAINT perfil_bienestar_usuario_pkey PRIMARY KEY (id);

ALTER TABLE ONLY perfil_bienestar_usuario
    ADD CONSTRAINT perfil_bienestar_usuario_usuario_id_key UNIQUE (usuario_id);

ALTER TABLE ONLY plan_entrenamiento_semanal
    ADD CONSTRAINT plan_entrenamiento_semanal_pkey PRIMARY KEY (id);

ALTER TABLE ONLY plan_entrenamiento_semanal
    ADD CONSTRAINT plan_entrenamiento_semanal_usuario_id_semana_inicio_key UNIQUE (usuario_id, semana_inicio);

ALTER TABLE ONLY planes_estudio
    ADD CONSTRAINT planes_estudio_pkey PRIMARY KEY (id);

ALTER TABLE ONLY preferencias_notificacion
    ADD CONSTRAINT preferencias_notificacion_pkey PRIMARY KEY (id);

ALTER TABLE ONLY preferencias_notificacion
    ADD CONSTRAINT preferencias_notificacion_usuario_id_key UNIQUE (usuario_id);

ALTER TABLE ONLY preguntas
    ADD CONSTRAINT preguntas_pkey PRIMARY KEY (id);

ALTER TABLE ONLY prerrequisitos_asignatura
    ADD CONSTRAINT prerrequisitos_asignatura_pkey PRIMARY KEY (id);

ALTER TABLE ONLY profesores_asignatura
    ADD CONSTRAINT profesores_asignatura_asignatura_id_nombre_completo_key UNIQUE (asignatura_id, nombre_completo);

ALTER TABLE ONLY profesores_asignatura
    ADD CONSTRAINT profesores_asignatura_pkey PRIMARY KEY (id);

ALTER TABLE ONLY progreso_de_reto
    ADD CONSTRAINT progreso_de_reto_pkey PRIMARY KEY (id);

ALTER TABLE ONLY recomendaciones_pendientes
    ADD CONSTRAINT recomendaciones_pendientes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY registros_carga_fisica
    ADD CONSTRAINT registros_carga_fisica_pkey PRIMARY KEY (id);

ALTER TABLE ONLY registros_repaso_srs
    ADD CONSTRAINT registros_repaso_srs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY retos
    ADD CONSTRAINT retos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY rutinas
    ADD CONSTRAINT rutinas_pkey PRIMARY KEY (id);

ALTER TABLE ONLY seleccion_de_ejercicios
    ADD CONSTRAINT seleccion_de_ejercicios_pkey PRIMARY KEY (id);

ALTER TABLE ONLY semanas_rutina
    ADD CONSTRAINT semanas_rutina_pkey PRIMARY KEY (id);

ALTER TABLE ONLY semanas_rutina
    ADD CONSTRAINT semanas_rutina_rutina_id_numero_semana_key UNIQUE (rutina_id, numero_semana);

ALTER TABLE ONLY series_sesion
    ADD CONSTRAINT series_sesion_pkey PRIMARY KEY (id);

ALTER TABLE ONLY sesiones_focus
    ADD CONSTRAINT sesiones_focus_pkey PRIMARY KEY (id);

ALTER TABLE ONLY sesiones_registradas
    ADD CONSTRAINT sesiones_registradas_pkey PRIMARY KEY (id);

ALTER TABLE ONLY test_sessions
    ADD CONSTRAINT test_sessions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY universidades
    ADD CONSTRAINT universidades_nombre_key UNIQUE (nombre);

ALTER TABLE ONLY universidades
    ADD CONSTRAINT universidades_pkey PRIMARY KEY (id);

ALTER TABLE ONLY archivos_asignatura
    ADD CONSTRAINT uq_archivos_object_key UNIQUE (cloudflare_object_key);

ALTER TABLE ONLY entregas_examenes
    ADD CONSTRAINT uq_entregas_examenes_usuario_ics_uid UNIQUE (usuario_id, ics_uid);

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT uq_horarios_academicos_usuario_ics_uid UNIQUE (usuario_id, ics_uid);

ALTER TABLE ONLY usuario_carreras
    ADD CONSTRAINT usuario_carreras_pkey PRIMARY KEY (id);

ALTER TABLE ONLY usuario_carreras
    ADD CONSTRAINT usuario_carreras_usuario_id_carrera_id_key UNIQUE (usuario_id, carrera_id);

ALTER TABLE ONLY usuario_insignias
    ADD CONSTRAINT usuario_insignias_pkey PRIMARY KEY (id);

ALTER TABLE ONLY usuario_insignias
    ADD CONSTRAINT usuario_insignias_usuario_id_insignia_id_key UNIQUE (usuario_id, insignia_id);

ALTER TABLE ONLY usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);

ALTER TABLE ONLY usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);

CREATE INDEX idx_actividades_creado_en ON actividades_sociales USING btree (creado_en DESC);

CREATE INDEX idx_actividades_usuario_id ON actividades_sociales USING btree (usuario_id);

CREATE INDEX idx_admin_auditoria_accion ON admin_auditoria USING btree (accion);

CREATE INDEX idx_admin_auditoria_admin ON admin_auditoria USING btree (admin_id, creado_en DESC);

CREATE INDEX idx_amistades_estado ON amistades USING btree (estado);

CREATE INDEX idx_amistades_receptor ON amistades USING btree (receptor_id);

CREATE INDEX idx_amistades_solicitante ON amistades USING btree (solicitante_id);

CREATE INDEX idx_apuntes_asignatura ON apuntes USING btree (asignatura_id);

CREATE INDEX idx_apuntes_usuario ON apuntes USING btree (usuario_id);

CREATE INDEX idx_apuntes_usuario_actualizado ON apuntes USING btree (usuario_id, actualizado_en DESC);

CREATE INDEX idx_archivos_asignatura ON archivos_asignatura USING btree (asignatura_id, creado_en DESC);

CREATE INDEX idx_archivos_usuario ON archivos_asignatura USING btree (usuario_id);

CREATE INDEX idx_asignaturas_archivado ON asignaturas USING btree (archivado);

CREATE INDEX idx_asignaturas_catalogo_carrera ON asignaturas_catalogo USING btree (carrera_id);

CREATE INDEX idx_asignaturas_proxima_evaluacion ON asignaturas USING btree (proxima_evaluacion);

CREATE INDEX idx_asignaturas_usuario_id ON asignaturas USING btree (usuario_id);

CREATE INDEX idx_bancos_material ON bancos_preguntas USING btree (material_id);

CREATE INDEX idx_carga_academica_semana ON carga_academica_semanal USING btree (semana_inicio DESC);

CREATE INDEX idx_carga_academica_usuario_id ON carga_academica_semanal USING btree (usuario_id);

CREATE INDEX idx_carga_fisica_sesion ON registros_carga_fisica USING btree (sesion_id);

CREATE INDEX idx_carga_fisica_usuario_fecha ON registros_carga_fisica USING btree (usuario_id, fecha_registro);

CREATE INDEX idx_carreras_centro ON carreras USING btree (centro_id);

CREATE INDEX idx_centros_universidad ON centros USING btree (universidad_id);

CREATE INDEX idx_comentarios_actividad ON comentarios_feed USING btree (actividad_id, creado_en);

CREATE INDEX idx_comentarios_usuario ON comentarios_feed USING btree (usuario_id);

CREATE INDEX idx_dias_semana ON dias_rutina USING btree (semana_id);

CREATE INDEX idx_documentos_ia_asignatura ON documentos_ia USING btree (usuario_id, asignatura_id);

CREATE INDEX idx_documentos_ia_fuente ON documentos_ia USING btree (usuario_id, fuente_tipo, fuente_id);

CREATE INDEX idx_ee_equip ON ejercicio_equipamiento USING btree (equipamiento_id);

CREATE INDEX idx_ejercicios_dificultad ON ejercicios USING btree (dificultad);

CREATE INDEX idx_ejercicios_fts ON ejercicios USING gin (to_tsvector('spanish'::regconfig, ((COALESCE(nombre, ''::text) || ' '::text) || COALESCE(descripcion, ''::text))));

CREATE INDEX idx_ejercicios_nombre ON ejercicios USING btree (nombre);

CREATE INDEX idx_emo_musculo ON ejercicio_musculo_objetivo USING btree (musculo_id);

CREATE INDEX idx_ems_musculo ON ejercicio_musculo_secundario USING btree (musculo_id);

CREATE INDEX idx_entregas_examenes_fecha ON entregas_examenes USING btree (fecha_limite);

CREATE INDEX idx_entregas_examenes_plan ON entregas_examenes USING btree (plan_estudio_id);

CREATE INDEX idx_entregas_examenes_usuario ON entregas_examenes USING btree (usuario_id);

CREATE INDEX idx_epc_parte ON ejercicio_parte_cuerpo USING btree (parte_cuerpo_id);

CREATE INDEX idx_estado_diario_usuario_fecha ON estado_diario_usuario USING btree (usuario_id, fecha DESC);

CREATE INDEX idx_historial_objetivos_usuario ON historial_objetivos USING btree (usuario_id, fecha_inicio DESC);

CREATE INDEX idx_historial_peso_registrado_en ON historial_peso USING btree (registrado_en DESC);

CREATE INDEX idx_historial_peso_usuario_id ON historial_peso USING btree (usuario_id);

CREATE INDEX idx_hitos_de_reto_apunte ON hitos_de_reto USING btree (apunte_id);

CREATE INDEX idx_hitos_de_reto_archivo ON hitos_de_reto USING btree (archivo_id);

CREATE INDEX idx_hitos_entidad_vinculada ON hitos_de_reto USING btree (entidad_vinculada_id) WHERE (entidad_vinculada_id IS NOT NULL);

CREATE INDEX idx_hitos_reto_id ON hitos_de_reto USING btree (reto_id);

CREATE INDEX idx_horarios_academicos_plan ON horarios_academicos USING btree (plan_estudio_id);

CREATE INDEX idx_horarios_academicos_tipo ON horarios_academicos USING btree (tipo_actividad);

CREATE INDEX idx_horarios_completado_xp ON horarios_academicos USING btree (usuario_id, completado, xp_bloque_otorgado);

CREATE INDEX idx_horarios_dia_rutina ON horarios_academicos USING btree (dia_rutina_id) WHERE (dia_rutina_id IS NOT NULL);

CREATE INDEX idx_horarios_dia_semana ON horarios_academicos USING btree (dia_semana);

CREATE INDEX idx_horarios_entrega_examen ON horarios_academicos USING btree (entrega_examen_id) WHERE (entrega_examen_id IS NOT NULL);

CREATE INDEX idx_horarios_es_fijo ON horarios_academicos USING btree (es_fijo);

CREATE INDEX idx_horarios_fecha_inicio ON horarios_academicos USING btree (usuario_id, hora_inicio);

CREATE INDEX idx_horarios_hito_id ON horarios_academicos USING btree (hito_id) WHERE (hito_id IS NOT NULL);

CREATE INDEX idx_horarios_hora_inicio ON horarios_academicos USING btree (hora_inicio);

CREATE INDEX idx_horarios_reto_id ON horarios_academicos USING btree (reto_id) WHERE (reto_id IS NOT NULL);

CREATE INDEX idx_horarios_semana_rutina ON horarios_academicos USING btree (semana_rutina_id) WHERE (semana_rutina_id IS NOT NULL);

CREATE INDEX idx_horarios_usuario_id ON horarios_academicos USING btree (usuario_id);

CREATE INDEX idx_insignias_categoria ON insignias USING btree (categoria);

CREATE INDEX idx_intentos_usuario_pregunta ON intentos_pregunta USING btree (usuario_id, pregunta_id);

CREATE INDEX idx_interacciones_actividad_id ON interacciones_sociales USING btree (actividad_id);

CREATE INDEX idx_interacciones_usuario_id ON interacciones_sociales USING btree (usuario_id);

CREATE INDEX idx_materiales_siguiente_repaso ON materiales_estudio USING btree (usuario_id, siguiente_repaso_en) WHERE (siguiente_repaso_en IS NOT NULL);

CREATE INDEX idx_materiales_usuario_asignatura ON materiales_estudio USING btree (usuario_id, asignatura_id);

CREATE INDEX idx_notif_creado_en ON notificaciones USING btree (creado_en DESC);

CREATE INDEX idx_notif_esta_leida ON notificaciones USING btree (esta_leida);

CREATE INDEX idx_notif_usuario_id ON notificaciones USING btree (usuario_id);

CREATE INDEX idx_plan_entrenamiento_semana ON plan_entrenamiento_semanal USING btree (semana_inicio DESC);

CREATE INDEX idx_plan_entrenamiento_usuario_id ON plan_entrenamiento_semanal USING btree (usuario_id);

CREATE INDEX idx_planes_estudio_semana ON planes_estudio USING btree (semana_inicio, semana_fin);

CREATE INDEX idx_planes_estudio_usuario ON planes_estudio USING btree (usuario_id);

CREATE INDEX idx_preguntas_banco ON preguntas USING btree (banco_id);

CREATE INDEX idx_progreso_hito_id ON progreso_de_reto USING btree (hito_id);

CREATE INDEX idx_progreso_registrado_en ON progreso_de_reto USING btree (registrado_en DESC);

CREATE INDEX idx_progreso_reto_id ON progreso_de_reto USING btree (reto_id);

CREATE INDEX idx_progreso_usuario_id ON progreso_de_reto USING btree (usuario_id);

CREATE INDEX idx_recom_pend_usuario ON recomendaciones_pendientes USING btree (usuario_id, creado_en DESC);

CREATE INDEX idx_repaso_srs_material ON registros_repaso_srs USING btree (material_estudio_id, fecha_repaso);

CREATE INDEX idx_retos_completado ON retos USING btree (esta_completado);

CREATE INDEX idx_retos_creado_en ON retos USING btree (creado_en DESC);

CREATE INDEX idx_retos_entidad_vinculada ON retos USING btree (entidad_vinculada_id) WHERE (entidad_vinculada_id IS NOT NULL);

CREATE INDEX idx_retos_usuario_id ON retos USING btree (usuario_id);

CREATE INDEX idx_rutinas_creado_en ON rutinas USING btree (creado_en DESC);

CREATE INDEX idx_rutinas_fecha_inicio ON rutinas USING btree (usuario_id, fecha_inicio);

CREATE INDEX idx_rutinas_usuario_estado ON rutinas USING btree (usuario_id, estado);

CREATE INDEX idx_rutinas_usuario_id ON rutinas USING btree (usuario_id);

CREATE INDEX idx_rutinas_visibilidad ON rutinas USING btree (visibilidad);

CREATE INDEX idx_sel_ejercicio_id ON seleccion_de_ejercicios USING btree (ejercicio_id);

CREATE INDEX idx_sel_rutina_id ON seleccion_de_ejercicios USING btree (rutina_id);

CREATE INDEX idx_seleccion_dia ON seleccion_de_ejercicios USING btree (dia_id);

CREATE UNIQUE INDEX idx_seleccion_dia_ej_orden ON seleccion_de_ejercicios USING btree (rutina_id, COALESCE(dia_id, id), ejercicio_id, indice_orden);

CREATE INDEX idx_semanas_rutina ON semanas_rutina USING btree (rutina_id);

CREATE INDEX idx_semanas_rutina_tipo ON semanas_rutina USING btree (rutina_id, numero_semana, tipo_semana);

CREATE INDEX idx_series_sesion ON series_sesion USING btree (sesion_id);

CREATE INDEX idx_sesiones_completada_en ON sesiones_registradas USING btree (completada_en DESC);

CREATE INDEX idx_sesiones_dia ON sesiones_registradas USING btree (dia_id);

CREATE INDEX idx_sesiones_focus_usuario_fecha ON sesiones_focus USING btree (usuario_id, fecha DESC);

CREATE INDEX idx_sesiones_rutina_id ON sesiones_registradas USING btree (rutina_id);

CREATE INDEX idx_sesiones_usuario_completada ON sesiones_registradas USING btree (usuario_id, completada_en DESC);

CREATE INDEX idx_sesiones_usuario_id ON sesiones_registradas USING btree (usuario_id);

CREATE INDEX idx_test_sessions_usuario ON test_sessions USING btree (usuario_id, material_id, status);

CREATE INDEX idx_usuario_carreras_usuario ON usuario_carreras USING btree (usuario_id);

CREATE INDEX idx_usuario_insignias_usuario ON usuario_insignias USING btree (usuario_id);

CREATE INDEX idx_usuarios_creado_en ON usuarios USING btree (creado_en DESC);

CREATE INDEX idx_usuarios_privacidad ON usuarios USING btree (nivel_privacidad);

CREATE INDEX idx_usuarios_shadowbanned ON usuarios USING btree (is_shadowbanned) WHERE (is_shadowbanned = true);

ALTER TABLE ONLY actividades_sociales
    ADD CONSTRAINT actividades_sociales_reportado_por_fkey FOREIGN KEY (reportado_por) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY actividades_sociales
    ADD CONSTRAINT actividades_sociales_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY admin_auditoria
    ADD CONSTRAINT admin_auditoria_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY amistades
    ADD CONSTRAINT amistades_receptor_id_fkey FOREIGN KEY (receptor_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY amistades
    ADD CONSTRAINT amistades_solicitante_id_fkey FOREIGN KEY (solicitante_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY apuntes
    ADD CONSTRAINT apuntes_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE SET NULL;

ALTER TABLE ONLY apuntes
    ADD CONSTRAINT apuntes_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY archivos_asignatura
    ADD CONSTRAINT archivos_asignatura_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE CASCADE;

ALTER TABLE ONLY asignaturas
    ADD CONSTRAINT asignaturas_catalogo_asignatura_id_fkey FOREIGN KEY (catalogo_asignatura_id) REFERENCES asignaturas_catalogo(id) ON DELETE SET NULL;

ALTER TABLE ONLY asignaturas_catalogo
    ADD CONSTRAINT asignaturas_catalogo_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES carreras(id) ON DELETE CASCADE;

ALTER TABLE ONLY asignaturas
    ADD CONSTRAINT asignaturas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY bancos_preguntas
    ADD CONSTRAINT bancos_preguntas_material_id_fkey FOREIGN KEY (material_id) REFERENCES materiales_estudio(id) ON DELETE CASCADE;

ALTER TABLE ONLY bancos_preguntas
    ADD CONSTRAINT bancos_preguntas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY bibliografia_asignatura
    ADD CONSTRAINT bibliografia_asignatura_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas_catalogo(id) ON DELETE CASCADE;

ALTER TABLE ONLY carga_academica_semanal
    ADD CONSTRAINT carga_academica_semanal_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY carreras
    ADD CONSTRAINT carreras_centro_id_fkey FOREIGN KEY (centro_id) REFERENCES centros(id) ON DELETE CASCADE;

ALTER TABLE ONLY centros
    ADD CONSTRAINT centros_universidad_id_fkey FOREIGN KEY (universidad_id) REFERENCES universidades(id) ON DELETE CASCADE;

ALTER TABLE ONLY comentarios_feed
    ADD CONSTRAINT comentarios_feed_actividad_id_fkey FOREIGN KEY (actividad_id) REFERENCES actividades_sociales(id) ON DELETE CASCADE;

ALTER TABLE ONLY comentarios_feed
    ADD CONSTRAINT comentarios_feed_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY configuracion_global
    ADD CONSTRAINT configuracion_global_lockdown_iniciado_por_fkey FOREIGN KEY (lockdown_iniciado_por) REFERENCES usuarios(id) ON DELETE SET NULL;

ALTER TABLE ONLY criterios_evaluacion
    ADD CONSTRAINT criterios_evaluacion_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas_catalogo(id) ON DELETE CASCADE;

ALTER TABLE ONLY dias_rutina
    ADD CONSTRAINT dias_rutina_semana_id_fkey FOREIGN KEY (semana_id) REFERENCES semanas_rutina(id) ON DELETE CASCADE;

ALTER TABLE ONLY documentos_ia
    ADD CONSTRAINT documentos_ia_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_equipamiento
    ADD CONSTRAINT ejercicio_equipamiento_ejercicio_id_fkey FOREIGN KEY (ejercicio_id) REFERENCES ejercicios(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_equipamiento
    ADD CONSTRAINT ejercicio_equipamiento_equipamiento_id_fkey FOREIGN KEY (equipamiento_id) REFERENCES equipamientos(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_musculo_objetivo
    ADD CONSTRAINT ejercicio_musculo_objetivo_ejercicio_id_fkey FOREIGN KEY (ejercicio_id) REFERENCES ejercicios(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_musculo_objetivo
    ADD CONSTRAINT ejercicio_musculo_objetivo_musculo_id_fkey FOREIGN KEY (musculo_id) REFERENCES musculos(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_musculo_secundario
    ADD CONSTRAINT ejercicio_musculo_secundario_ejercicio_id_fkey FOREIGN KEY (ejercicio_id) REFERENCES ejercicios(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_musculo_secundario
    ADD CONSTRAINT ejercicio_musculo_secundario_musculo_id_fkey FOREIGN KEY (musculo_id) REFERENCES musculos(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_parte_cuerpo
    ADD CONSTRAINT ejercicio_parte_cuerpo_ejercicio_id_fkey FOREIGN KEY (ejercicio_id) REFERENCES ejercicios(id) ON DELETE CASCADE;

ALTER TABLE ONLY ejercicio_parte_cuerpo
    ADD CONSTRAINT ejercicio_parte_cuerpo_parte_cuerpo_id_fkey FOREIGN KEY (parte_cuerpo_id) REFERENCES partes_cuerpo(id) ON DELETE CASCADE;

ALTER TABLE ONLY entregas_examenes
    ADD CONSTRAINT entregas_examenes_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE SET NULL;

ALTER TABLE ONLY entregas_examenes
    ADD CONSTRAINT entregas_examenes_plan_estudio_id_fkey FOREIGN KEY (plan_estudio_id) REFERENCES planes_estudio(id) ON DELETE SET NULL;

ALTER TABLE ONLY entregas_examenes
    ADD CONSTRAINT entregas_examenes_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY estado_cognitivo_usuario
    ADD CONSTRAINT estado_cognitivo_usuario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY estado_diario_usuario
    ADD CONSTRAINT estado_diario_usuario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY estado_regulacion_cruzada
    ADD CONSTRAINT estado_regulacion_cruzada_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT fk_horarios_rutina FOREIGN KEY (rutina_id) REFERENCES rutinas(id) ON DELETE SET NULL;

ALTER TABLE ONLY historial_objetivos
    ADD CONSTRAINT historial_objetivos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY historial_peso
    ADD CONSTRAINT historial_peso_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY hitos_de_reto
    ADD CONSTRAINT hitos_de_reto_apunte_id_fkey FOREIGN KEY (apunte_id) REFERENCES apuntes(id) ON DELETE SET NULL;

ALTER TABLE ONLY hitos_de_reto
    ADD CONSTRAINT hitos_de_reto_archivo_id_fkey FOREIGN KEY (archivo_id) REFERENCES archivos_asignatura(id) ON DELETE SET NULL;

ALTER TABLE ONLY hitos_de_reto
    ADD CONSTRAINT hitos_de_reto_reto_id_fkey FOREIGN KEY (reto_id) REFERENCES retos(id) ON DELETE CASCADE;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE CASCADE;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_dia_rutina_id_fkey FOREIGN KEY (dia_rutina_id) REFERENCES dias_rutina(id) ON DELETE SET NULL;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_entrega_examen_id_fkey FOREIGN KEY (entrega_examen_id) REFERENCES entregas_examenes(id) ON DELETE SET NULL;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_hito_id_fkey FOREIGN KEY (hito_id) REFERENCES hitos_de_reto(id) ON DELETE SET NULL;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_plan_estudio_id_fkey FOREIGN KEY (plan_estudio_id) REFERENCES planes_estudio(id) ON DELETE SET NULL;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_reto_id_fkey FOREIGN KEY (reto_id) REFERENCES retos(id) ON DELETE SET NULL;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_semana_rutina_id_fkey FOREIGN KEY (semana_rutina_id) REFERENCES semanas_rutina(id) ON DELETE SET NULL;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY intentos_pregunta
    ADD CONSTRAINT intentos_pregunta_pregunta_id_fkey FOREIGN KEY (pregunta_id) REFERENCES preguntas(id) ON DELETE CASCADE;

ALTER TABLE ONLY intentos_pregunta
    ADD CONSTRAINT intentos_pregunta_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY interacciones_sociales
    ADD CONSTRAINT interacciones_sociales_actividad_id_fkey FOREIGN KEY (actividad_id) REFERENCES actividades_sociales(id) ON DELETE CASCADE;

ALTER TABLE ONLY interacciones_sociales
    ADD CONSTRAINT interacciones_sociales_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY materiales_estudio
    ADD CONSTRAINT materiales_estudio_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE CASCADE;

ALTER TABLE ONLY materiales_estudio
    ADD CONSTRAINT materiales_estudio_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY notificaciones
    ADD CONSTRAINT notificaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY perfil_academico_usuario
    ADD CONSTRAINT perfil_academico_usuario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY perfil_bienestar_usuario
    ADD CONSTRAINT perfil_bienestar_usuario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY plan_entrenamiento_semanal
    ADD CONSTRAINT plan_entrenamiento_semanal_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY planes_estudio
    ADD CONSTRAINT planes_estudio_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY preferencias_notificacion
    ADD CONSTRAINT preferencias_notificacion_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY preguntas
    ADD CONSTRAINT preguntas_banco_id_fkey FOREIGN KEY (banco_id) REFERENCES bancos_preguntas(id) ON DELETE CASCADE;

ALTER TABLE ONLY prerrequisitos_asignatura
    ADD CONSTRAINT prerrequisitos_asignatura_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas_catalogo(id) ON DELETE CASCADE;

ALTER TABLE ONLY profesores_asignatura
    ADD CONSTRAINT profesores_asignatura_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas_catalogo(id) ON DELETE CASCADE;

ALTER TABLE ONLY progreso_de_reto
    ADD CONSTRAINT progreso_de_reto_hito_id_fkey FOREIGN KEY (hito_id) REFERENCES hitos_de_reto(id) ON DELETE CASCADE;

ALTER TABLE ONLY progreso_de_reto
    ADD CONSTRAINT progreso_de_reto_reto_id_fkey FOREIGN KEY (reto_id) REFERENCES retos(id) ON DELETE CASCADE;

ALTER TABLE ONLY progreso_de_reto
    ADD CONSTRAINT progreso_de_reto_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY recomendaciones_pendientes
    ADD CONSTRAINT recomendaciones_pendientes_ejercicio_id_fkey FOREIGN KEY (ejercicio_id) REFERENCES ejercicios(id) ON DELETE SET NULL;

ALTER TABLE ONLY recomendaciones_pendientes
    ADD CONSTRAINT recomendaciones_pendientes_rutina_id_fkey FOREIGN KEY (rutina_id) REFERENCES rutinas(id) ON DELETE SET NULL;

ALTER TABLE ONLY recomendaciones_pendientes
    ADD CONSTRAINT recomendaciones_pendientes_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY registros_carga_fisica
    ADD CONSTRAINT registros_carga_fisica_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesiones_registradas(id) ON DELETE CASCADE;

ALTER TABLE ONLY registros_carga_fisica
    ADD CONSTRAINT registros_carga_fisica_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY registros_repaso_srs
    ADD CONSTRAINT registros_repaso_srs_material_estudio_id_fkey FOREIGN KEY (material_estudio_id) REFERENCES materiales_estudio(id) ON DELETE CASCADE;

ALTER TABLE ONLY retos
    ADD CONSTRAINT retos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY rutinas
    ADD CONSTRAINT rutinas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY seleccion_de_ejercicios
    ADD CONSTRAINT seleccion_de_ejercicios_dia_id_fkey FOREIGN KEY (dia_id) REFERENCES dias_rutina(id) ON DELETE CASCADE;

ALTER TABLE ONLY seleccion_de_ejercicios
    ADD CONSTRAINT seleccion_de_ejercicios_ejercicio_id_fkey FOREIGN KEY (ejercicio_id) REFERENCES ejercicios(id) ON DELETE RESTRICT;

ALTER TABLE ONLY seleccion_de_ejercicios
    ADD CONSTRAINT seleccion_de_ejercicios_rutina_id_fkey FOREIGN KEY (rutina_id) REFERENCES rutinas(id) ON DELETE CASCADE;

ALTER TABLE ONLY semanas_rutina
    ADD CONSTRAINT semanas_rutina_rutina_id_fkey FOREIGN KEY (rutina_id) REFERENCES rutinas(id) ON DELETE CASCADE;

ALTER TABLE ONLY series_sesion
    ADD CONSTRAINT series_sesion_seleccion_id_fkey FOREIGN KEY (seleccion_id) REFERENCES seleccion_de_ejercicios(id) ON DELETE SET NULL;

ALTER TABLE ONLY series_sesion
    ADD CONSTRAINT series_sesion_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES sesiones_registradas(id) ON DELETE CASCADE;

ALTER TABLE ONLY sesiones_focus
    ADD CONSTRAINT sesiones_focus_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY sesiones_registradas
    ADD CONSTRAINT sesiones_registradas_dia_id_fkey FOREIGN KEY (dia_id) REFERENCES dias_rutina(id) ON DELETE SET NULL;

ALTER TABLE ONLY sesiones_registradas
    ADD CONSTRAINT sesiones_registradas_rutina_id_fkey FOREIGN KEY (rutina_id) REFERENCES rutinas(id) ON DELETE SET NULL;

ALTER TABLE ONLY sesiones_registradas
    ADD CONSTRAINT sesiones_registradas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY test_sessions
    ADD CONSTRAINT test_sessions_material_id_fkey FOREIGN KEY (material_id) REFERENCES materiales_estudio(id) ON DELETE CASCADE;

ALTER TABLE ONLY test_sessions
    ADD CONSTRAINT test_sessions_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY usuario_carreras
    ADD CONSTRAINT usuario_carreras_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES carreras(id) ON DELETE CASCADE;

ALTER TABLE ONLY usuario_carreras
    ADD CONSTRAINT usuario_carreras_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY usuario_insignias
    ADD CONSTRAINT usuario_insignias_insignia_id_fkey FOREIGN KEY (insignia_id) REFERENCES insignias(id) ON DELETE CASCADE;

ALTER TABLE ONLY usuario_insignias
    ADD CONSTRAINT usuario_insignias_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;


-- Foreign keys que faltaban en el esquema heredado.
ALTER TABLE ONLY retos
    ADD CONSTRAINT retos_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE SET NULL;

ALTER TABLE ONLY hitos_de_reto
    ADD CONSTRAINT hitos_de_reto_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE SET NULL;

ALTER TABLE ONLY documentos_ia
    ADD CONSTRAINT documentos_ia_asignatura_id_fkey FOREIGN KEY (asignatura_id) REFERENCES asignaturas(id) ON DELETE SET NULL;

ALTER TABLE ONLY archivos_asignatura
    ADD CONSTRAINT archivos_asignatura_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

-- Autenticación propia (sustituye a auth.users de Supabase).
CREATE UNIQUE INDEX ux_usuarios_google_sub ON usuarios USING btree (google_sub) WHERE (google_sub IS NOT NULL);

CREATE TABLE refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    token_hash text NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    revocado_en timestamp with time zone,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id),
    CONSTRAINT refresh_tokens_token_hash_key UNIQUE (token_hash),
    CONSTRAINT refresh_tokens_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_refresh_tokens_usuario ON refresh_tokens USING btree (usuario_id);

-- Configuración global: fila única.
INSERT INTO configuracion_global (id) VALUES (true);
