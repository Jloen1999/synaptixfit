package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.Deadline;
import java.util.UUID;

/** Una entrega del usuario. */
public interface GetDeadlineUseCase {

    Deadline getDeadline(UUID userId, UUID deadlineId);
}
