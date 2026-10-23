package com.synaptixfit.domain.model.planner;

import java.util.List;

/**
 * Balance estudio/deporte de una semana a partir de sus bloques.
 *
 * <p>Regla heredada: equilibrado si el deporte supone entre el 30 % y el 50 % de las horas
 * planificadas (estudio + deporte). Descanso, comida y sueño no cuentan.
 */
public record WeekBalance(double plannedStudyHours, double actualStudyHours, double plannedSportHours,
                          double actualSportHours, State state) {

    /** Estado del balance. */
    public enum State {
        INACTIVE,
        BALANCED,
        STUDY_HEAVY,
        SPORT_HEAVY
    }

    public static WeekBalance of(List<CalendarBlock> blocks) {
        double study = 0;
        double studyDone = 0;
        double sport = 0;
        double sportDone = 0;
        for (CalendarBlock b : blocks) {
            double hours = b.range().minutes() / 60.0;
            if (b.type() == ActivityType.SPORT) {
                sport += hours;
                sportDone += b.completed() ? hours : 0;
            } else if (b.type().grantsExperience()) {
                study += hours;
                studyDone += b.completed() ? hours : 0;
            }
        }
        return new WeekBalance(round(study), round(studyDone), round(sport), round(sportDone), stateFor(study, sport));
    }

    static State stateFor(double study, double sport) {
        double total = study + sport;
        if (total == 0) {
            return State.INACTIVE;
        }
        double sportRatio = sport / total;
        if (sportRatio < 0.3) {
            return State.STUDY_HEAVY;
        }
        return sportRatio <= 0.5 ? State.BALANCED : State.SPORT_HEAVY;
    }

    private static double round(double v) {
        return Math.round(v * 100) / 100.0;
    }
}
