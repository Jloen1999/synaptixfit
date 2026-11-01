package com.synaptixfit.domain.model.challenge;

import java.util.List;
import java.util.UUID;

/**
 * Definición de una tarea al crear un reto o reemplazar su lista de tareas. No lleva peso: el peso de
 * cada tarea en el progreso se deriva de su dificultad (ADR 0028).
 *
 * @param id            tarea existente que se conserva (con su progreso); {@code null} si es nueva
 * @param dependsOn     posiciones (base 0) de otras tareas de la misma lista de las que depende
 * @param subjectId     asignatura; si es {@code null} hereda la del reto
 */
public record MilestoneDraft(UUID id, String title, Difficulty difficulty, UUID subjectId,
                             UUID noteId, UUID fileId, ChallengeLink link, List<Integer> dependsOn,
                             UnlockCondition condition, Integer conditionN) {

    public MilestoneDraft {
        dependsOn = dependsOn == null ? List.of() : List.copyOf(dependsOn);
    }
}
