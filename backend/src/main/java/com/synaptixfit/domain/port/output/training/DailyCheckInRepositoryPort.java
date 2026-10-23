package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de los check-ins diarios. */
public interface DailyCheckInRepositoryPort {

    Optional<DailyCheckIn> findByUserAndDate(UUID userId, LocalDate date);

    DailyCheckIn save(DailyCheckIn checkIn);

    /** Más recientes primero. */
    PageResult<DailyCheckIn> findByUser(UUID userId, PageRequest page);
}
