package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.TimelineEntry;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Línea de tiempo real de la actividad de un usuario. */
public interface GetUserTimelineUseCase {

    PageResult<TimelineEntry> getUserTimeline(UUID userId, PageRequest page);
}
