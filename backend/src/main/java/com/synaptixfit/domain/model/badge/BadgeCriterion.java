package com.synaptixfit.domain.model.badge;

import java.util.Arrays;

/**
 * Métrica que evalúa una insignia (columna {@code criterio_tipo}). Se obtiene la insignia cuando
 * el valor actual de la métrica alcanza {@code criterio_valor}.
 */
public enum BadgeCriterion {
    /** Sesiones de entrenamiento registradas. */
    SESSIONS_COMPLETED("sesiones_completadas"),
    /** Sesiones con RPE ≥ 8. */
    HIGH_RPE_SESSIONS("rpe_alto"),
    /** Check-ins diarios consecutivos hasta hoy (o ayer). */
    CONSECUTIVE_CHECK_INS("checkins_consecutivos"),
    /** Bloques de estudio completados. */
    STUDY_BLOCKS("bloques_estudio"),
    /** Planes de estudio creados. */
    STUDY_PLANS("planes_estudio"),
    /** Apuntes escritos. */
    NOTES_CREATED("apuntes_creados"),
    /** Publicaciones en el muro social. */
    FEED_POSTS("publicaciones_feed"),
    /** Likes recibidos en las publicaciones propias. */
    LIKES_RECEIVED("likes_recibidos"),
    /** Racha diaria del usuario (sesiones o check-ins). */
    STREAK_DAYS("racha_dias"),
    /** Retos completados. */
    CHALLENGES_COMPLETED("retos_completados"),
    /** Insignias ya obtenidas. */
    BADGES_EARNED("insignias_obtenidas"),
    /** Semanas consecutivas con adherencia al plan de estudio ≥ 80 %. */
    PLAN_ADHERENCE_WEEKS("semanas_plan_adherencia"),
    /** Criterio desconocido en el catálogo: nunca se otorga. */
    UNKNOWN("");

    private final String code;

    BadgeCriterion(String code) {
        this.code = code;
    }

    public String code() {
        return code;
    }

    public static BadgeCriterion fromCode(String code) {
        return Arrays.stream(values()).filter(c -> c != UNKNOWN && c.code.equals(code)).findFirst().orElse(UNKNOWN);
    }
}
