package com.synaptixfit.domain.model.notification;

/**
 * Qué recuerda un aviso del plan de recordatorios del móvil ({@link ReminderPlanner}). El móvil descarta los tipos que
 * no conoce, así que se pueden añadir tipos nuevos (como el cumpleaños, ADR 0036) sin romper las versiones anteriores
 * de la app.
 */
public enum ReminderKind {
    /** Repasos espaciados (SM-2) vencidos. */
    REVIEWS,
    /** Bloque de deporte del planificador a punto de empezar. */
    TRAINING,
    /** Bloque de estudio o repaso del planificador a punto de empezar. */
    STUDY,
    /** Examen pendiente en pocos días. */
    EXAM,
    /** Entrega (trabajo, práctica, presentación…) pendiente en pocos días. */
    DEADLINE,
    /** «Tu semana»: el domingo por la tarde, repasar cómo ha ido y planificar la siguiente. */
    WEEKLY_SUMMARY,
    /** «Tocaba ayer»: el día de rutina previsto pasó sin entrenar. */
    ROUTINE_DAY_MISSED,
    /** «¿Terminaste la sesión?»: una sesión de entrenamiento sigue abierta horas después de empezar. */
    OPEN_SESSION,
    /** «Tu reto vence mañana». */
    CHALLENGE_DUE,
    /** «Tu racha está en riesgo»: hay racha y hoy aún no hay actividad (por la tarde). */
    STREAK_AT_RISK,
    /** «¿Qué tal estás hoy?»: el registro diario, por la mañana si aún no se ha hecho. */
    CHECK_IN,
    /** «Tu clase empieza pronto» (con la antelación elegida), con el aula. */
    CLASS_SOON,
    /** Evento personal a punto de empezar (ADR 0035). */
    PERSONAL_EVENT,
    /** Tarea de reto con fecha que ningún otro aviso menciona: «Mañana: Repasar tema 3 · reto Aprobar Física». */
    CHALLENGE_TASK,
    /** Resumen de la mañana, solo si hay algo: «Hoy: 2 estudios, 1 entreno y 1 tarea de reto». */
    MORNING_SUMMARY,
    /**
     * «¡Feliz cumpleaños, Ana!» la mañana de su cumpleaños (ADR 0036). Si ese día hay resumen de la mañana, va dentro
     * de él ({@link ReminderPlan.DaySummary#birthday()}) en vez de llegar aparte.
     */
    BIRTHDAY,
    /**
     * «Hoy toca tu entreno de carrera: 6 × 800 m» con la antelación de los eventos (ADR 0037). Sustituye al aviso
     * {@link #TRAINING} de su evento: nunca dos avisos por lo mismo. Al tocarlo se abre Correr, con ese entreno
     * arriba. Las versiones de la app anteriores a la 4b no conocen este tipo y lo descartan (ADR 0037).
     */
    RUN_WORKOUT
}
