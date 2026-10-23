package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.Priority;
import java.util.UUID;

/**
 * Datos editables de un bloque (todo menos el horario). Los vínculos son opcionales y se validan
 * contra la propiedad del usuario.
 *
 * @param deadlineTitle título de la entrega/examen que se crea al crear un bloque EXAM o DELIVERY sin
 *                      {@code deadlineId} (si falta se usan los temas o un título por defecto)
 */
public record BlockDetailsInput(ActivityType type, UUID subjectId, String topics, String location,
                                Priority priority, boolean isPrivate, ClassKind classKind, UUID routineId,
                                UUID routineWeekId, UUID routineDayId, UUID challengeId, UUID milestoneId,
                                UUID deadlineId, String deadlineTitle, Priority deadlineDifficulty) {
}
