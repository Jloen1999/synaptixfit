package com.synaptixfit.domain.model.analytics;

import java.time.LocalDate;

/** Horas de estudio reales de una semana ({@code carga_academica_semanal}). */
public record WeeklyStudyLoad(LocalDate weekStart, double studyHours) {
}
