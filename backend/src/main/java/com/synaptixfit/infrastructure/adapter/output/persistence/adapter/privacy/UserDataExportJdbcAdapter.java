package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.privacy;

import com.synaptixfit.domain.port.output.privacy.UserDataExportPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin.JdbcValues;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link UserDataExportPort}: PostgreSQL compone el documento JSON con todas las
 * tablas del usuario en una sola consulta de lectura (sustituye a {@code exportar_datos_usuario}).
 *
 * <p>Las secciones usan nombres en camelCase; cada fila conserva los nombres de columna de la base
 * de datos. Nunca se exportan credenciales (hash de contraseña, identificador de Google, tokens) ni
 * claves internas del almacenamiento de archivos.
 */
@Repository
public class UserDataExportJdbcAdapter implements UserDataExportPort {

    /** jsonb_build_object admite como mucho 100 argumentos: se agrupan las secciones de 20 en 20. */
    private static final int SECTIONS_PER_OBJECT = 20;

    private static final String ROUTINE_IDS = "(SELECT id FROM rutinas WHERE usuario_id = :id)";

    private static final String OWNER_SQL = buildSql(true);
    private static final String ADMINISTRATOR_SQL = buildSql(false);

    private final JdbcClient jdbc;

    public UserDataExportJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public String exportAsJson(UUID userId, Instant exportedAt, Requester requester) {
        return jdbc.sql(requester.includesHealthData() ? OWNER_SQL : ADMINISTRATOR_SQL)
                .param("id", userId)
                .param("exportedAt", JdbcValues.param(exportedAt))
                .query(String.class)
                .single();
    }

