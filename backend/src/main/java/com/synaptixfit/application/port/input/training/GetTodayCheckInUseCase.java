package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.DailyCheckIn;
import java.util.Optional;
import java.util.UUID;

/** Check-in de hoy, si existe. */
public interface GetTodayCheckInUseCase {

    Optional<DailyCheckIn> today(UUID userId);
}
