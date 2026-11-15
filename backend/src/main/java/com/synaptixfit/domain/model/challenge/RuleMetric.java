package com.synaptixfit.domain.model.challenge;

import java.util.Set;

/**
 * Qué mide un reto automático (ADR 0043) y de qué cosas hechas sale. Solo datos que el servidor ya guarda: nada que
 * dependa de lo que la persona diga a mano.
 */
public enum RuleMetric {
    /** Repasos hechos. */
    REVIEWS(Set.of(ActivityKind.REVIEW)),
    /** Minutos de Pomodoro de concentración terminados. */
    FOCUS_MINUTES(Set.of(ActivityKind.FOCUS)),
    /** Pomodoros que empezaron antes de las {@value ChallengeRule#EARLY_HOUR}:00 (hora local). */
    EARLY_FOCUS(Set.of(ActivityKind.FOCUS)),
    /** Entrenos hechos (gimnasio o actividad, la misma definición que el resto de la app). */
    WORKOUTS(Set.of(ActivityKind.WORKOUT)),
    /** Días con un Pomodoro y un entreno a la vez. */
    STUDY_AND_MOVE(Set.of(ActivityKind.FOCUS, ActivityKind.WORKOUT)),
    /** Tests o simulacros terminados. */
    TESTS(Set.of(ActivityKind.TEST)),
    /** Días con «¿Qué tal estás hoy?» respondido. Bienestar: el reto nunca se comparte. */
    CHECK_INS(Set.of(ActivityKind.CHECK_IN)),
    /** Semanas planificadas en el calendario (las que dieron la experiencia de planificar). */
    PLANNED_WEEKS(Set.of(ActivityKind.PLANNED_WEEK)),
    /** Carreras grabadas con el GPS. */
    RUNS(Set.of(ActivityKind.RUN));

    private final Set<ActivityKind> sources;

    RuleMetric(Set<ActivityKind> sources) {
        this.sources = sources;
    }

    public Set<ActivityKind> sources() {
        return sources;
    }

    /** Sale de datos de bienestar: el reto queda privado siempre y no se comparte. */
    public boolean wellbeing() {
        return sources.contains(ActivityKind.CHECK_IN);
    }
}
