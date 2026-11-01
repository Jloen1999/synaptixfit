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

        /**
         * Semestre del curso (1 o 2) según cuándo empiezan las clases: de agosto a enero, el primero; de febrero
         * a julio, el segundo. Los horarios de las universidades suelen traer los dos y hay que elegir.
         */
        public int semesterNumber() {
            int month = semesterStart == null ? 9 : semesterStart.getMonthValue();
            return month >= 8 || month == 1 ? 1 : 2;
        }

        /** Objetivo semanal de estudio si el usuario no tiene perfil académico (el de la columna por defecto). */
        public static final int DEFAULT_WEEKLY_GOAL_HOURS = 14;

        public boolean hasSemesterDates() {
            return semesterStart != null && semesterEnd != null && !semesterEnd.isBefore(semesterStart);
        }
    }
}
