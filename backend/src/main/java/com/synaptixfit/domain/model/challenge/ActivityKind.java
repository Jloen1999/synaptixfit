package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.model.user.UsageFocus;

/**
 * Qué se hizo, leído de otros módulos para los retos que se cuentan solos (ADR 0043). Cada tipo dice de qué ámbito
 * de la app es, para no ofrecer un reto que la persona no puede cumplir con su modo de uso.
 */
public enum ActivityKind {
    /** Repaso de un material (Académico). */
    REVIEW(Area.ACADEMIC),
    /** Test o simulacro terminado (Académico). */
    TEST(Area.ACADEMIC),
    /** Pomodoro de concentración terminado (Calendario, para todos). */
    FOCUS(Area.ANY),
    /** Semana planificada (Calendario, para todos). */
    PLANNED_WEEK(Area.ANY),
    /** Entreno hecho: sesión de gimnasio o actividad apuntada (Entreno). */
    WORKOUT(Area.FITNESS),
    /** Carrera grabada con el GPS (Entreno › Correr). */
    RUN(Area.FITNESS),
    /** «¿Qué tal estás hoy?» respondido (Entreno). Solo cuenta que se hizo, nunca las respuestas. */
    CHECK_IN(Area.FITNESS);

    private enum Area { ACADEMIC, FITNESS, ANY }

    private final Area area;

    ActivityKind(Area area) {
        this.area = area;
    }

    /** Si una persona con ese modo de uso ve la parte de la app donde se hace. */
    public boolean availableFor(UsageFocus focus) {
        return switch (area) {
            case ACADEMIC -> focus.includesAcademic();
            case FITNESS -> focus.includesFitness();
            case ANY -> true;
        };
    }
}
