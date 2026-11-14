package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.model.planner.ActivityType;

/**
 * Definición única de «entreno hecho» en SQL estándar (vocabulario.md §3): una sesión de gimnasio terminada o una
 * actividad apuntada (carrera GPS, partido, deporte a mano) cuyo evento de deporte libre está hecho. La usan Inicio,
 * Progreso, insignias, retos y el panel de administración, para que todos cuenten las mismas filas.
 *
 * <p>Es una tabla derivada sin reglas de recompensa: el mínimo de minutos de {@code TrainingRewards} lo añade quien
 * lo necesita ({@link #counted}), como parámetro (ADR 0012). Columnas: {@code usuario_id}, {@code terminado_en},
 * {@code minutos}, {@code kcal} (nulas si el servidor no las calculó), {@code rpe} (de la sesión o del registro de
 * carga del evento) y {@code tipo_entreno} ({@link #FROM_SESSION} o {@link #FROM_ACTIVITY}).
 *
 * <p>Qué evento cuenta como actividad repite en SQL la regla de {@code CalendarBlock.countsAsPhysicalActivity} (deporte
 * que no refleja un día de rutina): el dominio sigue siendo la fuente de verdad y {@code CompletedWorkoutsSqlIT} fija
 * que coinciden (excepción anotada en el ADR 0012).
 */
public final class CompletedWorkoutsSql {

    /** Valor de {@code tipo_entreno} de una sesión de gimnasio. */
    public static final String FROM_SESSION = "SESION";

    /** Valor de {@code tipo_entreno} de una actividad apuntada. */
    public static final String FROM_ACTIVITY = "ACTIVIDAD";

    /**
     * Condición de los entrenos que cuentan para insignias y retos sobre la tabla con alias {@code alias}; necesita el
     * parámetro {@code :minMinutes}.
     */
    public static String counted(String alias) {
        return alias + ".minutos >= :minMinutes";
    }

    /**
     * Tabla derivada con un entreno hecho por fila; se usa como {@code FROM <TABLE> e}. El evento de una actividad es
     * deporte que no refleja un día de rutina (la misma regla que {@code CalendarBlock.mirrorsTrackedActivity}): esos
     * ya cuentan por su sesión.
     */
    public static final String TABLE = """
            (SELECT s.usuario_id, s.completada_en AS terminado_en, s.duracion_minutos AS minutos,
                    s.calorias_quemadas AS kcal, s.rpe, '%s' AS tipo_entreno
               FROM sesiones_registradas s
              WHERE s.completada_en IS NOT NULL
             UNION ALL
             SELECT a.usuario_id, b.hora_fin, a.minutos_reales, c.kcal, r.rpe_sesion, '%s'
               FROM actividades_apuntadas a
               JOIN horarios_academicos b ON b.id = a.bloque_id
               LEFT JOIN carreras_gps c ON c.bloque_id = a.bloque_id
               LEFT JOIN registros_carga_fisica r ON r.bloque_id = a.bloque_id
              WHERE b.completado = true AND b.tipo_actividad = '%s' AND b.dia_rutina_id IS NULL)"""
            .formatted(FROM_SESSION, FROM_ACTIVITY, ActivityType.SPORT.code());

    private CompletedWorkoutsSql() {
    }
}
