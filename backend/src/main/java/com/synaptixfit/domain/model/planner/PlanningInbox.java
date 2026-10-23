package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.LocalDate;
import java.util.List;

/**
 * Entrada de las sugerencias de planificación: objetivos de la semana y contexto del usuario.
 *
 * @param busyBlocks bloques ya existentes en la semana (zonas ocupadas)
 */
public record PlanningInbox(LocalDate weekStart, double studyHoursTarget, int sportSessionsTarget,
                            int minutesPerSportSession, int maxStudyBlockMinutes, List<SubjectRef> subjects,
                            List<Deadline> deadlines, List<RoutineRef> routines, List<CalendarBlock> busyBlocks) {

    /** Un bloque del calendario dura al menos 30 minutos ({@link TimeRange}). */
    public static final int MIN_STUDY_BLOCK_MINUTES = 30;

    /**
     * Duración máxima de un bloque de estudio: la pedida, recortada por la regulación cruzada (que
     * puede bajar hasta 25 min con sobreentrenamiento) pero nunca por debajo del bloque mínimo.
     */
    public static int cappedStudyBlockMinutes(int requested, int crossRegulationMax) {
        return Math.max(MIN_STUDY_BLOCK_MINUTES, Math.min(requested, crossRegulationMax));
    }

    public PlanningInbox {
        weekStart = PlannerZone.mondayOf(Guard.notNull(weekStart, "weekStart"));
        Guard.range(studyHoursTarget, "studyHours", 0, 80);
        Guard.range(sportSessionsTarget, "sportSessions", 0, 7);
        Guard.range(minutesPerSportSession, "minutesPerSportSession", 30, 120);
        Guard.range(maxStudyBlockMinutes, "maxStudyBlockMinutes", MIN_STUDY_BLOCK_MINUTES, 240);
        subjects = List.copyOf(subjects);
        deadlines = List.copyOf(deadlines);
        routines = List.copyOf(routines);
        busyBlocks = List.copyOf(busyBlocks);
    }
}
