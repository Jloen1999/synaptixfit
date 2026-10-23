package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import java.util.UUID;

/** Historial de check-ins. */
public interface ListCheckInsUseCase {

    PageResult<DailyCheckIn> list(UUID userId, PageRequest page);
}
