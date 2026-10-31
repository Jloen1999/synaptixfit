package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.neuro.BiologicalSex;
import java.time.LocalDate;

/** Datos de perfil que el planificador lee de otros módulos. */
public final class PlannerProfile {

    private PlannerProfile() {
    }

    /** Datos metabólicos (perfil de bienestar) para el gasto calórico de estudio. */
    public record Metabolic(double weightKg, double heightCm, int age, BiologicalSex sex) {
    }

    /**
     * Perfil académico.
     *
     * @param weeklyStudyGoalHours objetivo de horas de estudio semanales
     * @param semesterStart        inicio de clases (puede ser nulo)
     * @param semesterEnd          fin de clases (puede ser nulo)
     */
    public record Academic(int weeklyStudyGoalHours, LocalDate semesterStart, LocalDate semesterEnd) {

        /** Objetivo semanal de estudio si el usuario no tiene perfil académico (el de la columna por defecto). */
        public static final int DEFAULT_WEEKLY_GOAL_HOURS = 14;

        public boolean hasSemesterDates() {
            return semesterStart != null && semesterEnd != null && !semesterEnd.isBefore(semesterStart);
        }
    }
}
