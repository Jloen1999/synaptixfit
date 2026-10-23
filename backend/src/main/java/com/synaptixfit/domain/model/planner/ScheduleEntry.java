package com.synaptixfit.domain.model.planner;

import java.time.LocalTime;

/**
 * Clase del patrón semanal extraído de un horario (sin fechas absolutas).
 *
 * @param subjectCode siglas de la asignatura (puede estar vacío)
 * @param subjectName nombre de la asignatura tal como aparece en el documento
 * @param classKind   teoría o práctica (nulo si no consta)
 * @param dayOfWeek   1 = lunes … 7 = domingo
 * @param room        aula (puede estar vacía)
 */
public record ScheduleEntry(String subjectCode, String subjectName, ClassKind classKind, int dayOfWeek,
                            LocalTime start, LocalTime end, String room) {
}
