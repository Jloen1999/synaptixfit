package com.synaptixfit.domain.model.insights;

import java.time.LocalDate;

/** Carga académica de una semana (lectura de {@code carga_academica_semanal} del planificador). */
public record WeeklyAcademicLoad(LocalDate weekStart, int plannedStudyHours, int realStudyHours,
                                 int evaluations, int deliveries, int stressLevel, double avgSleepHours) {
}