    private static String buildSql(boolean includeHealthData) {
        Map<String, String> sections = new LinkedHashMap<>();
        sections.put("formatVersion", "1");
        sections.put("exportedAt", "CAST(:exportedAt AS timestamptz)");
        sections.put("userId", "CAST(:id AS uuid)");
        sections.put("account", """
                (SELECT jsonb_build_object(
                    'id', u.id, 'email', u.email, 'nombre_completo', u.nombre_completo, 'url_avatar', u.url_avatar,
                    'nivel', u.nivel, 'xp_nivel_actual', u.xp_nivel_actual, 'racha_actual', u.racha_actual,
                    'nivel_privacidad', u.nivel_privacidad, 'rol', u.rol, 'is_shadowbanned', u.is_shadowbanned,
                    'tiene_contrasena', u.password_hash IS NOT NULL, 'google_vinculado', u.google_sub IS NOT NULL,
                    'creado_en', u.creado_en, 'actualizado_en', u.actualizado_en, 'eliminado_en', u.eliminado_en)
                   FROM usuarios u WHERE u.id = :id)""");
        // Perfil
        sections.put("wellbeingProfile", single("perfil_bienestar_usuario"));
        sections.put("academicProfile", single("perfil_academico_usuario"));
        sections.put("weightHistory", rows("historial_peso t", "t.usuario_id = :id", "t.registrado_en"));
        sections.put("goalHistory", rows("historial_objetivos t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("degrees", rows("to_jsonb(t) || jsonb_build_object('carrera_nombre', c.nombre)",
                "usuario_carreras t LEFT JOIN carreras c ON c.id = t.carrera_id", "t.usuario_id = :id", "t.creado_en"));
        // Académico
        sections.put("subjects", rows("asignaturas t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("subjectSemesters", rows("asignaturas_usuario_semestre t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("notes", rows("apuntes t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("files", rows("to_jsonb(t) - 'cloudflare_object_key' - 'url_publica_o_firmada'",
                "archivos_asignatura t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("aiDocuments", rows("documentos_ia t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("teachingGuideImports", rows("to_jsonb(t) - 'clave_objeto'", "importaciones_plan_docente t",
                "t.usuario_id = :id", "t.creado_en"));
        sections.put("studyMaterials", rows("materiales_estudio t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("srsReviews", rows("registros_repaso_srs t",
                "t.material_estudio_id IN (SELECT id FROM materiales_estudio WHERE usuario_id = :id)", "t.fecha_repaso"));
        sections.put("questionBanks", rows("bancos_preguntas t", "t.usuario_id = :id", "t.generado_en"));
        sections.put("questions", rows("preguntas t",
                "t.banco_id IN (SELECT id FROM bancos_preguntas WHERE usuario_id = :id)", "t.banco_id, t.orden"));
        sections.put("questionAttempts", rows("intentos_pregunta t", "t.usuario_id = :id", "t.respondido_en"));
        sections.put("testSessions", rows("test_sessions t", "t.usuario_id = :id", "t.iniciado_en"));
        // Planificador
        sections.put("studyBlocks", rows("horarios_academicos t", "t.usuario_id = :id", "t.hora_inicio"));
        sections.put("studyPlans", rows("planes_estudio t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("deadlines", rows("entregas_examenes t", "t.usuario_id = :id", "t.fecha_limite"));
        sections.put("weeklyAcademicLoad", rows("carga_academica_semanal t", "t.usuario_id = :id", "t.semana_inicio"));
        sections.put("focusSessions", rows("sesiones_focus t", "t.usuario_id = :id", "t.creado_en"));
        // Entrenamiento
        sections.put("routines", rows("rutinas t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("routineWeeks", rows("semanas_rutina t", "t.rutina_id IN " + ROUTINE_IDS,
                "t.rutina_id, t.numero_semana"));
        sections.put("routineDays", rows("dias_rutina t",
                "t.semana_id IN (SELECT id FROM semanas_rutina WHERE rutina_id IN " + ROUTINE_IDS + ")",
                "t.semana_id, t.numero_dia"));
        sections.put("routineExercises", rows("to_jsonb(t) || jsonb_build_object('ejercicio_nombre', e.nombre)",
                "seleccion_de_ejercicios t LEFT JOIN ejercicios e ON e.id = t.ejercicio_id",
                "t.rutina_id IN " + ROUTINE_IDS, "t.rutina_id, t.indice_orden"));
        sections.put("trainingSessions", rows("sesiones_registradas t", "t.usuario_id = :id", "t.completada_en"));
        sections.put("sessionSets", rows("series_sesion t",
                "t.sesion_id IN (SELECT id FROM sesiones_registradas WHERE usuario_id = :id)",
                "t.sesion_id, t.numero_serie"));
        sections.put("weeklyTrainingPlans", rows("plan_entrenamiento_semanal t", "t.usuario_id = :id",
                "t.semana_inicio"));
        sections.put("exerciseNotes", rows("notas_ejercicio t", "t.usuario_id = :id", "t.actualizado_en"));
        sections.put("healthConsent", single("consentimientos_salud"));
        if (includeHealthData) {
            // Datos de salud (ADR 0033 y 0034): el registro diario y el ciclo, solo en la copia de su dueño.
            sections.put("dailyCheckIns", rows("estado_diario_usuario t", "t.usuario_id = :id", "t.fecha"));
            sections.put("cycleTracking", single("seguimiento_ciclo"));
            sections.put("cycleDays", rows("dias_ciclo t", "t.usuario_id = :id", "t.fecha"));
            // Rutas GPS (ADR 0037): ubicación exacta, solo en la copia de su dueño.
            sections.put("gpsRuns", rows("carreras_gps t", "t.usuario_id = :id", "t.iniciada_en"));
        }
        sections.put("runWorkouts", rows("entrenos_carrera t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("loggedActivities", rows("actividades_apuntadas t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("reminderOptions", single("opciones_avisos"));
        sections.put("legalAcceptances", rows("aceptaciones_legales t", "t.usuario_id = :id", "t.aceptada_en"));
        sections.put("recommendations", rows("recomendaciones_pendientes t", "t.usuario_id = :id", "t.creado_en"));
        // Gamificación
        sections.put("challenges", rows("retos t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("challengeTasks", rows("hitos_de_reto t",
                "t.reto_id IN (SELECT id FROM retos WHERE usuario_id = :id)", "t.reto_id, t.indice_orden"));
        sections.put("challengeProgress", rows("progreso_de_reto t", "t.usuario_id = :id", "t.registrado_en"));
        sections.put("badges", rows(
                "to_jsonb(t) || jsonb_build_object('insignia_nombre', i.nombre, 'insignia_descripcion', i.descripcion)",
                "usuario_insignias t JOIN insignias i ON i.id = t.insignia_id", "t.usuario_id = :id", "t.obtenida_en"));
        // Social
        sections.put("posts", rows("actividades_sociales t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("comments", rows("comentarios_feed t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("likes", rows("interacciones_sociales t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("friendships", rows("amistades t", "t.solicitante_id = :id OR t.receptor_id = :id",
                "t.creado_en"));
        sections.put("notifications", rows("notificaciones t", "t.usuario_id = :id", "t.creado_en"));
        sections.put("notificationPreferences", single("preferencias_notificacion"));
        // Indicadores
        sections.put("cognitiveState", single("estado_cognitivo_usuario"));
        sections.put("crossRegulationState", single("estado_regulacion_cruzada"));
        sections.put("physicalLoad", rows("registros_carga_fisica t", "t.usuario_id = :id", "t.fecha_registro"));

        List<String> objects = new ArrayList<>();
        List<String> pairs = new ArrayList<>();
        for (Map.Entry<String, String> section : sections.entrySet()) {
            pairs.add("'" + section.getKey() + "', " + section.getValue());
            if (pairs.size() == SECTIONS_PER_OBJECT) {
                objects.add("jsonb_build_object(" + String.join(",\n", pairs) + ")");
                pairs.clear();
            }
        }
        if (!pairs.isEmpty()) {
            objects.add("jsonb_build_object(" + String.join(",\n", pairs) + ")");
        }
        return "SELECT (" + String.join("\n || ", objects) + ")::text";
    }

    /** Fila única de una tabla por {@code usuario_id}, o JSON null. */
    private static String single(String table) {
        return "(SELECT to_jsonb(t) FROM " + table + " t WHERE t.usuario_id = :id LIMIT 1)";
    }

    /** Todas las filas de una tabla (alias {@code t}) como array, vacío si no hay. */
    private static String rows(String fromWithAlias, String where, String orderBy) {
        return rows("to_jsonb(t)", fromWithAlias, where, orderBy);
    }

    private static String rows(String element, String from, String where, String orderBy) {
        return "COALESCE((SELECT jsonb_agg(" + element + " ORDER BY " + orderBy + ") FROM " + from
                + " WHERE " + where + "), '[]'::jsonb)";
    }
}
