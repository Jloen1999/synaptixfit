package com.synaptixfit.domain.model.planner;

import java.util.List;

/**
 * Lo que la IA lee de un horario: las clases de las asignaturas del usuario y todas las asignaturas que aparecen
 * en el documento (con sus siglas si las tiene), para explicar qué se buscó cuando no coincide ninguna.
 */
public record ScheduleScan(List<ScheduleEntry> entries, List<String> documentSubjects) {

    public ScheduleScan {
        entries = entries == null ? List.of() : List.copyOf(entries);
        documentSubjects = documentSubjects == null ? List.of() : List.copyOf(documentSubjects);
    }
}
