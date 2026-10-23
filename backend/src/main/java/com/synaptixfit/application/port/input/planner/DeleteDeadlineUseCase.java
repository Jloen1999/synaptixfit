package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/** Borra una entrega. Si había dado experiencia al completarse, se resta. */
public interface DeleteDeadlineUseCase {

    void deleteDeadline(UUID userId, UUID deadlineId);
}
