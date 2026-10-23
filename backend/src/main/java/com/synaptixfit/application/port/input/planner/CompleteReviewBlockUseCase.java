package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Se ha hecho el repaso SM-2 de un material: se completa su bloque de repaso pendiente de hoy o
 * atrasado (el más reciente), sin XP de bloque porque la da el repaso. Un bloque de un día futuro no
 * se completa: lo moverá {@link ScheduleReviewBlockUseCase} a la nueva fecha. Idempotente (lo
 * invoca el oyente de {@code ReviewCompleted}).
 */
public interface CompleteReviewBlockUseCase {

    void completeReviewBlock(UUID userId, UUID studyMaterialId);
}
