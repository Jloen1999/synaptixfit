package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.privacy;

import com.synaptixfit.domain.port.output.privacy.UserDataErasurePort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin.JdbcValues;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link UserDataErasurePort} con sentencias directas sobre las tablas de todos los
 * módulos. Excepción justificada a la propiedad de tablas: el derecho de supresión (RGPD) es
 * transversal y debe ejecutarse de forma atómica en la misma transacción. Las tablas hijas sin
 * {@code usuario_id} (semanas y días de rutina, ejercicios seleccionados, series, hitos,
 * preguntas, repasos SRS…) se borran en cascada desde sus padres.
 */
@Repository
public class UserDataErasureJdbcAdapter implements UserDataErasurePort {

    /** Contenido que se conserva solo como estadística anónima al anonimizar. */
    private static final List<String> STATISTICAL_CONTENT = List.of(
            "DELETE FROM horarios_academicos WHERE usuario_id = :id",
            "DELETE FROM carga_academica_semanal WHERE usuario_id = :id",
            "DELETE FROM registros_carga_fisica WHERE usuario_id = :id",
            "DELETE FROM sesiones_registradas WHERE usuario_id = :id",
            "DELETE FROM estado_diario_usuario WHERE usuario_id = :id",
            "DELETE FROM estado_regulacion_cruzada WHERE usuario_id = :id");

    /**
     * Contenido personal: se borra al vaciar y al anonimizar. Los datos del ciclo son de salud (categoría
     * especial del RGPD, ADR 0033): nunca se conservan vinculados a un id anonimizado.
     */
    private static final List<String> PERSONAL_CONTENT = List.of(
            "DELETE FROM dias_ciclo WHERE usuario_id = :id",
            "DELETE FROM seguimiento_ciclo WHERE usuario_id = :id",
            "DELETE FROM notas_ejercicio WHERE usuario_id = :id",
            "DELETE FROM sesiones_focus WHERE usuario_id = :id",
            "DELETE FROM entregas_examenes WHERE usuario_id = :id",
            "DELETE FROM planes_estudio WHERE usuario_id = :id",
            "DELETE FROM progreso_de_reto WHERE usuario_id = :id",
            "DELETE FROM retos WHERE usuario_id = :id",
            "DELETE FROM usuario_insignias WHERE usuario_id = :id",
            "DELETE FROM plan_entrenamiento_semanal WHERE usuario_id = :id",
            "DELETE FROM recomendaciones_pendientes WHERE usuario_id = :id",
            "DELETE FROM rutinas WHERE usuario_id = :id",
            "DELETE FROM intentos_pregunta WHERE usuario_id = :id",
            "DELETE FROM test_sessions WHERE usuario_id = :id",
            "DELETE FROM bancos_preguntas WHERE usuario_id = :id",
            "DELETE FROM materiales_estudio WHERE usuario_id = :id",
            "DELETE FROM documentos_ia WHERE usuario_id = :id",
            "DELETE FROM importaciones_plan_docente WHERE usuario_id = :id",
            "DELETE FROM apuntes WHERE usuario_id = :id",
            "DELETE FROM archivos_asignatura WHERE usuario_id = :id",
            "DELETE FROM asignaturas_usuario_semestre WHERE usuario_id = :id",
            "DELETE FROM asignaturas WHERE usuario_id = :id",
            "DELETE FROM interacciones_sociales WHERE usuario_id = :id",
            "DELETE FROM comentarios_feed WHERE usuario_id = :id",
            "DELETE FROM actividades_sociales WHERE usuario_id = :id",
            "DELETE FROM amistades WHERE solicitante_id = :id OR receptor_id = :id",
            "DELETE FROM notificaciones WHERE usuario_id = :id",
            "DELETE FROM historial_peso WHERE usuario_id = :id",
            "DELETE FROM historial_objetivos WHERE usuario_id = :id");

    /**
     * Perfil y configuración: se conservan al vaciar y se borran al anonimizar. Al vaciar la cuenta sigue en uso,
     * así que la constancia de la política aceptada (ADR 0034) se conserva; al anonimizar ya no hay a quién tratar.
     */
    private static final List<String> PROFILE = List.of(
            "DELETE FROM perfil_bienestar_usuario WHERE usuario_id = :id",
            "DELETE FROM perfil_academico_usuario WHERE usuario_id = :id",
            "DELETE FROM usuario_carreras WHERE usuario_id = :id",
            "DELETE FROM preferencias_notificacion WHERE usuario_id = :id",
            "DELETE FROM opciones_avisos WHERE usuario_id = :id",
            "DELETE FROM aceptaciones_legales WHERE usuario_id = :id",
            "DELETE FROM consentimientos_salud WHERE usuario_id = :id");

    /** Texto libre de los registros estadísticos que se conservan al anonimizar. */
    private static final List<String> SCRUB_STATISTICS = List.of(
            "UPDATE horarios_academicos SET temas = NULL, ubicacion = NULL, ics_uid = NULL WHERE usuario_id = :id",
            "UPDATE carga_academica_semanal SET notas = NULL WHERE usuario_id = :id",
            "UPDATE estado_diario_usuario SET notas = NULL WHERE usuario_id = :id",
            "UPDATE estado_cognitivo_usuario SET rmr_base = NULL WHERE usuario_id = :id");

    private static final String RESET_COGNITIVE_STATE = """
            UPDATE estado_cognitivo_usuario
               SET carga_cognitiva_actual = 0, capacidad_atencion_actual = 1, duracion_ultimo_bloque_min = 0,
                   fecha_ultimo_descanso = NULL, actualizado_en = :at
             WHERE usuario_id = :id
            """;

    private final JdbcClient jdbc;

    public UserDataErasureJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<String> storedObjectKeys(UUID userId) {
        // Los PDF de planes docentes aplicados ya figuran en archivos_asignatura; UNION evita duplicarlos.
        return jdbc.sql("SELECT cloudflare_object_key FROM archivos_asignatura WHERE usuario_id = :id "
                        + "UNION SELECT clave_objeto FROM importaciones_plan_docente WHERE usuario_id = :id")
                .param("id", userId)
                .query(String.class)
                .list();
    }

    @Override
    public int wipeContent(UUID userId, Instant at) {
        int deleted = execute(STATISTICAL_CONTENT, userId) + execute(PERSONAL_CONTENT, userId);
        jdbc.sql(RESET_COGNITIVE_STATE).param("id", userId).param("at", JdbcValues.param(at)).update();
        return deleted;
    }

    @Override
    public int erasePersonalData(UUID userId) {
        int deleted = execute(PERSONAL_CONTENT, userId) + execute(PROFILE, userId);
        execute(SCRUB_STATISTICS, userId);
        return deleted;
    }

    @Override
    public void deleteAccount(UUID userId) {
        jdbc.sql("DELETE FROM usuarios WHERE id = :id").param("id", userId).update();
    }

    private int execute(List<String> statements, UUID userId) {
        int rows = 0;
        for (String sql : statements) {
            rows += jdbc.sql(sql).param("id", userId).update();
        }
        return rows;
    }
}
