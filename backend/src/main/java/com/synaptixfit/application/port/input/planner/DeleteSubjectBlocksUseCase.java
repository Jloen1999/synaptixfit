package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Borra todos los bloques de una asignatura que se va a eliminar, como si el usuario los borrase uno
 * a uno: resta su XP, avisa a retos e indicadores ({@code StudyBlockCompletionChanged}) y recalcula
 * la carga semanal. Idempotente (lo invoca el oyente de {@code SubjectDeleted}).
 */
public interface DeleteSubjectBlocksUseCase {

    void deleteSubjectBlocks(UUID userId, UUID subjectId);
}
